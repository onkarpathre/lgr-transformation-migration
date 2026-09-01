using LgrTransformationMigration.Api.Domain;
using LgrTransformationMigration.Api.Infrastructure;
using LgrTransformationMigration.Api.Services.Discovery;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Logging;

namespace LgrTransformationMigration.Api.IntegrationTests;

public sealed class LgrWebApplicationFactory : WebApplicationFactory<Program>
{
    private readonly SqliteConnection _connection = new("Data Source=:memory:");
    private readonly string _storagePath = Path.Combine(Path.GetTempPath(), "lgr-discovery-import-tests", Guid.NewGuid().ToString("N"));

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        _connection.Open();
        builder.UseEnvironment("Testing");
        builder.ConfigureLogging(logging => logging.ClearProviders());
        builder.ConfigureServices(services =>
        {
            services.RemoveAll<AppDbContext>();
            services.RemoveAll<DbContextOptions>();
            services.RemoveAll<DbContextOptions<AppDbContext>>();
            services.RemoveAll<IDbContextOptionsConfiguration<AppDbContext>>();
            services.AddDbContext<AppDbContext>(options => options.UseSqlite(_connection));
            services.PostConfigure<DiscoveryImportOptions>(options => options.LocalStoragePath = _storagePath);

            using var provider = services.BuildServiceProvider();
            using var scope = provider.CreateScope();
            scope.ServiceProvider.GetRequiredService<AppDbContext>().Database.EnsureCreated();
        });
    }

    public async Task<(Guid CustomerId, Guid ProjectId)> SeedSecondTenantAsync()
    {
        var customerId = Guid.Parse("eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee");
        var projectId = Guid.Parse("ffffffff-ffff-ffff-ffff-ffffffffffff");
        using var scope = Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var now = DateTimeOffset.UtcNow;
        db.Customers.Add(new Customer { Id = customerId, Name = "Other Council", Code = "OTHER", Status = "Active", CreatedAt = now, UpdatedAt = now });
        db.Projects.Add(new Project { Id = projectId, CustomerId = customerId, Name = "Other Programme", Description = "Isolation fixture", Status = "Active", CreatedAt = now, UpdatedAt = now });
        db.Applications.Add(new Application { Id = Guid.NewGuid(), CustomerId = customerId, ProjectId = projectId, Name = "Other Housing", Environment = "Prod", Description = "Other tenant", Criticality = "High", ApplicationType = "COTS", CurrentVersion = "1", MigrationScope = "In Scope", MigrationStrategy = "Rehost", MigrationStatus = "Not Started", CreatedAt = now, UpdatedAt = now });
        db.Servers.Add(new Server { Id = Guid.NewGuid(), CustomerId = customerId, ProjectId = projectId, Hostname = "OTHER-APP01", Environment = "Prod", OperatingSystem = "Windows Server 2022", IpAddress = "192.0.2.10", VCores = 2, MemoryMb = 4096, AllocatedStorageGb = 100, PowerStatus = "On", MigrationStatus = "Not Started", CreatedAt = now, UpdatedAt = now });
        await db.SaveChangesAsync();
        return (customerId, projectId);
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        if (disposing)
        {
            _connection.Dispose();
            var safeRoot = Path.GetFullPath(Path.Combine(Path.GetTempPath(), "lgr-discovery-import-tests"));
            var resolved = Path.GetFullPath(_storagePath);
            if (resolved.StartsWith(safeRoot + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase) && Directory.Exists(resolved))
                Directory.Delete(resolved, recursive: true);
        }
    }
}
