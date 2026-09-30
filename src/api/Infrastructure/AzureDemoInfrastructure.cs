using System.Net.Http.Headers;
using System.Text.Json;
using Azure.Core;
using Azure.Identity;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Options;

namespace LgrTransformationMigration.Api.Infrastructure;

public sealed class AzureIdentityOptions
{
    public const string SectionName = "AzureIdentity";
    public string ManagedIdentityClientId { get; set; } = string.Empty;
}

public sealed class EntraDemoMembershipOptions
{
    public string SecretUri { get; set; } = string.Empty;
    public int CacheSeconds { get; set; } = 300;
}

public interface IAzureAccessTokenProvider
{
    ValueTask<string> GetTokenAsync(string scope, CancellationToken cancellationToken);
}

public sealed class ManagedIdentityAccessTokenProvider : IAzureAccessTokenProvider
{
    private readonly ManagedIdentityCredential credential;

    public ManagedIdentityAccessTokenProvider(IOptions<AzureIdentityOptions> options)
    {
        credential = new ManagedIdentityCredential(options.Value.ManagedIdentityClientId);
    }

    public async ValueTask<string> GetTokenAsync(string scope, CancellationToken cancellationToken)
    {
        var token = await credential.GetTokenAsync(
            new TokenRequestContext([scope]),
            cancellationToken);
        return token.Token;
    }
}

public static class AzureDemoStartupGuard
{
    public static void Validate(WebApplicationBuilder builder)
    {
        if (!builder.Environment.IsEnvironment("AzureDemo"))
        {
            return;
        }

        var configuration = builder.Configuration;
        RequireEqual(configuration["Authentication:Mode"], InternalAuthenticationDefaults.EntraMode,
            "Authentication:Mode must be Entra in AzureDemo.");
        RequireEqual(configuration["DiscoveryImport:StorageMode"], "AzureBlob",
            "DiscoveryImport:StorageMode must be AzureBlob in AzureDemo.");
        RequireEqual(configuration["DemoData:Enabled"], "false",
            "DemoData:Enabled must remain false at API startup in AzureDemo.");

        RequireGuid(configuration["AzureIdentity:ManagedIdentityClientId"],
            "AzureIdentity:ManagedIdentityClientId");
        RequireGuid(configuration["Authentication:Entra:TenantId"],
            "Authentication:Entra:TenantId");
        var tenantId = configuration["Authentication:Entra:TenantId"]!;
        RequireEqual(configuration["Authentication:Entra:Issuer"],
            $"https://login.microsoftonline.com/{tenantId}/v2.0",
            "Authentication:Entra:Issuer must be the exact workforce-tenant v2 issuer in AzureDemo.");
        var audience = configuration["Authentication:Entra:Audience"];
        if (string.IsNullOrWhiteSpace(audience)
            || !audience.StartsWith("api://", StringComparison.Ordinal)
            || !Guid.TryParse(audience["api://".Length..], out var audienceId)
            || audienceId == Guid.Empty)
        {
            throw new InvalidOperationException("Authentication:Entra:Audience must be an exact api:// GUID in AzureDemo.");
        }

        var allowedClientIds = configuration.GetSection("Authentication:Entra:AllowedClientIds").Get<string[]>() ?? [];
        if (allowedClientIds.Length == 0
            || allowedClientIds.Distinct(StringComparer.Ordinal).Count() != allowedClientIds.Length
            || allowedClientIds.Any(value => !Guid.TryParse(value, out var clientId) || clientId == Guid.Empty))
        {
            throw new InvalidOperationException("Authentication:Entra:AllowedClientIds must contain unique non-empty GUIDs in AzureDemo.");
        }

        RequireAbsoluteHttps(configuration["Authentication:EntraDemoMemberships:SecretUri"],
            "Authentication:EntraDemoMemberships:SecretUri", ".vault.azure.net", "/secrets/entra-demo-memberships");
        if (!int.TryParse(configuration["Authentication:EntraDemoMemberships:CacheSeconds"], out var cacheSeconds)
            || cacheSeconds is < 1 or > 300)
        {
            throw new InvalidOperationException("Authentication:EntraDemoMemberships:CacheSeconds must be between 1 and 300 in AzureDemo.");
        }

        RequireAbsoluteHttps(configuration["DiscoveryImport:StorageAccountUri"],
            "DiscoveryImport:StorageAccountUri", ".blob.core.windows.net", "/");
        RequireEqual(configuration["DiscoveryImport:ContainerName"], "discovery-imports",
            "DiscoveryImport:ContainerName must be discovery-imports in AzureDemo.");

        var allowedHosts = configuration["AllowedHosts"];
        if (string.IsNullOrWhiteSpace(allowedHosts) || allowedHosts.Contains('*', StringComparison.Ordinal))
        {
            throw new InvalidOperationException("AllowedHosts must contain only the approved API hosts in AzureDemo.");
        }

        var origins = configuration.GetSection("AllowedOrigins").Get<string[]>() ?? [];
        if (origins.Length == 0 || origins.Any(origin =>
                !Uri.TryCreate(origin, UriKind.Absolute, out var uri)
                || uri.Scheme != Uri.UriSchemeHttps
                || uri.AbsolutePath != "/"
                || !string.IsNullOrEmpty(uri.Query)
                || !string.IsNullOrEmpty(uri.Fragment)))
        {
            throw new InvalidOperationException("AllowedOrigins must contain exact HTTPS web origins in AzureDemo.");
        }

        var connectionString = configuration.GetConnectionString("LgrDatabase");
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException("ConnectionStrings:LgrDatabase is required in AzureDemo.");
        }

        var sql = new SqlConnectionStringBuilder(connectionString);
        if (sql.Authentication != SqlAuthenticationMethod.ActiveDirectoryManagedIdentity
            || !sql.Encrypt
            || sql.TrustServerCertificate
            || !string.IsNullOrEmpty(sql.Password)
            || !IsApprovedAzureSqlDataSource(sql.DataSource)
            || !string.Equals(sql.InitialCatalog, "sqldb-lgrtm-azdemo", StringComparison.Ordinal)
            || !Guid.TryParse(sql.UserID, out var sqlIdentity)
            || !Guid.TryParse(configuration["AzureIdentity:ManagedIdentityClientId"], out var configuredIdentity)
            || sqlIdentity != configuredIdentity)
        {
            throw new InvalidOperationException(
                "AzureDemo SQL must use encrypted, certificate-validating, passwordless user-assigned managed identity authentication.");
        }

        var prohibitedConfiguration = configuration.AsEnumerable()
            .Where(entry => entry.Value is not null)
            .FirstOrDefault(entry =>
                entry.Key.Contains("LocalTest", StringComparison.OrdinalIgnoreCase)
                || entry.Key.Contains("Lgr-Test-Principal", StringComparison.OrdinalIgnoreCase)
                || entry.Key.Contains("LGR_TEST_PRINCIPAL", StringComparison.OrdinalIgnoreCase));
        if (prohibitedConfiguration.Key is not null)
        {
            throw new InvalidOperationException(
                $"Prohibited local identity configuration was supplied in AzureDemo: {prohibitedConfiguration.Key}.");
        }
    }

    private static void RequireEqual(string? actual, string expected, string message)
    {
        if (!string.Equals(actual, expected, StringComparison.Ordinal))
        {
            throw new InvalidOperationException(message);
        }
    }

    private static void RequireGuid(string? value, string name)
    {
        if (!Guid.TryParse(value, out var parsed) || parsed == Guid.Empty)
        {
            throw new InvalidOperationException($"{name} must be a non-empty GUID in AzureDemo.");
        }
    }

    private static void RequireAbsoluteHttps(
        string? value,
        string name,
        string? requiredHostSuffix = null,
        string? requiredPath = null)
    {
        if (!Uri.TryCreate(value, UriKind.Absolute, out var uri)
            || uri.Scheme != Uri.UriSchemeHttps
            || !string.IsNullOrEmpty(uri.UserInfo)
            || !string.IsNullOrEmpty(uri.Query)
            || !string.IsNullOrEmpty(uri.Fragment)
            || (requiredHostSuffix is not null
                && !uri.Host.EndsWith(requiredHostSuffix, StringComparison.OrdinalIgnoreCase))
            || (requiredPath is not null
                && !string.Equals(uri.AbsolutePath.TrimEnd('/'), requiredPath.TrimEnd('/'), StringComparison.Ordinal)))
        {
            throw new InvalidOperationException($"{name} must be an approved HTTPS URI in AzureDemo.");
        }
    }

    private static bool IsApprovedAzureSqlDataSource(string dataSource)
    {
        var normalized = dataSource.Trim();
        if (normalized.StartsWith("tcp:", StringComparison.OrdinalIgnoreCase))
        {
            normalized = normalized[4..];
        }

        var comma = normalized.IndexOf(',');
        if (comma >= 0)
        {
            normalized = normalized[..comma];
        }

        return normalized.StartsWith("sql-lgrtm-azdemo-uks-", StringComparison.OrdinalIgnoreCase)
            && normalized.EndsWith(".database.windows.net", StringComparison.OrdinalIgnoreCase);
    }
}

public interface IProjectMembershipReadiness
{
    ValueTask<bool> IsReadyAsync(CancellationToken cancellationToken);
}

public sealed class KeyVaultProjectMembershipProvider(
    IHttpClientFactory httpClientFactory,
    IAzureAccessTokenProvider tokenProvider,
    IOptions<LgrAuthenticationOptions> authenticationOptions,
    IOptions<EntraDemoMembershipOptions> membershipOptions,
    TimeProvider timeProvider,
    ILogger<KeyVaultProjectMembershipProvider> logger)
    : IProjectMembershipProvider, IProjectMembershipReadiness
{
    private static readonly HashSet<string> ApprovedRoles =
    [
        "MigrationArchitect", "DatabaseSme", "ProjectManager", "DiscoveryAnalyst", "ReviewerAuditor"
    ];

    private readonly SemaphoreSlim refreshLock = new(1, 1);
    private MembershipDocument? cached;
    private DateTimeOffset cacheExpiresAt;

    public async ValueTask<MembershipResolution> ResolveAsync(
        InternalPrincipal principal,
        Guid projectId,
        CancellationToken cancellationToken)
    {
        var document = await GetDocumentAsync(cancellationToken);
        if (document is null
            || principal.AuthenticationScheme != InternalAuthenticationDefaults.EntraMode
            || principal.PrincipalType != InternalPrincipalType.Human
            || principal.DirectoryTenantId != document.TenantId)
        {
            return new MembershipResolution(MembershipResolutionStatus.Unavailable);
        }

        var configured = document.Principals.SingleOrDefault(x => x.ObjectId == principal.DirectoryObjectId);
        if (configured is null || configured.Status != "Active")
        {
            return new MembershipResolution(MembershipResolutionStatus.NotFound);
        }

        var memberships = configured.Memberships.Where(x => x.ProjectId == projectId).ToList();
        if (memberships.Count != 1)
        {
            return new MembershipResolution(MembershipResolutionStatus.NotFound);
        }

        var membership = memberships[0];
        var now = timeProvider.GetUtcNow();
        if (membership.Status != "Active"
            || membership.ValidFromUtc > now
            || membership.ValidUntilUtc <= now)
        {
            return new MembershipResolution(MembershipResolutionStatus.NotFound);
        }

        return new MembershipResolution(
            MembershipResolutionStatus.Active,
            membership.CustomerId,
            membership.ProjectId,
            membership.Roles.ToHashSet(StringComparer.Ordinal),
            document.MembershipVersion);
    }

    public async ValueTask<bool> IsReadyAsync(CancellationToken cancellationToken) =>
        await GetDocumentAsync(cancellationToken) is not null;

    private async ValueTask<MembershipDocument?> GetDocumentAsync(CancellationToken cancellationToken)
    {
        var now = timeProvider.GetUtcNow();
        if (cached is not null && now < cacheExpiresAt)
        {
            return cached;
        }

        await refreshLock.WaitAsync(cancellationToken);
        try
        {
            now = timeProvider.GetUtcNow();
            if (cached is not null && now < cacheExpiresAt)
            {
                return cached;
            }

            try
            {
                cached = await LoadAsync(cancellationToken);
                cacheExpiresAt = now.AddSeconds(Math.Clamp(membershipOptions.Value.CacheSeconds, 1, 300));
                return cached;
            }
            catch (Exception exception) when (!cancellationToken.IsCancellationRequested)
            {
                cached = null;
                cacheExpiresAt = default;
                logger.LogError(exception,
                    "The AzureDemo membership authority is unavailable; project access remains fail-closed.");
                return null;
            }
        }
        finally
        {
            refreshLock.Release();
        }
    }

    private async Task<MembershipDocument> LoadAsync(CancellationToken cancellationToken)
    {
        var secretUri = new Uri(membershipOptions.Value.SecretUri);
        var requestUri = new UriBuilder(secretUri) { Query = "api-version=7.5" }.Uri;
        using var request = new HttpRequestMessage(HttpMethod.Get, requestUri);
        request.Headers.Authorization = new AuthenticationHeaderValue(
            "Bearer",
            await tokenProvider.GetTokenAsync("https://vault.azure.net/.default", cancellationToken));

        using var response = await httpClientFactory.CreateClient("AzurePrivateDataPlane")
            .SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
        response.EnsureSuccessStatusCode();
        var envelope = await JsonSerializer.DeserializeAsync<KeyVaultSecretEnvelope>(
            await response.Content.ReadAsStreamAsync(cancellationToken),
            cancellationToken: cancellationToken)
            ?? throw new InvalidOperationException("The membership secret response was empty.");
        var document = JsonSerializer.Deserialize<MembershipDocument>(envelope.Value,
            new JsonSerializerOptions { PropertyNameCaseInsensitive = true })
            ?? throw new InvalidOperationException("The membership document was empty.");
        Validate(document);
        return document;
    }

    private void Validate(MembershipDocument document)
    {
        if (document.SchemaVersion != "1"
            || string.IsNullOrWhiteSpace(document.MembershipVersion)
            || document.TenantId != Guid.Parse(authenticationOptions.Value.Entra.TenantId)
            || document.Principals.Count == 0
            || document.Principals.Select(x => x.ObjectId).Distinct().Count() != document.Principals.Count)
        {
            throw new InvalidOperationException("The membership document failed schema or tenant validation.");
        }

        foreach (var principal in document.Principals)
        {
            if (principal.ObjectId == Guid.Empty
                || (principal.Status != "Active" && principal.Status != "Disabled")
                || principal.Memberships.GroupBy(x => x.ProjectId).Any(group => group.Count() != 1))
            {
                throw new InvalidOperationException("The membership document contains an invalid principal.");
            }

            foreach (var membership in principal.Memberships)
            {
                if (membership.CustomerId == Guid.Empty
                    || membership.ProjectId == Guid.Empty
                    || membership.ValidUntilUtc <= membership.ValidFromUtc
                    || (membership.Status != "Active" && membership.Status != "Disabled")
                    || membership.Roles.Count == 0
                    || membership.Roles.Distinct(StringComparer.Ordinal).Count() != membership.Roles.Count
                    || membership.Roles.Any(role => !ApprovedRoles.Contains(role)))
                {
                    throw new InvalidOperationException("The membership document contains an invalid project membership.");
                }
            }
        }
    }

    private sealed class KeyVaultSecretEnvelope
    {
        public string Value { get; set; } = string.Empty;
    }

    private sealed class MembershipDocument
    {
        public string SchemaVersion { get; set; } = string.Empty;
        public string MembershipVersion { get; set; } = string.Empty;
        public Guid TenantId { get; set; }
        public List<MembershipPrincipal> Principals { get; set; } = [];
    }

    private sealed class MembershipPrincipal
    {
        public Guid ObjectId { get; set; }
        public string Status { get; set; } = string.Empty;
        public List<MembershipEntry> Memberships { get; set; } = [];
    }

    private sealed class MembershipEntry
    {
        public Guid CustomerId { get; set; }
        public Guid ProjectId { get; set; }
        public string Status { get; set; } = "Active";
        public DateTimeOffset ValidFromUtc { get; set; }
        public DateTimeOffset ValidUntilUtc { get; set; }
        public List<string> Roles { get; set; } = [];
    }
}
