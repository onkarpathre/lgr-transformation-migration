using System.Globalization;
using System.Security.Cryptography;
using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Domain;
using LgrTransformationMigration.Api.Infrastructure;
using Microsoft.EntityFrameworkCore;

namespace LgrTransformationMigration.Api.Services;

public sealed class SqlInventoryService(
    AppDbContext db,
    ICurrentCustomerContext context,
    TimeProvider timeProvider)
{
    public async Task<PagedResult<SqlInstanceDto>> ListInstancesAsync(
        int page,
        int pageSize,
        string? search,
        Guid? serverId,
        string? serviceStatus,
        CancellationToken cancellationToken)
    {
        await EnsureCurrentProjectAsync(cancellationToken);
        var query = db.SqlInstances.AsNoTracking().Where(x => x.ProjectId == context.ProjectId);
        if (!string.IsNullOrWhiteSpace(search))
        {
            var normalizedSearch = SqlInventoryNormalizer.NormalizeInstanceName(search);
            query = query.Where(x => x.NormalizedInstanceName.Contains(normalizedSearch));
        }

        if (serverId.HasValue)
        {
            query = query.Where(x => x.ServerId == serverId.Value);
        }

        if (!string.IsNullOrWhiteSpace(serviceStatus))
        {
            var normalizedStatus = SqlInventoryNormalizer.NormalizeServiceStatus(serviceStatus);
            query = query.Where(x => x.ServiceStatus == normalizedStatus);
        }

        var totalCount = await query.CountAsync(cancellationToken);
        var entities = await query
            .Include(x => x.Server)
            .OrderBy(x => x.NormalizedInstanceName)
            .ThenBy(x => x.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);
        return new PagedResult<SqlInstanceDto>(entities.Select(Map).ToList(), page, pageSize, totalCount);
    }

    public async Task<SqlInstanceDto> GetInstanceAsync(Guid id, CancellationToken cancellationToken)
    {
        await EnsureCurrentProjectAsync(cancellationToken);
        return Map(await FindInstanceAsync(id, tracking: false, cancellationToken));
    }

    public async Task<SqlInstanceDto> CreateInstanceAsync(
        SqlInstanceWriteV1 request,
        CancellationToken cancellationToken)
    {
        await EnsureCurrentProjectAsync(cancellationToken);
        var values = Validate(request);
        var server = await RequireServerAsync(request.ServerId, cancellationToken);
        await EnsureInstanceNameAvailableAsync(server.Id, values.NormalizedName, null, cancellationToken);

        var now = Now;
        var actor = Actor;
        var entity = new SqlInstance
        {
            Id = Guid.NewGuid(),
            CustomerId = context.CustomerId,
            ProjectId = context.ProjectId,
            ServerId = server.Id,
            InstanceName = values.DisplayName,
            NormalizedInstanceName = values.NormalizedName,
            SqlVersion = values.SqlVersion,
            Edition = values.Edition,
            Port = request.Port,
            ServiceStatus = values.ServiceStatus,
            DiscoverySource = "Manual",
            ServiceAccountName = values.ServiceAccountName,
            CreatedAt = now,
            UpdatedAt = now,
            CreatedBy = actor,
            UpdatedBy = actor,
            RowVersion = NewVersion(),
            Server = server
        };
        db.SqlInstances.Add(entity);
        AddAudit("SqlInstance", entity.Id, "SqlInstanceCreated");
        await SaveAsync(cancellationToken);
        return Map(entity);
    }

    public async Task<SqlInstanceDto> UpdateInstanceAsync(
        Guid id,
        SqlInstanceWriteV1 request,
        string? ifMatch,
        CancellationToken cancellationToken)
    {
        await EnsureCurrentProjectAsync(cancellationToken);
        var entity = await FindInstanceAsync(id, tracking: true, cancellationToken);
        EnsureIfMatch(ifMatch, entity.RowVersion);
        var values = Validate(request);
        var server = await RequireServerAsync(request.ServerId, cancellationToken);
        await EnsureInstanceNameAvailableAsync(server.Id, values.NormalizedName, id, cancellationToken);

        var originalVersion = entity.RowVersion.ToArray();
        var changed = false;
        if (entity.ServerId != server.Id)
        {
            AddAudit("SqlInstance", entity.Id, "SqlInstanceRelationshipChanged", "ServerId", entity.ServerId, server.Id);
            changed = true;
        }

        changed |= AuditChange("SqlInstance", entity.Id, "SqlInstanceUpdated", "InstanceName", entity.InstanceName, values.DisplayName);
        changed |= AuditChange("SqlInstance", entity.Id, "SqlInstanceUpdated", "SqlVersion", entity.SqlVersion, values.SqlVersion);
        changed |= AuditChange("SqlInstance", entity.Id, "SqlInstanceUpdated", "Edition", entity.Edition, values.Edition);
        changed |= AuditChange("SqlInstance", entity.Id, "SqlInstanceUpdated", "Port", entity.Port, request.Port);
        changed |= AuditChange("SqlInstance", entity.Id, "SqlInstanceUpdated", "ServiceStatus", entity.ServiceStatus, values.ServiceStatus);
        if (!Equals(entity.ServiceAccountName, values.ServiceAccountName))
        {
            AddAudit(
                "SqlInstance",
                entity.Id,
                "SqlInstanceUpdated",
                "ServiceAccountName",
                Redacted(entity.ServiceAccountName),
                Redacted(values.ServiceAccountName));
            changed = true;
        }

        entity.ServerId = server.Id;
        entity.Server = server;
        entity.InstanceName = values.DisplayName;
        entity.NormalizedInstanceName = values.NormalizedName;
        entity.SqlVersion = values.SqlVersion;
        entity.Edition = values.Edition;
        entity.Port = request.Port;
        entity.ServiceStatus = values.ServiceStatus;
        entity.ServiceAccountName = values.ServiceAccountName;
        if (changed)
        {
            entity.UpdatedAt = Now;
            entity.UpdatedBy = Actor;
            RotateVersion(entity, originalVersion);
            await SaveAsync(cancellationToken);
        }

        return Map(entity);
    }

    public async Task ArchiveInstanceAsync(Guid id, string? ifMatch, CancellationToken cancellationToken)
    {
        await EnsureCurrentProjectAsync(cancellationToken);
        var entity = await FindInstanceAsync(id, tracking: true, cancellationToken);
        EnsureIfMatch(ifMatch, entity.RowVersion);
        if (await db.SqlDatabases.AnyAsync(
                x => x.SqlInstanceId == id && x.ProjectId == context.ProjectId,
                cancellationToken))
        {
            throw new DomainConflictException("The SQL instance cannot be archived while it has active databases.");
        }

        var originalVersion = entity.RowVersion.ToArray();
        entity.IsDeleted = true;
        entity.DeletedAt = Now;
        entity.DeletedBy = Actor;
        entity.UpdatedAt = entity.DeletedAt.Value;
        entity.UpdatedBy = Actor;
        RotateVersion(entity, originalVersion);
        AddAudit("SqlInstance", entity.Id, "SqlInstanceArchived");
        await SaveAsync(cancellationToken);
    }

    public async Task<PagedResult<SqlDatabaseDto>> ListDatabasesAsync(
        int page,
        int pageSize,
        string? search,
        Guid? sqlInstanceId,
        string? status,
        CancellationToken cancellationToken)
    {
        await EnsureCurrentProjectAsync(cancellationToken);
        var query = db.SqlDatabases.AsNoTracking().Where(x => x.ProjectId == context.ProjectId);
        if (!string.IsNullOrWhiteSpace(search))
        {
            var normalizedSearch = SqlInventoryNormalizer.NormalizeDatabaseName(search);
            query = query.Where(x => x.NormalizedName.Contains(normalizedSearch));
        }

        if (sqlInstanceId.HasValue)
        {
            query = query.Where(x => x.SqlInstanceId == sqlInstanceId.Value);
        }

        if (!string.IsNullOrWhiteSpace(status))
        {
            var normalizedStatus = SqlInventoryNormalizer.NormalizeDatabaseStatus(status);
            query = query.Where(x => x.Status == normalizedStatus);
        }

        var totalCount = await query.CountAsync(cancellationToken);
        var entities = await query
            .Include(x => x.SqlInstance)
            .OrderBy(x => x.NormalizedName)
            .ThenBy(x => x.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);
        return new PagedResult<SqlDatabaseDto>(entities.Select(Map).ToList(), page, pageSize, totalCount);
    }

    public async Task<SqlDatabaseDto> GetDatabaseAsync(Guid id, CancellationToken cancellationToken)
    {
        await EnsureCurrentProjectAsync(cancellationToken);
        return Map(await FindDatabaseAsync(id, tracking: false, cancellationToken));
    }

    public async Task<SqlDatabaseDto> CreateDatabaseAsync(
        SqlDatabaseWriteV1 request,
        CancellationToken cancellationToken)
    {
        await EnsureCurrentProjectAsync(cancellationToken);
        var values = Validate(request);
        var instance = await RequireInstanceAsync(request.SqlInstanceId, cancellationToken);
        await EnsureDatabaseNameAvailableAsync(instance.Id, values.NormalizedName, null, cancellationToken);

        var now = Now;
        var actor = Actor;
        var entity = new SqlDatabase
        {
            Id = Guid.NewGuid(),
            CustomerId = context.CustomerId,
            ProjectId = context.ProjectId,
            SqlInstanceId = instance.Id,
            Name = values.DisplayName,
            NormalizedName = values.NormalizedName,
            SizeMb = request.SizeMb,
            CompatibilityLevel = request.CompatibilityLevel,
            RecoveryModel = values.RecoveryModel,
            Collation = values.Collation,
            Status = values.Status,
            CreatedAt = now,
            UpdatedAt = now,
            CreatedBy = actor,
            UpdatedBy = actor,
            RowVersion = NewVersion(),
            SqlInstance = instance
        };
        db.SqlDatabases.Add(entity);
        AddAudit("SqlDatabase", entity.Id, "SqlDatabaseCreated");
        await SaveAsync(cancellationToken);
        return Map(entity);
    }

    public async Task<SqlDatabaseDto> UpdateDatabaseAsync(
        Guid id,
        SqlDatabaseWriteV1 request,
        string? ifMatch,
        CancellationToken cancellationToken)
    {
        await EnsureCurrentProjectAsync(cancellationToken);
        var entity = await FindDatabaseAsync(id, tracking: true, cancellationToken);
        EnsureIfMatch(ifMatch, entity.RowVersion);
        var values = Validate(request);
        var instance = await RequireInstanceAsync(request.SqlInstanceId, cancellationToken);
        await EnsureDatabaseNameAvailableAsync(instance.Id, values.NormalizedName, id, cancellationToken);

        var originalVersion = entity.RowVersion.ToArray();
        var changed = false;
        if (entity.SqlInstanceId != instance.Id)
        {
            AddAudit(
                "SqlDatabase",
                entity.Id,
                "SqlDatabaseRelationshipChanged",
                "SqlInstanceId",
                entity.SqlInstanceId,
                instance.Id);
            changed = true;
        }

        changed |= AuditChange("SqlDatabase", entity.Id, "SqlDatabaseUpdated", "Name", entity.Name, values.DisplayName);
        changed |= AuditChange("SqlDatabase", entity.Id, "SqlDatabaseUpdated", "SizeMb", entity.SizeMb, request.SizeMb);
        changed |= AuditChange(
            "SqlDatabase",
            entity.Id,
            "SqlDatabaseUpdated",
            "CompatibilityLevel",
            entity.CompatibilityLevel,
            request.CompatibilityLevel);
        changed |= AuditChange("SqlDatabase", entity.Id, "SqlDatabaseUpdated", "RecoveryModel", entity.RecoveryModel, values.RecoveryModel);
        changed |= AuditChange("SqlDatabase", entity.Id, "SqlDatabaseUpdated", "Collation", entity.Collation, values.Collation);
        changed |= AuditChange("SqlDatabase", entity.Id, "SqlDatabaseUpdated", "Status", entity.Status, values.Status);

        entity.SqlInstanceId = instance.Id;
        entity.SqlInstance = instance;
        entity.Name = values.DisplayName;
        entity.NormalizedName = values.NormalizedName;
        entity.SizeMb = request.SizeMb;
        entity.CompatibilityLevel = request.CompatibilityLevel;
        entity.RecoveryModel = values.RecoveryModel;
        entity.Collation = values.Collation;
        entity.Status = values.Status;
        if (changed)
        {
            entity.UpdatedAt = Now;
            entity.UpdatedBy = Actor;
            RotateVersion(entity, originalVersion);
            await SaveAsync(cancellationToken);
        }

        return Map(entity);
    }

    public async Task ArchiveDatabaseAsync(Guid id, string? ifMatch, CancellationToken cancellationToken)
    {
        await EnsureCurrentProjectAsync(cancellationToken);
        var entity = await FindDatabaseAsync(id, tracking: true, cancellationToken);
        EnsureIfMatch(ifMatch, entity.RowVersion);
        var originalVersion = entity.RowVersion.ToArray();
        entity.IsDeleted = true;
        entity.DeletedAt = Now;
        entity.DeletedBy = Actor;
        entity.UpdatedAt = entity.DeletedAt.Value;
        entity.UpdatedBy = Actor;
        RotateVersion(entity, originalVersion);
        AddAudit("SqlDatabase", entity.Id, "SqlDatabaseArchived");
        await SaveAsync(cancellationToken);
    }

    private DateTimeOffset Now => timeProvider.GetUtcNow();

    private string Actor => SqlInventoryNormalizer.RequiredDisplayValue(context.UserName, 200, "Current actor");

    private async Task EnsureCurrentProjectAsync(CancellationToken cancellationToken)
    {
        if (!await db.Projects.AsNoTracking().AnyAsync(
                x => x.Id == context.ProjectId && x.CustomerId == context.CustomerId,
                cancellationToken))
        {
            throw new KeyNotFoundException("Project not found.");
        }
    }

    private async Task<Server> RequireServerAsync(Guid id, CancellationToken cancellationToken)
    {
        if (id == Guid.Empty)
        {
            throw new DomainValidationException("ServerId is required.");
        }

        return await db.Servers.SingleOrDefaultAsync(
                   x => x.Id == id && x.ProjectId == context.ProjectId,
                   cancellationToken)
               ?? throw new KeyNotFoundException("Server not found.");
    }

    private async Task<SqlInstance> RequireInstanceAsync(Guid id, CancellationToken cancellationToken)
    {
        if (id == Guid.Empty)
        {
            throw new DomainValidationException("SqlInstanceId is required.");
        }

        return await db.SqlInstances.SingleOrDefaultAsync(
                   x => x.Id == id && x.ProjectId == context.ProjectId,
                   cancellationToken)
               ?? throw new KeyNotFoundException("SQL instance not found.");
    }

    private async Task<SqlInstance> FindInstanceAsync(
        Guid id,
        bool tracking,
        CancellationToken cancellationToken)
    {
        var query = db.SqlInstances.Include(x => x.Server).Where(x => x.ProjectId == context.ProjectId);
        if (!tracking)
        {
            query = query.AsNoTracking();
        }

        return await query.SingleOrDefaultAsync(x => x.Id == id, cancellationToken)
               ?? throw new KeyNotFoundException("SQL instance not found.");
    }

    private async Task<SqlDatabase> FindDatabaseAsync(
        Guid id,
        bool tracking,
        CancellationToken cancellationToken)
    {
        var query = db.SqlDatabases.Include(x => x.SqlInstance).Where(x => x.ProjectId == context.ProjectId);
        if (!tracking)
        {
            query = query.AsNoTracking();
        }

        return await query.SingleOrDefaultAsync(x => x.Id == id, cancellationToken)
               ?? throw new KeyNotFoundException("SQL database not found.");
    }

    private async Task EnsureInstanceNameAvailableAsync(
        Guid serverId,
        string normalizedName,
        Guid? excludedId,
        CancellationToken cancellationToken)
    {
        if (await db.SqlInstances.AnyAsync(
                x => x.ProjectId == context.ProjectId
                     && x.ServerId == serverId
                     && x.NormalizedInstanceName == normalizedName
                     && (!excludedId.HasValue || x.Id != excludedId.Value),
                cancellationToken))
        {
            throw new DomainConflictException("An active SQL instance with the same normalized name already exists on this server.");
        }
    }

    private async Task EnsureDatabaseNameAvailableAsync(
        Guid sqlInstanceId,
        string normalizedName,
        Guid? excludedId,
        CancellationToken cancellationToken)
    {
        if (await db.SqlDatabases.AnyAsync(
                x => x.ProjectId == context.ProjectId
                     && x.SqlInstanceId == sqlInstanceId
                     && x.NormalizedName == normalizedName
                     && (!excludedId.HasValue || x.Id != excludedId.Value),
                cancellationToken))
        {
            throw new DomainConflictException("An active SQL database with the same normalized name already exists on this instance.");
        }
    }

    private static InstanceValues Validate(SqlInstanceWriteV1 request)
    {
        var displayName = SqlInventoryNormalizer.RequiredDisplayValue(request.InstanceName, 128, "Instance name");
        if (request.Port is < 1 or > 65535)
        {
            throw new DomainValidationException("Port must be between 1 and 65535 when supplied.");
        }

        return new InstanceValues(
            displayName,
            SqlInventoryNormalizer.NormalizeInstanceName(displayName),
            SqlInventoryNormalizer.RequiredDisplayValue(request.SqlVersion, 100, "SQL version"),
            SqlInventoryNormalizer.RequiredDisplayValue(request.Edition, 100, "Edition"),
            SqlInventoryNormalizer.NormalizeServiceStatus(request.ServiceStatus),
            SqlInventoryNormalizer.NormalizeServiceAccountName(request.ServiceAccountName));
    }

    private static DatabaseValues Validate(SqlDatabaseWriteV1 request)
    {
        var displayName = SqlInventoryNormalizer.RequiredDisplayValue(request.Name, 128, "Database name");
        if (request.SizeMb < 0)
        {
            throw new DomainValidationException("SizeMb cannot be negative.");
        }

        if (request.CompatibilityLevel is < 80 or > 200)
        {
            throw new DomainValidationException("CompatibilityLevel must be between 80 and 200.");
        }

        return new DatabaseValues(
            displayName,
            SqlInventoryNormalizer.NormalizeDatabaseName(displayName),
            SqlInventoryNormalizer.NormalizeRecoveryModel(request.RecoveryModel),
            SqlInventoryNormalizer.NormalizeOptionalDisplayValue(request.Collation, 128, "Collation"),
            SqlInventoryNormalizer.NormalizeDatabaseStatus(request.Status));
    }

    private void AddAudit(
        string entityType,
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
            EntityType = entityType,
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

    private bool AuditChange(
        string entityType,
        Guid entityId,
        string action,
        string propertyName,
        object? oldValue,
        object? newValue)
    {
        if (Equals(oldValue, newValue))
        {
            return false;
        }

        AddAudit(entityType, entityId, action, propertyName, oldValue, newValue);
        return true;
    }

    private static string? AuditValue(object? value) => value switch
    {
        null => null,
        DateTimeOffset timestamp => timestamp.ToUniversalTime().ToString("O", CultureInfo.InvariantCulture),
        IFormattable formattable => formattable.ToString(null, CultureInfo.InvariantCulture),
        _ => value.ToString()
    };

    private static string? Redacted(string? value) => value is null ? null : "[REDACTED]";

    private static byte[] NewVersion() => RandomNumberGenerator.GetBytes(8);

    private void RotateVersion(SqlInstance entity, byte[] originalVersion)
    {
        entity.RowVersion = NewVersion();
        db.Entry(entity).Property(x => x.RowVersion).OriginalValue = originalVersion;
    }

    private void RotateVersion(SqlDatabase entity, byte[] originalVersion)
    {
        entity.RowVersion = NewVersion();
        db.Entry(entity).Property(x => x.RowVersion).OriginalValue = originalVersion;
    }

    private static void EnsureIfMatch(string? ifMatch, byte[] rowVersion)
    {
        if (string.IsNullOrWhiteSpace(ifMatch))
        {
            throw new PreconditionRequiredException("If-Match is required for updates and deletes.");
        }

        var expected = ToEntityTag(rowVersion);
        var suppliedTags = ifMatch.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        if (!suppliedTags.Contains(expected, StringComparer.Ordinal))
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

    public static string ToEntityTag(byte[] rowVersion) => $"\"{Convert.ToBase64String(rowVersion)}\"";

    private static SqlInstanceDto Map(SqlInstance entity) => new(
        entity.Id,
        entity.CustomerId,
        entity.ProjectId,
        new NamedReferenceDto(entity.ServerId, entity.Server.Hostname),
        entity.InstanceName,
        entity.SqlVersion,
        entity.Edition,
        entity.Port,
        entity.ServiceStatus,
        entity.DiscoverySource,
        entity.ServiceAccountName,
        entity.LastDiscoveredAt,
        entity.LastImportBatchId,
        entity.LastImportedAt,
        entity.CreatedAt,
        entity.UpdatedAt,
        entity.CreatedBy,
        entity.UpdatedBy,
        Convert.ToBase64String(entity.RowVersion));

    private static SqlDatabaseDto Map(SqlDatabase entity) => new(
        entity.Id,
        entity.CustomerId,
        entity.ProjectId,
        new NamedReferenceDto(entity.SqlInstanceId, entity.SqlInstance.InstanceName),
        entity.Name,
        entity.SizeMb,
        entity.CompatibilityLevel,
        entity.RecoveryModel,
        entity.Collation,
        entity.Status,
        entity.LastImportBatchId,
        entity.LastImportedAt,
        entity.CreatedAt,
        entity.UpdatedAt,
        entity.CreatedBy,
        entity.UpdatedBy,
        Convert.ToBase64String(entity.RowVersion));

    private sealed record InstanceValues(
        string DisplayName,
        string NormalizedName,
        string SqlVersion,
        string Edition,
        string ServiceStatus,
        string? ServiceAccountName);

    private sealed record DatabaseValues(
        string DisplayName,
        string NormalizedName,
        string RecoveryModel,
        string? Collation,
        string Status);
}
