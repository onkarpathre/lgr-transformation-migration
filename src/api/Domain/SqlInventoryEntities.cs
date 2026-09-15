namespace LgrTransformationMigration.Api.Domain;

public sealed class SqlInstance : IProjectOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public Guid ServerId { get; set; }
    public string InstanceName { get; set; } = string.Empty;
    public string NormalizedInstanceName { get; set; } = string.Empty;
    public string SqlVersion { get; set; } = string.Empty;
    public string Edition { get; set; } = string.Empty;
    public int? Port { get; set; }
    public string ServiceStatus { get; set; } = string.Empty;
    public string DiscoverySource { get; set; } = string.Empty;
    public string? ServiceAccountName { get; set; }
    public DateTimeOffset? LastDiscoveredAt { get; set; }
    public Guid? LastImportBatchId { get; set; }
    public DateTimeOffset? LastImportedAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public string CreatedBy { get; set; } = string.Empty;
    public string UpdatedBy { get; set; } = string.Empty;
    public bool IsDeleted { get; set; }
    public DateTimeOffset? DeletedAt { get; set; }
    public string? DeletedBy { get; set; }
    public byte[] RowVersion { get; set; } = [];
    public Project Project { get; set; } = null!;
    public Server Server { get; set; } = null!;
    public ImportBatch? LastImportBatch { get; set; }
    public ICollection<SqlDatabase> Databases { get; set; } = [];
}

public sealed class SqlDatabase : IProjectOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public Guid SqlInstanceId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string NormalizedName { get; set; } = string.Empty;
    public long SizeMb { get; set; }
    public int CompatibilityLevel { get; set; }
    public string RecoveryModel { get; set; } = string.Empty;
    public string? Collation { get; set; }
    public string Status { get; set; } = string.Empty;
    public Guid? LastImportBatchId { get; set; }
    public DateTimeOffset? LastImportedAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public string CreatedBy { get; set; } = string.Empty;
    public string UpdatedBy { get; set; } = string.Empty;
    public bool IsDeleted { get; set; }
    public DateTimeOffset? DeletedAt { get; set; }
    public string? DeletedBy { get; set; }
    public byte[] RowVersion { get; set; } = [];
    public Project Project { get; set; } = null!;
    public SqlInstance SqlInstance { get; set; } = null!;
    public ImportBatch? LastImportBatch { get; set; }
}
