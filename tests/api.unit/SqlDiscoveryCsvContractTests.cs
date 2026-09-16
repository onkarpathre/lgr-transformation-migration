using LgrTransformationMigration.Api.Domain;
using LgrTransformationMigration.Api.Services.Discovery;
using System.Text;

namespace LgrTransformationMigration.Api.UnitTests;

public sealed class SqlDiscoveryCsvContractTests
{
    private readonly CsvDiscoveryFileReader reader = new();
    private readonly SqlDiscoveryCsvContract contract = new();

    [Fact]
    public void Instance_contract_normalizes_default_status_alias_and_utc_timestamp()
    {
        var document = reader.Parse(
            "Server,Instance Name,SQL Version,Edition,Port,Service Status,Discovery Source,Last Discovered At\n" +
            "SYNTH-SQL01,default,SQL Server 2022,Standard,1433,Online,Synthetic scan,2026-09-15T12:00:00+01:00");

        var unknown = contract.ValidateHeaders(DiscoverySourceTypes.SqlInstanceCsvV1, document.Headers);
        var result = contract.Validate(DiscoverySourceTypes.SqlInstanceCsvV1, document.Rows.Single(), unknown, false);

        Assert.False(result.HasErrors);
        Assert.Equal("SYNTH-SQL01", result.NormalizedHostname);
        Assert.Equal("MSSQLSERVER", result.NormalizedInstanceName);
        Assert.Equal(SqlInstanceServiceStatuses.Running, result.ServiceStatus);
        Assert.Equal(DateTimeOffset.Parse("2026-09-15T11:00:00Z"), result.LastDiscoveredAt);
    }

    [Fact]
    public void Database_contract_normalizes_recovery_and_status_variants()
    {
        var document = reader.Parse(
            "Status,Collation,Recovery Model,Compatibility Level,Size MB,Database Name,Instance Name,Server\n" +
            "recovery_pending,,Bulk-Logged,160,9223372036854775807,SyntheticDb,MSSQLSERVER,SYNTH-SQL01");

        var result = contract.Validate(
            DiscoverySourceTypes.SqlDatabaseCsvV1,
            document.Rows.Single(),
            contract.ValidateHeaders(DiscoverySourceTypes.SqlDatabaseCsvV1, document.Headers),
            false);

        Assert.False(result.HasErrors);
        Assert.Equal(long.MaxValue, result.SizeMb);
        Assert.Equal(SqlDatabaseRecoveryModels.BulkLogged, result.RecoveryModel);
        Assert.Equal(SqlDatabaseStatuses.RecoveryPending, result.DatabaseStatus);
        Assert.False(result.CollationSupplied);
    }

    [Fact]
    public void Unknown_safe_status_extra_column_and_repeat_hash_are_warnings()
    {
        var document = reader.Parse(
            "Server,Instance Name,SQL Version,Edition,Port,Service Status,Discovery Source,Last Discovered At,Extra\n" +
            "SYNTH-SQL01,SYNTH,SQL Server 2022,Standard,,Starting,Synthetic scan,,evidence");
        var unknown = contract.ValidateHeaders(DiscoverySourceTypes.SqlInstanceCsvV1, document.Headers);

        var result = contract.Validate(DiscoverySourceTypes.SqlInstanceCsvV1, document.Rows.Single(), unknown, true);

        Assert.False(result.HasErrors);
        Assert.True(result.HasWarnings);
        Assert.Equal(SqlInstanceServiceStatuses.Unknown, result.ServiceStatus);
        Assert.Equal(3, result.Messages.Count(message => message.Severity == ValidationSeverities.Warning));
    }

    [Theory]
    [InlineData("0", "Running", "2026-09-15T12:00:00Z")]
    [InlineData("65536", "Running", "2026-09-15T12:00:00Z")]
    [InlineData("1433", "Running", "2026-09-15T12:00:00")]
    [InlineData("1433", "Running", "2026-09-15")]
    public void Invalid_instance_ranges_or_non_offset_dates_are_rejected(string port, string status, string timestamp)
    {
        var document = reader.Parse(
            "Server,Instance Name,SQL Version,Edition,Port,Service Status,Discovery Source,Last Discovered At\n" +
            $"SYNTH-SQL01,SYNTH,SQL Server 2022,Standard,{port},{status},Synthetic scan,{timestamp}");

        var result = contract.Validate(
            DiscoverySourceTypes.SqlInstanceCsvV1,
            document.Rows.Single(),
            [],
            false);

        Assert.True(result.HasErrors);
    }

    [Theory]
    [InlineData("-1", "160", "Full")]
    [InlineData("1", "79", "Full")]
    [InlineData("1", "201", "Full")]
    [InlineData("1", "160", "Unsupported")]
    public void Invalid_database_ranges_and_recovery_values_are_rejected(
        string size,
        string compatibility,
        string recovery)
    {
        var document = reader.Parse(
            "Server,Instance Name,Database Name,Size MB,Compatibility Level,Recovery Model,Collation,Status\n" +
            $"SYNTH-SQL01,SYNTH,SyntheticDb,{size},{compatibility},{recovery},,Online");

        var result = contract.Validate(DiscoverySourceTypes.SqlDatabaseCsvV1, document.Rows.Single(), [], false);

        Assert.True(result.HasErrors);
    }

    [Theory]
    [InlineData("=cmd")]
    [InlineData(" +SUM(A1:A2)")]
    [InlineData("@formula")]
    [InlineData("\tformula")]
    public void Formula_like_source_values_are_rejected_without_echoing_value(string value)
    {
        var document = reader.Parse(
            "Server,Instance Name,SQL Version,Edition,Port,Service Status,Discovery Source,Last Discovered At\n" +
            $"SYNTH-SQL01,SYNTH,SQL Server 2022,Standard,1433,Running,{value},");

        var result = contract.Validate(DiscoverySourceTypes.SqlInstanceCsvV1, document.Rows.Single(), [], false);

        Assert.True(result.HasErrors);
        Assert.DoesNotContain(result.Messages, message => message.Message.Contains(value.Trim(), StringComparison.Ordinal));
    }

    [Fact]
    public void Credential_like_extra_column_is_rejected()
    {
        var document = reader.Parse(
            "Server,Instance Name,SQL Version,Edition,Port,Service Status,Discovery Source,Last Discovered At,Password\n" +
            "SYNTH-SQL01,SYNTH,SQL Server 2022,Standard,1433,Running,Synthetic scan,,not-a-real-secret");

        var result = contract.Validate(
            DiscoverySourceTypes.SqlInstanceCsvV1,
            document.Rows.Single(),
            contract.ValidateHeaders(DiscoverySourceTypes.SqlInstanceCsvV1, document.Headers),
            false);

        Assert.True(result.HasErrors);
        Assert.Contains(result.Messages, message => message.Message == "Credential-like source data is not permitted.");
    }

    [Fact]
    public void Required_header_mismatch_is_an_unsupported_recognized_contract()
    {
        var document = reader.Parse("Server,Instance Name\nSYNTH-SQL01,SYNTH");

        Assert.Throws<UnsupportedSourceContractException>(() =>
            contract.ValidateHeaders(DiscoverySourceTypes.SqlInstanceCsvV1, document.Headers));
    }

    [Fact]
    public void Csv_parser_supports_quoted_line_breaks_and_rejects_normalized_duplicate_headers()
    {
        var quoted = reader.Parse("Server,Notes\r\nSYNTH-SQL01,\"line one\r\nline two\"");
        Assert.Equal("line one\r\nline two", quoted.Rows.Single().Values["Notes"]);

        Assert.Throws<DomainValidationException>(() =>
            reader.Parse("Instance Name,instance-name\nSYNTH,SYNTH"));
    }

    [Fact]
    public void Csv_parser_enforces_column_and_row_safety_envelopes()
    {
        var tooManyColumns = string.Join(',', Enumerable.Range(1, CsvDiscoveryFileReader.MaximumColumns + 1).Select(i => $"C{i}"));
        Assert.Throws<DomainValidationException>(() => reader.Parse($"{tooManyColumns}\nvalue"));

        var content = new StringBuilder("Server\n");
        for (var index = 0; index <= CsvDiscoveryFileReader.MaximumDataRows; index++) content.AppendLine($"S{index}");
        Assert.Throws<DomainValidationException>(() => reader.Parse(content.ToString()));
    }
}
