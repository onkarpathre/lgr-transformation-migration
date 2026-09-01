using LgrTransformationMigration.Api.Domain;
using LgrTransformationMigration.Api.Services;

namespace LgrTransformationMigration.Api.UnitTests;

public sealed class IpTransitionPolicyTests
{
    private readonly IpTransitionPolicy _policy = new();

    [Theory]
    [InlineData(IpStatuses.Available, IpStatuses.Reserved)]
    [InlineData(IpStatuses.Reserved, IpStatuses.Allocated)]
    [InlineData(IpStatuses.Allocated, IpStatuses.Released)]
    public void Required_transitions_are_allowed(string from, string to) => _policy.Validate(from, to);

    [Theory]
    [InlineData(IpStatuses.Available, IpStatuses.Allocated)]
    [InlineData(IpStatuses.Reserved, IpStatuses.Released)]
    [InlineData(IpStatuses.Released, IpStatuses.Reserved)]
    public void Invalid_transitions_are_rejected(string from, string to) =>
        Assert.Throws<DomainValidationException>(() => _policy.Validate(from, to));
}
