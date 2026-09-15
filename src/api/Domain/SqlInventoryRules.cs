using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace LgrTransformationMigration.Api.Domain;

public static class SqlInstanceServiceStatuses
{
    public const string Running = nameof(Running);
    public const string Stopped = nameof(Stopped);
    public const string Paused = nameof(Paused);
    public const string Disabled = nameof(Disabled);
    public const string Unknown = nameof(Unknown);

    public static readonly string[] All = [Running, Stopped, Paused, Disabled, Unknown];
}

public static class SqlDatabaseRecoveryModels
{
    public const string Simple = nameof(Simple);
    public const string Full = nameof(Full);
    public const string BulkLogged = nameof(BulkLogged);

    public static readonly string[] All = [Simple, Full, BulkLogged];
}

public static class SqlDatabaseStatuses
{
    public const string Online = nameof(Online);
    public const string Offline = nameof(Offline);
    public const string Restoring = nameof(Restoring);
    public const string Recovering = nameof(Recovering);
    public const string RecoveryPending = nameof(RecoveryPending);
    public const string Suspect = nameof(Suspect);
    public const string Emergency = nameof(Emergency);
    public const string Standby = nameof(Standby);
    public const string Unknown = nameof(Unknown);

    public static readonly string[] All =
        [Online, Offline, Restoring, Recovering, RecoveryPending, Suspect, Emergency, Standby, Unknown];
}

public static class SqlInventoryNormalizer
{
    private static readonly Regex ServiceAccountPattern = new(
        @"^[\p{L}\p{N}][\p{L}\p{N} ._@$\\-]{0,255}$",
        RegexOptions.CultureInvariant | RegexOptions.Compiled);

    public static string NormalizeInstanceName(string value)
    {
        var display = RequiredDisplayValue(value, 128, "Instance name");
        var normalized = display.ToUpperInvariant();
        return normalized is "DEFAULT" or "(DEFAULT)" or "MSSQLSERVER" ? "MSSQLSERVER" : normalized;
    }

    public static string NormalizeDatabaseName(string value) =>
        RequiredDisplayValue(value, 128, "Database name").ToUpperInvariant();

    public static string RequiredDisplayValue(string value, int maximumLength, string fieldName)
    {
        var normalized = (value ?? string.Empty).Trim().Normalize(NormalizationForm.FormC);
        if (normalized.Length == 0)
        {
            throw new DomainValidationException($"{fieldName} is required.");
        }

        if (normalized.Length > maximumLength)
        {
            throw new DomainValidationException($"{fieldName} cannot exceed {maximumLength.ToString(CultureInfo.InvariantCulture)} characters.");
        }

        return normalized;
    }

    public static string NormalizeServiceStatus(string value) =>
        NormalizeControlledValue(value, SqlInstanceServiceStatuses.All, "service status");

    public static string NormalizeRecoveryModel(string value)
    {
        var compact = CompactControlledValue(value);
        return compact switch
        {
            "SIMPLE" => SqlDatabaseRecoveryModels.Simple,
            "FULL" => SqlDatabaseRecoveryModels.Full,
            "BULKLOGGED" => SqlDatabaseRecoveryModels.BulkLogged,
            _ => throw new DomainValidationException("Recovery model must be Simple, Full or BulkLogged.")
        };
    }

    public static string NormalizeDatabaseStatus(string value)
    {
        var compact = CompactControlledValue(value);
        return SqlDatabaseStatuses.All.SingleOrDefault(x =>
                   string.Equals(CompactControlledValue(x), compact, StringComparison.Ordinal))
               ?? throw new DomainValidationException("Database status is not supported.");
    }

    public static string? NormalizeOptionalDisplayValue(string? value, int maximumLength, string fieldName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        return RequiredDisplayValue(value, maximumLength, fieldName);
    }

    public static string? NormalizeServiceAccountName(string? value)
    {
        var normalized = NormalizeOptionalDisplayValue(value, 256, "Service account display name");
        if (normalized is not null && !ServiceAccountPattern.IsMatch(normalized))
        {
            throw new DomainValidationException(
                "Service account display name contains unsupported characters. Enter a display name only, never credentials.");
        }

        return normalized;
    }

    private static string NormalizeControlledValue(string value, IEnumerable<string> allowed, string fieldName)
    {
        var display = RequiredDisplayValue(value, 50, fieldName);
        return allowed.SingleOrDefault(x => string.Equals(x, display, StringComparison.OrdinalIgnoreCase))
               ?? throw new DomainValidationException($"The supplied {fieldName} is not supported.");
    }

    private static string CompactControlledValue(string value) =>
        new(RequiredDisplayValue(value, 50, "Value")
            .Where(char.IsLetterOrDigit)
            .Select(char.ToUpperInvariant)
            .ToArray());
}

public sealed class DomainConflictException(string message) : Exception(message);
public sealed class PreconditionRequiredException(string message) : Exception(message);
public sealed class StaleVersionException : Exception
{
    public StaleVersionException(string message) : base(message)
    {
    }

    public StaleVersionException(string message, Exception innerException) : base(message, innerException)
    {
    }
}
