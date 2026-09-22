namespace LgrTransformationMigration.Api.Domain;

public sealed class DependencyReference : IProjectOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public string ReferenceType { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string NormalizedName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string ResolutionStatus { get; set; } = string.Empty;
    public bool IsArchived { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public string CreatedBy { get; set; } = string.Empty;
    public DateTimeOffset UpdatedAt { get; set; }
    public string UpdatedBy { get; set; } = string.Empty;
    public byte[] RowVersion { get; set; } = [];
}

public sealed class Dependency : IProjectOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public string SourceType { get; set; } = string.Empty;
    public Guid? SourceApplicationId { get; set; }
    public Guid? SourceServerId { get; set; }
    public Guid? SourceSqlInstanceId { get; set; }
    public Guid? SourceSqlDatabaseId { get; set; }
    public string SourceEndpointKey { get; set; } = string.Empty;
    public string TargetType { get; set; } = string.Empty;
    public Guid? TargetApplicationId { get; set; }
    public Guid? TargetServerId { get; set; }
    public Guid? TargetSqlInstanceId { get; set; }
    public Guid? TargetSqlDatabaseId { get; set; }
    public Guid? TargetReferenceId { get; set; }
    public string TargetEndpointKey { get; set; } = string.Empty;
    public string DependencyType { get; set; } = string.Empty;
    public string Criticality { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? BusinessContext { get; set; }
    public string ConfirmationStatus { get; set; } = string.Empty;
    public DateTimeOffset? ConfirmedAt { get; set; }
    public string? ConfirmedBy { get; set; }
    public bool IsArchived { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public string CreatedBy { get; set; } = string.Empty;
    public DateTimeOffset UpdatedAt { get; set; }
    public string UpdatedBy { get; set; } = string.Empty;
    public byte[] RowVersion { get; set; } = [];
}

public sealed class DependencyPolicy : IProjectOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public int Version { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public string CreatedBy { get; set; } = string.Empty;
    public DateTimeOffset? ActivatedAt { get; set; }
    public string? ActivatedBy { get; set; }
    public byte[] RowVersion { get; set; } = [];
    public ICollection<DependencyPolicyRule> Rules { get; set; } = [];
}

public sealed class DependencyPolicyRule : IProjectOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public Guid DependencyPolicyId { get; set; }
    public string RuleCode { get; set; } = string.Empty;
    public string MandatorySeverity { get; set; } = string.Empty;
    public string AdvisorySeverity { get; set; } = string.Empty;
    public DependencyPolicy DependencyPolicy { get; set; } = null!;
}

public sealed class DependencyGraphState : IProjectOwned
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public long GraphVersion { get; set; }
    public long PlanningVersion { get; set; }
    public Guid? CurrentValidationRunId { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public byte[] RowVersion { get; set; } = [];
}
