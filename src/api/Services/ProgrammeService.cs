using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Domain;
using LgrTransformationMigration.Api.Infrastructure;
using LgrTransformationMigration.Api.Services.Discovery;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace LgrTransformationMigration.Api.Services;

public sealed class ProgrammeService(
    AppDbContext db,
    ICurrentCustomerContext context,
    ReadinessCalculator readinessCalculator,
    TimeProvider timeProvider,
    IOptions<DiscoveryImportOptions> discoveryOptions)
{
    public async Task<CustomerDto> GetCustomerAsync(CancellationToken cancellationToken)
    {
        var entity = await db.Customers.SingleOrDefaultAsync(cancellationToken)
            ?? throw new KeyNotFoundException("Customer not found.");
        return Map(entity);
    }

    public async Task<CustomerDto> UpdateCustomerAsync(CustomerRequest request, CancellationToken cancellationToken)
    {
        var entity = await db.Customers.SingleOrDefaultAsync(cancellationToken)
            ?? throw new KeyNotFoundException("Customer not found.");
        entity.Name = request.Name.Trim();
        entity.Code = request.Code.Trim().ToUpperInvariant();
        entity.Status = request.Status;
        entity.UpdatedAt = Now;
        AddAudit("Customer", entity.Id, "Updated", null);
        await db.SaveChangesAsync(cancellationToken);
        return Map(entity);
    }

    public async Task<IReadOnlyList<ProjectDto>> ListProjectsAsync(CancellationToken cancellationToken) =>
        await db.Projects.OrderBy(x => x.Name).Select(x => new ProjectDto(
            x.Id, x.CustomerId, x.Name, x.Description, x.Status, x.PlannedStartDate, x.PlannedEndDate, x.CreatedAt, x.UpdatedAt))
            .ToListAsync(cancellationToken);

    public async Task<ProjectDto> GetProjectAsync(Guid id, CancellationToken cancellationToken) =>
        await db.Projects.Where(x => x.Id == id).Select(x => new ProjectDto(
            x.Id, x.CustomerId, x.Name, x.Description, x.Status, x.PlannedStartDate, x.PlannedEndDate, x.CreatedAt, x.UpdatedAt))
            .SingleOrDefaultAsync(cancellationToken)
            ?? throw new KeyNotFoundException("Project not found.");

    public async Task<ProjectDto> CreateProjectAsync(ProjectRequest request, CancellationToken cancellationToken)
    {
        ValidateDates(request.PlannedStartDate, request.PlannedEndDate);
        var entity = new Project
        {
            Id = Guid.NewGuid(), CustomerId = context.CustomerId, Name = request.Name.Trim(), Description = request.Description,
            Status = request.Status, PlannedStartDate = request.PlannedStartDate, PlannedEndDate = request.PlannedEndDate,
            CreatedAt = Now, UpdatedAt = Now
        };
        db.Projects.Add(entity);
        AddAudit("Project", entity.Id, "Created", entity.Id);
        await db.SaveChangesAsync(cancellationToken);
        return await GetProjectAsync(entity.Id, cancellationToken);
    }

    public async Task<ProjectDto> UpdateProjectAsync(Guid id, ProjectRequest request, CancellationToken cancellationToken)
    {
        ValidateDates(request.PlannedStartDate, request.PlannedEndDate);
        var entity = await db.Projects.SingleOrDefaultAsync(x => x.Id == id, cancellationToken)
            ?? throw new KeyNotFoundException("Project not found.");
        entity.Name = request.Name.Trim(); entity.Description = request.Description; entity.Status = request.Status;
        entity.PlannedStartDate = request.PlannedStartDate; entity.PlannedEndDate = request.PlannedEndDate; entity.UpdatedAt = Now;
        AddAudit("Project", entity.Id, "Updated", entity.Id);
        await db.SaveChangesAsync(cancellationToken);
        return await GetProjectAsync(entity.Id, cancellationToken);
    }

    public async Task DeleteProjectAsync(Guid id, CancellationToken cancellationToken)
    {
        var entity = await db.Projects.SingleOrDefaultAsync(x => x.Id == id, cancellationToken)
            ?? throw new KeyNotFoundException("Project not found.");
        db.Projects.Remove(entity);
        AddAudit("Project", entity.Id, "Deleted", entity.Id);
        await db.SaveChangesAsync(cancellationToken);
    }

    public async Task<PagedResult<ApplicationDto>> ListApplicationsAsync(int page, int pageSize, string? search, CancellationToken cancellationToken)
    {
        var query = db.Applications.Where(x => x.ProjectId == context.ProjectId)
            .Include(x => x.ApplicationServers).ThenInclude(x => x.Server).AsQueryable();
        if (!string.IsNullOrWhiteSpace(search))
        {
            query = query.Where(x => x.Name.Contains(search));
        }
        var count = await query.CountAsync(cancellationToken);
        var entities = await query.OrderBy(x => x.Name).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken);
        return new PagedResult<ApplicationDto>(entities.Select(Map).ToList(), page, pageSize, count);
    }

    public async Task<ApplicationDto> GetApplicationAsync(Guid id, CancellationToken cancellationToken) =>
        Map(await FindApplicationAsync(id, cancellationToken));

    public async Task<ApplicationDto> CreateApplicationAsync(ApplicationRequest request, CancellationToken cancellationToken)
    {
        var entity = new Application
        {
            Id = Guid.NewGuid(), CustomerId = context.CustomerId, ProjectId = context.ProjectId,
            CreatedAt = Now, UpdatedAt = Now
        };
        Apply(entity, request);
        db.Applications.Add(entity);
        await SetApplicationServersAsync(entity, request.ServerIds, cancellationToken);
        AddAudit("Application", entity.Id, "Created", context.ProjectId);
        await db.SaveChangesAsync(cancellationToken);
        return await GetApplicationAsync(entity.Id, cancellationToken);
    }

    public async Task<ApplicationDto> UpdateApplicationAsync(Guid id, ApplicationRequest request, CancellationToken cancellationToken)
    {
        var entity = await FindApplicationAsync(id, cancellationToken);
        Apply(entity, request);
        entity.UpdatedAt = Now;
        await SetApplicationServersAsync(entity, request.ServerIds, cancellationToken);
        AddAudit("Application", entity.Id, "Updated", context.ProjectId);
        await db.SaveChangesAsync(cancellationToken);
        return await GetApplicationAsync(entity.Id, cancellationToken);
    }

    public async Task DeleteApplicationAsync(Guid id, CancellationToken cancellationToken)
    {
        var entity = await FindApplicationAsync(id, cancellationToken);
        db.Applications.Remove(entity);
        AddAudit("Application", entity.Id, "Deleted", context.ProjectId);
        await db.SaveChangesAsync(cancellationToken);
    }

    public async Task<PagedResult<ServerDto>> ListServersAsync(int page, int pageSize, string? search, string? environment, CancellationToken cancellationToken)
    {
        var query = db.Servers.Where(x => x.ProjectId == context.ProjectId)
            .Include(x => x.ApplicationServers).ThenInclude(x => x.Application)
            .Include(x => x.AzureTarget).Include(x => x.LastImportBatch).AsQueryable();
        if (!string.IsNullOrWhiteSpace(search)) query = query.Where(x => x.Hostname.Contains(search) || x.IpAddress.Contains(search));
        if (!string.IsNullOrWhiteSpace(environment)) query = query.Where(x => x.Environment == environment);
        var count = await query.CountAsync(cancellationToken);
        var entities = await query.OrderBy(x => x.Hostname).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken);
        return new PagedResult<ServerDto>(entities.Select(Map).ToList(), page, pageSize, count);
    }

    public async Task<ServerDto> GetServerAsync(Guid id, CancellationToken cancellationToken) => Map(await FindServerAsync(id, cancellationToken));

    public async Task<ServerDto> CreateServerAsync(ServerRequest request, CancellationToken cancellationToken)
    {
        var entity = new Server { Id = Guid.NewGuid(), CustomerId = context.CustomerId, ProjectId = context.ProjectId, CreatedAt = Now, UpdatedAt = Now };
        Apply(entity, request);
        db.Servers.Add(entity);
        await SetServerApplicationsAsync(entity, request.ApplicationIds, cancellationToken);
        AddAudit("Server", entity.Id, "Created", context.ProjectId);
        await db.SaveChangesAsync(cancellationToken);
        return await GetServerAsync(entity.Id, cancellationToken);
    }

    public async Task<ServerDto> UpdateServerAsync(Guid id, ServerRequest request, CancellationToken cancellationToken)
    {
        var entity = await FindServerAsync(id, cancellationToken);
        Apply(entity, request); entity.UpdatedAt = Now;
        await SetServerApplicationsAsync(entity, request.ApplicationIds, cancellationToken);
        AddAudit("Server", entity.Id, "Updated", context.ProjectId);
        await db.SaveChangesAsync(cancellationToken);
        return await GetServerAsync(entity.Id, cancellationToken);
    }

    public async Task DeleteServerAsync(Guid id, CancellationToken cancellationToken)
    {
        var entity = await FindServerAsync(id, cancellationToken);
        db.Servers.Remove(entity); AddAudit("Server", entity.Id, "Deleted", context.ProjectId);
        await db.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<MigrationDecisionDto>> ListDecisionsAsync(CancellationToken cancellationToken) =>
        await db.MigrationDecisions.Where(x => x.ProjectId == context.ProjectId).OrderBy(x => x.Application.Name)
            .Select(x => new MigrationDecisionDto(x.Id, x.ApplicationId, x.Application.Name, x.MigrationScope, x.MigrationStrategy,
                x.TargetPlatform, x.Reason, x.Risk, x.DecisionStatus, x.DecisionDate, x.CreatedAt, x.UpdatedAt))
            .ToListAsync(cancellationToken);

    public async Task<MigrationDecisionDto> GetDecisionAsync(Guid id, CancellationToken cancellationToken) =>
        await db.MigrationDecisions.Where(x => x.Id == id && x.ProjectId == context.ProjectId)
            .Select(x => new MigrationDecisionDto(x.Id, x.ApplicationId, x.Application.Name, x.MigrationScope, x.MigrationStrategy,
                x.TargetPlatform, x.Reason, x.Risk, x.DecisionStatus, x.DecisionDate, x.CreatedAt, x.UpdatedAt))
            .SingleOrDefaultAsync(cancellationToken) ?? throw new KeyNotFoundException("Migration decision not found.");

    public async Task<MigrationDecisionDto> CreateDecisionAsync(MigrationDecisionRequest request, CancellationToken cancellationToken)
    {
        await RequireApplicationAsync(request.ApplicationId, cancellationToken);
        var entity = new MigrationDecision
        {
            Id = Guid.NewGuid(), CustomerId = context.CustomerId, ProjectId = context.ProjectId,
            ApplicationId = request.ApplicationId, CreatedAt = Now, UpdatedAt = Now
        };
        Apply(entity, request); db.MigrationDecisions.Add(entity); AddAudit("MigrationDecision", entity.Id, "Created", context.ProjectId);
        await db.SaveChangesAsync(cancellationToken); return await GetDecisionAsync(entity.Id, cancellationToken);
    }

    public async Task<MigrationDecisionDto> UpdateDecisionAsync(Guid id, MigrationDecisionRequest request, CancellationToken cancellationToken)
    {
        await RequireApplicationAsync(request.ApplicationId, cancellationToken);
        var entity = await db.MigrationDecisions.SingleOrDefaultAsync(x => x.Id == id && x.ProjectId == context.ProjectId, cancellationToken)
            ?? throw new KeyNotFoundException("Migration decision not found.");
        entity.ApplicationId = request.ApplicationId; Apply(entity, request); entity.UpdatedAt = Now;
        AddAudit("MigrationDecision", entity.Id, "Updated", context.ProjectId);
        await db.SaveChangesAsync(cancellationToken); return await GetDecisionAsync(entity.Id, cancellationToken);
    }

    public async Task DeleteDecisionAsync(Guid id, CancellationToken cancellationToken)
    {
        var entity = await db.MigrationDecisions.SingleOrDefaultAsync(x => x.Id == id && x.ProjectId == context.ProjectId, cancellationToken)
            ?? throw new KeyNotFoundException("Migration decision not found.");
        db.MigrationDecisions.Remove(entity); AddAudit("MigrationDecision", entity.Id, "Deleted", context.ProjectId);
        await db.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<AzureTargetDto>> ListTargetsAsync(CancellationToken cancellationToken) =>
        await db.AzureTargets.Where(x => x.ProjectId == context.ProjectId).OrderBy(x => x.Server.Hostname).Select(TargetProjection())
            .ToListAsync(cancellationToken);

    public async Task<AzureTargetDto> GetTargetAsync(Guid id, CancellationToken cancellationToken) =>
        await db.AzureTargets.Where(x => x.Id == id && x.ProjectId == context.ProjectId).Select(TargetProjection())
            .SingleOrDefaultAsync(cancellationToken) ?? throw new KeyNotFoundException("Azure target not found.");

    public async Task<AzureTargetDto> CreateTargetAsync(AzureTargetRequest request, CancellationToken cancellationToken)
    {
        await RequireServerAsync(request.ServerId, cancellationToken);
        if (await db.AzureTargets.AnyAsync(x => x.ServerId == request.ServerId, cancellationToken))
            throw new DomainValidationException("The server already has an Azure target.");
        var entity = new AzureTarget { Id = Guid.NewGuid(), CustomerId = context.CustomerId, ProjectId = context.ProjectId, ServerId = request.ServerId, CreatedAt = Now, UpdatedAt = Now };
        Apply(entity, request); db.AzureTargets.Add(entity); AddAudit("AzureTarget", entity.Id, "Created", context.ProjectId);
        await db.SaveChangesAsync(cancellationToken); return await GetTargetAsync(entity.Id, cancellationToken);
    }

    public async Task<AzureTargetDto> UpdateTargetAsync(Guid id, AzureTargetRequest request, CancellationToken cancellationToken)
    {
        await RequireServerAsync(request.ServerId, cancellationToken);
        var entity = await db.AzureTargets.SingleOrDefaultAsync(x => x.Id == id && x.ProjectId == context.ProjectId, cancellationToken)
            ?? throw new KeyNotFoundException("Azure target not found.");
        if (await db.AzureTargets.AnyAsync(x => x.ServerId == request.ServerId && x.Id != id, cancellationToken))
            throw new DomainValidationException("The server already has an Azure target.");
        entity.ServerId = request.ServerId; Apply(entity, request); entity.UpdatedAt = Now; AddAudit("AzureTarget", entity.Id, "Updated", context.ProjectId);
        await db.SaveChangesAsync(cancellationToken); return await GetTargetAsync(entity.Id, cancellationToken);
    }

    public async Task DeleteTargetAsync(Guid id, CancellationToken cancellationToken)
    {
        var entity = await db.AzureTargets.SingleOrDefaultAsync(x => x.Id == id && x.ProjectId == context.ProjectId, cancellationToken)
            ?? throw new KeyNotFoundException("Azure target not found.");
        db.AzureTargets.Remove(entity); AddAudit("AzureTarget", entity.Id, "Deleted", context.ProjectId); await db.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<SubnetDto>> ListSubnetsAsync(CancellationToken cancellationToken)
    {
        var entities = await db.Subnets.Where(x => x.ProjectId == context.ProjectId).Include(x => x.IpAddresses).OrderBy(x => x.Name).ToListAsync(cancellationToken);
        return entities.Select(Map).ToList();
    }

    public async Task<SubnetDto> CreateSubnetAsync(SubnetRequest request, CancellationToken cancellationToken)
    {
        var entity = new Subnet
        {
            Id = Guid.NewGuid(), CustomerId = context.CustomerId, ProjectId = context.ProjectId, Name = request.Name.Trim(), VNetName = request.VNetName.Trim(),
            Cidr = request.Cidr.Trim(), Environment = request.Environment, CreatedAt = Now, UpdatedAt = Now
        };
        db.Subnets.Add(entity); AddAudit("Subnet", entity.Id, "Created", context.ProjectId); await db.SaveChangesAsync(cancellationToken); return Map(entity);
    }

    public async Task<SubnetDto> UpdateSubnetAsync(Guid id, SubnetRequest request, CancellationToken cancellationToken)
    {
        var entity = await db.Subnets.Include(x => x.IpAddresses).SingleOrDefaultAsync(x => x.Id == id && x.ProjectId == context.ProjectId, cancellationToken)
            ?? throw new KeyNotFoundException("Subnet not found.");
        entity.Name = request.Name.Trim(); entity.VNetName = request.VNetName.Trim(); entity.Cidr = request.Cidr.Trim(); entity.Environment = request.Environment; entity.UpdatedAt = Now;
        AddAudit("Subnet", entity.Id, "Updated", context.ProjectId); await db.SaveChangesAsync(cancellationToken); return Map(entity);
    }

    public async Task DeleteSubnetAsync(Guid id, CancellationToken cancellationToken)
    {
        var entity = await db.Subnets.SingleOrDefaultAsync(x => x.Id == id && x.ProjectId == context.ProjectId, cancellationToken)
            ?? throw new KeyNotFoundException("Subnet not found.");
        db.Subnets.Remove(entity); AddAudit("Subnet", entity.Id, "Deleted", context.ProjectId); await db.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<IpAddressDto>> ListIpAddressesAsync(Guid? subnetId, CancellationToken cancellationToken)
    {
        var query = db.IpAddresses.Where(x => x.ProjectId == context.ProjectId);
        if (subnetId.HasValue) query = query.Where(x => x.SubnetId == subnetId);
        return await query.OrderBy(x => x.Address).Select(x => new IpAddressDto(
            x.Id, x.SubnetId, x.Subnet.Name, x.Address, x.Status, x.ServerId, x.Server != null ? x.Server.Hostname : null,
            x.ReservedAt, x.AllocatedAt, x.CreatedAt, x.UpdatedAt)).ToListAsync(cancellationToken);
    }

    public async Task<IpAddressDto> CreateIpAddressAsync(IpAddressRequest request, CancellationToken cancellationToken)
    {
        var subnetExists = await db.Subnets.AnyAsync(x => x.Id == request.SubnetId && x.ProjectId == context.ProjectId, cancellationToken);
        if (!subnetExists) throw new DomainValidationException("Subnet does not exist in the current project.");
        if (request.Status != IpStatuses.Available) throw new DomainValidationException("New POC IP records must start as Available.");
        var entity = new IpAddress { Id = Guid.NewGuid(), CustomerId = context.CustomerId, ProjectId = context.ProjectId, SubnetId = request.SubnetId, Address = request.Address.Trim(), Status = IpStatuses.Available, CreatedAt = Now, UpdatedAt = Now };
        db.IpAddresses.Add(entity); AddAudit("IpAddress", entity.Id, "Created", context.ProjectId); await db.SaveChangesAsync(cancellationToken);
        return (await ListIpAddressesAsync(request.SubnetId, cancellationToken)).Single(x => x.Id == entity.Id);
    }

    public async Task DeleteIpAddressAsync(Guid id, CancellationToken cancellationToken)
    {
        var entity = await db.IpAddresses.SingleOrDefaultAsync(x => x.Id == id && x.ProjectId == context.ProjectId, cancellationToken)
            ?? throw new KeyNotFoundException("IP address not found.");
        if (entity.Status is not (IpStatuses.Available or IpStatuses.Released)) throw new DomainValidationException("Only Available or Released addresses can be deleted.");
        db.IpAddresses.Remove(entity); AddAudit("IpAddress", entity.Id, "Deleted", context.ProjectId); await db.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<MigrationWaveDto>> ListWavesAsync(CancellationToken cancellationToken)
    {
        var entities = await db.MigrationWaves.Where(x => x.ProjectId == context.ProjectId).Include(x => x.Assets).OrderBy(x => x.PlannedDate).ToListAsync(cancellationToken);
        var readiness = await GetAssetReadinessAsync(cancellationToken);
        return entities.Select(x => Map(x, readiness)).ToList();
    }

    public async Task<MigrationWaveDetailDto> GetWaveAsync(Guid id, CancellationToken cancellationToken)
    {
        var wave = await db.MigrationWaves.Where(x => x.Id == id && x.ProjectId == context.ProjectId).Include(x => x.Assets).ThenInclude(x => x.Application)
            .Include(x => x.Assets).ThenInclude(x => x.Server).SingleOrDefaultAsync(cancellationToken)
            ?? throw new KeyNotFoundException("Migration wave not found.");
        var readiness = await GetAssetReadinessAsync(cancellationToken);
        var assets = wave.Assets.OrderBy(x => x.Application?.Name ?? x.Server!.Hostname).Select(x =>
        {
            var key = AssetKey(x.ApplicationId, x.ServerId);
            return new WaveAssetDto(x.Id, x.ApplicationId, x.ServerId, x.Application?.Name ?? x.Server?.Hostname ?? "Unknown",
                x.ApplicationId.HasValue ? "Application" : "Server", x.Status, readiness.GetValueOrDefault(key, OverallReadinessStatuses.NotReady));
        }).ToList();
        return new MigrationWaveDetailDto(Map(wave, readiness), assets);
    }

    public async Task<MigrationWaveDto> CreateWaveAsync(MigrationWaveRequest request, CancellationToken cancellationToken)
    {
        var entity = new MigrationWave { Id = Guid.NewGuid(), CustomerId = context.CustomerId, ProjectId = context.ProjectId, CreatedAt = Now, UpdatedAt = Now };
        Apply(entity, request); db.MigrationWaves.Add(entity); AddAudit("MigrationWave", entity.Id, "Created", context.ProjectId); await db.SaveChangesAsync(cancellationToken);
        return (await ListWavesAsync(cancellationToken)).Single(x => x.Id == entity.Id);
    }

    public async Task<MigrationWaveDto> UpdateWaveAsync(Guid id, MigrationWaveRequest request, CancellationToken cancellationToken)
    {
        var entity = await db.MigrationWaves.SingleOrDefaultAsync(x => x.Id == id && x.ProjectId == context.ProjectId, cancellationToken)
            ?? throw new KeyNotFoundException("Migration wave not found.");
        Apply(entity, request); entity.UpdatedAt = Now; AddAudit("MigrationWave", entity.Id, "Updated", context.ProjectId); await db.SaveChangesAsync(cancellationToken);
        return (await ListWavesAsync(cancellationToken)).Single(x => x.Id == entity.Id);
    }

    public async Task DeleteWaveAsync(Guid id, CancellationToken cancellationToken)
    {
        var entity = await db.MigrationWaves.SingleOrDefaultAsync(x => x.Id == id && x.ProjectId == context.ProjectId, cancellationToken)
            ?? throw new KeyNotFoundException("Migration wave not found.");
        db.MigrationWaves.Remove(entity); AddAudit("MigrationWave", entity.Id, "Deleted", context.ProjectId); await db.SaveChangesAsync(cancellationToken);
    }

    public async Task<MigrationWaveDetailDto> AddWaveAssetAsync(Guid waveId, WaveAssetRequest request, CancellationToken cancellationToken)
    {
        if (request.ApplicationId is null && request.ServerId is null) throw new DomainValidationException("At least ApplicationId or ServerId is required.");
        var waveExists = await db.MigrationWaves.AnyAsync(x => x.Id == waveId && x.ProjectId == context.ProjectId, cancellationToken);
        if (!waveExists) throw new KeyNotFoundException("Migration wave not found.");
        if (request.ApplicationId.HasValue) await RequireApplicationAsync(request.ApplicationId.Value, cancellationToken);
        if (request.ServerId.HasValue) await RequireServerAsync(request.ServerId.Value, cancellationToken);
        var duplicate = await db.WaveAssets.AnyAsync(x => x.MigrationWaveId == waveId && x.ApplicationId == request.ApplicationId && x.ServerId == request.ServerId, cancellationToken);
        if (duplicate) throw new DomainValidationException("The asset is already associated with this migration wave.");
        var entity = new WaveAsset { Id = Guid.NewGuid(), CustomerId = context.CustomerId, ProjectId = context.ProjectId, MigrationWaveId = waveId, ApplicationId = request.ApplicationId, ServerId = request.ServerId, Status = request.Status };
        db.WaveAssets.Add(entity); AddAudit("WaveAsset", entity.Id, "Created", context.ProjectId); await db.SaveChangesAsync(cancellationToken); return await GetWaveAsync(waveId, cancellationToken);
    }

    public async Task RemoveWaveAssetAsync(Guid waveId, Guid assetId, CancellationToken cancellationToken)
    {
        var entity = await db.WaveAssets.SingleOrDefaultAsync(x => x.Id == assetId && x.MigrationWaveId == waveId && x.ProjectId == context.ProjectId, cancellationToken)
            ?? throw new KeyNotFoundException("Wave asset not found.");
        db.WaveAssets.Remove(entity); AddAudit("WaveAsset", entity.Id, "Deleted", context.ProjectId); await db.SaveChangesAsync(cancellationToken);
    }

    public async Task<ReadinessResponse> GetReadinessAsync(CancellationToken cancellationToken)
    {
        var checks = await db.ReadinessChecks.Where(x => x.ProjectId == context.ProjectId).Include(x => x.Application).Include(x => x.Server)
            .OrderBy(x => x.Application != null ? x.Application.Name : x.Server!.Hostname).ThenBy(x => x.CheckType).ToListAsync(cancellationToken);
        var overall = checks.GroupBy(x => AssetKey(x.ApplicationId, x.ServerId)).ToDictionary(x => x.Key, x => readinessCalculator.Calculate(x.Select(y => y.Status)));
        var dtos = checks.Select(x => new ReadinessCheckDto(x.Id, x.ApplicationId, x.ServerId,
            x.Application?.Name ?? x.Server?.Hostname ?? "Unknown", x.ApplicationId.HasValue ? "Application" : "Server",
            x.CheckType, x.Status, x.Comment, overall[AssetKey(x.ApplicationId, x.ServerId)], x.UpdatedAt)).ToList();

        var waves = await db.MigrationWaves.Where(x => x.ProjectId == context.ProjectId).Include(x => x.Assets).OrderBy(x => x.PlannedDate).ToListAsync(cancellationToken);
        var summaries = waves.Select(w =>
        {
            var statuses = w.Assets.Select(a => overall.GetValueOrDefault(AssetKey(a.ApplicationId, a.ServerId), OverallReadinessStatuses.NotReady)).ToArray();
            return new WaveReadinessSummaryDto(w.Id, w.Name, statuses.Length,
                statuses.Count(x => x == OverallReadinessStatuses.Ready),
                statuses.Count(x => x is OverallReadinessStatuses.AtRisk or OverallReadinessStatuses.ReadyWithConditions),
                statuses.Count(x => x == OverallReadinessStatuses.NotReady), statuses.Count(x => x == OverallReadinessStatuses.Blocked));
        }).ToList();
        return new ReadinessResponse(dtos, summaries);
    }

    public async Task<ReadinessCheckDto> UpdateReadinessAsync(Guid id, ReadinessUpdateRequest request, CancellationToken cancellationToken)
    {
        var valid = new[] { ReadinessStatuses.NotStarted, ReadinessStatuses.Complete, ReadinessStatuses.AtRisk, ReadinessStatuses.Blocked, ReadinessStatuses.NotApplicable };
        if (!valid.Contains(request.Status)) throw new DomainValidationException("Invalid readiness status.");
        var entity = await db.ReadinessChecks.SingleOrDefaultAsync(x => x.Id == id && x.ProjectId == context.ProjectId, cancellationToken)
            ?? throw new KeyNotFoundException("Readiness check not found.");
        entity.Status = request.Status; entity.Comment = request.Comment; entity.UpdatedAt = Now; AddAudit("ReadinessCheck", entity.Id, "Updated", context.ProjectId);
        await db.SaveChangesAsync(cancellationToken);
        return (await GetReadinessAsync(cancellationToken)).Checks.Single(x => x.Id == id);
    }

    public async Task<IReadOnlyList<LookupOptionDto>> GetConfigurationAsync(string? group, CancellationToken cancellationToken)
    {
        var query = db.LookupOptions.Where(x => x.IsActive);
        if (!string.IsNullOrWhiteSpace(group)) query = query.Where(x => x.Group == group);
        return await query.OrderBy(x => x.Group).ThenBy(x => x.SortOrder).Select(x => new LookupOptionDto(x.Id, x.CustomerId, x.Group, x.Value, x.DisplayName, x.SortOrder, x.IsActive)).ToListAsync(cancellationToken);
    }

    public async Task<LookupOptionDto> AddConfigurationAsync(LookupOptionRequest request, CancellationToken cancellationToken)
    {
        var entity = new LookupOption { Id = Guid.NewGuid(), CustomerId = context.CustomerId, Group = request.Group.Trim(), Value = request.Value.Trim(), DisplayName = request.DisplayName.Trim(), SortOrder = request.SortOrder, IsActive = request.IsActive };
        db.LookupOptions.Add(entity); await db.SaveChangesAsync(cancellationToken);
        return new LookupOptionDto(entity.Id, entity.CustomerId, entity.Group, entity.Value, entity.DisplayName, entity.SortOrder, entity.IsActive);
    }

    public async Task<DashboardSummaryDto> GetDashboardAsync(CancellationToken cancellationToken)
    {
        var applications = db.Applications.Where(x => x.ProjectId == context.ProjectId);
        var servers = db.Servers.Where(x => x.ProjectId == context.ProjectId);
        var statusGroups = await applications.GroupBy(x => x.MigrationStatus).Select(x => new { x.Key, Count = x.Count() }).ToDictionaryAsync(x => x.Key, x => x.Count, cancellationToken);
        var readiness = await GetAssetReadinessAsync(cancellationToken);
        var waves = await ListWavesAsync(cancellationToken);
        var latestImport = (await db.ImportBatches.Where(x => x.ProjectId == context.ProjectId)
            .ToListAsync(cancellationToken)).OrderByDescending(x => x.UploadedAt).FirstOrDefault();
        var discovery = latestImport is null ? null : new DiscoveryDashboardDto(
            latestImport.Id, latestImport.CommittedAt ?? latestImport.UploadedAt, latestImport.Status,
            latestImport.ValidRows, latestImport.CreateCount, latestImport.UpdateCount,
            latestImport.WarningCount, latestImport.RejectCount);
        return new DashboardSummaryDto(
            await applications.CountAsync(cancellationToken), await servers.CountAsync(cancellationToken),
            await applications.CountAsync(x => x.MigrationScope == "In Scope", cancellationToken),
            await applications.CountAsync(x => x.MigrationStatus == "Completed", cancellationToken),
            await servers.CountAsync(x => x.MigrationStatus == "Completed", cancellationToken), waves.Count,
            readiness.Values.Count(x => x == OverallReadinessStatuses.Ready), readiness.Values.Count(x => x == OverallReadinessStatuses.Blocked),
            await db.IpAddresses.CountAsync(x => x.ProjectId == context.ProjectId && x.Status == IpStatuses.Available, cancellationToken),
            await db.IpAddresses.CountAsync(x => x.ProjectId == context.ProjectId && x.Status == IpStatuses.Reserved, cancellationToken),
            await db.IpAddresses.CountAsync(x => x.ProjectId == context.ProjectId && x.Status == IpStatuses.Allocated, cancellationToken),
            statusGroups, waves, discovery);
    }

    private DateTimeOffset Now => timeProvider.GetUtcNow();

    private async Task<Application> FindApplicationAsync(Guid id, CancellationToken cancellationToken) =>
        await db.Applications.Include(x => x.ApplicationServers).ThenInclude(x => x.Server)
            .SingleOrDefaultAsync(x => x.Id == id && x.ProjectId == context.ProjectId, cancellationToken)
        ?? throw new KeyNotFoundException("Application not found.");

    private async Task<Server> FindServerAsync(Guid id, CancellationToken cancellationToken) =>
        await db.Servers.Include(x => x.ApplicationServers).ThenInclude(x => x.Application).Include(x => x.AzureTarget)
            .Include(x => x.LastImportBatch)
            .SingleOrDefaultAsync(x => x.Id == id && x.ProjectId == context.ProjectId, cancellationToken)
        ?? throw new KeyNotFoundException("Server not found.");

    private async Task RequireApplicationAsync(Guid id, CancellationToken cancellationToken)
    {
        if (!await db.Applications.AnyAsync(x => x.Id == id && x.ProjectId == context.ProjectId, cancellationToken))
            throw new DomainValidationException("Application does not exist in the current project.");
    }

    private async Task RequireServerAsync(Guid id, CancellationToken cancellationToken)
    {
        if (!await db.Servers.AnyAsync(x => x.Id == id && x.ProjectId == context.ProjectId, cancellationToken))
            throw new DomainValidationException("Server does not exist in the current project.");
    }

    private async Task SetApplicationServersAsync(Application entity, IReadOnlyList<Guid>? serverIds, CancellationToken cancellationToken)
    {
        db.ApplicationServers.RemoveRange(entity.ApplicationServers);
        entity.ApplicationServers.Clear();
        foreach (var serverId in (serverIds ?? []).Distinct())
        {
            await RequireServerAsync(serverId, cancellationToken);
            entity.ApplicationServers.Add(new ApplicationServer { Id = Guid.NewGuid(), CustomerId = context.CustomerId, ProjectId = context.ProjectId, ApplicationId = entity.Id, ServerId = serverId });
        }
    }

    private async Task SetServerApplicationsAsync(Server entity, IReadOnlyList<Guid>? applicationIds, CancellationToken cancellationToken)
    {
        db.ApplicationServers.RemoveRange(entity.ApplicationServers);
        entity.ApplicationServers.Clear();
        foreach (var applicationId in (applicationIds ?? []).Distinct())
        {
            await RequireApplicationAsync(applicationId, cancellationToken);
            entity.ApplicationServers.Add(new ApplicationServer { Id = Guid.NewGuid(), CustomerId = context.CustomerId, ProjectId = context.ProjectId, ApplicationId = applicationId, ServerId = entity.Id });
        }
    }

    private async Task<Dictionary<string, string>> GetAssetReadinessAsync(CancellationToken cancellationToken)
    {
        var checks = await db.ReadinessChecks.Where(x => x.ProjectId == context.ProjectId).Select(x => new { x.ApplicationId, x.ServerId, x.Status }).ToListAsync(cancellationToken);
        return checks.GroupBy(x => AssetKey(x.ApplicationId, x.ServerId)).ToDictionary(x => x.Key, x => readinessCalculator.Calculate(x.Select(y => y.Status)));
    }

    private static string AssetKey(Guid? applicationId, Guid? serverId) => applicationId.HasValue ? $"a:{applicationId}" : $"s:{serverId}";

    private void AddAudit(string entityType, Guid entityId, string action, Guid? projectId) => db.AuditEvents.Add(new AuditEvent
    {
        Id = Guid.NewGuid(), CustomerId = context.CustomerId, ProjectId = projectId, EntityType = entityType, EntityId = entityId,
        Action = action, ChangedBy = context.UserName, ChangedAt = Now
    });

    private static void ValidateDates(DateOnly? start, DateOnly? end)
    {
        if (start.HasValue && end.HasValue && end < start) throw new DomainValidationException("Planned end date cannot be before planned start date.");
    }

    private static CustomerDto Map(Customer x) => new(x.Id, x.Name, x.Code, x.Status, x.CreatedAt, x.UpdatedAt);
    private static ApplicationDto Map(Application x) => new(x.Id, x.CustomerId, x.ProjectId, x.Name, x.Environment, x.Description, x.Criticality,
        x.ApplicationType, x.CurrentVersion, x.MigrationScope, x.MigrationStrategy, x.MigrationStatus,
        x.ApplicationServers.OrderBy(y => y.Server.Hostname).Select(y => new NamedReferenceDto(y.ServerId, y.Server.Hostname)).ToList(), x.CreatedAt, x.UpdatedAt);
    private ServerDto Map(Server x) => new(x.Id, x.CustomerId, x.ProjectId, x.Hostname, x.Environment, x.OperatingSystem, x.IpAddress,
        x.VCores, x.MemoryMb, x.AllocatedStorageGb, x.PowerStatus, x.MigrationScope, x.MigrationStrategy, x.MigrationStatus,
        x.LastImportBatch?.SourceType, x.LastDiscoveredAt, x.LastImportedAt, x.SupportStatus, Freshness(x.LastDiscoveredAt),
        x.ApplicationServers.OrderBy(y => y.Application.Name).Select(y => new NamedReferenceDto(y.ApplicationId, y.Application.Name)).ToList(),
        x.AzureTarget is null ? null : new NamedReferenceDto(x.AzureTarget.Id, x.AzureTarget.AzureHostname), x.CreatedAt, x.UpdatedAt);

    private string Freshness(DateTimeOffset? lastDiscoveredAt)
    {
        if (!lastDiscoveredAt.HasValue) return DiscoveryFreshnessStatuses.Unknown;
        return timeProvider.GetUtcNow() - lastDiscoveredAt.Value <= TimeSpan.FromDays(discoveryOptions.Value.FreshnessThresholdDays)
            ? DiscoveryFreshnessStatuses.Current : DiscoveryFreshnessStatuses.Stale;
    }
    private static SubnetDto Map(Subnet x) => new(x.Id, x.Name, x.VNetName, x.Cidr, x.Environment, x.IpAddresses.Count,
        x.IpAddresses.Count(y => y.Status == IpStatuses.Available), x.IpAddresses.Count(y => y.Status == IpStatuses.Reserved),
        x.IpAddresses.Count(y => y.Status == IpStatuses.Allocated), x.CreatedAt, x.UpdatedAt);
    private static MigrationWaveDto Map(MigrationWave x, IReadOnlyDictionary<string, string> readiness)
    {
        var statuses = x.Assets.Select(a => readiness.GetValueOrDefault(AssetKey(a.ApplicationId, a.ServerId), OverallReadinessStatuses.NotReady)).ToArray();
        return new MigrationWaveDto(x.Id, x.Name, x.PlannedDate, x.Status, x.Description, x.Assets.Count(a => a.ApplicationId.HasValue),
            x.Assets.Count(a => a.ServerId.HasValue), statuses.Count(s => s == OverallReadinessStatuses.Ready),
            statuses.Count(s => s == OverallReadinessStatuses.Blocked), x.CreatedAt, x.UpdatedAt);
    }

    private static System.Linq.Expressions.Expression<Func<AzureTarget, AzureTargetDto>> TargetProjection() => x => new AzureTargetDto(
        x.Id, x.ServerId, x.Server.Hostname, x.Subscription, x.ResourceGroup, x.VNet, x.Subnet, x.AzureIp, x.AzureHostname,
        x.VmSize, x.OperatingSystem, x.BackupPolicy, x.Domain, x.OrganisationalUnit, x.Notes, x.CreatedAt, x.UpdatedAt);

    private static void Apply(Application x, ApplicationRequest r)
    {
        x.Name = r.Name.Trim(); x.Environment = r.Environment; x.Description = r.Description; x.Criticality = r.Criticality;
        x.ApplicationType = r.ApplicationType; x.CurrentVersion = r.CurrentVersion; x.MigrationScope = r.MigrationScope;
        x.MigrationStrategy = r.MigrationStrategy; x.MigrationStatus = r.MigrationStatus;
    }
    private static void Apply(Server x, ServerRequest r)
    {
        x.Hostname = r.Hostname.Trim().ToUpperInvariant(); x.Environment = r.Environment; x.OperatingSystem = r.OperatingSystem;
        x.IpAddress = r.IpAddress; x.VCores = r.VCores; x.MemoryMb = r.MemoryMb; x.AllocatedStorageGb = r.AllocatedStorageGb;
        x.PowerStatus = r.PowerStatus; x.MigrationStatus = r.MigrationStatus;
    }
    private static void Apply(MigrationDecision x, MigrationDecisionRequest r)
    {
        x.MigrationScope = r.MigrationScope; x.MigrationStrategy = r.MigrationStrategy; x.TargetPlatform = r.TargetPlatform;
        x.Reason = r.Reason; x.Risk = r.Risk; x.DecisionStatus = r.DecisionStatus; x.DecisionDate = r.DecisionDate;
    }
    private static void Apply(AzureTarget x, AzureTargetRequest r)
    {
        x.Subscription = r.Subscription; x.ResourceGroup = r.ResourceGroup; x.VNet = r.VNet; x.Subnet = r.Subnet; x.AzureIp = r.AzureIp;
        x.AzureHostname = r.AzureHostname; x.VmSize = r.VmSize; x.OperatingSystem = r.OperatingSystem; x.BackupPolicy = r.BackupPolicy;
        x.Domain = r.Domain; x.OrganisationalUnit = r.OrganisationalUnit; x.Notes = r.Notes;
    }
    private static void Apply(MigrationWave x, MigrationWaveRequest r)
    {
        x.Name = r.Name.Trim(); x.PlannedDate = r.PlannedDate; x.Status = r.Status; x.Description = r.Description;
    }
}
