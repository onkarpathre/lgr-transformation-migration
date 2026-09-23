using System.Globalization;
using System.Security.Cryptography;
using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Domain;
using LgrTransformationMigration.Api.Infrastructure;
using Microsoft.EntityFrameworkCore;

namespace LgrTransformationMigration.Api.Services;

public sealed class DependencyRegisterService(
    AppDbContext db,
    ICurrentCustomerContext context,
    IProjectAuthorizationContextAccessor authorization,
    TimeProvider timeProvider)
{
    public async Task<PagedResult<DependencyReferenceDto>> ListReferencesAsync(
        int page,
        int pageSize,
        string? referenceType,
        string? resolutionStatus,
        string? search,
        bool includeArchived,
        CancellationToken cancellationToken)
    {
        ValidateReferenceFilters(referenceType, resolutionStatus);
        EnsureArchivedAccess(includeArchived);
        var query = db.DependencyReferences.AsNoTracking().Where(x => x.ProjectId == context.ProjectId);
        if (!includeArchived)
        {
            query = query.Where(x => !x.IsArchived);
        }
        if (referenceType is not null)
        {
            query = query.Where(x => x.ReferenceType == referenceType);
        }
        if (resolutionStatus is not null)
        {
            query = query.Where(x => x.ResolutionStatus == resolutionStatus);
        }
        if (!string.IsNullOrWhiteSpace(search))
        {
            var normalizedSearch = search.Trim();
            query = query.Where(x => x.Name.Contains(normalizedSearch));
        }

        var total = await query.CountAsync(cancellationToken);
        var rows = await query.OrderBy(x => x.NormalizedName).ThenBy(x => x.Id)
            .Skip((page - 1) * pageSize).Take(pageSize)
            .Select(x => new
            {
                Entity = x,
                ActiveDependencyCount = db.Dependencies.Count(dependency =>
                    dependency.ProjectId == context.ProjectId
                    && !dependency.IsArchived
                    && dependency.TargetReferenceId == x.Id)
            })
            .ToListAsync(cancellationToken);
        return new PagedResult<DependencyReferenceDto>(
            rows.Select(x => Map(x.Entity, x.ActiveDependencyCount)).ToArray(), page, pageSize, total);
    }

    public async Task<DependencyReferenceDto> GetReferenceAsync(
        Guid id,
        bool includeArchived,
        CancellationToken cancellationToken)
    {
        EnsureArchivedAccess(includeArchived);
        var entity = await db.DependencyReferences.AsNoTracking().SingleOrDefaultAsync(
            x => x.Id == id && x.ProjectId == context.ProjectId && (includeArchived || !x.IsArchived),
            cancellationToken) ?? throw new KeyNotFoundException("Dependency reference not found.");
        var activeCount = await db.Dependencies.CountAsync(
            x => x.ProjectId == context.ProjectId && !x.IsArchived && x.TargetReferenceId == id,
            cancellationToken);
        return Map(entity, activeCount);
    }

    public async Task<DependencyReferenceDto> CreateReferenceAsync(
        DependencyReferenceWriteV1 request,
        CancellationToken cancellationToken)
    {
        var values = ValidateReference(request);
        await EnsureReferenceNameAvailableAsync(values.ReferenceType, values.NormalizedName, null, cancellationToken);
        var now = Now;
        var entity = new DependencyReference
        {
            Id = Guid.NewGuid(),
            CustomerId = context.CustomerId,
            ProjectId = context.ProjectId,
            ReferenceType = values.ReferenceType,
            Name = values.Name,
            NormalizedName = values.NormalizedName,
            Description = values.Description,
            ResolutionStatus = values.ResolutionStatus,
            CreatedAt = now,
            CreatedBy = Actor,
            UpdatedAt = now,
            UpdatedBy = Actor,
            RowVersion = NewVersion()
        };
        db.DependencyReferences.Add(entity);
        await IncrementGraphVersionAsync(cancellationToken);
        AddAudit("DependencyReference", entity.Id, "DependencyReferenceCreated");
        await SaveAsync(cancellationToken);
        return Map(entity, 0);
    }

    public async Task<DependencyReferenceDto> UpdateReferenceAsync(
        Guid id,
        DependencyReferenceWriteV1 request,
        string? ifMatch,
        CancellationToken cancellationToken)
    {
        var values = ValidateReference(request);
        var entity = await FindReferenceAsync(id, cancellationToken);
        EnsureIfMatch(ifMatch, entity.RowVersion);
        await EnsureReferenceNameAvailableAsync(values.ReferenceType, values.NormalizedName, id, cancellationToken);
        if (values.ReferenceType != entity.ReferenceType
            && await db.Dependencies.AnyAsync(x =>
                x.ProjectId == context.ProjectId && !x.IsArchived && x.TargetReferenceId == id,
                cancellationToken))
        {
            throw new DomainConflictException(
                "A dependency reference type cannot change while active dependencies use it.");
        }
        if (values.ResolutionStatus == DependencyResolutionStatuses.Unresolved
            && entity.ResolutionStatus == DependencyResolutionStatuses.Resolved
            && await db.Dependencies.AnyAsync(x =>
                x.ProjectId == context.ProjectId
                && !x.IsArchived
                && x.TargetReferenceId == id
                && x.ConfirmationStatus == DependencyConfirmationStatuses.Confirmed,
                cancellationToken))
        {
            throw new DomainConflictException(
                "A reference with confirmed active dependencies must be unconfirmed before it becomes unresolved.");
        }

        var originalVersion = entity.RowVersion.ToArray();
        entity.ReferenceType = values.ReferenceType;
        entity.Name = values.Name;
        entity.NormalizedName = values.NormalizedName;
        entity.Description = values.Description;
        entity.ResolutionStatus = values.ResolutionStatus;
        entity.UpdatedAt = Now;
        entity.UpdatedBy = Actor;
        RotateVersion(entity, originalVersion);
        await IncrementGraphVersionAsync(cancellationToken);
        AddAudit("DependencyReference", entity.Id, "DependencyReferenceUpdated");
        await SaveAsync(cancellationToken);
        return await GetReferenceAsync(id, includeArchived: false, cancellationToken);
    }

    public async Task ArchiveReferenceAsync(Guid id, string? ifMatch, CancellationToken cancellationToken)
    {
        var entity = await FindReferenceAsync(id, cancellationToken);
        EnsureIfMatch(ifMatch, entity.RowVersion);
        if (await db.Dependencies.AnyAsync(
            x => x.ProjectId == context.ProjectId && !x.IsArchived && x.TargetReferenceId == id,
            cancellationToken))
        {
            throw new DomainConflictException("The dependency reference is used by an active dependency.");
        }

        var originalVersion = entity.RowVersion.ToArray();
        entity.IsArchived = true;
        entity.UpdatedAt = Now;
        entity.UpdatedBy = Actor;
        RotateVersion(entity, originalVersion);
        await IncrementGraphVersionAsync(cancellationToken);
        AddAudit("DependencyReference", entity.Id, "DependencyReferenceArchived");
        await SaveAsync(cancellationToken);
    }

    public async Task<PagedResult<DependencyDto>> ListDependenciesAsync(
        int page,
        int pageSize,
        string? assetType,
        Guid? assetId,
        string direction,
        string? dependencyType,
        string? criticality,
        string? confirmationStatus,
        string? search,
        bool includeArchived,
        CancellationToken cancellationToken)
    {
        ValidateDependencyFilters(assetType, assetId, direction, dependencyType, criticality, confirmationStatus);
        EnsureArchivedAccess(includeArchived);
        var query = db.Dependencies.AsNoTracking().Where(x => x.ProjectId == context.ProjectId);
        if (!includeArchived)
        {
            query = query.Where(x => !x.IsArchived);
        }
        if (assetId.HasValue)
        {
            var endpointKey = DependencyEndpointKeys.Create(assetType!, assetId.Value);
            query = direction switch
            {
                "DependsOn" => query.Where(x => x.SourceEndpointKey == endpointKey),
                "RequiredBy" => query.Where(x => x.TargetEndpointKey == endpointKey),
                _ => query.Where(x => x.SourceEndpointKey == endpointKey || x.TargetEndpointKey == endpointKey)
            };
        }
        if (dependencyType is not null)
        {
            query = query.Where(x => x.DependencyType == dependencyType);
        }
        if (criticality is not null)
        {
            query = query.Where(x => x.Criticality == criticality);
        }
        if (confirmationStatus is not null)
        {
            query = query.Where(x => x.ConfirmationStatus == confirmationStatus);
        }
        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim();
            query = query.Where(x =>
                x.DependencyType.Contains(term)
                || (x.Description != null && x.Description.Contains(term))
                || (x.BusinessContext != null && x.BusinessContext.Contains(term))
                || db.Applications.Any(a => a.ProjectId == context.ProjectId
                    && (a.Id == x.SourceApplicationId || a.Id == x.TargetApplicationId) && a.Name.Contains(term))
                || db.Servers.Any(s => s.ProjectId == context.ProjectId
                    && (s.Id == x.SourceServerId || s.Id == x.TargetServerId) && s.Hostname.Contains(term))
                || db.SqlInstances.Any(i => i.ProjectId == context.ProjectId
                    && (i.Id == x.SourceSqlInstanceId || i.Id == x.TargetSqlInstanceId) && i.InstanceName.Contains(term))
                || db.SqlDatabases.Any(d => d.ProjectId == context.ProjectId
                    && (d.Id == x.SourceSqlDatabaseId || d.Id == x.TargetSqlDatabaseId) && d.Name.Contains(term))
                || db.DependencyReferences.Any(r => r.ProjectId == context.ProjectId
                    && r.Id == x.TargetReferenceId && r.Name.Contains(term)));
        }

        var total = await query.CountAsync(cancellationToken);
        var orderedQuery = IsSqlite
            ? query.OrderBy(x => x.Id)
            : query.OrderByDescending(x => x.UpdatedAt).ThenBy(x => x.Id);
        var entities = await orderedQuery
            .Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken);
        var endpoints = await ResolveEndpointDisplaysAsync(entities, cancellationToken);
        return new PagedResult<DependencyDto>(
            entities.Select(entity => Map(entity, endpoints)).ToArray(), page, pageSize, total);
    }

    public async Task<DependencyDto> GetDependencyAsync(
        Guid id,
        bool includeArchived,
        CancellationToken cancellationToken)
    {
        EnsureArchivedAccess(includeArchived);
        var entity = await db.Dependencies.AsNoTracking().SingleOrDefaultAsync(
            x => x.Id == id && x.ProjectId == context.ProjectId && (includeArchived || !x.IsArchived),
            cancellationToken) ?? throw new KeyNotFoundException("Dependency not found.");
        var endpoints = await ResolveEndpointDisplaysAsync([entity], cancellationToken);
        return Map(entity, endpoints);
    }

    public async Task<DependencyDto> CreateDependencyAsync(
        DependencyCreateV1 request,
        CancellationToken cancellationToken)
    {
        var source = await ResolveEndpointAsync(request.Source, source: true, cancellationToken);
        var target = await ResolveEndpointAsync(request.Target, source: false, cancellationToken);
        var values = ValidateDependency(request.DependencyType, request.Criticality, request.Description, request.BusinessContext, source, target);
        if (source.Key == target.Key)
        {
            throw new DomainValidationException("A dependency cannot target itself.");
        }
        await EnsureDependencyAvailableAsync(source.Key, target.Key, values.DependencyType, null, cancellationToken);

        var now = Now;
        var entity = new Dependency
        {
            Id = Guid.NewGuid(),
            CustomerId = context.CustomerId,
            ProjectId = context.ProjectId,
            SourceType = source.Type,
            SourceEndpointKey = source.Key,
            TargetType = target.Type,
            TargetEndpointKey = target.Key,
            DependencyType = values.DependencyType,
            Criticality = values.Criticality,
            Description = values.Description,
            BusinessContext = values.BusinessContext,
            ConfirmationStatus = DependencyConfirmationStatuses.Unconfirmed,
            CreatedAt = now,
            CreatedBy = Actor,
            UpdatedAt = now,
            UpdatedBy = Actor,
            RowVersion = NewVersion()
        };
        ApplySource(entity, source);
        ApplyTarget(entity, target);
        db.Dependencies.Add(entity);
        await IncrementGraphVersionAsync(cancellationToken);
        AddAudit("Dependency", entity.Id, "DependencyCreated");
        await SaveAsync(cancellationToken);
        return await GetDependencyAsync(entity.Id, includeArchived: false, cancellationToken);
    }

    public async Task<DependencyDto> UpdateDependencyAsync(
        Guid id,
        DependencyUpdateV1 request,
        string? ifMatch,
        CancellationToken cancellationToken)
    {
        var entity = await FindDependencyAsync(id, cancellationToken);
        EnsureIfMatch(ifMatch, entity.RowVersion);
        var source = EndpointFromEntity(entity, source: true);
        var target = await ResolveEndpointAsync(
            new DependencyEndpointV1(entity.TargetType, TargetId(entity)), source: false, cancellationToken);
        var values = ValidateDependency(request.DependencyType, request.Criticality, request.Description, request.BusinessContext, source, target);
        await EnsureDependencyAvailableAsync(source.Key, target.Key, values.DependencyType, id, cancellationToken);

        var originalVersion = entity.RowVersion.ToArray();
        entity.DependencyType = values.DependencyType;
        entity.Criticality = values.Criticality;
        entity.Description = values.Description;
        entity.BusinessContext = values.BusinessContext;
        entity.UpdatedAt = Now;
        entity.UpdatedBy = Actor;
        RotateVersion(entity, originalVersion);
        await IncrementGraphVersionAsync(cancellationToken);
        AddAudit("Dependency", entity.Id, "DependencyUpdated");
        await SaveAsync(cancellationToken);
        return await GetDependencyAsync(id, includeArchived: false, cancellationToken);
    }

    public async Task<DependencyDto> SetConfirmationAsync(
        Guid id,
        DependencyConfirmationV1 request,
        string? ifMatch,
        CancellationToken cancellationToken)
    {
        if (!DependencyConfirmationStatuses.All.Contains(request.ConfirmationStatus))
        {
            throw new DomainValidationException("ConfirmationStatus is not supported.");
        }
        var entity = await FindDependencyAsync(id, cancellationToken);
        EnsureIfMatch(ifMatch, entity.RowVersion);
        if (request.ConfirmationStatus == DependencyConfirmationStatuses.Confirmed
            && entity.TargetReferenceId.HasValue)
        {
            var resolved = await db.DependencyReferences.AnyAsync(x =>
                x.Id == entity.TargetReferenceId.Value
                && x.ProjectId == context.ProjectId
                && !x.IsArchived
                && x.ResolutionStatus == DependencyResolutionStatuses.Resolved,
                cancellationToken);
            if (!resolved)
            {
                throw new DomainConflictException("An unresolved dependency reference cannot be confirmed.");
            }
        }

        var originalVersion = entity.RowVersion.ToArray();
        var confirming = request.ConfirmationStatus == DependencyConfirmationStatuses.Confirmed;
        entity.ConfirmationStatus = request.ConfirmationStatus;
        entity.ConfirmedAt = confirming ? Now : null;
        entity.ConfirmedBy = confirming ? Actor : null;
        entity.UpdatedAt = Now;
        entity.UpdatedBy = Actor;
        RotateVersion(entity, originalVersion);
        await IncrementGraphVersionAsync(cancellationToken);
        AddAudit(
            "Dependency",
            entity.Id,
            confirming ? "DependencyConfirmed" : "DependencyUnconfirmed");
        await SaveAsync(cancellationToken);
        return await GetDependencyAsync(id, includeArchived: false, cancellationToken);
    }

    public async Task ArchiveDependencyAsync(Guid id, string? ifMatch, CancellationToken cancellationToken)
    {
        var entity = await FindDependencyAsync(id, cancellationToken);
        EnsureIfMatch(ifMatch, entity.RowVersion);
        var originalVersion = entity.RowVersion.ToArray();
        entity.IsArchived = true;
        entity.UpdatedAt = Now;
        entity.UpdatedBy = Actor;
        RotateVersion(entity, originalVersion);
        await IncrementGraphVersionAsync(cancellationToken);
        AddAudit("Dependency", entity.Id, "DependencyArchived");
        await SaveAsync(cancellationToken);
    }

    public async Task<PagedResult<DependencyAuditEventDto>> ListAuditAsync(
        Guid id,
        int page,
        int pageSize,
        CancellationToken cancellationToken)
    {
        if (!await db.Dependencies.IgnoreQueryFilters().AnyAsync(x =>
            x.CustomerId == context.CustomerId && x.ProjectId == context.ProjectId && x.Id == id,
            cancellationToken))
        {
            throw new KeyNotFoundException("Dependency not found.");
        }
        var query = db.AuditEvents.AsNoTracking().Where(x =>
            x.ProjectId == context.ProjectId && x.EntityType == "Dependency" && x.EntityId == id);
        var total = await query.CountAsync(cancellationToken);
        var orderedQuery = IsSqlite
            ? query.OrderBy(x => x.Id)
            : query.OrderByDescending(x => x.ChangedAt).ThenBy(x => x.Id);
        var events = await orderedQuery
            .Skip((page - 1) * pageSize).Take(pageSize)
            .Select(x => new DependencyAuditEventDto(
                x.Id, x.Action, x.PropertyName, x.OldValue, x.NewValue, x.ChangedBy,
                x.ActorPrincipalType, x.ChangedAt, x.CorrelationId))
            .ToListAsync(cancellationToken);
        return new PagedResult<DependencyAuditEventDto>(events, page, pageSize, total);
    }

    private DateTimeOffset Now => timeProvider.GetUtcNow();
    private string Actor => context.UserName;
    private bool IsSqlite => db.Database.ProviderName?.Contains("Sqlite", StringComparison.Ordinal) == true;

    private async Task<DependencyReference> FindReferenceAsync(Guid id, CancellationToken cancellationToken) =>
        await db.DependencyReferences.SingleOrDefaultAsync(
            x => x.Id == id && x.ProjectId == context.ProjectId && !x.IsArchived,
            cancellationToken) ?? throw new KeyNotFoundException("Dependency reference not found.");

    private async Task<Dependency> FindDependencyAsync(Guid id, CancellationToken cancellationToken) =>
        await db.Dependencies.SingleOrDefaultAsync(
            x => x.Id == id && x.ProjectId == context.ProjectId && !x.IsArchived,
            cancellationToken) ?? throw new KeyNotFoundException("Dependency not found.");

    private async Task<EndpointResolution> ResolveEndpointAsync(
        DependencyEndpointV1 endpoint,
        bool source,
        CancellationToken cancellationToken)
    {
        if (endpoint.Id == Guid.Empty)
        {
            throw new DomainValidationException("Endpoint id is required.");
        }
        if (source && !DependencyAssetTypes.Canonical.Contains(endpoint.Type))
        {
            throw new DomainValidationException("A dependency source must be a supported canonical asset.");
        }
        if (!source && endpoint.Type != DependencyAssetTypes.DependencyReference
            && !DependencyAssetTypes.Canonical.Contains(endpoint.Type))
        {
            throw new DomainValidationException("Dependency target type is not supported.");
        }

        string displayName;
        string route;
        string? referenceType = null;
        string? resolutionStatus = null;
        switch (endpoint.Type)
        {
            case DependencyAssetTypes.Application:
                displayName = await db.Applications.Where(x => x.ProjectId == context.ProjectId && x.Id == endpoint.Id)
                    .Select(x => x.Name).SingleOrDefaultAsync(cancellationToken)
                    ?? throw new KeyNotFoundException("Endpoint not found.");
                route = $"/inventory/applications?assetId={endpoint.Id:D}";
                break;
            case DependencyAssetTypes.Server:
                displayName = await db.Servers.Where(x => x.ProjectId == context.ProjectId && x.Id == endpoint.Id)
                    .Select(x => x.Hostname).SingleOrDefaultAsync(cancellationToken)
                    ?? throw new KeyNotFoundException("Endpoint not found.");
                route = $"/inventory/servers?assetId={endpoint.Id:D}";
                break;
            case DependencyAssetTypes.SqlInstance:
                displayName = await db.SqlInstances.Where(x => x.ProjectId == context.ProjectId && x.Id == endpoint.Id)
                    .Select(x => x.InstanceName).SingleOrDefaultAsync(cancellationToken)
                    ?? throw new KeyNotFoundException("Endpoint not found.");
                route = $"/inventory/sql-instances/{endpoint.Id:D}";
                break;
            case DependencyAssetTypes.SqlDatabase:
                displayName = await db.SqlDatabases.Where(x => x.ProjectId == context.ProjectId && x.Id == endpoint.Id)
                    .Select(x => x.Name).SingleOrDefaultAsync(cancellationToken)
                    ?? throw new KeyNotFoundException("Endpoint not found.");
                route = $"/inventory/sql-databases/{endpoint.Id:D}";
                break;
            case DependencyAssetTypes.DependencyReference:
                var reference = await db.DependencyReferences.AsNoTracking().SingleOrDefaultAsync(x =>
                    x.ProjectId == context.ProjectId && x.Id == endpoint.Id && !x.IsArchived,
                    cancellationToken) ?? throw new KeyNotFoundException("Endpoint not found.");
                displayName = reference.Name;
                route = $"/planning/dependencies?referenceId={endpoint.Id:D}";
                referenceType = reference.ReferenceType;
                resolutionStatus = reference.ResolutionStatus;
                break;
            default:
                throw new DomainValidationException("Endpoint type is not supported.");
        }

        return new EndpointResolution(
            endpoint.Type, endpoint.Id, DependencyEndpointKeys.Create(endpoint.Type, endpoint.Id),
            displayName, route, referenceType, resolutionStatus);
    }

    private static DependencyValues ValidateDependency(
        string dependencyType,
        string criticality,
        string? description,
        string? businessContext,
        EndpointResolution source,
        EndpointResolution target)
    {
        if (!DependencyTypes.All.Contains(dependencyType))
        {
            throw new DomainValidationException("DependencyType is not supported.");
        }
        if (!DependencyCriticalities.All.Contains(criticality))
        {
            throw new DomainValidationException("Criticality is not supported.");
        }
        if (!DependencyTypes.IsAllowed(dependencyType, source.Type, target.Type, target.ReferenceType))
        {
            throw new DomainValidationException("The dependency type is not allowed for the selected source and target.");
        }
        return new DependencyValues(
            dependencyType,
            criticality,
            DependencyText.Optional(description, 2000, "Description"),
            DependencyText.Optional(businessContext, 4000, "Business context"));
    }

    private static ReferenceValues ValidateReference(DependencyReferenceWriteV1 request)
    {
        if (!DependencyReferenceTypes.All.Contains(request.ReferenceType))
        {
            throw new DomainValidationException("ReferenceType is not supported.");
        }
        if (!DependencyResolutionStatuses.All.Contains(request.ResolutionStatus))
        {
            throw new DomainValidationException("ResolutionStatus is not supported.");
        }
        var name = DependencyText.Required(request.Name, 200, "Name");
        return new ReferenceValues(
            request.ReferenceType,
            name,
            DependencyText.NormalizedName(name),
            DependencyText.Optional(request.Description, 1000, "Description"),
            request.ResolutionStatus);
    }

    private async Task EnsureReferenceNameAvailableAsync(
        string referenceType,
        string normalizedName,
        Guid? excludedId,
        CancellationToken cancellationToken)
    {
        if (await db.DependencyReferences.AnyAsync(x =>
            x.ProjectId == context.ProjectId && !x.IsArchived
            && x.ReferenceType == referenceType && x.NormalizedName == normalizedName
            && (!excludedId.HasValue || x.Id != excludedId.Value), cancellationToken))
        {
            throw new DomainConflictException("An active dependency reference with this type and name already exists.");
        }
    }

    private async Task EnsureDependencyAvailableAsync(
        string sourceKey,
        string targetKey,
        string dependencyType,
        Guid? excludedId,
        CancellationToken cancellationToken)
    {
        if (await db.Dependencies.AnyAsync(x =>
            x.ProjectId == context.ProjectId && !x.IsArchived
            && x.SourceEndpointKey == sourceKey && x.TargetEndpointKey == targetKey
            && x.DependencyType == dependencyType
            && (!excludedId.HasValue || x.Id != excludedId.Value), cancellationToken))
        {
            throw new DomainConflictException("An active dependency with the same endpoints and type already exists.");
        }
    }

    private async Task IncrementGraphVersionAsync(CancellationToken cancellationToken)
    {
        var state = await db.DependencyGraphStates.SingleOrDefaultAsync(
            x => x.ProjectId == context.ProjectId, cancellationToken);
        if (state is null)
        {
            state = new DependencyGraphState
            {
                Id = Guid.NewGuid(),
                CustomerId = context.CustomerId,
                ProjectId = context.ProjectId,
                GraphVersion = 0,
                PlanningVersion = 0,
                UpdatedAt = Now,
                RowVersion = NewVersion()
            };
            db.DependencyGraphStates.Add(state);
        }
        state.GraphVersion = checked(state.GraphVersion + 1);
        state.UpdatedAt = Now;
    }

    private async Task<IReadOnlyDictionary<string, DependencyEndpointDto>> ResolveEndpointDisplaysAsync(
        IReadOnlyCollection<Dependency> dependencies,
        CancellationToken cancellationToken)
    {
        var applicationIds = dependencies.SelectMany(x => new[] { x.SourceApplicationId, x.TargetApplicationId }).Where(x => x.HasValue).Select(x => x!.Value).Distinct().ToArray();
        var serverIds = dependencies.SelectMany(x => new[] { x.SourceServerId, x.TargetServerId }).Where(x => x.HasValue).Select(x => x!.Value).Distinct().ToArray();
        var instanceIds = dependencies.SelectMany(x => new[] { x.SourceSqlInstanceId, x.TargetSqlInstanceId }).Where(x => x.HasValue).Select(x => x!.Value).Distinct().ToArray();
        var databaseIds = dependencies.SelectMany(x => new[] { x.SourceSqlDatabaseId, x.TargetSqlDatabaseId }).Where(x => x.HasValue).Select(x => x!.Value).Distinct().ToArray();
        var referenceIds = dependencies.Where(x => x.TargetReferenceId.HasValue).Select(x => x.TargetReferenceId!.Value).Distinct().ToArray();
        var result = new Dictionary<string, DependencyEndpointDto>(StringComparer.Ordinal);

        foreach (var item in await db.Applications.AsNoTracking().Where(x => x.ProjectId == context.ProjectId && applicationIds.Contains(x.Id)).Select(x => new { x.Id, x.Name }).ToListAsync(cancellationToken))
            AddEndpoint(result, DependencyAssetTypes.Application, item.Id, item.Name, $"/inventory/applications?assetId={item.Id:D}");
        foreach (var item in await db.Servers.AsNoTracking().Where(x => x.ProjectId == context.ProjectId && serverIds.Contains(x.Id)).Select(x => new { x.Id, x.Hostname }).ToListAsync(cancellationToken))
            AddEndpoint(result, DependencyAssetTypes.Server, item.Id, item.Hostname, $"/inventory/servers?assetId={item.Id:D}");
        foreach (var item in await db.SqlInstances.AsNoTracking().Where(x => x.ProjectId == context.ProjectId && instanceIds.Contains(x.Id)).Select(x => new { x.Id, x.InstanceName }).ToListAsync(cancellationToken))
            AddEndpoint(result, DependencyAssetTypes.SqlInstance, item.Id, item.InstanceName, $"/inventory/sql-instances/{item.Id:D}");
        foreach (var item in await db.SqlDatabases.AsNoTracking().Where(x => x.ProjectId == context.ProjectId && databaseIds.Contains(x.Id)).Select(x => new { x.Id, x.Name }).ToListAsync(cancellationToken))
            AddEndpoint(result, DependencyAssetTypes.SqlDatabase, item.Id, item.Name, $"/inventory/sql-databases/{item.Id:D}");
        foreach (var item in await db.DependencyReferences.AsNoTracking().Where(x => x.ProjectId == context.ProjectId && referenceIds.Contains(x.Id)).Select(x => new { x.Id, x.Name, x.ReferenceType, x.ResolutionStatus }).ToListAsync(cancellationToken))
            AddEndpoint(result, DependencyAssetTypes.DependencyReference, item.Id, item.Name, $"/planning/dependencies?referenceId={item.Id:D}", item.ReferenceType, item.ResolutionStatus);

        if (dependencies.Any(x => !result.ContainsKey(x.SourceEndpointKey) || !result.ContainsKey(x.TargetEndpointKey)))
        {
            throw new InvalidOperationException("A dependency endpoint could not be resolved inside the authorized project.");
        }
        return result;
    }

    private static void AddEndpoint(
        IDictionary<string, DependencyEndpointDto> endpoints,
        string type,
        Guid id,
        string displayName,
        string route,
        string? referenceType = null,
        string? resolutionStatus = null) =>
        endpoints[DependencyEndpointKeys.Create(type, id)] = new DependencyEndpointDto(
            type, id, displayName, route, referenceType, resolutionStatus);

    private static void ApplySource(Dependency entity, EndpointResolution endpoint)
    {
        if (endpoint.Type == DependencyAssetTypes.Application) entity.SourceApplicationId = endpoint.Id;
        else if (endpoint.Type == DependencyAssetTypes.Server) entity.SourceServerId = endpoint.Id;
        else if (endpoint.Type == DependencyAssetTypes.SqlInstance) entity.SourceSqlInstanceId = endpoint.Id;
        else if (endpoint.Type == DependencyAssetTypes.SqlDatabase) entity.SourceSqlDatabaseId = endpoint.Id;
    }

    private static void ApplyTarget(Dependency entity, EndpointResolution endpoint)
    {
        if (endpoint.Type == DependencyAssetTypes.Application) entity.TargetApplicationId = endpoint.Id;
        else if (endpoint.Type == DependencyAssetTypes.Server) entity.TargetServerId = endpoint.Id;
        else if (endpoint.Type == DependencyAssetTypes.SqlInstance) entity.TargetSqlInstanceId = endpoint.Id;
        else if (endpoint.Type == DependencyAssetTypes.SqlDatabase) entity.TargetSqlDatabaseId = endpoint.Id;
        else if (endpoint.Type == DependencyAssetTypes.DependencyReference) entity.TargetReferenceId = endpoint.Id;
    }

    private static EndpointResolution EndpointFromEntity(Dependency entity, bool source)
    {
        var type = source ? entity.SourceType : entity.TargetType;
        var id = source ? SourceId(entity) : TargetId(entity);
        return new EndpointResolution(type, id, DependencyEndpointKeys.Create(type, id), string.Empty, string.Empty, null, null);
    }

    private static Guid SourceId(Dependency entity) =>
        entity.SourceApplicationId ?? entity.SourceServerId ?? entity.SourceSqlInstanceId ?? entity.SourceSqlDatabaseId
        ?? throw new InvalidOperationException("Dependency source is invalid.");

    private static Guid TargetId(Dependency entity) =>
        entity.TargetApplicationId ?? entity.TargetServerId ?? entity.TargetSqlInstanceId ?? entity.TargetSqlDatabaseId ?? entity.TargetReferenceId
        ?? throw new InvalidOperationException("Dependency target is invalid.");

    private static DependencyDto Map(
        Dependency entity,
        IReadOnlyDictionary<string, DependencyEndpointDto> endpoints) => new(
        entity.Id, endpoints[entity.SourceEndpointKey], endpoints[entity.TargetEndpointKey], "DependsOn",
        entity.DependencyType, entity.Criticality, entity.Description, entity.BusinessContext,
        entity.ConfirmationStatus, entity.ConfirmedAt, entity.ConfirmedBy,
        new DependencyFindingCountsDto(0, 0, 0), entity.IsArchived,
        entity.CreatedAt, entity.CreatedBy, entity.UpdatedAt, entity.UpdatedBy,
        Convert.ToBase64String(entity.RowVersion));

    private static DependencyReferenceDto Map(DependencyReference entity, int activeDependencyCount) => new(
        entity.Id, entity.ReferenceType, entity.Name, entity.Description, entity.ResolutionStatus,
        activeDependencyCount, entity.IsArchived, entity.CreatedAt, entity.CreatedBy,
        entity.UpdatedAt, entity.UpdatedBy, Convert.ToBase64String(entity.RowVersion));

    private void AddAudit(string entityType, Guid entityId, string action) => db.AuditEvents.Add(new AuditEvent
    {
        Id = Guid.NewGuid(),
        CustomerId = context.CustomerId,
        ProjectId = context.ProjectId,
        EntityType = entityType,
        EntityId = entityId,
        Action = action,
        ChangedBy = Actor,
        ActorPrincipalType = context.Principal.PrincipalType.ToString(),
        ChangedAt = Now,
        CorrelationId = context.CorrelationId
    });

    private void EnsureArchivedAccess(bool includeArchived)
    {
        if (includeArchived && !(authorization.AuthorizationContext?.Permissions.Contains(DependencyPermissions.AuditRead) ?? false))
        {
            throw new DomainForbiddenException("Archived dependency records require audit permission.");
        }
    }

    private static void ValidateReferenceFilters(string? referenceType, string? resolutionStatus)
    {
        if (referenceType is not null && !DependencyReferenceTypes.All.Contains(referenceType))
            throw new DomainValidationException("ReferenceType filter is not supported.");
        if (resolutionStatus is not null && !DependencyResolutionStatuses.All.Contains(resolutionStatus))
            throw new DomainValidationException("ResolutionStatus filter is not supported.");
    }

    private static void ValidateDependencyFilters(
        string? assetType, Guid? assetId, string direction, string? dependencyType,
        string? criticality, string? confirmationStatus)
    {
        if (assetId.HasValue != (assetType is not null))
            throw new DomainValidationException("AssetType and AssetId must be supplied together.");
        if (assetType is not null && assetType != DependencyAssetTypes.DependencyReference && !DependencyAssetTypes.Canonical.Contains(assetType))
            throw new DomainValidationException("AssetType filter is not supported.");
        if (direction is not ("DependsOn" or "RequiredBy" or "Either"))
            throw new DomainValidationException("Direction filter is not supported.");
        if (dependencyType is not null && !DependencyTypes.All.Contains(dependencyType))
            throw new DomainValidationException("DependencyType filter is not supported.");
        if (criticality is not null && !DependencyCriticalities.All.Contains(criticality))
            throw new DomainValidationException("Criticality filter is not supported.");
        if (confirmationStatus is not null && !DependencyConfirmationStatuses.All.Contains(confirmationStatus))
            throw new DomainValidationException("ConfirmationStatus filter is not supported.");
    }

    private static byte[] NewVersion() => RandomNumberGenerator.GetBytes(8);

    private void RotateVersion(DependencyReference entity, byte[] originalVersion)
    {
        entity.RowVersion = NewVersion();
        db.Entry(entity).Property(x => x.RowVersion).OriginalValue = originalVersion;
    }

    private void RotateVersion(Dependency entity, byte[] originalVersion)
    {
        entity.RowVersion = NewVersion();
        db.Entry(entity).Property(x => x.RowVersion).OriginalValue = originalVersion;
    }

    private static void EnsureIfMatch(string? ifMatch, byte[] rowVersion)
    {
        if (string.IsNullOrWhiteSpace(ifMatch))
            throw new PreconditionRequiredException("If-Match is required for updates and deletes.");
        var expected = ToEntityTag(rowVersion);
        if (!ifMatch.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .Contains(expected, StringComparer.Ordinal))
            throw new StaleVersionException("The resource was changed after it was retrieved.");
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

    private sealed record ReferenceValues(
        string ReferenceType, string Name, string NormalizedName, string? Description, string ResolutionStatus);
    private sealed record DependencyValues(
        string DependencyType, string Criticality, string? Description, string? BusinessContext);
    private sealed record EndpointResolution(
        string Type, Guid Id, string Key, string DisplayName, string Route,
        string? ReferenceType, string? ResolutionStatus);
}
