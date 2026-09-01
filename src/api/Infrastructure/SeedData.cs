using LgrTransformationMigration.Api.Domain;
using Microsoft.EntityFrameworkCore;

namespace LgrTransformationMigration.Api.Infrastructure;

public static class SeedData
{
    private static readonly DateTimeOffset SeedTime = new(2026, 1, 15, 9, 0, 0, TimeSpan.Zero);
    private static Guid AppId(int value) => Guid.Parse($"aaaaaaaa-aaaa-aaaa-aaaa-{value:000000000000}");
    private static Guid ServerId(int value) => Guid.Parse($"bbbbbbbb-bbbb-bbbb-bbbb-{value:000000000000}");
    private static Guid OtherId(int value) => Guid.Parse($"cccccccc-cccc-cccc-cccc-{value:000000000000}");
    private static Guid LookupId(int value) => Guid.Parse($"dddddddd-dddd-dddd-dddd-{value:000000000000}");

    public static void Configure(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Customer>().HasData(new Customer
        {
            Id = SeedIds.DemoCustomer,
            Name = "Demo Council",
            Code = "DEMO",
            Status = "Active",
            CreatedAt = SeedTime,
            UpdatedAt = SeedTime
        });

        modelBuilder.Entity<Project>().HasData(new Project
        {
            Id = SeedIds.DemoProject,
            CustomerId = SeedIds.DemoCustomer,
            Name = "LGR Azure Transformation Programme",
            Description = "Fictional programme demonstrating discovery, assessment, design and migration planning.",
            Status = "Active",
            PlannedStartDate = new DateOnly(2026, 2, 1),
            PlannedEndDate = new DateOnly(2027, 3, 31),
            CreatedAt = SeedTime,
            UpdatedAt = SeedTime
        });

        var applications = new[]
        {
            NewApplication(1, "Housing Management", "Prod", "Critical", "COTS", "2024.3", "In Scope", "Rehost", "In Progress"),
            NewApplication(2, "Revenues and Benefits", "Prod", "Critical", "COTS", "8.7", "In Scope", "Build Ahead", "Not Started"),
            NewApplication(3, "Document Management", "Prod", "High", "COTS", "12.2", "In Scope", "Replatform", "In Progress"),
            NewApplication(4, "Environmental Services", "Prod", "Medium", "Custom", "5.4", "Under Review", "Investigate", "Not Started"),
            NewApplication(5, "Finance", "Prod", "High", "COTS", "2025 R1", "In Scope", "SaaS", "Completed")
        };
        modelBuilder.Entity<Application>().HasData(applications);

        var servers = new[]
        {
            NewServer(1, "DC-HOU-APP01", "Prod", "Windows Server 2022", "10.20.10.21", 4, 16384, 250, "On", "In Progress"),
            NewServer(2, "DC-HOU-SQL01", "Prod", "Windows Server 2022", "10.20.10.22", 8, 32768, 800, "On", "Not Started"),
            NewServer(3, "DC-REV-APP01", "Prod", "Windows Server 2019", "10.20.10.31", 4, 16384, 300, "On", "Not Started"),
            NewServer(4, "DC-REV-SQL01", "Prod", "Windows Server 2019", "10.20.10.32", 8, 65536, 1200, "On", "Not Started"),
            NewServer(5, "DC-DMS-APP01", "Prod", "Red Hat Enterprise Linux 9", "10.20.10.41", 4, 16384, 400, "On", "In Progress"),
            NewServer(6, "DC-DMS-IDX01", "Prod", "Red Hat Enterprise Linux 9", "10.20.10.42", 8, 32768, 600, "On", "In Progress"),
            NewServer(7, "DC-ENV-WEB01", "Prod", "Windows Server 2019", "10.20.10.51", 2, 8192, 150, "On", "Not Started"),
            NewServer(8, "DC-ENV-APP01", "Prod", "Windows Server 2019", "10.20.10.52", 4, 16384, 250, "On", "Blocked"),
            NewServer(9, "DC-FIN-APP01", "Prod", "Windows Server 2022", "10.20.10.61", 4, 16384, 200, "On", "Completed"),
            NewServer(10, "DC-FIN-SQL01", "Prod", "Windows Server 2022", "10.20.10.62", 8, 32768, 700, "On", "Completed")
        };
        modelBuilder.Entity<Server>().HasData(servers);

        modelBuilder.Entity<ApplicationServer>().HasData(
            Enumerable.Range(1, 10).Select(index => new ApplicationServer
            {
                Id = OtherId(100 + index), CustomerId = SeedIds.DemoCustomer, ProjectId = SeedIds.DemoProject,
                ApplicationId = AppId((index + 1) / 2), ServerId = ServerId(index)
            }).ToArray());

        modelBuilder.Entity<MigrationDecision>().HasData(
            NewDecision(1, 1, "In Scope", "Rehost", "Azure Virtual Machines", "Vendor supports lift and optimise after migration.", "Medium", "Approved", new DateOnly(2026, 2, 12)),
            NewDecision(2, 2, "In Scope", "Build Ahead", "Azure Virtual Machines", "Operating system refresh required before cutover.", "High", "Approved", new DateOnly(2026, 2, 18)),
            NewDecision(3, 3, "In Scope", "Replatform", "Azure App Service and Azure SQL", "Supported managed platform target.", "Medium", "Proposed", null),
            NewDecision(4, 4, "Under Review", "Investigate", "To be confirmed", "Dependency discovery remains incomplete.", "High", "Draft", null),
            NewDecision(5, 5, "In Scope", "SaaS", "Vendor SaaS", "SaaS transition completed before infrastructure waves.", "Low", "Approved", new DateOnly(2026, 1, 30)));

        var subnetOne = OtherId(201);
        var subnetTwo = OtherId(202);
        modelBuilder.Entity<Subnet>().HasData(
            new Subnet { Id = subnetOne, CustomerId = SeedIds.DemoCustomer, ProjectId = SeedIds.DemoProject, Name = "snet-prod-app", VNetName = "vnet-lgr-prod-uks-01", Cidr = "10.80.10.0/27", Environment = "Prod", CreatedAt = SeedTime, UpdatedAt = SeedTime },
            new Subnet { Id = subnetTwo, CustomerId = SeedIds.DemoCustomer, ProjectId = SeedIds.DemoProject, Name = "snet-prod-data", VNetName = "vnet-lgr-data-uks-01", Cidr = "10.80.20.0/27", Environment = "Prod", CreatedAt = SeedTime, UpdatedAt = SeedTime });

        var ips = new List<IpAddress>();
        for (var i = 1; i <= 10; i++)
        {
            ips.Add(NewIp(i, subnetOne, $"10.80.10.{i + 3}", i == 1 ? IpStatuses.Allocated : i == 2 ? IpStatuses.Reserved : IpStatuses.Available, i == 1 ? ServerId(1) : i == 2 ? ServerId(3) : null));
            ips.Add(NewIp(20 + i, subnetTwo, $"10.80.20.{i + 3}", i == 1 ? IpStatuses.Allocated : IpStatuses.Available, i == 1 ? ServerId(2) : null));
        }
        modelBuilder.Entity<IpAddress>().HasData(ips);

        modelBuilder.Entity<AzureTarget>().HasData(
            NewTarget(1, 1, "az-hou-app01", "10.80.10.4", "vnet-lgr-prod-uks-01", "snet-prod-app", "Standard_D4s_v5"),
            NewTarget(2, 2, "az-hou-sql01", "10.80.20.4", "vnet-lgr-data-uks-01", "snet-prod-data", "Standard_E8s_v5"),
            NewTarget(3, 3, "az-rev-app01", "10.80.10.5", "vnet-lgr-prod-uks-01", "snet-prod-app", "Standard_D4s_v5"),
            NewTarget(4, 5, "az-dms-app01", "10.80.10.7", "vnet-lgr-prod-uks-01", "snet-prod-app", "Standard_D4s_v5"),
            NewTarget(5, 6, "az-dms-idx01", "10.80.20.7", "vnet-lgr-data-uks-01", "snet-prod-data", "Standard_E8s_v5"));

        var waves = new[]
        {
            NewWave(1, "Wave 1 - Housing", new DateOnly(2026, 5, 16), "In Progress", "Housing service production workload."),
            NewWave(2, "Wave 2 - Documents", new DateOnly(2026, 6, 20), "Planning", "Document management application and indexing tier."),
            NewWave(3, "Wave 3 - Corporate", new DateOnly(2026, 8, 15), "Not Started", "Revenues, environment and residual corporate workloads.")
        };
        modelBuilder.Entity<MigrationWave>().HasData(waves);

        modelBuilder.Entity<WaveAsset>().HasData(
            NewWaveAsset(1, 1, AppId(1), null), NewWaveAsset(2, 1, null, ServerId(1)), NewWaveAsset(3, 1, null, ServerId(2)),
            NewWaveAsset(4, 2, AppId(3), null), NewWaveAsset(5, 2, null, ServerId(5)), NewWaveAsset(6, 2, null, ServerId(6)),
            NewWaveAsset(7, 3, AppId(2), null), NewWaveAsset(8, 3, AppId(4), null), NewWaveAsset(9, 3, null, ServerId(3)), NewWaveAsset(10, 3, null, ServerId(4)), NewWaveAsset(11, 3, null, ServerId(7)), NewWaveAsset(12, 3, null, ServerId(8)));

        var readiness = new List<ReadinessCheck>();
        var readinessIndex = 1;
        for (var app = 1; app <= 5; app++)
        {
            readiness.Add(NewReadiness(readinessIndex++, AppId(app), null, "DiscoveryComplete", ReadinessStatuses.Complete, "Inventory owner confirmed."));
            readiness.Add(NewReadiness(readinessIndex++, AppId(app), null, "MigrationDecisionApproved", app == 4 ? ReadinessStatuses.Blocked : ReadinessStatuses.Complete, app == 4 ? "Architecture decision required." : "Decision recorded."));
            readiness.Add(NewReadiness(readinessIndex++, AppId(app), null, "BusinessTestingDefined", app is 2 or 3 ? ReadinessStatuses.AtRisk : ReadinessStatuses.Complete, app is 2 or 3 ? "Test lead action outstanding." : "Test plan agreed."));
        }
        for (var server = 1; server <= 10; server++)
        {
            readiness.Add(NewReadiness(readinessIndex++, null, ServerId(server), "AzureTargetDefined", server <= 6 ? ReadinessStatuses.Complete : ReadinessStatuses.NotStarted, server <= 6 ? "Target build reviewed." : "Target not yet designed."));
            readiness.Add(NewReadiness(readinessIndex++, null, ServerId(server), "IpAllocated", server <= 2 ? ReadinessStatuses.Complete : server == 8 ? ReadinessStatuses.Blocked : ReadinessStatuses.NotStarted, server == 8 ? "Network route decision blocked." : "IP plan status recorded."));
        }
        modelBuilder.Entity<ReadinessCheck>().HasData(readiness);

        var runbookId = OtherId(501);
        modelBuilder.Entity<Runbook>().HasData(new Runbook
        {
            Id = runbookId, CustomerId = SeedIds.DemoCustomer, ProjectId = SeedIds.DemoProject,
            MigrationWaveId = OtherId(301), Name = "Wave 1 - Housing Migration Runbook", Status = "Draft",
            CreatedAt = SeedTime, UpdatedAt = SeedTime
        });
        var taskNames = RunbookTemplate.DefaultTasks;
        modelBuilder.Entity<RunbookTask>().HasData(taskNames.Select((name, index) => new RunbookTask
        {
            Id = OtherId(600 + index), CustomerId = SeedIds.DemoCustomer, ProjectId = SeedIds.DemoProject,
            RunbookId = runbookId, Sequence = index + 1, Category = name, Task = name,
            Owner = index < 4 ? "Migration Lead" : "Technical Team", Status = "Not Started", Comment = string.Empty
        }).ToArray());

        SeedLookups(modelBuilder);
    }

    private static Application NewApplication(int id, string name, string environment, string criticality, string type, string version, string scope, string strategy, string status) => new()
    {
        Id = AppId(id), CustomerId = SeedIds.DemoCustomer, ProjectId = SeedIds.DemoProject,
        Name = name, Environment = environment, Description = $"Fictional {name.ToLowerInvariant()} workload.", Criticality = criticality,
        ApplicationType = type, CurrentVersion = version, MigrationScope = scope, MigrationStrategy = strategy, MigrationStatus = status,
        CreatedAt = SeedTime, UpdatedAt = SeedTime
    };

    private static Server NewServer(int id, string hostname, string environment, string os, string ip, int cores, int memory, int storage, string power, string status) => new()
    {
        Id = ServerId(id), CustomerId = SeedIds.DemoCustomer, ProjectId = SeedIds.DemoProject,
        Hostname = hostname, Environment = environment, OperatingSystem = os, IpAddress = ip, VCores = cores, MemoryMb = memory,
        AllocatedStorageGb = storage, PowerStatus = power, MigrationStatus = status, CreatedAt = SeedTime, UpdatedAt = SeedTime
    };

    private static MigrationDecision NewDecision(int id, int app, string scope, string strategy, string target, string reason, string risk, string status, DateOnly? date) => new()
    {
        Id = OtherId(400 + id), CustomerId = SeedIds.DemoCustomer, ProjectId = SeedIds.DemoProject, ApplicationId = AppId(app),
        MigrationScope = scope, MigrationStrategy = strategy, TargetPlatform = target, Reason = reason, Risk = risk,
        DecisionStatus = status, DecisionDate = date, CreatedAt = SeedTime, UpdatedAt = SeedTime
    };

    private static IpAddress NewIp(int id, Guid subnetId, string address, string status, Guid? serverId) => new()
    {
        Id = OtherId(700 + id), CustomerId = SeedIds.DemoCustomer, ProjectId = SeedIds.DemoProject, SubnetId = subnetId,
        Address = address, Status = status, ServerId = serverId,
        ReservedAt = status is IpStatuses.Reserved or IpStatuses.Allocated ? SeedTime.AddDays(10) : null,
        AllocatedAt = status == IpStatuses.Allocated ? SeedTime.AddDays(14) : null,
        CreatedAt = SeedTime, UpdatedAt = SeedTime
    };

    private static AzureTarget NewTarget(int id, int server, string hostname, string ip, string vnet, string subnet, string size) => new()
    {
        Id = OtherId(800 + id), CustomerId = SeedIds.DemoCustomer, ProjectId = SeedIds.DemoProject, ServerId = ServerId(server),
        Subscription = "LGR-Production", ResourceGroup = "rg-lgr-prod-uks-01", VNet = vnet, Subnet = subnet, AzureIp = ip,
        AzureHostname = hostname, VmSize = size, OperatingSystem = "Azure supported image", BackupPolicy = "Enhanced-30Day",
        Domain = "demo-council.example", OrganisationalUnit = "OU=Azure,OU=Servers", Notes = "POC target build example.",
        CreatedAt = SeedTime, UpdatedAt = SeedTime
    };

    private static MigrationWave NewWave(int id, string name, DateOnly date, string status, string description) => new()
    {
        Id = OtherId(300 + id), CustomerId = SeedIds.DemoCustomer, ProjectId = SeedIds.DemoProject, Name = name,
        PlannedDate = date, Status = status, Description = description, CreatedAt = SeedTime, UpdatedAt = SeedTime
    };

    private static WaveAsset NewWaveAsset(int id, int wave, Guid? app, Guid? server) => new()
    {
        Id = OtherId(900 + id), CustomerId = SeedIds.DemoCustomer, ProjectId = SeedIds.DemoProject,
        MigrationWaveId = OtherId(300 + wave), ApplicationId = app, ServerId = server, Status = "Planned"
    };

    private static ReadinessCheck NewReadiness(int id, Guid? app, Guid? server, string type, string status, string comment) => new()
    {
        Id = OtherId(1000 + id), CustomerId = SeedIds.DemoCustomer, ProjectId = SeedIds.DemoProject,
        ApplicationId = app, ServerId = server, CheckType = type, Status = status, Comment = comment, UpdatedAt = SeedTime
    };

    private static void SeedLookups(ModelBuilder modelBuilder)
    {
        var definitions = new Dictionary<string, string[]>
        {
            [LookupGroups.Environment] = ["Prod", "UAT", "Dev", "Test"],
            [LookupGroups.MigrationStrategy] = ["Rehost", "Build Ahead", "Replatform", "Refactor", "SaaS", "Retain", "Retire", "Investigate"],
            [LookupGroups.MigrationScope] = ["In Scope", "Out of Scope", "Under Review"],
            [LookupGroups.MigrationStatus] = ["Not Started", "In Progress", "Completed", "Rolled Back", "Blocked"],
            [LookupGroups.ApplicationCriticality] = ["Critical", "High", "Medium", "Low"],
            [LookupGroups.WorkloadType] = ["COTS", "Custom", "Database", "Web", "SaaS"],
            [LookupGroups.WaveStatus] = ["Not Started", "Planning", "Ready", "In Progress", "Completed", "Blocked"],
            [LookupGroups.RunbookStatus] = ["Draft", "In Review", "Approved", "In Progress", "Completed"]
        };

        var options = new List<LookupOption>();
        var id = 1;
        foreach (var group in definitions)
        {
            options.AddRange(group.Value.Select((value, index) => new LookupOption
            {
                Id = LookupId(id++), CustomerId = null, Group = group.Key, Value = value,
                DisplayName = value, SortOrder = index + 1, IsActive = true
            }));
        }
        modelBuilder.Entity<LookupOption>().HasData(options);
    }
}

public static class RunbookTemplate
{
    public static readonly string[] DefaultTasks =
    [
        "Pre-Migration Checks", "Backup Validation", "Network Validation", "Application Preparation",
        "Stop Application Services", "Migration Activity", "Start Azure Workload", "DNS / Connectivity Validation",
        "Technical Validation", "Business Validation", "Monitoring Validation", "Backup Validation", "Migration Completion"
    ];
}
