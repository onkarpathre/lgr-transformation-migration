using System.Globalization;
using System.Net;
using System.Text.RegularExpressions;
using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Domain;

namespace LgrTransformationMigration.Api.Services.Discovery;

public sealed class DiscoveryRecordValidator
{
    private static readonly IReadOnlyDictionary<string, string> EnvironmentMappings =
        new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            ["Production"] = "Prod",
            ["PROD"] = "Prod",
            ["Prod"] = "Prod",
            ["Development"] = "Dev",
            ["DEV"] = "Dev",
            ["Dev"] = "Dev",
            ["User Acceptance Testing"] = "UAT",
            ["UAT"] = "UAT"
        };

    public ValidatedDiscoveryRecord Validate(DiscoveryServerRecord source)
    {
        var messages = new List<DiscoveryValidationMessageDto>();
        string? hostname = null;
        if (source.IsServerRecord)
        {
            if (string.IsNullOrWhiteSpace(source.Hostname))
                messages.Add(Error("Server", "Hostname is required for server reconciliation."));
            else
                hostname = source.Hostname.Trim().ToUpperInvariant();
        }
        else
        {
            hostname = string.IsNullOrWhiteSpace(source.Hostname) ? null : source.Hostname.Trim().ToUpperInvariant();
            messages.Add(Warning("Type", "This All Inventory row is staged for source tracking but is not a canonical server row in Phase 2."));
        }

        var environment = NormalizeEnvironment(source.Environment, messages);
        var ips = ParseIpAddresses(source.IpAddresses, messages);
        return new ValidatedDiscoveryRecord(
            source,
            hostname,
            environment,
            ips,
            ParseInteger(source.SoftwareCount, "Softwares(#)", messages),
            ParseInteger(source.DatabaseInstanceCount, "DB instances(#)", messages),
            ParseInteger(source.WebAppCount, "Webapps(#)", messages),
            ParseInteger(source.FileShareCount, "Fileshares(#)", messages),
            ParseInteger(source.IssueCount, "Issues(#)", messages),
            ParseInteger(source.MemoryMb, "Memory (MB)", messages),
            ParseInteger(source.DiskCount, "Disks(#)", messages),
            ParseInteger(source.VCores, "vCores(#)", messages),
            ParseInteger(source.AllocatedStorageGb, "Allocated storage (GB)", messages),
            ParseInteger(source.NetworkAdapterCount, "Network adapters(#)", messages),
            ParseDate(source.FirstDiscoveredAt, "First discovered at", messages),
            ParseDate(source.LastUpdatedAt, "Last updated at", messages),
            messages);
    }

    private static string? NormalizeEnvironment(string? value, ICollection<DiscoveryValidationMessageDto> messages)
    {
        if (string.IsNullOrWhiteSpace(value)) return null;
        var trimmed = value.Trim();
        if (EnvironmentMappings.TryGetValue(trimmed, out var normalized)) return normalized;
        messages.Add(Warning("Environment", $"Environment '{trimmed}' is not a known mapping and will be preserved."));
        return trimmed;
    }

    private static int? ParseInteger(string? value, string field, ICollection<DiscoveryValidationMessageDto> messages)
    {
        if (string.IsNullOrWhiteSpace(value)) return null;
        if (decimal.TryParse(value.Trim(), NumberStyles.Number, CultureInfo.InvariantCulture, out var parsed)
            && parsed >= 0 && parsed <= int.MaxValue && decimal.Truncate(parsed) == parsed)
            return decimal.ToInt32(parsed);

        messages.Add(Error(field, $"'{value.Trim()}' is not a valid non-negative whole number."));
        return null;
    }

    private static DateTimeOffset? ParseDate(string? value, string field, ICollection<DiscoveryValidationMessageDto> messages)
    {
        if (string.IsNullOrWhiteSpace(value)) return null;
        var styles = DateTimeStyles.AllowWhiteSpaces | DateTimeStyles.AssumeUniversal;
        if (DateTimeOffset.TryParse(value.Trim(), CultureInfo.InvariantCulture, styles, out var parsed)
            || DateTimeOffset.TryParse(value.Trim(), CultureInfo.GetCultureInfo("en-GB"), styles, out parsed))
            return parsed.ToUniversalTime();

        messages.Add(Error(field, $"'{value.Trim()}' is not a valid date/time."));
        return null;
    }

    private static IReadOnlyList<string> ParseIpAddresses(string? value, ICollection<DiscoveryValidationMessageDto> messages)
    {
        if (string.IsNullOrWhiteSpace(value)) return [];
        var valid = new List<string>();
        foreach (var candidate in Regex.Split(value.Trim(), "[,;|\\s]+", RegexOptions.CultureInvariant).Where(x => x.Length > 0))
        {
            if (IPAddress.TryParse(candidate, out var address))
                valid.Add(address.ToString());
            else
                messages.Add(Error("IPv4/IPv6", $"'{candidate}' is not a valid IPv4 or IPv6 address."));
        }
        return valid.Distinct(StringComparer.OrdinalIgnoreCase).ToArray();
    }

    private static DiscoveryValidationMessageDto Error(string field, string message) => new(ValidationSeverities.Error, field, message);
    private static DiscoveryValidationMessageDto Warning(string field, string message) => new(ValidationSeverities.Warning, field, message);
}
