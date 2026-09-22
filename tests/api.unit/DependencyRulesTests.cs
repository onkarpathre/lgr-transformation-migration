using LgrTransformationMigration.Api.Domain;
using LgrTransformationMigration.Api.Infrastructure;

namespace LgrTransformationMigration.Api.UnitTests;

public sealed class DependencyRulesTests
{
    [Theory]
    [InlineData("MigrationArchitect", true, true, true, true, true)]
    [InlineData("DatabaseSme", true, true, true, true, true)]
    [InlineData("ProjectManager", true, false, false, true, true)]
    [InlineData("DiscoveryAnalyst", true, false, false, false, false)]
    [InlineData("ReviewerAuditor", true, false, false, false, true)]
    [InlineData("CustomerAdministrator", false, false, false, false, false)]
    [InlineData("PlatformAdministrator", false, false, false, false, false)]
    [InlineData("UnexpectedRole", false, false, false, false, false)]
    public void Dependency_role_mapping_is_exact_and_deny_by_default(
        string role,
        bool read,
        bool manage,
        bool confirm,
        bool validate,
        bool auditRead)
    {
        var permissions = DependencyPermissions.ForRoles([role]);

        Assert.Equal(read, permissions.Contains(DependencyPermissions.Read));
        Assert.Equal(manage, permissions.Contains(DependencyPermissions.Manage));
        Assert.Equal(confirm, permissions.Contains(DependencyPermissions.Confirm));
        Assert.Equal(validate, permissions.Contains(DependencyPermissions.Validate));
        Assert.Equal(auditRead, permissions.Contains(DependencyPermissions.AuditRead));
    }

    [Fact]
    public void Multiple_roles_produce_only_the_documented_dependency_union()
    {
        var permissions = DependencyPermissions.ForRoles(
            ["DiscoveryAnalyst", "ReviewerAuditor", "UnexpectedRole"]);

        Assert.True(permissions.SetEquals([DependencyPermissions.Read, DependencyPermissions.AuditRead]));
    }

    [Theory]
    [InlineData("Service", "Application", "Server", null, true)]
    [InlineData("Service", "Application", "DependencyReference", "FileShare", false)]
    [InlineData("Service", "Application", "DependencyReference", "ExternalSystem", true)]
    [InlineData("DataRead", "SqlDatabase", "DependencyReference", "FileShare", true)]
    [InlineData("DataWrite", "Application", "Application", null, false)]
    [InlineData("ApiCall", "Application", "DependencyReference", "Api", true)]
    [InlineData("ApiCall", "SqlInstance", "DependencyReference", "Api", false)]
    [InlineData("FileTransfer", "SqlInstance", "Server", null, true)]
    [InlineData("FileTransfer", "SqlDatabase", "Server", null, false)]
    [InlineData("Authentication", "Server", "Application", null, true)]
    [InlineData("Authentication", "SqlDatabase", "Application", null, false)]
    [InlineData("NetworkConnectivity", "SqlDatabase", "DependencyReference", "FileShare", true)]
    [InlineData("OperationalSequence", "Application", "SqlDatabase", null, true)]
    [InlineData("OperationalSequence", "Application", "DependencyReference", "ExternalSystem", false)]
    public void Dependency_type_matrix_matches_the_approved_contract(
        string dependencyType,
        string sourceType,
        string targetType,
        string? referenceType,
        bool expected) =>
        Assert.Equal(expected, DependencyTypes.IsAllowed(dependencyType, sourceType, targetType, referenceType));

    [Theory]
    [InlineData("<script>alert(1)</script>")]
    [InlineData("Password=synthetic-secret")]
    [InlineData("AccountKey=synthetic-secret")]
    [InlineData("Bearer abcdefghijklmnopqrstuvwxyz")]
    [InlineData("eyJabcdefgh.abcdefghijkl.abcdefghijkl")]
    [InlineData("https://example.invalid/path?sig=synthetic")]
    [InlineData("-----BEGIN PRIVATE KEY-----")]
    public void Narrative_rejects_markup_and_secret_like_content(string value) =>
        Assert.Throws<DomainValidationException>(() => DependencyText.Optional(value, 2000, "Description"));

    [Fact]
    public void Narrative_is_trimmed_and_unicode_normalized()
    {
        var value = DependencyText.Required("  Cafe\u0301 service  ", 200, "Name");

        Assert.Equal("Caf\u00e9 service", value);
        Assert.Equal("CAF\u00c9 SERVICE", DependencyText.NormalizedName(value));
    }
}
