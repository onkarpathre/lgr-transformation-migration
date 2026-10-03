using LgrTransformationMigration.Api.Infrastructure;
using LgrTransformationMigration.Api.Services;
using LgrTransformationMigration.Api.Services.Discovery;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authorization.Policy;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

var builder = WebApplication.CreateBuilder(args);
if (builder.Environment.IsDevelopment() || builder.Environment.IsEnvironment("Testing"))
{
    builder.Configuration.AddJsonFile("appsettings.LocalTest.json", optional: false, reloadOnChange: false);
}
AzureDemoStartupGuard.Validate(builder);

builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.ForwardLimit = 2;
    if (builder.Environment.IsEnvironment("AzureDemo"))
    {
        options.KnownIPNetworks.Clear();
        options.KnownProxies.Clear();
    }
});
builder.Services.AddHttpClient("AzurePrivateDataPlane", client =>
{
    client.Timeout = TimeSpan.FromSeconds(150);
    client.DefaultRequestHeaders.UserAgent.ParseAdd("lgrtm-azure-demo/1.0");
});

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<RequestAuthorizationState>();
builder.Services.AddScoped<IInternalPrincipalAccessor>(services => services.GetRequiredService<RequestAuthorizationState>());
builder.Services.AddScoped<IProjectAuthorizationContextAccessor>(services => services.GetRequiredService<RequestAuthorizationState>());
builder.Services.AddScoped<ICurrentCustomerContext, CurrentCustomerContext>();
builder.Services.AddOptions<LgrAuthenticationOptions>()
    .Bind(builder.Configuration.GetSection(LgrAuthenticationOptions.SectionName))
    .ValidateOnStart();
builder.Services.AddSingleton<IValidateOptions<LgrAuthenticationOptions>, LgrAuthenticationOptionsValidator>();
builder.Services.AddSingleton<LocalTestIdentityProvider>();
builder.Services.AddSingleton<ILocalTestIdentityProvider>(services => services.GetRequiredService<LocalTestIdentityProvider>());
if (builder.Environment.IsDevelopment() || builder.Environment.IsEnvironment("Testing"))
{
    builder.Services.AddSingleton<IProjectMembershipProvider>(services =>
        services.GetRequiredService<LocalTestIdentityProvider>());
    builder.Services.AddSingleton<IProjectMembershipReadiness>(services =>
        services.GetRequiredService<LocalTestIdentityProvider>());
}
else if (builder.Environment.IsEnvironment("AzureDemo"))
{
    builder.Services.Configure<AzureIdentityOptions>(builder.Configuration.GetSection(AzureIdentityOptions.SectionName));
    builder.Services.Configure<EntraDemoMembershipOptions>(
        builder.Configuration.GetSection("Authentication:EntraDemoMemberships"));
    builder.Services.AddSingleton<IAzureAccessTokenProvider, ManagedIdentityAccessTokenProvider>();
    builder.Services.AddSingleton<KeyVaultProjectMembershipProvider>();
    builder.Services.AddSingleton<IProjectMembershipProvider>(services =>
        services.GetRequiredService<KeyVaultProjectMembershipProvider>());
    builder.Services.AddSingleton<IProjectMembershipReadiness>(services =>
        services.GetRequiredService<KeyVaultProjectMembershipProvider>());
}
else
{
    builder.Services.AddSingleton<UnavailableProjectMembershipProvider>();
    builder.Services.AddSingleton<IProjectMembershipProvider>(services =>
        services.GetRequiredService<UnavailableProjectMembershipProvider>());
    builder.Services.AddSingleton<IProjectMembershipReadiness>(services =>
        services.GetRequiredService<UnavailableProjectMembershipProvider>());
}

builder.Services.AddSingleton<IEntraOpenIdConfigurationProvider, MicrosoftEntraOpenIdConfigurationProvider>();
builder.Services.AddSingleton<IEntraAccessTokenValidator, MicrosoftEntraAccessTokenValidator>();
builder.Services.AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = InternalAuthenticationDefaults.Scheme;
        options.DefaultChallengeScheme = InternalAuthenticationDefaults.Scheme;
    })
    .AddScheme<AuthenticationSchemeOptions, InternalAuthenticationHandler>(
        InternalAuthenticationDefaults.Scheme,
        _ => { });
builder.Services.AddScoped<ProjectAuthorizationResolver>();
builder.Services.AddScoped<IAuthorizationHandler, ApiAccessAuthorizationHandler>();
builder.Services.AddScoped<IAuthorizationHandler, ActiveProjectMembershipAuthorizationHandler>();
builder.Services.AddScoped<IAuthorizationHandler, ProjectPermissionAuthorizationHandler>();
builder.Services.AddSingleton<IAuthorizationMiddlewareResultHandler, ApiAuthorizationMiddlewareResultHandler>();

static AuthorizationPolicy ProjectPolicy(string? permission = null)
{
    var policy = new AuthorizationPolicyBuilder(InternalAuthenticationDefaults.Scheme)
        .RequireAuthenticatedUser()
        .AddRequirements(new ApiAccessRequirement());
    policy.AddRequirements(permission is null
        ? new ActiveProjectMembershipRequirement()
        : new ProjectPermissionRequirement(permission));
    return policy.Build();
}

builder.Services.AddAuthorizationBuilder()
    .SetFallbackPolicy(ProjectPolicy())
    .AddPolicy(ProjectAuthorizationPolicies.ActiveMembership, ProjectPolicy())
    .AddPolicy(SqlInventoryAuthorizationPolicies.Read, ProjectPolicy(SqlInventoryPermissions.Read))
    .AddPolicy(SqlInventoryAuthorizationPolicies.Create, ProjectPolicy(SqlInventoryPermissions.Create))
    .AddPolicy(SqlInventoryAuthorizationPolicies.Update, ProjectPolicy(SqlInventoryPermissions.Update))
    .AddPolicy(SqlInventoryAuthorizationPolicies.Delete, ProjectPolicy(SqlInventoryPermissions.Delete))
    .AddPolicy(SqlDiscoveryAuthorizationPolicies.Read, ProjectPolicy(SqlDiscoveryPermissions.Read))
    .AddPolicy(SqlDiscoveryAuthorizationPolicies.Prepare, ProjectPolicy(SqlDiscoveryPermissions.Prepare))
    .AddPolicy(SqlDiscoveryAuthorizationPolicies.Commit, ProjectPolicy(SqlDiscoveryPermissions.Commit))
    .AddPolicy(SqlDiscoveryAuthorizationPolicies.Cancel, ProjectPolicy(SqlDiscoveryPermissions.Cancel))
    .AddPolicy(SqlAssessmentAuthorizationPolicies.Read, ProjectPolicy(SqlAssessmentPermissions.Read))
    .AddPolicy(SqlAssessmentAuthorizationPolicies.Manage, ProjectPolicy(SqlAssessmentPermissions.Manage))
    .AddPolicy(SqlAssessmentAuthorizationPolicies.Plan, ProjectPolicy(SqlAssessmentPermissions.Plan))
    .AddPolicy(DependencyAuthorizationPolicies.Read, ProjectPolicy(DependencyPermissions.Read))
    .AddPolicy(DependencyAuthorizationPolicies.Manage, ProjectPolicy(DependencyPermissions.Manage))
    .AddPolicy(DependencyAuthorizationPolicies.Confirm, ProjectPolicy(DependencyPermissions.Confirm))
    .AddPolicy(DependencyAuthorizationPolicies.Validate, ProjectPolicy(DependencyPermissions.Validate))
    .AddPolicy(DependencyAuthorizationPolicies.AuditRead, ProjectPolicy(DependencyPermissions.AuditRead));
builder.Services.AddDbContext<AppDbContext>(options => options.UseSqlServer(
    builder.Configuration.GetConnectionString("LgrDatabase")
    ?? throw new InvalidOperationException("ConnectionStrings:LgrDatabase is required.")));
builder.Services.AddScoped<ProgrammeService>();
builder.Services.AddScoped<SqlInventoryService>();
builder.Services.AddScoped<SqlAssessmentService>();
builder.Services.AddScoped<DependencyRegisterService>();
builder.Services.AddScoped<IpAllocationService>();
builder.Services.AddScoped<RunbookService>();
builder.Services.Configure<DiscoveryImportOptions>(builder.Configuration.GetSection(DiscoveryImportOptions.SectionName));
var discoveryOptions = builder.Configuration.GetSection(DiscoveryImportOptions.SectionName).Get<DiscoveryImportOptions>() ?? new();
builder.Services.Configure<FormOptions>(form => form.MultipartBodyLengthLimit = discoveryOptions.MaximumFileSizeBytes + 65536);
if (builder.Environment.IsEnvironment("AzureDemo"))
{
    builder.Services.AddScoped<AzureBlobImportFileStorage>();
    builder.Services.AddScoped<IImportFileStorage>(services => services.GetRequiredService<AzureBlobImportFileStorage>());
    builder.Services.AddScoped<IImportStorageReadiness>(services => services.GetRequiredService<AzureBlobImportFileStorage>());
}
else
{
    builder.Services.AddScoped<LocalImportFileStorage>();
    builder.Services.AddScoped<IImportFileStorage>(services => services.GetRequiredService<LocalImportFileStorage>());
    builder.Services.AddScoped<IImportStorageReadiness>(services => services.GetRequiredService<LocalImportFileStorage>());
}
builder.Services.AddSingleton<IDiscoveryFileReader, CsvDiscoveryFileReader>();
builder.Services.AddSingleton<IDiscoverySourceMapper, AzureMigrateServerReportMapper>();
builder.Services.AddSingleton<IDiscoverySourceMapper, AzureMigrateAllInventoryMapper>();
builder.Services.AddSingleton<DiscoverySourceMapperResolver>();
builder.Services.AddSingleton<DiscoveryRecordValidator>();
builder.Services.AddSingleton<DiscoveryReconciler>();
builder.Services.AddScoped<DiscoveryImportService>();
builder.Services.AddSingleton<SqlDiscoveryCsvContract>();
builder.Services.AddScoped<SqlDiscoveryImportService>();
builder.Services.AddSingleton<ReadinessCalculator>();
builder.Services.AddSingleton<IpTransitionPolicy>();
builder.Services.AddSingleton(TimeProvider.System);
builder.Services.AddExceptionHandler<ApiExceptionHandler>();
builder.Services.AddProblemDetails();
builder.Services.Configure<FeatureOptions>(builder.Configuration.GetSection(FeatureOptions.SectionName));
builder.Services.AddScoped<SqlDiscoveryAssessmentFeatureFilter>();
builder.Services.AddScoped<SqlDiscoveryImportFeatureFilter>();
builder.Services.AddScoped<SqlAssessmentFeatureFilter>();
builder.Services.AddScoped<SqlBrowserJourneysFeatureFilter>();
builder.Services.AddScoped<DependencyRegisterFeatureFilter>();
builder.Services.AddControllers().ConfigureApiBehaviorOptions(options =>
{
    options.InvalidModelStateResponseFactory = context =>
    {
        var problemDetails = new ValidationProblemDetails(context.ModelState)
        {
            Type = "https://www.rfc-editor.org/rfc/rfc9110#section-15.5.1",
            Title = "Request validation failed",
            Status = StatusCodes.Status400BadRequest,
            Detail = "One or more request fields are invalid.",
            Instance = context.HttpContext.Request.Path
        };
        problemDetails.Extensions["errorCode"] = "validation_failed";
        problemDetails.Extensions["correlationId"] = context.HttpContext.TraceIdentifier;

        return new BadRequestObjectResult(problemDetails)
        {
            ContentTypes = { "application/problem+json" }
        };
    };
});
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new() { Title = "LGR Transformation and Migration API", Version = "v1" });
});

var origins = builder.Configuration.GetSection("AllowedOrigins").Get<string[]>() ?? ["http://localhost:3000"];
builder.Services.AddCors(options => options.AddPolicy("Web", policy => policy
    .WithOrigins(origins)
    .WithMethods("GET", "HEAD", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
    .WithHeaders("Authorization", "Content-Type", "Accept", "X-Project-Id", "If-Match", "If-None-Match", "traceparent", "tracestate")
    .WithExposedHeaders("ETag", "X-Correlation-Id", "traceparent")
    .SetPreflightMaxAge(TimeSpan.FromMinutes(10))));

var app = builder.Build();

app.UseExceptionHandler();
app.UseForwardedHeaders();
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

if (!app.Environment.IsDevelopment() && !app.Environment.IsEnvironment("Testing"))
{
    app.UseHsts();
}
app.UseHttpsRedirection();
app.UseRouting();
app.UseMiddleware<TraceCorrelationMiddleware>();
app.UseMiddleware<ApiSecurityHeadersMiddleware>();
app.UseCors("Web");
app.UseMiddleware<ProhibitedIdentityHeaderMiddleware>();
app.UseAuthentication();
app.UseAuthorization();
app.UseMiddleware<AuthorizedAccessLoggingMiddleware>();
app.MapControllers();
HealthEndpoints.Map(app);

app.Run();

public partial class Program;
