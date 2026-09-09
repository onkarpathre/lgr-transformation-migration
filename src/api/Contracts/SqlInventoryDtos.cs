using System.ComponentModel.DataAnnotations;

namespace LgrTransformationMigration.Api.Contracts;

public sealed record SqlInstanceWriteV1(
    Guid ServerId,
    [Required, MaxLength(128)] string InstanceName,
    [Required, MaxLength(100)] string SqlVersion,
    [Required, MaxLength(100)] string Edition,
    [Range(1, 65535)] int? Port,
    [Required, MaxLength(50)] string ServiceStatus,
    [MaxLength(256)] string? ServiceAccountName);

public sealed record SqlInstanceDto(
    Guid Id,
    Guid CustomerId,
    Guid ProjectId,
    NamedReferenceDto Server,
    string InstanceName,
    string SqlVersion,
    string Edition,
    int? Port,
    string ServiceStatus,
    string DiscoverySource,
    string? ServiceAccountName,
    DateTimeOffset? LastDiscoveredAt,
    Guid? LastImportBatchId,
    DateTimeOffset? LastImportedAt,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    string CreatedBy,
    string UpdatedBy,
    string Version);

public sealed record SqlDatabaseWriteV1(
    Guid SqlInstanceId,
    [Required, MaxLength(128)] string Name,
    [Range(typeof(long), "0", "9223372036854775807")] long SizeMb,
    [Range(80, 200)] int CompatibilityLevel,
    [Required, MaxLength(30)] string RecoveryModel,
    [MaxLength(128)] string? Collation,
    [Required, MaxLength(50)] string Status);

public sealed record SqlDatabaseDto(
    Guid Id,
    Guid CustomerId,
    Guid ProjectId,
    NamedReferenceDto SqlInstance,
    string Name,
    long SizeMb,
    int CompatibilityLevel,
    string RecoveryModel,
    string? Collation,
    string Status,
    Guid? LastImportBatchId,
    DateTimeOffset? LastImportedAt,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    string CreatedBy,
    string UpdatedBy,
    string Version);
