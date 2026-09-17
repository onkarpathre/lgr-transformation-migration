using LgrTransformationMigration.Api.Domain;

namespace LgrTransformationMigration.Api.UnitTests;

public sealed class SqlAssessmentRulesTests
{
    private static readonly DateTimeOffset Now = new(2026, 9, 17, 12, 0, 0, TimeSpan.Zero);

    [Theory]
    [InlineData(SqlAssessmentStatuses.NotStarted, SqlReadinessStatuses.NotAssessed)]
    [InlineData(SqlAssessmentStatuses.InProgress, SqlReadinessStatuses.NotReady)]
    [InlineData(SqlAssessmentStatuses.InProgress, SqlReadinessStatuses.AtRisk)]
    [InlineData(SqlAssessmentStatuses.Complete, SqlReadinessStatuses.ReadyWithConditions)]
    [InlineData(SqlAssessmentStatuses.Complete, SqlReadinessStatuses.Ready)]
    [InlineData(SqlAssessmentStatuses.Blocked, SqlReadinessStatuses.Blocked)]
    public void Every_approved_status_and_readiness_value_has_a_valid_human_transition(
        string assessmentStatus,
        string readinessStatus)
    {
        var notStarted = assessmentStatus == SqlAssessmentStatuses.NotStarted;
        var blocked = assessmentStatus == SqlAssessmentStatuses.Blocked;
        var result = SqlAssessmentRules.Validate(
            assessmentStatus,
            readinessStatus,
            notStarted ? null : SqlAssessmentTargetPlatforms.Investigate,
            null,
            notStarted ? null : SqlMigrationApproaches.ToBeDetermined,
            blocked ? "Synthetic blocker" : "",
            "Synthetic finding",
            readinessStatus == SqlReadinessStatuses.ReadyWithConditions ? "Synthetic condition" : "",
            assessmentStatus == SqlAssessmentStatuses.Complete ? Now : null,
            Now);

        Assert.Equal(assessmentStatus, result.AssessmentStatus);
        Assert.Equal(readinessStatus, result.ReadinessStatus);
    }

    [Theory]
    [InlineData(SqlAssessmentTargetPlatforms.AzureSqlDatabase, SqlMigrationApproaches.Offline, null)]
    [InlineData(SqlAssessmentTargetPlatforms.AzureSqlManagedInstance, SqlMigrationApproaches.Online, null)]
    [InlineData(SqlAssessmentTargetPlatforms.SqlServerOnAzureVm, SqlMigrationApproaches.ToBeDetermined, "SQL Server 2025")]
    [InlineData(SqlAssessmentTargetPlatforms.Retain, SqlMigrationApproaches.NotApplicable, null)]
    [InlineData(SqlAssessmentTargetPlatforms.Retire, SqlMigrationApproaches.NotApplicable, null)]
    [InlineData(SqlAssessmentTargetPlatforms.Investigate, SqlMigrationApproaches.ToBeDetermined, null)]
    public void Approved_target_and_approach_combinations_are_human_planning_records(
        string target,
        string approach,
        string? version)
    {
        var result = Valid(targetPlatform: target, migrationApproach: approach, targetSqlVersion: version);

        Assert.Equal(target, result.TargetPlatform);
        Assert.Equal(approach, result.MigrationApproach);
        Assert.Equal(version, result.TargetSqlVersion);
    }

    [Theory]
    [InlineData("notstarted", SqlReadinessStatuses.NotAssessed)]
    [InlineData(SqlAssessmentStatuses.NotStarted, "notassessed")]
    [InlineData("Recommended", SqlReadinessStatuses.Ready)]
    public void Controlled_values_are_case_sensitive_and_unknown_values_are_rejected(
        string assessmentStatus,
        string readinessStatus)
    {
        Assert.Throws<DomainValidationException>(() => Valid(
            assessmentStatus: assessmentStatus,
            readinessStatus: readinessStatus));
    }

    [Fact]
    public void Not_started_requires_empty_planning_and_assessed_time()
    {
        Assert.Throws<DomainValidationException>(() => Valid(
            assessmentStatus: SqlAssessmentStatuses.NotStarted,
            readinessStatus: SqlReadinessStatuses.NotAssessed,
            targetPlatform: SqlAssessmentTargetPlatforms.Investigate,
            migrationApproach: SqlMigrationApproaches.ToBeDetermined));
    }

    [Fact]
    public void In_progress_cannot_be_ready()
    {
        Assert.Throws<DomainValidationException>(() => Valid(
            assessmentStatus: SqlAssessmentStatuses.InProgress,
            readinessStatus: SqlReadinessStatuses.Ready));
    }

    [Theory]
    [InlineData(SqlReadinessStatuses.AtRisk, "blocked")]
    [InlineData(SqlReadinessStatuses.Blocked, "")]
    public void Blocked_assessment_requires_blocked_readiness_and_blockers(string readiness, string blockers)
    {
        Assert.Throws<DomainValidationException>(() => Valid(
            assessmentStatus: SqlAssessmentStatuses.Blocked,
            readinessStatus: readiness,
            blockers: blockers));
    }

    [Fact]
    public void Complete_requires_assessed_time_target_and_assessed_readiness()
    {
        Assert.Throws<DomainValidationException>(() => Valid(
            targetPlatform: null,
            migrationApproach: null));
        Assert.Throws<DomainValidationException>(() => SqlAssessmentRules.Validate(
            SqlAssessmentStatuses.Complete,
            SqlReadinessStatuses.Ready,
            SqlAssessmentTargetPlatforms.AzureSqlDatabase,
            null,
            SqlMigrationApproaches.Offline,
            "",
            "Synthetic finding",
            "Synthetic note",
            null,
            Now));
        Assert.Throws<DomainValidationException>(() => Valid(readinessStatus: SqlReadinessStatuses.NotAssessed));
    }

    [Theory]
    [InlineData(SqlAssessmentTargetPlatforms.AzureSqlDatabase, SqlMigrationApproaches.NotApplicable)]
    [InlineData(SqlAssessmentTargetPlatforms.Retain, SqlMigrationApproaches.Online)]
    [InlineData(SqlAssessmentTargetPlatforms.Retire, SqlMigrationApproaches.ToBeDetermined)]
    [InlineData(SqlAssessmentTargetPlatforms.Investigate, SqlMigrationApproaches.Offline)]
    public void Invalid_target_approach_combinations_are_rejected(string target, string approach)
    {
        Assert.Throws<DomainValidationException>(() => Valid(
            targetPlatform: target,
            migrationApproach: approach));
    }

    [Fact]
    public void Target_version_is_only_allowed_for_sql_server_on_azure_vm()
    {
        Assert.Throws<DomainValidationException>(() => Valid(targetSqlVersion: "SQL Server 2025"));
    }

    [Fact]
    public void Ready_with_conditions_requires_blockers_or_notes_and_ready_requires_blank_blockers()
    {
        Assert.Throws<DomainValidationException>(() => Valid(
            readinessStatus: SqlReadinessStatuses.ReadyWithConditions,
            blockers: "",
            notes: ""));
        Assert.Throws<DomainValidationException>(() => Valid(
            readinessStatus: SqlReadinessStatuses.Ready,
            blockers: "unresolved"));
    }

    [Fact]
    public void Assessed_time_cannot_exceed_server_time_tolerance()
    {
        Assert.Throws<DomainValidationException>(() => Valid(assessedAt: Now.AddMinutes(5).AddTicks(1)));
        Assert.Equal(Now.AddMinutes(5), Valid(assessedAt: Now.AddMinutes(5)).AssessedAt);
    }

    [Fact]
    public void Narrative_boundaries_and_unsafe_control_characters_are_enforced()
    {
        Assert.Equal(4000, Valid(readinessStatus: SqlReadinessStatuses.AtRisk, blockers: new string('b', 4000)).Blockers.Length);
        Assert.Equal(8000, Valid(findings: new string('f', 8000)).Findings.Length);
        Assert.Equal(4000, Valid(notes: new string('n', 4000)).Notes.Length);
        Assert.Throws<DomainValidationException>(() => Valid(readinessStatus: SqlReadinessStatuses.AtRisk, blockers: new string('b', 4001)));
        Assert.Throws<DomainValidationException>(() => Valid(findings: new string('f', 8001)));
        Assert.Throws<DomainValidationException>(() => Valid(notes: "unsafe\0value"));
    }

    private static SqlAssessmentValues Valid(
        string assessmentStatus = SqlAssessmentStatuses.Complete,
        string readinessStatus = SqlReadinessStatuses.Ready,
        string? targetPlatform = SqlAssessmentTargetPlatforms.AzureSqlDatabase,
        string? targetSqlVersion = null,
        string? migrationApproach = SqlMigrationApproaches.Offline,
        string blockers = "",
        string findings = "Synthetic finding",
        string notes = "Synthetic note",
        DateTimeOffset? assessedAt = null) =>
        SqlAssessmentRules.Validate(
            assessmentStatus,
            readinessStatus,
            targetPlatform,
            targetSqlVersion,
            migrationApproach,
            blockers,
            findings,
            notes,
            assessedAt ?? Now,
            Now);
}
