using System.ComponentModel.DataAnnotations;

namespace LgrTransformationMigration.Api.Contracts;

public sealed record DependencyReferenceWriteV1(
    [Required, MaxLength(32)] string ReferenceType,
    [Required, MaxLength(200)] string Name,
    [MaxLength(1000)] string? Description,
    [Required, MaxLength(20)] string ResolutionStatus);

public sealed record DependencyReferenceDto(
    Guid Id,
    string ReferenceType,
    string Name,
    string? Description,
    string ResolutionStatus,
    int ActiveDependencyCount,
    bool IsArchived,
    DateTimeOffset CreatedAt,
    string CreatedBy,
    DateTimeOffset UpdatedAt,
    string UpdatedBy,
    string Version);

public sealed record DependencyEndpointV1(
    [Required, MaxLength(32)] string Type,
    Guid Id);

public sealed record DependencyCreateV1(
    [Required] DependencyEndpointV1 Source,
    [Required] DependencyEndpointV1 Target,
    [Required, MaxLength(40)] string DependencyType,
    [Required, MaxLength(20)] string Criticality,
    [MaxLength(2000)] string? Description,
    [MaxLength(4000)] string? BusinessContext);

public sealed record DependencyUpdateV1(
    [Required, MaxLength(40)] string DependencyType,
    [Required, MaxLength(20)] string Criticality,
    [MaxLength(2000)] string? Description,
    [MaxLength(4000)] string? BusinessContext);

public sealed record DependencyConfirmationV1(
    [Required, MaxLength(20)] string ConfirmationStatus);

public sealed record DependencyEndpointDto(
    string Type,
    Guid Id,
    string DisplayName,
    string InventoryRoute,
    string? ReferenceType,
    string? ResolutionStatus);

public sealed record DependencyFindingCountsDto(int Information, int Warning, int Blocker);

public sealed record DependencyDto(
    Guid Id,
    DependencyEndpointDto Source,
    DependencyEndpointDto Target,
    string DirectionLabel,
    string DependencyType,
    string Criticality,
    string? Description,
    string? BusinessContext,
    string ConfirmationStatus,
    DateTimeOffset? ConfirmedAt,
    string? ConfirmedByDisplay,
    DependencyFindingCountsDto CurrentFindingCounts,
    bool IsArchived,
    DateTimeOffset CreatedAt,
    string CreatedBy,
    DateTimeOffset UpdatedAt,
    string UpdatedBy,
    string Version);

public sealed record DependencyAuditEventDto(
    Guid Id,
    string Action,
    string? PropertyName,
    string? OldValue,
    string? NewValue,
    string ChangedBy,
    string? ActorPrincipalType,
    DateTimeOffset ChangedAt,
    string? CorrelationId);
