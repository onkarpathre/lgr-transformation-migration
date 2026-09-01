using System.Globalization;
using System.Text.Json;
using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Domain;
using LgrTransformationMigration.Api.Infrastructure;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace LgrTransformationMigration.Api.Services.Discovery;

public sealed class DiscoveryImportService(
    AppDbContext db,
    ICurrentCustomerContext context,
    IImportFileStorage fileStorage,
    IDiscoveryFileReader fileReader,
    DiscoverySourceMapperResolver mapperResolver,
    DiscoveryRecordValidator validator,
    DiscoveryReconciler reconciler,
    TimeProvider timeProvider,
    IOptions<DiscoveryImportOptions> options)
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
    private DateTimeOffset Now => timeProvider.GetUtcNow();

    public async Task<DiscoveryImportBatchDto> UploadAsync(IFormFile file, string sourceType, CancellationToken cancellationToken)
    {
        var mapper = mapperResolver.Resolve(sourceType);
        if (!await db.Projects.AnyAsync(x => x.Id == context.ProjectId, cancellationToken))
            throw new DomainValidationException("The selected project does not exist in the current customer context.");
        if (file is null || file.Length == 0) throw new DomainValidationException("Select a non-empty discovery file.");

        var originalFileName = Path.GetFileName(file.FileName);
        if (string.IsNullOrWhiteSpace(originalFileName)) originalFileName = "discovery-report.csv";
        var extension = Path.GetExtension(originalFileName);
        if (!extension.Equals(".csv", StringComparison.OrdinalIgnoreCase))
            throw new DomainValidationException("Only .csv discovery reports are supported in Phase 2.");
        if (file.Length > options.Value.MaximumFileSizeBytes)
            throw new DomainValidationException($"The upload exceeds the configured {options.Value.MaximumFileSizeBytes} byte limit.");

        StoredImportFile stored;
        await using (var upload = file.OpenReadStream())
            stored = await fileStorage.SaveAsync(upload, extension, options.Value.MaximumFileSizeBytes, cancellationToken);

        try
        {
            await using var stream = await fileStorage.OpenReadAsync(stored.StoredFileName, cancellationToken);
            var document = await fileReader.ReadAsync(stream, cancellationToken);
            mapper.ValidateHeaders(document.Headers);
            if (document.Rows.Count == 0) throw new DomainValidationException("The discovery report contains headers but no data rows.");
        }
        catch
        {
            await fileStorage.DeleteAsync(stored.StoredFileName, cancellationToken);
            throw;
        }

        var previous = (await db.ImportBatches.Where(x => x.FileHash == stored.FileHash)
            .Select(x => new { x.UploadedAt, x.OriginalFileName }).ToListAsync(cancellationToken))
            .OrderByDescending(x => x.UploadedAt).FirstOrDefault();
        var duplicateWarning = previous is null ? null
            : $"This file appears to have been imported previously on {previous.UploadedAt:dd-MMM-yyyy HH:mm} as '{previous.OriginalFileName}'.";

        var batch = new ImportBatch
        {
            Id = Guid.NewGuid(), CustomerId = context.CustomerId, ProjectId = context.ProjectId,
            SourceType = mapper.SourceType, OriginalFileName = originalFileName,
            StoredFileName = stored.StoredFileName, FileHash = stored.FileHash, FileSizeBytes = stored.FileSizeBytes,
            Status = ImportBatchStatuses.Uploaded, UploadedBy = context.UserName, UploadedAt = Now, Notes = duplicateWarning
        };
        db.ImportBatches.Add(batch);
        await db.SaveChangesAsync(cancellationToken);
        return Map(batch);
    }

    public async Task<IReadOnlyList<DiscoveryImportBatchDto>> ListAsync(CancellationToken cancellationToken) =>
        (await db.ImportBatches.Where(x => x.ProjectId == context.ProjectId).ToListAsync(cancellationToken))
            .OrderByDescending(x => x.UploadedAt).Select(Map).ToList();

    public async Task<DiscoveryImportBatchDto> GetAsync(Guid id, CancellationToken cancellationToken) =>
        Map(await FindBatchAsync(id, cancellationToken));

    public async Task<DiscoveryImportBatchDto> PreviewAsync(Guid id, CancellationToken cancellationToken)
    {
        var batch = await FindBatchAsync(id, cancellationToken);
        if (batch.Status == ImportBatchStatuses.PreviewReady) return Map(batch);
        if (batch.Status != ImportBatchStatuses.Uploaded)
            throw new DomainValidationException($"A batch in status '{batch.Status}' cannot be previewed.");
        if (string.IsNullOrWhiteSpace(batch.StoredFileName)) throw new DomainValidationException("The import batch has no stored source file.");

        batch.Status = ImportBatchStatuses.Parsing;
        await db.SaveChangesAsync(cancellationToken);
        try
        {
            await using var stream = await fileStorage.OpenReadAsync(batch.StoredFileName, cancellationToken);
            var document = await fileReader.ReadAsync(stream, cancellationToken);
            var mapper = mapperResolver.Resolve(batch.SourceType);
            mapper.ValidateHeaders(document.Headers);

            var mapped = document.Rows.Select(row => new { Row = row, Record = mapper.Map(row.Values) }).ToList();
            var duplicateIds = mapped.Where(x => !string.IsNullOrWhiteSpace(x.Record.SourceRecordId))
                .GroupBy(x => x.Record.SourceRecordId!, StringComparer.OrdinalIgnoreCase)
                .Where(x => x.Count() > 1).Select(x => x.Key).ToHashSet(StringComparer.OrdinalIgnoreCase);
            var duplicateHostnames = mapped.Where(x => x.Record.IsServerRecord && !string.IsNullOrWhiteSpace(x.Record.Hostname))
                .GroupBy(x => x.Record.Hostname!.Trim(), StringComparer.OrdinalIgnoreCase)
                .Where(x => x.Count() > 1).Select(x => x.Key).ToHashSet(StringComparer.OrdinalIgnoreCase);
            var existingServers = (await db.Servers.ToListAsync(cancellationToken))
                .ToDictionary(x => x.Hostname.Trim().ToUpperInvariant(), StringComparer.OrdinalIgnoreCase);

            db.DiscoveryImportRows.RemoveRange(db.DiscoveryImportRows.Where(x => x.ImportBatchId == batch.Id));
            var staged = new List<DiscoveryImportRow>();
            foreach (var item in mapped)
            {
                var validated = validator.Validate(item.Record);
                var messages = validated.Messages.ToList();
                if (item.Record.SourceRecordId is not null && duplicateIds.Contains(item.Record.SourceRecordId))
                    messages.Add(new(ValidationSeverities.Error, "Id", $"Source Id '{item.Record.SourceRecordId}' occurs more than once in this import."));
                if (item.Record.Hostname is not null && duplicateHostnames.Contains(item.Record.Hostname.Trim()))
                    messages.Add(new(ValidationSeverities.Error, "Server", $"Hostname '{item.Record.Hostname.Trim()}' occurs more than once in this import."));

                Server? matched = null;
                if (validated.NormalizedHostname is not null) existingServers.TryGetValue(validated.NormalizedHostname, out matched);
                if (matched is not null && matched.ProjectId != batch.ProjectId)
                    messages.Add(new(ValidationSeverities.Error, "Server", "The matched server belongs to another project and cannot be changed by this import."));
                validated = validated with { Messages = messages };
                var result = reconciler.Reconcile(validated, matched);
                var validationStatus = validated.HasErrors ? ImportValidationStatuses.Invalid
                    : validated.HasWarnings ? ImportValidationStatuses.Warning : ImportValidationStatuses.Valid;

                staged.Add(new DiscoveryImportRow
                {
                    Id = Guid.NewGuid(), CustomerId = batch.CustomerId, ProjectId = batch.ProjectId,
                    ImportBatchId = batch.Id, RowNumber = item.Row.RowNumber, SourceRecordId = item.Record.SourceRecordId,
                    SourceType = batch.SourceType, RawDataJson = JsonSerializer.Serialize(item.Row.Values, JsonOptions),
                    NormalizedHostname = validated.NormalizedHostname, Classification = result.Classification,
                    ValidationStatus = validationStatus,
                    ValidationMessagesJson = messages.Count == 0 ? null : JsonSerializer.Serialize(messages, JsonOptions),
                    MatchedEntityId = matched?.Id,
                    ProposedChangesJson = result.Changes.Count == 0 ? null : JsonSerializer.Serialize(result.Changes, JsonOptions),
                    CreatedAt = Now
                });
            }

            db.DiscoveryImportRows.AddRange(staged);
            batch.TotalRows = staged.Count;
            batch.ValidRows = staged.Count(x => x.Classification != ImportClassifications.Reject);
            batch.CreateCount = staged.Count(x => x.Classification == ImportClassifications.Create);
            batch.UpdateCount = staged.Count(x => x.Classification == ImportClassifications.Update);
            batch.UnchangedCount = staged.Count(x => x.Classification == ImportClassifications.Unchanged);
            batch.WarningCount = staged.Count(x => x.Classification == ImportClassifications.Warning);
            batch.RejectCount = staged.Count(x => x.Classification == ImportClassifications.Reject);
            batch.PreviewedAt = Now;
            batch.Status = ImportBatchStatuses.PreviewReady;
            await db.SaveChangesAsync(cancellationToken);
            return Map(batch);
        }
        catch (Exception exception)
        {
            batch.Status = ImportBatchStatuses.Failed;
            batch.Notes = AppendNote(batch.Notes, $"Preview failed: {exception.Message}");
            await db.SaveChangesAsync(cancellationToken);
            throw;
        }
    }

    public async Task<PagedResult<DiscoveryImportRowDto>> ListRowsAsync(
        Guid batchId, int page, int pageSize, string? classification, CancellationToken cancellationToken)
    {
        var batch = await FindBatchAsync(batchId, cancellationToken);
        if (!string.IsNullOrWhiteSpace(classification) && !ImportClassifications.All.Contains(classification, StringComparer.OrdinalIgnoreCase))
            throw new DomainValidationException("The classification filter is invalid.");

        var query = db.DiscoveryImportRows.Where(x => x.ImportBatchId == batch.Id);
        if (!string.IsNullOrWhiteSpace(classification)) query = query.Where(x => x.Classification == classification);
        var count = await query.CountAsync(cancellationToken);
        var rows = await query.Include(x => x.MatchedServer).OrderBy(x => x.RowNumber)
            .Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken);
        return new PagedResult<DiscoveryImportRowDto>(rows.Select(MapRow).ToList(), page, pageSize, count);
    }

    public async Task<DiscoveryImportRowDetailDto> GetRowAsync(Guid batchId, Guid rowId, CancellationToken cancellationToken)
    {
        var batch = await FindBatchAsync(batchId, cancellationToken);
        var row = await db.DiscoveryImportRows.Include(x => x.MatchedServer)
            .SingleOrDefaultAsync(x => x.Id == rowId && x.ImportBatchId == batch.Id && x.ProjectId == context.ProjectId, cancellationToken)
            ?? throw new KeyNotFoundException("Discovery import row not found.");
        var raw = DeserializeRaw(row.RawDataJson);
        return new DiscoveryImportRowDetailDto(
            row.Id, row.RowNumber, row.SourceType, raw, row.NormalizedHostname, row.Classification, row.ValidationStatus,
            Deserialize<DiscoveryValidationMessageDto>(row.ValidationMessagesJson),
            row.MatchedServer is null ? null : new NamedReferenceDto(row.MatchedServer.Id, row.MatchedServer.Hostname),
            Deserialize<DiscoveryFieldChangeDto>(row.ProposedChangesJson));
    }

    public async Task<DiscoveryImportBatchDto> CommitAsync(Guid id, CancellationToken cancellationToken)
    {
        var current = await FindBatchAsync(id, cancellationToken);
        if (current.Status != ImportBatchStatuses.PreviewReady)
            throw new DomainValidationException($"A batch in status '{current.Status}' cannot be committed.");
        if (current.ValidRows == 0) throw new DomainValidationException("The import has no valid rows to commit.");

        await using var transaction = await db.Database.BeginTransactionAsync(cancellationToken);
        try
        {
            var claimed = await db.ImportBatches
                .Where(x => x.Id == id && x.ProjectId == context.ProjectId && x.Status == ImportBatchStatuses.PreviewReady)
                .ExecuteUpdateAsync(setters => setters.SetProperty(x => x.Status, ImportBatchStatuses.Importing), cancellationToken);
            if (claimed != 1) throw new DomainValidationException("The import has already been committed or is being processed.");
            current.Status = ImportBatchStatuses.Importing;

            var rows = await db.DiscoveryImportRows.Where(x => x.ImportBatchId == id).OrderBy(x => x.RowNumber)
                .AsNoTracking().ToListAsync(cancellationToken);
            var mapper = mapperResolver.Resolve(current.SourceType);
            var now = Now;
            foreach (var row in rows)
            {
                if (row.Classification == ImportClassifications.Reject) continue;
                var validated = validator.Validate(mapper.Map(DeserializeRaw(row.RawDataJson)));
                if (validated.HasErrors) throw new DomainValidationException($"Row {row.RowNumber} is no longer safe to commit.");
                if (!validated.Source.IsServerRecord) continue;

                Server server;
                IReadOnlyList<DiscoveryFieldChangeDto> changes;
                if (row.MatchedEntityId.HasValue)
                {
                    server = await db.Servers.SingleOrDefaultAsync(x => x.Id == row.MatchedEntityId.Value && x.ProjectId == current.ProjectId, cancellationToken)
                        ?? throw new DomainValidationException($"The server matched by row {row.RowNumber} is no longer available.");
                    changes = DiscoveryManagedServerFields.BuildChanges(server, validated);
                    EnsurePreviewStillCurrent(row, server, changes);
                    DiscoveryManagedServerFields.ApplyTechnicalFields(server, validated, current.Id, now);
                    foreach (var change in changes)
                        AddAudit("Server", server.Id, "ServerUpdatedFromDiscovery", current.ProjectId, change.Field, change.OldValue, change.NewValue, now);
                }
                else
                {
                    if (await db.Servers.AnyAsync(x => x.Hostname == validated.NormalizedHostname, cancellationToken))
                        throw new DomainValidationException($"A server matching row {row.RowNumber} was created after preview. Preview the import again.");
                    server = DiscoveryManagedServerFields.CreateServer(current.CustomerId, current.ProjectId, validated, current.Id, now);
                    db.Servers.Add(server);
                    changes = [];
                    AddAudit("Server", server.Id, "ServerCreatedFromDiscovery", current.ProjectId, null, null, null, now);
                }

                db.ServerDiscoverySnapshots.Add(DiscoveryManagedServerFields.CreateSnapshot(
                    current.CustomerId, current.ProjectId, server.Id, current.Id, validated, now));
            }

            current.Status = current.WarningCount > 0 || current.RejectCount > 0
                ? ImportBatchStatuses.CompletedWithWarnings : ImportBatchStatuses.Completed;
            current.CommittedAt = now;
            AddAudit("ImportBatch", current.Id, "DiscoveryImportCommitted", current.ProjectId, null, null, null, now);
            await db.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
            return Map(current);
        }
        catch (Exception exception)
        {
            await transaction.RollbackAsync(cancellationToken);
            await transaction.DisposeAsync();
            db.ChangeTracker.Clear();
            var failed = await FindBatchAsync(id, cancellationToken);
            if (failed.Status == ImportBatchStatuses.PreviewReady)
            {
                failed.Status = ImportBatchStatuses.Failed;
                failed.Notes = AppendNote(failed.Notes, $"Commit failed: {exception.Message}");
                await db.SaveChangesAsync(cancellationToken);
            }
            throw;
        }
    }

    public async Task<DiscoveryImportBatchDto> CancelAsync(Guid id, CancellationToken cancellationToken)
    {
        var batch = await FindBatchAsync(id, cancellationToken);
        if (ImportBatchStatuses.Committed.Contains(batch.Status) || batch.Status is ImportBatchStatuses.Failed or ImportBatchStatuses.Cancelled or ImportBatchStatuses.Importing)
            throw new DomainValidationException($"A batch in status '{batch.Status}' cannot be cancelled.");
        batch.Status = ImportBatchStatuses.Cancelled;
        await db.SaveChangesAsync(cancellationToken);
        return Map(batch);
    }

    public async Task<IReadOnlyList<ServerDiscoverySnapshotDto>> GetServerHistoryAsync(Guid serverId, CancellationToken cancellationToken)
    {
        if (!await db.Servers.AnyAsync(x => x.Id == serverId && x.ProjectId == context.ProjectId, cancellationToken))
            throw new KeyNotFoundException("Server not found.");
        var snapshots = await db.ServerDiscoverySnapshots.Include(x => x.ImportBatch)
            .Where(x => x.ServerId == serverId && x.ProjectId == context.ProjectId).ToListAsync(cancellationToken);
        return snapshots.OrderByDescending(x => x.ImportedAt)
            .Select(x => new ServerDiscoverySnapshotDto(
                x.Id, x.ImportBatchId, x.ImportBatch.SourceType, x.ExternalSourceId, x.Hostname, x.Environment,
                x.MigrationIntent, x.IpAddresses, x.OperatingSystem, x.Dependencies, x.SoftwareCount,
                x.DatabaseInstanceCount, x.WebAppCount, x.FileShareCount, x.SecurityRisks, x.SupportStatus,
                x.ApplicationNames, x.IssueCount, x.Tags, x.Host, x.MemoryMb, x.DiskCount, x.VCores,
                x.AllocatedStorageGb, x.NetworkAdapterCount, x.MacAddress, x.BootType, x.OsFamily,
                x.OsArchitecture, x.Processor, x.ResourceType, x.PowerStatus, x.HypervisorType,
                x.DiscoveryMethod, x.ConnectedAppliance, x.FirstDiscoveredAt, x.LastUpdatedAt, x.ImportedAt))
            .ToList();
    }

    private async Task<ImportBatch> FindBatchAsync(Guid id, CancellationToken cancellationToken) =>
        await db.ImportBatches.SingleOrDefaultAsync(x => x.Id == id && x.ProjectId == context.ProjectId, cancellationToken)
        ?? throw new KeyNotFoundException("Discovery import batch not found.");

    private DiscoveryImportRowDto MapRow(DiscoveryImportRow row)
    {
        var source = mapperResolver.Resolve(row.SourceType).Map(DeserializeRaw(row.RawDataJson));
        return new DiscoveryImportRowDto(row.Id, row.RowNumber, row.SourceRecordId, source.Hostname, source.Environment,
            source.OperatingSystem, source.IpAddresses, row.Classification, row.ValidationStatus,
            row.MatchedServer?.Hostname, row.MatchedEntityId);
    }

    private static DiscoveryImportBatchDto Map(ImportBatch batch)
    {
        var duplicate = batch.Notes?.StartsWith("This file appears", StringComparison.Ordinal) == true ? batch.Notes.Split(Environment.NewLine)[0] : null;
        return new DiscoveryImportBatchDto(batch.Id, batch.CustomerId, batch.ProjectId, batch.SourceType,
            batch.OriginalFileName, batch.FileHash, batch.FileSizeBytes, batch.Status, batch.UploadedBy,
            batch.UploadedAt, batch.PreviewedAt, batch.CommittedAt, batch.TotalRows, batch.ValidRows,
            batch.CreateCount, batch.UpdateCount, batch.UnchangedCount, batch.WarningCount, batch.RejectCount,
            batch.Notes, duplicate);
    }

    private void AddAudit(string entityType, Guid entityId, string action, Guid? projectId,
        string? propertyName, string? oldValue, string? newValue, DateTimeOffset changedAt) =>
        db.AuditEvents.Add(new AuditEvent
        {
            Id = Guid.NewGuid(), CustomerId = context.CustomerId, ProjectId = projectId,
            EntityType = entityType, EntityId = entityId, Action = action, PropertyName = propertyName,
            OldValue = oldValue, NewValue = newValue, ChangedBy = context.UserName, ChangedAt = changedAt
        });

    private static IReadOnlyDictionary<string, string> DeserializeRaw(string json) =>
        JsonSerializer.Deserialize<Dictionary<string, string>>(json, JsonOptions)
        ?? throw new DomainValidationException("The staged source data is invalid.");

    private static IReadOnlyList<T> Deserialize<T>(string? json) => string.IsNullOrWhiteSpace(json)
        ? [] : JsonSerializer.Deserialize<List<T>>(json, JsonOptions) ?? [];

    private static string AppendNote(string? existing, string note) =>
        string.IsNullOrWhiteSpace(existing) ? note : $"{existing}{Environment.NewLine}{note}";

    private static void EnsurePreviewStillCurrent(
        DiscoveryImportRow row, Server server, IReadOnlyList<DiscoveryFieldChangeDto> currentChanges)
    {
        var previewChanges = Deserialize<DiscoveryFieldChangeDto>(row.ProposedChangesJson);
        if (row.Classification == ImportClassifications.Unchanged && currentChanges.Count > 0)
            throw new DomainValidationException($"Server '{server.Hostname}' changed after preview. Preview the import again.");

        foreach (var preview in previewChanges)
        {
            var current = CurrentValue(server, preview.Field);
            if (!string.Equals(current, preview.OldValue, StringComparison.OrdinalIgnoreCase))
                throw new DomainValidationException($"Server '{server.Hostname}' field '{preview.Field}' changed after preview. Preview the import again.");
        }
    }

    private static string? CurrentValue(Server server, string field) => field switch
    {
        "ExternalSourceId" => server.ExternalSourceId,
        "Environment" => server.Environment,
        "OperatingSystem" => server.OperatingSystem,
        "IpAddress" => server.IpAddress,
        "VCores" => server.VCores?.ToString(CultureInfo.InvariantCulture),
        "MemoryMb" => server.MemoryMb?.ToString(CultureInfo.InvariantCulture),
        "AllocatedStorageGb" => server.AllocatedStorageGb?.ToString(CultureInfo.InvariantCulture),
        "PowerStatus" => server.PowerStatus,
        "OsFamily" => server.OsFamily,
        "OsArchitecture" => server.OsArchitecture,
        "Processor" => server.Processor,
        "HypervisorType" => server.HypervisorType,
        "Host" => server.Host,
        "SupportStatus" => server.SupportStatus,
        "DiscoveryMethod" => server.DiscoveryMethod,
        "FirstDiscoveredAt" => server.FirstDiscoveredAt?.ToUniversalTime().ToString("O"),
        "LastDiscoveredAt" => server.LastDiscoveredAt?.ToUniversalTime().ToString("O"),
        _ => throw new DomainValidationException($"Unsupported discovery-managed field '{field}'.")
    };
}
