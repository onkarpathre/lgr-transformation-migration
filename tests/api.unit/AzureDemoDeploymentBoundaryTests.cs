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
        Assert.Matches("(?ms)- name: deployAzureDemo\\s+type: boolean\\s+default: false", pipeline);
        Assert.Contains("refs/heads/release/azure-demo-v1", pipeline, StringComparison.Ordinal);
        Assert.Contains("deployToSlotOrASE: true", pipeline, StringComparison.Ordinal);
        Assert.Contains("slotName: staging", pipeline, StringComparison.Ordinal);
        Assert.Contains("ManualValidation@0", pipeline, StringComparison.Ordinal);
        Assert.Contains("environment: mtp-azure-demo-dev", pipeline, StringComparison.Ordinal);
        Assert.DoesNotContain("publishProfile:", pipeline, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Pipeline_swaps_api_before_web_and_rolls_back_web_before_api()
    {
        var root = FindRepositoryRoot();
        var pipeline = File.ReadAllText(Path.Combine(root, "azure-pipelines.yml"));
        var swapStage = pipeline[pipeline.IndexOf("- stage: SwapAndVerify", StringComparison.Ordinal)..pipeline.IndexOf("- stage: Rollback", StringComparison.Ordinal)];
        var rollbackStage = pipeline[pipeline.IndexOf("- stage: Rollback", StringComparison.Ordinal)..];

        Assert.True(swapStage.IndexOf("$(AZDEMO_API_APP_NAME)", StringComparison.Ordinal) < swapStage.IndexOf("$(AZDEMO_WEB_APP_NAME)", StringComparison.Ordinal));
        Assert.True(rollbackStage.IndexOf("--name $env:ROLLBACK_WEB_APP", StringComparison.Ordinal) < rollbackStage.IndexOf("--name $env:ROLLBACK_API_APP", StringComparison.Ordinal));
    }

    [Fact]
    public void Rollback_requires_exact_branch_release_environment_and_target_guard()
    {
        var root = FindRepositoryRoot();
        var pipeline = File.ReadAllText(Path.Combine(root, "azure-pipelines.yml"));
        var rollbackStage = pipeline[pipeline.IndexOf("- stage: Rollback", StringComparison.Ordinal)..];

        foreach (var fragment in new[]
        {
            "eq('${{ parameters.deployAzureDemo }}', true)",
            "eq('${{ parameters.rollbackAzureDemo }}', true)",
            "eq(variables['Build.SourceBranch'], 'refs/heads/release/azure-demo-v1')",
            "eq('${{ parameters.rollbackReleaseIdentifier }}', variables['Build.SourceVersion'])",
            "eq(variables['Build.DefinitionName'], 'mtp-azure-demo-deploy')",
            "eq('${{ parameters.rollbackEnvironmentName }}', 'mtp-azure-demo-dev')",
            "eq('${{ parameters.rollbackResourceGroupName }}', variables['AZDEMO_RESOURCE_GROUP_NAME'])",
            "eq('${{ parameters.rollbackWebAppName }}', variables['AZDEMO_WEB_APP_NAME'])",
            "eq('${{ parameters.rollbackApiAppName }}', variables['AZDEMO_API_APP_NAME'])",
            "in(dependencies.SwapAndVerify.result, 'Succeeded', 'SucceededWithIssues', 'Failed')",
            "Assert-AzureDemoRollbackTarget.ps1"
        })
        {
            Assert.Contains(fragment, rollbackStage, StringComparison.Ordinal);
        }

        Assert.True(rollbackStage.IndexOf("Assert-AzureDemoRollbackTarget.ps1", StringComparison.Ordinal) < rollbackStage.IndexOf("AzureCLI@2", StringComparison.Ordinal));
    }

    [Fact]
    public void Bicep_defines_every_approved_monitoring_alert_family_and_action_group_wiring()
    {
        var root = FindRepositoryRoot();
        var alerts = File.ReadAllText(Path.Combine(root, "infra", "bicep", "modules", "alerts.bicep"));
        var parameters = File.ReadAllText(Path.Combine(root, "infra", "bicep", "parameters", "azure-demo.bicepparam"));

        foreach (var alertName in new[]
        {
            "alert-mtp-web-health-dev-uks-001",
            "alert-mtp-api-readiness-dev-uks-001",
            "alert-mtp-web-http5xx-dev-uks-001",
            "alert-mtp-api-http5xx-dev-uks-001",
            "alert-mtp-unhandled-errors-dev-uks-001",
            "alert-mtp-auth-failures-denials-dev-uks-001",
            "alert-mtp-sql-cpu-dev-uks-001",
            "alert-mtp-sql-connectivity-dev-uks-001",
            "alert-mtp-keyvault-denial-dev-uks-001",
            "alert-mtp-blob-dependency-dev-uks-001",
            "alert-mtp-import-failure-dev-uks-001",
            "alert-mtp-storage-malware-dev-uks-001",
            "alert-mtp-failed-deployment-dev-uks-001",
            "alert-mtp-web-slot-health-dev-uks-001",
            "alert-mtp-api-slot-health-dev-uks-001",
            "alert-mtp-log-daily-cap-dev-uks-001",
            "alert-mtp-service-health-dev-uks-001"
        })
        {
            Assert.Contains(alertName, parameters, StringComparison.Ordinal);
        }

        Assert.Contains("actionGroupId: actionGroupId", alerts, StringComparison.Ordinal);
        Assert.Contains("Microsoft.Insights/webtests@2022-06-15", alerts, StringComparison.Ordinal);
        Assert.Contains("Microsoft.Insights/scheduledQueryRules@2023-12-01", alerts, StringComparison.Ordinal);
        Assert.Contains("Microsoft.Insights/activityLogAlerts@2020-10-01", alerts, StringComparison.Ordinal);
        Assert.Contains("metricName: 'cpu_percent'", alerts, StringComparison.Ordinal);
        Assert.Contains("metricNamespace: 'Microsoft.Sql/servers/databases'", alerts, StringComparison.Ordinal);
        Assert.Contains("metricNamespace: 'Microsoft.Web/sites/slots'", alerts, StringComparison.Ordinal);
        Assert.DoesNotContain("dtu_consumption_percent", alerts, StringComparison.Ordinal);
        Assert.DoesNotContain("app_cpu_percent", alerts, StringComparison.Ordinal);
    }

    [Fact]
    public void Deployment_targets_exact_existing_MTP_resources_and_no_obsolete_LGR_physical_estate()
    {
        var root = FindRepositoryRoot();
        var deploymentPaths = new[]
        {
            "azure-pipelines.yml",
            Path.Combine("infra", "bicep", "main.bicep"),
            Path.Combine("infra", "bicep", "parameters", "azure-demo.bicepparam"),
            Path.Combine("infra", "bicep", "modules", "appservice.bicep"),
            Path.Combine("infra", "bicep", "modules", "data.bicep"),
            Path.Combine("scripts", "database", "Configure-AzureDemoDatabasePrincipals.sql"),
            Path.Combine("scripts", "database", "Assert-AzureDemoMigrationTarget.ps1"),
            Path.Combine("scripts", "data", "Invoke-AzureDemoSeed.ps1"),
            Path.Combine("scripts", "smoke", "Invoke-AzureDemoSmokeTests.ps1")
        };
        var deployment = string.Join('\n', deploymentPaths.Select(path => File.ReadAllText(Path.Combine(root, path))));
        var main = File.ReadAllText(Path.Combine(root, "infra", "bicep", "main.bicep"));
        var parameters = File.ReadAllText(Path.Combine(root, "infra", "bicep", "parameters", "azure-demo.bicepparam"));
        var modules = string.Join('\n', Directory.GetFiles(Path.Combine(root, "infra", "bicep", "modules"), "*.bicep").Select(File.ReadAllText));

        foreach (var name in new[]
        {
            "Onkar.Pathre", "asp-mtp-dev-uks-001", "app-mtp-web-dev-uks-001", "app-mtp-api-dev-uks-001",
            "sql-mtp-dev-uks-001", "sqldb-mtp-dev-uks-001", "kv-mtp-dev-uks-op01", "appi-mtp-dev-uks-001",
            "log-mtp-dev-uks-001", "stmtpdevuks001", "vnet-mtp-dev-uks-001", "pep-sql-mtp-dev-uks-001",
            "privatelink.database.windows.net"
        })
        {
            Assert.Contains(name, parameters, StringComparison.Ordinal);
        }

        foreach (var obsolete in new[] { "app-lgrtm-", "sql-lgrtm-", "sqldb-lgrtm-", "asp-lgrtm-", "kvlgrtm", "stlgrtm", "vnet-lgrtm-", "pep-sql-lgrtm-" })
        {
            Assert.DoesNotContain(obsolete, deployment, StringComparison.OrdinalIgnoreCase);
        }

        Assert.Contains("Microsoft.Web/serverfarms@2023-12-01' existing", modules, StringComparison.Ordinal);
        Assert.Contains("Microsoft.Web/sites@2023-12-01' existing", modules, StringComparison.Ordinal);
        Assert.Contains("Microsoft.Sql/servers@2023-08-01-preview' existing", modules, StringComparison.Ordinal);
        Assert.Contains("Microsoft.Sql/servers/databases@2023-08-01-preview' existing", modules, StringComparison.Ordinal);
        Assert.Contains("Microsoft.Network/privateEndpoints@2024-05-01' existing", modules, StringComparison.Ordinal);
        Assert.Contains("assert exactResourceNames", main, StringComparison.Ordinal);
        Assert.Contains("Required existing MTP resource was not found", deployment, StringComparison.Ordinal);
        Assert.Contains("Assert-AzureDemoMigrationTarget.ps1", deployment, StringComparison.Ordinal);
    }

    [Fact]
    public void Deferred_internal_LGR_naming_remains_unchanged()
    {
        var root = FindRepositoryRoot();
        var pipeline = File.ReadAllText(Path.Combine(root, "azure-pipelines.yml"));
        var bundleWrapper = File.ReadAllText(Path.Combine(root, "scripts", "database", "Invoke-AzureDemoEfMigrationBundle.ps1"));

        const string migrationTaskDisplayName = "displayName: Execute reviewed EF bundle with dedicated migration workload identity";
        var migrationTaskDisplayNameIndex = pipeline.IndexOf(migrationTaskDisplayName, StringComparison.Ordinal);
        Assert.True(migrationTaskDisplayNameIndex >= 0, "The approved EF migration task is missing from azure-pipelines.yml.");

        var migrationTaskStartIndex = pipeline.LastIndexOf("          - task: AzureCLI@2", migrationTaskDisplayNameIndex, StringComparison.Ordinal);
        var migrationTaskEndIndex = pipeline.IndexOf("          - task:", migrationTaskDisplayNameIndex + migrationTaskDisplayName.Length, StringComparison.Ordinal);
        Assert.True(migrationTaskStartIndex >= 0 && migrationTaskEndIndex > migrationTaskStartIndex, "The approved EF migration AzureCLI task could not be isolated.");
        var migrationTask = pipeline[migrationTaskStartIndex..migrationTaskEndIndex];

        const string approvedWrapperInvocation = "./scripts/database/Invoke-AzureDemoEfMigrationBundle.ps1 -ImmutableArtifactRoot '$(Pipeline.Workspace)/azure-demo-immutable' -DeploymentManifestPath '$(Pipeline.Workspace)/azure-demo-immutable/deployment-artifact-manifest.json' -ExpectedSourceCommit '$(Build.SourceVersion)'";
        var activeWrapperInvocationPattern = $@"(?m)^\s+{System.Text.RegularExpressions.Regex.Escape(approvedWrapperInvocation)}\s*$";
        Assert.Single(System.Text.RegularExpressions.Regex.Matches(migrationTask, activeWrapperInvocationPattern).Cast<System.Text.RegularExpressions.Match>());

        const string approvedBundleIdentity = "$expectedBundlePath = Join-Path $artifactRoot 'migration/lgrtm-efbundle-linux-x64'";
        var activeBundleIdentityPattern = $@"(?m)^\s*{System.Text.RegularExpressions.Regex.Escape(approvedBundleIdentity)}\s*$";
        Assert.Single(System.Text.RegularExpressions.Regex.Matches(bundleWrapper, activeBundleIdentityPattern).Cast<System.Text.RegularExpressions.Match>());

        Assert.True(File.Exists(Path.Combine(root, "LgrTransformationMigration.sln")));
        Assert.True(File.Exists(Path.Combine(root, "src", "api", "LgrTransformationMigration.Api.csproj")));
        Assert.Contains("namespace LgrTransformationMigration.Api.Infrastructure", File.ReadAllText(Path.Combine(root, "src", "api", "Infrastructure", "AzureDemoInfrastructure.cs")), StringComparison.Ordinal);
        Assert.Contains("ConnectionStrings__LgrDatabase", File.ReadAllText(Path.Combine(root, "infra", "bicep", "modules", "appservice.bicep")), StringComparison.Ordinal);
        Assert.Contains("vg-mtp-azdemo-public", pipeline, StringComparison.Ordinal);
        Assert.Contains("sc-mtp-azure-demo-dev", pipeline, StringComparison.Ordinal);
        Assert.Contains("mtp-azure-demo-deploy", pipeline, StringComparison.Ordinal);
        Assert.Contains("mtp-azure-demo-dev", pipeline, StringComparison.Ordinal);
        Assert.Contains("mdp-mtp-dev-uks-001", pipeline, StringComparison.Ordinal);
        Assert.DoesNotContain("vg-lgrtm-azdemo-public", pipeline, StringComparison.Ordinal);
    }

    [Fact]
    public void EF_bundle_path_validation_preserves_links_until_rejection()
    {
        var root = FindRepositoryRoot();
        var wrapper = File.ReadAllText(Path.Combine(root, "scripts", "database", "Invoke-AzureDemoEfMigrationBundle.ps1"));
        var utilities = File.ReadAllText(Path.Combine(root, "scripts", "build", "AzureDemoDeploymentArtifactUtilities.ps1"));

        Assert.Contains("$artifactRoot = [IO.Path]::GetFullPath($ImmutableArtifactRoot)", wrapper, StringComparison.Ordinal);
        Assert.DoesNotContain("Resolve-Path -LiteralPath $ImmutableArtifactRoot", wrapper, StringComparison.Ordinal);
        Assert.Contains("[IO.File]::GetAttributes($current)", utilities, StringComparison.Ordinal);

        var resolverStart = utilities.IndexOf("function Resolve-AzureDemoArtifactPath", StringComparison.Ordinal);
        var resolverEnd = utilities.IndexOf("function ConvertTo-AzureDemoArtifactRelativePath", StringComparison.Ordinal);
        Assert.True(resolverStart >= 0 && resolverEnd > resolverStart, "The immutable artifact path resolver could not be isolated.");
        var resolver = utilities[resolverStart..resolverEnd];
        var reparseValidationIndex = resolver.IndexOf("Assert-AzureDemoNoReparsePoints", StringComparison.Ordinal);
        var rootExistenceIndex = resolver.IndexOf("Test-Path -LiteralPath $root -PathType Container", StringComparison.Ordinal);
        var candidateExistenceIndex = resolver.IndexOf("Test-Path -LiteralPath $candidate -PathType $PathType", StringComparison.Ordinal);
        Assert.True(reparseValidationIndex >= 0 && rootExistenceIndex > reparseValidationIndex && candidateExistenceIndex > reparseValidationIndex,
            "Symbolic-link validation must precede root and payload existence checks so dangling links cannot be misclassified as ordinary missing paths.");
    }

    [Fact]
    public void Bicep_routes_Defender_ScanResults_to_the_alert_workspace_at_the_exact_nested_scope()
    {
        var root = FindRepositoryRoot();
        var main = File.ReadAllText(Path.Combine(root, "infra", "bicep", "main.bicep"));
        var data = File.ReadAllText(Path.Combine(root, "infra", "bicep", "modules", "data.bicep"));
        var alerts = File.ReadAllText(Path.Combine(root, "infra", "bicep", "modules", "alerts.bicep"));

        Assert.Contains("resource storageDefender 'Microsoft.Security/defenderForStorageSettings@2022-12-01-preview'", data, StringComparison.Ordinal);
        Assert.Contains("scope: storage", data, StringComparison.Ordinal);
        Assert.Contains("name: 'current'", data, StringComparison.Ordinal);
        Assert.Contains("overrideSubscriptionLevelSettings: true", data, StringComparison.Ordinal);
        Assert.Contains("capGBPerMonth: 10", data, StringComparison.Ordinal);
        Assert.Contains("resource storageMalwareScanResultsDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview'", data, StringComparison.Ordinal);
        Assert.Contains("scope: storageDefender", data, StringComparison.Ordinal);
        Assert.Contains("name: 'service'", data, StringComparison.Ordinal);
        Assert.Contains("category: 'ScanResults'", data, StringComparison.Ordinal);
        Assert.Contains("workspaceId: logAnalyticsWorkspaceId", data, StringComparison.Ordinal);
        Assert.Contains("days: logRetentionDays", data, StringComparison.Ordinal);
        Assert.Contains("logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId", main, StringComparison.Ordinal);
        Assert.Contains("malwareScanResultsDiagnosticId: data.outputs.storageMalwareScanResultsDiagnosticId", main, StringComparison.Ordinal);
        Assert.Contains("/providers/microsoft.security/defenderforstoragesettings/current/providers/microsoft.insights/diagnosticsettings/service", alerts, StringComparison.Ordinal);
        Assert.Contains("StorageMalwareScanningResults", alerts, StringComparison.Ordinal);
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
