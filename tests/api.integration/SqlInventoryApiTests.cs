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

public sealed class SqlInventoryApiTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    [Fact]
    public async Task Sql_discovery_assessment_is_not_exposed_when_feature_is_disabled()
    {
        using var factory = new LgrWebApplicationFactory();
        using var disabledFactory = factory.WithWebHostBuilder(builder =>
            builder.ConfigureAppConfiguration((_, configuration) =>
                configuration.AddInMemoryCollection(new Dictionary<string, string?>
                {
                    ["Features:SqlDiscoveryAssessment"] = "false"
                })));
        using var client = disabledFactory.CreateClient();

        var listResponse = await client.GetAsync("/api/v1/sql-instances");
        var createResponse = await client.PostAsJsonAsync(
            "/api/v1/sql-instances",
            InstanceRequest(Guid.NewGuid(), "DISABLED-FEATURE") with { Port = 70000 });

        Assert.Equal(HttpStatusCode.NotFound, listResponse.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, createResponse.StatusCode);
        using var document = JsonDocument.Parse(await listResponse.Content.ReadAsStringAsync());
        var root = document.RootElement;
        Assert.Equal("feature_disabled", root.GetProperty("errorCode").GetString());
        Assert.Equal("/api/v1/sql-instances", root.GetProperty("instance").GetString());
        Assert.False(string.IsNullOrWhiteSpace(root.GetProperty("correlationId").GetString()));
        using var createDocument = JsonDocument.Parse(await createResponse.Content.ReadAsStringAsync());
        Assert.Equal(
            "feature_disabled",
            createDocument.RootElement.GetProperty("errorCode").GetString());

        using var scope = disabledFactory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.Empty(await db.SqlInstances.ToListAsync());
    }

    [Fact]
    public async Task Instance_and_database_crud_is_audited_and_uses_optimistic_concurrency()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateClient();
        var serverId = await ServerIdAsync(client, "DC-HOU-SQL01");
        var (instance, instanceTag) = await CreateInstanceAsync(client, serverId, "POC01");

        var get = await client.GetAsync($"/api/v1/sql-instances/{instance.Id}");
        Assert.Equal(HttpStatusCode.OK, get.StatusCode);
        Assert.Equal(instanceTag, get.Headers.ETag!.Tag);
        Assert.Equal("Manual", instance.DiscoverySource);

        var updateRequest = InstanceRequest(serverId, "POC01") with
        {
            SqlVersion = "SQL Server 2025 CU1",
            ServiceStatus = "stopped",
            ServiceAccountName = "SYNTHETIC\\sql-service"
        };
        Assert.Equal(
            (HttpStatusCode)428,
            (await client.PutAsJsonAsync($"/api/v1/sql-instances/{instance.Id}", updateRequest)).StatusCode);
        var update = await SendWithIfMatchAsync(
            client,
            HttpMethod.Put,
            $"/api/v1/sql-instances/{instance.Id}",
            updateRequest,
            instanceTag);
        Assert.Equal(HttpStatusCode.OK, update.StatusCode);
        var updatedInstance = (await update.Content.ReadFromJsonAsync<SqlInstanceDto>(JsonOptions))!;
        var updatedInstanceTag = update.Headers.ETag!.Tag;
        Assert.Equal("SQL Server 2025 CU1", updatedInstance.SqlVersion);
        Assert.Equal(SqlInstanceServiceStatuses.Stopped, updatedInstance.ServiceStatus);
        Assert.Equal("SYNTHETIC\\sql-service", updatedInstance.ServiceAccountName);
        Assert.NotEqual(instanceTag, updatedInstanceTag);

        var (database, databaseTag) = await CreateDatabaseAsync(client, instance.Id, "SyntheticHousing");
        var databaseUpdate = DatabaseRequest(instance.Id, database.Name) with
        {
            SizeMb = 2048,
            RecoveryModel = "bulk logged",
            Status = "recovery pending"
        };
        var updatedDatabaseResponse = await SendWithIfMatchAsync(
            client,
            HttpMethod.Put,
            $"/api/v1/sql-databases/{database.Id}",
            databaseUpdate,
            databaseTag);
        Assert.Equal(HttpStatusCode.OK, updatedDatabaseResponse.StatusCode);
        var updatedDatabase = (await updatedDatabaseResponse.Content.ReadFromJsonAsync<SqlDatabaseDto>(JsonOptions))!;
        var updatedDatabaseTag = updatedDatabaseResponse.Headers.ETag!.Tag;
        Assert.Equal(SqlDatabaseRecoveryModels.BulkLogged, updatedDatabase.RecoveryModel);
        Assert.Equal(SqlDatabaseStatuses.RecoveryPending, updatedDatabase.Status);

        Assert.Equal(
            (HttpStatusCode)428,
            (await client.DeleteAsync($"/api/v1/sql-databases/{database.Id}")).StatusCode);
        Assert.Equal(
            HttpStatusCode.NoContent,
            (await SendWithIfMatchAsync(
                client,
                HttpMethod.Delete,
                $"/api/v1/sql-databases/{database.Id}",
                null,
                updatedDatabaseTag)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync($"/api/v1/sql-databases/{database.Id}")).StatusCode);

        Assert.Equal(
            HttpStatusCode.NoContent,
            (await SendWithIfMatchAsync(
                client,
                HttpMethod.Delete,
                $"/api/v1/sql-instances/{instance.Id}",
                null,
                updatedInstanceTag)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync($"/api/v1/sql-instances/{instance.Id}")).StatusCode);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var audit = await db.AuditEvents.Where(x => x.EntityId == instance.Id || x.EntityId == database.Id).ToListAsync();
        Assert.Contains(audit, x => x.Action == "SqlInstanceCreated" && x.ProjectId == SeedIds.DemoProject);
        Assert.Contains(audit, x => x.Action == "SqlInstanceUpdated" && x.PropertyName == "SqlVersion");
        Assert.Contains(audit, x =>
            x.Action == "SqlInstanceUpdated"
            && x.PropertyName == "ServiceAccountName"
            && x.OldValue is null
            && x.NewValue == "[REDACTED]");
        Assert.Contains(audit, x => x.Action == "SqlDatabaseCreated");
        Assert.Contains(audit, x => x.Action == "SqlDatabaseUpdated" && x.PropertyName == "SizeMb");
        Assert.Contains(audit, x => x.Action == "SqlDatabaseArchived");
        Assert.Contains(audit, x => x.Action == "SqlInstanceArchived");
        Assert.All(audit, x =>
        {
            Assert.Equal(SeedIds.DemoCustomer, x.CustomerId);
            Assert.False(string.IsNullOrWhiteSpace(x.ChangedBy));
            Assert.False(string.IsNullOrWhiteSpace(x.CorrelationId));
            Assert.Equal(TimeSpan.Zero, x.ChangedAt.Offset);
        });
    }

    [Fact]
    public async Task Stale_etag_is_rejected_without_mutating_the_record()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateClient();
        var serverId = await ServerIdAsync(client, "DC-HOU-SQL01");
        var (instance, tag) = await CreateInstanceAsync(client, serverId, "CONCURRENCY");
        var firstUpdate = InstanceRequest(serverId, instance.InstanceName) with { Edition = "Developer" };
        var first = await SendWithIfMatchAsync(
            client,
            HttpMethod.Put,
            $"/api/v1/sql-instances/{instance.Id}",
            firstUpdate,
            tag);
        Assert.Equal(HttpStatusCode.OK, first.StatusCode);

        var stale = await SendWithIfMatchAsync(
            client,
            HttpMethod.Put,
            $"/api/v1/sql-instances/{instance.Id}",
            firstUpdate with { Edition = "Enterprise" },
            tag);
        Assert.Equal(HttpStatusCode.PreconditionFailed, stale.StatusCode);
        var current = await client.GetFromJsonAsync<SqlInstanceDto>($"/api/v1/sql-instances/{instance.Id}", JsonOptions);
        Assert.Equal("Developer", current!.Edition);
    }

    [Fact]
    public async Task Normalized_instance_and_database_names_are_unique_within_their_parent()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateClient();
        var firstServer = await ServerIdAsync(client, "DC-HOU-SQL01");
        var secondServer = await ServerIdAsync(client, "DC-REV-SQL01");
        var (defaultInstance, _) = await CreateInstanceAsync(client, firstServer, "default");

        Assert.Equal(
            HttpStatusCode.Conflict,
            (await client.PostAsJsonAsync(
                "/api/v1/sql-instances",
                InstanceRequest(firstServer, " (DEFAULT) "))).StatusCode);
        var (otherServerInstance, _) = await CreateInstanceAsync(client, secondServer, "MSSQLSERVER");
        var (database, _) = await CreateDatabaseAsync(client, defaultInstance.Id, "CaseSensitiveName");

        Assert.Equal(
            HttpStatusCode.Conflict,
            (await client.PostAsJsonAsync(
                "/api/v1/sql-databases",
                DatabaseRequest(defaultInstance.Id, " casesensitivename "))).StatusCode);
        var sameNameDifferentParent = await client.PostAsJsonAsync(
            "/api/v1/sql-databases",
            DatabaseRequest(otherServerInstance.Id, database.Name));
        Assert.Equal(HttpStatusCode.Created, sameNameDifferentParent.StatusCode);
    }

    [Fact]
    public async Task Missing_and_invalid_relationships_or_values_fail_safely()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateClient();

        Assert.Equal(
            HttpStatusCode.NotFound,
            (await client.PostAsJsonAsync(
                "/api/v1/sql-instances",
                InstanceRequest(Guid.NewGuid(), "MISSING-PARENT"))).StatusCode);
        Assert.Equal(
            HttpStatusCode.NotFound,
            (await client.PostAsJsonAsync(
                "/api/v1/sql-databases",
                DatabaseRequest(Guid.NewGuid(), "MissingParent"))).StatusCode);
        var serverId = await ServerIdAsync(client, "DC-HOU-SQL01");
        Assert.Equal(
            HttpStatusCode.BadRequest,
            (await client.PostAsJsonAsync(
                "/api/v1/sql-instances",
                InstanceRequest(serverId, "BAD-PORT") with { Port = 70000 })).StatusCode);
        var (instance, _) = await CreateInstanceAsync(client, serverId, "VALID-PARENT");
        Assert.Equal(
            HttpStatusCode.BadRequest,
            (await client.PostAsJsonAsync(
                "/api/v1/sql-databases",
                DatabaseRequest(instance.Id, "BadCompatibility") with { CompatibilityLevel = 70 })).StatusCode);
    }

    [Fact]
    public async Task Dto_validation_returns_the_approved_problem_details_contract()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateClient();
        var serverId = await ServerIdAsync(client, "DC-HOU-SQL01");

        var response = await client.PostAsJsonAsync(
            "/api/v1/sql-instances",
            InstanceRequest(serverId, "INVALID-DTO") with { Port = 70000 });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var root = document.RootElement;
        var requiredMembers = new[]
        {
            "type", "title", "status", "detail", "instance", "errorCode", "correlationId", "errors"
        };
        var missingMembers = requiredMembers
            .Where(member => !root.TryGetProperty(member, out _))
            .ToArray();

        Assert.True(
            missingMembers.Length == 0,
            $"Missing required Problem Details members: {string.Join(", ", missingMembers)}. Payload: {root}");
        Assert.Equal("validation_failed", root.GetProperty("errorCode").GetString());
        Assert.True(root.GetProperty("errors").TryGetProperty("Port", out _));
    }

    [Fact]
    public async Task Dto_validation_problem_details_values_are_complete_and_safe()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateClient();
        var serverId = await ServerIdAsync(client, "DC-HOU-SQL01");

        var response = await client.PostAsJsonAsync(
            "/api/v1/sql-instances",
            InstanceRequest(serverId, "INVALID-DTO-VALUES") with { Port = 70000 });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal("application/problem+json", response.Content.Headers.ContentType?.MediaType);
        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var root = document.RootElement;
        Assert.Equal((int)HttpStatusCode.BadRequest, root.GetProperty("status").GetInt32());
        Assert.Equal("Request validation failed", root.GetProperty("title").GetString());
        Assert.Equal("One or more request fields are invalid.", root.GetProperty("detail").GetString());
        Assert.Equal("/api/v1/sql-instances", root.GetProperty("instance").GetString());
        Assert.Equal("validation_failed", root.GetProperty("errorCode").GetString());
        Assert.False(string.IsNullOrWhiteSpace(root.GetProperty("correlationId").GetString()));
        Assert.True(root.GetProperty("errors").TryGetProperty("Port", out _));
    }

    [Fact]
    public async Task Cross_customer_records_cannot_be_read_mutated_enumerated_or_related()
    {
        using var factory = new LgrWebApplicationFactory();
        var otherScope = await factory.SeedSecondTenantAsync();
        using var other = ContextClient(factory, otherScope.CustomerId, otherScope.ProjectId);
        var (otherInstance, otherTag) = await CreateInstanceAsync(
            other,
            LgrWebApplicationFactory.SecondTenantServerId,
            "OTHER-TENANT");
        using var demo = factory.CreateClient();

        Assert.Equal(HttpStatusCode.NotFound, (await demo.GetAsync($"/api/v1/sql-instances/{otherInstance.Id}")).StatusCode);
        var list = await demo.GetFromJsonAsync<PagedResult<SqlInstanceDto>>(
            "/api/v1/sql-instances?search=OTHER-TENANT",
            JsonOptions);
        Assert.Empty(list!.Items);
        Assert.Equal(
            HttpStatusCode.NotFound,
            (await SendWithIfMatchAsync(
                demo,
                HttpMethod.Put,
                $"/api/v1/sql-instances/{otherInstance.Id}",
                InstanceRequest(LgrWebApplicationFactory.SecondTenantServerId, otherInstance.InstanceName),
                otherTag)).StatusCode);
        Assert.Equal(
            HttpStatusCode.NotFound,
            (await SendWithIfMatchAsync(
                demo,
                HttpMethod.Delete,
                $"/api/v1/sql-instances/{otherInstance.Id}",
                null,
                otherTag)).StatusCode);
        Assert.Equal(
            HttpStatusCode.NotFound,
            (await demo.PostAsJsonAsync(
                "/api/v1/sql-databases",
                DatabaseRequest(otherInstance.Id, "IdorAttempt"))).StatusCode);
    }

    [Fact]
    public async Task Cross_project_direct_object_and_relationship_attacks_are_rejected()
    {
        using var factory = new LgrWebApplicationFactory();
        var otherScope = await factory.SeedSecondProjectForDemoCustomerAsync();
        using var otherProject = ContextClient(factory, SeedIds.DemoCustomer, otherScope.ProjectId);
        var (otherInstance, otherTag) = await CreateInstanceAsync(otherProject, otherScope.ServerId, "OTHER-PROJECT");
        using var demo = factory.CreateClient();

        Assert.Equal(HttpStatusCode.NotFound, (await demo.GetAsync($"/api/v1/sql-instances/{otherInstance.Id}")).StatusCode);
        Assert.Equal(
            HttpStatusCode.NotFound,
            (await demo.PostAsJsonAsync(
                "/api/v1/sql-databases",
                DatabaseRequest(otherInstance.Id, "CrossProject"))).StatusCode);

        var demoServer = await ServerIdAsync(demo, "DC-HOU-SQL01");
        var (demoInstance, demoTag) = await CreateInstanceAsync(demo, demoServer, "DEMO-PROJECT");
        var reparentAttack = await SendWithIfMatchAsync(
            demo,
            HttpMethod.Put,
            $"/api/v1/sql-instances/{demoInstance.Id}",
            InstanceRequest(otherScope.ServerId, demoInstance.InstanceName),
            demoTag);
        Assert.Equal(HttpStatusCode.NotFound, reparentAttack.StatusCode);
        var unchanged = await demo.GetFromJsonAsync<SqlInstanceDto>(
            $"/api/v1/sql-instances/{demoInstance.Id}",
            JsonOptions);
        Assert.Equal(demoServer, unchanged!.Server.Id);

        Assert.Equal(
            HttpStatusCode.NotFound,
            (await SendWithIfMatchAsync(
                demo,
                HttpMethod.Delete,
                $"/api/v1/sql-instances/{otherInstance.Id}",
                null,
                otherTag)).StatusCode);
    }

    [Fact]
    public async Task Mismatched_customer_and_project_context_fails_closed()
    {
        using var factory = new LgrWebApplicationFactory();
        var otherScope = await factory.SeedSecondTenantAsync();
        using var mismatched = ContextClient(factory, otherScope.CustomerId, SeedIds.DemoProject);

        Assert.Equal(
            HttpStatusCode.NotFound,
            (await mismatched.GetAsync("/api/v1/sql-instances")).StatusCode);
        Assert.Equal(
            HttpStatusCode.NotFound,
            (await mismatched.PostAsJsonAsync(
                "/api/v1/sql-instances",
                InstanceRequest(LgrWebApplicationFactory.SecondTenantServerId, "MISMATCHED-CONTEXT"))).StatusCode);
    }

    [Fact]
    public async Task Same_project_relationship_moves_are_explicit_and_audited()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateClient();
        var firstServer = await ServerIdAsync(client, "DC-HOU-SQL01");
        var secondServer = await ServerIdAsync(client, "DC-REV-SQL01");
        var (firstInstance, firstInstanceTag) = await CreateInstanceAsync(client, firstServer, "MOVE-SOURCE");
        var (secondInstance, _) = await CreateInstanceAsync(client, secondServer, "MOVE-TARGET");
        var (database, databaseTag) = await CreateDatabaseAsync(client, firstInstance.Id, "MoveDatabase");

        var movedInstance = await SendWithIfMatchAsync(
            client,
            HttpMethod.Put,
            $"/api/v1/sql-instances/{firstInstance.Id}",
            InstanceRequest(secondServer, firstInstance.InstanceName),
            firstInstanceTag);
        var movedDatabase = await SendWithIfMatchAsync(
            client,
            HttpMethod.Put,
            $"/api/v1/sql-databases/{database.Id}",
            DatabaseRequest(secondInstance.Id, database.Name),
            databaseTag);
        Assert.Equal(HttpStatusCode.OK, movedInstance.StatusCode);
        Assert.Equal(HttpStatusCode.OK, movedDatabase.StatusCode);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var audit = await db.AuditEvents
            .Where(x => x.EntityId == firstInstance.Id || x.EntityId == database.Id)
            .ToListAsync();
        Assert.Contains(audit, x =>
            x.Action == "SqlInstanceRelationshipChanged"
            && x.PropertyName == "ServerId"
            && x.OldValue == firstServer.ToString()
            && x.NewValue == secondServer.ToString());
        Assert.Contains(audit, x =>
            x.Action == "SqlDatabaseRelationshipChanged"
            && x.PropertyName == "SqlInstanceId"
            && x.OldValue == firstInstance.Id.ToString()
            && x.NewValue == secondInstance.Id.ToString());
    }

    [Fact]
    public async Task Parent_deletes_are_restricted_while_active_dependants_exist()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateClient();
        var serverResponse = await client.PostAsJsonAsync(
            "/api/servers",
            new ServerRequest(
                "SYNTH-DELETE-SQL01",
                "Test",
                "Synthetic OS",
                "192.0.2.30",
                2,
                4096,
                100,
                "On",
                "Not Started",
                []));
        serverResponse.EnsureSuccessStatusCode();
        var server = (await serverResponse.Content.ReadFromJsonAsync<ServerDto>(JsonOptions))!;
        var (instance, instanceTag) = await CreateInstanceAsync(client, server.Id, "DELETE-RESTRICT");
        var (database, databaseTag) = await CreateDatabaseAsync(client, instance.Id, "DeleteRestriction");

        Assert.Equal(HttpStatusCode.Conflict, (await client.DeleteAsync($"/api/servers/{server.Id}")).StatusCode);
        Assert.Equal(
            HttpStatusCode.Conflict,
            (await SendWithIfMatchAsync(
                client,
                HttpMethod.Delete,
                $"/api/v1/sql-instances/{instance.Id}",
                null,
                instanceTag)).StatusCode);
        Assert.Equal(
            HttpStatusCode.NoContent,
            (await SendWithIfMatchAsync(
                client,
                HttpMethod.Delete,
                $"/api/v1/sql-databases/{database.Id}",
                null,
                databaseTag)).StatusCode);
        Assert.Equal(
            HttpStatusCode.NoContent,
            (await SendWithIfMatchAsync(
                client,
                HttpMethod.Delete,
                $"/api/v1/sql-instances/{instance.Id}",
                null,
                instanceTag)).StatusCode);
    }

    [Fact]
    public async Task Instance_and_database_lists_are_bounded_paged_and_filterable_above_200_assets()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateClient();
        var firstServer = await ServerIdAsync(client, "DC-HOU-SQL01");
        var secondServer = await ServerIdAsync(client, "DC-REV-SQL01");
        var now = DateTimeOffset.UtcNow;
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.SqlInstances.AddRange(Enumerable.Range(0, 205).Select(index => new SqlInstance
            {
                Id = Guid.NewGuid(),
                CustomerId = SeedIds.DemoCustomer,
                ProjectId = SeedIds.DemoProject,
                ServerId = index % 2 == 0 ? firstServer : secondServer,
                InstanceName = $"SYNTH-INSTANCE-{index:000}",
                NormalizedInstanceName = $"SYNTH-INSTANCE-{index:000}",
                SqlVersion = "Synthetic SQL",
                Edition = "Developer",
                ServiceStatus = index % 2 == 0 ? SqlInstanceServiceStatuses.Running : SqlInstanceServiceStatuses.Stopped,
                DiscoverySource = "Manual",
                CreatedAt = now,
                UpdatedAt = now,
                CreatedBy = "synthetic.test",
                UpdatedBy = "synthetic.test",
                RowVersion = BitConverter.GetBytes(index + 1L)
            }));
            await db.SaveChangesAsync();
        }

        var boundedInstances = await client.GetFromJsonAsync<PagedResult<SqlInstanceDto>>(
            "/api/v1/sql-instances?pageSize=500",
            JsonOptions);
        var secondPage = await client.GetFromJsonAsync<PagedResult<SqlInstanceDto>>(
            "/api/v1/sql-instances?page=2&pageSize=50",
            JsonOptions);
        var filteredInstances = await client.GetFromJsonAsync<PagedResult<SqlInstanceDto>>(
            $"/api/v1/sql-instances?pageSize=200&serverId={firstServer}&serviceStatus=running",
            JsonOptions);
        Assert.Equal(205, boundedInstances!.TotalCount);
        Assert.Equal(200, boundedInstances.Items.Count);
        Assert.Equal(200, boundedInstances.PageSize);
        Assert.Equal(50, secondPage!.Items.Count);
        Assert.All(filteredInstances!.Items, x =>
        {
            Assert.Equal(firstServer, x.Server.Id);
            Assert.Equal(SqlInstanceServiceStatuses.Running, x.ServiceStatus);
        });

        var parent = boundedInstances.Items[0];
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.SqlDatabases.AddRange(Enumerable.Range(0, 205).Select(index => new SqlDatabase
            {
                Id = Guid.NewGuid(),
                CustomerId = SeedIds.DemoCustomer,
                ProjectId = SeedIds.DemoProject,
                SqlInstanceId = parent.Id,
                Name = $"SYNTH-DATABASE-{index:000}",
                NormalizedName = $"SYNTH-DATABASE-{index:000}",
                SizeMb = index,
                CompatibilityLevel = 160,
                RecoveryModel = SqlDatabaseRecoveryModels.Full,
                Status = index % 2 == 0 ? SqlDatabaseStatuses.Online : SqlDatabaseStatuses.Offline,
                CreatedAt = now,
                UpdatedAt = now,
                CreatedBy = "synthetic.test",
                UpdatedBy = "synthetic.test",
                RowVersion = BitConverter.GetBytes(index + 1000L)
            }));
            await db.SaveChangesAsync();
        }

        var boundedDatabases = await client.GetFromJsonAsync<PagedResult<SqlDatabaseDto>>(
            "/api/v1/sql-databases?pageSize=500",
            JsonOptions);
        var filteredDatabases = await client.GetFromJsonAsync<PagedResult<SqlDatabaseDto>>(
            $"/api/v1/sql-databases?pageSize=200&sqlInstanceId={parent.Id}&status=online",
            JsonOptions);
        Assert.Equal(205, boundedDatabases!.TotalCount);
        Assert.Equal(200, boundedDatabases.Items.Count);
        Assert.All(filteredDatabases!.Items, x =>
        {
            Assert.Equal(parent.Id, x.SqlInstance.Id);
            Assert.Equal(SqlDatabaseStatuses.Online, x.Status);
        });
    }

    [Fact]
    public async Task Composite_database_constraints_reject_cross_project_parent_ownership()
    {
        using var factory = new LgrWebApplicationFactory();
        var otherScope = await factory.SeedSecondProjectForDemoCustomerAsync();
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var now = DateTimeOffset.UtcNow;
        db.SqlInstances.Add(new SqlInstance
        {
            Id = Guid.NewGuid(),
            CustomerId = SeedIds.DemoCustomer,
            ProjectId = SeedIds.DemoProject,
            ServerId = otherScope.ServerId,
            InstanceName = "INVALID-RELATIONSHIP",
            NormalizedInstanceName = "INVALID-RELATIONSHIP",
            SqlVersion = "Synthetic SQL",
            Edition = "Developer",
            ServiceStatus = SqlInstanceServiceStatuses.Running,
            DiscoverySource = "Manual",
            CreatedAt = now,
            UpdatedAt = now,
            CreatedBy = "synthetic.test",
            UpdatedBy = "synthetic.test",
            RowVersion = BitConverter.GetBytes(999L)
        });

        await Assert.ThrowsAsync<DbUpdateException>(() => db.SaveChangesAsync());
    }

    [Fact]
    public void Model_uses_tenant_leading_relationships_and_filtered_business_uniqueness()
    {
        using var factory = new LgrWebApplicationFactory();
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var instanceType = db.Model.FindEntityType(typeof(SqlInstance))!;
        var databaseType = db.Model.FindEntityType(typeof(SqlDatabase))!;

        Assert.Contains(instanceType.GetForeignKeys(), foreignKey =>
            foreignKey.Properties.Select(x => x.Name)
                .SequenceEqual(["CustomerId", "ProjectId", "ServerId"])
            && foreignKey.PrincipalKey.Properties.Select(x => x.Name)
                .SequenceEqual(["CustomerId", "ProjectId", "Id"]));
        Assert.Contains(databaseType.GetForeignKeys(), foreignKey =>
            foreignKey.Properties.Select(x => x.Name)
                .SequenceEqual(["CustomerId", "ProjectId", "SqlInstanceId"])
            && foreignKey.PrincipalKey.Properties.Select(x => x.Name)
                .SequenceEqual(["CustomerId", "ProjectId", "Id"]));

        var instanceUnique = instanceType.GetIndexes().Single(index =>
            index.GetDatabaseName() == "UX_SqlInstances_Owner_Server_NormalizedName_Active");
        Assert.True(instanceUnique.IsUnique);
        Assert.Equal(["CustomerId", "ProjectId", "ServerId", "NormalizedInstanceName"],
            instanceUnique.Properties.Select(x => x.Name));
        Assert.Equal("[IsDeleted] = 0", instanceUnique.GetFilter());

        var databaseUnique = databaseType.GetIndexes().Single(index =>
            index.GetDatabaseName() == "UX_SqlDatabases_Owner_Instance_NormalizedName_Active");
        Assert.True(databaseUnique.IsUnique);
        Assert.Equal(["CustomerId", "ProjectId", "SqlInstanceId", "NormalizedName"],
            databaseUnique.Properties.Select(x => x.Name));
        Assert.Equal("[IsDeleted] = 0", databaseUnique.GetFilter());
    }

    [Fact]
    public void Sql_server_provider_generates_rowversion_filtered_indexes_and_composite_foreign_keys()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlServer("Server=(local);Database=SyntheticSchemaOnly;Integrated Security=True;TrustServerCertificate=True")
            .Options;
        using var db = new AppDbContext(options, new FixedSyntheticContext());

        var script = db.Database.GenerateCreateScript();

        Assert.Contains("[RowVersion] rowversion NOT NULL", script, StringComparison.Ordinal);
        Assert.Contains(
            "CONSTRAINT [FK_SqlInstances_Servers_CustomerId_ProjectId_ServerId] FOREIGN KEY ([CustomerId], [ProjectId], [ServerId])",
            script,
            StringComparison.Ordinal);
        Assert.Contains(
            "CONSTRAINT [FK_SqlDatabases_SqlInstances_CustomerId_ProjectId_SqlInstanceId] FOREIGN KEY ([CustomerId], [ProjectId], [SqlInstanceId])",
            script,
            StringComparison.Ordinal);
        Assert.Contains(
            "CREATE UNIQUE INDEX [UX_SqlInstances_Owner_Server_NormalizedName_Active]",
            script,
            StringComparison.Ordinal);
        Assert.Contains("WHERE [IsDeleted] = 0", script, StringComparison.Ordinal);
    }

    [Fact]
    public async Task Existing_synthetic_ownership_preflight_has_no_orphaned_project_relationships()
    {
        using var factory = new LgrWebApplicationFactory();
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var orphanedServers = await (
            from server in db.Servers
            join project in db.Projects
                on new { server.CustomerId, server.ProjectId }
                equals new { project.CustomerId, ProjectId = project.Id }
                into projects
            from project in projects.DefaultIfEmpty()
            where project == null
            select server.Id).CountAsync();
        var orphanedBatches = await (
            from batch in db.ImportBatches
            join project in db.Projects
                on new { batch.CustomerId, batch.ProjectId }
                equals new { project.CustomerId, ProjectId = project.Id }
                into projects
            from project in projects.DefaultIfEmpty()
            where project == null
            select batch.Id).CountAsync();

        Assert.Equal(0, orphanedServers);
        Assert.Equal(0, orphanedBatches);
    }

    private static async Task<Guid> ServerIdAsync(HttpClient client, string hostname)
    {
        var servers = await client.GetFromJsonAsync<PagedResult<ServerDto>>("/api/servers?pageSize=200", JsonOptions);
        return servers!.Items.Single(x => x.Hostname == hostname).Id;
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
        new(sqlInstanceId, name, 1024, 160, SqlDatabaseRecoveryModels.Full, "Latin1_General_100_CI_AS", SqlDatabaseStatuses.Online);

    private static HttpClient ContextClient(LgrWebApplicationFactory factory, Guid customerId, Guid projectId)
    {
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-Customer-Id", customerId.ToString());
        client.DefaultRequestHeaders.Add("X-Project-Id", projectId.ToString());
        client.DefaultRequestHeaders.Add("X-User-Name", "synthetic.tester@example.test");
        return client;
    }

    private static async Task<HttpResponseMessage> SendWithIfMatchAsync(
        HttpClient client,
        HttpMethod method,
        string uri,
        object? body,
        string entityTag)
    {
        var message = new HttpRequestMessage(method, uri);
        if (body is not null)
        {
            message.Content = JsonContent.Create(body, options: JsonOptions);
        }

        message.Headers.TryAddWithoutValidation("If-Match", entityTag);
        return await client.SendAsync(message);
    }

    private sealed class FixedSyntheticContext : ICurrentCustomerContext
    {
        public Guid CustomerId => SeedIds.DemoCustomer;
        public Guid ProjectId => SeedIds.DemoProject;
        public string UserName => "synthetic.schema@example.test";
        public string CorrelationId => "synthetic-schema-generation";
    }
}
