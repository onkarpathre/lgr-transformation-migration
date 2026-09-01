using LgrTransformationMigration.Api.Domain;
using LgrTransformationMigration.Api.Services.Discovery;

namespace LgrTransformationMigration.Api.UnitTests;

public sealed class DiscoveryImportTests
{
    private readonly DiscoveryRecordValidator validator = new();
    private readonly DiscoveryReconciler reconciler = new();

    [Fact]
    public void Valid_server_report_parses_quoted_commas_and_lf_rows()
    {
        var csv = " Id , SERVER ,memory (mb),IPv4 / IPv6,Operating System\n" +
                  "srv-1, DC-CSV-01 ,16384,\"10.0.0.1, 2001:db8::1\",\"Windows Server, 2022\"\n";
        var document = new CsvDiscoveryFileReader().Parse(csv);
        var mapper = new AzureMigrateServerReportMapper();
        mapper.ValidateHeaders(document.Headers);
        var record = mapper.Map(Assert.Single(document.Rows).Values);

        Assert.Equal("DC-CSV-01", record.Hostname);
        Assert.Equal("Windows Server, 2022", record.OperatingSystem);
        Assert.Equal("10.0.0.1, 2001:db8::1", record.IpAddresses);
    }

    [Fact]
    public void Column_mapping_tolerates_case_spaces_slashes_and_hash_characters()
    {
        var mapper = new AzureMigrateServerReportMapper();
        var raw = new Dictionary<string, string>
        {
            [" SERVER "] = "dc-map-01",
            ["memory (mb)"] = "8192",
            ["IPv4 / IPv6"] = "10.1.1.10",
            ["SOFTWARES(#)"] = "9",
            ["Operating System"] = "Windows Server 2019"
        };
        mapper.ValidateHeaders(raw.Keys.ToArray());
        var record = mapper.Map(raw);

        Assert.Equal("dc-map-01", record.Hostname);
        Assert.Equal("8192", record.MemoryMb);
        Assert.Equal("9", record.SoftwareCount);
    }

    [Fact]
    public void Missing_hostname_is_rejected()
    {
        var validated = validator.Validate(Record(hostname: null));
        var result = reconciler.Reconcile(validated, null);

        Assert.True(validated.HasErrors);
        Assert.Equal(ImportClassifications.Reject, result.Classification);
    }

    [Fact]
    public void Invalid_numeric_value_is_rejected()
    {
        var validated = validator.Validate(Record(memory: "sixteen gigabytes"));
        var result = reconciler.Reconcile(validated, null);

        Assert.Contains(validated.Messages, x => x.Field == "Memory (MB)" && x.Severity == ValidationSeverities.Error);
        Assert.Equal(ImportClassifications.Reject, result.Classification);
    }

    [Theory]
    [InlineData("Production", "Prod")]
    [InlineData("PROD", "Prod")]
    [InlineData("Prod", "Prod")]
    [InlineData("Development", "Dev")]
    [InlineData("DEV", "Dev")]
    [InlineData("User Acceptance Testing", "UAT")]
    [InlineData("UAT", "UAT")]
    public void Environment_values_are_normalised(string source, string expected)
    {
        var result = validator.Validate(Record(environment: source));
        Assert.Equal(expected, result.NormalizedEnvironment);
        Assert.False(result.HasWarnings);
    }

    [Fact]
    public void No_matching_server_classifies_create()
    {
        var result = reconciler.Reconcile(validator.Validate(Record()), null);
        Assert.Equal(ImportClassifications.Create, result.Classification);
    }

    [Fact]
    public void Changed_discovery_field_classifies_update()
    {
        var server = Server(memory: 8192);
        var result = reconciler.Reconcile(validator.Validate(Record(memory: "16384")), server);

        Assert.Equal(ImportClassifications.Update, result.Classification);
        Assert.Contains(result.Changes, x => x.Field == "MemoryMb" && x.OldValue == "8192" && x.NewValue == "16384");
    }

    [Fact]
    public void Equivalent_discovery_fields_classify_unchanged()
    {
        var server = Server(memory: 16384);
        var result = reconciler.Reconcile(validator.Validate(Record(memory: "16384")), server);
        Assert.Equal(ImportClassifications.Unchanged, result.Classification);
    }

    [Fact]
    public void Unknown_environment_classifies_warning_without_rejecting()
    {
        var validated = validator.Validate(Record(environment: "Training Lab"));
        var result = reconciler.Reconcile(validated, null);

        Assert.False(validated.HasErrors);
        Assert.True(validated.HasWarnings);
        Assert.Equal("Training Lab", validated.NormalizedEnvironment);
        Assert.Equal(ImportClassifications.Warning, result.Classification);
    }

    [Fact]
    public void Field_differences_include_each_meaningful_change()
    {
        var server = Server(memory: 8192);
        server.OperatingSystem = "Windows Server 2016";
        server.PowerStatus = "Off";
        var record = WithChanges(Record(memory: "16384"), "Windows Server 2022", "On");
        var result = reconciler.Reconcile(validator.Validate(record), server);

        Assert.Equal(3, result.Changes.Count);
        Assert.Contains(result.Changes, x => x.Field == "OperatingSystem" && x.OldValue == "Windows Server 2016" && x.NewValue == "Windows Server 2022");
        Assert.Contains(result.Changes, x => x.Field == "PowerStatus" && x.OldValue == "Off" && x.NewValue == "On");
    }

    [Fact]
    public void All_inventory_mapper_identifies_a_clear_server_row()
    {
        var mapper = new AzureMigrateAllInventoryMapper();
        var raw = new Dictionary<string, string>
        {
            ["Id"] = "all-1", ["Server"] = "DC-ALL-01", ["Workload"] = "Server",
            ["Category"] = "Infrastructure", ["Type"] = "Virtual Machine", ["Memory (MB)"] = "4096"
        };
        mapper.ValidateHeaders(raw.Keys.ToArray());
        var record = mapper.Map(raw);

        Assert.True(record.IsServerRecord);
        Assert.Equal(ImportClassifications.Create, reconciler.Reconcile(validator.Validate(record), null).Classification);
    }

    [Fact]
    public void All_inventory_non_server_row_is_staged_as_warning()
    {
        var mapper = new AzureMigrateAllInventoryMapper();
        var raw = new Dictionary<string, string>
        {
            ["Id"] = "db-1", ["Server"] = "DC-ALL-01", ["Workload"] = "Database",
            ["Category"] = "Database", ["Type"] = "SQL Database"
        };
        var result = reconciler.Reconcile(validator.Validate(mapper.Map(raw)), null);
        Assert.Equal(ImportClassifications.Warning, result.Classification);
    }

    [Fact]
    public void Selected_source_conflict_returns_clear_validation_error()
    {
        var exception = Assert.Throws<DomainValidationException>(() => new AzureMigrateServerReportMapper()
            .ValidateHeaders(["Server", "Operating System", "Workload", "Category", "Type"]));
        Assert.Contains("conflicts", exception.Message, StringComparison.OrdinalIgnoreCase);
    }

    private static DiscoveryServerRecord Record(string? hostname = "DC-UNIT-01", string? environment = "Prod", string? memory = null) => new()
    {
        RawData = new Dictionary<string, string>(), IsServerRecord = true, Hostname = hostname,
        Environment = environment, MemoryMb = memory
    };

    private static DiscoveryServerRecord WithChanges(DiscoveryServerRecord source, string operatingSystem, string powerStatus) => new()
    {
        RawData = source.RawData, IsServerRecord = source.IsServerRecord, Hostname = source.Hostname,
        Environment = source.Environment, MemoryMb = source.MemoryMb,
        OperatingSystem = operatingSystem, PowerStatus = powerStatus
    };

    private static Server Server(int memory) => new()
    {
        Id = Guid.NewGuid(), CustomerId = Guid.NewGuid(), ProjectId = Guid.NewGuid(), Hostname = "DC-UNIT-01",
        Environment = "Prod", OperatingSystem = string.Empty, IpAddress = string.Empty, MemoryMb = memory,
        PowerStatus = string.Empty, MigrationScope = "In Scope", MigrationStrategy = "Rehost", MigrationStatus = "Not Started"
    };
}
