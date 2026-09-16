using System.ComponentModel.DataAnnotations;

namespace LgrTransformationMigration.Api.Contracts;

public sealed class DiscoveryUploadRequest
{
    [Required]
    public string SourceType { get; set; } = string.Empty;

    [Required]
    public IFormFile File { get; set; } = null!;
}

public sealed record DiscoveryImportBatchDto(
    Guid Id, Guid CustomerId, Guid ProjectId, string SourceType, string OriginalFileName,
    string FileHash, long FileSizeBytes, string Status, string UploadedBy, DateTimeOffset UploadedAt,
    DateTimeOffset? PreviewedAt, DateTimeOffset? CommittedAt, int TotalRows, int ValidRows,
    int CreateCount, int UpdateCount, int UnchangedCount, int WarningCount, int RejectCount,
    string? Notes, string? DuplicateWarning, string Version);

public sealed record DiscoveryImportRowDto(
    Guid Id, int RowNumber, string? SourceRecordId, string? Hostname, string? Environment,
    string? OperatingSystem, string? CurrentIp, string Classification, string ValidationStatus,
    string? MatchedServerName, Guid? MatchedServerId);

public sealed record DiscoveryValidationMessageDto(string Severity, string Field, string Message);

public sealed record DiscoveryFieldChangeDto(string Field, string? OldValue, string? NewValue);

public sealed record DiscoveryImportRowDetailDto(
    Guid Id, int RowNumber, string SourceType, IReadOnlyDictionary<string, string> RawData,
    string? NormalizedHostname, string Classification, string ValidationStatus,
    IReadOnlyList<DiscoveryValidationMessageDto> ValidationMessages,
    NamedReferenceDto? MatchedServer, IReadOnlyList<DiscoveryFieldChangeDto> ProposedChanges);

public sealed record ServerDiscoverySnapshotDto(
    Guid Id, Guid ImportBatchId, string SourceType, string? ExternalSourceId, string Hostname,
    string? Environment, string? MigrationIntent, string? IpAddresses, string? OperatingSystem,
    string? Dependencies, int? SoftwareCount, int? DatabaseInstanceCount, int? WebAppCount,
    int? FileShareCount, string? SecurityRisks, string? SupportStatus, string? ApplicationNames,
    int? IssueCount, string? Tags, string? Host, int? MemoryMb, int? DiskCount, int? VCores,
    int? AllocatedStorageGb, int? NetworkAdapterCount, string? MacAddress, string? BootType,
    string? OsFamily, string? OsArchitecture, string? Processor, string? ResourceType,
    string? PowerStatus, string? HypervisorType, string? DiscoveryMethod,
    string? ConnectedAppliance, DateTimeOffset? FirstDiscoveredAt,
    DateTimeOffset? LastUpdatedAt, DateTimeOffset ImportedAt);

public sealed record SqlDiscoveryImportRowDto(
    Guid Id,
    int RowNumber,
    string SourceType,
    string? Server,
    string? InstanceName,
    string? DatabaseName,
    string Classification,
    string? ProposedAction,
    string ValidationStatus,
    NamedReferenceDto? MatchedServer,
    NamedReferenceDto? MatchedSqlInstance,
    NamedReferenceDto? MatchedSqlDatabase);

public sealed record SqlDiscoveryImportRowDetailDto(
    Guid Id,
    int RowNumber,
    string SourceType,
    IReadOnlyDictionary<string, string> RawData,
    string? NormalizedHostname,
    string? NormalizedInstanceName,
    string? NormalizedDatabaseName,
    string Classification,
    string? ProposedAction,
    string ValidationStatus,
    IReadOnlyList<DiscoveryValidationMessageDto> ValidationMessages,
    NamedReferenceDto? MatchedServer,
    NamedReferenceDto? MatchedSqlInstance,
    NamedReferenceDto? MatchedSqlDatabase,
    IReadOnlyList<DiscoveryFieldChangeDto> ProposedChanges);

public sealed record SqlInstanceDiscoverySnapshotDto(
    Guid Id,
    Guid ImportBatchId,
    string SourceType,
    Guid ServerId,
    string InstanceName,
    string SqlVersion,
    string Edition,
    int? Port,
    string ServiceStatus,
    string DiscoverySource,
    DateTimeOffset? LastDiscoveredAt,
    DateTimeOffset ImportedAt);

public sealed record SqlDatabaseDiscoverySnapshotDto(
    Guid Id,
    Guid ImportBatchId,
    string SourceType,
    Guid SqlInstanceId,
    string Name,
    long SizeMb,
    int CompatibilityLevel,
    string RecoveryModel,
    string? Collation,
    string Status,
    DateTimeOffset ImportedAt);
