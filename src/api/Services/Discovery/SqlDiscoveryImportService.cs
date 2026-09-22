using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Domain;
using LgrTransformationMigration.Api.Infrastructure;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace LgrTransformationMigration.Api.Services.Discovery;

public sealed class SqlDiscoveryImportService(
    AppDbContext db,
    ICurrentCustomerContext context,
    IProjectAuthorizationContextAccessor authorizationContextAccessor,
    IImportFileStorage fileStorage,
    IDiscoveryFileReader fileReader,
    SqlDiscoveryCsvContract contract,
    TimeProvider timeProvider,
    IOptions<DiscoveryImportOptions> options,
    IOptionsSnapshot<FeatureOptions> featureOptions,
    IHostEnvironment environment)
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
    private const int MaximumIdempotencyKeyLength = 200;
    private DateTimeOffset Now => timeProvider.GetUtcNow();

    public async Task<DiscoveryImportBatchDto> UploadAsync(
        IFormFile file,
        string sourceType,
        CancellationToken cancellationToken)
    {
        EnsureEnabled();
        sourceType = NormalizeSourceType(sourceType);
        if (!await db.Projects.AsNoTracking().AnyAsync(
                project => project.Id == context.ProjectId && project.CustomerId == context.CustomerId,
                cancellationToken))
        {
            throw new KeyNotFoundException("Project not found.");
        }

        if (file is null || file.Length == 0)
        {
            throw new DomainValidationException("Select a non-empty SQL discovery file.");
        }

        var originalFileName = Path.GetFileName(file.FileName);
        if (string.IsNullOrWhiteSpace(originalFileName))
        {
            originalFileName = "sql-discovery.csv";
        }

        var extension = Path.GetExtension(originalFileName);
        if (!extension.Equals(".csv", StringComparison.OrdinalIgnoreCase))
        {
            throw new UnsupportedMediaTypeException("Only .csv SQL discovery files are supported.");
        }

        if (file.Length > options.Value.MaximumFileSizeBytes)
        {
            throw new PayloadTooLargeException("The SQL discovery file exceeds the configured size limit.");
        }

        StoredImportFile stored;
        await using (var upload = file.OpenReadStream())
        {
            stored = await fileStorage.SaveAsync(
                upload,
                extension,
                options.Value.MaximumFileSizeBytes,
                cancellationToken);
        }

        try
        {
            await using var stream = await fileStorage.OpenReadAsync(stored.StoredFileName, cancellationToken);
            var document = await fileReader.ReadAsync(stream, cancellationToken);
            contract.ValidateHeaders(sourceType, document.Headers);
            if (document.Rows.Count == 0)
            {
                throw new UnsupportedSourceContractException("The SQL discovery file contains no data rows.");
            }

            var repeated = await db.ImportBatches.AsNoTracking().AnyAsync(
                batch => batch.ProjectId == context.ProjectId
                         && batch.FileHash == stored.FileHash
                         && batch.SourceType == sourceType,
                cancellationToken);
            var batch = new ImportBatch
            {
                Id = Guid.NewGuid(),
                CustomerId = context.CustomerId,
                ProjectId = context.ProjectId,
                SourceType = sourceType,
                OriginalFileName = originalFileName,
                StoredFileName = stored.StoredFileName,
                FileHash = stored.FileHash,
                FileSizeBytes = stored.FileSizeBytes,
                Status = ImportBatchStatuses.Uploaded,
                UploadedBy = Actor,
                UploadedAt = Now,
                Notes = repeated ? "The same file content was uploaded previously in this project." : null,
                RowVersion = NewVersion()
            };
            db.ImportBatches.Add(batch);
            AddAudit("ImportBatch", batch.Id, "SqlDiscoveryImportUploaded", batch.UploadedAt);
            await db.SaveChangesAsync(cancellationToken);
            return Map(batch);
        }
        catch
        {
            await fileStorage.DeleteAsync(stored.StoredFileName, cancellationToken);
            throw;
        }
    }

    public async Task<PagedResult<DiscoveryImportBatchDto>> ListAsync(
        int page,
        int pageSize,
        CancellationToken cancellationToken)
    {
        EnsureEnabled();
        var query = db.ImportBatches.AsNoTracking().Where(
            batch => batch.ProjectId == context.ProjectId
                     && (batch.SourceType == DiscoverySourceTypes.SqlInstanceCsvV1
                         || batch.SourceType == DiscoverySourceTypes.SqlDatabaseCsvV1));
        var total = await query.CountAsync(cancellationToken);
        var batches = await query.OrderByDescending(batch => batch.UploadedAt)
            .ThenBy(batch => batch.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);
        return new PagedResult<DiscoveryImportBatchDto>(batches.Select(Map).ToList(), page, pageSize, total);
    }

    public async Task<DiscoveryImportBatchDto> GetAsync(Guid id, CancellationToken cancellationToken)
    {
        EnsureEnabled();
        return Map(await FindBatchAsync(id, tracking: false, cancellationToken));
    }

    public async Task<DiscoveryImportBatchDto> PreviewAsync(
        Guid id,
        string? ifMatch,
        CancellationToken cancellationToken)
    {
        EnsureEnabled();
        var batch = await FindBatchAsync(id, tracking: true, cancellationToken);
        EnsureIfMatch(ifMatch, batch.RowVersion);
        if (batch.Status is not (ImportBatchStatuses.Uploaded or ImportBatchStatuses.PreviewReady))
        {
            throw new DomainConflictException("The SQL discovery batch cannot be previewed in its current state.");
        }

        if (string.IsNullOrWhiteSpace(batch.StoredFileName))
        {
            throw new DomainConflictException("The SQL discovery source file is not available.");
        }

        await using var stream = await fileStorage.OpenReadAsync(batch.StoredFileName, cancellationToken);
        var document = await fileReader.ReadAsync(stream, cancellationToken);
        var unknownHeaders = contract.ValidateHeaders(batch.SourceType, document.Headers);
        if (unknownHeaders.Count > 0
            && !(batch.Notes?.Contains("unsupported extra columns", StringComparison.Ordinal) ?? false))
        {
            batch.Notes = AppendSafeNote(
                batch.Notes,
                "The file contains unsupported extra columns retained only as staged source evidence.");
        }
        var repeated = await db.ImportBatches.AsNoTracking().AnyAsync(
            candidate => candidate.ProjectId == context.ProjectId
                         && candidate.Id != batch.Id
                         && candidate.FileHash == batch.FileHash
                         && candidate.SourceType == batch.SourceType,
            cancellationToken);
        var validatedRows = document.Rows
            .Select(row => contract.Validate(batch.SourceType, row, unknownHeaders, repeated))
            .ToList();
        MarkDuplicateBusinessKeys(validatedRows);

        var servers = await db.Servers.AsNoTracking()
            .Where(server => server.ProjectId == context.ProjectId)
            .ToListAsync(cancellationToken);
        var instances = await db.SqlInstances.AsNoTracking()
            .Where(instance => instance.ProjectId == context.ProjectId)
            .ToListAsync(cancellationToken);
        var databases = await db.SqlDatabases.AsNoTracking()
            .Where(database => database.ProjectId == context.ProjectId)
            .ToListAsync(cancellationToken);

        var staged = validatedRows.Select(row => Stage(batch, row, servers, instances, databases)).ToList();
        db.DiscoveryImportRows.RemoveRange(
            db.DiscoveryImportRows.Where(row => row.ImportBatchId == batch.Id && row.ProjectId == context.ProjectId));
        db.DiscoveryImportRows.AddRange(staged);
        UpdateCounts(batch, staged);
        batch.PreviewedAt = Now;
        batch.Status = ImportBatchStatuses.PreviewReady;
        var originalVersion = batch.RowVersion.ToArray();
        RotateVersion(batch, originalVersion);
        AddAudit("ImportBatch", batch.Id, "SqlDiscoveryImportPreviewed", batch.PreviewedAt.Value);
        await SaveAsync(cancellationToken);
        return Map(batch);
    }

    public async Task<PagedResult<SqlDiscoveryImportRowDto>> ListRowsAsync(
        Guid batchId,
        int page,
        int pageSize,
        string? classification,
        CancellationToken cancellationToken)
    {
        EnsureEnabled();
        var batch = await FindBatchAsync(batchId, tracking: false, cancellationToken);
        if (!string.IsNullOrWhiteSpace(classification)
            && !ImportClassifications.All.Contains(classification, StringComparer.OrdinalIgnoreCase))
        {
            throw new DomainValidationException("The classification filter is invalid.");
        }

        var query = db.DiscoveryImportRows.AsNoTracking()
            .Where(row => row.ImportBatchId == batch.Id && row.ProjectId == context.ProjectId);
        if (!string.IsNullOrWhiteSpace(classification))
        {
            query = query.Where(row => row.Classification == classification);
        }

        var total = await query.CountAsync(cancellationToken);
        var rows = await query
            .Include(row => row.MatchedServer)
            .Include(row => row.MatchedSqlInstance)
            .Include(row => row.MatchedSqlDatabase)
            .OrderBy(row => row.RowNumber)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);
        return new PagedResult<SqlDiscoveryImportRowDto>(rows.Select(MapRow).ToList(), page, pageSize, total);
    }

    public async Task<SqlDiscoveryImportRowDetailDto> GetRowAsync(
        Guid batchId,
        Guid rowId,
        CancellationToken cancellationToken)
    {
        EnsureEnabled();
        EnsureRawRowAccess();
        var batch = await FindBatchAsync(batchId, tracking: false, cancellationToken);
        var row = await db.DiscoveryImportRows.AsNoTracking()
                      .Include(item => item.MatchedServer)
                      .Include(item => item.MatchedSqlInstance)
                      .Include(item => item.MatchedSqlDatabase)
                      .SingleOrDefaultAsync(
                          item => item.Id == rowId
                                  && item.ImportBatchId == batch.Id
                                  && item.ProjectId == context.ProjectId,
                          cancellationToken)
                  ?? throw new KeyNotFoundException("Discovery import row not found.");
        return MapRowDetail(row);
    }

    public async Task<DiscoveryImportBatchDto> CommitAsync(
        Guid id,
        string? ifMatch,
        string? idempotencyKey,
        CancellationToken cancellationToken)
    {
        EnsureEnabled();
        if (string.IsNullOrWhiteSpace(ifMatch))
        {
            throw new PreconditionRequiredException("If-Match is required to commit a SQL discovery batch.");
        }

        var idempotencyHash = HashIdempotencyKey(idempotencyKey);
        var current = await FindBatchAsync(id, tracking: true, cancellationToken);
        if (current.Status == ImportBatchStatuses.Committed)
        {
            if (CryptographicOperations.FixedTimeEquals(
                    Encoding.ASCII.GetBytes(current.CommitIdempotencyKeyHash ?? string.Empty),
                    Encoding.ASCII.GetBytes(idempotencyHash)))
            {
                return Map(current);
            }

            throw new DomainConflictException("The SQL discovery batch was already committed with another idempotency key.");
        }

        EnsureIfMatch(ifMatch, current.RowVersion);
        if (current.Status != ImportBatchStatuses.PreviewReady || current.ValidRows == 0)
        {
            throw new DomainConflictException("The SQL discovery batch is not ready to commit.");
        }

        if (await db.ImportBatches.AsNoTracking().AnyAsync(
                batch => batch.ProjectId == context.ProjectId
                         && batch.Id != current.Id
                         && batch.CommitIdempotencyKeyHash == idempotencyHash,
                cancellationToken))
        {
            throw new DomainConflictException("The idempotency key was already used for another request.");
        }

        await using var transaction = await db.Database.BeginTransactionAsync(cancellationToken);
        try
        {
            var originalVersion = current.RowVersion.ToArray();
            current.Status = ImportBatchStatuses.Committing;
            RotateVersion(current, originalVersion);
            await SaveAsync(cancellationToken);

            var rows = await db.DiscoveryImportRows.AsNoTracking()
                .Where(row => row.ImportBatchId == current.Id && row.ProjectId == context.ProjectId)
                .OrderBy(row => row.RowNumber)
                .ToListAsync(cancellationToken);
            var servers = await db.Servers.Where(server => server.ProjectId == context.ProjectId)
                .ToListAsync(cancellationToken);
            var instances = await db.SqlInstances.Where(instance => instance.ProjectId == context.ProjectId)
                .ToListAsync(cancellationToken);
            var databases = await db.SqlDatabases.Where(database => database.ProjectId == context.ProjectId)
                .ToListAsync(cancellationToken);
            var now = Now;

            foreach (var staged in rows.Where(row => row.Classification != ImportClassifications.Reject))
            {
                var raw = DeserializeRaw(staged.RawDataJson);
                var validated = contract.Validate(
                    current.SourceType,
                    new CsvDataRow(staged.RowNumber, raw),
                    [],
                    repeatFileHash: false);
                var resolution = Resolve(validated, servers, instances, databases);
                if (validated.HasErrors || resolution.Error is not null)
                {
                    throw new StaleVersionException("The SQL discovery preview is no longer current.");
                }

                var changes = BuildChanges(validated, resolution.Instance, resolution.Database);
                var proposedAction = ActionFor(validated.Kind, resolution.Instance, resolution.Database, changes);
                var fingerprint = Fingerprint(validated, resolution.Server, resolution.Instance, resolution.Database, changes);
                if (!string.Equals(fingerprint, staged.ReconciliationFingerprint, StringComparison.Ordinal)
                    || !string.Equals(proposedAction, staged.ProposedAction, StringComparison.Ordinal))
                {
                    throw new StaleVersionException("The SQL discovery preview is no longer current.");
                }

                if (validated.Kind == SqlDiscoveryRowKind.Instance)
                {
                    var instance = ApplyInstance(current, validated, resolution.Server!, resolution.Instance, changes, now);
                    if (resolution.Instance is null)
                    {
                        instances.Add(instance);
                    }

                    db.SqlInstanceDiscoverySnapshots.Add(CreateInstanceSnapshot(current, instance, validated, now));
                }
                else
                {
                    var database = ApplyDatabase(current, validated, resolution.Instance!, resolution.Database, changes, now);
                    if (resolution.Database is null)
                    {
                        databases.Add(database);
                    }

                    db.SqlDatabaseDiscoverySnapshots.Add(CreateDatabaseSnapshot(current, database, validated, now));
                }
            }

            current.Status = ImportBatchStatuses.Committed;
            current.CommittedAt = now;
            current.CommitIdempotencyKeyHash = idempotencyHash;
            current.CommitResultJson = JsonSerializer.Serialize(
                new
                {
                    current.TotalRows,
                    current.ValidRows,
                    current.CreateCount,
                    current.UpdateCount,
                    current.UnchangedCount,
                    current.WarningCount,
                    current.RejectCount
                },
                JsonOptions);
            RotateVersion(current, current.RowVersion.ToArray());
            AddAudit("ImportBatch", current.Id, "SqlDiscoveryImportCommitted", now);
            await SaveAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
            return Map(current);
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            db.ChangeTracker.Clear();
            var failed = await FindBatchAsync(id, tracking: true, cancellationToken);
            if (failed.Status == ImportBatchStatuses.PreviewReady)
            {
                failed.Notes = AppendSafeNote(failed.Notes, "The previous commit attempt failed safely; preview again before retrying.");
                RotateVersion(failed, failed.RowVersion.ToArray());
                await SaveAsync(cancellationToken);
            }

            throw;
        }
    }

    public async Task<DiscoveryImportBatchDto> CancelAsync(
        Guid id,
        string? ifMatch,
        CancellationToken cancellationToken)
    {
        EnsureEnabled();
        var batch = await FindBatchAsync(id, tracking: true, cancellationToken);
        EnsureIfMatch(ifMatch, batch.RowVersion);
        if (batch.Status is not (ImportBatchStatuses.Uploaded or ImportBatchStatuses.PreviewReady))
        {
            throw new DomainConflictException("The SQL discovery batch cannot be cancelled in its current state.");
        }

        batch.Status = ImportBatchStatuses.Cancelled;
        RotateVersion(batch, batch.RowVersion.ToArray());
        AddAudit("ImportBatch", batch.Id, "SqlDiscoveryImportCancelled", Now);
        await SaveAsync(cancellationToken);
        return Map(batch);
    }

    public async Task<PagedResult<SqlInstanceDiscoverySnapshotDto>> GetInstanceHistoryAsync(
        Guid instanceId,
        int page,
        int pageSize,
        CancellationToken cancellationToken)
    {
        EnsureEnabled();
        if (!await db.SqlInstances.AsNoTracking().AnyAsync(
                instance => instance.Id == instanceId && instance.ProjectId == context.ProjectId,
                cancellationToken))
        {
            throw new KeyNotFoundException("SQL instance not found.");
        }

        var query = db.SqlInstanceDiscoverySnapshots.AsNoTracking().Where(
            snapshot => snapshot.SqlInstanceId == instanceId && snapshot.ProjectId == context.ProjectId);
        var total = await query.CountAsync(cancellationToken);
        List<SqlInstanceDiscoverySnapshot> snapshots;
        if (db.Database.IsSqlServer())
        {
            snapshots = await query.Include(snapshot => snapshot.ImportBatch)
                .OrderByDescending(snapshot => snapshot.ImportedAt)
                .ThenBy(snapshot => snapshot.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);
        }
        else
        {
            snapshots = (await query.Include(snapshot => snapshot.ImportBatch).ToListAsync(cancellationToken))
                .OrderByDescending(snapshot => snapshot.ImportedAt)
                .ThenBy(snapshot => snapshot.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList();
        }

        var items = snapshots.Select(snapshot => new SqlInstanceDiscoverySnapshotDto(
            snapshot.Id,
            snapshot.ImportBatchId,
            snapshot.ImportBatch.SourceType,
            snapshot.ServerId,
            snapshot.InstanceName,
            snapshot.SqlVersion,
            snapshot.Edition,
            snapshot.Port,
            snapshot.ServiceStatus,
            snapshot.DiscoverySource,
            snapshot.LastDiscoveredAt,
            snapshot.ImportedAt)).ToList();
        return new PagedResult<SqlInstanceDiscoverySnapshotDto>(items, page, pageSize, total);
    }

    public async Task<PagedResult<SqlDatabaseDiscoverySnapshotDto>> GetDatabaseHistoryAsync(
        Guid databaseId,
        int page,
        int pageSize,
        CancellationToken cancellationToken)
    {
        EnsureEnabled();
        if (!await db.SqlDatabases.AsNoTracking().AnyAsync(
                database => database.Id == databaseId && database.ProjectId == context.ProjectId,
                cancellationToken))
        {
            throw new KeyNotFoundException("SQL database not found.");
        }

        var query = db.SqlDatabaseDiscoverySnapshots.AsNoTracking().Where(
            snapshot => snapshot.SqlDatabaseId == databaseId && snapshot.ProjectId == context.ProjectId);
        var total = await query.CountAsync(cancellationToken);
        List<SqlDatabaseDiscoverySnapshot> snapshots;
        if (db.Database.IsSqlServer())
        {
            snapshots = await query.Include(snapshot => snapshot.ImportBatch)
                .OrderByDescending(snapshot => snapshot.ImportedAt)
                .ThenBy(snapshot => snapshot.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);
        }
        else
        {
            snapshots = (await query.Include(snapshot => snapshot.ImportBatch).ToListAsync(cancellationToken))
                .OrderByDescending(snapshot => snapshot.ImportedAt)
                .ThenBy(snapshot => snapshot.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList();
        }

        var items = snapshots.Select(snapshot => new SqlDatabaseDiscoverySnapshotDto(
            snapshot.Id,
            snapshot.ImportBatchId,
            snapshot.ImportBatch.SourceType,
            snapshot.SqlInstanceId,
            snapshot.Name,
            snapshot.SizeMb,
            snapshot.CompatibilityLevel,
            snapshot.RecoveryModel,
            snapshot.Collation,
            snapshot.Status,
            snapshot.ImportedAt)).ToList();
        return new PagedResult<SqlDatabaseDiscoverySnapshotDto>(items, page, pageSize, total);
    }

    private DiscoveryImportRow Stage(
        ImportBatch batch,
        ValidatedSqlDiscoveryRow validated,
        IReadOnlyCollection<Server> servers,
        IReadOnlyCollection<SqlInstance> instances,
        IReadOnlyCollection<SqlDatabase> databases)
    {
        var resolution = Resolve(validated, servers, instances, databases);
        var messages = validated.Messages.ToList();
        if (resolution.Error is not null)
        {
            messages.Add(new DiscoveryValidationMessageDto(ValidationSeverities.Error, "Parent", resolution.Error));
        }

        var effective = validated with { Messages = messages };
        var changes = BuildChanges(effective, resolution.Instance, resolution.Database);
        var action = effective.HasErrors ? null : ActionFor(effective.Kind, resolution.Instance, resolution.Database, changes);
        var classification = effective.HasErrors
            ? ImportClassifications.Reject
            : effective.HasWarnings ? ImportClassifications.Warning : action!;
        return new DiscoveryImportRow
        {
            Id = Guid.NewGuid(),
            CustomerId = batch.CustomerId,
            ProjectId = batch.ProjectId,
            ImportBatchId = batch.Id,
            RowNumber = effective.RowNumber,
            SourceType = batch.SourceType,
            RawDataJson = JsonSerializer.Serialize(SanitizeRaw(effective.RawData), JsonOptions),
            NormalizedHostname = effective.NormalizedHostname,
            NormalizedInstanceName = effective.NormalizedInstanceName,
            NormalizedDatabaseName = effective.NormalizedDatabaseName,
            Classification = classification,
            ProposedAction = action,
            ValidationStatus = effective.HasErrors
                ? ImportValidationStatuses.Invalid
                : effective.HasWarnings ? ImportValidationStatuses.Warning : ImportValidationStatuses.Valid,
            ValidationMessagesJson = messages.Count == 0 ? null : JsonSerializer.Serialize(messages, JsonOptions),
            MatchedEntityId = resolution.Server?.Id,
            MatchedSqlInstanceId = resolution.Instance?.Id,
            MatchedSqlDatabaseId = resolution.Database?.Id,
            ReconciliationFingerprint = effective.HasErrors
                ? null
                : Fingerprint(effective, resolution.Server, resolution.Instance, resolution.Database, changes),
            ProposedChangesJson = changes.Count == 0 ? null : JsonSerializer.Serialize(changes, JsonOptions),
            CreatedAt = Now
        };
    }

    private static Resolution Resolve(
        ValidatedSqlDiscoveryRow row,
        IReadOnlyCollection<Server> servers,
        IReadOnlyCollection<SqlInstance> instances,
        IReadOnlyCollection<SqlDatabase> databases)
    {
        if (row.HasErrors || row.NormalizedHostname is null || row.NormalizedInstanceName is null)
        {
            return new Resolution(null, null, null, null);
        }

        var serverMatches = servers.Where(
            server => NormalizeHostname(server.Hostname) == row.NormalizedHostname).ToList();
        if (serverMatches.Count != 1)
        {
            return new Resolution(null, null, null,
                serverMatches.Count == 0
                    ? "The server was not found in the current project."
                    : "The server identity is ambiguous in the current project.");
        }

        var server = serverMatches[0];
        var instanceMatches = instances.Where(
            instance => instance.ServerId == server.Id
                        && instance.NormalizedInstanceName == row.NormalizedInstanceName).ToList();
        if (instanceMatches.Count > 1)
        {
            return new Resolution(server, null, null, "The SQL instance identity is ambiguous in the current project.");
        }

        var instance = instanceMatches.SingleOrDefault();
        if (row.Kind == SqlDiscoveryRowKind.Instance)
        {
            return new Resolution(server, instance, null, null);
        }

        if (instance is null)
        {
            return new Resolution(server, null, null, "The SQL instance was not found in the current project.");
        }

        var databaseMatches = databases.Where(
            database => database.SqlInstanceId == instance.Id
                        && database.NormalizedName == row.NormalizedDatabaseName).ToList();
        return databaseMatches.Count switch
        {
            0 => new Resolution(server, instance, null, null),
            1 => new Resolution(server, instance, databaseMatches[0], null),
            _ => new Resolution(server, instance, null, "The SQL database identity is ambiguous in the current project.")
        };
    }

    private static IReadOnlyList<DiscoveryFieldChangeDto> BuildChanges(
        ValidatedSqlDiscoveryRow row,
        SqlInstance? instance,
        SqlDatabase? database)
    {
        var changes = new List<DiscoveryFieldChangeDto>();
        if (row.Kind == SqlDiscoveryRowKind.Instance && instance is not null)
        {
            Add(changes, "InstanceName", instance.InstanceName, row.InstanceName);
            Add(changes, "SqlVersion", instance.SqlVersion, row.SqlVersion);
            Add(changes, "Edition", instance.Edition, row.Edition);
            if (row.PortSupplied) Add(changes, "Port", Format(instance.Port), Format(row.Port));
            Add(changes, "ServiceStatus", instance.ServiceStatus, row.ServiceStatus);
            Add(changes, "DiscoverySource", instance.DiscoverySource, row.DiscoverySource);
            if (row.LastDiscoveredAtSupplied)
                Add(changes, "LastDiscoveredAt", Format(instance.LastDiscoveredAt), Format(row.LastDiscoveredAt));
        }
        else if (row.Kind == SqlDiscoveryRowKind.Database && database is not null)
        {
            Add(changes, "Name", database.Name, row.DatabaseName);
            Add(changes, "SizeMb", Format(database.SizeMb), Format(row.SizeMb));
            Add(changes, "CompatibilityLevel", Format(database.CompatibilityLevel), Format(row.CompatibilityLevel));
            Add(changes, "RecoveryModel", database.RecoveryModel, row.RecoveryModel);
            if (row.CollationSupplied) Add(changes, "Collation", database.Collation, row.Collation);
            Add(changes, "Status", database.Status, row.DatabaseStatus);
        }

        return changes;
    }

    private SqlInstance ApplyInstance(
        ImportBatch batch,
        ValidatedSqlDiscoveryRow row,
        Server server,
        SqlInstance? instance,
        IReadOnlyList<DiscoveryFieldChangeDto> changes,
        DateTimeOffset now)
    {
        if (instance is null)
        {
            instance = new SqlInstance
            {
                Id = Guid.NewGuid(),
                CustomerId = batch.CustomerId,
                ProjectId = batch.ProjectId,
                ServerId = server.Id,
                InstanceName = row.InstanceName!,
                NormalizedInstanceName = row.NormalizedInstanceName!,
                SqlVersion = row.SqlVersion!,
                Edition = row.Edition!,
                Port = row.Port,
                ServiceStatus = row.ServiceStatus!,
                DiscoverySource = row.DiscoverySource!,
                LastDiscoveredAt = row.LastDiscoveredAt,
                LastImportBatchId = batch.Id,
                LastImportedAt = now,
                CreatedAt = now,
                UpdatedAt = now,
                CreatedBy = Actor,
                UpdatedBy = Actor,
                RowVersion = NewVersion()
            };
            db.SqlInstances.Add(instance);
            AddAudit("SqlInstance", instance.Id, "SqlInstanceCreatedFromDiscovery", now);
            return instance;
        }

        foreach (var change in changes)
            AddAudit("SqlInstance", instance.Id, "SqlInstanceUpdatedFromDiscovery", now, change.Field, change.OldValue, change.NewValue);
        instance.InstanceName = row.InstanceName!;
        instance.NormalizedInstanceName = row.NormalizedInstanceName!;
        instance.SqlVersion = row.SqlVersion!;
        instance.Edition = row.Edition!;
        if (row.PortSupplied) instance.Port = row.Port;
        instance.ServiceStatus = row.ServiceStatus!;
        instance.DiscoverySource = row.DiscoverySource!;
        if (row.LastDiscoveredAtSupplied) instance.LastDiscoveredAt = row.LastDiscoveredAt;
        instance.LastImportBatchId = batch.Id;
        instance.LastImportedAt = now;
        instance.UpdatedAt = now;
        instance.UpdatedBy = Actor;
        RotateVersion(instance, instance.RowVersion.ToArray());
        return instance;
    }

    private SqlDatabase ApplyDatabase(
        ImportBatch batch,
        ValidatedSqlDiscoveryRow row,
        SqlInstance parent,
        SqlDatabase? database,
        IReadOnlyList<DiscoveryFieldChangeDto> changes,
        DateTimeOffset now)
    {
        if (database is null)
        {
            database = new SqlDatabase
            {
                Id = Guid.NewGuid(),
                CustomerId = batch.CustomerId,
                ProjectId = batch.ProjectId,
                SqlInstanceId = parent.Id,
                Name = row.DatabaseName!,
                NormalizedName = row.NormalizedDatabaseName!,
                SizeMb = row.SizeMb!.Value,
                CompatibilityLevel = row.CompatibilityLevel!.Value,
                RecoveryModel = row.RecoveryModel!,
                Collation = row.Collation,
                Status = row.DatabaseStatus!,
                LastImportBatchId = batch.Id,
                LastImportedAt = now,
                CreatedAt = now,
                UpdatedAt = now,
                CreatedBy = Actor,
                UpdatedBy = Actor,
                RowVersion = NewVersion()
            };
            db.SqlDatabases.Add(database);
            AddAudit("SqlDatabase", database.Id, "SqlDatabaseCreatedFromDiscovery", now);
            return database;
        }

        foreach (var change in changes)
            AddAudit("SqlDatabase", database.Id, "SqlDatabaseUpdatedFromDiscovery", now, change.Field, change.OldValue, change.NewValue);
        database.Name = row.DatabaseName!;
        database.NormalizedName = row.NormalizedDatabaseName!;
        database.SizeMb = row.SizeMb!.Value;
        database.CompatibilityLevel = row.CompatibilityLevel!.Value;
        database.RecoveryModel = row.RecoveryModel!;
        if (row.CollationSupplied) database.Collation = row.Collation;
        database.Status = row.DatabaseStatus!;
        database.LastImportBatchId = batch.Id;
        database.LastImportedAt = now;
        database.UpdatedAt = now;
        database.UpdatedBy = Actor;
        RotateVersion(database, database.RowVersion.ToArray());
        return database;
    }

    private static SqlInstanceDiscoverySnapshot CreateInstanceSnapshot(
        ImportBatch batch,
        SqlInstance instance,
        ValidatedSqlDiscoveryRow row,
        DateTimeOffset now) => new()
        {
            Id = Guid.NewGuid(),
            CustomerId = batch.CustomerId,
            ProjectId = batch.ProjectId,
            SqlInstanceId = instance.Id,
            ImportBatchId = batch.Id,
            ServerId = instance.ServerId,
            InstanceName = row.InstanceName!,
            SqlVersion = row.SqlVersion!,
            Edition = row.Edition!,
            Port = row.Port,
            ServiceStatus = row.ServiceStatus!,
            DiscoverySource = row.DiscoverySource!,
            LastDiscoveredAt = row.LastDiscoveredAt,
            ImportedAt = now
        };

    private static SqlDatabaseDiscoverySnapshot CreateDatabaseSnapshot(
        ImportBatch batch,
        SqlDatabase database,
        ValidatedSqlDiscoveryRow row,
        DateTimeOffset now) => new()
        {
            Id = Guid.NewGuid(),
            CustomerId = batch.CustomerId,
            ProjectId = batch.ProjectId,
            SqlDatabaseId = database.Id,
            ImportBatchId = batch.Id,
            SqlInstanceId = database.SqlInstanceId,
            Name = row.DatabaseName!,
            SizeMb = row.SizeMb!.Value,
            CompatibilityLevel = row.CompatibilityLevel!.Value,
            RecoveryModel = row.RecoveryModel!,
            Collation = row.Collation,
            Status = row.DatabaseStatus!,
            ImportedAt = now
        };

    private static string ActionFor(
        SqlDiscoveryRowKind kind,
        SqlInstance? instance,
        SqlDatabase? database,
        IReadOnlyCollection<DiscoveryFieldChangeDto> changes) =>
        (kind == SqlDiscoveryRowKind.Instance ? instance is null : database is null)
            ? ImportClassifications.Create
            : changes.Count == 0 ? ImportClassifications.Unchanged : ImportClassifications.Update;

    private static string Fingerprint(
        ValidatedSqlDiscoveryRow row,
        Server? server,
        SqlInstance? instance,
        SqlDatabase? database,
        IReadOnlyCollection<DiscoveryFieldChangeDto> changes)
    {
        var source = string.Join("\u001e",
            row.Kind,
            server?.Id,
            instance?.Id,
            instance is null ? null : Convert.ToBase64String(instance.RowVersion),
            database?.Id,
            database is null ? null : Convert.ToBase64String(database.RowVersion),
            row.BusinessKey,
            string.Join("\u001d", changes.OrderBy(change => change.Field, StringComparer.Ordinal)
                .Select(change => $"{change.Field}\u001f{change.OldValue}\u001f{change.NewValue}")));
        return Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(source))).ToLowerInvariant();
    }

    private static void MarkDuplicateBusinessKeys(IReadOnlyCollection<ValidatedSqlDiscoveryRow> rows)
    {
        var duplicates = rows.Where(row => row.BusinessKey is not null)
            .GroupBy(row => row.BusinessKey!, StringComparer.Ordinal)
            .Where(group => group.Count() > 1)
            .Select(group => group.Key)
            .ToHashSet(StringComparer.Ordinal);
        foreach (var row in rows.Where(row => row.BusinessKey is not null && duplicates.Contains(row.BusinessKey)))
        {
            ((List<DiscoveryValidationMessageDto>)row.Messages).Add(
                new DiscoveryValidationMessageDto(
                    ValidationSeverities.Error,
                    "Identity",
                    "The SQL discovery business key occurs more than once in this file."));
        }
    }

    private static void UpdateCounts(ImportBatch batch, IReadOnlyCollection<DiscoveryImportRow> rows)
    {
        batch.TotalRows = rows.Count;
        batch.ValidRows = rows.Count(row => row.Classification != ImportClassifications.Reject);
        batch.CreateCount = rows.Count(row => row.Classification == ImportClassifications.Create);
        batch.UpdateCount = rows.Count(row => row.Classification == ImportClassifications.Update);
        batch.UnchangedCount = rows.Count(row => row.Classification == ImportClassifications.Unchanged);
        batch.WarningCount = rows.Count(row => row.Classification == ImportClassifications.Warning);
        batch.RejectCount = rows.Count(row => row.Classification == ImportClassifications.Reject);
    }

    private async Task<ImportBatch> FindBatchAsync(Guid id, bool tracking, CancellationToken cancellationToken)
    {
        var query = db.ImportBatches.Where(
            batch => batch.Id == id
                     && batch.ProjectId == context.ProjectId
                     && (batch.SourceType == DiscoverySourceTypes.SqlInstanceCsvV1
                         || batch.SourceType == DiscoverySourceTypes.SqlDatabaseCsvV1));
        if (!tracking) query = query.AsNoTracking();
        return await query.SingleOrDefaultAsync(cancellationToken)
               ?? throw new KeyNotFoundException("Discovery import batch not found.");
    }

    private void EnsureRawRowAccess()
    {
        var roles = authorizationContextAccessor.AuthorizationContext?.ProjectRoles;
        if (roles is null || !roles.Overlaps(["DatabaseSme", "DiscoveryAnalyst"]))
        {
            throw new DomainForbiddenException("Raw staged SQL discovery evidence is restricted.");
        }
    }

    private void EnsureEnabled()
    {
        if (!(environment.IsDevelopment() || environment.IsEnvironment("Testing"))
            || !featureOptions.Value.SqlDiscoveryAssessment
            || !featureOptions.Value.SqlDiscoveryImport)
        {
            throw new KeyNotFoundException("The requested resource was not found.");
        }
    }

    private string Actor => context.UserName;

    private void AddAudit(
        string entityType,
        Guid entityId,
        string action,
        DateTimeOffset changedAt,
        string? propertyName = null,
        string? oldValue = null,
        string? newValue = null) =>
        db.AuditEvents.Add(new AuditEvent
        {
            Id = Guid.NewGuid(),
            CustomerId = context.CustomerId,
            ProjectId = context.ProjectId,
            EntityType = entityType,
            EntityId = entityId,
            Action = action,
            PropertyName = propertyName,
            OldValue = oldValue,
            NewValue = newValue,
            ChangedBy = Actor,
            ActorPrincipalType = context.Principal.PrincipalType.ToString(),
            ChangedAt = changedAt,
            CorrelationId = context.CorrelationId
        });

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

    private static void Add(
        ICollection<DiscoveryFieldChangeDto> changes,
        string field,
        string? oldValue,
        string? newValue)
    {
        if (newValue is not null && !string.Equals(oldValue, newValue, StringComparison.Ordinal))
            changes.Add(new DiscoveryFieldChangeDto(field, oldValue, newValue));
    }

    private static string? Format(object? value) => value switch
    {
        null => null,
        DateTimeOffset timestamp => timestamp.ToUniversalTime().ToString("O", CultureInfo.InvariantCulture),
        IFormattable formattable => formattable.ToString(null, CultureInfo.InvariantCulture),
        _ => value.ToString()
    };

    private static string NormalizeHostname(string value) =>
        value.Trim().Normalize(NormalizationForm.FormC).ToUpperInvariant();

    private static string NormalizeSourceType(string sourceType) =>
        sourceType.Equals(DiscoverySourceTypes.SqlInstanceCsvV1, StringComparison.OrdinalIgnoreCase)
            ? DiscoverySourceTypes.SqlInstanceCsvV1
            : sourceType.Equals(DiscoverySourceTypes.SqlDatabaseCsvV1, StringComparison.OrdinalIgnoreCase)
                ? DiscoverySourceTypes.SqlDatabaseCsvV1
                : throw new UnsupportedSourceContractException("Select a supported SQL discovery source contract.");

    private static string HashIdempotencyKey(string? value)
    {
        var normalized = value?.Trim();
        if (string.IsNullOrWhiteSpace(normalized))
            throw new PreconditionRequiredException("Idempotency-Key is required to commit a SQL discovery batch.");
        if (normalized.Length > MaximumIdempotencyKeyLength || normalized.Any(char.IsControl))
            throw new DomainValidationException("Idempotency-Key is invalid.");
        return Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(normalized))).ToLowerInvariant();
    }

    private static void EnsureIfMatch(string? ifMatch, byte[] rowVersion)
    {
        if (string.IsNullOrWhiteSpace(ifMatch))
            throw new PreconditionRequiredException("If-Match is required for this operation.");
        var expected = ToEntityTag(rowVersion);
        if (!ifMatch.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .Contains(expected, StringComparer.Ordinal))
            throw new StaleVersionException("The resource was changed after it was retrieved.");
    }

    private void RotateVersion(ImportBatch entity, byte[] originalVersion)
    {
        if (!db.Database.IsSqlServer()) entity.RowVersion = NewVersion();
        db.Entry(entity).Property(item => item.RowVersion).OriginalValue = originalVersion;
    }

    private void RotateVersion(SqlInstance entity, byte[] originalVersion)
    {
        if (!db.Database.IsSqlServer()) entity.RowVersion = NewVersion();
        db.Entry(entity).Property(item => item.RowVersion).OriginalValue = originalVersion;
    }

    private void RotateVersion(SqlDatabase entity, byte[] originalVersion)
    {
        if (!db.Database.IsSqlServer()) entity.RowVersion = NewVersion();
        db.Entry(entity).Property(item => item.RowVersion).OriginalValue = originalVersion;
    }

    public static string ToEntityTag(byte[] rowVersion) => $"\"{Convert.ToBase64String(rowVersion)}\"";

    private static byte[] NewVersion() => RandomNumberGenerator.GetBytes(8);

    private static DiscoveryImportBatchDto Map(ImportBatch batch) => new(
        batch.Id,
        batch.CustomerId,
        batch.ProjectId,
        batch.SourceType,
        batch.OriginalFileName,
        batch.FileHash,
        batch.FileSizeBytes,
        batch.Status,
        batch.UploadedBy,
        batch.UploadedAt,
        batch.PreviewedAt,
        batch.CommittedAt,
        batch.TotalRows,
        batch.ValidRows,
        batch.CreateCount,
        batch.UpdateCount,
        batch.UnchangedCount,
        batch.WarningCount,
        batch.RejectCount,
        batch.Notes,
        batch.Notes?.StartsWith("The same file content", StringComparison.Ordinal) == true ? batch.Notes : null,
        Convert.ToBase64String(batch.RowVersion));

    private static SqlDiscoveryImportRowDto MapRow(DiscoveryImportRow row)
    {
        var raw = DeserializeRaw(row.RawDataJson).ToDictionary(
            pair => DiscoveryColumnName.Normalize(pair.Key),
            pair => pair.Value,
            StringComparer.OrdinalIgnoreCase);
        return new SqlDiscoveryImportRowDto(
            row.Id,
            row.RowNumber,
            row.SourceType,
            raw.GetValueOrDefault("server"),
            raw.GetValueOrDefault("instancename"),
            raw.GetValueOrDefault("databasename"),
            row.Classification,
            row.ProposedAction,
            row.ValidationStatus,
            row.MatchedServer is null ? null : new NamedReferenceDto(row.MatchedServer.Id, row.MatchedServer.Hostname),
            row.MatchedSqlInstance is null ? null : new NamedReferenceDto(row.MatchedSqlInstance.Id, row.MatchedSqlInstance.InstanceName),
            row.MatchedSqlDatabase is null ? null : new NamedReferenceDto(row.MatchedSqlDatabase.Id, row.MatchedSqlDatabase.Name));
    }

    private static SqlDiscoveryImportRowDetailDto MapRowDetail(DiscoveryImportRow row) => new(
        row.Id,
        row.RowNumber,
        row.SourceType,
        DeserializeRaw(row.RawDataJson),
        row.NormalizedHostname,
        row.NormalizedInstanceName,
        row.NormalizedDatabaseName,
        row.Classification,
        row.ProposedAction,
        row.ValidationStatus,
        Deserialize<DiscoveryValidationMessageDto>(row.ValidationMessagesJson),
        row.MatchedServer is null ? null : new NamedReferenceDto(row.MatchedServer.Id, row.MatchedServer.Hostname),
        row.MatchedSqlInstance is null ? null : new NamedReferenceDto(row.MatchedSqlInstance.Id, row.MatchedSqlInstance.InstanceName),
        row.MatchedSqlDatabase is null ? null : new NamedReferenceDto(row.MatchedSqlDatabase.Id, row.MatchedSqlDatabase.Name),
        Deserialize<DiscoveryFieldChangeDto>(row.ProposedChangesJson));

    private static IReadOnlyDictionary<string, string> DeserializeRaw(string json) =>
        JsonSerializer.Deserialize<Dictionary<string, string>>(json, JsonOptions)
        ?? throw new DomainConflictException("The staged SQL discovery evidence is invalid.");

    private static IReadOnlyDictionary<string, string> SanitizeRaw(IReadOnlyDictionary<string, string> raw) =>
        raw.ToDictionary(
            pair => pair.Key,
            pair => pair.Value.Length > 0
                    && new[] { "password", "secret", "credential", "token", "connectionstring", "serviceaccount" }
                        .Any(marker => DiscoveryColumnName.Normalize(pair.Key).Contains(marker, StringComparison.OrdinalIgnoreCase))
                ? "[REDACTED]"
                : pair.Value,
            StringComparer.Ordinal);

    private static IReadOnlyList<T> Deserialize<T>(string? json) => string.IsNullOrWhiteSpace(json)
        ? []
        : JsonSerializer.Deserialize<List<T>>(json, JsonOptions) ?? [];

    private static string AppendSafeNote(string? existing, string note) =>
        string.IsNullOrWhiteSpace(existing)
            ? note
            : $"{existing}{Environment.NewLine}{note}"[..Math.Min(2000, existing.Length + Environment.NewLine.Length + note.Length)];

    private sealed record Resolution(Server? Server, SqlInstance? Instance, SqlDatabase? Database, string? Error);
}
