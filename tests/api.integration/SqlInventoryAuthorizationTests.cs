using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Claims;
using System.Text.Json;
using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Domain;
using LgrTransformationMigration.Api.Infrastructure;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;

namespace LgrTransformationMigration.Api.IntegrationTests;

public sealed class SqlInventoryAuthorizationTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public static TheoryData<string, bool, bool> RoleMatrix => new()
    {
        { "dba-project-a", true, true },
        { "architect-project-a", true, false },
        { "manager-project-a", true, false },
        { "analyst-project-a", true, false },
        { "reader-project-a", true, false },
        { "multi-role-project-a", true, false },
        { "customer-admin", false, false },
        { "platform-admin", false, false },
        { "unknown-role", false, false }
    };

    public static TheoryData<HttpMethod, string> SqlRoutes => new()
    {
        { HttpMethod.Get, "/api/v1/sql-instances" },
        { HttpMethod.Get, $"/api/v1/sql-instances/{Guid.Parse("40000000-0000-0000-0000-000000000001")}" },
        { HttpMethod.Post, "/api/v1/sql-instances" },
        { HttpMethod.Put, $"/api/v1/sql-instances/{Guid.Parse("40000000-0000-0000-0000-000000000001")}" },
        { HttpMethod.Delete, $"/api/v1/sql-instances/{Guid.Parse("40000000-0000-0000-0000-000000000001")}" },
        { HttpMethod.Get, "/api/v1/sql-databases" },
        { HttpMethod.Get, $"/api/v1/sql-databases/{Guid.Parse("40000000-0000-0000-0000-000000000002")}" },
        { HttpMethod.Post, "/api/v1/sql-databases" },
        { HttpMethod.Put, $"/api/v1/sql-databases/{Guid.Parse("40000000-0000-0000-0000-000000000002")}" },
        { HttpMethod.Delete, $"/api/v1/sql-databases/{Guid.Parse("40000000-0000-0000-0000-000000000002")}" }
    };

    [Theory]
    [MemberData(nameof(RoleMatrix))]
    public async Task Every_sql_instance_and_database_method_enforces_the_exact_role_matrix(
        string alias,
        bool canRead,
        bool canWrite)
    {
        using var factory = new LgrWebApplicationFactory();
        var fixture = await CreateInventoryFixtureAsync(factory);
        using var client = factory.CreateAuthenticatedClient(alias, SeedIds.DemoProject);

        var responses = new Dictionary<string, HttpResponseMessage>
        {
            ["instance-list"] = await client.GetAsync("/api/v1/sql-instances"),
            ["instance-detail"] = await client.GetAsync($"/api/v1/sql-instances/{fixture.Instance.Id}"),
            ["database-list"] = await client.GetAsync("/api/v1/sql-databases"),
            ["database-detail"] = await client.GetAsync($"/api/v1/sql-databases/{fixture.Database.Id}"),
            ["instance-create"] = await client.PostAsJsonAsync(
                "/api/v1/sql-instances",
                InstanceRequest(fixture.ServerId, $"CREATE-{alias}")),
            ["database-create"] = await client.PostAsJsonAsync(
                "/api/v1/sql-databases",
                DatabaseRequest(fixture.ParentInstance.Id, $"Create-{alias}")),
            ["instance-update"] = await SendWithIfMatchAsync(
                client,
                HttpMethod.Put,
                $"/api/v1/sql-instances/{fixture.Instance.Id}",
                InstanceRequest(fixture.ServerId, fixture.Instance.InstanceName),
                fixture.InstanceTag),
            ["database-update"] = await SendWithIfMatchAsync(
                client,
                HttpMethod.Put,
                $"/api/v1/sql-databases/{fixture.Database.Id}",
                DatabaseRequest(fixture.ParentInstance.Id, fixture.Database.Name),
                fixture.DatabaseTag),
            ["database-delete"] = await SendWithIfMatchAsync(
                client,
                HttpMethod.Delete,
                $"/api/v1/sql-databases/{fixture.Database.Id}",
                null,
                fixture.DatabaseTag),
            ["instance-delete"] = await SendWithIfMatchAsync(
                client,
                HttpMethod.Delete,
                $"/api/v1/sql-instances/{fixture.Instance.Id}",
                null,
                fixture.InstanceTag)
        };

        Assert.Equal(canRead ? HttpStatusCode.OK : HttpStatusCode.Forbidden, responses["instance-list"].StatusCode);
        Assert.Equal(canRead ? HttpStatusCode.OK : HttpStatusCode.Forbidden, responses["instance-detail"].StatusCode);
        Assert.Equal(canRead ? HttpStatusCode.OK : HttpStatusCode.Forbidden, responses["database-list"].StatusCode);
        Assert.Equal(canRead ? HttpStatusCode.OK : HttpStatusCode.Forbidden, responses["database-detail"].StatusCode);
        Assert.Equal(canWrite ? HttpStatusCode.Created : HttpStatusCode.Forbidden, responses["instance-create"].StatusCode);
        Assert.Equal(canWrite ? HttpStatusCode.Created : HttpStatusCode.Forbidden, responses["database-create"].StatusCode);
        Assert.Equal(canWrite ? HttpStatusCode.OK : HttpStatusCode.Forbidden, responses["instance-update"].StatusCode);
        Assert.Equal(canWrite ? HttpStatusCode.OK : HttpStatusCode.Forbidden, responses["database-update"].StatusCode);
        Assert.Equal(canWrite ? HttpStatusCode.NoContent : HttpStatusCode.Forbidden, responses["database-delete"].StatusCode);
        Assert.Equal(canWrite ? HttpStatusCode.NoContent : HttpStatusCode.Forbidden, responses["instance-delete"].StatusCode);

        foreach (var response in responses.Values.Where(response => response.StatusCode == HttpStatusCode.Forbidden))
        {
            await AssertProblemDetailsAsync(response, HttpStatusCode.Forbidden, "permission_denied");
        }

        foreach (var response in responses.Values)
        {
            response.Dispose();
        }
    }

    [Theory]
    [MemberData(nameof(SqlRoutes))]
    public async Task Unauthenticated_requests_receive_safe_401_on_every_sql_route(HttpMethod method, string route)
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateUnauthenticatedClient();
        using var request = new HttpRequestMessage(method, route);
        if (method == HttpMethod.Post || method == HttpMethod.Put)
        {
            request.Content = JsonContent.Create(new { });
        }

        using var response = await client.SendAsync(request);

        await AssertProblemDetailsAsync(response, HttpStatusCode.Unauthorized, "authentication_required");
        Assert.Contains("Bearer", response.Headers.WwwAuthenticate.Select(value => value.Scheme));
    }

    [Fact]
    public async Task Authentication_challenge_precedes_project_authorization()
    {
        using var factory = new LgrWebApplicationFactory();
        using var anonymous = factory.CreateUnauthenticatedClient();
        using var anonymousResponse = await anonymous.GetAsync("/api/v1/sql-instances");

        using var authenticatedWithoutProject = factory.CreateUnauthenticatedClient();
        authenticatedWithoutProject.DefaultRequestHeaders.Add("X-Lgr-Test-Principal", "dba-project-a");
        using var missingProjectResponse = await authenticatedWithoutProject.GetAsync("/api/v1/sql-instances");

        await AssertProblemDetailsAsync(
            anonymousResponse,
            HttpStatusCode.Unauthorized,
            "authentication_required");
        await AssertProblemDetailsAsync(
            missingProjectResponse,
            HttpStatusCode.BadRequest,
            "project_context_required");
    }

    [Theory]
    [InlineData("unassigned")]
    [InlineData("disabled")]
    [InlineData("disabled-principal")]
    [InlineData("expired")]
    [InlineData("not-yet-valid")]
    public async Task Missing_disabled_or_out_of_window_membership_is_non_enumerating_404(string alias)
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateAuthenticatedClient(alias, SeedIds.DemoProject);

        using var response = await client.GetAsync("/api/v1/sql-instances");

        await AssertProblemDetailsAsync(response, HttpStatusCode.NotFound, "resource_not_found");
    }

    [Theory]
    [InlineData(null, "project_context_required")]
    [InlineData("not-a-guid", "invalid_project_context")]
    [InlineData("00000000-0000-0000-0000-000000000000", "invalid_project_context")]
    public async Task Missing_or_malformed_project_selector_is_safe_400(string? projectId, string errorCode)
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateUnauthenticatedClient();
        client.DefaultRequestHeaders.Add("X-Lgr-Test-Principal", "dba-project-a");
        if (projectId is not null)
        {
            client.DefaultRequestHeaders.Add("X-Project-Id", projectId);
        }

        using var response = await client.GetAsync("/api/v1/sql-instances");

        await AssertProblemDetailsAsync(response, HttpStatusCode.BadRequest, errorCode);
    }

    [Theory]
    [InlineData("arbitrary-alias")]
    [InlineData("11111111-1111-1111-1111-111111111111")]
    [InlineData("DatabaseSme")]
    [InlineData("someone@example.test")]
    public async Task LocalTest_rejects_every_non_allow_list_identity_value(string alias)
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateUnauthenticatedClient();
        client.DefaultRequestHeaders.Add("X-Lgr-Test-Principal", alias);
        client.DefaultRequestHeaders.Add("X-Project-Id", SeedIds.DemoProject.ToString("D"));

        using var response = await client.GetAsync("/api/v1/sql-instances");

        await AssertProblemDetailsAsync(response, HttpStatusCode.Unauthorized, "authentication_required");
    }

    [Fact]
    public async Task Role_permission_customer_and_user_headers_cannot_widen_a_read_only_membership()
    {
        using var factory = new LgrWebApplicationFactory();
        using var verifier = factory.CreateClient();
        var serverId = await ServerIdAsync(verifier);
        using var client = factory.CreateAuthenticatedClient("reader-project-a", SeedIds.DemoProject);
        client.DefaultRequestHeaders.Add("X-Customer-Id", Guid.NewGuid().ToString("D"));
        client.DefaultRequestHeaders.Add("X-User-Name", "forged-user");
        client.DefaultRequestHeaders.Add("X-Principal-Id", Guid.NewGuid().ToString("D"));
        client.DefaultRequestHeaders.Add("X-Roles", "DatabaseSme");
        client.DefaultRequestHeaders.Add("X-Project-Roles", "DatabaseSme");
        client.DefaultRequestHeaders.Add("X-Permissions", "sql.inventory.create");

        using var response = await client.PostAsJsonAsync(
            "/api/v1/sql-instances",
            InstanceRequest(serverId, "FORGED-AUTHORITY"));

        await AssertProblemDetailsAsync(response, HttpStatusCode.Forbidden, "permission_denied");
        var inventory = await verifier.GetFromJsonAsync<PagedResult<SqlInstanceDto>>(
            "/api/v1/sql-instances?search=FORGED-AUTHORITY",
            JsonOptions);
        Assert.Empty(inventory!.Items);
    }

    [Fact]
    public async Task Spoofed_customer_header_has_no_effect_on_server_derived_scope()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateClient();
        var serverId = await ServerIdAsync(client);
        await CreateInstanceAsync(client, serverId, "SERVER-DERIVED-SCOPE");
        client.DefaultRequestHeaders.Add("X-Customer-Id", Guid.NewGuid().ToString("D"));

        var response = await client.GetFromJsonAsync<PagedResult<SqlInstanceDto>>(
            "/api/v1/sql-instances",
            JsonOptions);

        var item = Assert.Single(response!.Items);
        Assert.Equal(SeedIds.DemoCustomer, item.CustomerId);
    }

    [Fact]
    public async Task Project_selection_derives_customer_and_rejects_cross_customer_or_project_membership()
    {
        using var factory = new LgrWebApplicationFactory();
        var other = await factory.SeedSecondTenantAsync();
        using var client = factory.CreateAuthenticatedClient("dba-project-a", other.ProjectId);
        client.DefaultRequestHeaders.Add("X-Customer-Id", other.CustomerId.ToString("D"));

        using var response = await client.GetAsync("/api/v1/sql-instances");

        await AssertProblemDetailsAsync(response, HttpStatusCode.NotFound, "resource_not_found");
    }

    [Fact]
    public async Task Membership_authority_failure_returns_safe_503_without_fallback()
    {
        using var factory = new LgrWebApplicationFactory();
        using var unavailableFactory = factory.WithWebHostBuilder(builder =>
            builder.ConfigureServices(services =>
            {
                services.RemoveAll<IProjectMembershipProvider>();
                services.AddSingleton<IProjectMembershipProvider, UnavailableProjectMembershipProvider>();
            }));
        using var client = unavailableFactory.CreateClient();
        LgrWebApplicationFactory.ApplySyntheticIdentity(client, "dba-project-a", SeedIds.DemoProject);

        using var response = await client.GetAsync("/api/v1/sql-instances");

        await AssertProblemDetailsAsync(response, HttpStatusCode.ServiceUnavailable, "authorization_unavailable");
    }

    [Fact]
    public async Task Membership_revocation_is_revalidated_without_a_stale_authorization_cache()
    {
        using var factory = new LgrWebApplicationFactory();
        var membership = new RevocableMembershipProvider();
        using var revocableFactory = factory.WithWebHostBuilder(builder =>
            builder.ConfigureServices(services =>
            {
                services.RemoveAll<IProjectMembershipProvider>();
                services.AddSingleton<IProjectMembershipProvider>(membership);
            }));
        using var client = revocableFactory.CreateClient();
        LgrWebApplicationFactory.ApplySyntheticIdentity(client, "reader-project-a", SeedIds.DemoProject);

        using var allowed = await client.GetAsync("/api/v1/sql-instances");
        membership.Revoke();
        using var revoked = await client.GetAsync("/api/v1/sql-instances");

        Assert.Equal(HttpStatusCode.OK, allowed.StatusCode);
        await AssertProblemDetailsAsync(revoked, HttpStatusCode.NotFound, "resource_not_found");
    }

    [Fact]
    public async Task Missing_and_inaccessible_sql_entities_have_the_same_non_enumerating_404_contract()
    {
        using var factory = new LgrWebApplicationFactory();
        var other = await factory.SeedSecondTenantAsync();
        using var otherClient = factory.CreateAuthenticatedClient("dba-project-b", other.ProjectId);
        var otherServer = LgrWebApplicationFactory.SecondTenantServerId;
        var (otherInstance, _) = await CreateInstanceAsync(otherClient, otherServer, "INACCESSIBLE");
        using var demo = factory.CreateClient();

        using var inaccessible = await demo.GetAsync($"/api/v1/sql-instances/{otherInstance.Id}");
        using var missing = await demo.GetAsync($"/api/v1/sql-instances/{Guid.NewGuid()}");

        var inaccessibleProblem = await AssertProblemDetailsAsync(
            inaccessible,
            HttpStatusCode.NotFound,
            "resource_not_found");
        var missingProblem = await AssertProblemDetailsAsync(missing, HttpStatusCode.NotFound, "resource_not_found");
        Assert.Equal(missingProblem.GetProperty("title").GetString(), inaccessibleProblem.GetProperty("title").GetString());
        Assert.Equal(missingProblem.GetProperty("detail").GetString(), inaccessibleProblem.GetProperty("detail").GetString());
    }

    [Fact]
    public async Task Cross_customer_and_cross_project_databases_are_non_enumerating_for_detail_and_mutation()
    {
        using var factory = new LgrWebApplicationFactory();
        var otherCustomer = await factory.SeedSecondTenantAsync();
        using var otherCustomerClient = factory.CreateAuthenticatedClient("dba-project-b", otherCustomer.ProjectId);
        var (otherCustomerInstance, _) = await CreateInstanceAsync(
            otherCustomerClient,
            LgrWebApplicationFactory.SecondTenantServerId,
            "DATABASE-CUSTOMER-PARENT");
        var (otherCustomerDatabase, otherCustomerTag) = await CreateDatabaseAsync(
            otherCustomerClient,
            otherCustomerInstance.Id,
            "OtherCustomerDatabase");

        var otherProject = await factory.SeedSecondProjectForDemoCustomerAsync();
        using var otherProjectClient = factory.CreateAuthenticatedClient("dba-project-a2", otherProject.ProjectId);
        var (otherProjectInstance, _) = await CreateInstanceAsync(
            otherProjectClient,
            otherProject.ServerId,
            "DATABASE-PROJECT-PARENT");
        var (otherProjectDatabase, otherProjectTag) = await CreateDatabaseAsync(
            otherProjectClient,
            otherProjectInstance.Id,
            "OtherProjectDatabase");

        using var demo = factory.CreateClient();
        using var missing = await demo.GetAsync($"/api/v1/sql-databases/{Guid.NewGuid()}");
        var missingProblem = await AssertProblemDetailsAsync(
            missing,
            HttpStatusCode.NotFound,
            "resource_not_found");

        foreach (var (database, tag) in new[]
                 {
                     (otherCustomerDatabase, otherCustomerTag),
                     (otherProjectDatabase, otherProjectTag)
                 })
        {
            using var detail = await demo.GetAsync($"/api/v1/sql-databases/{database.Id}");
            var inaccessibleProblem = await AssertProblemDetailsAsync(
                detail,
                HttpStatusCode.NotFound,
                "resource_not_found");
            Assert.Equal(
                missingProblem.GetProperty("title").GetString(),
                inaccessibleProblem.GetProperty("title").GetString());
            Assert.Equal(
                missingProblem.GetProperty("detail").GetString(),
                inaccessibleProblem.GetProperty("detail").GetString());

            using var update = await SendWithIfMatchAsync(
                demo,
                HttpMethod.Put,
                $"/api/v1/sql-databases/{database.Id}",
                DatabaseRequest(database.SqlInstance.Id, database.Name),
                tag);
            await AssertProblemDetailsAsync(update, HttpStatusCode.NotFound, "resource_not_found");

            using var archive = await SendWithIfMatchAsync(
                demo,
                HttpMethod.Delete,
                $"/api/v1/sql-databases/{database.Id}",
                null,
                tag);
            await AssertProblemDetailsAsync(archive, HttpStatusCode.NotFound, "resource_not_found");
        }

        var customerList = await demo.GetFromJsonAsync<PagedResult<SqlDatabaseDto>>(
            "/api/v1/sql-databases?search=OtherCustomerDatabase",
            JsonOptions);
        var projectList = await demo.GetFromJsonAsync<PagedResult<SqlDatabaseDto>>(
            "/api/v1/sql-databases?search=OtherProjectDatabase",
            JsonOptions);
        Assert.Empty(customerList!.Items);
        Assert.Empty(projectList!.Items);
    }

    [Fact]
    public async Task Sql_mutation_audit_uses_stable_principal_identity_type_scope_and_correlation()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateClient();
        var serverId = await ServerIdAsync(client);

        var response = await client.PostAsJsonAsync(
            "/api/v1/sql-instances",
            InstanceRequest(serverId, "STABLE-ACTOR"));
        response.EnsureSuccessStatusCode();
        var created = (await response.Content.ReadFromJsonAsync<SqlInstanceDto>(JsonOptions))!;
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var audit = await db.AuditEvents.IgnoreQueryFilters().SingleAsync(x =>
            x.EntityId == created.Id && x.Action == "SqlInstanceCreated");

        Assert.Equal("local-test:70000000-0000-0000-0000-000000000001", audit.ChangedBy);
        Assert.Equal(nameof(InternalPrincipalType.Human), audit.ActorPrincipalType);
        Assert.Equal(SeedIds.DemoCustomer, audit.CustomerId);
        Assert.Equal(SeedIds.DemoProject, audit.ProjectId);
        Assert.False(string.IsNullOrWhiteSpace(audit.CorrelationId));
        Assert.Equal(TimeSpan.Zero, audit.ChangedAt.Offset);
    }

    [Fact]
    public async Task Fallback_policy_protects_phase_one_and_two_routes_while_health_is_explicitly_anonymous()
    {
        using var factory = new LgrWebApplicationFactory();
        using var anonymous = factory.CreateUnauthenticatedClient();
        using var protectedResponse = await anonymous.GetAsync("/api/dashboard/summary");
        using var healthResponse = await anonymous.GetAsync("/health");
        using var authorized = factory.CreateClient();
        using var regressionResponse = await authorized.GetAsync("/api/dashboard/summary");

        await AssertProblemDetailsAsync(protectedResponse, HttpStatusCode.Unauthorized, "authentication_required");
        Assert.Equal(HttpStatusCode.OK, healthResponse.StatusCode);
        Assert.Equal(HttpStatusCode.OK, regressionResponse.StatusCode);
    }

    [Fact]
    public void Production_like_environment_fails_startup_when_LocalTest_is_selected()
    {
        using var factory = new ProductionLikeWebApplicationFactory(InternalAuthenticationDefaults.LocalTestMode);

        var exception = Assert.ThrowsAny<Exception>(() => factory.CreateClient());

        Assert.Contains("LocalTest is prohibited outside Development and Testing", exception.ToString());
    }

    [Fact]
    public void Production_like_environment_fails_startup_when_Entra_configuration_is_incomplete()
    {
        using var factory = new ProductionLikeWebApplicationFactory(InternalAuthenticationDefaults.EntraMode, completeEntra: false);

        var exception = Assert.ThrowsAny<Exception>(() => factory.CreateClient());

        Assert.Contains("Authentication:Entra:TenantId is required", exception.ToString());
    }

    [Fact]
    public async Task Production_identity_headers_are_ignored_and_bearer_failure_never_falls_back()
    {
        using var factory = new ProductionLikeWebApplicationFactory(InternalAuthenticationDefaults.EntraMode);
        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-Lgr-Test-Principal", "dba-project-a");
        client.DefaultRequestHeaders.Add("X-Customer-Id", SeedIds.DemoCustomer.ToString("D"));
        client.DefaultRequestHeaders.Add("X-User-Name", "forged-user");
        client.DefaultRequestHeaders.Add("X-Principal-Id", Guid.NewGuid().ToString("D"));
        client.DefaultRequestHeaders.Add("X-Roles", "DatabaseSme");
        client.DefaultRequestHeaders.Add("X-Project-Roles", "DatabaseSme");
        client.DefaultRequestHeaders.Add("X-Permissions", "sql.inventory.read");
        client.DefaultRequestHeaders.Add("X-Project-Id", SeedIds.DemoProject.ToString("D"));

        using var response = await client.GetAsync("/api/v1/sql-instances");

        await AssertProblemDetailsAsync(response, HttpStatusCode.Unauthorized, "authentication_required");
    }

    [Theory]
    [InlineData("valid", "permission_denied")]
    [InlineData("missing-scope", "api_access_denied")]
    [InlineData("app-only", "api_access_denied")]
    public async Task Production_bearer_identity_cannot_be_widened_by_private_claim_or_headers(
        string token,
        string expectedError)
    {
        using var factory = new ProductionLikeWebApplicationFactory(InternalAuthenticationDefaults.EntraMode);
        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        client.DefaultRequestHeaders.Add("X-Project-Id", SeedIds.DemoProject.ToString("D"));
        client.DefaultRequestHeaders.Add("X-Roles", "DatabaseSme");
        client.DefaultRequestHeaders.Add("X-Project-Roles", "DatabaseSme");
        client.DefaultRequestHeaders.Add("X-Permissions", "sql.inventory.create");
        client.DefaultRequestHeaders.Add("X-Customer-Id", Guid.NewGuid().ToString("D"));
        client.DefaultRequestHeaders.Add("X-User-Name", "forged-production-user");
        client.DefaultRequestHeaders.Add("X-Principal-Id", Guid.NewGuid().ToString("D"));
        client.DefaultRequestHeaders.Add("X-Lgr-Test-Principal", "dba-project-a");

        using var response = await client.PostAsJsonAsync(
            "/api/v1/sql-instances",
            InstanceRequest(Guid.NewGuid(), "FORGED-PRODUCTION-AUTHORITY"));

        await AssertProblemDetailsAsync(response, HttpStatusCode.Forbidden, expectedError);
    }

    private static async Task<InventoryFixture> CreateInventoryFixtureAsync(LgrWebApplicationFactory factory)
    {
        using var dba = factory.CreateClient();
        var serverId = await ServerIdAsync(dba);
        var (instance, instanceTag) = await CreateInstanceAsync(dba, serverId, "MATRIX-INSTANCE");
        var (parentInstance, _) = await CreateInstanceAsync(dba, serverId, "MATRIX-PARENT");
        var (database, databaseTag) = await CreateDatabaseAsync(dba, parentInstance.Id, "MatrixDatabase");
        return new InventoryFixture(serverId, instance, instanceTag, parentInstance, database, databaseTag);
    }

    private static async Task<Guid> ServerIdAsync(HttpClient client)
    {
        var servers = await client.GetFromJsonAsync<PagedResult<ServerDto>>("/api/servers?pageSize=200", JsonOptions);
        return servers!.Items.Single(server => server.Hostname == "DC-HOU-SQL01").Id;
    }

    private static async Task<(SqlInstanceDto Dto, string EntityTag)> CreateInstanceAsync(
        HttpClient client,
        Guid serverId,
        string name)
    {
        var response = await client.PostAsJsonAsync("/api/v1/sql-instances", InstanceRequest(serverId, name));
        response.EnsureSuccessStatusCode();
        return ((await response.Content.ReadFromJsonAsync<SqlInstanceDto>(JsonOptions))!, response.Headers.ETag!.Tag);
    }

    private static async Task<(SqlDatabaseDto Dto, string EntityTag)> CreateDatabaseAsync(
        HttpClient client,
        Guid sqlInstanceId,
        string name)
    {
        var response = await client.PostAsJsonAsync("/api/v1/sql-databases", DatabaseRequest(sqlInstanceId, name));
        response.EnsureSuccessStatusCode();
        return ((await response.Content.ReadFromJsonAsync<SqlDatabaseDto>(JsonOptions))!, response.Headers.ETag!.Tag);
    }

    private static SqlInstanceWriteV1 InstanceRequest(Guid serverId, string name) =>
        new(serverId, name, "SQL Server 2022", "Standard", 1433, SqlInstanceServiceStatuses.Running, null);

    private static SqlDatabaseWriteV1 DatabaseRequest(Guid sqlInstanceId, string name) =>
        new(
            sqlInstanceId,
            name,
            1024,
            160,
            SqlDatabaseRecoveryModels.Full,
            "Latin1_General_100_CI_AS",
            SqlDatabaseStatuses.Online);

    private static async Task<HttpResponseMessage> SendWithIfMatchAsync(
        HttpClient client,
        HttpMethod method,
        string uri,
        object? body,
        string entityTag)
    {
        var request = new HttpRequestMessage(method, uri);
        if (body is not null)
        {
            request.Content = JsonContent.Create(body, options: JsonOptions);
        }

        request.Headers.TryAddWithoutValidation("If-Match", entityTag);
        return await client.SendAsync(request);
    }

    private static async Task<JsonElement> AssertProblemDetailsAsync(
        HttpResponseMessage response,
        HttpStatusCode expectedStatus,
        string expectedErrorCode)
    {
        Assert.Equal(expectedStatus, response.StatusCode);
        Assert.Equal("application/problem+json", response.Content.Headers.ContentType?.MediaType);
        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var root = document.RootElement.Clone();
        Assert.Equal((int)expectedStatus, root.GetProperty("status").GetInt32());
        Assert.False(string.IsNullOrWhiteSpace(root.GetProperty("type").GetString()));
        Assert.False(string.IsNullOrWhiteSpace(root.GetProperty("title").GetString()));
        Assert.False(string.IsNullOrWhiteSpace(root.GetProperty("detail").GetString()));
        Assert.False(string.IsNullOrWhiteSpace(root.GetProperty("instance").GetString()));
        Assert.Equal(expectedErrorCode, root.GetProperty("errorCode").GetString());
        Assert.False(string.IsNullOrWhiteSpace(root.GetProperty("correlationId").GetString()));
        return root;
    }

    private sealed record InventoryFixture(
        Guid ServerId,
        SqlInstanceDto Instance,
        string InstanceTag,
        SqlInstanceDto ParentInstance,
        SqlDatabaseDto Database,
        string DatabaseTag);

    private sealed class ProductionLikeWebApplicationFactory(string mode, bool completeEntra = true)
        : WebApplicationFactory<Program>
    {
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Staging");
            builder.ConfigureLogging(logging => logging.ClearProviders());
            builder.ConfigureAppConfiguration((_, configuration) =>
            {
                var values = new Dictionary<string, string?>
                {
                    ["Authentication:Mode"] = mode
                };
                if (completeEntra)
                {
                    values["Authentication:Entra:TenantId"] = SyntheticEntraTokenValidator.TenantId.ToString("D");
                    values["Authentication:Entra:Issuer"] = SyntheticEntraTokenValidator.Issuer;
                    values["Authentication:Entra:Audience"] = "api://synthetic-lgr";
                    values["Authentication:Entra:AllowedClientIds:0"] =
                        SyntheticEntraTokenValidator.ClientId.ToString("D");
                }

                configuration.AddInMemoryCollection(values);
            });
            builder.ConfigureServices(services =>
            {
                services.RemoveAll<IEntraAccessTokenValidator>();
                services.AddSingleton<IEntraAccessTokenValidator, SyntheticEntraTokenValidator>();
                services.RemoveAll<IProjectMembershipProvider>();
                services.AddSingleton<IProjectMembershipProvider, SyntheticReadOnlyMembershipProvider>();
            });
        }
    }

    private sealed class SyntheticEntraTokenValidator : IEntraAccessTokenValidator
    {
        public static readonly Guid TenantId = Guid.Parse("10000000-0000-0000-0000-000000000001");
        public static readonly Guid ObjectId = Guid.Parse("20000000-0000-0000-0000-000000000002");
        public static readonly Guid ClientId = Guid.Parse("30000000-0000-0000-0000-000000000003");
        public const string Issuer = "https://login.microsoftonline.com/10000000-0000-0000-0000-000000000001/v2.0";

        public Task<ClaimsPrincipal> ValidateAsync(string token, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            if (token is not ("valid" or "missing-scope" or "app-only"))
            {
                throw new SecurityTokenValidationException("Synthetic invalid token.");
            }

            var claims = new List<Claim>
            {
                new("tid", TenantId.ToString("D")),
                new("oid", ObjectId.ToString("D")),
                new("azp", ClientId.ToString("D")),
                new("sub", token == "app-only" ? ObjectId.ToString("D") : "synthetic-subject"),
                new("ver", "2.0"),
                new("urn:agilisys:lgr:permission", SqlInventoryPermissions.Create)
            };
            if (token == "valid")
            {
                claims.Add(new Claim("scp", "lgr.access"));
            }
            else if (token == "app-only")
            {
                claims.Add(new Claim("roles", "Lgr.Api.Service"));
            }

            return Task.FromResult(new ClaimsPrincipal(new ClaimsIdentity(claims, "SyntheticValidatedBearer")));
        }
    }

    private sealed class SyntheticReadOnlyMembershipProvider : IProjectMembershipProvider
    {
        public ValueTask<MembershipResolution> ResolveAsync(
            InternalPrincipal principal,
            Guid projectId,
            CancellationToken cancellationToken) =>
            ValueTask.FromResult(new MembershipResolution(
                MembershipResolutionStatus.Active,
                SeedIds.DemoCustomer,
                projectId,
                new HashSet<string>(["ReviewerAuditor"], StringComparer.Ordinal),
                "synthetic-production-membership-v1"));
    }

    private sealed class RevocableMembershipProvider : IProjectMembershipProvider
    {
        private bool _active = true;

        public void Revoke() => _active = false;

        public ValueTask<MembershipResolution> ResolveAsync(
            InternalPrincipal principal,
            Guid projectId,
            CancellationToken cancellationToken) =>
            ValueTask.FromResult(_active
                ? new MembershipResolution(
                    MembershipResolutionStatus.Active,
                    SeedIds.DemoCustomer,
                    projectId,
                    new HashSet<string>(["ReviewerAuditor"], StringComparer.Ordinal),
                    "revocable-v1")
                : new MembershipResolution(MembershipResolutionStatus.NotFound));
    }
}
