using System.Collections.Frozen;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authorization.Policy;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Controllers;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Protocols;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;

namespace LgrTransformationMigration.Api.Infrastructure;

public static class InternalAuthenticationDefaults
{
    public const string Scheme = "Internal";
    public const string EntraMode = "Entra";
    public const string LocalTestMode = "LocalTest";
}

public static class SqlInventoryAuthorizationPolicies
{
    public const string Read = "SqlInventoryRead";
    public const string Create = "SqlInventoryCreate";
    public const string Update = "SqlInventoryUpdate";
    public const string Delete = "SqlInventoryDelete";
}

public static class SqlInventoryPermissions
{
    public const string Read = "sql.inventory.read";
    public const string Create = "sql.inventory.create";
    public const string Update = "sql.inventory.update";
    public const string Delete = "sql.inventory.delete";

    private static readonly IReadOnlySet<string> Empty = Array.Empty<string>().ToFrozenSet(StringComparer.Ordinal);
    private static readonly IReadOnlySet<string> ReadOnly = new[] { Read }.ToFrozenSet(StringComparer.Ordinal);
    private static readonly IReadOnlySet<string> ReadWrite = new[] { Read, Create, Update, Delete }
        .ToFrozenSet(StringComparer.Ordinal);

    public static IReadOnlySet<string> ForRoles(IEnumerable<string> roles)
    {
        var normalized = roles.ToHashSet(StringComparer.Ordinal);
        if (normalized.Contains("DatabaseSme"))
        {
            return ReadWrite;
        }

        return normalized.Overlaps(
            ["MigrationArchitect", "ProjectManager", "DiscoveryAnalyst", "ReviewerAuditor"])
            ? ReadOnly
            : Empty;
    }
}

public enum InternalPrincipalType
{
    Human,
    Workload
}

public sealed record InternalPrincipal(
    Guid PrincipalId,
    InternalPrincipalType PrincipalType,
    string IdentityProvider,
    Guid DirectoryTenantId,
    Guid DirectoryObjectId,
    Guid ClientApplicationId,
    string Subject,
    string? DisplayName,
    string AuthenticationScheme,
    bool IsActive,
    bool ApiAccessAllowed)
{
    public string AuditActor => AuthenticationScheme == InternalAuthenticationDefaults.LocalTestMode
        ? $"local-test:{PrincipalId:D}"
        : PrincipalType == InternalPrincipalType.Workload
            ? $"entra-app:{DirectoryTenantId:D}:{DirectoryObjectId:D}"
            : $"entra:{DirectoryTenantId:D}:{DirectoryObjectId:D}";
}

public sealed record ProjectAuthorizationContext(
    InternalPrincipal Principal,
    Guid CustomerId,
    Guid ProjectId,
    IReadOnlySet<string> ProjectRoles,
    IReadOnlySet<string> Permissions,
    string MembershipVersion);

public interface IInternalPrincipalAccessor
{
    InternalPrincipal? Principal { get; }
}

public interface IProjectAuthorizationContextAccessor
{
    ProjectAuthorizationContext? AuthorizationContext { get; }
}

public sealed class RequestAuthorizationState : IInternalPrincipalAccessor, IProjectAuthorizationContextAccessor
{
    public InternalPrincipal? Principal { get; private set; }
    public ProjectAuthorizationContext? AuthorizationContext { get; private set; }

    internal void SetPrincipal(InternalPrincipal principal)
    {
        Principal = principal;
        AuthorizationContext = null;
    }

    internal void SetAuthorizationContext(ProjectAuthorizationContext context)
    {
        if (Principal is null || Principal.PrincipalId != context.Principal.PrincipalId)
        {
            throw new InvalidOperationException("Project authorization cannot replace the authenticated principal.");
        }

        if (AuthorizationContext is not null && AuthorizationContext != context)
        {
            throw new InvalidOperationException("Project authorization context is immutable for a request.");
        }

        AuthorizationContext = context;
    }
}

public sealed class LgrAuthenticationOptions
{
    public const string SectionName = "Authentication";

    public string Mode { get; set; } = InternalAuthenticationDefaults.EntraMode;
    public EntraAuthenticationOptions Entra { get; set; } = new();
    public LocalTestAuthenticationOptions LocalTest { get; set; } = new();
}

public sealed class EntraAuthenticationOptions
{
    public string TenantId { get; set; } = string.Empty;
    public string Issuer { get; set; } = string.Empty;
    public string Audience { get; set; } = string.Empty;
    public List<string> AllowedClientIds { get; set; } = [];
}

public sealed class LocalTestAuthenticationOptions
{
    public List<LocalTestPrincipalOptions> Principals { get; set; } = [];
}

public sealed class LocalTestPrincipalOptions
{
    public string Alias { get; set; } = string.Empty;
    public Guid PrincipalId { get; set; }
    public string Status { get; set; } = "Active";
    public string? DisplayName { get; set; }
    public List<LocalTestMembershipOptions> Memberships { get; set; } = [];
}

public sealed class LocalTestMembershipOptions
{
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public string CustomerStatus { get; set; } = "Active";
    public string ProjectStatus { get; set; } = "Active";
    public DateTimeOffset ValidFromUtc { get; set; }
    public DateTimeOffset? ValidUntilUtc { get; set; }
    public string Version { get; set; } = string.Empty;
    public List<string> Roles { get; set; } = [];
}

public sealed partial class LgrAuthenticationOptionsValidator(IHostEnvironment environment)
    : IValidateOptions<LgrAuthenticationOptions>
{
    public ValidateOptionsResult Validate(string? name, LgrAuthenticationOptions options)
    {
        var localEnvironment = environment.IsDevelopment() || environment.IsEnvironment("Testing");
        if (options.Mode == InternalAuthenticationDefaults.LocalTestMode)
        {
            if (!localEnvironment)
            {
                return ValidateOptionsResult.Fail(
                    "Authentication:Mode LocalTest is prohibited outside Development and Testing.");
            }

            return ValidateLocalTest(options.LocalTest);
        }

        if (options.Mode != InternalAuthenticationDefaults.EntraMode)
        {
            return ValidateOptionsResult.Fail("Authentication:Mode must be Entra or LocalTest.");
        }

        if (!Guid.TryParse(options.Entra.TenantId, out var tenantId) || tenantId == Guid.Empty)
        {
            return ValidateOptionsResult.Fail("Authentication:Entra:TenantId is required and must be a GUID.");
        }

        if (!Uri.TryCreate(options.Entra.Issuer, UriKind.Absolute, out var issuer)
            || issuer.Scheme != Uri.UriSchemeHttps
            || !issuer.AbsolutePath.TrimEnd('/').EndsWith($"/{tenantId:D}/v2.0", StringComparison.OrdinalIgnoreCase))
        {
            return ValidateOptionsResult.Fail(
                "Authentication:Entra:Issuer is required, must use HTTPS and must identify the configured v2 tenant.");
        }

        if (string.IsNullOrWhiteSpace(options.Entra.Audience))
        {
            return ValidateOptionsResult.Fail("Authentication:Entra:Audience is required.");
        }

        if (options.Entra.AllowedClientIds.Count == 0
            || options.Entra.AllowedClientIds.Any(value => !Guid.TryParse(value, out var id) || id == Guid.Empty))
        {
            return ValidateOptionsResult.Fail(
                "Authentication:Entra:AllowedClientIds must contain at least one valid GUID.");
        }

        return ValidateOptionsResult.Success;
    }

    private static ValidateOptionsResult ValidateLocalTest(LocalTestAuthenticationOptions options)
    {
        if (options.Principals.Count == 0)
        {
            return ValidateOptionsResult.Fail("Authentication:LocalTest requires synthetic principals.");
        }

        var aliases = new HashSet<string>(StringComparer.Ordinal);
        var principalIds = new HashSet<Guid>();
        foreach (var principal in options.Principals)
        {
            if (!LocalAliasPattern().IsMatch(principal.Alias)
                || Guid.TryParse(principal.Alias, out _)
                || !aliases.Add(principal.Alias)
                || principal.PrincipalId == Guid.Empty
                || !principalIds.Add(principal.PrincipalId)
                || (principal.Status != "Active" && principal.Status != "Disabled"))
            {
                return ValidateOptionsResult.Fail("Authentication:LocalTest contains an invalid synthetic principal.");
            }

            foreach (var membership in principal.Memberships)
            {
                if (membership.CustomerId == Guid.Empty
                    || membership.ProjectId == Guid.Empty
                    || string.IsNullOrWhiteSpace(membership.Version)
                    || membership.Roles.Count != membership.Roles.Distinct(StringComparer.Ordinal).Count()
                    || (membership.CustomerStatus != "Active" && membership.CustomerStatus != "Disabled")
                    || (membership.ProjectStatus != "Active" && membership.ProjectStatus != "Disabled"))
                {
                    return ValidateOptionsResult.Fail("Authentication:LocalTest contains an invalid synthetic membership.");
                }
            }
        }

        return ValidateOptionsResult.Success;
    }

    [GeneratedRegex("^[a-z][a-z0-9-]{1,63}$", RegexOptions.CultureInvariant)]
    private static partial Regex LocalAliasPattern();
}

public interface ILocalTestIdentityProvider
{
    InternalPrincipal? FindPrincipal(string alias);
}

public enum MembershipResolutionStatus
{
    Active,
    NotFound,
    Unavailable
}

public sealed record MembershipResolution(
    MembershipResolutionStatus Status,
    Guid CustomerId = default,
    Guid ProjectId = default,
    IReadOnlySet<string>? Roles = null,
    string MembershipVersion = "");

public interface IProjectMembershipProvider
{
    ValueTask<MembershipResolution> ResolveAsync(
        InternalPrincipal principal,
        Guid projectId,
        CancellationToken cancellationToken);
}

public sealed class LocalTestIdentityProvider(
    IOptions<LgrAuthenticationOptions> options,
    TimeProvider timeProvider) : ILocalTestIdentityProvider, IProjectMembershipProvider
{
    private static readonly Guid SyntheticTenantId = Guid.Parse("99999999-9999-9999-9999-999999999999");
    private static readonly Guid SyntheticClientId = Guid.Parse("88888888-8888-8888-8888-888888888888");

    public InternalPrincipal? FindPrincipal(string alias)
    {
        var configured = options.Value.LocalTest.Principals.SingleOrDefault(x => x.Alias == alias);
        return configured is null
            ? null
            : new InternalPrincipal(
                configured.PrincipalId,
                InternalPrincipalType.Human,
                "EntraId",
                SyntheticTenantId,
                configured.PrincipalId,
                SyntheticClientId,
                configured.Alias,
                configured.DisplayName,
                InternalAuthenticationDefaults.LocalTestMode,
                configured.Status == "Active",
                ApiAccessAllowed: true);
    }

    public ValueTask<MembershipResolution> ResolveAsync(
        InternalPrincipal principal,
        Guid projectId,
        CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var configured = options.Value.LocalTest.Principals.SingleOrDefault(x => x.PrincipalId == principal.PrincipalId);
        if (configured is null || !principal.IsActive || configured.Status != "Active")
        {
            return ValueTask.FromResult(new MembershipResolution(MembershipResolutionStatus.NotFound));
        }

        var memberships = configured.Memberships.Where(x => x.ProjectId == projectId).ToList();
        if (memberships.Count != 1)
        {
            return ValueTask.FromResult(new MembershipResolution(MembershipResolutionStatus.NotFound));
        }

        var membership = memberships[0];
        var now = timeProvider.GetUtcNow();
        if (membership.CustomerStatus != "Active"
            || membership.ProjectStatus != "Active"
            || membership.ValidFromUtc > now
            || (membership.ValidUntilUtc.HasValue && membership.ValidUntilUtc.Value <= now))
        {
            return ValueTask.FromResult(new MembershipResolution(MembershipResolutionStatus.NotFound));
        }

        return ValueTask.FromResult(new MembershipResolution(
            MembershipResolutionStatus.Active,
            membership.CustomerId,
            membership.ProjectId,
            membership.Roles.ToHashSet(StringComparer.Ordinal),
            membership.Version));
    }
}

public sealed class UnavailableProjectMembershipProvider : IProjectMembershipProvider
{
    public ValueTask<MembershipResolution> ResolveAsync(
        InternalPrincipal principal,
        Guid projectId,
        CancellationToken cancellationToken) =>
        ValueTask.FromResult(new MembershipResolution(MembershipResolutionStatus.Unavailable));
}

public interface IEntraAccessTokenValidator
{
    Task<ClaimsPrincipal> ValidateAsync(string token, CancellationToken cancellationToken);
}

public interface IEntraOpenIdConfigurationProvider
{
    Task<OpenIdConnectConfiguration> GetAsync(CancellationToken cancellationToken);
}

public sealed class MicrosoftEntraOpenIdConfigurationProvider(IOptions<LgrAuthenticationOptions> options)
    : IEntraOpenIdConfigurationProvider
{
    private readonly EntraAuthenticationOptions _options = options.Value.Entra;
    private ConfigurationManager<OpenIdConnectConfiguration>? _configurationManager;

    public Task<OpenIdConnectConfiguration> GetAsync(CancellationToken cancellationToken)
    {
        var metadataAddress = $"{_options.Issuer.TrimEnd('/')}/.well-known/openid-configuration";
        _configurationManager ??= new ConfigurationManager<OpenIdConnectConfiguration>(
            metadataAddress,
            new OpenIdConnectConfigurationRetriever(),
            new HttpDocumentRetriever { RequireHttps = true });
        return _configurationManager.GetConfigurationAsync(cancellationToken);
    }
}

public sealed class MicrosoftEntraAccessTokenValidator(
    IOptions<LgrAuthenticationOptions> options,
    IEntraOpenIdConfigurationProvider configurationProvider) : IEntraAccessTokenValidator
{
    private readonly EntraAuthenticationOptions _options = options.Value.Entra;
    private readonly JsonWebTokenHandler _tokenHandler = new() { MapInboundClaims = false };

    public async Task<ClaimsPrincipal> ValidateAsync(string token, CancellationToken cancellationToken)
    {
        var configuration = await configurationProvider.GetAsync(cancellationToken);
        var validation = await _tokenHandler.ValidateTokenAsync(token, new TokenValidationParameters
        {
            ValidIssuer = _options.Issuer,
            ValidateIssuer = true,
            ValidAudience = _options.Audience,
            ValidateAudience = true,
            ValidateLifetime = true,
            RequireExpirationTime = true,
            RequireSignedTokens = true,
            ValidateIssuerSigningKey = true,
            IssuerSigningKeys = configuration.SigningKeys,
            ClockSkew = TimeSpan.FromMinutes(2)
        });

        if (!validation.IsValid || validation.ClaimsIdentity is null)
        {
            throw new SecurityTokenValidationException("The access token could not be validated.", validation.Exception);
        }

        return new ClaimsPrincipal(validation.ClaimsIdentity);
    }
}

public static class EntraInternalPrincipalMapper
{
    public static InternalPrincipal Map(ClaimsPrincipal tokenPrincipal, EntraAuthenticationOptions options)
    {
        var tenantId = RequiredGuid(tokenPrincipal, "tid");
        var configuredTenant = Guid.Parse(options.TenantId);
        if (tenantId != configuredTenant)
        {
            throw new SecurityTokenValidationException("The access token could not be validated.");
        }

        var objectId = RequiredGuid(tokenPrincipal, "oid");
        var clientId = RequiredGuid(tokenPrincipal, "azp");
        var subject = RequiredClaim(tokenPrincipal, "sub");
        if (RequiredClaim(tokenPrincipal, "ver") != "2.0")
        {
            throw new SecurityTokenValidationException("The access token could not be validated.");
        }

        var scopes = ClaimValues(tokenPrincipal, "scp")
            .SelectMany(value => value.Split(' ', StringSplitOptions.RemoveEmptyEntries))
            .ToHashSet(StringComparer.Ordinal);
        var tokenRoles = ClaimValues(tokenPrincipal, "roles").ToHashSet(StringComparer.Ordinal);
        var hasServiceRole = tokenRoles.Contains("Lgr.Api.Service");
        var principalType = hasServiceRole && scopes.Count == 0
            ? InternalPrincipalType.Workload
            : InternalPrincipalType.Human;
        if (principalType == InternalPrincipalType.Workload
            && (!Guid.TryParse(subject, out var workloadSubject) || workloadSubject != objectId))
        {
            throw new SecurityTokenValidationException("The access token could not be validated.");
        }

        var allowedClients = options.AllowedClientIds
            .Select(Guid.Parse)
            .ToHashSet();
        var mixedDelegatedAndWorkload = scopes.Count > 0 && hasServiceRole;
        var apiAccessAllowed = principalType == InternalPrincipalType.Human
                               && scopes.Contains("lgr.access")
                               && allowedClients.Contains(clientId)
                               && !mixedDelegatedAndWorkload;

        return new InternalPrincipal(
            StablePrincipalId(tenantId, objectId, principalType),
            principalType,
            "EntraId",
            tenantId,
            objectId,
            clientId,
            subject,
            tokenPrincipal.FindFirst("name")?.Value,
            InternalAuthenticationDefaults.EntraMode,
            IsActive: true,
            apiAccessAllowed);
    }

    private static string RequiredClaim(ClaimsPrincipal principal, string claimType) =>
        principal.FindFirst(claimType)?.Value is { Length: > 0 } value
            ? value
            : throw new SecurityTokenValidationException("The access token could not be validated.");

    private static Guid RequiredGuid(ClaimsPrincipal principal, string claimType) =>
        Guid.TryParse(RequiredClaim(principal, claimType), out var value) && value != Guid.Empty
            ? value
            : throw new SecurityTokenValidationException("The access token could not be validated.");

    private static IEnumerable<string> ClaimValues(ClaimsPrincipal principal, string claimType) =>
        principal.FindAll(claimType).Select(claim => claim.Value);

    private static Guid StablePrincipalId(Guid tenantId, Guid objectId, InternalPrincipalType principalType)
    {
        var source = Encoding.UTF8.GetBytes($"lgr|{tenantId:D}|{objectId:D}|{principalType}");
        var bytes = SHA256.HashData(source).AsSpan(0, 16).ToArray();
        return new Guid(bytes);
    }
}

public sealed partial class InternalAuthenticationHandler(
    IOptionsMonitor<AuthenticationSchemeOptions> schemeOptions,
    ILoggerFactory loggerFactory,
    UrlEncoder encoder,
    IOptions<LgrAuthenticationOptions> authenticationOptions,
    ILocalTestIdentityProvider localTestIdentityProvider,
    IEntraAccessTokenValidator entraTokenValidator,
    RequestAuthorizationState authorizationState)
    : AuthenticationHandler<AuthenticationSchemeOptions>(schemeOptions, loggerFactory, encoder)
{
    protected override async Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        try
        {
            var options = authenticationOptions.Value;
            InternalPrincipal? principal;
            if (options.Mode == InternalAuthenticationDefaults.LocalTestMode)
            {
                var aliases = Request.Headers["X-Lgr-Test-Principal"];
                if (aliases.Count != 1
                    || !LocalAliasPattern().IsMatch(aliases[0]!)
                    || Guid.TryParse(aliases[0], out _))
                {
                    return AuthenticateResult.NoResult();
                }

                principal = localTestIdentityProvider.FindPrincipal(aliases[0]!);
                if (principal is null)
                {
                    Logger.LogWarning("LocalTest authentication rejected a non-allow-listed synthetic alias.");
                    return AuthenticateResult.Fail("Authentication is required.");
                }
            }
            else
            {
                var authorization = Request.Headers.Authorization.ToString();
                if (!authorization.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)
                    || string.IsNullOrWhiteSpace(authorization[7..]))
                {
                    return AuthenticateResult.NoResult();
                }

                var validatedToken = await entraTokenValidator.ValidateAsync(
                    authorization[7..].Trim(),
                    Context.RequestAborted);
                principal = EntraInternalPrincipalMapper.Map(validatedToken, options.Entra);
            }

            authorizationState.SetPrincipal(principal);
            var identity = new ClaimsIdentity(
                [new Claim(ClaimTypes.NameIdentifier, principal.PrincipalId.ToString("D"))],
                InternalAuthenticationDefaults.Scheme);
            return AuthenticateResult.Success(
                new AuthenticationTicket(new ClaimsPrincipal(identity), InternalAuthenticationDefaults.Scheme));
        }
        catch (Exception) when (!Context.RequestAborted.IsCancellationRequested)
        {
            Logger.LogWarning("Bearer authentication failed validation.");
            return AuthenticateResult.Fail("Authentication is required.");
        }
    }

    [GeneratedRegex("^[a-z][a-z0-9-]{1,63}$", RegexOptions.CultureInvariant)]
    private static partial Regex LocalAliasPattern();
}

public sealed class ProjectAuthorizationResolver(
    IHttpContextAccessor httpContextAccessor,
    RequestAuthorizationState state,
    IProjectMembershipProvider membershipProvider,
    ILogger<ProjectAuthorizationResolver> logger)
{
    public async ValueTask<string?> ResolveAsync(CancellationToken cancellationToken)
    {
        if (state.AuthorizationContext is not null)
        {
            return null;
        }

        var httpContext = httpContextAccessor.HttpContext
                          ?? throw new InvalidOperationException("An HTTP authorization context is required.");
        if (state.Principal is null || !state.Principal.IsActive)
        {
            return AuthorizationFailureCodes.MembershipNotFound;
        }

        var projectValues = httpContext.Request.Headers["X-Project-Id"];
        if (projectValues.Count == 0 || string.IsNullOrWhiteSpace(projectValues[0]))
        {
            return AuthorizationFailureCodes.ProjectContextRequired;
        }

        if (projectValues.Count != 1
            || !Guid.TryParse(projectValues[0], out var projectId)
            || projectId == Guid.Empty)
        {
            return AuthorizationFailureCodes.InvalidProjectContext;
        }

        MembershipResolution resolution;
        try
        {
            resolution = await membershipProvider.ResolveAsync(
                state.Principal,
                projectId,
                httpContext.RequestAborted.CanBeCanceled ? httpContext.RequestAborted : cancellationToken);
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            logger.LogError("Project membership authority failed closed with {ExceptionType}.", exception.GetType().Name);
            return AuthorizationFailureCodes.AuthorizationUnavailable;
        }

        if (resolution.Status == MembershipResolutionStatus.Unavailable)
        {
            logger.LogError("Project membership authority reported an unavailable result.");
            return AuthorizationFailureCodes.AuthorizationUnavailable;
        }

        if (resolution.Status != MembershipResolutionStatus.Active
            || resolution.CustomerId == Guid.Empty
            || resolution.ProjectId != projectId
            || resolution.Roles is null
            || string.IsNullOrWhiteSpace(resolution.MembershipVersion))
        {
            return AuthorizationFailureCodes.MembershipNotFound;
        }

        state.SetAuthorizationContext(new ProjectAuthorizationContext(
            state.Principal,
            resolution.CustomerId,
            resolution.ProjectId,
            resolution.Roles.ToFrozenSet(StringComparer.Ordinal),
            SqlInventoryPermissions.ForRoles(resolution.Roles),
            resolution.MembershipVersion));
        return null;
    }
}

public sealed record ApiAccessRequirement : IAuthorizationRequirement;
public sealed record ActiveProjectMembershipRequirement : IAuthorizationRequirement;
public sealed record ProjectPermissionRequirement(string Permission) : IAuthorizationRequirement;

public sealed class ApiAccessAuthorizationHandler(RequestAuthorizationState state)
    : AuthorizationHandler<ApiAccessRequirement>
{
    protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, ApiAccessRequirement requirement)
    {
        if (state.Principal is { ApiAccessAllowed: true, PrincipalType: InternalPrincipalType.Human })
        {
            context.Succeed(requirement);
        }
        else
        {
            context.Fail(new AuthorizationFailureReason(this, AuthorizationFailureCodes.ApiAccessDenied));
        }

        return Task.CompletedTask;
    }
}

public sealed class ActiveProjectMembershipAuthorizationHandler(ProjectAuthorizationResolver resolver)
    : AuthorizationHandler<ActiveProjectMembershipRequirement>
{
    protected override async Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        ActiveProjectMembershipRequirement requirement)
    {
        var failure = await resolver.ResolveAsync(CancellationToken.None);
        if (failure is null)
        {
            context.Succeed(requirement);
        }
        else
        {
            context.Fail(new AuthorizationFailureReason(this, failure));
        }
    }
}

public sealed class ProjectPermissionAuthorizationHandler(
    ProjectAuthorizationResolver resolver,
    RequestAuthorizationState state)
    : AuthorizationHandler<ProjectPermissionRequirement>
{
    protected override async Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        ProjectPermissionRequirement requirement)
    {
        var failure = await resolver.ResolveAsync(CancellationToken.None);
        if (failure is not null)
        {
            context.Fail(new AuthorizationFailureReason(this, failure));
            return;
        }

        if (state.AuthorizationContext!.Permissions.Contains(requirement.Permission))
        {
            context.Succeed(requirement);
        }
        else
        {
            context.Fail(new AuthorizationFailureReason(this, AuthorizationFailureCodes.PermissionDenied));
        }
    }
}

public static class AuthorizationFailureCodes
{
    public const string ApiAccessDenied = "api_access_denied";
    public const string ProjectContextRequired = "project_context_required";
    public const string InvalidProjectContext = "invalid_project_context";
    public const string MembershipNotFound = "resource_not_found";
    public const string PermissionDenied = "permission_denied";
    public const string AuthorizationUnavailable = "authorization_unavailable";
}

public sealed class ApiAuthorizationMiddlewareResultHandler(
    IProblemDetailsService problemDetailsService,
    ILogger<ApiAuthorizationMiddlewareResultHandler> logger) : IAuthorizationMiddlewareResultHandler
{
    public async Task HandleAsync(
        RequestDelegate next,
        HttpContext context,
        AuthorizationPolicy policy,
        PolicyAuthorizationResult authorizeResult)
    {
        if (authorizeResult.Succeeded)
        {
            await next(context);
            return;
        }

        if (authorizeResult.Challenged)
        {
            context.Response.Headers.WWWAuthenticate = "Bearer";
            await WriteAsync(
                context,
                StatusCodes.Status401Unauthorized,
                "Authentication required",
                "Authentication is required to access this resource.",
                "authentication_required");
            return;
        }

        var reasons = authorizeResult.AuthorizationFailure?.FailureReasons
            .Select(reason => reason.Message)
            .ToHashSet(StringComparer.Ordinal) ?? [];
        var code = SelectFailureCode(reasons);
        var response = code switch
        {
            AuthorizationFailureCodes.ApiAccessDenied =>
                (StatusCodes.Status403Forbidden, "API access denied", "The request is not permitted."),
            AuthorizationFailureCodes.ProjectContextRequired =>
                (StatusCodes.Status400BadRequest, "Project context required", "A project context is required."),
            AuthorizationFailureCodes.InvalidProjectContext =>
                (StatusCodes.Status400BadRequest, "Invalid project context", "The project context is invalid."),
            AuthorizationFailureCodes.MembershipNotFound =>
                (StatusCodes.Status404NotFound, "Resource not found", "The requested resource was not found."),
            AuthorizationFailureCodes.AuthorizationUnavailable =>
                (StatusCodes.Status503ServiceUnavailable, "Authorization unavailable", "Authorization could not be completed."),
            _ => (StatusCodes.Status403Forbidden, "Permission denied", "The request is not permitted.")
        };

        logger.LogWarning(
            "API authorization failed with outcome {Outcome}, method {Method}, endpoint {Endpoint} and correlation {CorrelationId}.",
            code,
            context.Request.Method,
            context.GetEndpoint()?.DisplayName ?? "unmatched",
            context.TraceIdentifier);
        await WriteAsync(context, response.Item1, response.Item2, response.Item3, code);
    }

    private async Task WriteAsync(HttpContext context, int status, string title, string detail, string errorCode)
    {
        context.Response.StatusCode = status;
        var problemDetails = new ProblemDetails
        {
            Type = ProblemType(status),
            Title = title,
            Status = status,
            Detail = detail,
            Instance = context.Request.Path
        };
        problemDetails.Extensions["errorCode"] = errorCode;
        problemDetails.Extensions["correlationId"] = context.TraceIdentifier;
        if (!await problemDetailsService.TryWriteAsync(new ProblemDetailsContext
        {
            HttpContext = context,
            ProblemDetails = problemDetails
        }))
        {
            context.Response.ContentType = "application/problem+json";
            await context.Response.WriteAsJsonAsync(problemDetails, context.RequestAborted);
        }
    }

    private static string SelectFailureCode(IReadOnlySet<string> reasons)
    {
        string[] precedence =
        [
            AuthorizationFailureCodes.ApiAccessDenied,
            AuthorizationFailureCodes.AuthorizationUnavailable,
            AuthorizationFailureCodes.ProjectContextRequired,
            AuthorizationFailureCodes.InvalidProjectContext,
            AuthorizationFailureCodes.MembershipNotFound,
            AuthorizationFailureCodes.PermissionDenied
        ];
        return precedence.FirstOrDefault(reasons.Contains) ?? AuthorizationFailureCodes.PermissionDenied;
    }

    private static string ProblemType(int status) =>
        status switch
        {
            StatusCodes.Status400BadRequest => "https://www.rfc-editor.org/rfc/rfc9110#section-15.5.1",
            StatusCodes.Status401Unauthorized => "https://www.rfc-editor.org/rfc/rfc9110#section-15.5.2",
            StatusCodes.Status403Forbidden => "https://www.rfc-editor.org/rfc/rfc9110#section-15.5.4",
            StatusCodes.Status404NotFound => "https://www.rfc-editor.org/rfc/rfc9110#section-15.5.5",
            StatusCodes.Status503ServiceUnavailable => "https://www.rfc-editor.org/rfc/rfc9110#section-15.6.4",
            _ => "about:blank"
        };
}

public sealed class ProhibitedIdentityHeaderMiddleware(
    RequestDelegate next,
    ILogger<ProhibitedIdentityHeaderMiddleware> logger,
    IHostEnvironment environment)
{
    private static readonly string[] ProhibitedHeaders =
    [
        "X-Customer-Id",
        "X-User-Name",
        "X-Lgr-Test-Principal",
        "X-Principal-Id",
        "X-Roles",
        "X-Project-Roles",
        "X-Permissions"
    ];

    public async Task InvokeAsync(HttpContext context)
    {
        if (!environment.IsDevelopment() && !environment.IsEnvironment("Testing"))
        {
            foreach (var header in ProhibitedHeaders.Where(context.Request.Headers.ContainsKey))
            {
                context.Request.Headers.Remove(header);
                logger.LogWarning(
                    "Ignored prohibited caller-supplied identity header {HeaderName}; correlation {CorrelationId}.",
                    header,
                    context.TraceIdentifier);
            }
        }

        await next(context);
    }
}

public sealed class AuthorizedAccessLoggingMiddleware(
    RequestDelegate next,
    ILogger<AuthorizedAccessLoggingMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context, IProjectAuthorizationContextAccessor authorizationAccessor)
    {
        await next(context);

        var authorization = authorizationAccessor.AuthorizationContext;
        if (authorization is null)
        {
            return;
        }

        var routeTemplate = context.GetEndpoint()?.Metadata.GetMetadata<ControllerActionDescriptor>()
            ?.AttributeRouteInfo?.Template ?? "authorized-endpoint";
        logger.LogInformation(
            "Authorized API access by principal {PrincipalId} in customer {CustomerId} project {ProjectId}: " +
            "{Method} {RouteTemplate} returned {StatusCode}; correlation {CorrelationId}.",
            authorization.Principal.PrincipalId,
            authorization.CustomerId,
            authorization.ProjectId,
            context.Request.Method,
            routeTemplate,
            context.Response.StatusCode,
            context.TraceIdentifier);
    }
}
