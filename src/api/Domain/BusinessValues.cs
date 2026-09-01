namespace LgrTransformationMigration.Api.Domain;

public static class LookupGroups
{
    public const string Environment = nameof(Environment);
    public const string MigrationStrategy = nameof(MigrationStrategy);
    public const string MigrationScope = nameof(MigrationScope);
    public const string MigrationStatus = nameof(MigrationStatus);
    public const string ApplicationCriticality = nameof(ApplicationCriticality);
    public const string WorkloadType = nameof(WorkloadType);
    public const string WaveStatus = nameof(WaveStatus);
    public const string RunbookStatus = nameof(RunbookStatus);
}

public static class IpStatuses
{
    public const string Available = nameof(Available);
    public const string Reserved = nameof(Reserved);
    public const string Allocated = nameof(Allocated);
    public const string Released = nameof(Released);
    public const string AzureReserved = nameof(AzureReserved);
    public const string Excluded = nameof(Excluded);

    public static readonly string[] Active = [Reserved, Allocated];
}

public static class ReadinessStatuses
{
    public const string NotStarted = nameof(NotStarted);
    public const string Complete = nameof(Complete);
    public const string AtRisk = nameof(AtRisk);
    public const string Blocked = nameof(Blocked);
    public const string NotApplicable = nameof(NotApplicable);
}

public static class OverallReadinessStatuses
{
    public const string NotReady = nameof(NotReady);
    public const string AtRisk = nameof(AtRisk);
    public const string ReadyWithConditions = nameof(ReadyWithConditions);
    public const string Ready = nameof(Ready);
    public const string Blocked = nameof(Blocked);
}

public static class DiscoverySourceTypes
{
    public const string AzureMigrateServerReport = nameof(AzureMigrateServerReport);
    public const string AzureMigrateAllInventoryReport = nameof(AzureMigrateAllInventoryReport);

    public static readonly string[] All = [AzureMigrateServerReport, AzureMigrateAllInventoryReport];
}

public static class ImportBatchStatuses
{
    public const string Uploaded = nameof(Uploaded);
    public const string Parsing = nameof(Parsing);
    public const string Validated = nameof(Validated);
    public const string PreviewReady = nameof(PreviewReady);
    public const string Importing = nameof(Importing);
    public const string Completed = nameof(Completed);
    public const string CompletedWithWarnings = nameof(CompletedWithWarnings);
    public const string Failed = nameof(Failed);
    public const string Cancelled = nameof(Cancelled);

    public static readonly string[] Committed = [Completed, CompletedWithWarnings];
}

public static class ImportClassifications
{
    public const string Create = nameof(Create);
    public const string Update = nameof(Update);
    public const string Unchanged = nameof(Unchanged);
    public const string Warning = nameof(Warning);
    public const string Reject = nameof(Reject);

    public static readonly string[] All = [Create, Update, Unchanged, Warning, Reject];
}

public static class ImportValidationStatuses
{
    public const string Valid = nameof(Valid);
    public const string Warning = nameof(Warning);
    public const string Invalid = nameof(Invalid);
}

public static class ValidationSeverities
{
    public const string Error = nameof(Error);
    public const string Warning = nameof(Warning);
    public const string Information = nameof(Information);
}

public static class DiscoveryFreshnessStatuses
{
    public const string Current = nameof(Current);
    public const string Stale = nameof(Stale);
    public const string Unknown = nameof(Unknown);
}

public static class ReadinessCheckTypes
{
    public static readonly string[] All =
    [
        "DiscoveryComplete",
        "ApplicationAssessmentComplete",
        "DependenciesValidated",
        "MigrationDecisionApproved",
        "AzureTargetDefined",
        "IpAllocated",
        "BackupConfirmed",
        "RunbookApproved",
        "RollbackApproved",
        "TechnicalTestingDefined",
        "BusinessTestingDefined"
    ];
}

public static class SeedIds
{
    public static readonly Guid DemoCustomer = Guid.Parse("11111111-1111-1111-1111-111111111111");
    public static readonly Guid DemoProject = Guid.Parse("22222222-2222-2222-2222-222222222222");
}

public sealed class DomainValidationException(string message) : Exception(message);
