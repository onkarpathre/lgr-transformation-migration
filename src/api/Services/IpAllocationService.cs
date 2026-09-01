using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Domain;
using LgrTransformationMigration.Api.Infrastructure;
using Microsoft.EntityFrameworkCore;

namespace LgrTransformationMigration.Api.Services;

public sealed class IpAllocationService(AppDbContext db, ICurrentCustomerContext context, TimeProvider timeProvider, IpTransitionPolicy transitionPolicy)
{
    public async Task<IpAddressDto> ReserveAsync(Guid id, Guid serverId, CancellationToken cancellationToken)
    {
        var address = await FindAsync(id, cancellationToken);
        transitionPolicy.Validate(address.Status, IpStatuses.Reserved);

        var serverExists = await db.Servers.AnyAsync(x => x.Id == serverId && x.ProjectId == context.ProjectId, cancellationToken);
        if (!serverExists)
        {
            throw new DomainValidationException("The selected server does not exist in the current customer and project.");
        }

        var alreadyAssigned = await db.IpAddresses.AnyAsync(x =>
            x.ServerId == serverId && x.Id != id && (x.Status == IpStatuses.Reserved || x.Status == IpStatuses.Allocated), cancellationToken);
        if (alreadyAssigned)
        {
            throw new DomainValidationException("The selected server already has an active IP reservation or allocation.");
        }

        address.ServerId = serverId;
        address.Status = IpStatuses.Reserved;
        address.ReservedAt = timeProvider.GetUtcNow();
        address.UpdatedAt = timeProvider.GetUtcNow();
        await db.SaveChangesAsync(cancellationToken);
        return await ToDtoAsync(address.Id, cancellationToken);
    }

    public async Task<IpAddressDto> AllocateAsync(Guid id, CancellationToken cancellationToken)
    {
        var address = await FindAsync(id, cancellationToken);
        transitionPolicy.Validate(address.Status, IpStatuses.Allocated);
        if (address.ServerId is null)
        {
            throw new DomainValidationException("Only a Reserved address with a server can be allocated.");
        }

        address.Status = IpStatuses.Allocated;
        address.AllocatedAt = timeProvider.GetUtcNow();
        address.UpdatedAt = timeProvider.GetUtcNow();
        await db.SaveChangesAsync(cancellationToken);
        return await ToDtoAsync(address.Id, cancellationToken);
    }

    public async Task<IpAddressDto> ReleaseAsync(Guid id, CancellationToken cancellationToken)
    {
        var address = await FindAsync(id, cancellationToken);
        transitionPolicy.Validate(address.Status, IpStatuses.Released);

        address.Status = IpStatuses.Released;
        address.UpdatedAt = timeProvider.GetUtcNow();
        await db.SaveChangesAsync(cancellationToken);
        return await ToDtoAsync(address.Id, cancellationToken);
    }

    private async Task<IpAddress> FindAsync(Guid id, CancellationToken cancellationToken) =>
        await db.IpAddresses.SingleOrDefaultAsync(x => x.Id == id && x.ProjectId == context.ProjectId, cancellationToken)
        ?? throw new KeyNotFoundException("IP address not found.");

    private async Task<IpAddressDto> ToDtoAsync(Guid id, CancellationToken cancellationToken) =>
        await db.IpAddresses.Where(x => x.Id == id).Select(x => new IpAddressDto(
            x.Id, x.SubnetId, x.Subnet.Name, x.Address, x.Status, x.ServerId, x.Server != null ? x.Server.Hostname : null,
            x.ReservedAt, x.AllocatedAt, x.CreatedAt, x.UpdatedAt)).SingleAsync(cancellationToken);
}
