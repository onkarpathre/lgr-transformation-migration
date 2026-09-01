using System.ComponentModel.DataAnnotations;

namespace LgrTransformationMigration.Api.Contracts;

public sealed record PagedResult<T>(IReadOnlyList<T> Items, int Page, int PageSize, int TotalCount);

public sealed record CustomerDto(Guid Id, string Name, string Code, string Status, DateTimeOffset CreatedAt, DateTimeOffset UpdatedAt);
public sealed record CustomerRequest([Required, MaxLength(200)] string Name, [Required, MaxLength(50)] string Code, [Required] string Status);

public sealed record ProjectDto(Guid Id, Guid CustomerId, string Name, string Description, string Status, DateOnly? PlannedStartDate, DateOnly? PlannedEndDate, DateTimeOffset CreatedAt, DateTimeOffset UpdatedAt);
public sealed record ProjectRequest([Required, MaxLength(200)] string Name, string Description, [Required] string Status, DateOnly? PlannedStartDate, DateOnly? PlannedEndDate);

public sealed record ApplicationDto(
    Guid Id, Guid CustomerId, Guid ProjectId, string Name, string Environment, string Description,
    string Criticality, string ApplicationType, string CurrentVersion, string MigrationScope,
    string MigrationStrategy, string MigrationStatus, IReadOnlyList<NamedReferenceDto> AssociatedServers,
    DateTimeOffset CreatedAt, DateTimeOffset UpdatedAt);

public sealed record ApplicationRequest(
    [Required, MaxLength(200)] string Name, [Required] string Environment, string Description,
    [Required] string Criticality, [Required] string ApplicationType, string CurrentVersion,
    [Required] string MigrationScope, [Required] string MigrationStrategy, [Required] string MigrationStatus,
    IReadOnlyList<Guid>? ServerIds);

public sealed record ServerDto(
    Guid Id, Guid CustomerId, Guid ProjectId, string Hostname, string Environment, string OperatingSystem,
    string IpAddress, int? VCores, int? MemoryMb, int? AllocatedStorageGb, string PowerStatus,
    string MigrationScope, string MigrationStrategy, string MigrationStatus,
    string? DiscoverySource, DateTimeOffset? LastDiscoveredAt, DateTimeOffset? LastImportedAt,
    string? SupportStatus, string DiscoveryFreshness,
    IReadOnlyList<NamedReferenceDto> AssociatedApplications, NamedReferenceDto? AzureTarget,
    DateTimeOffset CreatedAt, DateTimeOffset UpdatedAt);

public sealed record ServerRequest(
    [Required, MaxLength(253)] string Hostname, [Required] string Environment, [Required] string OperatingSystem,
    string IpAddress, [Range(1, 1024)] int? VCores, [Range(1, int.MaxValue)] int? MemoryMb,
    [Range(1, int.MaxValue)] int? AllocatedStorageGb, [Required] string PowerStatus,
    [Required] string MigrationStatus, IReadOnlyList<Guid>? ApplicationIds);

public sealed record NamedReferenceDto(Guid Id, string Name);

public sealed record MigrationDecisionDto(
    Guid Id, Guid ApplicationId, string ApplicationName, string MigrationScope, string MigrationStrategy,
    string TargetPlatform, string Reason, string Risk, string DecisionStatus, DateOnly? DecisionDate,
    DateTimeOffset CreatedAt, DateTimeOffset UpdatedAt);

public sealed record MigrationDecisionRequest(
    Guid ApplicationId, [Required] string MigrationScope, [Required] string MigrationStrategy,
    [Required] string TargetPlatform, [Required] string Reason, [Required] string Risk,
    [Required] string DecisionStatus, DateOnly? DecisionDate);

public sealed record AzureTargetDto(
    Guid Id, Guid ServerId, string ServerName, string Subscription, string ResourceGroup, string VNet,
    string Subnet, string AzureIp, string AzureHostname, string VmSize, string OperatingSystem,
    string BackupPolicy, string Domain, string OrganisationalUnit, string Notes,
    DateTimeOffset CreatedAt, DateTimeOffset UpdatedAt);

public sealed record AzureTargetRequest(
    Guid ServerId, [Required] string Subscription, [Required] string ResourceGroup, [Required] string VNet,
    [Required] string Subnet, [Required] string AzureIp, [Required] string AzureHostname, [Required] string VmSize,
    [Required] string OperatingSystem, string BackupPolicy, string Domain, string OrganisationalUnit, string Notes);

public sealed record SubnetDto(
    Guid Id, string Name, string VNetName, string Cidr, string Environment,
    int TotalAddresses, int Available, int Reserved, int Allocated, DateTimeOffset CreatedAt, DateTimeOffset UpdatedAt);
public sealed record SubnetRequest([Required] string Name, [Required] string VNetName, [Required] string Cidr, [Required] string Environment);

public sealed record IpAddressDto(
    Guid Id, Guid SubnetId, string SubnetName, string Address, string Status, Guid? ServerId, string? ServerName,
    DateTimeOffset? ReservedAt, DateTimeOffset? AllocatedAt, DateTimeOffset CreatedAt, DateTimeOffset UpdatedAt);
public sealed record IpAddressRequest(Guid SubnetId, [Required] string Address, string Status = "Available");
public sealed record IpTransitionRequest(Guid? ServerId);

public sealed record MigrationWaveDto(
    Guid Id, string Name, DateOnly? PlannedDate, string Status, string Description,
    int Applications, int Servers, int Ready, int Blocked, DateTimeOffset CreatedAt, DateTimeOffset UpdatedAt);
public sealed record MigrationWaveRequest([Required] string Name, DateOnly? PlannedDate, [Required] string Status, string Description);
public sealed record WaveAssetRequest(Guid? ApplicationId, Guid? ServerId, string Status = "Planned");
public sealed record WaveAssetDto(Guid Id, Guid? ApplicationId, Guid? ServerId, string AssetName, string AssetType, string Status, string OverallReadiness);
public sealed record MigrationWaveDetailDto(MigrationWaveDto Wave, IReadOnlyList<WaveAssetDto> Assets);

public sealed record ReadinessCheckDto(
    Guid Id, Guid? ApplicationId, Guid? ServerId, string AssetName, string AssetType,
    string CheckType, string Status, string Comment, string OverallStatus, DateTimeOffset UpdatedAt);
public sealed record ReadinessUpdateRequest([Required] string Status, string Comment);
public sealed record WaveReadinessSummaryDto(Guid WaveId, string WaveName, int TotalAssets, int Ready, int AtRisk, int NotReady, int Blocked);
public sealed record ReadinessResponse(IReadOnlyList<ReadinessCheckDto> Checks, IReadOnlyList<WaveReadinessSummaryDto> Waves);

public sealed record RunbookTaskDto(
    Guid Id, int Sequence, string Category, string Task, string Owner, DateTimeOffset? PlannedStart,
    DateTimeOffset? PlannedEnd, DateTimeOffset? ActualStart, DateTimeOffset? ActualEnd, string Status, string Comment);
public sealed record RunbookDto(
    Guid Id, Guid MigrationWaveId, string MigrationWaveName, string Name, string Status,
    IReadOnlyList<RunbookTaskDto> Tasks, DateTimeOffset CreatedAt, DateTimeOffset UpdatedAt);
public sealed record GenerateRunbookRequest(Guid MigrationWaveId, string? Name);
public sealed record RunbookTaskUpdateRequest([Required] string Status, string? Owner, string? Comment, DateTimeOffset? ActualStart, DateTimeOffset? ActualEnd);

public sealed record LookupOptionDto(Guid Id, Guid? CustomerId, string Group, string Value, string DisplayName, int SortOrder, bool IsActive);
public sealed record LookupOptionRequest([Required] string Group, [Required] string Value, [Required] string DisplayName, int SortOrder, bool IsActive = true);

public sealed record DashboardSummaryDto(
    int TotalApplications, int TotalServers, int ApplicationsInScope, int ApplicationsMigrated,
    int ServersMigrated, int MigrationWaves, int ReadyAssets, int BlockedAssets,
    int AvailableIpAddresses, int ReservedIpAddresses, int AllocatedIpAddresses,
    IReadOnlyDictionary<string, int> ApplicationMigrationStatus, IReadOnlyList<MigrationWaveDto> Waves,
    DiscoveryDashboardDto? Discovery);

public sealed record DiscoveryDashboardDto(
    Guid ImportBatchId, DateTimeOffset ImportDate, string Status, int ServersDiscovered,
    int Created, int Updated, int Warnings, int Rejects);
