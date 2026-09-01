using LgrTransformationMigration.Api.Infrastructure;

namespace LgrTransformationMigration.Api.UnitTests;

public sealed class RunbookTemplateTests
{
    [Fact]
    public void Default_template_has_ordered_migration_lifecycle()
    {
        Assert.Equal(13, RunbookTemplate.DefaultTasks.Length);
        Assert.Equal("Pre-Migration Checks", RunbookTemplate.DefaultTasks[0]);
        Assert.Equal("Migration Completion", RunbookTemplate.DefaultTasks[^1]);
        Assert.Equal(2, RunbookTemplate.DefaultTasks.Count(x => x == "Backup Validation"));
    }
}
