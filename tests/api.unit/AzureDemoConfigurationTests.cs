using LgrTransformationMigration.Api.Infrastructure;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Configuration;

namespace LgrTransformationMigration.Api.UnitTests;

public sealed class AzureDemoConfigurationTests
{
    private const string SubscriptionId = "633398e2-6c00-4bb7-a576-2db0d210ee77";
    private const string ResourceGroupName = "Onkar.Pathre";
    private const string ApiAppName = "app-mtp-api-dev-uks-001";
    private const string WebAppName = "app-mtp-web-dev-uks-001";
    private const string ProductionApiHost = $"{ApiAppName}-d4f5g6h7j8k9m2n3.uksouth-01.azurewebsites.net";
    private const string ProductionWebHost = $"{WebAppName}-csdtetbtbeh3h7fy.uksouth-01.azurewebsites.net";
    private const string StagingApiHost = $"{ApiAppName}-staging-athrc5epbzcdetb8.uksouth-01.azurewebsites.net";
    private const string StagingWebHost = $"{WebAppName}-staging-csdtetbtbeh3h7fy.uksouth-01.azurewebsites.net";

    [Fact]
    public void AzureDemo_rejects_LocalTest_before_service_startup()
    {
        var builder = Builder();
        builder.Configuration["Authentication:Mode"] = "LocalTest";

        var error = Assert.Throws<InvalidOperationException>(() => AzureDemoStartupGuard.Validate(builder));

        Assert.Contains("must be Entra", error.Message, StringComparison.Ordinal);
    }

    [Fact]
    public void AzureDemo_rejects_password_or_certificate_bypass_in_SQL_configuration()
    {
        var builder = CompleteBuilder();
        builder.Configuration["ConnectionStrings:LgrDatabase"] =
            "Server=tcp:sql-mtp-dev-uks-001.database.windows.net,1433;Database=sqldb-mtp-dev-uks-001;Encrypt=True;TrustServerCertificate=True;User ID=demo;Password=prohibited";

        var error = Assert.Throws<InvalidOperationException>(() => AzureDemoStartupGuard.Validate(builder));

        Assert.Contains("passwordless", error.Message, StringComparison.Ordinal);
    }

    [Fact]
    public void AzureDemo_accepts_complete_Entra_UAMI_private_service_configuration()
    {
        var builder = CompleteBuilder();

        AzureDemoStartupGuard.Validate(builder);
    }

    [Fact]
    public void AzureDemo_accepts_Azure_reported_generated_staging_hosts()
    {
        var builder = CompleteBuilder();
        ConfigureHostIdentity(builder, "staging", StagingApiHost, StagingWebHost);

        AzureDemoStartupGuard.Validate(builder);
    }

    [Fact]
    public void AzureDemo_accepts_Azure_reported_generated_production_hosts()
    {
        var builder = CompleteBuilder();
        ConfigureHostIdentity(builder, "production", ProductionApiHost, ProductionWebHost);

        AzureDemoStartupGuard.Validate(builder);
    }

    [Theory]
    [InlineData("app-unapproved-api-dev-uks-001.azurewebsites.net")]
    [InlineData("app-mtp-api-dev-uks-001-evil.azurewebsites.net")]
    [InlineData("app-mtp-api-dev-uks-001.azurewebsites.net.evil.example")]
    [InlineData("*.azurewebsites.net")]
    [InlineData("app-mtp-api-dev-uks-001.azurewebsites.net;other.example")]
    [InlineData("app-mtp-api-dev-uks-001.azurewebsites.net:443")]
    public void AzureDemo_rejects_wrong_wildcard_suffix_and_multiple_allowed_hosts(string allowedHosts)
    {
        var builder = CompleteBuilder();
        builder.Configuration["AllowedHosts"] = allowedHosts;

        Assert.Throws<InvalidOperationException>(() => AzureDemoStartupGuard.Validate(builder));
    }

    [Theory]
    [InlineData("http://app-mtp-web-dev-uks-001.azurewebsites.net")]
    [InlineData("https://app-mtp-web-dev-uks-001.azurewebsites.net:443")]
    [InlineData("https://app-mtp-web-dev-uks-001.azurewebsites.net/path")]
    [InlineData("https://user@app-mtp-web-dev-uks-001.azurewebsites.net")]
    [InlineData("https://app-mtp-web-dev-uks-001.azurewebsites.net?query=value")]
    [InlineData("https://app-mtp-web-dev-uks-001.azurewebsites.net#fragment")]
    [InlineData("https://*.azurewebsites.net")]
    [InlineData("https://app-mtp-web-dev-uks-001.azurewebsites.net.evil.example")]
    public void AzureDemo_rejects_invalid_origin_scheme_port_path_userinfo_query_fragment_and_wildcards(
        string origin)
    {
        var builder = CompleteBuilder();
        builder.Configuration["AllowedOrigins:0"] = origin;

        Assert.Throws<InvalidOperationException>(() => AzureDemoStartupGuard.Validate(builder));
    }

    [Fact]
    public void AzureDemo_rejects_multiple_origins()
    {
        var builder = CompleteBuilder();
        builder.Configuration["AllowedOrigins:1"] = "https://other.example";

        Assert.Throws<InvalidOperationException>(() => AzureDemoStartupGuard.Validate(builder));
    }

    [Fact]
    public void AzureDemo_rejects_cross_environment_host_and_origin_mapping()
    {
        var builder = CompleteBuilder();
        ConfigureHostIdentity(builder, "staging", ProductionApiHost, ProductionWebHost);

        Assert.Throws<InvalidOperationException>(() => AzureDemoStartupGuard.Validate(builder));
    }

    [Theory]
    [InlineData("Api", "app-other-api-dev-uks-001-d4f5g6h7j8k9m2n3.uksouth-01.azurewebsites.net")]
    [InlineData("Web", "app-other-web-dev-uks-001-csdtetbtbeh3h7fy.uksouth-01.azurewebsites.net")]
    public void AzureDemo_does_not_treat_allowlist_values_as_their_own_trusted_identity(
        string workload,
        string substitutedHost)
    {
        var builder = CompleteBuilder();
        builder.Configuration[$"AzureDemoHostIdentity:{workload}DefaultHostName"] = substitutedHost;
        if (workload == "Api")
        {
            builder.Configuration["AllowedHosts"] = substitutedHost;
        }
        else
        {
            builder.Configuration["AllowedOrigins:0"] = $"https://{substitutedHost}";
        }

        Assert.Throws<InvalidOperationException>(() => AzureDemoStartupGuard.Validate(builder));
    }

    [Theory]
    [InlineData("AzureDemoHostIdentity:SlotName", "other")]
    [InlineData("AzureDemoHostIdentity:ApiResourceId", "/subscriptions/633398e2-6c00-4bb7-a576-2db0d210ee77/resourceGroups/Onkar.Pathre/providers/Microsoft.Web/sites/app-other")]
    [InlineData("AzureDemoHostIdentity:WebResourceId", "/subscriptions/633398e2-6c00-4bb7-a576-2db0d210ee77/resourceGroups/Other.Group/providers/Microsoft.Web/sites/app-mtp-web-dev-uks-001")]
    [InlineData("AzureDemoHostIdentity:ApiDefaultHostName", "arbitrary.azurewebsites.net")]
    [InlineData("AzureDemoHostIdentity:WebDefaultHostName", "app-mtp-web-dev-uks-001.azurewebsites.net.evil.example")]
    public void AzureDemo_rejects_untrusted_host_identity_configuration(string key, string value)
    {
        var builder = CompleteBuilder();
        builder.Configuration[key] = value;

        Assert.Throws<InvalidOperationException>(() => AzureDemoStartupGuard.Validate(builder));
    }

    [Theory]
    [InlineData("Authentication:Entra:Issuer", "https://login.microsoftonline.com/common/v2.0")]
    [InlineData("Authentication:Entra:Audience", "api://not-a-guid")]
    [InlineData("Authentication:Entra:AllowedClientIds:0", "")]
    [InlineData("Authentication:EntraDemoMemberships:SecretUri", "https://kv-mtp-dev-uks-op01.vault.azure.net/secrets/other")]
    [InlineData("Authentication:EntraDemoMemberships:SecretUri", "https://kv-other.vault.azure.net/secrets/entra-demo-memberships")]
    [InlineData("Authentication:EntraDemoMemberships:CacheSeconds", "301")]
    [InlineData("DiscoveryImport:StorageAccountUri", "https://stmtpdevuks001.blob.core.windows.net/other")]
    [InlineData("DiscoveryImport:StorageAccountUri", "https://stother.blob.core.windows.net")]
    [InlineData("DiscoveryImport:ContainerName", "other")]
    [InlineData("AllowedHosts", "app-unapproved-api-dev-uks-001.azurewebsites.net")]
    [InlineData("AllowedOrigins:0", "https://app-unapproved-web-dev-uks-001.azurewebsites.net")]
    public void AzureDemo_rejects_inexact_identity_and_storage_configuration(string key, string value)
    {
        var builder = CompleteBuilder();
        builder.Configuration[key] = value;

        Assert.Throws<InvalidOperationException>(() => AzureDemoStartupGuard.Validate(builder));
    }

    [Theory]
    [InlineData("Server=tcp:other.database.windows.net,1433;Database=sqldb-mtp-dev-uks-001;Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Managed Identity;User Id=aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")]
    [InlineData("Server=tcp:sql-unapproved-dev-uks-001.database.windows.net,1433;Database=sqldb-mtp-dev-uks-001;Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Managed Identity;User Id=aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")]
    [InlineData("Server=tcp:sql-mtp-dev-uks-001.database.windows.net,1433;Database=other;Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Managed Identity;User Id=aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")]
    public void AzureDemo_rejects_wrong_Azure_SQL_target(string connectionString)
    {
        var builder = CompleteBuilder();
        builder.Configuration["ConnectionStrings:LgrDatabase"] = connectionString;

        Assert.Throws<InvalidOperationException>(() => AzureDemoStartupGuard.Validate(builder));
    }

    private static WebApplicationBuilder CompleteBuilder()
    {
        var identity = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
        var builder = Builder();
        var values = new Dictionary<string, string?>
        {
            ["Authentication:Mode"] = "Entra",
            ["Authentication:Entra:TenantId"] = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
            ["Authentication:Entra:Issuer"] = "https://login.microsoftonline.com/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/v2.0",
            ["Authentication:Entra:Audience"] = "api://cccccccc-cccc-cccc-cccc-cccccccccccc",
            ["Authentication:Entra:AllowedClientIds:0"] = "dddddddd-dddd-dddd-dddd-dddddddddddd",
            ["Authentication:EntraDemoMemberships:SecretUri"] = "https://kv-mtp-dev-uks-op01.vault.azure.net/secrets/entra-demo-memberships",
            ["Authentication:EntraDemoMemberships:CacheSeconds"] = "300",
            ["AzureIdentity:ManagedIdentityClientId"] = identity,
            ["AzureDemoHostIdentity:SlotName"] = "production",
            ["AzureDemoHostIdentity:ApiResourceId"] = ResourceId(ApiAppName, "production"),
            ["AzureDemoHostIdentity:ApiDefaultHostName"] = $"{ApiAppName}.azurewebsites.net",
            ["AzureDemoHostIdentity:WebResourceId"] = ResourceId(WebAppName, "production"),
            ["AzureDemoHostIdentity:WebDefaultHostName"] = $"{WebAppName}.azurewebsites.net",
            ["DiscoveryImport:StorageMode"] = "AzureBlob",
            ["DiscoveryImport:StorageAccountUri"] = "https://stmtpdevuks001.blob.core.windows.net",
            ["DiscoveryImport:ContainerName"] = "discovery-imports",
            ["DemoData:Enabled"] = "false",
            ["AllowedHosts"] = "app-mtp-api-dev-uks-001.azurewebsites.net",
            ["AllowedOrigins:0"] = "https://app-mtp-web-dev-uks-001.azurewebsites.net",
            ["ConnectionStrings:LgrDatabase"] = $"Server=tcp:sql-mtp-dev-uks-001.database.windows.net,1433;Database=sqldb-mtp-dev-uks-001;Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Managed Identity;User Id={identity}"
        };
        builder.Configuration.AddInMemoryCollection(values);
        return builder;
    }

    private static void ConfigureHostIdentity(
        WebApplicationBuilder builder,
        string slotName,
        string apiHost,
        string webHost)
    {
        builder.Configuration["AzureDemoHostIdentity:SlotName"] = slotName;
        builder.Configuration["AzureDemoHostIdentity:ApiResourceId"] = ResourceId(ApiAppName, slotName);
        builder.Configuration["AzureDemoHostIdentity:ApiDefaultHostName"] = apiHost;
        builder.Configuration["AzureDemoHostIdentity:WebResourceId"] = ResourceId(WebAppName, slotName);
        builder.Configuration["AzureDemoHostIdentity:WebDefaultHostName"] = webHost;
        builder.Configuration["AllowedHosts"] = apiHost;
        builder.Configuration["AllowedOrigins:0"] = $"https://{webHost}";
    }

    private static string ResourceId(string appName, string slotName)
    {
        var slotSuffix = slotName == "production" ? string.Empty : "/slots/staging";
        return $"/subscriptions/{SubscriptionId}/resourceGroups/{ResourceGroupName}" +
               $"/providers/Microsoft.Web/sites/{appName}{slotSuffix}";
    }

    private static WebApplicationBuilder Builder() => WebApplication.CreateBuilder(new WebApplicationOptions
    {
        EnvironmentName = "AzureDemo",
        ApplicationName = typeof(Program).Assembly.FullName,
        ContentRootPath = AppContext.BaseDirectory
    });
}
