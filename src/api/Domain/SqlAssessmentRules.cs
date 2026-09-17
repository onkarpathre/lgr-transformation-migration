using System.Text;

namespace LgrTransformationMigration.Api.Domain;

public static class SqlAssessmentStatuses
{
    public const string NotStarted = "NotStarted";
    public const string InProgress = "InProgress";
    public const string Complete = "Complete";
    public const string Blocked = "Blocked";

    public static readonly IReadOnlySet<string> All = new HashSet<string>(StringComparer.Ordinal)
    {
        NotStarted, InProgress, Complete, Blocked
    };
}

public static class SqlReadinessStatuses
{
    public const string NotAssessed = "NotAssessed";
    public const string NotReady = "NotReady";
    public const string AtRisk = "AtRisk";
    public const string ReadyWithConditions = "ReadyWithConditions";
    public const string Ready = "Ready";
    public const string Blocked = "Blocked";

    public static readonly IReadOnlySet<string> All = new HashSet<string>(StringComparer.Ordinal)
    {
        NotAssessed, NotReady, AtRisk, ReadyWithConditions, Ready, Blocked
    };
}

public static class SqlAssessmentTargetPlatforms
{
    public const string AzureSqlDatabase = "AzureSqlDatabase";
    public const string AzureSqlManagedInstance = "AzureSqlManagedInstance";
    public const string SqlServerOnAzureVm = "SqlServerOnAzureVm";
    public const string Retain = "Retain";
    public const string Retire = "Retire";
    public const string Investigate = "Investigate";

    public static readonly IReadOnlySet<string> All = new HashSet<string>(StringComparer.Ordinal)
    {
        AzureSqlDatabase, AzureSqlManagedInstance, SqlServerOnAzureVm, Retain, Retire, Investigate
    };

    public static readonly IReadOnlySet<string> AzureTargets = new HashSet<string>(StringComparer.Ordinal)
    {
        AzureSqlDatabase, AzureSqlManagedInstance, SqlServerOnAzureVm
    };
}

public static class SqlMigrationApproaches
{
    public const string Offline = "Offline";
    public const string Online = "Online";
    public const string ToBeDetermined = "ToBeDetermined";
    public const string NotApplicable = "NotApplicable";

    public static readonly IReadOnlySet<string> All = new HashSet<string>(StringComparer.Ordinal)
    {
        Offline, Online, ToBeDetermined, NotApplicable
    };
}

public sealed record SqlAssessmentValues(
    string AssessmentStatus,
    string ReadinessStatus,
    string? TargetPlatform,
    string? TargetSqlVersion,
    string? MigrationApproach,
    string Blockers,
    string Findings,
    string Notes,
    DateTimeOffset? AssessedAt);

public static class SqlAssessmentRules
{
    public static SqlAssessmentValues Validate(
        string assessmentStatus,
        string readinessStatus,
        string? targetPlatform,
        string? targetSqlVersion,
        string? migrationApproach,
        string? blockers,
        string? findings,
        string? notes,
        DateTimeOffset? assessedAt,
        DateTimeOffset serverNow)
    {
        RequireControlled(assessmentStatus, SqlAssessmentStatuses.All, "AssessmentStatus");
        RequireControlled(readinessStatus, SqlReadinessStatuses.All, "ReadinessStatus");
        targetPlatform = OptionalControlled(targetPlatform, SqlAssessmentTargetPlatforms.All, "TargetPlatform");
        migrationApproach = OptionalControlled(migrationApproach, SqlMigrationApproaches.All, "MigrationApproach");
        targetSqlVersion = Narrative(targetSqlVersion, 100, "TargetSqlVersion", allowNull: true);
        var safeBlockers = Narrative(blockers, 4000, "Blockers", allowNull: false)!;
        var safeFindings = Narrative(findings, 8000, "Findings", allowNull: false)!;
        var safeNotes = Narrative(notes, 4000, "Notes", allowNull: false)!;
        var utcAssessedAt = assessedAt?.ToUniversalTime();

        if (utcAssessedAt > serverNow.ToUniversalTime().AddMinutes(5))
        {
            throw new DomainValidationException("AssessedAt cannot be later than server time plus five minutes.");
        }

        if (assessmentStatus == SqlAssessmentStatuses.NotStarted
            && (readinessStatus != SqlReadinessStatuses.NotAssessed
                || targetPlatform is not null
                || targetSqlVersion is not null
                || migrationApproach is not null
                || utcAssessedAt is not null))
        {
            throw new DomainValidationException("NotStarted requires NotAssessed and no planning or assessed time.");
        }

        if (assessmentStatus == SqlAssessmentStatuses.InProgress
            && readinessStatus == SqlReadinessStatuses.Ready)
        {
            throw new DomainValidationException("InProgress cannot be Ready.");
        }

        if (assessmentStatus == SqlAssessmentStatuses.Blocked
            && (readinessStatus != SqlReadinessStatuses.Blocked || string.IsNullOrWhiteSpace(safeBlockers)))
        {
            throw new DomainValidationException("Blocked requires Blocked readiness and non-blank blockers.");
        }

        if (assessmentStatus == SqlAssessmentStatuses.Complete
            && (utcAssessedAt is null
                || targetPlatform is null
                || readinessStatus == SqlReadinessStatuses.NotAssessed))
        {
            throw new DomainValidationException("Complete requires assessed time, target platform and assessed readiness.");
        }

        if (targetPlatform is not null)
        {
            if (SqlAssessmentTargetPlatforms.AzureTargets.Contains(targetPlatform)
                && migrationApproach is not (SqlMigrationApproaches.Offline or SqlMigrationApproaches.Online or SqlMigrationApproaches.ToBeDetermined))
            {
                throw new DomainValidationException("An Azure target requires Offline, Online or ToBeDetermined approach.");
            }

            if (targetPlatform is SqlAssessmentTargetPlatforms.Retain or SqlAssessmentTargetPlatforms.Retire
                && migrationApproach != SqlMigrationApproaches.NotApplicable)
            {
                throw new DomainValidationException("Retain and Retire require NotApplicable approach.");
            }

            if (targetPlatform == SqlAssessmentTargetPlatforms.Investigate
                && migrationApproach != SqlMigrationApproaches.ToBeDetermined)
            {
                throw new DomainValidationException("Investigate requires ToBeDetermined approach.");
            }
        }
        else if (migrationApproach is not null || targetSqlVersion is not null)
        {
            throw new DomainValidationException("Planning details require a target platform.");
        }

        if (targetPlatform != SqlAssessmentTargetPlatforms.SqlServerOnAzureVm && targetSqlVersion is not null)
        {
            throw new DomainValidationException("TargetSqlVersion is allowed only for SqlServerOnAzureVm.");
        }

        if (readinessStatus == SqlReadinessStatuses.ReadyWithConditions
            && string.IsNullOrWhiteSpace(safeBlockers)
            && string.IsNullOrWhiteSpace(safeNotes))
        {
            throw new DomainValidationException("ReadyWithConditions requires blockers or notes.");
        }

        if (readinessStatus == SqlReadinessStatuses.Ready && !string.IsNullOrWhiteSpace(safeBlockers))
        {
            throw new DomainValidationException("Ready requires blank blockers.");
        }

        return new SqlAssessmentValues(
            assessmentStatus,
            readinessStatus,
            targetPlatform,
            targetSqlVersion,
            migrationApproach,
            safeBlockers,
            safeFindings,
            safeNotes,
            utcAssessedAt);
    }

    private static void RequireControlled(string? value, IReadOnlySet<string> allowed, string field)
    {
        if (value is null || !allowed.Contains(value))
        {
            throw new DomainValidationException($"{field} is not an allowed value.");
        }
    }

    private static string? OptionalControlled(string? value, IReadOnlySet<string> allowed, string field)
    {
        var normalized = string.IsNullOrWhiteSpace(value) ? null : value;
        if (normalized is not null && !allowed.Contains(normalized))
        {
            throw new DomainValidationException($"{field} is not an allowed value.");
        }

        return normalized;
    }

    private static string? Narrative(string? value, int maximumLength, string field, bool allowNull)
    {
        if (value is null)
        {
            if (allowNull)
            {
                return null;
            }

            throw new DomainValidationException($"{field} is required.");
        }

        var normalized = value.Trim().Normalize(NormalizationForm.FormC);
        if (normalized.Length > maximumLength)
        {
            throw new DomainValidationException($"{field} cannot exceed {maximumLength} characters.");
        }

        if (normalized.Any(character => char.IsControl(character) && character is not '\r' and not '\n' and not '\t'))
        {
            throw new DomainValidationException($"{field} contains unsupported control characters.");
        }

        return normalized.Length == 0 && allowNull ? null : normalized;
    }
}
