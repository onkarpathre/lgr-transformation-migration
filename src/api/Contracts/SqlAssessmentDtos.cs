using System.ComponentModel.DataAnnotations;

namespace LgrTransformationMigration.Api.Contracts;

public sealed record SqlAssessmentCreateV1(
    Guid? SqlInstanceId,
    Guid? SqlDatabaseId,
    [Required, MaxLength(50)] string AssessmentStatus,
    [Required, MaxLength(50)] string ReadinessStatus,
    [MaxLength(80)] string? TargetPlatform,
    [MaxLength(100)] string? TargetSqlVersion,
    [MaxLength(50)] string? MigrationApproach,
    [Required(AllowEmptyStrings = true), MaxLength(4000)] string Blockers,
    [Required(AllowEmptyStrings = true), MaxLength(8000)] string Findings,
    [Required(AllowEmptyStrings = true), MaxLength(4000)] string Notes,
    DateTimeOffset? AssessedAt);

public sealed record SqlAssessmentEvidenceUpdateV1(
    [Required, MaxLength(50)] string AssessmentStatus,
    [Required, MaxLength(50)] string ReadinessStatus,
    [Required(AllowEmptyStrings = true), MaxLength(4000)] string Blockers,
    [Required(AllowEmptyStrings = true), MaxLength(8000)] string Findings,
    [Required(AllowEmptyStrings = true), MaxLength(4000)] string Notes,
    DateTimeOffset? AssessedAt);

public sealed record SqlAssessmentPlanningUpdateV1(
    [MaxLength(80)] string? TargetPlatform,
    [MaxLength(100)] string? TargetSqlVersion,
    [MaxLength(50)] string? MigrationApproach);

public sealed record SqlAssessmentDto(
    Guid Id,
    Guid CustomerId,
    Guid ProjectId,
    string TargetType,
    NamedReferenceDto Target,
    string AssessmentStatus,
    string ReadinessStatus,
    string? TargetPlatform,
    string? TargetSqlVersion,
    string? MigrationApproach,
    string Blockers,
    string Findings,
    string Notes,
    DateTimeOffset? AssessedAt,
    DateTimeOffset CreatedAt,
    string CreatedBy,
    DateTimeOffset UpdatedAt,
    string UpdatedBy,
    string Version);
