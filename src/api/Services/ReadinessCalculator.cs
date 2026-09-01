using LgrTransformationMigration.Api.Domain;

namespace LgrTransformationMigration.Api.Services;

public sealed class ReadinessCalculator
{
    public string Calculate(IEnumerable<string> statuses)
    {
        var values = statuses.ToArray();
        if (values.Length == 0)
        {
            return OverallReadinessStatuses.NotReady;
        }

        if (values.Contains(ReadinessStatuses.Blocked, StringComparer.OrdinalIgnoreCase))
        {
            return OverallReadinessStatuses.Blocked;
        }

        if (values.Contains(ReadinessStatuses.NotStarted, StringComparer.OrdinalIgnoreCase))
        {
            return OverallReadinessStatuses.NotReady;
        }

        var atRisk = values.Count(x => x.Equals(ReadinessStatuses.AtRisk, StringComparison.OrdinalIgnoreCase));
        if (atRisk > 1)
        {
            return OverallReadinessStatuses.AtRisk;
        }

        if (atRisk == 1)
        {
            return OverallReadinessStatuses.ReadyWithConditions;
        }

        return values.All(x => x.Equals(ReadinessStatuses.Complete, StringComparison.OrdinalIgnoreCase) ||
                               x.Equals(ReadinessStatuses.NotApplicable, StringComparison.OrdinalIgnoreCase))
            ? OverallReadinessStatuses.Ready
            : OverallReadinessStatuses.NotReady;
    }
}
