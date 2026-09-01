using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using LgrTransformationMigration.Api.Contracts;

namespace LgrTransformationMigration.Api.IntegrationTests;

public sealed class ApiJourneyTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    [Fact]
    public async Task Customer_and_dashboard_queries_are_tenant_isolated()
    {
        using var factory = new LgrWebApplicationFactory();
        var (otherCustomer, otherProject) = await factory.SeedSecondTenantAsync();
        using var demo = factory.CreateClient();
        var demoApps = await demo.GetFromJsonAsync<PagedResult<ApplicationDto>>("/api/applications", JsonOptions);
        Assert.Equal(5, demoApps!.TotalCount);

        using var other = factory.CreateClient();
        other.DefaultRequestHeaders.Add("X-Customer-Id", otherCustomer.ToString());
        other.DefaultRequestHeaders.Add("X-Project-Id", otherProject.ToString());
        var otherApps = await other.GetFromJsonAsync<PagedResult<ApplicationDto>>("/api/applications", JsonOptions);
        var summary = await other.GetFromJsonAsync<DashboardSummaryDto>("/api/dashboard/summary", JsonOptions);
        Assert.Equal(1, otherApps!.TotalCount);
        Assert.Equal("Other Housing", Assert.Single(otherApps.Items).Name);
        Assert.Equal(1, summary!.TotalApplications);
        Assert.Equal(1, summary.TotalServers);
    }

    [Fact]
    public async Task CustomerId_and_hostname_uniqueness_is_enforced()
    {
        using var factory = new LgrWebApplicationFactory(); using var client = factory.CreateClient();
        var request = ServerRequest("DC-HOU-APP01");
        var response = await client.PostAsJsonAsync("/api/servers", request);
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task Application_crud_round_trip_works()
    {
        using var factory = new LgrWebApplicationFactory(); using var client = factory.CreateClient();
        var create = new ApplicationRequest("Electoral Services", "Prod", "Fictional elections workload", "High", "COTS", "4.2", "In Scope", "Rehost", "Not Started", []);
        var createdResponse = await client.PostAsJsonAsync("/api/applications", create);
        Assert.Equal(HttpStatusCode.Created, createdResponse.StatusCode);
        var created = await createdResponse.Content.ReadFromJsonAsync<ApplicationDto>(JsonOptions);
        Assert.NotNull(created);

        var update = create with { CurrentVersion = "4.3", MigrationStatus = "In Progress" };
        var updatedResponse = await client.PutAsJsonAsync($"/api/applications/{created.Id}", update);
        var updated = await updatedResponse.Content.ReadFromJsonAsync<ApplicationDto>(JsonOptions);
        Assert.Equal("4.3", updated!.CurrentVersion);

        Assert.Equal(HttpStatusCode.NoContent, (await client.DeleteAsync($"/api/applications/{created.Id}")).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync($"/api/applications/{created.Id}")).StatusCode);
    }

    [Fact]
    public async Task Server_crud_round_trip_works()
    {
        using var factory = new LgrWebApplicationFactory(); using var client = factory.CreateClient();
        var create = ServerRequest("DC-NEW-APP01");
        var createdResponse = await client.PostAsJsonAsync("/api/servers", create);
        Assert.Equal(HttpStatusCode.Created, createdResponse.StatusCode);
        var created = await createdResponse.Content.ReadFromJsonAsync<ServerDto>(JsonOptions);
        var update = create with { VCores = 8, MigrationStatus = "In Progress" };
        var updatedResponse = await client.PutAsJsonAsync($"/api/servers/{created!.Id}", update);
        var updated = await updatedResponse.Content.ReadFromJsonAsync<ServerDto>(JsonOptions);
        Assert.Equal(8, updated!.VCores);
        Assert.Equal(HttpStatusCode.NoContent, (await client.DeleteAsync($"/api/servers/{created.Id}")).StatusCode);
    }

    [Fact]
    public async Task Duplicate_active_ip_allocation_for_a_server_is_prevented()
    {
        using var factory = new LgrWebApplicationFactory(); using var client = factory.CreateClient();
        var servers = await client.GetFromJsonAsync<PagedResult<ServerDto>>("/api/servers?pageSize=200", JsonOptions);
        var addresses = await client.GetFromJsonAsync<List<IpAddressDto>>("/api/ip-addresses", JsonOptions);
        var serverWithAllocation = servers!.Items.Single(x => x.Hostname == "DC-HOU-APP01");
        var available = addresses!.First(x => x.Status == "Available");
        var response = await client.PostAsJsonAsync($"/api/ip-addresses/{available.Id}/reserve", new IpTransitionRequest(serverWithAllocation.Id));
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Ip_status_transitions_are_validated_and_complete_in_order()
    {
        using var factory = new LgrWebApplicationFactory(); using var client = factory.CreateClient();
        var servers = await client.GetFromJsonAsync<PagedResult<ServerDto>>("/api/servers?pageSize=200", JsonOptions);
        var addresses = await client.GetFromJsonAsync<List<IpAddressDto>>("/api/ip-addresses", JsonOptions);
        var available = addresses!.First(x => x.Status == "Available");
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsync($"/api/ip-addresses/{available.Id}/allocate", null)).StatusCode);

        var freeServer = servers!.Items.Single(x => x.Hostname == "DC-REV-SQL01");
        var reserved = await (await client.PostAsJsonAsync($"/api/ip-addresses/{available.Id}/reserve", new IpTransitionRequest(freeServer.Id))).Content.ReadFromJsonAsync<IpAddressDto>(JsonOptions);
        Assert.Equal("Reserved", reserved!.Status);
        var allocated = await (await client.PostAsync($"/api/ip-addresses/{available.Id}/allocate", null)).Content.ReadFromJsonAsync<IpAddressDto>(JsonOptions);
        Assert.Equal("Allocated", allocated!.Status);
        var released = await (await client.PostAsync($"/api/ip-addresses/{available.Id}/release", null)).Content.ReadFromJsonAsync<IpAddressDto>(JsonOptions);
        Assert.Equal("Released", released!.Status);
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsync($"/api/ip-addresses/{available.Id}/allocate", null)).StatusCode);
    }

    [Fact]
    public async Task Migration_wave_crud_and_asset_association_work()
    {
        using var factory = new LgrWebApplicationFactory(); using var client = factory.CreateClient();
        var createdResponse = await client.PostAsJsonAsync("/api/migration-waves", new MigrationWaveRequest("Wave 4 - Elections", new DateOnly(2026, 10, 3), "Planning", "Electoral services workload."));
        var created = await createdResponse.Content.ReadFromJsonAsync<MigrationWaveDto>(JsonOptions);
        Assert.Equal(HttpStatusCode.Created, createdResponse.StatusCode);
        var apps = await client.GetFromJsonAsync<PagedResult<ApplicationDto>>("/api/applications?pageSize=200", JsonOptions);
        var associatedResponse = await client.PostAsJsonAsync($"/api/migration-waves/{created!.Id}/assets", new WaveAssetRequest(apps!.Items[0].Id, null));
        var detail = await associatedResponse.Content.ReadFromJsonAsync<MigrationWaveDetailDto>(JsonOptions);
        Assert.Single(detail!.Assets);
        Assert.Equal(apps.Items[0].Id, detail.Assets[0].ApplicationId);

        var updated = await (await client.PutAsJsonAsync($"/api/migration-waves/{created.Id}", new MigrationWaveRequest(created.Name, created.PlannedDate, "Ready", created.Description))).Content.ReadFromJsonAsync<MigrationWaveDto>(JsonOptions);
        Assert.Equal("Ready", updated!.Status);
        Assert.Equal(HttpStatusCode.NoContent, (await client.DeleteAsync($"/api/migration-waves/{created.Id}")).StatusCode);
    }

    [Fact]
    public async Task Runbook_generation_creates_ordered_default_tasks()
    {
        using var factory = new LgrWebApplicationFactory(); using var client = factory.CreateClient();
        var waves = await client.GetFromJsonAsync<List<MigrationWaveDto>>("/api/migration-waves", JsonOptions);
        var waveWithoutRunbook = waves!.Single(x => x.Name.Contains("Documents"));
        var response = await client.PostAsJsonAsync("/api/runbooks/generate", new GenerateRunbookRequest(waveWithoutRunbook.Id, null));
        var runbook = await response.Content.ReadFromJsonAsync<RunbookDto>(JsonOptions);
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        Assert.Equal(13, runbook!.Tasks.Count);
        Assert.Equal(Enumerable.Range(1, 13), runbook.Tasks.Select(x => x.Sequence));
        Assert.Equal("Pre-Migration Checks", runbook.Tasks[0].Task);
        Assert.Equal("Migration Completion", runbook.Tasks[^1].Task);
    }

    private static ServerRequest ServerRequest(string hostname) => new(hostname, "Prod", "Windows Server 2022", "10.20.99.10", 4, 8192, 100, "On", "Not Started", []);
}
