using LgrTransformationMigration.Api.Infrastructure;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace LgrTransformationMigration.Api.UnitTests;

public sealed class MigrationDbContextFactoryTests
{
    [Fact]
    public void Creates_complete_sql_server_migration_context_without_configuration_files_or_connection()
    {
        var temporaryDirectory = Path.Combine(
            Path.GetTempPath(),
            $"lgrtm-migration-context-{Guid.NewGuid():N}");
        Directory.CreateDirectory(temporaryDirectory);

        var previousDirectory = Environment.CurrentDirectory;
        try
        {
            Environment.CurrentDirectory = temporaryDirectory;
            Assert.Empty(Directory.EnumerateFileSystemEntries(temporaryDirectory));

            using var context = new MigrationDbContextFactory().CreateDbContext([]);

            Assert.Equal("Microsoft.EntityFrameworkCore.SqlServer", context.Database.ProviderName);
            Assert.True(string.IsNullOrEmpty(context.Database.GetConnectionString()));

            var migrations = context.GetService<IMigrationsAssembly>();
            Assert.Equal(typeof(AppDbContext).Assembly, migrations.Assembly);
            Assert.NotNull(migrations.ModelSnapshot);
            Assert.Equal(
                [
                    "20260823111854_InitialCreate",
                    "20260824181918_AddDiscoveryImport",
                    "20260909164944_AddSqlInventory",
                    "20260910082037_AddInternalPrincipalAuditType",
                    "20260915171019_AddSqlDiscoveryImportHistory",
                    "20260916121802_EnforceDiscoveryImportRowTenantBatchOwnership",
                    "20260917001712_AddSqlAssessments",
                    "20260922151243_AddDependencyRegister"
                ],
                migrations.Migrations.Keys);

            var historyScript = context.GetService<IHistoryRepository>().GetCreateScript();
            Assert.Contains("CREATE TABLE [__EFMigrationsHistory]", historyScript, StringComparison.Ordinal);
        }
        finally
        {
            Environment.CurrentDirectory = previousDirectory;
            Directory.Delete(temporaryDirectory, recursive: true);
        }
    }
}
