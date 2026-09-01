using LgrTransformationMigration.Api.Domain;

namespace LgrTransformationMigration.Api.Services;

public sealed class IpTransitionPolicy
{
    private static readonly HashSet<(string From, string To)> Allowed =
    [
        (IpStatuses.Available, IpStatuses.Reserved),
        (IpStatuses.Reserved, IpStatuses.Allocated),
        (IpStatuses.Allocated, IpStatuses.Released)
    ];

    public void Validate(string from, string to)
    {
        if (!Allowed.Contains((from, to)))
        {
            throw new DomainValidationException($"IP address transition {from} -> {to} is not allowed.");
        }
    }
}
