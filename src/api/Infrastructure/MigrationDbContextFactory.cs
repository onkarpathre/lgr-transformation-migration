using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace LgrTransformationMigration.Api.Infrastructure;

public sealed class MigrationDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
{
    public AppDbContext CreateDbContext(string[] args)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlServer()
            .Options;

        return new AppDbContext(options, new MigrationCustomerContext());
    }

    private sealed class MigrationCustomerContext : ICurrentCustomerContext
    {
        public Guid CustomerId => Guid.Empty;
        public Guid ProjectId => Guid.Empty;
        public string UserName => "ef-migration";
        public string CorrelationId => "ef-migration";

        public InternalPrincipal Principal => throw new InvalidOperationException(
            "The EF migration context has no interactive principal.");
    }
}
