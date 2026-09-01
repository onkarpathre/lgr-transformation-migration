using LgrTransformationMigration.Api.Contracts;

namespace LgrTransformationMigration.Api.Services.Discovery;

public sealed record CsvDataRow(int RowNumber, IReadOnlyDictionary<string, string> Values);
public sealed record DiscoveryFileDocument(IReadOnlyList<string> Headers, IReadOnlyList<CsvDataRow> Rows);

public sealed class DiscoveryServerRecord
{
    public required IReadOnlyDictionary<string, string> RawData { get; init; }
    public bool IsServerRecord { get; init; }
    public string? SourceRecordId { get; init; }
    public string? ParentId { get; init; }
    public string? Hostname { get; init; }
    public string? Environment { get; init; }
    public string? MigrationIntent { get; init; }
    public string? OperatingSystem { get; init; }
    public string? IpAddresses { get; init; }
    public string? Dependencies { get; init; }
    public string? SoftwareCount { get; init; }
    public string? DatabaseInstanceCount { get; init; }
    public string? WebAppCount { get; init; }
    public string? FileShareCount { get; init; }
    public string? SecurityRisks { get; init; }
    public string? SupportStatus { get; init; }
    public string? ApplicationNames { get; init; }
    public string? IssueCount { get; init; }
    public string? Tags { get; init; }
    public string? Host { get; init; }
    public string? MemoryMb { get; init; }
    public string? DiskCount { get; init; }
    public string? VCores { get; init; }
    public string? AllocatedStorageGb { get; init; }
    public string? NetworkAdapterCount { get; init; }
    public string? MacAddress { get; init; }
    public string? BootType { get; init; }
    public string? OsFamily { get; init; }
    public string? OsArchitecture { get; init; }
    public string? FirstDiscoveredAt { get; init; }
    public string? LastUpdatedAt { get; init; }
    public string? Processor { get; init; }
    public string? ResourceType { get; init; }
    public string? PowerStatus { get; init; }
    public string? HypervisorType { get; init; }
    public string? DiscoveryMethod { get; init; }
    public string? ConnectedAppliance { get; init; }
    public string? AppArmIdNames { get; init; }
}

public sealed record ValidatedDiscoveryRecord(
    DiscoveryServerRecord Source,
    string? NormalizedHostname,
    string? NormalizedEnvironment,
    IReadOnlyList<string> ValidIpAddresses,
    int? SoftwareCount,
    int? DatabaseInstanceCount,
    int? WebAppCount,
    int? FileShareCount,
    int? IssueCount,
    int? MemoryMb,
    int? DiskCount,
    int? VCores,
    int? AllocatedStorageGb,
    int? NetworkAdapterCount,
    DateTimeOffset? FirstDiscoveredAt,
    DateTimeOffset? LastUpdatedAt,
    IReadOnlyList<DiscoveryValidationMessageDto> Messages)
{
    public bool HasErrors => Messages.Any(x => x.Severity == Domain.ValidationSeverities.Error);
    public bool HasWarnings => Messages.Any(x => x.Severity == Domain.ValidationSeverities.Warning);
}

public sealed record DiscoveryReconciliationResult(string Classification, IReadOnlyList<DiscoveryFieldChangeDto> Changes);
