using LgrTransformationMigration.Api.Domain;
using LgrTransformationMigration.Api.Infrastructure;
using Microsoft.EntityFrameworkCore;

namespace LgrTransformationMigration.Api.IntegrationTests;

/// <summary>
/// Tester-owned PH3-SQL-001 Slice 2 database-integrity assurance.
/// This test intentionally captures the approved tenant-leading relationship contract
/// independently of the implementation tests.
/// </summary>
public sealed class SqlDiscoveryImportTenantIntegrityTests
{
    [Fact]
    public void Staging_batch_relationship_is_tenant_and_project_scoped()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlServer(
                "Server=(local);Database=SyntheticSchemaOnly;Integrated Security=True;TrustServerCertificate=True")
            .Options;
        using var db = new AppDbContext(options, new FixedSyntheticContext());

        var stagingType = db.Model.FindEntityType(typeof(DiscoveryImportRow));
        Assert.NotNull(stagingType);
        var batchForeignKey = Assert.Single(
            stagingType.GetForeignKeys(),
            foreignKey => foreignKey.PrincipalEntityType.ClrType == typeof(ImportBatch));

        Assert.Equal(
            ["CustomerId", "ProjectId", "ImportBatchId"],
            batchForeignKey.Properties.Select(property => property.Name));
        Assert.Equal(
            ["CustomerId", "ProjectId", "Id"],
            batchForeignKey.PrincipalKey.Properties.Select(property => property.Name));
    }

    private sealed class FixedSyntheticContext : ICurrentCustomerContext
    {
        public Guid CustomerId => SeedIds.DemoCustomer;
        public Guid ProjectId => SeedIds.DemoProject;
        public string UserName => "local-test:tester-tenant-integrity";
        public string CorrelationId => "synthetic-tester-tenant-integrity";
        public InternalPrincipal Principal { get; } = new(
            Guid.Parse("74000000-0000-0000-0000-000000000001"),
            InternalPrincipalType.Human,
            "Synthetic",
            Guid.Parse("99999999-9999-9999-9999-999999999999"),
            Guid.Parse("74000000-0000-0000-0000-000000000001"),
            Guid.Parse("88888888-8888-8888-8888-888888888888"),
            "tester-tenant-integrity",
            "Synthetic Tester Tenant Integrity",
            InternalAuthenticationDefaults.LocalTestMode,
            true,
            true);
    }
}
