namespace LgrTransformationMigration.Api.Domain;

public interface ICustomerOwned
{
    Guid CustomerId { get; set; }
}

public interface IProjectOwned : ICustomerOwned
{
    Guid ProjectId { get; set; }
}

public sealed class Customer
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public ICollection<Project> Projects { get; set; } = [];
}

public sealed class Project : ICustomerOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateOnly? PlannedStartDate { get; set; }
    public DateOnly? PlannedEndDate { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public Customer Customer { get; set; } = null!;
}

public sealed class Application : IProjectOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Environment { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Criticality { get; set; } = string.Empty;
    public string ApplicationType { get; set; } = string.Empty;
    public string CurrentVersion { get; set; } = string.Empty;
    public string MigrationScope { get; set; } = string.Empty;
    public string MigrationStrategy { get; set; } = string.Empty;
    public string MigrationStatus { get; set; } = string.Empty;
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public Project Project { get; set; } = null!;
    public ICollection<ApplicationServer> ApplicationServers { get; set; } = [];
}

public sealed class Server : IProjectOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public string Hostname { get; set; } = string.Empty;
    public string Environment { get; set; } = string.Empty;
    public string OperatingSystem { get; set; } = string.Empty;
    public string IpAddress { get; set; } = string.Empty;
    public int? VCores { get; set; }
    public int? MemoryMb { get; set; }
    public int? AllocatedStorageGb { get; set; }
    public string PowerStatus { get; set; } = string.Empty;
    public string MigrationScope { get; set; } = string.Empty;
    public string MigrationStrategy { get; set; } = string.Empty;
    public string MigrationStatus { get; set; } = string.Empty;
    public string? ExternalSourceId { get; set; }
    public string? OsFamily { get; set; }
    public string? OsArchitecture { get; set; }
    public string? Processor { get; set; }
    public string? HypervisorType { get; set; }
    public string? Host { get; set; }
    public string? SupportStatus { get; set; }
    public string? DiscoveryMethod { get; set; }
    public DateTimeOffset? FirstDiscoveredAt { get; set; }
    public DateTimeOffset? LastDiscoveredAt { get; set; }
    public Guid? LastImportBatchId { get; set; }
    public DateTimeOffset? LastImportedAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public Project Project { get; set; } = null!;
    public ICollection<ApplicationServer> ApplicationServers { get; set; } = [];
    public ICollection<ServerDiscoverySnapshot> DiscoverySnapshots { get; set; } = [];
    public ImportBatch? LastImportBatch { get; set; }
    public AzureTarget? AzureTarget { get; set; }
}

public sealed class ImportBatch : IProjectOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public string SourceType { get; set; } = string.Empty;
    public string OriginalFileName { get; set; } = string.Empty;
    public string? StoredFileName { get; set; }
    public string FileHash { get; set; } = string.Empty;
    public long FileSizeBytes { get; set; }
    public string Status { get; set; } = string.Empty;
    public string UploadedBy { get; set; } = string.Empty;
    public DateTimeOffset UploadedAt { get; set; }
    public DateTimeOffset? PreviewedAt { get; set; }
    public DateTimeOffset? CommittedAt { get; set; }
    public int TotalRows { get; set; }
    public int ValidRows { get; set; }
    public int CreateCount { get; set; }
    public int UpdateCount { get; set; }
    public int UnchangedCount { get; set; }
    public int WarningCount { get; set; }
    public int RejectCount { get; set; }
    public string? Notes { get; set; }
    public Project Project { get; set; } = null!;
    public ICollection<DiscoveryImportRow> Rows { get; set; } = [];
    public ICollection<ServerDiscoverySnapshot> ServerSnapshots { get; set; } = [];
}

public sealed class DiscoveryImportRow : IProjectOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public Guid ImportBatchId { get; set; }
    public int RowNumber { get; set; }
    public string? SourceRecordId { get; set; }
    public string SourceType { get; set; } = string.Empty;
    public string RawDataJson { get; set; } = string.Empty;
    public string? NormalizedHostname { get; set; }
    public string Classification { get; set; } = string.Empty;
    public string ValidationStatus { get; set; } = string.Empty;
    public string? ValidationMessagesJson { get; set; }
    public Guid? MatchedEntityId { get; set; }
    public string? ProposedChangesJson { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public ImportBatch ImportBatch { get; set; } = null!;
    public Server? MatchedServer { get; set; }
}

public sealed class ServerDiscoverySnapshot : IProjectOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public Guid ServerId { get; set; }
    public Guid ImportBatchId { get; set; }
    public string? ExternalSourceId { get; set; }
    public string Hostname { get; set; } = string.Empty;
    public string? Environment { get; set; }
    public string? MigrationIntent { get; set; }
    public string? IpAddresses { get; set; }
    public string? OperatingSystem { get; set; }
    public string? Dependencies { get; set; }
    public int? SoftwareCount { get; set; }
    public int? DatabaseInstanceCount { get; set; }
    public int? WebAppCount { get; set; }
    public int? FileShareCount { get; set; }
    public string? SecurityRisks { get; set; }
    public string? SupportStatus { get; set; }
    public string? ApplicationNames { get; set; }
    public int? IssueCount { get; set; }
    public string? Tags { get; set; }
    public string? Host { get; set; }
    public int? MemoryMb { get; set; }
    public int? DiskCount { get; set; }
    public int? VCores { get; set; }
    public int? AllocatedStorageGb { get; set; }
    public int? NetworkAdapterCount { get; set; }
    public string? MacAddress { get; set; }
    public string? BootType { get; set; }
    public string? OsFamily { get; set; }
    public string? OsArchitecture { get; set; }
    public string? Processor { get; set; }
    public string? ResourceType { get; set; }
    public string? PowerStatus { get; set; }
    public string? HypervisorType { get; set; }
    public string? DiscoveryMethod { get; set; }
    public string? ConnectedAppliance { get; set; }
    public DateTimeOffset? FirstDiscoveredAt { get; set; }
    public DateTimeOffset? LastUpdatedAt { get; set; }
    public DateTimeOffset ImportedAt { get; set; }
    public Server Server { get; set; } = null!;
    public ImportBatch ImportBatch { get; set; } = null!;
}

public sealed class ApplicationServer : IProjectOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public Guid ApplicationId { get; set; }
    public Guid ServerId { get; set; }
    public Application Application { get; set; } = null!;
    public Server Server { get; set; } = null!;
}

public sealed class MigrationDecision : IProjectOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public Guid ApplicationId { get; set; }
    public string MigrationScope { get; set; } = string.Empty;
    public string MigrationStrategy { get; set; } = string.Empty;
    public string TargetPlatform { get; set; } = string.Empty;
    public string Reason { get; set; } = string.Empty;
    public string Risk { get; set; } = string.Empty;
    public string DecisionStatus { get; set; } = string.Empty;
    public DateOnly? DecisionDate { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public Application Application { get; set; } = null!;
}

public sealed class AzureTarget : IProjectOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public Guid ServerId { get; set; }
    public string Subscription { get; set; } = string.Empty;
    public string ResourceGroup { get; set; } = string.Empty;
    public string VNet { get; set; } = string.Empty;
    public string Subnet { get; set; } = string.Empty;
    public string AzureIp { get; set; } = string.Empty;
    public string AzureHostname { get; set; } = string.Empty;
    public string VmSize { get; set; } = string.Empty;
    public string OperatingSystem { get; set; } = string.Empty;
    public string BackupPolicy { get; set; } = string.Empty;
    public string Domain { get; set; } = string.Empty;
    public string OrganisationalUnit { get; set; } = string.Empty;
    public string Notes { get; set; } = string.Empty;
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public Server Server { get; set; } = null!;
}

public sealed class Subnet : IProjectOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string VNetName { get; set; } = string.Empty;
    public string Cidr { get; set; } = string.Empty;
    public string Environment { get; set; } = string.Empty;
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public ICollection<IpAddress> IpAddresses { get; set; } = [];
}

public sealed class IpAddress : IProjectOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public Guid SubnetId { get; set; }
    public string Address { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public Guid? ServerId { get; set; }
    public DateTimeOffset? ReservedAt { get; set; }
    public DateTimeOffset? AllocatedAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public Subnet Subnet { get; set; } = null!;
    public Server? Server { get; set; }
}

public sealed class MigrationWave : IProjectOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public string Name { get; set; } = string.Empty;
    public DateOnly? PlannedDate { get; set; }
    public string Status { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public ICollection<WaveAsset> Assets { get; set; } = [];
}

public sealed class WaveAsset : IProjectOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public Guid MigrationWaveId { get; set; }
    public Guid? ApplicationId { get; set; }
    public Guid? ServerId { get; set; }
    public string Status { get; set; } = string.Empty;
    public MigrationWave MigrationWave { get; set; } = null!;
    public Application? Application { get; set; }
    public Server? Server { get; set; }
}

public sealed class ReadinessCheck : IProjectOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public Guid? ApplicationId { get; set; }
    public Guid? ServerId { get; set; }
    public string CheckType { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string Comment { get; set; } = string.Empty;
    public DateTimeOffset UpdatedAt { get; set; }
    public Application? Application { get; set; }
    public Server? Server { get; set; }
}

public sealed class Runbook : IProjectOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public Guid MigrationWaveId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public MigrationWave MigrationWave { get; set; } = null!;
    public ICollection<RunbookTask> Tasks { get; set; } = [];
}

public sealed class RunbookTask : IProjectOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public Guid RunbookId { get; set; }
    public int Sequence { get; set; }
    public string Category { get; set; } = string.Empty;
    public string Task { get; set; } = string.Empty;
    public string Owner { get; set; } = string.Empty;
    public DateTimeOffset? PlannedStart { get; set; }
    public DateTimeOffset? PlannedEnd { get; set; }
    public DateTimeOffset? ActualStart { get; set; }
    public DateTimeOffset? ActualEnd { get; set; }
    public string Status { get; set; } = string.Empty;
    public string Comment { get; set; } = string.Empty;
    public Runbook Runbook { get; set; } = null!;
}

public sealed class AuditEvent : ICustomerOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid? ProjectId { get; set; }
    public string EntityType { get; set; } = string.Empty;
    public Guid EntityId { get; set; }
    public string Action { get; set; } = string.Empty;
    public string? PropertyName { get; set; }
    public string? OldValue { get; set; }
    public string? NewValue { get; set; }
    public string ChangedBy { get; set; } = string.Empty;
    public DateTimeOffset ChangedAt { get; set; }
}

public sealed class LookupOption
{
    public Guid Id { get; set; }
    public Guid? CustomerId { get; set; }
    public string Group { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
}
