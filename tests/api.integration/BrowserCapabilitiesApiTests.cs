using System.Net;
using System.Net.Http.Json;
using LgrTransformationMigration.Api.Domain;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;

namespace LgrTransformationMigration.Api.IntegrationTests;

public sealed class BrowserCapabilitiesApiTests
{
    [Theory]
    [InlineData("dba-project-a", "sql.inventory.create", "sql.discovery.commit", true)]
    [InlineData("analyst-project-a", "sql.discovery.commit", "sql.assessment.manage", false)]
    [InlineData("architect-project-a", "sql.assessment.plan", "sql.inventory.create", false)]
    [InlineData("reader-project-a", "sql.discovery.read", "sql.discovery.commit", false)]
    public async Task Capabilities_are_server_derived_for_the_active_membership(
        string alias,
        string allowed,
        string denied,
        bool dba)
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateAuthenticatedClient(alias, SeedIds.DemoProject);

        using var response = await client.GetAsync("/api/v1/session/capabilities");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var result = await response.Content.ReadFromJsonAsync<Capabilities>();
        Assert.NotNull(result);
        Assert.Contains(allowed, result.Permissions);
        Assert.DoesNotContain(denied, result.Permissions);
        Assert.Equal(dba, result.Permissions.Contains("sql.inventory.delete"));
        Assert.All(result.Permissions, permission => Assert.True(
            permission.StartsWith("sql.", StringComparison.Ordinal)
            || permission.StartsWith("dependency.", StringComparison.Ordinal),
            $"Unexpected browser permission family: {permission}"));
    }

    [Fact]
    public async Task Unknown_role_gets_no_sql_capabilities_and_cannot_widen_them_with_headers()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateAuthenticatedClient("unknown-role", SeedIds.DemoProject);
        client.DefaultRequestHeaders.Add("X-Permissions", "sql.inventory.create");

        using var response = await client.GetAsync("/api/v1/session/capabilities");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var result = await response.Content.ReadFromJsonAsync<Capabilities>();
        Assert.NotNull(result);
        Assert.Empty(result.Permissions);
    }

    [Fact]
    public async Task Browser_child_flag_is_default_deny_and_not_an_authorization_control()
    {
        using var factory = new LgrWebApplicationFactory();
        using var disabled = factory.WithWebHostBuilder(builder => builder.ConfigureAppConfiguration((_, configuration) =>
            configuration.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Features:SqlBrowserJourneys"] = "false"
            })));
        using var client = disabled.CreateClient();
        LgrWebApplicationFactory.ApplySyntheticIdentity(client, "dba-project-a", SeedIds.DemoProject);

        using var response = await client.GetAsync("/api/v1/session/capabilities");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        var problem = await response.Content.ReadFromJsonAsync<Problem>();
        Assert.Equal("feature_disabled", problem?.ErrorCode);
    }

    [Fact]
    public async Task Capabilities_require_authenticated_active_project_membership()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateUnauthenticatedClient();

        using var response = await client.GetAsync("/api/v1/session/capabilities");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    private sealed record Capabilities(IReadOnlyList<string> Permissions);
    private sealed record Problem(string ErrorCode);
}
