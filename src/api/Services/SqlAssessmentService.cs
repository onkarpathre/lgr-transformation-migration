using System.Globalization;
using System.Security.Cryptography;
using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Domain;
using LgrTransformationMigration.Api.Infrastructure;
using Microsoft.EntityFrameworkCore;

namespace LgrTransformationMigration.Api.Services;

public sealed class SqlAssessmentService(
    AppDbContext db,
    ICurrentCustomerContext context,
    TimeProvider timeProvider)
{
    public async Task<PagedResult<SqlAssessmentDto>> ListAsync(
        int page,
        int pageSize,
        string? targetType,
        Guid? targetId,
        string? assessmentStatus,
        string? readinessStatus,
        CancellationToken cancellationToken)
    {
        await EnsureCurrentProjectAsync(cancellationToken);
        var query = BaseQuery(tracking: false);

        if (!string.IsNullOrWhiteSpace(targetType))
        {
            targetType = ValidateTargetType(targetType);
            query = targetType == "SqlInstance"
                ? query.Where(x => x.SqlInstanceId != null)
                : query.Where(x => x.SqlDatabaseId != null);
        }

        if (targetId.HasValue)
        {
            if (targetId == Guid.Empty || targetType is null)
            {
                throw new DomainValidationException("TargetId requires a valid TargetType.");
            }

            query = targetType == "SqlInstance"
                ? query.Where(x => x.SqlInstanceId == targetId)
                : query.Where(x => x.SqlDatabaseId == targetId);
        }

        if (!string.IsNullOrWhiteSpace(assessmentStatus))
        {
            RequireControlled(assessmentStatus, SqlAssessmentStatuses.All, "AssessmentStatus");
            query = query.Where(x => x.AssessmentStatus == assessmentStatus);
        }

        if (!string.IsNullOrWhiteSpace(readinessStatus))
        {
            RequireControlled(readinessStatus, SqlReadinessStatuses.All, "ReadinessStatus");
            query = query.Where(x => x.ReadinessStatus == readinessStatus);
        }

        var totalCount = await query.CountAsync(cancellationToken);
        List<SqlAssessmentReadModel> items;
        if (db.Database.ProviderName == "Microsoft.EntityFrameworkCore.Sqlite")
        {
            // SQLite is a supplementary test provider and cannot order DateTimeOffset.
            items = (await query.Select(ReadProjection).ToListAsync(cancellationToken))
                .OrderByDescending(x => x.UpdatedAt)
                .ThenBy(x => x.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList();
        }
        else
        {
            items = await query
                .OrderByDescending(x => x.UpdatedAt)
                .ThenBy(x => x.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(ReadProjection)
                .ToListAsync(cancellationToken);
        }
        return new PagedResult<SqlAssessmentDto>(items.Select(Map).ToList(), page, pageSize, totalCount);
    }

    public async Task<SqlAssessmentDto> GetAsync(Guid id, CancellationToken cancellationToken)
    {
        await EnsureCurrentProjectAsync(cancellationToken);
        var item = await BaseQuery(tracking: false)
            .Where(x => x.Id == id)
            .Select(ReadProjection)
            .SingleOrDefaultAsync(cancellationToken)
            ?? throw new KeyNotFoundException("SQL assessment not found.");
        return Map(item);
    }

    public async Task<SqlAssessmentDto> CreateAsync(
        SqlAssessmentCreateV1 request,
        CancellationToken cancellationToken)
    {
        await EnsureCurrentProjectAsync(cancellationToken);
        ValidateExactlyOneTarget(request.SqlInstanceId, request.SqlDatabaseId);
        var target = await RequireTargetAsync(request.SqlInstanceId, request.SqlDatabaseId, cancellationToken);
        await EnsureTargetAvailableAsync(request.SqlInstanceId, request.SqlDatabaseId, cancellationToken);
        var values = SqlAssessmentRules.Validate(
            request.AssessmentStatus,
            request.ReadinessStatus,
            request.TargetPlatform,
            request.TargetSqlVersion,
            request.MigrationApproach,
            request.Blockers,
            request.Findings,
            request.Notes,
            request.AssessedAt,
            Now);
        var now = Now;
        var entity = new SqlAssessment
        {
            Id = Guid.NewGuid(),
            CustomerId = context.CustomerId,
            ProjectId = context.ProjectId,
            SqlInstanceId = request.SqlInstanceId,
            SqlDatabaseId = request.SqlDatabaseId,
            AssessmentStatus = values.AssessmentStatus,
            ReadinessStatus = values.ReadinessStatus,
            TargetPlatform = values.TargetPlatform,
            TargetSqlVersion = values.TargetSqlVersion,
            MigrationApproach = values.MigrationApproach,
            Blockers = values.Blockers,
            Findings = values.Findings,
            Notes = values.Notes,
            AssessedAt = values.AssessedAt,
            CreatedAt = now,
            CreatedBy = Actor,
            UpdatedAt = now,
            UpdatedBy = Actor,
            RowVersion = NewVersion(),
            SqlInstance = target.Instance,
            SqlDatabase = target.Database
        };
        db.SqlAssessments.Add(entity);
        AddAudit(entity.Id, "SqlAssessmentCreated");
        await SaveAsync(cancellationToken);
        return Map(entity, target.Instance?.InstanceName ?? target.Database!.Name);
    }

    public async Task<SqlAssessmentDto> UpdateEvidenceAsync(
        Guid id,
        SqlAssessmentEvidenceUpdateV1 request,
        string? ifMatch,
        CancellationToken cancellationToken)
    {
        await EnsureCurrentProjectAsync(cancellationToken);
        var entity = await FindAsync(id, tracking: true, cancellationToken);
        EnsureIfMatch(ifMatch, entity.RowVersion);
        var values = SqlAssessmentRules.Validate(
            request.AssessmentStatus,
            request.ReadinessStatus,
            entity.TargetPlatform,
            entity.TargetSqlVersion,
            entity.MigrationApproach,
            request.Blockers,
            request.Findings,
            request.Notes,
            request.AssessedAt,
            Now);
        var changed = false;
        changed |= AuditChange(entity.Id, "AssessmentStatus", entity.AssessmentStatus, values.AssessmentStatus, "SqlAssessmentEvidenceChanged");
        changed |= AuditChange(entity.Id, "ReadinessStatus", entity.ReadinessStatus, values.ReadinessStatus, "SqlAssessmentEvidenceChanged");
        changed |= AuditChange(entity.Id, "Blockers", entity.Blockers, values.Blockers, "SqlAssessmentEvidenceChanged");
        changed |= AuditChange(entity.Id, "Findings", entity.Findings, values.Findings, "SqlAssessmentEvidenceChanged");
        changed |= AuditChange(entity.Id, "Notes", entity.Notes, values.Notes, "SqlAssessmentEvidenceChanged");
        changed |= AuditChange(entity.Id, "AssessedAt", entity.AssessedAt, values.AssessedAt, "SqlAssessmentEvidenceChanged");
        if (changed)
        {
            var originalVersion = entity.RowVersion.ToArray();
            entity.AssessmentStatus = values.AssessmentStatus;
            entity.ReadinessStatus = values.ReadinessStatus;
            entity.Blockers = values.Blockers;
            entity.Findings = values.Findings;
            entity.Notes = values.Notes;
            entity.AssessedAt = values.AssessedAt;
            entity.UpdatedAt = Now;
            entity.UpdatedBy = Actor;
            RotateVersion(entity, originalVersion);
            await SaveAsync(cancellationToken);
        }

        return await MapTrackedAsync(entity, cancellationToken);
    }

    public async Task<SqlAssessmentDto> UpdatePlanningAsync(
        Guid id,
        SqlAssessmentPlanningUpdateV1 request,
        string? ifMatch,
        CancellationToken cancellationToken)
    {
        await EnsureCurrentProjectAsync(cancellationToken);
        var entity = await FindAsync(id, tracking: true, cancellationToken);
        EnsureIfMatch(ifMatch, entity.RowVersion);
        var values = SqlAssessmentRules.Validate(
            entity.AssessmentStatus,
            entity.ReadinessStatus,
            request.TargetPlatform,
            request.TargetSqlVersion,
            request.MigrationApproach,
            entity.Blockers,
            entity.Findings,
            entity.Notes,
            entity.AssessedAt,
            Now);
        var changed = false;
        changed |= AuditChange(entity.Id, "TargetPlatform", entity.TargetPlatform, values.TargetPlatform, "SqlAssessmentPlanningChanged");
        changed |= AuditChange(entity.Id, "TargetSqlVersion", entity.TargetSqlVersion, values.TargetSqlVersion, "SqlAssessmentPlanningChanged");
        changed |= AuditChange(entity.Id, "MigrationApproach", entity.MigrationApproach, values.MigrationApproach, "SqlAssessmentPlanningChanged");
        if (changed)
        {
            var originalVersion = entity.RowVersion.ToArray();
            entity.TargetPlatform = values.TargetPlatform;
            entity.TargetSqlVersion = values.TargetSqlVersion;
            entity.MigrationApproach = values.MigrationApproach;
            entity.UpdatedAt = Now;
            entity.UpdatedBy = Actor;
            RotateVersion(entity, originalVersion);
            await SaveAsync(cancellationToken);
        }

        return await MapTrackedAsync(entity, cancellationToken);
    }

    public async Task ArchiveAsync(Guid id, string? ifMatch, CancellationToken cancellationToken)
    {
        await EnsureCurrentProjectAsync(cancellationToken);
        var entity = await FindAsync(id, tracking: true, cancellationToken);
        EnsureIfMatch(ifMatch, entity.RowVersion);
        var originalVersion = entity.RowVersion.ToArray();
        entity.IsDeleted = true;
        entity.DeletedAt = Now;
        entity.DeletedBy = Actor;
        entity.UpdatedAt = entity.DeletedAt.Value;
        entity.UpdatedBy = Actor;
        RotateVersion(entity, originalVersion);
        AddAudit(entity.Id, "SqlAssessmentArchived");
        await SaveAsync(cancellationToken);
    }

    private DateTimeOffset Now => timeProvider.GetUtcNow();
    private string Actor => context.UserName;

    private IQueryable<SqlAssessment> BaseQuery(bool tracking)
    {
        var query = db.SqlAssessments.Where(x => x.ProjectId == context.ProjectId);
        return tracking ? query : query.AsNoTracking();
    }

    private async Task<SqlAssessment> FindAsync(Guid id, bool tracking, CancellationToken cancellationToken) =>
        await BaseQuery(tracking).SingleOrDefaultAsync(x => x.Id == id, cancellationToken)
        ?? throw new KeyNotFoundException("SQL assessment not found.");

    private async Task EnsureCurrentProjectAsync(CancellationToken cancellationToken)
    {
        if (!await db.Projects.AsNoTracking().AnyAsync(
                x => x.Id == context.ProjectId && x.CustomerId == context.CustomerId,
                cancellationToken))
        {
            throw new KeyNotFoundException("Project not found.");
        }
    }

    private async Task<(SqlInstance? Instance, SqlDatabase? Database)> RequireTargetAsync(
        Guid? sqlInstanceId,
        Guid? sqlDatabaseId,
        CancellationToken cancellationToken)
    {
        if (sqlInstanceId.HasValue)
        {
            var instance = await db.SqlInstances.SingleOrDefaultAsync(
                x => x.Id == sqlInstanceId && x.ProjectId == context.ProjectId,
                cancellationToken);
            return (instance ?? throw new KeyNotFoundException("SQL assessment target not found."), null);
        }

        var database = await db.SqlDatabases.SingleOrDefaultAsync(
            x => x.Id == sqlDatabaseId && x.ProjectId == context.ProjectId,
            cancellationToken);
        return (null, database ?? throw new KeyNotFoundException("SQL assessment target not found."));
    }

    private async Task EnsureTargetAvailableAsync(
        Guid? sqlInstanceId,
        Guid? sqlDatabaseId,
        CancellationToken cancellationToken)
    {
        if (await db.SqlAssessments.AnyAsync(
                x => x.ProjectId == context.ProjectId
                     && ((sqlInstanceId != null && x.SqlInstanceId == sqlInstanceId)
                         || (sqlDatabaseId != null && x.SqlDatabaseId == sqlDatabaseId)),
                cancellationToken))
        {
            throw new DomainConflictException("The SQL target already has an active assessment.");
        }
    }

    private static void ValidateExactlyOneTarget(Guid? sqlInstanceId, Guid? sqlDatabaseId)
    {
        if ((sqlInstanceId.HasValue ? 1 : 0) + (sqlDatabaseId.HasValue ? 1 : 0) != 1
            || sqlInstanceId == Guid.Empty
            || sqlDatabaseId == Guid.Empty)
        {
            throw new DomainValidationException("Exactly one non-empty SQL instance or SQL database target is required.");
        }
    }

    private static string ValidateTargetType(string targetType) => targetType switch
    {
        "SqlInstance" => targetType,
        "SqlDatabase" => targetType,
        _ => throw new DomainValidationException("TargetType must be SqlInstance or SqlDatabase.")
    };

    private static void RequireControlled(string value, IReadOnlySet<string> values, string field)
    {
        if (!values.Contains(value))
        {
            throw new DomainValidationException($"{field} is not an allowed value.");
        }
    }

    private void AddAudit(
        Guid entityId,
        string action,
        string? propertyName = null,
        object? oldValue = null,
        object? newValue = null) =>
        db.AuditEvents.Add(new AuditEvent
        {
            Id = Guid.NewGuid(),
            CustomerId = context.CustomerId,
            ProjectId = context.ProjectId,
            EntityType = "SqlAssessment",
            EntityId = entityId,
            Action = action,
            PropertyName = propertyName,
            OldValue = AuditValue(oldValue),
            NewValue = AuditValue(newValue),
            ChangedBy = Actor,
            ActorPrincipalType = context.Principal.PrincipalType.ToString(),
            ChangedAt = Now,
            CorrelationId = context.CorrelationId
        });

    private bool AuditChange(Guid id, string propertyName, object? oldValue, object? newValue, string action)
    {
        if (Equals(oldValue, newValue))
        {
            return false;
        }

        AddAudit(id, action, propertyName, oldValue, newValue);
        return true;
    }

    private static string? AuditValue(object? value) => value switch
    {
        null => null,
        DateTimeOffset timestamp => timestamp.ToUniversalTime().ToString("O", CultureInfo.InvariantCulture),
        IFormattable formattable => formattable.ToString(null, CultureInfo.InvariantCulture),
        _ => value.ToString()
    };

    private static byte[] NewVersion() => RandomNumberGenerator.GetBytes(8);

    private void RotateVersion(SqlAssessment entity, byte[] originalVersion)
    {
        entity.RowVersion = NewVersion();
        db.Entry(entity).Property(x => x.RowVersion).OriginalValue = originalVersion;
    }

    private static void EnsureIfMatch(string? ifMatch, byte[] rowVersion)
    {
        if (string.IsNullOrWhiteSpace(ifMatch))
        {
            throw new PreconditionRequiredException("If-Match is required for updates and archive.");
        }

        var expected = $"\"{Convert.ToBase64String(rowVersion)}\"";
        if (!ifMatch.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .Contains(expected, StringComparer.Ordinal))
        {
            throw new StaleVersionException("The resource was changed after it was retrieved.");
        }
    }

    private async Task SaveAsync(CancellationToken cancellationToken)
    {
        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateConcurrencyException exception)
        {
            throw new StaleVersionException("The resource was changed after it was retrieved.", exception);
        }
    }

    private async Task<SqlAssessmentDto> MapTrackedAsync(
        SqlAssessment entity,
        CancellationToken cancellationToken)
    {
        var targetName = entity.SqlInstanceId.HasValue
            ? await db.SqlInstances.Where(x => x.Id == entity.SqlInstanceId && x.ProjectId == context.ProjectId)
                .Select(x => x.InstanceName)
                .SingleAsync(cancellationToken)
            : await db.SqlDatabases.Where(x => x.Id == entity.SqlDatabaseId && x.ProjectId == context.ProjectId)
                .Select(x => x.Name)
                .SingleAsync(cancellationToken);
        return Map(entity, targetName);
    }

    private static SqlAssessmentDto Map(SqlAssessment entity, string targetName)
    {
        var instanceTarget = entity.SqlInstanceId.HasValue;
        return new SqlAssessmentDto(
            entity.Id,
            entity.CustomerId,
            entity.ProjectId,
            instanceTarget ? "SqlInstance" : "SqlDatabase",
            new NamedReferenceDto(
                instanceTarget ? entity.SqlInstanceId!.Value : entity.SqlDatabaseId!.Value,
                targetName),
            entity.AssessmentStatus,
            entity.ReadinessStatus,
            entity.TargetPlatform,
            entity.TargetSqlVersion,
            entity.MigrationApproach,
            entity.Blockers,
            entity.Findings,
            entity.Notes,
            entity.AssessedAt,
            entity.CreatedAt,
            entity.CreatedBy,
            entity.UpdatedAt,
            entity.UpdatedBy,
            Convert.ToBase64String(entity.RowVersion));
    }

    private static SqlAssessmentDto Map(SqlAssessmentReadModel item) => new(
        item.Id,
        item.CustomerId,
        item.ProjectId,
        item.TargetType,
        new NamedReferenceDto(item.TargetId, item.TargetName),
        item.AssessmentStatus,
        item.ReadinessStatus,
        item.TargetPlatform,
        item.TargetSqlVersion,
        item.MigrationApproach,
        item.Blockers,
        item.Findings,
        item.Notes,
        item.AssessedAt,
        item.CreatedAt,
        item.CreatedBy,
        item.UpdatedAt,
        item.UpdatedBy,
        Convert.ToBase64String(item.RowVersion));

    private static readonly System.Linq.Expressions.Expression<Func<SqlAssessment, SqlAssessmentReadModel>> ReadProjection =
        entity => new SqlAssessmentReadModel(
            entity.Id,
            entity.CustomerId,
            entity.ProjectId,
            entity.SqlInstanceId != null ? "SqlInstance" : "SqlDatabase",
            entity.SqlInstanceId ?? entity.SqlDatabaseId!.Value,
            entity.SqlInstanceId != null ? entity.SqlInstance!.InstanceName : entity.SqlDatabase!.Name,
            entity.AssessmentStatus,
            entity.ReadinessStatus,
            entity.TargetPlatform,
            entity.TargetSqlVersion,
            entity.MigrationApproach,
            entity.Blockers,
            entity.Findings,
            entity.Notes,
            entity.AssessedAt,
            entity.CreatedAt,
            entity.CreatedBy,
            entity.UpdatedAt,
            entity.UpdatedBy,
            entity.RowVersion);

    private sealed record SqlAssessmentReadModel(
        Guid Id,
        Guid CustomerId,
        Guid ProjectId,
        string TargetType,
        Guid TargetId,
        string TargetName,
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
        byte[] RowVersion);
}
