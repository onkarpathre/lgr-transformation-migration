using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using System.Net;

namespace LgrTransformationMigration.Api.IntegrationTests;

public sealed class GeneratedHostnameSecurityTests
{
    private const string ProductionApiHost = "api-mtp-generated-7f3a.azurewebsites.net";
    private const string StagingApiHost = "api-mtp-generated-7f3a-staging.azurewebsites.net";
    private const string ProductionWebOrigin = "https://web-mtp-generated-91bd.azurewebsites.net";
    private const string StagingWebOrigin = "https://web-mtp-generated-91bd-staging.azurewebsites.net";
    private const string AzureDemoStagingApiHost =
        "app-mtp-api-dev-uks-001-staging-athrc5epbzcdetb8.uksouth-01.azurewebsites.net";
    private const string AzureDemoStagingWebHost =
        "app-mtp-web-dev-uks-001-staging-csdtetbtbeh3h7fy.uksouth-01.azurewebsites.net";

    [Fact]
    public async Task Actual_AzureDemo_application_startup_accepts_Azure_reported_generated_staging_hosts()
    {
        using var factory = new AzureDemoStartupFactory();
        using var client = factory.CreateClient(new WebApplicationFactoryClientOptions
        {
            AllowAutoRedirect = false,
            BaseAddress = new Uri($"https://{AzureDemoStagingApiHost}")
        });

        using var response = await client.GetAsync("/health/live");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Theory]
    [InlineData(ProductionApiHost, ProductionWebOrigin, StagingApiHost, StagingWebOrigin)]
    [InlineData(StagingApiHost, StagingWebOrigin, ProductionApiHost, ProductionWebOrigin)]
    public async Task Exact_environment_host_and_origin_are_allowed_while_other_environment_is_rejected(
        string allowedHost,
        string allowedOrigin,
        string unrelatedHost,
        string unrelatedOrigin)
    {
        using var baseFactory = new LgrWebApplicationFactory();
        using var factory = ConfigureHostAndOrigin(baseFactory, allowedHost, allowedOrigin);
        using var client = factory.CreateClient(new WebApplicationFactoryClientOptions
        {
            AllowAutoRedirect = false,
            BaseAddress = new Uri("https://localhost")
        });

        using var allowedHostRequest = Request(allowedHost);
        using var allowedHostResponse = await client.SendAsync(allowedHostRequest);
        Assert.Equal(HttpStatusCode.OK, allowedHostResponse.StatusCode);

        using var unrelatedHostRequest = Request(unrelatedHost);
        using var unrelatedHostResponse = await client.SendAsync(unrelatedHostRequest);
        Assert.Equal(HttpStatusCode.BadRequest, unrelatedHostResponse.StatusCode);

        using var allowedOriginRequest = Request(allowedHost, allowedOrigin);
        using var allowedOriginResponse = await client.SendAsync(allowedOriginRequest);
        Assert.Equal(HttpStatusCode.OK, allowedOriginResponse.StatusCode);
        Assert.Equal(allowedOrigin, Header(allowedOriginResponse, "Access-Control-Allow-Origin"));

        using var unrelatedOriginRequest = Request(allowedHost, unrelatedOrigin);
        using var unrelatedOriginResponse = await client.SendAsync(unrelatedOriginRequest);
        Assert.Equal(HttpStatusCode.OK, unrelatedOriginResponse.StatusCode);
        Assert.Null(Header(unrelatedOriginResponse, "Access-Control-Allow-Origin"));
    }

    [Fact]
    public async Task Forwarded_host_cannot_bypass_the_exact_host_allowlist()
    {
        using var baseFactory = new LgrWebApplicationFactory();
        using var factory = ConfigureHostAndOrigin(baseFactory, ProductionApiHost, ProductionWebOrigin);
        using var client = factory.CreateClient(new WebApplicationFactoryClientOptions
        {
            AllowAutoRedirect = false,
            BaseAddress = new Uri("https://localhost")
        });
        using var request = Request("unrelated.example");
        request.Headers.TryAddWithoutValidation("X-Forwarded-Host", ProductionApiHost);

        using var response = await client.SendAsync(request);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    private static WebApplicationFactory<Program> ConfigureHostAndOrigin(
        LgrWebApplicationFactory factory,
        string allowedHost,
        string allowedOrigin) =>
        factory.WithWebHostBuilder(builder =>
        {
            builder.UseSetting("AllowedHosts", allowedHost);
            builder.UseSetting("AllowedOrigins:0", allowedOrigin);
        });

    private static HttpRequestMessage Request(string host, string? origin = null)
    {
        var request = new HttpRequestMessage(HttpMethod.Get, "/health/live");
        request.Headers.Host = host;
        if (origin is not null)
        {
            request.Headers.TryAddWithoutValidation("Origin", origin);
        }

        return request;
    }

    private static string? Header(HttpResponseMessage response, string name) =>
        response.Headers.TryGetValues(name, out var values) ? Assert.Single(values) : null;

    private sealed class AzureDemoStartupFactory : WebApplicationFactory<Program>
    {
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            const string identity = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
            builder.UseEnvironment("AzureDemo");
            foreach (var setting in new Dictionary<string, string>
            {
                ["Authentication:Mode"] = "Entra",
                ["Authentication:Entra:TenantId"] = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                ["Authentication:Entra:Issuer"] = "https://login.microsoftonline.com/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/v2.0",
                ["Authentication:Entra:Audience"] = "api://cccccccc-cccc-cccc-cccc-cccccccccccc",
                ["Authentication:Entra:AllowedClientIds:0"] = "dddddddd-dddd-dddd-dddd-dddddddddddd",
                ["Authentication:EntraDemoMemberships:SecretUri"] = "https://kv-mtp-dev-uks-op01.vault.azure.net/secrets/entra-demo-memberships",
                ["Authentication:EntraDemoMemberships:CacheSeconds"] = "300",
                ["AzureIdentity:ManagedIdentityClientId"] = identity,
                ["AzureDemoHostIdentity:SlotName"] = "staging",
                ["AzureDemoHostIdentity:ApiResourceId"] = "/subscriptions/633398e2-6c00-4bb7-a576-2db0d210ee77/resourceGroups/Onkar.Pathre/providers/Microsoft.Web/sites/app-mtp-api-dev-uks-001/slots/staging",
                ["AzureDemoHostIdentity:ApiDefaultHostName"] = AzureDemoStagingApiHost,
                ["AzureDemoHostIdentity:WebResourceId"] = "/subscriptions/633398e2-6c00-4bb7-a576-2db0d210ee77/resourceGroups/Onkar.Pathre/providers/Microsoft.Web/sites/app-mtp-web-dev-uks-001/slots/staging",
                ["AzureDemoHostIdentity:WebDefaultHostName"] = AzureDemoStagingWebHost,
                ["DiscoveryImport:StorageMode"] = "AzureBlob",
                ["DiscoveryImport:StorageAccountUri"] = "https://stmtpdevuks001.blob.core.windows.net",
                ["DiscoveryImport:ContainerName"] = "discovery-imports",
                ["DemoData:Enabled"] = "false",
                ["AllowedHosts"] = AzureDemoStagingApiHost,
                ["AllowedOrigins:0"] = $"https://{AzureDemoStagingWebHost}",
                ["ConnectionStrings:LgrDatabase"] = $"Server=tcp:sql-mtp-dev-uks-001.database.windows.net,1433;Database=sqldb-mtp-dev-uks-001;Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Managed Identity;User Id={identity}"
            })
            {
                builder.UseSetting(setting.Key, setting.Value);
            }
        }
    }
}
