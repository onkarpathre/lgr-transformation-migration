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
}
