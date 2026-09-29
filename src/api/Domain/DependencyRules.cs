using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace LgrTransformationMigration.Api.Domain;

public static class DependencyAssetTypes
{
    public const string Application = nameof(Application);
    public const string Server = nameof(Server);
    public const string SqlInstance = nameof(SqlInstance);
    public const string SqlDatabase = nameof(SqlDatabase);
    public const string DependencyReference = nameof(DependencyReference);

    public static readonly IReadOnlySet<string> Canonical = new HashSet<string>(
        [Application, Server, SqlInstance, SqlDatabase], StringComparer.Ordinal);
}

public static class DependencyReferenceTypes
{
    public const string FileShare = nameof(FileShare);
    public const string Api = nameof(Api);
    public const string ExternalSystem = nameof(ExternalSystem);
    public static readonly IReadOnlySet<string> All = new HashSet<string>(
        [FileShare, Api, ExternalSystem], StringComparer.Ordinal);
}

public static class DependencyResolutionStatuses
{
    public const string Unresolved = nameof(Unresolved);
    public const string Resolved = nameof(Resolved);
    public static readonly IReadOnlySet<string> All = new HashSet<string>(
        [Unresolved, Resolved], StringComparer.Ordinal);
}

public static class DependencyCriticalities
{
    public const string Mandatory = nameof(Mandatory);
    public const string Advisory = nameof(Advisory);
    public static readonly IReadOnlySet<string> All = new HashSet<string>(
        [Mandatory, Advisory], StringComparer.Ordinal);
}

public static class DependencyConfirmationStatuses
{
    public const string Unconfirmed = nameof(Unconfirmed);
    public const string Confirmed = nameof(Confirmed);
    public static readonly IReadOnlySet<string> All = new HashSet<string>(
        [Unconfirmed, Confirmed], StringComparer.Ordinal);
}

public static class DependencyTypes
{
    public const string Service = nameof(Service);
    public const string DataRead = nameof(DataRead);
    public const string DataWrite = nameof(DataWrite);
    public const string ApiCall = nameof(ApiCall);
    public const string FileTransfer = nameof(FileTransfer);
    public const string Authentication = nameof(Authentication);
    public const string NetworkConnectivity = nameof(NetworkConnectivity);
    public const string OperationalSequence = nameof(OperationalSequence);

    public static readonly IReadOnlySet<string> All = new HashSet<string>(
        [Service, DataRead, DataWrite, ApiCall, FileTransfer, Authentication, NetworkConnectivity, OperationalSequence],
        StringComparer.Ordinal);

    public static bool IsAllowed(string dependencyType, string sourceType, string targetAssetType, string? targetReferenceType)
    {
        if (!All.Contains(dependencyType) || !DependencyAssetTypes.Canonical.Contains(sourceType))
        {
            return false;
        }

        var targetType = targetAssetType == DependencyAssetTypes.DependencyReference
            ? targetReferenceType
            : targetAssetType;
        if (targetType is null)
        {
            return false;
        }

        return dependencyType switch
        {
            Service => DependencyAssetTypes.Canonical.Contains(targetType)
                       || targetType == DependencyReferenceTypes.ExternalSystem,
            DataRead or DataWrite => targetType is DependencyAssetTypes.SqlInstance
                or DependencyAssetTypes.SqlDatabase
                or DependencyReferenceTypes.FileShare
                or DependencyReferenceTypes.Api
                or DependencyReferenceTypes.ExternalSystem,
            ApiCall => sourceType is DependencyAssetTypes.Application or DependencyAssetTypes.Server
                       && targetType is DependencyAssetTypes.Application
                           or DependencyReferenceTypes.Api
                           or DependencyReferenceTypes.ExternalSystem,
            FileTransfer => sourceType is DependencyAssetTypes.Application
                or DependencyAssetTypes.Server
                or DependencyAssetTypes.SqlInstance
                && targetType is DependencyAssetTypes.Server
                    or DependencyReferenceTypes.FileShare
                    or DependencyReferenceTypes.ExternalSystem,
            Authentication => sourceType is DependencyAssetTypes.Application
                or DependencyAssetTypes.Server
                or DependencyAssetTypes.SqlInstance
                && targetType is DependencyAssetTypes.Application
                    or DependencyAssetTypes.Server
                    or DependencyReferenceTypes.Api
                    or DependencyReferenceTypes.ExternalSystem,
            NetworkConnectivity => DependencyAssetTypes.Canonical.Contains(targetType)
                                   || DependencyReferenceTypes.All.Contains(targetType),
            OperationalSequence => DependencyAssetTypes.Canonical.Contains(targetType),
            _ => false
        };
    }
}

public static partial class DependencyText
{
    public static string Required(string? value, int maxLength, string field)
    {
        var normalized = Optional(value, maxLength, field);
        return normalized ?? throw new DomainValidationException($"{field} is required.");
    }

    public static string? Optional(string? value, int maxLength, string field)
    {
        if (value is null)
        {
            return null;
        }

        var normalized = value.Normalize(NormalizationForm.FormC).Trim();
        if (normalized.Length == 0)
        {
            return null;
        }

        if (new StringInfo(normalized).LengthInTextElements > maxLength)
        {
            throw new DomainValidationException($"{field} must not exceed {maxLength} characters.");
        }

        if (normalized.Any(character => char.IsControl(character) && character is not ('\r' or '\n' or '\t')))
        {
            throw new DomainValidationException($"{field} contains unsupported control characters.");
        }

        if (HtmlPattern().IsMatch(normalized)
            || UrlPattern().IsMatch(normalized)
            || PrivateKeyPattern().IsMatch(normalized)
            || ConnectionSecretPattern().IsMatch(normalized)
            || BearerPattern().IsMatch(normalized)
            || JwtPattern().IsMatch(normalized)
            || SasPattern().IsMatch(normalized))
        {
            throw new DomainValidationException($"{field} contains prohibited markup, URL or secret-like content.");
        }

        return normalized;
    }

    public static string NormalizedName(string value) => value.Normalize(NormalizationForm.FormC).ToUpperInvariant();

    [GeneratedRegex("<[^>]+>", RegexOptions.CultureInvariant)]
    private static partial Regex HtmlPattern();

    [GeneratedRegex("https?://", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant)]
    private static partial Regex UrlPattern();

    [GeneratedRegex("-----BEGIN [A-Z ]*PRIVATE KEY-----", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant)]
    private static partial Regex PrivateKeyPattern();

    [GeneratedRegex("(?:Password|AccountKey)\\s*=", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant)]
    private static partial Regex ConnectionSecretPattern();

    [GeneratedRegex("\\bBearer\\s+[A-Za-z0-9._~+/=-]{12,}", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant)]
    private static partial Regex BearerPattern();

    [GeneratedRegex("\\beyJ[A-Za-z0-9_-]{8,}\\.[A-Za-z0-9_-]{8,}\\.[A-Za-z0-9_-]{8,}\\b", RegexOptions.CultureInvariant)]
    private static partial Regex JwtPattern();

    [GeneratedRegex("[?&](?:sig|se|sp|sv|spr|srt|ss)=", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant)]
    private static partial Regex SasPattern();
}

public static class DependencyEndpointKeys
{
    public static string Create(string type, Guid id)
    {
        var prefix = type switch
        {
            DependencyAssetTypes.Application => "A:",
            DependencyAssetTypes.Server => "S:",
            DependencyAssetTypes.SqlInstance => "I:",
            DependencyAssetTypes.SqlDatabase => "D:",
            DependencyAssetTypes.DependencyReference => "R:",
            _ => throw new DomainValidationException("Endpoint type is not supported.")
        };
        return prefix + id.ToString("N");
    }
}

public static class DependencyPolicyDefaults
{
    public const int Version = 1;
    public const string Name = "Default dependency validation policy";

    public static readonly (string Code, string Mandatory, string Advisory)[] Rules =
    [
        ("UnresolvedReference", "Blocker", "Warning"),
        ("UnconfirmedDependency", "Blocker", "Warning"),
        ("SelfDependency", "Blocker", "Blocker"),
        ("DuplicateDependency", "Blocker", "Blocker"),
        ("DirectedCycle", "Blocker", "Warning"),
        ("ProviderUnassigned", "Blocker", "Warning"),
        ("MultipleWaveAssignments", "Blocker", "Blocker"),
        ("ProviderLaterWave", "Blocker", "Warning"),
        ("WaveOrderUnknown", "Blocker", "Warning"),
        ("ExternalPlanningReview", "Warning", "Information")
    ];
}
