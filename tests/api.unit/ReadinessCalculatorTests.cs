using LgrTransformationMigration.Api.Domain;
using LgrTransformationMigration.Api.Services;

namespace LgrTransformationMigration.Api.UnitTests;

public sealed class ReadinessCalculatorTests
{
    private readonly ReadinessCalculator _calculator = new();

    [Theory]
    [InlineData(OverallReadinessStatuses.NotReady)]
    public void No_checks_is_not_ready(string expected) => Assert.Equal(expected, _calculator.Calculate([]));

    [Fact]
    public void Blocked_takes_precedence() => Assert.Equal(OverallReadinessStatuses.Blocked,
        _calculator.Calculate([ReadinessStatuses.Complete, ReadinessStatuses.Blocked, ReadinessStatuses.NotStarted]));

    [Fact]
    public void Not_started_is_not_ready() => Assert.Equal(OverallReadinessStatuses.NotReady,
        _calculator.Calculate([ReadinessStatuses.Complete, ReadinessStatuses.NotStarted]));

    [Fact]
    public void One_risk_is_ready_with_conditions() => Assert.Equal(OverallReadinessStatuses.ReadyWithConditions,
        _calculator.Calculate([ReadinessStatuses.Complete, ReadinessStatuses.AtRisk]));

    [Fact]
    public void Multiple_risks_are_at_risk() => Assert.Equal(OverallReadinessStatuses.AtRisk,
        _calculator.Calculate([ReadinessStatuses.AtRisk, ReadinessStatuses.Complete, ReadinessStatuses.AtRisk]));

    [Fact]
    public void Complete_and_not_applicable_are_ready() => Assert.Equal(OverallReadinessStatuses.Ready,
        _calculator.Calculate([ReadinessStatuses.Complete, ReadinessStatuses.NotApplicable]));
}
