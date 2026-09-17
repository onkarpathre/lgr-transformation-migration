using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Domain;
using LgrTransformationMigration.Api.Infrastructure;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace LgrTransformationMigration.Api.IntegrationTests;

public sealed class SqlAssessmentApiTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public static TheoryData<string, bool, bool, bool> RoleMatrix => new()
    {
        { "dba-project-a", true, true, true },
        { "architect-project-a", true, false, true },
        { "manager-project-a", true, false, false },
        { "analyst-project-a", true, false, false },
        { "reader-project-a", true, false, false },
        { "multi-role-project-a", true, false, true },
        { "customer-admin", false, false, false },
        { "platform-admin", false, false, false },
        { "unknown-role", false, false, false }
    };

    [Fact]
    public async Task Database_assessment_lifecycle_is_scoped_versioned_audited_and_archivable()
    {
        using var factory = new LgrWebApplicationFactory();
        var fixture = await SeedInventoryAsync(factory);
        using var client = factory.CreateClient();

        var (created, createdTag, location) = await CreateAssessmentAsync(
            client,
            CreateRequest(sqlDatabaseId: fixture.DatabaseId));
        Assert.Equal($"/api/v1/sql-assessments/{created.Id}", location);
        Assert.Equal("SqlDatabase", created.TargetType);
        Assert.Equal(fixture.DatabaseId, created.Target.Id);

        var list = await client.GetFromJsonAsync<PagedResult<SqlAssessmentDto>>(
            $"/api/v1/sql-assessments?targetType=SqlDatabase&targetId={fixture.DatabaseId:D}&assessmentStatus=InProgress&readinessStatus=AtRisk",
            JsonOptions);
        Assert.Equal(created.Id, Assert.Single(list!.Items).Id);

        using var evidenceResponse = await SendWithIfMatchAsync(
            client,
            HttpMethod.Put,
            $"/api/v1/sql-assessments/{created.Id}/evidence",
            new SqlAssessmentEvidenceUpdateV1(
                SqlAssessmentStatuses.Complete,
                SqlReadinessStatuses.Ready,
                "",
                "Synthetic evidence complete",
                "Human reviewed",
                DateTimeOffset.UtcNow),
            createdTag);
        Assert.Equal(HttpStatusCode.OK, evidenceResponse.StatusCode);
        var evidence = (await evidenceResponse.Content.ReadFromJsonAsync<SqlAssessmentDto>(JsonOptions))!;
        var evidenceTag = evidenceResponse.Headers.ETag!.Tag;

        using var planningResponse = await SendWithIfMatchAsync(
            client,
            HttpMethod.Put,
            $"/api/v1/sql-assessments/{created.Id}/planning",
            new SqlAssessmentPlanningUpdateV1(
                SqlAssessmentTargetPlatforms.SqlServerOnAzureVm,
                "SQL Server 2025",
                SqlMigrationApproaches.Online),
            evidenceTag);
        Assert.Equal(HttpStatusCode.OK, planningResponse.StatusCode);
        var planned = (await planningResponse.Content.ReadFromJsonAsync<SqlAssessmentDto>(JsonOptions))!;
        Assert.Equal("SQL Server 2025", planned.TargetSqlVersion);
        var planningTag = planningResponse.Headers.ETag!.Tag;

        using var blockedTargetArchive = await SendWithIfMatchAsync(
            client,
            HttpMethod.Delete,
            $"/api/v1/sql-databases/{fixture.DatabaseId}",
            null,
            fixture.DatabaseTag);
        await AssertProblemAsync(blockedTargetArchive, HttpStatusCode.Conflict, "data_conflict");

        using var archive = await SendWithIfMatchAsync(
            client,
            HttpMethod.Delete,
            $"/api/v1/sql-assessments/{created.Id}",
            null,
            planningTag);
        Assert.Equal(HttpStatusCode.NoContent, archive.StatusCode);
        using var missing = await client.GetAsync($"/api/v1/sql-assessments/{created.Id}");
        await AssertProblemAsync(missing, HttpStatusCode.NotFound, "resource_not_found");
        var (replacement, _, _) = await CreateAssessmentAsync(
            client,
            CreateRequest(sqlDatabaseId: fixture.DatabaseId));
        Assert.NotEqual(created.Id, replacement.Id);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var stored = await db.SqlAssessments.IgnoreQueryFilters().SingleAsync(x => x.Id == created.Id);
        Assert.True(stored.IsDeleted);
        Assert.Equal("local-test:70000000-0000-0000-0000-000000000001", stored.CreatedBy);
        var audit = await db.AuditEvents.IgnoreQueryFilters()
            .Where(x => x.EntityId == created.Id)
            .ToListAsync();
        Assert.Contains(audit, x => x.Action == "SqlAssessmentCreated");
        Assert.Contains(audit, x => x.Action == "SqlAssessmentEvidenceChanged" && x.PropertyName == "Findings");
        Assert.Contains(audit, x => x.Action == "SqlAssessmentPlanningChanged" && x.PropertyName == "TargetPlatform");
        Assert.Contains(audit, x => x.Action == "SqlAssessmentArchived");
        Assert.All(audit, x =>
        {
            Assert.Equal(SeedIds.DemoProject, x.ProjectId);
            Assert.False(string.IsNullOrWhiteSpace(x.CorrelationId));
        });
    }

    [Theory]
    [MemberData(nameof(RoleMatrix))]
    public async Task Every_assessment_route_enforces_the_exact_role_and_field_command_matrix(
        string alias,
        bool canRead,
        bool canManage,
        bool canPlan)
    {
        using var factory = new LgrWebApplicationFactory();
        var fixture = await SeedInventoryAsync(factory);
        var seeded = await SeedAssessmentAsync(factory, fixture.InstanceId);
        using var client = factory.CreateAuthenticatedClient(alias, SeedIds.DemoProject);

        using var list = await client.GetAsync("/api/v1/sql-assessments");
        using var detail = await client.GetAsync($"/api/v1/sql-assessments/{seeded.Id}");
        using var create = await client.PostAsJsonAsync(
            "/api/v1/sql-assessments",
            CreateRequest(sqlDatabaseId: fixture.DatabaseId));
        using var evidence = await SendWithIfMatchAsync(
            client,
            HttpMethod.Put,
            $"/api/v1/sql-assessments/{seeded.Id}/evidence",
            new SqlAssessmentEvidenceUpdateV1(
                SqlAssessmentStatuses.InProgress,
                SqlReadinessStatuses.AtRisk,
                "",
                "Synthetic evidence",
                "Updated evidence",
                null),
            seeded.Tag);
        var currentTag = evidence.Headers.ETag?.Tag ?? seeded.Tag;
        using var planning = await SendWithIfMatchAsync(
            client,
            HttpMethod.Put,
            $"/api/v1/sql-assessments/{seeded.Id}/planning",
            new SqlAssessmentPlanningUpdateV1(
                SqlAssessmentTargetPlatforms.Investigate,
                null,
                SqlMigrationApproaches.ToBeDetermined),
            currentTag);
        currentTag = planning.Headers.ETag?.Tag ?? currentTag;
        using var archive = await SendWithIfMatchAsync(
            client,
            HttpMethod.Delete,
            $"/api/v1/sql-assessments/{seeded.Id}",
            null,
            currentTag);

        Assert.Equal(canRead ? HttpStatusCode.OK : HttpStatusCode.Forbidden, list.StatusCode);
        Assert.Equal(canRead ? HttpStatusCode.OK : HttpStatusCode.Forbidden, detail.StatusCode);
        Assert.Equal(canManage ? HttpStatusCode.Created : HttpStatusCode.Forbidden, create.StatusCode);
        Assert.Equal(canManage ? HttpStatusCode.OK : HttpStatusCode.Forbidden, evidence.StatusCode);
        Assert.Equal(canPlan ? HttpStatusCode.OK : HttpStatusCode.Forbidden, planning.StatusCode);
        Assert.Equal(canManage ? HttpStatusCode.NoContent : HttpStatusCode.Forbidden, archive.StatusCode);

        foreach (var response in new[] { list, detail, create, evidence, planning, archive }
                     .Where(x => x.StatusCode == HttpStatusCode.Forbidden))
        {
            await AssertProblemAsync(response, HttpStatusCode.Forbidden, "permission_denied");
        }

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var deniedAudit = await db.AuditEvents.IgnoreQueryFilters()
            .Where(x => x.ProjectId == SeedIds.DemoProject && x.EntityType == "SqlAssessment")
            .Select(x => x.Action)
            .ToListAsync();
        if (!canManage)
        {
            Assert.Contains("SqlAssessmentCreateDenied", deniedAudit);
            Assert.Contains("SqlAssessmentEvidenceChangeDenied", deniedAudit);
            Assert.Contains("SqlAssessmentArchiveDenied", deniedAudit);
        }

        if (!canPlan)
        {
            Assert.Contains("SqlAssessmentPlanningChangeDenied", deniedAudit);
        }
    }

    [Fact]
    public async Task Xor_duplicate_cross_scope_and_unknown_targets_fail_safely_without_mutation()
    {
        using var factory = new LgrWebApplicationFactory();
        var fixture = await SeedInventoryAsync(factory);
        var other = await factory.SeedSecondTenantAsync();
        var otherInventory = await SeedInventoryAsync(factory, other.CustomerId, other.ProjectId, LgrWebApplicationFactory.SecondTenantServerId);
        using var client = factory.CreateClient();

        using var noTarget = await client.PostAsJsonAsync(
            "/api/v1/sql-assessments",
            CreateRequest());
        using var twoTargets = await client.PostAsJsonAsync(
            "/api/v1/sql-assessments",
            CreateRequest(fixture.InstanceId, fixture.DatabaseId));
        await AssertProblemAsync(noTarget, HttpStatusCode.BadRequest, "validation_failed");
        await AssertProblemAsync(twoTargets, HttpStatusCode.BadRequest, "validation_failed");

        await CreateAssessmentAsync(client, CreateRequest(sqlInstanceId: fixture.InstanceId));
        using var duplicate = await client.PostAsJsonAsync(
            "/api/v1/sql-assessments",
            CreateRequest(sqlInstanceId: fixture.InstanceId));
        await AssertProblemAsync(duplicate, HttpStatusCode.Conflict, "data_conflict");

        using var unknown = await client.PostAsJsonAsync(
            "/api/v1/sql-assessments",
            CreateRequest(sqlInstanceId: Guid.NewGuid()));
        using var inaccessible = await client.PostAsJsonAsync(
            "/api/v1/sql-assessments",
            CreateRequest(sqlInstanceId: otherInventory.InstanceId));
        var unknownProblem = await AssertProblemAsync(unknown, HttpStatusCode.NotFound, "resource_not_found");
        var inaccessibleProblem = await AssertProblemAsync(inaccessible, HttpStatusCode.NotFound, "resource_not_found");
        Assert.Equal(unknownProblem.GetProperty("title").GetString(), inaccessibleProblem.GetProperty("title").GetString());
        Assert.Equal(unknownProblem.GetProperty("detail").GetString(), inaccessibleProblem.GetProperty("detail").GetString());

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.Equal(1, await db.SqlAssessments.IgnoreQueryFilters()
            .CountAsync(x => x.CustomerId == SeedIds.DemoCustomer && x.ProjectId == SeedIds.DemoProject));
    }

    [Fact]
    public async Task Cross_scope_assessment_identifiers_match_missing_for_read_and_mutation()
    {
        using var factory = new LgrWebApplicationFactory();
        var other = await factory.SeedSecondTenantAsync();
        var otherInventory = await SeedInventoryAsync(factory, other.CustomerId, other.ProjectId, LgrWebApplicationFactory.SecondTenantServerId);
        using var otherClient = factory.CreateAuthenticatedClient("dba-project-b", other.ProjectId);
        var (otherAssessment, otherTag, _) = await CreateAssessmentAsync(
            otherClient,
            CreateRequest(sqlInstanceId: otherInventory.InstanceId));
        using var client = factory.CreateClient();

        using var missing = await client.GetAsync($"/api/v1/sql-assessments/{Guid.NewGuid()}");
        using var inaccessible = await client.GetAsync($"/api/v1/sql-assessments/{otherAssessment.Id}");
        var missingProblem = await AssertProblemAsync(missing, HttpStatusCode.NotFound, "resource_not_found");
        var inaccessibleProblem = await AssertProblemAsync(inaccessible, HttpStatusCode.NotFound, "resource_not_found");
        Assert.Equal(missingProblem.GetProperty("detail").GetString(), inaccessibleProblem.GetProperty("detail").GetString());

        using var update = await SendWithIfMatchAsync(
            client,
            HttpMethod.Put,
            $"/api/v1/sql-assessments/{otherAssessment.Id}/planning",
            new SqlAssessmentPlanningUpdateV1(
                SqlAssessmentTargetPlatforms.Investigate,
                null,
                SqlMigrationApproaches.ToBeDetermined),
            otherTag);
        using var archive = await SendWithIfMatchAsync(
            client,
            HttpMethod.Delete,
            $"/api/v1/sql-assessments/{otherAssessment.Id}",
            null,
            otherTag);
        await AssertProblemAsync(update, HttpStatusCode.NotFound, "resource_not_found");
        await AssertProblemAsync(archive, HttpStatusCode.NotFound, "resource_not_found");
    }

    [Theory]
    [InlineData("GET", "/api/v1/sql-assessments")]
    [InlineData("GET", "/api/v1/sql-assessments/40000000-0000-0000-0000-000000000001")]
    [InlineData("POST", "/api/v1/sql-assessments")]
    [InlineData("PUT", "/api/v1/sql-assessments/40000000-0000-0000-0000-000000000001/evidence")]
    [InlineData("PUT", "/api/v1/sql-assessments/40000000-0000-0000-0000-000000000001/planning")]
    [InlineData("DELETE", "/api/v1/sql-assessments/40000000-0000-0000-0000-000000000001")]
    public async Task Every_assessment_route_requires_authentication(string method, string route)
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateUnauthenticatedClient();
        using var request = new HttpRequestMessage(new HttpMethod(method), route);
        if (method is "POST" or "PUT")
        {
            request.Content = JsonContent.Create(new { });
        }

        using var response = await client.SendAsync(request);

        await AssertProblemAsync(response, HttpStatusCode.Unauthorized, "authentication_required");
    }

    [Fact]
    public async Task Updates_and_archive_require_current_if_match_and_never_silently_overwrite()
    {
        using var factory = new LgrWebApplicationFactory();
        var fixture = await SeedInventoryAsync(factory);
        using var client = factory.CreateClient();
        var (assessment, tag, _) = await CreateAssessmentAsync(client, CreateRequest(sqlInstanceId: fixture.InstanceId));
        var request = new SqlAssessmentPlanningUpdateV1(
            SqlAssessmentTargetPlatforms.Investigate,
            null,
            SqlMigrationApproaches.ToBeDetermined);

        using var missing = await client.PutAsJsonAsync($"/api/v1/sql-assessments/{assessment.Id}/planning", request);
        await AssertProblemAsync(missing, HttpStatusCode.PreconditionRequired, "precondition_required");
        using var stale = await SendWithIfMatchAsync(
            client,
            HttpMethod.Put,
            $"/api/v1/sql-assessments/{assessment.Id}/planning",
            request,
            "\"c3RhbGU=\"");
        await AssertProblemAsync(stale, HttpStatusCode.PreconditionFailed, "stale_version");
        using var updated = await SendWithIfMatchAsync(
            client,
            HttpMethod.Put,
            $"/api/v1/sql-assessments/{assessment.Id}/planning",
            request,
            tag);
        Assert.Equal(HttpStatusCode.OK, updated.StatusCode);
        using var staleArchive = await SendWithIfMatchAsync(
            client,
            HttpMethod.Delete,
            $"/api/v1/sql-assessments/{assessment.Id}",
            null,
            tag);
        await AssertProblemAsync(staleArchive, HttpStatusCode.PreconditionFailed, "stale_version");
    }

    [Fact]
    public async Task Feature_flag_is_not_authorization_and_disabled_child_is_non_enumerating()
    {
        using var factory = new LgrWebApplicationFactory();
        using var disabledFactory = factory.WithWebHostBuilder(builder => builder.ConfigureAppConfiguration((_, configuration) =>
            configuration.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Features:SqlAssessment"] = "false"
            })));
        using var client = disabledFactory.CreateClient();
        LgrWebApplicationFactory.ApplySyntheticIdentity(client, "dba-project-a", SeedIds.DemoProject);

        using var response = await client.GetAsync("/api/v1/sql-assessments");

        await AssertProblemAsync(response, HttpStatusCode.NotFound, "feature_disabled");
    }

    [Fact]
    public async Task Ef_model_has_xor_controlled_values_composite_fks_filtered_uniqueness_and_rowversion()
    {
        using var factory = new LgrWebApplicationFactory();
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var designModel = db.GetService<IDesignTimeModel>().Model;
        var entity = designModel.FindEntityType(typeof(SqlAssessment))!;

        Assert.True(entity.FindProperty(nameof(SqlAssessment.RowVersion))!.IsConcurrencyToken);
        Assert.Equal(
            ["CustomerId", "ProjectId"],
            entity.GetForeignKeys().Single(x => x.PrincipalEntityType.ClrType == typeof(Project))
                .Properties.Select(x => x.Name));
        Assert.All(
            entity.GetForeignKeys().Where(x => x.PrincipalEntityType.ClrType is not null
                                                && (x.PrincipalEntityType.ClrType == typeof(SqlInstance)
                                                    || x.PrincipalEntityType.ClrType == typeof(SqlDatabase))),
            foreignKey => Assert.Equal(
                ["CustomerId", "ProjectId", foreignKey.PrincipalEntityType.ClrType == typeof(SqlInstance) ? "SqlInstanceId" : "SqlDatabaseId"],
                foreignKey.Properties.Select(x => x.Name)));
        Assert.Contains(entity.GetCheckConstraints(), x => x.Name == "CK_SqlAssessments_ExactlyOneTarget");
        Assert.Contains(entity.GetCheckConstraints(), x => x.Name == "CK_SqlAssessments_AssessmentStatus");
        Assert.Contains(entity.GetIndexes(), x => x.GetDatabaseName() == "UX_SqlAssessments_Owner_Active_Instance" && x.IsUnique && x.GetFilter() is not null);
        Assert.Contains(entity.GetIndexes(), x => x.GetDatabaseName() == "UX_SqlAssessments_Owner_Active_Database" && x.IsUnique && x.GetFilter() is not null);
    }

    [Fact]
    public void Sql_server_provider_generates_assessment_checks_composite_fks_filtered_indexes_and_rowversion()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlServer("Server=(local);Database=SyntheticSchemaOnly;Integrated Security=True;TrustServerCertificate=True")
            .Options;
        using var db = new AppDbContext(options, new FixedSyntheticContext());

        var script = db.Database.GenerateCreateScript();

        Assert.Contains("[SqlAssessments]", script, StringComparison.Ordinal);
        Assert.Contains("[RowVersion] rowversion NOT NULL", script, StringComparison.Ordinal);
        Assert.Contains("CONSTRAINT [CK_SqlAssessments_ExactlyOneTarget]", script, StringComparison.Ordinal);
        Assert.Contains("CONSTRAINT [CK_SqlAssessments_AssessmentStatus]", script, StringComparison.Ordinal);
        Assert.Contains("CONSTRAINT [FK_SqlAssessments_SqlInstances_CustomerId_ProjectId_SqlInstanceId]", script, StringComparison.Ordinal);
        Assert.Contains("CONSTRAINT [FK_SqlAssessments_SqlDatabases_CustomerId_ProjectId_SqlDatabaseId]", script, StringComparison.Ordinal);
        Assert.Contains("CREATE UNIQUE INDEX [UX_SqlAssessments_Owner_Active_Instance]", script, StringComparison.Ordinal);
        Assert.Contains("WHERE [IsDeleted] = 0 AND [SqlInstanceId] IS NOT NULL", script, StringComparison.Ordinal);
    }

    private static SqlAssessmentCreateV1 CreateRequest(Guid? sqlInstanceId = null, Guid? sqlDatabaseId = null) => new(
        sqlInstanceId,
        sqlDatabaseId,
        SqlAssessmentStatuses.InProgress,
        SqlReadinessStatuses.AtRisk,
        SqlAssessmentTargetPlatforms.AzureSqlManagedInstance,
        null,
        SqlMigrationApproaches.ToBeDetermined,
        "Synthetic blocker",
        "Synthetic finding",
        "Synthetic note",
        null);

    private static async Task<(SqlAssessmentDto Dto, string Tag, string Location)> CreateAssessmentAsync(
        HttpClient client,
        SqlAssessmentCreateV1 request)
    {
        using var response = await client.PostAsJsonAsync("/api/v1/sql-assessments", request);
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        return (
            (await response.Content.ReadFromJsonAsync<SqlAssessmentDto>(JsonOptions))!,
            response.Headers.ETag!.Tag,
            response.Headers.Location!.AbsolutePath);
    }

    private static async Task<(Guid Id, string Tag)> SeedAssessmentAsync(
        LgrWebApplicationFactory factory,
        Guid instanceId)
    {
        using var client = factory.CreateClient();
        var result = await CreateAssessmentAsync(client, CreateRequest(sqlInstanceId: instanceId));
        return (result.Dto.Id, result.Tag);
    }

    private static async Task<(Guid InstanceId, Guid DatabaseId, string DatabaseTag)> SeedInventoryAsync(
        LgrWebApplicationFactory factory,
        Guid? customerId = null,
        Guid? projectId = null,
        Guid? serverId = null)
    {
        var ownerCustomer = customerId ?? SeedIds.DemoCustomer;
        var ownerProject = projectId ?? SeedIds.DemoProject;
        var instanceId = Guid.NewGuid();
        var databaseId = Guid.NewGuid();
        var now = DateTimeOffset.UtcNow;
        var instanceVersion = new byte[] { 1, 2, 3, 4, 5, 6, 7, 8 };
        var databaseVersion = new byte[] { 8, 7, 6, 5, 4, 3, 2, 1 };
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var parentServer = serverId ?? await db.Servers.IgnoreQueryFilters()
            .Where(x => x.CustomerId == ownerCustomer && x.ProjectId == ownerProject)
            .Select(x => x.Id)
            .FirstAsync();
        db.SqlInstances.Add(new SqlInstance
        {
            Id = instanceId,
            CustomerId = ownerCustomer,
            ProjectId = ownerProject,
            ServerId = parentServer,
            InstanceName = $"SYNTH-{instanceId:N}"[..24],
            NormalizedInstanceName = $"SYNTH-{instanceId:N}"[..24].ToUpperInvariant(),
            SqlVersion = "SQL Server 2022",
            Edition = "Standard",
            ServiceStatus = SqlInstanceServiceStatuses.Running,
            DiscoverySource = "Synthetic fixture",
            CreatedAt = now,
            UpdatedAt = now,
            CreatedBy = "synthetic-fixture",
            UpdatedBy = "synthetic-fixture",
            RowVersion = instanceVersion
        });
        db.SqlDatabases.Add(new SqlDatabase
        {
            Id = databaseId,
            CustomerId = ownerCustomer,
            ProjectId = ownerProject,
            SqlInstanceId = instanceId,
            Name = $"Synthetic{databaseId:N}"[..24],
            NormalizedName = $"Synthetic{databaseId:N}"[..24].ToUpperInvariant(),
            SizeMb = 1024,
            CompatibilityLevel = 160,
            RecoveryModel = SqlDatabaseRecoveryModels.Full,
            Status = SqlDatabaseStatuses.Online,
            CreatedAt = now,
            UpdatedAt = now,
            CreatedBy = "synthetic-fixture",
            UpdatedBy = "synthetic-fixture",
            RowVersion = databaseVersion
        });
        await db.SaveChangesAsync();
        return (instanceId, databaseId, $"\"{Convert.ToBase64String(databaseVersion)}\"");
    }

    private static async Task<HttpResponseMessage> SendWithIfMatchAsync(
        HttpClient client,
        HttpMethod method,
        string path,
        object? body,
        string tag)
    {
        var request = new HttpRequestMessage(method, path);
        request.Headers.TryAddWithoutValidation("If-Match", tag);
        if (body is not null)
        {
            request.Content = JsonContent.Create(body);
        }

        return await client.SendAsync(request);
    }

    private static async Task<JsonElement> AssertProblemAsync(
        HttpResponseMessage response,
        HttpStatusCode status,
        string errorCode)
    {
        Assert.Equal(status, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(errorCode, json.GetProperty("errorCode").GetString());
        Assert.False(json.GetProperty("correlationId").GetString()!.Contains("Synthetic", StringComparison.Ordinal));
        return json;
    }

    private sealed class FixedSyntheticContext : ICurrentCustomerContext
    {
        public Guid CustomerId => SeedIds.DemoCustomer;
        public Guid ProjectId => SeedIds.DemoProject;
        public string UserName => "synthetic-schema";
        public string CorrelationId => "synthetic-schema-correlation";
        public InternalPrincipal Principal { get; } = new(
            Guid.Parse("70000000-0000-0000-0000-000000000099"),
            InternalPrincipalType.Human,
            "Synthetic",
            Guid.Empty,
            Guid.Empty,
            Guid.Empty,
            "synthetic-schema",
            "Synthetic Schema",
            InternalAuthenticationDefaults.LocalTestMode,
            true,
            true);
    }
}
