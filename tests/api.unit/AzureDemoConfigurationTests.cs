using LgrTransformationMigration.Api.Infrastructure;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Configuration;

namespace LgrTransformationMigration.Api.UnitTests;

public sealed class AzureDemoConfigurationTests
{
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
            "Server=tcp:sql-lgrtm-azdemo-uks-demo.database.windows.net,1433;Database=sqldb-lgrtm-azdemo;Encrypt=True;TrustServerCertificate=True;User ID=demo;Password=prohibited";

        var error = Assert.Throws<InvalidOperationException>(() => AzureDemoStartupGuard.Validate(builder));

        Assert.Contains("passwordless", error.Message, StringComparison.Ordinal);
    }

    [Fact]
    public void AzureDemo_accepts_complete_Entra_UAMI_private_service_configuration()
    {
        var builder = CompleteBuilder();

        AzureDemoStartupGuard.Validate(builder);
    }

    [Theory]
    [InlineData("Authentication:Entra:Issuer", "https://login.microsoftonline.com/common/v2.0")]
    [InlineData("Authentication:Entra:Audience", "api://not-a-guid")]
    [InlineData("Authentication:Entra:AllowedClientIds:0", "")]
    [InlineData("Authentication:EntraDemoMemberships:SecretUri", "https://kvlgrtmazddemo.vault.azure.net/secrets/other")]
    [InlineData("Authentication:EntraDemoMemberships:CacheSeconds", "301")]
    [InlineData("DiscoveryImport:StorageAccountUri", "https://stlgrtmazddemo.blob.core.windows.net/other")]
    [InlineData("DiscoveryImport:ContainerName", "other")]
    public void AzureDemo_rejects_inexact_identity_and_storage_configuration(string key, string value)
    {
        var builder = CompleteBuilder();
        builder.Configuration[key] = value;

        Assert.Throws<InvalidOperationException>(() => AzureDemoStartupGuard.Validate(builder));
    }

    [Theory]
    [InlineData("Server=tcp:other.database.windows.net,1433;Database=sqldb-lgrtm-azdemo;Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Managed Identity;User Id=aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")]
    [InlineData("Server=tcp:sql-lgrtm-azdemo-uks-demo.database.windows.net,1433;Database=other;Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Managed Identity;User Id=aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")]
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
            ["Authentication:EntraDemoMemberships:SecretUri"] = "https://kvlgrtmazddemo.vault.azure.net/secrets/entra-demo-memberships",
            ["Authentication:EntraDemoMemberships:CacheSeconds"] = "300",
            ["AzureIdentity:ManagedIdentityClientId"] = identity,
            ["DiscoveryImport:StorageMode"] = "AzureBlob",
            ["DiscoveryImport:StorageAccountUri"] = "https://stlgrtmazddemo.blob.core.windows.net",
            ["DiscoveryImport:ContainerName"] = "discovery-imports",
            ["DemoData:Enabled"] = "false",
            ["AllowedHosts"] = "app-lgrtm-api-azdemo-uks-demo.azurewebsites.net",
            ["AllowedOrigins:0"] = "https://app-lgrtm-web-azdemo-uks-demo.azurewebsites.net",
            ["ConnectionStrings:LgrDatabase"] = $"Server=tcp:sql-lgrtm-azdemo-uks-demo.database.windows.net,1433;Database=sqldb-lgrtm-azdemo;Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Managed Identity;User Id={identity}"
        };
        builder.Configuration.AddInMemoryCollection(values);
        return builder;
    }

    private static WebApplicationBuilder Builder() => WebApplication.CreateBuilder(new WebApplicationOptions
    {
        EnvironmentName = "AzureDemo",
        ApplicationName = typeof(Program).Assembly.FullName,
        ContentRootPath = AppContext.BaseDirectory
    });
}
