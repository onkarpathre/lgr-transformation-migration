using System.Net;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Domain;
using LgrTransformationMigration.Api.Infrastructure;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace LgrTransformationMigration.Api.IntegrationTests;

public sealed class DiscoveryImportApiTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    [Fact]
    public async Task Preview_does_not_change_canonical_server_inventory()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateClient();
        var before = await client.GetFromJsonAsync<PagedResult<ServerDto>>("/api/servers?pageSize=200", JsonOptions);

        var batch = await UploadAndPreviewAsync(client, Fixture("azure-migrate-server-report-test.csv"));
        var after = await client.GetFromJsonAsync<PagedResult<ServerDto>>("/api/servers?pageSize=200", JsonOptions);

        Assert.Equal(before!.TotalCount, after!.TotalCount);
        Assert.Equal(4, batch.TotalRows);
        Assert.Equal(1, batch.CreateCount);
        Assert.Equal(1, batch.UpdateCount);
        Assert.Equal(1, batch.WarningCount);
        Assert.Equal(1, batch.RejectCount);
    }

    [Fact]
    public async Task Commit_creates_new_servers_and_discovery_audit_events()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateClient();
        var batch = await UploadAndPreviewAsync(client, Fixture("azure-migrate-server-report-test.csv"));

        var committed = await CommitAsync(client, batch.Id);
        var servers = await client.GetFromJsonAsync<PagedResult<ServerDto>>("/api/servers?pageSize=200", JsonOptions);

        Assert.Equal(ImportBatchStatuses.CompletedWithWarnings, committed.Status);
        Assert.Contains(servers!.Items, x => x.Hostname == "DC-LIB-APP01");
        Assert.Contains(servers.Items, x => x.Hostname == "DC-PARKS-APP01");
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.Contains(await db.AuditEvents.ToListAsync(), x => x.Action == "ServerCreatedFromDiscovery");
        Assert.Contains(await db.AuditEvents.ToListAsync(), x => x.Action == "DiscoveryImportCommitted" && x.EntityId == batch.Id);
    }

    [Fact]
    public async Task Commit_updates_only_allowed_discovery_fields_with_field_level_audit()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateClient();
        var batch = await UploadAndPreviewAsync(client, Fixture("azure-migrate-server-report-test.csv"));

        await CommitAsync(client, batch.Id);
        var servers = await client.GetFromJsonAsync<PagedResult<ServerDto>>("/api/servers?pageSize=200", JsonOptions);
        var updated = servers!.Items.Single(x => x.Hostname == "DC-HOU-APP01");

        Assert.Equal(32768, updated.MemoryMb);
        Assert.Equal("Supported", updated.SupportStatus);
        Assert.Equal(DiscoverySourceTypes.AzureMigrateServerReport, updated.DiscoverySource);
        Assert.NotNull(updated.LastImportedAt);
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.Contains(await db.AuditEvents.ToListAsync(), x =>
            x.Action == "ServerUpdatedFromDiscovery" && x.PropertyName == "MemoryMb" && x.OldValue == "16384" && x.NewValue == "32768");
    }

    [Theory]
    [InlineData("MigrationScope")]
    [InlineData("MigrationStrategy")]
    public async Task Commit_does_not_overwrite_protected_business_fields(string field)
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateClient();
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var server = await db.Servers.SingleAsync(x => x.Hostname == "DC-HOU-APP01");
            if (field == "MigrationScope") server.MigrationScope = "Board Approved Scope";
            else server.MigrationStrategy = "Replatform - manually approved";
            await db.SaveChangesAsync();
        }

        var batch = await UploadAndPreviewAsync(client, Fixture("azure-migrate-server-report-test.csv"));
        await CommitAsync(client, batch.Id);

        using var verifyScope = factory.Services.CreateScope();
        var verifyDb = verifyScope.ServiceProvider.GetRequiredService<AppDbContext>();
        var updated = await verifyDb.Servers.SingleAsync(x => x.Hostname == "DC-HOU-APP01");
        Assert.Equal(field == "MigrationScope" ? "Board Approved Scope" : "Replatform - manually approved",
            field == "MigrationScope" ? updated.MigrationScope : updated.MigrationStrategy);
    }

    [Fact]
    public async Task Commit_stores_server_discovery_snapshots_and_exposes_history()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateClient();
        var batch = await UploadAndPreviewAsync(client, Fixture("azure-migrate-server-report-test.csv"));
        await CommitAsync(client, batch.Id);
        var servers = await client.GetFromJsonAsync<PagedResult<ServerDto>>("/api/servers?pageSize=200", JsonOptions);
        var server = servers!.Items.Single(x => x.Hostname == "DC-HOU-APP01");

        var history = await client.GetFromJsonAsync<List<ServerDiscoverySnapshotDto>>($"/api/servers/{server.Id}/discovery-history", JsonOptions);

        var snapshot = Assert.Single(history!);
        Assert.Equal(32768, snapshot.MemoryMb);
        Assert.Equal(batch.Id, snapshot.ImportBatchId);
        Assert.Equal(DiscoverySourceTypes.AzureMigrateServerReport, snapshot.SourceType);
    }

    [Fact]
    public async Task Duplicate_file_hash_returns_a_previous_import_warning()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateClient();
        var csv = Fixture("azure-migrate-server-report-test.csv");
        await UploadAsync(client, csv, DiscoverySourceTypes.AzureMigrateServerReport);

        var duplicate = await UploadAsync(client, csv, DiscoverySourceTypes.AzureMigrateServerReport);

        Assert.NotNull(duplicate.DuplicateWarning);
        Assert.Contains("previously", duplicate.DuplicateWarning, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task Import_cannot_be_committed_twice()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateClient();
        var batch = await UploadAndPreviewAsync(client, Fixture("azure-migrate-server-report-test.csv"));
        await CommitAsync(client, batch.Id);

        var second = await client.PostAsync($"/api/discovery/imports/{batch.Id}/commit", null);
        var unchanged = await client.GetFromJsonAsync<DiscoveryImportBatchDto>($"/api/discovery/imports/{batch.Id}", JsonOptions);

        Assert.Equal(HttpStatusCode.BadRequest, second.StatusCode);
        Assert.Equal(ImportBatchStatuses.CompletedWithWarnings, unchanged!.Status);
    }

    [Fact]
    public async Task Failed_commit_rolls_back_all_inventory_changes_and_marks_batch_failed()
    {
        const string csv = "Id,Server,Operating System,Memory (MB)\n" +
                           "rollback-1,DC-ROLLBACK-01,Windows Server 2022,8192\n" +
                           "rollback-2,DC-CONFLICT-01,Windows Server 2022,8192\n";
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateClient();
        var batch = await UploadAndPreviewAsync(client, csv);
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var now = DateTimeOffset.UtcNow;
            db.Servers.Add(new Server
            {
                Id = Guid.NewGuid(), CustomerId = SeedIds.DemoCustomer, ProjectId = SeedIds.DemoProject,
                Hostname = "DC-CONFLICT-01", Environment = "Prod", OperatingSystem = "Windows Server 2022",
                IpAddress = string.Empty, PowerStatus = "On", MigrationScope = "Protected", MigrationStrategy = "Rehost",
                MigrationStatus = "Not Started", CreatedAt = now, UpdatedAt = now
            });
            await db.SaveChangesAsync();
        }

        var response = await client.PostAsync($"/api/discovery/imports/{batch.Id}/commit", null);
        var failed = await client.GetFromJsonAsync<DiscoveryImportBatchDto>($"/api/discovery/imports/{batch.Id}", JsonOptions);
        using var verifyScope = factory.Services.CreateScope();
        var verifyDb = verifyScope.ServiceProvider.GetRequiredService<AppDbContext>();

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal(ImportBatchStatuses.Failed, failed!.Status);
        Assert.False(await verifyDb.Servers.AnyAsync(x => x.Hostname == "DC-ROLLBACK-01"));
        Assert.Empty(await verifyDb.ServerDiscoverySnapshots.Where(x => x.ImportBatchId == batch.Id).ToListAsync());
    }

    [Fact]
    public async Task Import_history_is_customer_isolated()
    {
        using var factory = new LgrWebApplicationFactory();
        var otherContext = await factory.SeedSecondTenantAsync();
        using var demo = factory.CreateClient();
        var batch = await UploadAsync(demo, Fixture("azure-migrate-server-report-test.csv"), DiscoverySourceTypes.AzureMigrateServerReport);
        using var other = OtherTenantClient(factory, otherContext);

        var otherHistory = await other.GetFromJsonAsync<List<DiscoveryImportBatchDto>>("/api/discovery/imports", JsonOptions);
        var otherGet = await other.GetAsync($"/api/discovery/imports/{batch.Id}");

        Assert.Empty(otherHistory!);
        Assert.Equal(HttpStatusCode.NotFound, otherGet.StatusCode);
    }

    [Fact]
    public async Task Import_rows_are_customer_isolated()
    {
        using var factory = new LgrWebApplicationFactory();
        var otherContext = await factory.SeedSecondTenantAsync();
        using var demo = factory.CreateClient();
        var batch = await UploadAndPreviewAsync(demo, Fixture("azure-migrate-server-report-test.csv"));
        using var other = OtherTenantClient(factory, otherContext);

        var response = await other.GetAsync($"/api/discovery/imports/{batch.Id}/rows");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task All_inventory_source_stages_server_and_non_server_rows_without_creating_canonical_databases()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateClient();
        var batch = await UploadAndPreviewAsync(client, Fixture("azure-migrate-all-inventory-test.csv"), DiscoverySourceTypes.AzureMigrateAllInventoryReport);
        var rows = await client.GetFromJsonAsync<PagedResult<DiscoveryImportRowDto>>($"/api/discovery/imports/{batch.Id}/rows", JsonOptions);

        Assert.Equal(2, batch.TotalRows);
        Assert.Contains(rows!.Items, x => x.Hostname == "DC-ALL-APP01" && x.Classification == ImportClassifications.Create);
        Assert.Contains(rows.Items, x => x.Classification == ImportClassifications.Warning);
    }

    [Fact]
    public async Task Reconciliation_uses_customer_and_normalized_hostname_together()
    {
        const string csv = "Id,Server,Operating System,Memory (MB)\ncurrent-1, other-app01 ,Windows Server 2022,4096\n";
        using var factory = new LgrWebApplicationFactory();
        await factory.SeedSecondTenantAsync();
        using var demo = factory.CreateClient();

        var batch = await UploadAndPreviewAsync(demo, csv);

        Assert.Equal(1, batch.CreateCount);
        Assert.Equal(0, batch.UpdateCount);
        Assert.Equal(0, batch.UnchangedCount);
    }

    [Fact]
    public async Task Update_row_detail_exposes_field_differences()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateClient();
        var batch = await UploadAndPreviewAsync(client, Fixture("azure-migrate-server-report-test.csv"));
        var rows = await client.GetFromJsonAsync<PagedResult<DiscoveryImportRowDto>>(
            $"/api/discovery/imports/{batch.Id}/rows?classification=Update", JsonOptions);

        var detail = await client.GetFromJsonAsync<DiscoveryImportRowDetailDto>(
            $"/api/discovery/imports/{batch.Id}/rows/{Assert.Single(rows!.Items).Id}", JsonOptions);

        Assert.Contains(detail!.ProposedChanges, x => x.Field == "MemoryMb" && x.OldValue == "16384" && x.NewValue == "32768");
        Assert.Equal("DC-HOU-APP01", detail.MatchedServer!.Name);
    }

    [Fact]
    public async Task Demonstration_file_shows_every_classification_then_reruns_as_unchanged_with_duplicate_warning()
    {
        using var factory = new LgrWebApplicationFactory();
        using var client = factory.CreateClient();
        var csv = File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "Samples", "azure-migrate-server-report-demo.csv"));

        var first = await UploadAndPreviewAsync(client, csv);
        Assert.Equal(7, first.TotalRows);
        Assert.Equal(2, first.CreateCount);
        Assert.Equal(2, first.UpdateCount);
        Assert.Equal(1, first.UnchangedCount);
        Assert.Equal(1, first.WarningCount);
        Assert.Equal(1, first.RejectCount);
        await CommitAsync(client, first.Id);

        var secondUpload = await UploadAsync(client, csv, DiscoverySourceTypes.AzureMigrateServerReport);
        Assert.NotNull(secondUpload.DuplicateWarning);
        var secondResponse = await client.PostAsync($"/api/discovery/imports/{secondUpload.Id}/preview", null);
        secondResponse.EnsureSuccessStatusCode();
        var second = (await secondResponse.Content.ReadFromJsonAsync<DiscoveryImportBatchDto>(JsonOptions))!;
        Assert.Equal(0, second.CreateCount);
        Assert.Equal(0, second.UpdateCount);
        Assert.Equal(5, second.UnchangedCount);
        Assert.Equal(1, second.WarningCount);
        Assert.Equal(1, second.RejectCount);
    }

    private static async Task<DiscoveryImportBatchDto> UploadAndPreviewAsync(
        HttpClient client, string csv, string sourceType = DiscoverySourceTypes.AzureMigrateServerReport)
    {
        var uploaded = await UploadAsync(client, csv, sourceType);
        var response = await client.PostAsync($"/api/discovery/imports/{uploaded.Id}/preview", null);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<DiscoveryImportBatchDto>(JsonOptions))!;
    }

    private static async Task<DiscoveryImportBatchDto> UploadAsync(HttpClient client, string csv, string sourceType)
    {
        using var content = new MultipartFormDataContent();
        content.Add(new StringContent(sourceType), "SourceType");
        content.Add(new ByteArrayContent(Encoding.UTF8.GetBytes(csv)), "File", "report.csv");
        var response = await client.PostAsync("/api/discovery/imports/upload", content);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<DiscoveryImportBatchDto>(JsonOptions))!;
    }

    private static async Task<DiscoveryImportBatchDto> CommitAsync(HttpClient client, Guid batchId)
    {
        var response = await client.PostAsync($"/api/discovery/imports/{batchId}/commit", null);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<DiscoveryImportBatchDto>(JsonOptions))!;
    }

    private static HttpClient OtherTenantClient(LgrWebApplicationFactory factory, (Guid CustomerId, Guid ProjectId) context)
    {
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-Customer-Id", context.CustomerId.ToString());
        client.DefaultRequestHeaders.Add("X-Project-Id", context.ProjectId.ToString());
        return client;
    }

    private static string Fixture(string name) => File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "TestData", name));
}
