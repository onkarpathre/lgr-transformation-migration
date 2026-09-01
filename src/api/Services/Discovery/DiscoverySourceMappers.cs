using System.Text;
using LgrTransformationMigration.Api.Domain;

namespace LgrTransformationMigration.Api.Services.Discovery;

public interface IDiscoverySourceMapper
{
    string SourceType { get; }
    void ValidateHeaders(IReadOnlyList<string> headers);
    DiscoveryServerRecord Map(IReadOnlyDictionary<string, string> row);
}

public sealed class DiscoverySourceMapperResolver(IEnumerable<IDiscoverySourceMapper> mappers)
{
    private readonly IReadOnlyDictionary<string, IDiscoverySourceMapper> bySource = mappers.ToDictionary(x => x.SourceType, StringComparer.OrdinalIgnoreCase);

    public IDiscoverySourceMapper Resolve(string sourceType)
    {
        if (!DiscoverySourceTypes.All.Contains(sourceType, StringComparer.OrdinalIgnoreCase) || !bySource.TryGetValue(sourceType, out var mapper))
            throw new DomainValidationException("Select a supported Azure Migrate discovery source type.");
        return mapper;
    }
}

public static class DiscoveryColumnName
{
    public static string Normalize(string value)
    {
        var result = new StringBuilder(value.Length);
        foreach (var character in value.Trim())
            if (char.IsLetterOrDigit(character)) result.Append(char.ToLowerInvariant(character));
        return result.ToString();
    }
}

public abstract class AzureMigrateMapperBase : IDiscoverySourceMapper
{
    public abstract string SourceType { get; }
    public abstract void ValidateHeaders(IReadOnlyList<string> headers);
    public abstract DiscoveryServerRecord Map(IReadOnlyDictionary<string, string> row);

    protected static Dictionary<string, string> NormalizeRow(IReadOnlyDictionary<string, string> row) =>
        row.ToDictionary(x => DiscoveryColumnName.Normalize(x.Key), x => x.Value, StringComparer.OrdinalIgnoreCase);

    protected static HashSet<string> NormalizeHeaders(IReadOnlyList<string> headers)
    {
        var normalized = headers.Select(DiscoveryColumnName.Normalize).ToArray();
        var duplicate = normalized.GroupBy(x => x).FirstOrDefault(x => x.Count() > 1);
        if (duplicate is not null) throw new DomainValidationException($"The report contains duplicate columns after normalisation: {duplicate.Key}.");
        return normalized.ToHashSet(StringComparer.OrdinalIgnoreCase);
    }

    protected static DiscoveryServerRecord Common(IReadOnlyDictionary<string, string> raw, bool isServerRecord)
    {
        var row = NormalizeRow(raw);
        string? Get(string name) => row.GetValueOrDefault(name) is { } value && !string.IsNullOrWhiteSpace(value) ? value.Trim() : null;
        return new DiscoveryServerRecord
        {
            RawData = raw,
            IsServerRecord = isServerRecord,
            SourceRecordId = Get("id"),
            ParentId = Get("parentid"),
            Hostname = Get("server"),
            Environment = Get("environment"),
            MigrationIntent = Get("migrationintent"),
            OperatingSystem = Get("operatingsystem"),
            IpAddresses = Get("ipv4ipv6"),
            Dependencies = Get("dependencies"),
            SoftwareCount = Get("softwares"),
            DatabaseInstanceCount = Get("dbinstances"),
            WebAppCount = Get("webapps"),
            FileShareCount = Get("fileshares"),
            SecurityRisks = Get("securityrisks"),
            SupportStatus = Get("supportstatus"),
            ApplicationNames = Get("applicationnames"),
            IssueCount = Get("issues"),
            Tags = Get("tags"),
            Host = Get("host"),
            MemoryMb = Get("memorymb"),
            DiskCount = Get("disks"),
            VCores = Get("vcores"),
            AllocatedStorageGb = Get("allocatedstoragegb"),
            NetworkAdapterCount = Get("networkadapters"),
            MacAddress = Get("macaddress"),
            BootType = Get("boottype"),
            OsFamily = Get("osfamily"),
            OsArchitecture = Get("osarchitecture"),
            FirstDiscoveredAt = Get("firstdiscoveredat"),
            LastUpdatedAt = Get("lastupdatedat"),
            Processor = Get("processor"),
            ResourceType = Get("resourcetype") ?? Get("type"),
            PowerStatus = Get("powerstatus"),
            HypervisorType = Get("hypervisortype"),
            DiscoveryMethod = Get("discoverymethod"),
            ConnectedAppliance = Get("connectedappliance"),
            AppArmIdNames = Get("apparmidnames")
        };
    }
}

public sealed class AzureMigrateServerReportMapper : AzureMigrateMapperBase
{
    public override string SourceType => DiscoverySourceTypes.AzureMigrateServerReport;

    public override void ValidateHeaders(IReadOnlyList<string> headers)
    {
        var normalized = NormalizeHeaders(headers);
        if (!normalized.Contains("server")) throw new DomainValidationException("The Azure Migrate Server Report must contain a Server column.");
        if (normalized.Overlaps(["workload", "category", "type"]))
            throw new DomainValidationException("The selected Server Report source conflicts with All Inventory report columns (Workload, Category or Type).");
        if (!normalized.Overlaps(["operatingsystem", "memorymb", "vcores", "resourcetype", "boottype", "networkadapters"]))
            throw new DomainValidationException("The selected file does not contain expected Azure Migrate Server Report technical columns.");
    }

    public override DiscoveryServerRecord Map(IReadOnlyDictionary<string, string> row) => Common(row, true);
}

public sealed class AzureMigrateAllInventoryMapper : AzureMigrateMapperBase
{
    public override string SourceType => DiscoverySourceTypes.AzureMigrateAllInventoryReport;

    public override void ValidateHeaders(IReadOnlyList<string> headers)
    {
        var normalized = NormalizeHeaders(headers);
        if (!normalized.Contains("server")) throw new DomainValidationException("The Azure Migrate All Inventory Report must contain a Server column.");
        if (!normalized.Overlaps(["workload", "category", "type"]))
            throw new DomainValidationException("The selected file does not contain expected All Inventory columns (Workload, Category or Type).");
    }

    public override DiscoveryServerRecord Map(IReadOnlyDictionary<string, string> row)
    {
        var normalized = NormalizeRow(row);
        var markers = new[] { normalized.GetValueOrDefault("workload"), normalized.GetValueOrDefault("category"), normalized.GetValueOrDefault("type") };
        var isServer = markers.Any(value => value is not null &&
            (value.Equals("server", StringComparison.OrdinalIgnoreCase)
             || value.Contains("virtual machine", StringComparison.OrdinalIgnoreCase)
             || value.Contains("physical server", StringComparison.OrdinalIgnoreCase)
             || value.Equals("machine", StringComparison.OrdinalIgnoreCase)));
        return Common(row, isServer);
    }
}
