namespace LgrTransformationMigration.Api.UnitTests;

public sealed class AzureDemoDeploymentBoundaryTests
{
    [Fact]
    public void Api_startup_contains_no_migration_ensure_created_or_seed_invocation()
    {
        var root = FindRepositoryRoot();
        var startup = File.ReadAllText(Path.Combine(root, "src", "api", "Program.cs"));

        Assert.DoesNotContain("Database.Migrate", startup, StringComparison.Ordinal);
        Assert.DoesNotContain("MigrateAsync", startup, StringComparison.Ordinal);
        Assert.DoesNotContain("EnsureCreated", startup, StringComparison.Ordinal);
        Assert.DoesNotContain("SeedData.Configure", startup, StringComparison.Ordinal);
    }

    [Fact]
    public void LocalTest_configuration_is_explicitly_excluded_from_publish()
    {
        var root = FindRepositoryRoot();
        var project = File.ReadAllText(Path.Combine(root, "src", "api", "LgrTransformationMigration.Api.csproj"));

        Assert.Contains("appsettings.LocalTest.json", project, StringComparison.Ordinal);
        Assert.Contains("appsettings.Development.json", project, StringComparison.Ordinal);
        Assert.Contains("appsettings.Testing.json", project, StringComparison.Ordinal);
        Assert.Contains("CopyToPublishDirectory=\"Never\"", project, StringComparison.Ordinal);
    }

    [Fact]
    public void Pipeline_requires_disabled_by_default_slot_only_deployment_and_human_gate()
    {
        var root = FindRepositoryRoot();
        var pipeline = File.ReadAllText(Path.Combine(root, "azure-pipelines.yml"));

        Assert.Contains("default: false", pipeline, StringComparison.Ordinal);
        Assert.Contains("refs/heads/release/azure-demo-v1", pipeline, StringComparison.Ordinal);
        Assert.Contains("deployToSlotOrASE: true", pipeline, StringComparison.Ordinal);
        Assert.Contains("slotName: staging", pipeline, StringComparison.Ordinal);
        Assert.Contains("ManualValidation@0", pipeline, StringComparison.Ordinal);
        Assert.Contains("environment: azure-demo", pipeline, StringComparison.Ordinal);
        Assert.DoesNotContain("publishProfile:", pipeline, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Pipeline_swaps_api_before_web_and_rolls_back_web_before_api()
    {
        var root = FindRepositoryRoot();
        var pipeline = File.ReadAllText(Path.Combine(root, "azure-pipelines.yml"));
        var swapStage = pipeline[pipeline.IndexOf("- stage: SwapAndVerify", StringComparison.Ordinal)..pipeline.IndexOf("- stage: Rollback", StringComparison.Ordinal)];
        var rollbackStage = pipeline[pipeline.IndexOf("- stage: Rollback", StringComparison.Ordinal)..];

        Assert.True(swapStage.IndexOf("$(apiAppName)", StringComparison.Ordinal) < swapStage.IndexOf("$(webAppName)", StringComparison.Ordinal));
        Assert.True(rollbackStage.IndexOf("$(webAppName)", StringComparison.Ordinal) < rollbackStage.IndexOf("$(apiAppName)", StringComparison.Ordinal));
    }

    [Fact]
    public void Application_has_no_resource_manager_or_direct_discovery_api_dependency()
    {
        var root = FindRepositoryRoot();
        var applicationFiles = Directory.GetFiles(Path.Combine(root, "src"), "*", SearchOption.AllDirectories)
            .Where(path => !path.Contains($"{Path.DirectorySeparatorChar}bin{Path.DirectorySeparatorChar}")
                && !path.Contains($"{Path.DirectorySeparatorChar}obj{Path.DirectorySeparatorChar}")
                && !path.Contains($"{Path.DirectorySeparatorChar}node_modules{Path.DirectorySeparatorChar}")
                && !path.Contains($"{Path.DirectorySeparatorChar}.next{Path.DirectorySeparatorChar}"));
        var content = string.Join('\n', applicationFiles.Select(File.ReadAllText));

        Assert.DoesNotContain("Azure.ResourceManager", content, StringComparison.Ordinal);
        Assert.DoesNotContain("Microsoft.Azure.Management", content, StringComparison.Ordinal);
        Assert.DoesNotContain("api.migrate.azure.com", content, StringComparison.OrdinalIgnoreCase);
    }

    private static string FindRepositoryRoot()
    {
        var current = new DirectoryInfo(AppContext.BaseDirectory);
        while (current is not null && !File.Exists(Path.Combine(current.FullName, "LgrTransformationMigration.sln"))) current = current.Parent;
        return current?.FullName ?? throw new InvalidOperationException("Repository root not found.");
    }
}
