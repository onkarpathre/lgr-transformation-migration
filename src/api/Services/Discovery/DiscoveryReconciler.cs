using System.Globalization;
using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Domain;

namespace LgrTransformationMigration.Api.Services.Discovery;

public sealed class DiscoveryReconciler
{
    public DiscoveryReconciliationResult Reconcile(ValidatedDiscoveryRecord record, Server? existing)
    {
        if (record.HasErrors) return new DiscoveryReconciliationResult(ImportClassifications.Reject, []);
        if (!record.Source.IsServerRecord) return new DiscoveryReconciliationResult(ImportClassifications.Warning, []);

        var changes = existing is null ? [] : DiscoveryManagedServerFields.BuildChanges(existing, record);
        var classification = existing is null
            ? ImportClassifications.Create
            : changes.Count == 0 ? ImportClassifications.Unchanged : ImportClassifications.Update;
        if (record.HasWarnings) classification = ImportClassifications.Warning;
        return new DiscoveryReconciliationResult(classification, changes);
    }
}

public static class DiscoveryManagedServerFields
{
    public static IReadOnlyList<DiscoveryFieldChangeDto> BuildChanges(Server server, ValidatedDiscoveryRecord record)
    {
        var changes = new List<DiscoveryFieldChangeDto>();
        AddString(changes, "ExternalSourceId", server.ExternalSourceId, record.Source.SourceRecordId);
        AddString(changes, "Environment", server.Environment, record.NormalizedEnvironment);
        AddString(changes, "OperatingSystem", server.OperatingSystem, record.Source.OperatingSystem);
        AddString(changes, "IpAddress", server.IpAddress, record.Source.IpAddresses is null ? null : record.ValidIpAddresses.FirstOrDefault());
        AddInt(changes, "VCores", server.VCores, record.Source.VCores is null ? null : record.VCores);
        AddInt(changes, "MemoryMb", server.MemoryMb, record.Source.MemoryMb is null ? null : record.MemoryMb);
        AddInt(changes, "AllocatedStorageGb", server.AllocatedStorageGb, record.Source.AllocatedStorageGb is null ? null : record.AllocatedStorageGb);
        AddString(changes, "PowerStatus", server.PowerStatus, record.Source.PowerStatus);
        AddString(changes, "OsFamily", server.OsFamily, record.Source.OsFamily);
        AddString(changes, "OsArchitecture", server.OsArchitecture, record.Source.OsArchitecture);
        AddString(changes, "Processor", server.Processor, record.Source.Processor);
        AddString(changes, "HypervisorType", server.HypervisorType, record.Source.HypervisorType);
        AddString(changes, "Host", server.Host, record.Source.Host);
        AddString(changes, "SupportStatus", server.SupportStatus, record.Source.SupportStatus);
        AddString(changes, "DiscoveryMethod", server.DiscoveryMethod, record.Source.DiscoveryMethod);
        AddDate(changes, "FirstDiscoveredAt", server.FirstDiscoveredAt, record.Source.FirstDiscoveredAt is null ? null : record.FirstDiscoveredAt);
        AddDate(changes, "LastDiscoveredAt", server.LastDiscoveredAt, record.Source.LastUpdatedAt is null ? null : record.LastUpdatedAt);
        return changes;
    }

    public static Server CreateServer(Guid customerId, Guid projectId, ValidatedDiscoveryRecord record, Guid batchId, DateTimeOffset now) => new()
    {
        Id = Guid.NewGuid(),
        CustomerId = customerId,
        ProjectId = projectId,
        Hostname = record.NormalizedHostname!,
        Environment = record.NormalizedEnvironment ?? string.Empty,
        OperatingSystem = record.Source.OperatingSystem?.Trim() ?? string.Empty,
        IpAddress = record.ValidIpAddresses.FirstOrDefault() ?? string.Empty,
        VCores = record.VCores,
        MemoryMb = record.MemoryMb,
        AllocatedStorageGb = record.AllocatedStorageGb,
        PowerStatus = record.Source.PowerStatus?.Trim() ?? "Unknown",
        MigrationScope = string.Empty,
        MigrationStrategy = string.Empty,
        MigrationStatus = "Not Started",
        ExternalSourceId = Trim(record.Source.SourceRecordId),
        OsFamily = Trim(record.Source.OsFamily),
        OsArchitecture = Trim(record.Source.OsArchitecture),
        Processor = Trim(record.Source.Processor),
        HypervisorType = Trim(record.Source.HypervisorType),
        Host = Trim(record.Source.Host),
        SupportStatus = Trim(record.Source.SupportStatus),
        DiscoveryMethod = Trim(record.Source.DiscoveryMethod),
        FirstDiscoveredAt = record.FirstDiscoveredAt,
        LastDiscoveredAt = record.LastUpdatedAt,
        LastImportBatchId = batchId,
        LastImportedAt = now,
        CreatedAt = now,
        UpdatedAt = now
    };

    public static void ApplyTechnicalFields(Server server, ValidatedDiscoveryRecord record, Guid batchId, DateTimeOffset now)
    {
        if (record.Source.SourceRecordId is not null) server.ExternalSourceId = Trim(record.Source.SourceRecordId);
        if (record.NormalizedEnvironment is not null) server.Environment = record.NormalizedEnvironment;
        if (record.Source.OperatingSystem is not null) server.OperatingSystem = record.Source.OperatingSystem.Trim();
        if (record.Source.IpAddresses is not null) server.IpAddress = record.ValidIpAddresses.FirstOrDefault() ?? server.IpAddress;
        if (record.Source.VCores is not null) server.VCores = record.VCores;
        if (record.Source.MemoryMb is not null) server.MemoryMb = record.MemoryMb;
        if (record.Source.AllocatedStorageGb is not null) server.AllocatedStorageGb = record.AllocatedStorageGb;
        if (record.Source.PowerStatus is not null) server.PowerStatus = record.Source.PowerStatus.Trim();
        if (record.Source.OsFamily is not null) server.OsFamily = Trim(record.Source.OsFamily);
        if (record.Source.OsArchitecture is not null) server.OsArchitecture = Trim(record.Source.OsArchitecture);
        if (record.Source.Processor is not null) server.Processor = Trim(record.Source.Processor);
        if (record.Source.HypervisorType is not null) server.HypervisorType = Trim(record.Source.HypervisorType);
        if (record.Source.Host is not null) server.Host = Trim(record.Source.Host);
        if (record.Source.SupportStatus is not null) server.SupportStatus = Trim(record.Source.SupportStatus);
        if (record.Source.DiscoveryMethod is not null) server.DiscoveryMethod = Trim(record.Source.DiscoveryMethod);
        if (record.Source.FirstDiscoveredAt is not null) server.FirstDiscoveredAt = record.FirstDiscoveredAt;
        if (record.Source.LastUpdatedAt is not null) server.LastDiscoveredAt = record.LastUpdatedAt;
        server.LastImportBatchId = batchId;
        server.LastImportedAt = now;
        server.UpdatedAt = now;
    }

    public static ServerDiscoverySnapshot CreateSnapshot(
        Guid customerId, Guid projectId, Guid serverId, Guid batchId,
        ValidatedDiscoveryRecord record, DateTimeOffset now) => new()
    {
        Id = Guid.NewGuid(), CustomerId = customerId, ProjectId = projectId, ServerId = serverId, ImportBatchId = batchId,
        ExternalSourceId = Trim(record.Source.SourceRecordId), Hostname = record.Source.Hostname?.Trim() ?? record.NormalizedHostname ?? string.Empty,
        Environment = record.NormalizedEnvironment, MigrationIntent = Trim(record.Source.MigrationIntent),
        IpAddresses = record.ValidIpAddresses.Count == 0 ? Trim(record.Source.IpAddresses) : string.Join(", ", record.ValidIpAddresses),
        OperatingSystem = Trim(record.Source.OperatingSystem), Dependencies = Trim(record.Source.Dependencies),
        SoftwareCount = record.SoftwareCount, DatabaseInstanceCount = record.DatabaseInstanceCount,
        WebAppCount = record.WebAppCount, FileShareCount = record.FileShareCount,
        SecurityRisks = Trim(record.Source.SecurityRisks), SupportStatus = Trim(record.Source.SupportStatus),
        ApplicationNames = Trim(record.Source.ApplicationNames), IssueCount = record.IssueCount, Tags = Trim(record.Source.Tags),
        Host = Trim(record.Source.Host), MemoryMb = record.MemoryMb, DiskCount = record.DiskCount, VCores = record.VCores,
        AllocatedStorageGb = record.AllocatedStorageGb, NetworkAdapterCount = record.NetworkAdapterCount,
        MacAddress = Trim(record.Source.MacAddress), BootType = Trim(record.Source.BootType), OsFamily = Trim(record.Source.OsFamily),
        OsArchitecture = Trim(record.Source.OsArchitecture), Processor = Trim(record.Source.Processor), ResourceType = Trim(record.Source.ResourceType),
        PowerStatus = Trim(record.Source.PowerStatus), HypervisorType = Trim(record.Source.HypervisorType),
        DiscoveryMethod = Trim(record.Source.DiscoveryMethod), ConnectedAppliance = Trim(record.Source.ConnectedAppliance),
        FirstDiscoveredAt = record.FirstDiscoveredAt, LastUpdatedAt = record.LastUpdatedAt, ImportedAt = now
    };

    private static void AddString(ICollection<DiscoveryFieldChangeDto> changes, string field, string? oldValue, string? newValue)
    {
        if (newValue is null) return;
        var normalizedNew = newValue.Trim();
        if (!string.Equals(oldValue?.Trim() ?? string.Empty, normalizedNew, StringComparison.OrdinalIgnoreCase))
            changes.Add(new DiscoveryFieldChangeDto(field, oldValue, normalizedNew));
    }

    private static void AddInt(ICollection<DiscoveryFieldChangeDto> changes, string field, int? oldValue, int? newValue)
    {
        if (newValue.HasValue && oldValue != newValue)
            changes.Add(new DiscoveryFieldChangeDto(field, oldValue?.ToString(CultureInfo.InvariantCulture), newValue.Value.ToString(CultureInfo.InvariantCulture)));
    }

    private static void AddDate(ICollection<DiscoveryFieldChangeDto> changes, string field, DateTimeOffset? oldValue, DateTimeOffset? newValue)
    {
        if (newValue.HasValue && oldValue?.ToUniversalTime() != newValue.Value.ToUniversalTime())
            changes.Add(new DiscoveryFieldChangeDto(field, oldValue?.ToUniversalTime().ToString("O"), newValue.Value.ToUniversalTime().ToString("O")));
    }

    private static string? Trim(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
