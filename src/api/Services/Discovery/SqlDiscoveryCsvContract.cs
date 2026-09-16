using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Domain;

namespace LgrTransformationMigration.Api.Services.Discovery;

public enum SqlDiscoveryRowKind
{
    Instance,
    Database
}

public sealed record ValidatedSqlDiscoveryRow(
    int RowNumber,
    SqlDiscoveryRowKind Kind,
    IReadOnlyDictionary<string, string> RawData,
    string? Server,
    string? NormalizedHostname,
    string? InstanceName,
    string? NormalizedInstanceName,
    string? DatabaseName,
    string? NormalizedDatabaseName,
    string? SqlVersion,
    string? Edition,
    int? Port,
    bool PortSupplied,
    string? ServiceStatus,
    string? DiscoverySource,
    DateTimeOffset? LastDiscoveredAt,
    bool LastDiscoveredAtSupplied,
    long? SizeMb,
    int? CompatibilityLevel,
    string? RecoveryModel,
    string? Collation,
    bool CollationSupplied,
    string? DatabaseStatus,
    IReadOnlyList<DiscoveryValidationMessageDto> Messages)
{
    public bool HasErrors => Messages.Any(message => message.Severity == ValidationSeverities.Error);
    public bool HasWarnings => Messages.Any(message => message.Severity == ValidationSeverities.Warning);

    public string? BusinessKey => Kind == SqlDiscoveryRowKind.Instance
        ? NormalizedHostname is null || NormalizedInstanceName is null
            ? null
            : $"{NormalizedHostname}\u001f{NormalizedInstanceName}"
        : NormalizedHostname is null || NormalizedInstanceName is null || NormalizedDatabaseName is null
            ? null
            : $"{NormalizedHostname}\u001f{NormalizedInstanceName}\u001f{NormalizedDatabaseName}";
}

public sealed class SqlDiscoveryCsvContract
{
    private static readonly string[] InstanceHeaders =
    [
        "Server", "Instance Name", "SQL Version", "Edition", "Port", "Service Status",
        "Discovery Source", "Last Discovered At"
    ];

    private static readonly string[] DatabaseHeaders =
    [
        "Server", "Instance Name", "Database Name", "Size MB", "Compatibility Level",
        "Recovery Model", "Collation", "Status"
    ];

    private static readonly Regex ExplicitOffset = new(
        "(?:Z|[+-][0-9]{2}:[0-9]{2})$",
        RegexOptions.CultureInvariant | RegexOptions.IgnoreCase | RegexOptions.Compiled);

    private static readonly string[] CredentialHeaderMarkers =
        ["password", "secret", "credential", "token", "connectionstring", "serviceaccount"];

    public IReadOnlyList<string> ValidateHeaders(string sourceType, IReadOnlyList<string> headers)
    {
        var required = RequiredHeaders(sourceType);
        var normalized = headers.Select(DiscoveryColumnName.Normalize).ToArray();
        var normalizedRequired = required.Select(DiscoveryColumnName.Normalize).ToHashSet(StringComparer.OrdinalIgnoreCase);
        var missing = normalizedRequired.Except(normalized, StringComparer.OrdinalIgnoreCase).ToArray();
        if (missing.Length > 0)
        {
            throw new UnsupportedSourceContractException(
                $"The {sourceType} file is missing one or more required headers.");
        }

        return headers.Where(header => !normalizedRequired.Contains(DiscoveryColumnName.Normalize(header))).ToArray();
    }

    public ValidatedSqlDiscoveryRow Validate(
        string sourceType,
        CsvDataRow row,
        IReadOnlyList<string> unknownHeaders,
        bool repeatFileHash)
    {
        var values = row.Values.ToDictionary(
            pair => DiscoveryColumnName.Normalize(pair.Key),
            pair => pair.Value,
            StringComparer.OrdinalIgnoreCase);
        var messages = new List<DiscoveryValidationMessageDto>();
        InspectUnsafeSource(row.Values, messages);
        if (unknownHeaders.Count > 0)
        {
            messages.Add(Warning("Headers", "The file contains unsupported extra columns retained only as staged source evidence."));
        }

        if (repeatFileHash)
        {
            messages.Add(Warning("File", "The same file content was uploaded previously in this project."));
        }

        return sourceType.Equals(DiscoverySourceTypes.SqlInstanceCsvV1, StringComparison.OrdinalIgnoreCase)
            ? ValidateInstance(row, values, messages)
            : sourceType.Equals(DiscoverySourceTypes.SqlDatabaseCsvV1, StringComparison.OrdinalIgnoreCase)
                ? ValidateDatabase(row, values, messages)
                : throw new UnsupportedSourceContractException("The SQL discovery source contract is not supported.");
    }

    private static ValidatedSqlDiscoveryRow ValidateInstance(
        CsvDataRow row,
        IReadOnlyDictionary<string, string> values,
        List<DiscoveryValidationMessageDto> messages)
    {
        var server = Required(values, "server", 253, "Server", messages);
        var instanceName = Required(values, "instancename", 128, "Instance Name", messages);
        if ((server?.Contains('\\') ?? false) || (instanceName?.Contains('\\') ?? false))
        {
            messages.Add(Error("Instance Name", "Combined server and instance values are not supported."));
        }

        var sqlVersion = Required(values, "sqlversion", 100, "SQL Version", messages);
        var edition = Required(values, "edition", 100, "Edition", messages);
        var discoverySource = Required(values, "discoverysource", 100, "Discovery Source", messages);
        var portText = Get(values, "port");
        int? port = null;
        if (portText is not null
            && (!int.TryParse(portText, NumberStyles.None, CultureInfo.InvariantCulture, out var parsedPort)
                || parsedPort is < 1 or > 65535))
        {
            messages.Add(Error("Port", "Port must be a whole number between 1 and 65535."));
        }
        else if (portText is not null)
        {
            port = int.Parse(portText, NumberStyles.None, CultureInfo.InvariantCulture);
        }

        var status = NormalizeInstanceStatus(Get(values, "servicestatus"), messages);
        var lastDiscoveredText = Get(values, "lastdiscoveredat");
        DateTimeOffset? lastDiscoveredAt = null;
        if (lastDiscoveredText is not null
            && (!ExplicitOffset.IsMatch(lastDiscoveredText)
                || !DateTimeOffset.TryParse(
                    lastDiscoveredText,
                    CultureInfo.InvariantCulture,
                    DateTimeStyles.AllowWhiteSpaces | DateTimeStyles.RoundtripKind,
                    out var parsed)))
        {
            messages.Add(Error("Last Discovered At", "Last Discovered At must be ISO-8601 with an explicit offset."));
        }
        else if (lastDiscoveredText is not null)
        {
            lastDiscoveredAt = DateTimeOffset.Parse(
                lastDiscoveredText,
                CultureInfo.InvariantCulture,
                DateTimeStyles.AllowWhiteSpaces | DateTimeStyles.RoundtripKind).ToUniversalTime();
        }

        return new ValidatedSqlDiscoveryRow(
            row.RowNumber,
            SqlDiscoveryRowKind.Instance,
            row.Values,
            server,
            NormalizeHostname(server),
            instanceName,
            NormalizeInstanceName(instanceName),
            null,
            null,
            sqlVersion,
            edition,
            port,
            portText is not null,
            status,
            discoverySource,
            lastDiscoveredAt,
            lastDiscoveredText is not null,
            null,
            null,
            null,
            null,
            false,
            null,
            messages);
    }

    private static ValidatedSqlDiscoveryRow ValidateDatabase(
        CsvDataRow row,
        IReadOnlyDictionary<string, string> values,
        List<DiscoveryValidationMessageDto> messages)
    {
        var server = Required(values, "server", 253, "Server", messages);
        var instanceName = Required(values, "instancename", 128, "Instance Name", messages);
        var databaseName = Required(values, "databasename", 128, "Database Name", messages);
        if ((server?.Contains('\\') ?? false) || (instanceName?.Contains('\\') ?? false))
        {
            messages.Add(Error("Instance Name", "Combined server and instance values are not supported."));
        }

        long? sizeMb = null;
        var sizeText = Get(values, "sizemb");
        if (sizeText is null
            || !long.TryParse(sizeText, NumberStyles.None, CultureInfo.InvariantCulture, out var parsedSize)
            || parsedSize < 0)
        {
            messages.Add(Error("Size MB", "Size MB must be a non-negative whole number within Int64."));
        }
        else
        {
            sizeMb = parsedSize;
        }

        int? compatibilityLevel = null;
        var compatibilityText = Get(values, "compatibilitylevel");
        if (compatibilityText is null
            || !int.TryParse(compatibilityText, NumberStyles.None, CultureInfo.InvariantCulture, out var parsedCompatibility)
            || parsedCompatibility is < 80 or > 200)
        {
            messages.Add(Error("Compatibility Level", "Compatibility Level must be a whole number between 80 and 200."));
        }
        else
        {
            compatibilityLevel = parsedCompatibility;
        }

        var recoveryModel = NormalizeRecoveryModel(Get(values, "recoverymodel"), messages);
        var collation = Optional(values, "collation", 128, "Collation", messages);
        var status = NormalizeDatabaseStatus(Get(values, "status"), messages);

        return new ValidatedSqlDiscoveryRow(
            row.RowNumber,
            SqlDiscoveryRowKind.Database,
            row.Values,
            server,
            NormalizeHostname(server),
            instanceName,
            NormalizeInstanceName(instanceName),
            databaseName,
            NormalizeDatabaseName(databaseName),
            null,
            null,
            null,
            false,
            null,
            null,
            null,
            false,
            sizeMb,
            compatibilityLevel,
            recoveryModel,
            collation,
            Get(values, "collation") is not null,
            status,
            messages);
    }

    private static IReadOnlyList<string> RequiredHeaders(string sourceType) =>
        sourceType.Equals(DiscoverySourceTypes.SqlInstanceCsvV1, StringComparison.OrdinalIgnoreCase)
            ? InstanceHeaders
            : sourceType.Equals(DiscoverySourceTypes.SqlDatabaseCsvV1, StringComparison.OrdinalIgnoreCase)
                ? DatabaseHeaders
                : throw new UnsupportedSourceContractException("The SQL discovery source contract is not supported.");

    private static string? Required(
        IReadOnlyDictionary<string, string> values,
        string key,
        int maximumLength,
        string field,
        ICollection<DiscoveryValidationMessageDto> messages)
    {
        var value = Get(values, key);
        if (value is null)
        {
            messages.Add(Error(field, $"{field} is required."));
            return null;
        }

        if (value.Length > maximumLength)
        {
            messages.Add(Error(field, $"{field} exceeds its maximum length."));
            return null;
        }

        return value.Normalize(NormalizationForm.FormC);
    }

    private static string? Optional(
        IReadOnlyDictionary<string, string> values,
        string key,
        int maximumLength,
        string field,
        ICollection<DiscoveryValidationMessageDto> messages)
    {
        var value = Get(values, key);
        if (value is null)
        {
            return null;
        }

        if (value.Length > maximumLength)
        {
            messages.Add(Error(field, $"{field} exceeds its maximum length."));
            return null;
        }

        return value.Normalize(NormalizationForm.FormC);
    }

    private static string? Get(IReadOnlyDictionary<string, string> values, string key) =>
        values.GetValueOrDefault(key) is { } value && !string.IsNullOrWhiteSpace(value)
            ? value.Trim().Normalize(NormalizationForm.FormC)
            : null;

    private static string? NormalizeHostname(string? value) => value?.Trim().Normalize(NormalizationForm.FormC).ToUpperInvariant();

    private static string? NormalizeInstanceName(string? value)
    {
        if (value is null)
        {
            return null;
        }

        var normalized = value.ToUpperInvariant();
        return normalized is "DEFAULT" or "(DEFAULT)" or "MSSQLSERVER" ? "MSSQLSERVER" : normalized;
    }

    private static string? NormalizeDatabaseName(string? value) => value?.ToUpperInvariant();

    private static string? NormalizeInstanceStatus(
        string? value,
        ICollection<DiscoveryValidationMessageDto> messages)
    {
        if (value is null)
        {
            messages.Add(Error("Service Status", "Service Status is required."));
            return null;
        }

        var compact = Compact(value);
        var status = compact switch
        {
            "RUNNING" or "STARTED" or "ONLINE" => SqlInstanceServiceStatuses.Running,
            "STOPPED" or "OFFLINE" => SqlInstanceServiceStatuses.Stopped,
            "PAUSED" => SqlInstanceServiceStatuses.Paused,
            "DISABLED" => SqlInstanceServiceStatuses.Disabled,
            "UNKNOWN" => SqlInstanceServiceStatuses.Unknown,
            _ => SqlInstanceServiceStatuses.Unknown
        };
        if (compact is not ("RUNNING" or "STARTED" or "ONLINE" or "STOPPED" or "OFFLINE" or "PAUSED" or "DISABLED" or "UNKNOWN"))
        {
            messages.Add(Warning("Service Status", "The unrecognised service status was normalised to Unknown."));
        }

        return status;
    }

    private static string? NormalizeRecoveryModel(
        string? value,
        ICollection<DiscoveryValidationMessageDto> messages)
    {
        if (value is null)
        {
            messages.Add(Error("Recovery Model", "Recovery Model is required."));
            return null;
        }

        var result = Compact(value) switch
        {
            "SIMPLE" => SqlDatabaseRecoveryModels.Simple,
            "FULL" => SqlDatabaseRecoveryModels.Full,
            "BULKLOGGED" => SqlDatabaseRecoveryModels.BulkLogged,
            _ => null
        };
        if (result is null)
        {
            messages.Add(Error("Recovery Model", "Recovery Model must be Simple, Full or BulkLogged."));
        }

        return result;
    }

    private static string? NormalizeDatabaseStatus(
        string? value,
        ICollection<DiscoveryValidationMessageDto> messages)
    {
        if (value is null)
        {
            messages.Add(Error("Status", "Status is required."));
            return null;
        }

        var compact = Compact(value);
        var result = SqlDatabaseStatuses.All.SingleOrDefault(
            status => Compact(status) == compact);
        if (result is null)
        {
            messages.Add(Warning("Status", "The unrecognised database status was normalised to Unknown."));
            return SqlDatabaseStatuses.Unknown;
        }

        return result;
    }

    private static string Compact(string value) =>
        new(value.Where(char.IsLetterOrDigit).Select(char.ToUpperInvariant).ToArray());

    private static void InspectUnsafeSource(
        IReadOnlyDictionary<string, string> values,
        ICollection<DiscoveryValidationMessageDto> messages)
    {
        foreach (var pair in values)
        {
            var normalizedHeader = DiscoveryColumnName.Normalize(pair.Key);
            if (pair.Value.Length > 0
                && CredentialHeaderMarkers.Any(marker => normalizedHeader.Contains(marker, StringComparison.OrdinalIgnoreCase)))
            {
                messages.Add(Error("Source", "Credential-like source data is not permitted."));
                continue;
            }

            var leading = pair.Value.TrimStart(' ');
            if (leading.StartsWith('=') || leading.StartsWith('+') || leading.StartsWith('-')
                || leading.StartsWith('@') || leading.StartsWith('\t') || leading.StartsWith('\r'))
            {
                messages.Add(Error(pair.Key, "Formula-like source content is not permitted."));
            }

            if (pair.Value.Any(character => char.IsControl(character) && character is not ('\r' or '\n')))
            {
                messages.Add(Error(pair.Key, "The source value contains unsupported control characters."));
            }
        }
    }

    private static DiscoveryValidationMessageDto Error(string field, string message) =>
        new(ValidationSeverities.Error, field, message);

    private static DiscoveryValidationMessageDto Warning(string field, string message) =>
        new(ValidationSeverities.Warning, field, message);
}
