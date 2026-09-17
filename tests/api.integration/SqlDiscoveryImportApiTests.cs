using System.Net;
using System.Net.Http.Json;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Domain;
using LgrTransformationMigration.Api.Infrastructure;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace LgrTransformationMigration.Api.IntegrationTests;

public sealed class SqlDiscoveryImportApiTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    [Fact]
    public async Task Instance_preview_commit_idempotency_protected_fields_history_and_audit_are_atomic()
    {
        using var factory = new LgrWebApplicationFactory();
        using var dba = factory.CreateClient();
        using var analyst = factory.CreateAuthenticatedClient("analyst-project-a", SeedIds.DemoProject);
        var servers = await ServersAsync(dba);
        var updated = await CreateInstanceAsync(
            dba,
            ServerId(servers, "DC-REV-SQL01"),
            "SYNTH-UPDATE",
            "SQL Server 2019",
            "Standard",
            1500,
            SqlInstanceServiceStatuses.Stopped,
            "SYNTHETIC\\protected-service");
        using var assessmentResponse = await dba.PostAsJsonAsync(
            "/api/v1/sql-assessments",
            new SqlAssessmentCreateV1(
                updated.Dto.Id,
                null,
                SqlAssessmentStatuses.InProgress,
                SqlReadinessStatuses.AtRisk,
                SqlAssessmentTargetPlatforms.AzureSqlManagedInstance,
                null,
                SqlMigrationApproaches.ToBeDetermined,
                "Synthetic assessment blocker",
                "Synthetic protected finding",
                "Synthetic protected planning note",
                null));
        Assert.Equal(HttpStatusCode.Created, assessmentResponse.StatusCode);
        var protectedAssessment = (await assessmentResponse.Content.ReadFromJsonAsync<SqlAssessmentDto>(JsonOptions))!;
        await CreateInstanceAsync(
            dba,
            ServerId(servers, "DC-FIN-SQL01"),
            "SYNTH-UNCHANGED",
            "SQL Server 2022",
            "Standard",
            1433,
            SqlInstanceServiceStatuses.Running,
            "SYNTHETIC\\unchanged-protected");
        var before = await dba.GetFromJsonAsync<PagedResult<SqlInstanceDto>>(
            "/api/v1/sql-instances?pageSize=200",
            JsonOptions);

        var (uploaded, uploadTag) = await UploadFixtureAsync(
            analyst,
            DiscoverySourceTypes.SqlInstanceCsvV1,
            "SQLI-V1-POS-01.csv");
        var (preview, previewTag) = await PreviewAsync(analyst, uploaded.Id, uploadTag);
        var afterPreview = await dba.GetFromJsonAsync<PagedResult<SqlInstanceDto>>(
            "/api/v1/sql-instances?pageSize=200",
            JsonOptions);

        Assert.Equal(before!.TotalCount, afterPreview!.TotalCount);
        Assert.Equal(3, preview.TotalRows);
        Assert.Equal(1, preview.CreateCount);
        Assert.Equal(1, preview.UpdateCount);
        Assert.Equal(1, preview.UnchangedCount);
        Assert.Equal(0, preview.WarningCount);
        Assert.Equal(0, preview.RejectCount);

        var rows = await analyst.GetFromJsonAsync<PagedResult<SqlDiscoveryImportRowDto>>(
            $"/api/v1/discovery/imports/{preview.Id}/rows",
            JsonOptions);
        Assert.Equal(
            [ImportClassifications.Create, ImportClassifications.Update, ImportClassifications.Unchanged],
            rows!.Items.Select(row => row.Classification));

        var (committed, _) = await CommitAsync(analyst, preview.Id, previewTag, "SQL-RECON-01-instance");
        Assert.Equal(ImportBatchStatuses.Committed, committed.Status);
        var retry = await CommitResponseAsync(analyst, preview.Id, previewTag, "SQL-RECON-01-instance");
        Assert.Equal(HttpStatusCode.OK, retry.StatusCode);
        var conflict = await CommitResponseAsync(analyst, preview.Id, previewTag, "SQL-RECON-01-other");
        await AssertProblemDetailsAsync(conflict, HttpStatusCode.Conflict, "data_conflict");

        var inventory = await dba.GetFromJsonAsync<PagedResult<SqlInstanceDto>>(
            "/api/v1/sql-instances?pageSize=200",
            JsonOptions);
        var updatedAfter = inventory!.Items.Single(instance => instance.Id == updated.Dto.Id);
        Assert.Equal("Enterprise", updatedAfter.Edition);
        Assert.Equal(1500, updatedAfter.Port);
        Assert.Equal("SYNTHETIC\\protected-service", updatedAfter.ServiceAccountName);
        var assessmentAfter = await dba.GetFromJsonAsync<SqlAssessmentDto>(
            $"/api/v1/sql-assessments/{protectedAssessment.Id}",
            JsonOptions);
        Assert.Equal(protectedAssessment.AssessmentStatus, assessmentAfter!.AssessmentStatus);
        Assert.Equal(protectedAssessment.ReadinessStatus, assessmentAfter.ReadinessStatus);
        Assert.Equal(protectedAssessment.TargetPlatform, assessmentAfter.TargetPlatform);
        Assert.Equal(protectedAssessment.MigrationApproach, assessmentAfter.MigrationApproach);
        Assert.Equal(protectedAssessment.Blockers, assessmentAfter.Blockers);
        Assert.Equal(protectedAssessment.Findings, assessmentAfter.Findings);
        Assert.Equal(protectedAssessment.Notes, assessmentAfter.Notes);
        Assert.Equal(protectedAssessment.Version, assessmentAfter.Version);
        var created = inventory.Items.Single(instance => instance.InstanceName == "SYNTH-CREATE");

        var history = await dba.GetFromJsonAsync<PagedResult<SqlInstanceDiscoverySnapshotDto>>(
            $"/api/v1/sql-instances/{created.Id}/discovery-history",
            JsonOptions);
        Assert.Single(history!.Items);
        Assert.Equal(preview.Id, history.Items.Single().ImportBatchId);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.Equal(3, await db.SqlInstanceDiscoverySnapshots.IgnoreQueryFilters()
            .CountAsync(snapshot => snapshot.ImportBatchId == preview.Id));
        Assert.Equal(3, await db.SqlInstances.IgnoreQueryFilters()
            .CountAsync(instance => instance.LastImportBatchId == preview.Id));
        Assert.Contains(await db.AuditEvents.IgnoreQueryFilters().ToListAsync(), audit =>
            audit.EntityId == preview.Id
            && audit.Action == "SqlDiscoveryImportCommitted"
            && audit.ChangedBy == "local-test:70000000-0000-0000-0000-000000000005"
            && audit.ProjectId == SeedIds.DemoProject
            && !string.IsNullOrWhiteSpace(audit.CorrelationId));
        var immutableSnapshot = await db.SqlInstanceDiscoverySnapshots.IgnoreQueryFilters()
            .FirstAsync(snapshot => snapshot.ImportBatchId == preview.Id);
        immutableSnapshot.Edition = "Attempted mutation";
        await Assert.ThrowsAsync<InvalidOperationException>(() => db.SaveChangesAsync());
    }

    [Fact]
    public async Task Database_import_preserves_blank_optional_value_and_snapshots_every_safe_row()
    {
        using var factory = new LgrWebApplicationFactory();
        using var dba = factory.CreateClient();
        using var analyst = factory.CreateAuthenticatedClient("analyst-project-a", SeedIds.DemoProject);
        var parent = await CreateInstanceAsync(
            dba,
            ServerId(await ServersAsync(dba), "DC-HOU-SQL01"),
            "SYNTH-PARENT");
        var update = await CreateDatabaseAsync(
            dba,
            parent.Dto.Id,
            "SyntheticUpdate",
            1024,
            140,
            SqlDatabaseRecoveryModels.Simple,
            "Synthetic_Collation",
            SqlDatabaseStatuses.Offline);
        await CreateDatabaseAsync(
            dba,
            parent.Dto.Id,
            "SyntheticUnchanged",
            1024,
            160,
            SqlDatabaseRecoveryModels.Full,
            "Latin1_General_100_CI_AS",
            SqlDatabaseStatuses.Online);

        var (uploaded, uploadTag) = await UploadFixtureAsync(
            analyst,
            DiscoverySourceTypes.SqlDatabaseCsvV1,
            "SQLD-V1-POS-01.csv");
        var (preview, previewTag) = await PreviewAsync(analyst, uploaded.Id, uploadTag);
        Assert.Equal((1, 1, 1, 0),
            (preview.CreateCount, preview.UpdateCount, preview.UnchangedCount, preview.RejectCount));

        await CommitAsync(analyst, preview.Id, previewTag, "SQL-HISTORY-01-database");
        var inventory = await dba.GetFromJsonAsync<PagedResult<SqlDatabaseDto>>(
            "/api/v1/sql-databases?pageSize=200",
            JsonOptions);
        var updated = inventory!.Items.Single(database => database.Id == update.Dto.Id);
        Assert.Equal(4096, updated.SizeMb);
        Assert.Equal(SqlDatabaseStatuses.RecoveryPending, updated.Status);
        Assert.Equal("Synthetic_Collation", updated.Collation);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.Equal(3, await db.SqlDatabaseDiscoverySnapshots.IgnoreQueryFilters()
            .CountAsync(snapshot => snapshot.ImportBatchId == preview.Id));
        var unchanged = inventory.Items.Single(database => database.Name == "SyntheticUnchanged");
        var history = await dba.GetFromJsonAsync<PagedResult<SqlDatabaseDiscoverySnapshotDto>>(
            $"/api/v1/sql-databases/{unchanged.Id}/discovery-history?pageSize=200",
            JsonOptions);
        Assert.Single(history!.Items);
    }

    [Fact]
    public async Task Stale_preview_rejects_whole_commit_without_snapshot_or_import_mutation()
    {
        using var factory = new LgrWebApplicationFactory();
        using var dba = factory.CreateClient();
        using var analyst = factory.CreateAuthenticatedClient("analyst-project-a", SeedIds.DemoProject);
        var instance = await CreateInstanceAsync(
            dba,
            ServerId(await ServersAsync(dba), "DC-HOU-SQL01"),
            "SYNTH-STALE",
            serviceAccountName: "SYNTHETIC\\stale-protected");
        var csv =
            "Server,Instance Name,SQL Version,Edition,Port,Service Status,Discovery Source,Last Discovered At\n" +
            "DC-HOU-SQL01,SYNTH-STALE,SQL Server 2022,Enterprise,1433,Running,Synthetic discovery,2026-09-15T12:00:00Z\n";
        var (uploaded, uploadTag) = await UploadTextAsync(
            analyst,
            DiscoverySourceTypes.SqlInstanceCsvV1,
            "SQL-RECON-01-stale.csv",
            csv);
        var (preview, previewTag) = await PreviewAsync(analyst, uploaded.Id, uploadTag);

        var changedRequest = InstanceRequest(
            instance.Dto.Server.Id,
            instance.Dto.InstanceName,
            "SQL Server 2022 CU",
            "Standard",
            1433,
            SqlInstanceServiceStatuses.Running,
            "SYNTHETIC\\stale-protected");
        using var changed = await SendWithIfMatchAsync(
            dba,
            HttpMethod.Put,
            $"/api/v1/sql-instances/{instance.Dto.Id}",
            changedRequest,
            instance.Tag);
        changed.EnsureSuccessStatusCode();

        using var response = await CommitResponseAsync(
            analyst,
            preview.Id,
            previewTag,
            "SQL-RECON-01-stale");
        await AssertProblemDetailsAsync(response, HttpStatusCode.PreconditionFailed, "stale_version");
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.Empty(await db.SqlInstanceDiscoverySnapshots.IgnoreQueryFilters()
            .Where(snapshot => snapshot.ImportBatchId == preview.Id).ToListAsync());
        var after = await db.SqlInstances.IgnoreQueryFilters().SingleAsync(item => item.Id == instance.Dto.Id);
        Assert.Equal("SQL Server 2022 CU", after.SqlVersion);
        Assert.Equal("Standard", after.Edition);
        Assert.Equal("SYNTHETIC\\stale-protected", after.ServiceAccountName);
        var batch = await db.ImportBatches.IgnoreQueryFilters().SingleAsync(item => item.Id == preview.Id);
        Assert.Equal(ImportBatchStatuses.PreviewReady, batch.Status);
        Assert.Null(batch.CommitIdempotencyKeyHash);
    }

    [Fact]
    public async Task Permission_matrix_raw_row_boundary_and_cancel_preconditions_are_enforced()
    {
        using var factory = new LgrWebApplicationFactory();
        using var analyst = factory.CreateAuthenticatedClient("analyst-project-a", SeedIds.DemoProject);
        var (batch, uploadTag) = await UploadFixtureAsync(
            analyst,
            DiscoverySourceTypes.SqlInstanceCsvV1,
            "SQLI-V1-WARN-01.csv");
        var (preview, previewTag) = await PreviewAsync(analyst, batch.Id, uploadTag);
        var rows = await analyst.GetFromJsonAsync<PagedResult<SqlDiscoveryImportRowDto>>(
            $"/api/v1/discovery/imports/{batch.Id}/rows",
            JsonOptions);
        var rowId = rows!.Items.Single().Id;

        foreach (var alias in new[]
                 {
                     "dba-project-a", "reader-project-a", "architect-project-a", "manager-project-a",
                     "analyst-project-a"
                 })
        {
            using var client = factory.CreateAuthenticatedClient(alias, SeedIds.DemoProject);
            using var read = await client.GetAsync($"/api/v1/discovery/imports/{batch.Id}");
            Assert.Equal(HttpStatusCode.OK, read.StatusCode);
        }

        foreach (var alias in new[] { "dba-project-a", "reader-project-a", "architect-project-a", "manager-project-a" })
        {
            using var client = factory.CreateAuthenticatedClient(alias, SeedIds.DemoProject);
            using var deniedUpload = await UploadResponseAsync(
                client,
                DiscoverySourceTypes.SqlInstanceCsvV1,
                "denied.csv",
                Encoding.UTF8.GetBytes(ValidSingleInstanceCsv("SYNTH-DENIED")));
            await AssertProblemDetailsAsync(deniedUpload, HttpStatusCode.Forbidden, "permission_denied");
        }

        using var manager = factory.CreateAuthenticatedClient("manager-project-a", SeedIds.DemoProject);
        using var rawDenied = await manager.GetAsync($"/api/v1/discovery/imports/{batch.Id}/rows/{rowId}");
        await AssertProblemDetailsAsync(rawDenied, HttpStatusCode.Forbidden, "permission_denied");
        using var dba = factory.CreateClient();
        using var rawAllowed = await dba.GetAsync($"/api/v1/discovery/imports/{batch.Id}/rows/{rowId}");
        Assert.Equal(HttpStatusCode.OK, rawAllowed.StatusCode);

        using var missingPrecondition = await analyst.PostAsync(
            $"/api/v1/discovery/imports/{batch.Id}/cancel",
            null);
        await AssertProblemDetailsAsync(missingPrecondition, (HttpStatusCode)428, "precondition_required");
        using var stale = await PostWithIfMatchAsync(
            analyst,
            $"/api/v1/discovery/imports/{batch.Id}/cancel",
            "\"stale\"");
        await AssertProblemDetailsAsync(stale, HttpStatusCode.PreconditionFailed, "stale_version");
        using var cancelledResponse = await PostWithIfMatchAsync(
            analyst,
            $"/api/v1/discovery/imports/{batch.Id}/cancel",
            previewTag);
        cancelledResponse.EnsureSuccessStatusCode();
        var cancelled = await cancelledResponse.Content.ReadFromJsonAsync<DiscoveryImportBatchDto>(JsonOptions);
        Assert.Equal(ImportBatchStatuses.Cancelled, cancelled!.Status);
        using var auditScope = factory.Services.CreateScope();
        var auditDb = auditScope.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.Equal(4, await auditDb.AuditEvents.IgnoreQueryFilters()
            .CountAsync(audit => audit.Action == "SqlDiscoveryUploadDenied"));
        Assert.Contains(await auditDb.AuditEvents.IgnoreQueryFilters().ToListAsync(), audit =>
            audit.EntityId == batch.Id
            && audit.Action == "SqlDiscoveryImportCancelled"
            && !string.IsNullOrWhiteSpace(audit.CorrelationId));
    }

    [Fact]
    public async Task Negative_fixture_rejects_all_rows_redacts_credentials_and_never_changes_inventory()
    {
        using var factory = new LgrWebApplicationFactory();
        using var analyst = factory.CreateAuthenticatedClient("analyst-project-a", SeedIds.DemoProject);
        using var dba = factory.CreateClient();
        var before = await dba.GetFromJsonAsync<PagedResult<SqlInstanceDto>>(
            "/api/v1/sql-instances?pageSize=200",
            JsonOptions);
        var (batch, uploadTag) = await UploadFixtureAsync(
            analyst,
            DiscoverySourceTypes.SqlInstanceCsvV1,
            "SQLI-V1-NEG-01.csv");
        var (preview, _) = await PreviewAsync(analyst, batch.Id, uploadTag);
        Assert.Equal(preview.TotalRows, preview.RejectCount);
        Assert.Equal(0, preview.ValidRows);

        var rows = await analyst.GetFromJsonAsync<PagedResult<SqlDiscoveryImportRowDto>>(
            $"/api/v1/discovery/imports/{batch.Id}/rows?pageSize=200",
            JsonOptions);
        var detail = await analyst.GetFromJsonAsync<SqlDiscoveryImportRowDetailDto>(
            $"/api/v1/discovery/imports/{batch.Id}/rows/{rows!.Items.First().Id}",
            JsonOptions);
        Assert.Equal("[REDACTED]", detail!.RawData["Service Account Name"]);
        Assert.DoesNotContain("synthetic-credential-negative", JsonSerializer.Serialize(detail, JsonOptions));
        var after = await dba.GetFromJsonAsync<PagedResult<SqlInstanceDto>>(
            "/api/v1/sql-instances?pageSize=200",
            JsonOptions);
        Assert.Equal(before!.TotalCount, after!.TotalCount);
    }

    [Fact]
    public async Task Cross_project_batches_and_history_are_non_enumerating()
    {
        using var factory = new LgrWebApplicationFactory();
        var other = await factory.SeedSecondProjectForDemoCustomerAsync();
        Guid batchId;
        Guid instanceId;
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var now = DateTimeOffset.UtcNow;
            batchId = Guid.NewGuid();
            instanceId = Guid.NewGuid();
            db.ImportBatches.Add(new ImportBatch
            {
                Id = batchId,
                CustomerId = SeedIds.DemoCustomer,
                ProjectId = other.ProjectId,
                SourceType = DiscoverySourceTypes.SqlInstanceCsvV1,
                OriginalFileName = "synthetic-cross-project.csv",
                FileHash = new string('a', 64),
                FileSizeBytes = 1,
                Status = ImportBatchStatuses.Committed,
                UploadedBy = "synthetic-test",
                UploadedAt = now,
                CommittedAt = now,
                RowVersion = new byte[8]
            });
            db.SqlInstances.Add(new SqlInstance
            {
                Id = instanceId,
                CustomerId = SeedIds.DemoCustomer,
                ProjectId = other.ProjectId,
                ServerId = other.ServerId,
                InstanceName = "CROSS-PROJECT",
                NormalizedInstanceName = "CROSS-PROJECT",
                SqlVersion = "SQL Server 2022",
                Edition = "Standard",
                ServiceStatus = SqlInstanceServiceStatuses.Running,
                DiscoverySource = "Synthetic",
                CreatedAt = now,
                UpdatedAt = now,
                CreatedBy = "synthetic-test",
                UpdatedBy = "synthetic-test",
                RowVersion = new byte[8]
            });
            await db.SaveChangesAsync();
        }

        using var demo = factory.CreateAuthenticatedClient("analyst-project-a", SeedIds.DemoProject);
        using var batch = await demo.GetAsync($"/api/v1/discovery/imports/{batchId}");
        await AssertProblemDetailsAsync(batch, HttpStatusCode.NotFound, "resource_not_found");
        using var history = await demo.GetAsync($"/api/v1/sql-instances/{instanceId}/discovery-history");
        await AssertProblemDetailsAsync(history, HttpStatusCode.NotFound, "resource_not_found");
    }

    [Fact]
    public async Task Upload_errors_use_safe_specific_problem_details_and_disabled_child_flag_hides_routes()
    {
        using var factory = new LgrWebApplicationFactory();
        using var analyst = factory.CreateAuthenticatedClient("analyst-project-a", SeedIds.DemoProject);
        using var wrongExtension = await UploadResponseAsync(
            analyst,
            DiscoverySourceTypes.SqlInstanceCsvV1,
            "synthetic.txt",
            Encoding.UTF8.GetBytes(ValidSingleInstanceCsv("SYNTH-WRONG-EXT")));
        await AssertProblemDetailsAsync(wrongExtension, HttpStatusCode.UnsupportedMediaType, "unsupported_media_type");

        using var wrongContract = await UploadResponseAsync(
            analyst,
            DiscoverySourceTypes.SqlInstanceCsvV1,
            "synthetic.csv",
            Encoding.UTF8.GetBytes("Server,Instance Name\nSYNTH-SQL01,SYNTH"));
        await AssertProblemDetailsAsync(wrongContract, HttpStatusCode.UnprocessableEntity, "unsupported_source_contract");

        using var disabledFactory = new LgrWebApplicationFactory();
        using var disabledApp = disabledFactory.WithWebHostBuilder(builder => builder.ConfigureAppConfiguration((_, configuration) =>
            configuration.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Features:SqlDiscoveryImport"] = "false"
            })));
        using var disabled = disabledApp.CreateClient();
        LgrWebApplicationFactory.ApplySyntheticIdentity(disabled, "analyst-project-a", SeedIds.DemoProject);
        using var hidden = await disabled.GetAsync("/api/v1/discovery/imports");
        await AssertProblemDetailsAsync(hidden, HttpStatusCode.NotFound, "feature_disabled");
    }

    [Fact]
    public async Task Warning_negative_and_boundary_fixture_matrix_is_deterministic()
    {
        using var factory = new LgrWebApplicationFactory();
        using var dba = factory.CreateClient();
        using var analyst = factory.CreateAuthenticatedClient("analyst-project-a", SeedIds.DemoProject);
        await CreateInstanceAsync(
            dba,
            ServerId(await ServersAsync(dba), "DC-HOU-SQL01"),
            "SYNTH-PARENT");

        var (instanceWarningUpload, instanceWarningTag) = await UploadFixtureAsync(
            analyst, DiscoverySourceTypes.SqlInstanceCsvV1, "SQLI-V1-WARN-01.csv");
        var (instanceWarning, instanceWarningPreviewTag) = await PreviewAsync(
            analyst, instanceWarningUpload.Id, instanceWarningTag);
        Assert.Equal((1, 1, 0), (instanceWarning.TotalRows, instanceWarning.WarningCount, instanceWarning.RejectCount));
        var warningRows = await analyst.GetFromJsonAsync<PagedResult<SqlDiscoveryImportRowDto>>(
            $"/api/v1/discovery/imports/{instanceWarning.Id}/rows", JsonOptions);
        Assert.Equal(ImportClassifications.Create, warningRows!.Items.Single().ProposedAction);
        await CommitAsync(analyst, instanceWarning.Id, instanceWarningPreviewTag, "SQLI-V1-WARN-01");

        var (instanceBoundaryUpload, instanceBoundaryTag) = await UploadFixtureAsync(
            analyst, DiscoverySourceTypes.SqlInstanceCsvV1, "SQLI-V1-BOUND-01.csv");
        var (instanceBoundary, _) = await PreviewAsync(analyst, instanceBoundaryUpload.Id, instanceBoundaryTag);
        Assert.Equal((1, 0), (instanceBoundary.ValidRows, instanceBoundary.RejectCount));

        var (databaseWarningUpload, databaseWarningTag) = await UploadFixtureAsync(
            analyst, DiscoverySourceTypes.SqlDatabaseCsvV1, "SQLD-V1-WARN-01.csv");
        var (databaseWarning, _) = await PreviewAsync(analyst, databaseWarningUpload.Id, databaseWarningTag);
        Assert.Equal((1, 1, 0), (databaseWarning.TotalRows, databaseWarning.WarningCount, databaseWarning.RejectCount));

        var (databaseNegativeUpload, databaseNegativeTag) = await UploadFixtureAsync(
            analyst, DiscoverySourceTypes.SqlDatabaseCsvV1, "SQLD-V1-NEG-01.csv");
        var (databaseNegative, _) = await PreviewAsync(analyst, databaseNegativeUpload.Id, databaseNegativeTag);
        Assert.Equal((4, 4, 0),
            (databaseNegative.TotalRows, databaseNegative.RejectCount, databaseNegative.ValidRows));

        var (databaseBoundaryUpload, databaseBoundaryTag) = await UploadFixtureAsync(
            analyst, DiscoverySourceTypes.SqlDatabaseCsvV1, "SQLD-V1-BOUND-01.csv");
        var (databaseBoundary, _) = await PreviewAsync(analyst, databaseBoundaryUpload.Id, databaseBoundaryTag);
        Assert.Equal((1, 0), (databaseBoundary.ValidRows, databaseBoundary.RejectCount));
    }

    [Fact]
    public async Task Commit_requires_both_preconditions_and_never_mutates_on_missing_or_stale_values()
    {
        using var factory = new LgrWebApplicationFactory();
        using var analyst = factory.CreateAuthenticatedClient("analyst-project-a", SeedIds.DemoProject);
        var (upload, uploadTag) = await UploadTextAsync(
            analyst,
            DiscoverySourceTypes.SqlInstanceCsvV1,
            "SQL-RECON-01-preconditions.csv",
            ValidSingleInstanceCsv("SYNTH-PRECONDITION"));
        var (preview, previewTag) = await PreviewAsync(analyst, upload.Id, uploadTag);

        using var missingIfMatch = new HttpRequestMessage(
            HttpMethod.Post,
            $"/api/v1/discovery/imports/{preview.Id}/commit");
        missingIfMatch.Headers.TryAddWithoutValidation("Idempotency-Key", "SQL-RECON-01-missing-etag");
        using var missingIfMatchResponse = await analyst.SendAsync(missingIfMatch);
        await AssertProblemDetailsAsync(missingIfMatchResponse, (HttpStatusCode)428, "precondition_required");

        using var missingKeyResponse = await PostWithIfMatchAsync(
            analyst,
            $"/api/v1/discovery/imports/{preview.Id}/commit",
            previewTag);
        await AssertProblemDetailsAsync(missingKeyResponse, (HttpStatusCode)428, "precondition_required");

        using var staleResponse = await CommitResponseAsync(
            analyst,
            preview.Id,
            "\"stale\"",
            "SQL-RECON-01-stale-etag");
        await AssertProblemDetailsAsync(staleResponse, HttpStatusCode.PreconditionFailed, "stale_version");

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.False(await db.SqlInstances.IgnoreQueryFilters().AnyAsync(
            instance => instance.InstanceName == "SYNTH-PRECONDITION"));
        Assert.Empty(await db.SqlInstanceDiscoverySnapshots.IgnoreQueryFilters()
            .Where(snapshot => snapshot.ImportBatchId == preview.Id).ToListAsync());
    }

    [Fact]
    public void Persistence_model_has_rowversion_owner_leading_constraints_and_history_indexes()
    {
        using var factory = new LgrWebApplicationFactory();
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var batchType = db.Model.FindEntityType(typeof(ImportBatch))!;
        var rowType = db.Model.FindEntityType(typeof(DiscoveryImportRow))!;
        var instanceSnapshotType = db.Model.FindEntityType(typeof(SqlInstanceDiscoverySnapshot))!;
        var databaseSnapshotType = db.Model.FindEntityType(typeof(SqlDatabaseDiscoverySnapshot))!;

        Assert.True(batchType.FindProperty(nameof(ImportBatch.RowVersion))!.IsConcurrencyToken);
        var idempotencyIndex = batchType.GetIndexes().Single(index =>
            index.GetDatabaseName() == "IX_ImportBatches_Owner_CommitIdempotencyKeyHash");
        Assert.Equal(["CustomerId", "ProjectId", "CommitIdempotencyKeyHash"],
            idempotencyIndex.Properties.Select(property => property.Name));
        Assert.Contains(rowType.GetForeignKeys(), foreignKey =>
            foreignKey.Properties.Select(property => property.Name)
                .SequenceEqual(["CustomerId", "ProjectId", "MatchedSqlInstanceId"]));
        Assert.Contains(rowType.GetForeignKeys(), foreignKey =>
            foreignKey.Properties.Select(property => property.Name)
                .SequenceEqual(["CustomerId", "ProjectId", "MatchedSqlDatabaseId"]));
        AssertSnapshotModel(instanceSnapshotType, "SqlInstanceId", "IX_SqlInstanceDiscoverySnapshots_Owner_History");
        AssertSnapshotModel(databaseSnapshotType, "SqlDatabaseId", "IX_SqlDatabaseDiscoverySnapshots_Owner_History");
    }

    [Fact]
    public void Sql_server_provider_generates_slice_two_rowversion_composite_fks_checks_and_indexes()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlServer("Server=(local);Database=SyntheticSchemaOnly;Integrated Security=True;TrustServerCertificate=True")
            .Options;
        using var db = new AppDbContext(options, new FixedSyntheticContext());

        var script = db.Database.GenerateCreateScript();

        Assert.Contains("[ImportBatches]", script, StringComparison.Ordinal);
        Assert.Contains("[RowVersion] rowversion NOT NULL", script, StringComparison.Ordinal);
        Assert.Contains("[CommitIdempotencyKeyHash] nchar(64)", script, StringComparison.Ordinal);
        Assert.Contains("CONSTRAINT [FK_SqlInstanceDiscoverySnapshots_SqlInstances_CustomerId_ProjectId_SqlInstanceId]", script, StringComparison.Ordinal);
        Assert.Contains("CONSTRAINT [FK_SqlDatabaseDiscoverySnapshots_SqlDatabases_CustomerId_ProjectId_SqlDatabaseId]", script, StringComparison.Ordinal);
        Assert.Contains("CONSTRAINT [CK_SqlInstanceDiscoverySnapshots_Port]", script, StringComparison.Ordinal);
        Assert.Contains("CONSTRAINT [CK_SqlDatabaseDiscoverySnapshots_CompatibilityLevel]", script, StringComparison.Ordinal);
        Assert.Contains("CREATE INDEX [IX_ImportBatches_Owner_CommitIdempotencyKeyHash]", script, StringComparison.Ordinal);
        Assert.Contains("WHERE [CommitIdempotencyKeyHash] IS NOT NULL", script, StringComparison.Ordinal);
    }

    private static async Task<(DiscoveryImportBatchDto Batch, string Tag)> UploadFixtureAsync(
        HttpClient client,
        string sourceType,
        string fixtureName)
    {
        var path = Path.Combine(AppContext.BaseDirectory, "TestData", "sql-discovery", fixtureName);
        return await UploadBytesAsync(client, sourceType, fixtureName, await File.ReadAllBytesAsync(path));
    }

    private static async Task<(DiscoveryImportBatchDto Batch, string Tag)> UploadTextAsync(
        HttpClient client,
        string sourceType,
        string fileName,
        string content) =>
        await UploadBytesAsync(client, sourceType, fileName, Encoding.UTF8.GetBytes(content));

    private static async Task<(DiscoveryImportBatchDto Batch, string Tag)> UploadBytesAsync(
        HttpClient client,
        string sourceType,
        string fileName,
        byte[] bytes)
    {
        using var response = await UploadResponseAsync(client, sourceType, fileName, bytes);
        response.EnsureSuccessStatusCode();
        return ((await response.Content.ReadFromJsonAsync<DiscoveryImportBatchDto>(JsonOptions))!, response.Headers.ETag!.Tag);
    }

    private static async Task<HttpResponseMessage> UploadResponseAsync(
        HttpClient client,
        string sourceType,
        string fileName,
        byte[] bytes)
    {
        var multipart = new MultipartFormDataContent();
        multipart.Add(new StringContent(sourceType), "sourceType");
        var file = new ByteArrayContent(bytes);
        file.Headers.ContentType = new MediaTypeHeaderValue("text/csv");
        multipart.Add(file, "file", fileName);
        return await client.PostAsync("/api/v1/discovery/imports/upload", multipart);
    }

    private static async Task<(DiscoveryImportBatchDto Batch, string Tag)> PreviewAsync(
        HttpClient client,
        Guid batchId,
        string tag)
    {
        using var response = await PostWithIfMatchAsync(client, $"/api/v1/discovery/imports/{batchId}/preview", tag);
        response.EnsureSuccessStatusCode();
        return ((await response.Content.ReadFromJsonAsync<DiscoveryImportBatchDto>(JsonOptions))!, response.Headers.ETag!.Tag);
    }

    private static async Task<(DiscoveryImportBatchDto Batch, string Tag)> CommitAsync(
        HttpClient client,
        Guid batchId,
        string tag,
        string key)
    {
        using var response = await CommitResponseAsync(client, batchId, tag, key);
        response.EnsureSuccessStatusCode();
        return ((await response.Content.ReadFromJsonAsync<DiscoveryImportBatchDto>(JsonOptions))!, response.Headers.ETag!.Tag);
    }

    private static Task<HttpResponseMessage> CommitResponseAsync(
        HttpClient client,
        Guid batchId,
        string tag,
        string key)
    {
        var request = new HttpRequestMessage(HttpMethod.Post, $"/api/v1/discovery/imports/{batchId}/commit");
        request.Headers.TryAddWithoutValidation("If-Match", tag);
        request.Headers.TryAddWithoutValidation("Idempotency-Key", key);
        return client.SendAsync(request);
    }

    private static Task<HttpResponseMessage> PostWithIfMatchAsync(HttpClient client, string uri, string tag)
    {
        var request = new HttpRequestMessage(HttpMethod.Post, uri);
        request.Headers.TryAddWithoutValidation("If-Match", tag);
        return client.SendAsync(request);
    }

    private static Task<HttpResponseMessage> SendWithIfMatchAsync(
        HttpClient client,
        HttpMethod method,
        string uri,
        object body,
        string tag)
    {
        var request = new HttpRequestMessage(method, uri)
        {
            Content = JsonContent.Create(body, options: JsonOptions)
        };
        request.Headers.TryAddWithoutValidation("If-Match", tag);
        return client.SendAsync(request);
    }

    private static async Task<IReadOnlyList<ServerDto>> ServersAsync(HttpClient client) =>
        (await client.GetFromJsonAsync<PagedResult<ServerDto>>("/api/servers?pageSize=200", JsonOptions))!.Items;

    private static Guid ServerId(IEnumerable<ServerDto> servers, string hostname) =>
        servers.Single(server => server.Hostname == hostname).Id;

    private static async Task<(SqlInstanceDto Dto, string Tag)> CreateInstanceAsync(
        HttpClient client,
        Guid serverId,
        string name,
        string sqlVersion = "SQL Server 2022",
        string edition = "Standard",
        int? port = 1433,
        string serviceStatus = SqlInstanceServiceStatuses.Running,
        string? serviceAccountName = null)
    {
        using var response = await client.PostAsJsonAsync(
            "/api/v1/sql-instances",
            InstanceRequest(serverId, name, sqlVersion, edition, port, serviceStatus, serviceAccountName));
        response.EnsureSuccessStatusCode();
        return ((await response.Content.ReadFromJsonAsync<SqlInstanceDto>(JsonOptions))!, response.Headers.ETag!.Tag);
    }

    private static SqlInstanceWriteV1 InstanceRequest(
        Guid serverId,
        string name,
        string sqlVersion,
        string edition,
        int? port,
        string serviceStatus,
        string? serviceAccountName) =>
        new(serverId, name, sqlVersion, edition, port, serviceStatus, serviceAccountName);

    private static async Task<(SqlDatabaseDto Dto, string Tag)> CreateDatabaseAsync(
        HttpClient client,
        Guid instanceId,
        string name,
        long sizeMb,
        int compatibilityLevel,
        string recoveryModel,
        string? collation,
        string status)
    {
        using var response = await client.PostAsJsonAsync(
            "/api/v1/sql-databases",
            new SqlDatabaseWriteV1(instanceId, name, sizeMb, compatibilityLevel, recoveryModel, collation, status));
        response.EnsureSuccessStatusCode();
        return ((await response.Content.ReadFromJsonAsync<SqlDatabaseDto>(JsonOptions))!, response.Headers.ETag!.Tag);
    }

    private static string ValidSingleInstanceCsv(string name) =>
        "Server,Instance Name,SQL Version,Edition,Port,Service Status,Discovery Source,Last Discovered At\n" +
        $"DC-HOU-SQL01,{name},SQL Server 2022,Standard,1433,Running,Synthetic discovery,\n";

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
        Assert.Equal(expectedErrorCode, root.GetProperty("errorCode").GetString());
        Assert.False(string.IsNullOrWhiteSpace(root.GetProperty("correlationId").GetString()));
        Assert.False(string.IsNullOrWhiteSpace(root.GetProperty("title").GetString()));
        Assert.False(string.IsNullOrWhiteSpace(root.GetProperty("detail").GetString()));
        return root;
    }

    private static void AssertSnapshotModel(
        Microsoft.EntityFrameworkCore.Metadata.IEntityType entityType,
        string canonicalId,
        string historyIndexName)
    {
        Assert.Contains(entityType.GetForeignKeys(), foreignKey =>
            foreignKey.Properties.Select(property => property.Name)
                .SequenceEqual(["CustomerId", "ProjectId", canonicalId])
            && foreignKey.DeleteBehavior == DeleteBehavior.Restrict);
        Assert.Contains(entityType.GetForeignKeys(), foreignKey =>
            foreignKey.Properties.Select(property => property.Name)
                .SequenceEqual(["CustomerId", "ProjectId", "ImportBatchId"])
            && foreignKey.DeleteBehavior == DeleteBehavior.Restrict);
        var historyIndex = entityType.GetIndexes().Single(index => index.GetDatabaseName() == historyIndexName);
        Assert.Equal(["CustomerId", "ProjectId", canonicalId, "ImportedAt", "Id"],
            historyIndex.Properties.Select(property => property.Name));
    }

    private sealed class FixedSyntheticContext : ICurrentCustomerContext
    {
        public Guid CustomerId => SeedIds.DemoCustomer;
        public Guid ProjectId => SeedIds.DemoProject;
        public string UserName => "local-test:synthetic-schema";
        public string CorrelationId => "synthetic-schema-correlation";
        public InternalPrincipal Principal { get; } = new(
            Guid.Parse("70000000-0000-0000-0000-000000000099"),
            InternalPrincipalType.Human,
            "Synthetic",
            Guid.Parse("99999999-9999-9999-9999-999999999999"),
            Guid.Parse("70000000-0000-0000-0000-000000000099"),
            Guid.Parse("88888888-8888-8888-8888-888888888888"),
            "synthetic-schema",
            "Synthetic Schema",
            InternalAuthenticationDefaults.LocalTestMode,
            true,
            true);
    }
}
