using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Domain;
using LgrTransformationMigration.Api.Infrastructure;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace LgrTransformationMigration.Api.IntegrationTests;

public sealed class DependencyRegisterApiTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    [Fact]
    public async Task Register_feature_is_fail_closed_when_disabled()
    {
        using var factory = new LgrWebApplicationFactory();
        using var disabled = factory.WithWebHostBuilder(builder =>
            builder.ConfigureAppConfiguration((_, configuration) =>
                configuration.AddInMemoryCollection(new Dictionary<string, string?>
                {
                    ["Features:DependencyRegister"] = "false"
                })));
        using var client = disabled.CreateClient();
        LgrWebApplicationFactory.ApplySyntheticIdentity(client, "architect-project-a", SeedIds.DemoProject);

        var response = await client.GetAsync("/api/v1/dependencies");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        Assert.Equal("feature_disabled", await ErrorCodeAsync(response));
    }

    [Fact]
    public async Task Dependency_lists_reject_unknown_query_parameters()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateAuthenticatedClient("architect-project-a", SeedIds.DemoProject);

        var dependencyResponse = await client.GetAsync("/api/v1/dependencies?unexpected=true");
        var referenceResponse = await client.GetAsync("/api/v1/dependency-references?sort=Name");

        Assert.Equal(HttpStatusCode.BadRequest, dependencyResponse.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, referenceResponse.StatusCode);
        Assert.Equal("validation_failed", await ErrorCodeAsync(dependencyResponse));
        Assert.Equal("validation_failed", await ErrorCodeAsync(referenceResponse));
    }

    [Fact]
    public async Task Dependency_and_reference_lifecycle_is_audited_concurrent_and_directional()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateAuthenticatedClient("architect-project-a", SeedIds.DemoProject);
        var (applicationId, serverId) = await CanonicalEndpointsAsync(client);
        var (reference, referenceEtag) = await CreateReferenceAsync(client, "Unresolved");
        var (dependency, firstEtag) = await CreateDependencyAsync(
            client,
            new DependencyEndpointV1("Application", applicationId),
            new DependencyEndpointV1("DependencyReference", reference.Id),
            "NetworkConnectivity");

        Assert.Equal("Unconfirmed", dependency.ConfirmationStatus);
        Assert.Equal("DependsOn", dependency.DirectionLabel);
        Assert.Equal("Unresolved", dependency.Target.ResolutionStatus);
        Assert.Equal(HttpStatusCode.Conflict,
            (await PutAsync(client, $"/api/v1/dependencies/{dependency.Id}/confirmation",
                new DependencyConfirmationV1("Confirmed"), firstEtag)).StatusCode);

        var resolvedResponse = await PutAsync(
            client,
            $"/api/v1/dependency-references/{reference.Id}",
            new DependencyReferenceWriteV1("Api", "Synthetic payroll API", "Planning label only", "Resolved"),
            referenceEtag);
        Assert.Equal(HttpStatusCode.OK, resolvedResponse.StatusCode);
        var resolvedReference = await resolvedResponse.Content.ReadFromJsonAsync<DependencyReferenceDto>(JsonOptions);

        var confirmResponse = await PutAsync(
            client,
            $"/api/v1/dependencies/{dependency.Id}/confirmation",
            new DependencyConfirmationV1("Confirmed"),
            firstEtag);
        Assert.Equal(HttpStatusCode.OK, confirmResponse.StatusCode);
        var confirmed = await confirmResponse.Content.ReadFromJsonAsync<DependencyDto>(JsonOptions);
        var confirmedEtag = confirmResponse.Headers.ETag!.Tag;
        Assert.NotNull(confirmed!.ConfirmedAt);
        Assert.StartsWith("local-test:", confirmed.ConfirmedByDisplay, StringComparison.Ordinal);

        var stale = await PutAsync(
            client,
            $"/api/v1/dependencies/{dependency.Id}",
            new DependencyUpdateV1("NetworkConnectivity", "Advisory", "Changed", null),
            firstEtag);
        Assert.Equal(HttpStatusCode.PreconditionFailed, stale.StatusCode);
        Assert.Equal("stale_version", await ErrorCodeAsync(stale));

        var missingPrecondition = await client.PutAsJsonAsync(
            $"/api/v1/dependencies/{dependency.Id}",
            new DependencyUpdateV1("NetworkConnectivity", "Advisory", "Changed", null));
        Assert.Equal((HttpStatusCode)428, missingPrecondition.StatusCode);
        Assert.Equal("precondition_required", await ErrorCodeAsync(missingPrecondition));

        var updateResponse = await PutAsync(
            client,
            $"/api/v1/dependencies/{dependency.Id}",
            new DependencyUpdateV1("NetworkConnectivity", "Advisory", "Updated synthetic context", null),
            confirmedEtag);
        Assert.Equal(HttpStatusCode.OK, updateResponse.StatusCode);
        var updatedEtag = updateResponse.Headers.ETag!.Tag;
        var unconfirmResponse = await PutAsync(
            client,
            $"/api/v1/dependencies/{dependency.Id}/confirmation",
            new DependencyConfirmationV1("Unconfirmed"),
            updatedEtag);
        Assert.Equal(HttpStatusCode.OK, unconfirmResponse.StatusCode);
        var reconfirmResponse = await PutAsync(
            client,
            $"/api/v1/dependencies/{dependency.Id}/confirmation",
            new DependencyConfirmationV1("Confirmed"),
            unconfirmResponse.Headers.ETag!.Tag);
        Assert.Equal(HttpStatusCode.OK, reconfirmResponse.StatusCode);
        var currentDependencyEtag = reconfirmResponse.Headers.ETag!.Tag;

        var sourceView = await client.GetFromJsonAsync<PagedResult<DependencyDto>>(
            $"/api/v1/dependencies?assetType=Application&assetId={applicationId:D}&direction=DependsOn",
            JsonOptions);
        var targetView = await client.GetFromJsonAsync<PagedResult<DependencyDto>>(
            $"/api/v1/dependencies?assetType=DependencyReference&assetId={reference.Id:D}&direction=RequiredBy",
            JsonOptions);
        Assert.Contains(sourceView!.Items, x => x.Id == dependency.Id);
        Assert.Contains(targetView!.Items, x => x.Id == dependency.Id);

        var activeReferenceDelete = await DeleteAsync(
            client, $"/api/v1/dependency-references/{reference.Id}", resolvedResponse.Headers.ETag!.Tag);
        Assert.Equal(HttpStatusCode.Conflict, activeReferenceDelete.StatusCode);

        var audit = await client.GetFromJsonAsync<PagedResult<DependencyAuditEventDto>>(
            $"/api/v1/dependencies/{dependency.Id}/audit", JsonOptions);
        Assert.Contains(audit!.Items, x => x.Action == "DependencyCreated");
        Assert.Contains(audit.Items, x => x.Action == "DependencyConfirmed");
        Assert.Contains(audit.Items, x => x.Action == "DependencyUpdated");
        Assert.Contains(audit.Items, x => x.Action == "DependencyUnconfirmed");
        Assert.All(audit.Items, item =>
        {
            Assert.Null(item.OldValue);
            Assert.Null(item.NewValue);
            Assert.False(string.IsNullOrWhiteSpace(item.CorrelationId));
        });

        var dependencyDelete = await DeleteAsync(
            client, $"/api/v1/dependencies/{dependency.Id}", currentDependencyEtag);
        Assert.Equal(HttpStatusCode.NoContent, dependencyDelete.StatusCode);
        var referenceDelete = await DeleteAsync(
            client, $"/api/v1/dependency-references/{reference.Id}", resolvedResponse.Headers.ETag!.Tag);
        Assert.Equal(HttpStatusCode.NoContent, referenceDelete.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync($"/api/v1/dependencies/{dependency.Id}")).StatusCode);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var state = await db.DependencyGraphStates.IgnoreQueryFilters().SingleAsync(x => x.ProjectId == SeedIds.DemoProject);
        Assert.Equal(9, state.GraphVersion);
        Assert.NotNull(resolvedReference);
        Assert.NotEqual(serverId, Guid.Empty);
    }

    [Fact]
    public async Task All_four_canonical_asset_types_can_be_dependency_sources()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateAuthenticatedClient("dba-project-a", SeedIds.DemoProject);
        var (applicationId, serverId) = await CanonicalEndpointsAsync(client);
        var instanceResponse = await client.PostAsJsonAsync("/api/v1/sql-instances", new SqlInstanceWriteV1(
            serverId, "SYNTH-DEP", "SQL Server 2025", "Developer", 1433, "Running", null));
        Assert.Equal(HttpStatusCode.Created, instanceResponse.StatusCode);
        var instance = await instanceResponse.Content.ReadFromJsonAsync<SqlInstanceDto>(JsonOptions);
        var databaseResponse = await client.PostAsJsonAsync("/api/v1/sql-databases", new SqlDatabaseWriteV1(
            instance!.Id, "SyntheticDependencyDb", 128, 170, "Full", null, "Online"));
        Assert.Equal(HttpStatusCode.Created, databaseResponse.StatusCode);
        var database = await databaseResponse.Content.ReadFromJsonAsync<SqlDatabaseDto>(JsonOptions);

        await CreateDependencyAsync(client, new("Application", applicationId), new("Server", serverId), "Service");
        await CreateDependencyAsync(client, new("Server", serverId), new("Application", applicationId), "Service");
        await CreateDependencyAsync(client, new("SqlInstance", instance.Id), new("Server", serverId), "NetworkConnectivity");
        await CreateDependencyAsync(client, new("SqlDatabase", database!.Id), new("SqlInstance", instance.Id), "DataRead");

        var registered = await client.GetFromJsonAsync<PagedResult<DependencyDto>>(
            "/api/v1/dependencies?pageSize=200", JsonOptions);
        Assert.Equal(
            ["Application", "Server", "SqlDatabase", "SqlInstance"],
            registered!.Items.Select(x => x.Source.Type).Order(StringComparer.Ordinal).ToArray());
    }

    [Fact]
    public async Task Missing_self_duplicate_invalid_matrix_and_sensitive_text_are_rejected_without_partial_writes()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateAuthenticatedClient("architect-project-a", SeedIds.DemoProject);
        var (applicationId, serverId) = await CanonicalEndpointsAsync(client);

        var self = await client.PostAsJsonAsync("/api/v1/dependencies", Request(
            new("Application", applicationId), new("Application", applicationId), "Service"));
        Assert.Equal(HttpStatusCode.BadRequest, self.StatusCode);

        var missing = await client.PostAsJsonAsync("/api/v1/dependencies", Request(
            new("Application", applicationId), new("Server", Guid.NewGuid()), "Service"));
        Assert.Equal(HttpStatusCode.NotFound, missing.StatusCode);
        Assert.Equal("resource_not_found", await ErrorCodeAsync(missing));

        var invalidMatrix = await client.PostAsJsonAsync("/api/v1/dependencies", Request(
            new("Application", applicationId), new("Server", serverId), "DataRead"));
        Assert.Equal(HttpStatusCode.BadRequest, invalidMatrix.StatusCode);

        var sensitive = await client.PostAsJsonAsync("/api/v1/dependencies", Request(
            new("Application", applicationId), new("Server", serverId), "Service") with
        {
            Description = "Password=synthetic-do-not-store"
        });
        Assert.Equal(HttpStatusCode.BadRequest, sensitive.StatusCode);

        var (created, _) = await CreateDependencyAsync(
            client, new("Application", applicationId), new("Server", serverId), "Service");
        var duplicate = await client.PostAsJsonAsync("/api/v1/dependencies", Request(
            new("Application", applicationId), new("Server", serverId), "Service"));
        Assert.Equal(HttpStatusCode.Conflict, duplicate.StatusCode);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.Single(await db.Dependencies.IgnoreQueryFilters().Where(x => x.ProjectId == SeedIds.DemoProject).ToListAsync());
        Assert.Equal(created.Id, (await db.Dependencies.IgnoreQueryFilters().SingleAsync()).Id);
    }

    [Fact]
    public async Task Cross_project_and_cross_customer_endpoints_and_objects_are_non_enumerating()
    {
        using var factory = new LgrWebApplicationFactory();
        var (_, otherProjectServer) = await factory.SeedSecondProjectForDemoCustomerAsync();
        await factory.SeedSecondTenantAsync();
        using var client = factory.CreateAuthenticatedClient("architect-project-a", SeedIds.DemoProject);
        var (applicationId, serverId) = await CanonicalEndpointsAsync(client);

        foreach (var foreignServer in new[] { otherProjectServer, LgrWebApplicationFactory.SecondTenantServerId })
        {
            var response = await client.PostAsJsonAsync("/api/v1/dependencies", Request(
                new("Application", applicationId), new("Server", foreignServer), "Service"));
            Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
            Assert.Equal("resource_not_found", await ErrorCodeAsync(response));
        }

        var (dependency, _) = await CreateDependencyAsync(
            client, new("Application", applicationId), new("Server", serverId), "Service");
        using var otherProjectClient = factory.CreateAuthenticatedClient(
            "dba-project-a2", Guid.Parse("eeeeeeee-2222-2222-2222-222222222222"));
        var foreignGet = await otherProjectClient.GetAsync($"/api/v1/dependencies/{dependency.Id}");
        Assert.Equal(HttpStatusCode.NotFound, foreignGet.StatusCode);
        Assert.Equal("resource_not_found", await ErrorCodeAsync(foreignGet));
    }

    [Theory]
    [InlineData("architect-project-a", true, true, true, true)]
    [InlineData("dba-project-a", true, true, true, true)]
    [InlineData("manager-project-a", true, false, false, true)]
    [InlineData("analyst-project-a", true, false, false, false)]
    [InlineData("reader-project-a", true, false, false, true)]
    [InlineData("customer-admin", false, false, false, false)]
    [InlineData("platform-admin", false, false, false, false)]
    [InlineData("unknown-role", false, false, false, false)]
    public async Task Dependency_routes_enforce_the_exact_role_matrix(
        string alias,
        bool canRead,
        bool canManage,
        bool canConfirm,
        bool canAudit)
    {
        using var factory = new LgrWebApplicationFactory();
        Guid dependencyId;
        string etag;
        Guid applicationId;
        Guid serverId;
        using (var owner = factory.CreateAuthenticatedClient("architect-project-a", SeedIds.DemoProject))
        {
            (applicationId, serverId) = await CanonicalEndpointsAsync(owner);
            var created = await CreateDependencyAsync(owner, new("Application", applicationId), new("Server", serverId), "Service");
            dependencyId = created.Value.Id;
            etag = created.ETag;
        }
        using var client = factory.CreateAuthenticatedClient(alias, SeedIds.DemoProject);

        Assert.Equal(canRead ? HttpStatusCode.OK : HttpStatusCode.Forbidden,
            (await client.GetAsync("/api/v1/dependencies")).StatusCode);
        Assert.Equal(canManage ? HttpStatusCode.Created : HttpStatusCode.Forbidden,
            (await client.PostAsJsonAsync("/api/v1/dependencies", Request(
                new("Server", serverId), new("Application", applicationId), "Service"))).StatusCode);
        Assert.Equal(canConfirm ? HttpStatusCode.OK : HttpStatusCode.Forbidden,
            (await PutAsync(client, $"/api/v1/dependencies/{dependencyId}/confirmation",
                new DependencyConfirmationV1("Confirmed"), etag)).StatusCode);
        Assert.Equal(canAudit ? HttpStatusCode.OK : HttpStatusCode.Forbidden,
            (await client.GetAsync($"/api/v1/dependencies/{dependencyId}/audit")).StatusCode);
    }

    [Fact]
    public async Task Session_capabilities_include_dependency_permissions_without_disclosing_roles()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateAuthenticatedClient("manager-project-a", SeedIds.DemoProject);

        var capabilities = await client.GetFromJsonAsync<BrowserCapabilitiesDto>(
            "/api/v1/session/capabilities", JsonOptions);

        Assert.Contains("dependency.read", capabilities!.Permissions);
        Assert.Contains("dependency.validate", capabilities.Permissions);
        Assert.Contains("dependency.audit.read", capabilities.Permissions);
        Assert.DoesNotContain("dependency.manage", capabilities.Permissions);
        Assert.DoesNotContain("ProjectManager", capabilities.Permissions);
    }

    [Fact]
    public async Task New_projects_receive_the_default_policy_and_graph_state_without_breaking_empty_project_deletion()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateAuthenticatedClient("architect-project-a", SeedIds.DemoProject);
        var create = await client.PostAsJsonAsync("/api/projects", new ProjectRequest(
            "Synthetic dependency project", "Synthetic fixture", "Active", null, null));
        Assert.Equal(HttpStatusCode.Created, create.StatusCode);
        var project = await create.Content.ReadFromJsonAsync<ProjectDto>(JsonOptions);
        Assert.NotNull(project);
        var projectId = project.Id;

        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var policy = await db.DependencyPolicies.IgnoreQueryFilters().Include(x => x.Rules)
                .SingleAsync(x => x.ProjectId == projectId);
            Assert.Equal(DependencyPolicyDefaults.Version, policy.Version);
            Assert.Equal(DependencyPolicyDefaults.Rules.Length, policy.Rules.Count);
            Assert.True(policy.IsActive);
            Assert.NotNull(await db.DependencyGraphStates.IgnoreQueryFilters().SingleOrDefaultAsync(x => x.ProjectId == projectId));
        }

        var delete = await client.DeleteAsync($"/api/projects/{projectId}");
        Assert.Equal(HttpStatusCode.NoContent, delete.StatusCode);
        using var verificationScope = factory.Services.CreateScope();
        var verificationDb = verificationScope.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.False(await verificationDb.DependencyPolicies.IgnoreQueryFilters().AnyAsync(x => x.ProjectId == projectId));
        Assert.False(await verificationDb.DependencyGraphStates.IgnoreQueryFilters().AnyAsync(x => x.ProjectId == projectId));
    }

    private static DependencyCreateV1 Request(
        DependencyEndpointV1 source,
        DependencyEndpointV1 target,
        string type) => new(source, target, type, "Mandatory", "Synthetic planning dependency", "Synthetic business context");

    private static async Task<(Guid ApplicationId, Guid ServerId)> CanonicalEndpointsAsync(HttpClient client)
    {
        var applications = await client.GetFromJsonAsync<PagedResult<ApplicationDto>>("/api/applications?pageSize=1", JsonOptions);
        var servers = await client.GetFromJsonAsync<PagedResult<ServerDto>>("/api/servers?pageSize=1", JsonOptions);
        return (applications!.Items[0].Id, servers!.Items[0].Id);
    }

    private static async Task<(DependencyReferenceDto Value, string ETag)> CreateReferenceAsync(
        HttpClient client,
        string status)
    {
        var response = await client.PostAsJsonAsync(
            "/api/v1/dependency-references",
            new DependencyReferenceWriteV1("Api", "Synthetic payroll API", "Planning label only", status));
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        return ((await response.Content.ReadFromJsonAsync<DependencyReferenceDto>(JsonOptions))!, response.Headers.ETag!.Tag);
    }

    private static async Task<(DependencyDto Value, string ETag)> CreateDependencyAsync(
        HttpClient client,
        DependencyEndpointV1 source,
        DependencyEndpointV1 target,
        string type)
    {
        var response = await client.PostAsJsonAsync("/api/v1/dependencies", Request(source, target, type));
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        return ((await response.Content.ReadFromJsonAsync<DependencyDto>(JsonOptions))!, response.Headers.ETag!.Tag);
    }

    private static Task<HttpResponseMessage> PutAsync<T>(HttpClient client, string path, T body, string etag)
    {
        var request = new HttpRequestMessage(HttpMethod.Put, path) { Content = JsonContent.Create(body) };
        request.Headers.TryAddWithoutValidation("If-Match", etag);
        return client.SendAsync(request);
    }

    private static Task<HttpResponseMessage> DeleteAsync(HttpClient client, string path, string etag)
    {
        var request = new HttpRequestMessage(HttpMethod.Delete, path);
        request.Headers.TryAddWithoutValidation("If-Match", etag);
        return client.SendAsync(request);
    }

    private static async Task<string?> ErrorCodeAsync(HttpResponseMessage response)
    {
        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        return document.RootElement.GetProperty("errorCode").GetString();
    }
}
