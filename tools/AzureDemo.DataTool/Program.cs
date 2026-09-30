using System.Security.Cryptography;
using System.Text.Json;
using LgrTransformationMigration.Api.Domain;
using LgrTransformationMigration.Api.Infrastructure;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

var arguments = args.Select((value, index) => (value, index))
    .Where(item => item.value.StartsWith("--", StringComparison.Ordinal) && item.index + 1 < args.Length)
    .ToDictionary(item => item.value, item => args[item.index + 1], StringComparer.Ordinal);

string Required(string name) => arguments.TryGetValue(name, out var value) && !string.IsNullOrWhiteSpace(value)
    ? value
    : throw new InvalidOperationException($"Required argument {name} was not supplied.");

if (Required("--environment") != "AzureDemo")
    throw new InvalidOperationException("The data tool refuses every environment except AzureDemo.");
if (Required("--resource-group") != "Onkar.Pathre")
    throw new InvalidOperationException("The data tool refuses an unapproved resource-group identifier.");
var manifestPath = Path.GetFullPath(Required("--manifest"));
var manifest = JsonSerializer.Deserialize<SeedManifest>(await File.ReadAllTextAsync(manifestPath),
    new JsonSerializerOptions { PropertyNameCaseInsensitive = true })
    ?? throw new InvalidOperationException("The seed manifest is invalid.");
if (manifest.SchemaVersion != "1" || manifest.Environment != "AzureDemo"
    || manifest.Classification != "synthetic"
    || manifest.CustomerId != SeedIds.DemoCustomer || manifest.ProjectId != SeedIds.DemoProject)
    throw new InvalidOperationException("The seed manifest is not approved for the AzureDemo synthetic project.");

var repositoryRoot = FindRepositoryRoot(Path.GetDirectoryName(manifestPath)!);
foreach (var sample in manifest.ApprovedSampleFiles)
{
    var samplePath = Path.GetFullPath(Path.Combine(repositoryRoot, sample.Path));
    if (!samplePath.StartsWith(repositoryRoot + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase)
        || !File.Exists(samplePath))
        throw new InvalidOperationException("An approved synthetic sample file is absent or outside the repository.");
    var sampleHash = Convert.ToHexString(SHA256.HashData(await File.ReadAllBytesAsync(samplePath))).ToLowerInvariant();
    if (!string.Equals(sampleHash, sample.Sha256, StringComparison.Ordinal))
        throw new InvalidOperationException("An approved synthetic sample file checksum does not match the manifest.");
}

var connectionString = Environment.GetEnvironmentVariable("LGR_AZURE_DEMO_SQL_CONNECTION_STRING");
if (string.IsNullOrWhiteSpace(connectionString))
    throw new InvalidOperationException("LGR_AZURE_DEMO_SQL_CONNECTION_STRING must be supplied by the protected seed stage.");
var sql = new SqlConnectionStringBuilder(connectionString);
var sqlHost = NormalizedSqlHost(sql.DataSource);
if (!sqlHost.StartsWith("sql-lgrtm-azdemo-uks-", StringComparison.OrdinalIgnoreCase)
    || !sqlHost.EndsWith(".database.windows.net", StringComparison.OrdinalIgnoreCase)
    || sql.InitialCatalog != Required("--database")
    || sql.Authentication != SqlAuthenticationMethod.ActiveDirectoryManagedIdentity
    || !sql.Encrypt || sql.TrustServerCertificate || !string.IsNullOrEmpty(sql.Password)
    || !Guid.TryParse(sql.UserID, out var managedIdentityClientId) || managedIdentityClientId == Guid.Empty)
    throw new InvalidOperationException("The seed tool requires the exact passwordless Azure SQL demo database.");

var context = new SyntheticContext();
var options = new DbContextOptionsBuilder<AppDbContext>().UseSqlServer(connectionString).Options;
await using var database = new AppDbContext(options, context);
var pending = await database.Database.GetPendingMigrationsAsync();
if (pending.Any())
    throw new InvalidOperationException("The data tool never migrates; apply the reviewed migration bundle first.");

var now = DateTimeOffset.UtcNow;
var sqlInstanceId = Guid.Parse("55555555-5555-5555-5555-555555555501");
var sqlDatabaseId = Guid.Parse("55555555-5555-5555-5555-555555555502");
var assessmentId = Guid.Parse("55555555-5555-5555-5555-555555555503");
var referenceId = Guid.Parse("66666666-6666-6666-6666-666666666601");
var dependencyId = Guid.Parse("66666666-6666-6666-6666-666666666602");
var serverId = Guid.Parse("bbbbbbbb-bbbb-bbbb-bbbb-000000000002");
var applicationId = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-000000000001");

if (!await database.SqlInstances.AnyAsync(x => x.Id == sqlInstanceId))
    database.SqlInstances.Add(new SqlInstance { Id = sqlInstanceId, CustomerId = context.CustomerId, ProjectId = context.ProjectId, ServerId = serverId, InstanceName = "MSSQLSERVER", NormalizedInstanceName = "MSSQLSERVER", SqlVersion = "SQL Server 2022", Edition = "Standard", Port = 1433, ServiceStatus = "Running", DiscoverySource = "SyntheticSeed", CreatedAt = now, UpdatedAt = now, CreatedBy = "azure-demo-seed", UpdatedBy = "azure-demo-seed" });
if (!await database.SqlDatabases.AnyAsync(x => x.Id == sqlDatabaseId))
    database.SqlDatabases.Add(new SqlDatabase { Id = sqlDatabaseId, CustomerId = context.CustomerId, ProjectId = context.ProjectId, SqlInstanceId = sqlInstanceId, Name = "HousingSynthetic", NormalizedName = "HOUSINGSYNTHETIC", SizeMb = 8192, CompatibilityLevel = 160, RecoveryModel = "Full", Collation = "Latin1_General_100_CI_AS_SC", Status = "Online", CreatedAt = now, UpdatedAt = now, CreatedBy = "azure-demo-seed", UpdatedBy = "azure-demo-seed" });
if (!await database.SqlAssessments.AnyAsync(x => x.Id == assessmentId))
    database.SqlAssessments.Add(new SqlAssessment { Id = assessmentId, CustomerId = context.CustomerId, ProjectId = context.ProjectId, SqlDatabaseId = sqlDatabaseId, AssessmentStatus = SqlAssessmentStatuses.InProgress, ReadinessStatus = SqlReadinessStatuses.AtRisk, TargetPlatform = SqlAssessmentTargetPlatforms.AzureSqlManagedInstance, MigrationApproach = SqlMigrationApproaches.ToBeDetermined, Blockers = "Synthetic vendor compatibility review outstanding.", Findings = "Synthetic assessment record for management demonstration only.", Notes = "Planning data; this record cannot execute a migration.", CreatedAt = now, UpdatedAt = now, CreatedBy = "azure-demo-seed", UpdatedBy = "azure-demo-seed" });
if (!await database.DependencyReferences.AnyAsync(x => x.Id == referenceId))
    database.DependencyReferences.Add(new DependencyReference { Id = referenceId, CustomerId = context.CustomerId, ProjectId = context.ProjectId, ReferenceType = DependencyReferenceTypes.ExternalSystem, Name = "Synthetic Workforce Identity", NormalizedName = "SYNTHETIC WORKFORCE IDENTITY", Description = "Fictional controlled reference for the restricted demonstration.", ResolutionStatus = DependencyResolutionStatuses.Resolved, CreatedAt = now, UpdatedAt = now, CreatedBy = "azure-demo-seed", UpdatedBy = "azure-demo-seed" });
if (!await database.Dependencies.AnyAsync(x => x.Id == dependencyId))
    database.Dependencies.Add(new Dependency { Id = dependencyId, CustomerId = context.CustomerId, ProjectId = context.ProjectId, SourceType = DependencyAssetTypes.Application, SourceApplicationId = applicationId, SourceEndpointKey = DependencyEndpointKeys.Create(DependencyAssetTypes.Application, applicationId), TargetType = DependencyAssetTypes.DependencyReference, TargetReferenceId = referenceId, TargetEndpointKey = DependencyEndpointKeys.Create(DependencyAssetTypes.DependencyReference, referenceId), DependencyType = DependencyTypes.Authentication, Criticality = DependencyCriticalities.Mandatory, Description = "Synthetic authentication dependency.", BusinessContext = "Demonstrates a human-governed planning record only.", ConfirmationStatus = DependencyConfirmationStatuses.Confirmed, ConfirmedAt = now, ConfirmedBy = "azure-demo-seed", CreatedAt = now, UpdatedAt = now, CreatedBy = "azure-demo-seed", UpdatedBy = "azure-demo-seed" });

await database.SaveChangesAsync();
var actual = new Dictionary<string, int>(StringComparer.Ordinal)
{
    ["customers"] = await database.Customers.CountAsync(),
    ["projects"] = await database.Projects.CountAsync(x => x.Id == context.ProjectId),
    ["applications"] = await database.Applications.CountAsync(x => x.ProjectId == context.ProjectId),
    ["servers"] = await database.Servers.CountAsync(x => x.ProjectId == context.ProjectId),
    ["sqlInstances"] = await database.SqlInstances.CountAsync(x => x.ProjectId == context.ProjectId),
    ["sqlDatabases"] = await database.SqlDatabases.CountAsync(x => x.ProjectId == context.ProjectId),
    ["sqlAssessments"] = await database.SqlAssessments.CountAsync(x => x.ProjectId == context.ProjectId),
    ["dependencyReferences"] = await database.DependencyReferences.CountAsync(x => x.ProjectId == context.ProjectId),
    ["dependencies"] = await database.Dependencies.CountAsync(x => x.ProjectId == context.ProjectId),
    ["waves"] = await database.MigrationWaves.CountAsync(x => x.ProjectId == context.ProjectId),
    ["runbooks"] = await database.Runbooks.CountAsync(x => x.ProjectId == context.ProjectId)
};
foreach (var expected in manifest.MinimumCounts)
    if (!actual.TryGetValue(expected.Key, out var count) || count < expected.Value)
        throw new InvalidOperationException($"Synthetic seed reconciliation failed for {expected.Key}.");

var manifestHash = Convert.ToHexString(SHA256.HashData(await File.ReadAllBytesAsync(manifestPath))).ToLowerInvariant();
Console.WriteLine(JsonSerializer.Serialize(new { status = "reconciled", manifestVersion = manifest.ManifestVersion, manifestSha256 = manifestHash, counts = actual }));

static string FindRepositoryRoot(string start)
{
    var current = new DirectoryInfo(start);
    while (current is not null && !File.Exists(Path.Combine(current.FullName, "LgrTransformationMigration.sln")))
        current = current.Parent;
    return current?.FullName ?? throw new InvalidOperationException("Repository root was not found for seed validation.");
}

static string NormalizedSqlHost(string dataSource)
{
    var value = dataSource.Trim();
    if (value.StartsWith("tcp:", StringComparison.OrdinalIgnoreCase)) value = value[4..];
    var comma = value.IndexOf(',');
    return comma >= 0 ? value[..comma] : value;
}

sealed class SyntheticContext : ICurrentCustomerContext
{
    public Guid CustomerId => SeedIds.DemoCustomer;
    public Guid ProjectId => SeedIds.DemoProject;
    public string UserName => "azure-demo-seed";
    public string CorrelationId => Guid.NewGuid().ToString("N");
    public InternalPrincipal Principal => throw new InvalidOperationException("The controlled data tool has no interactive principal.");
}

sealed class SeedManifest
{
    public string SchemaVersion { get; set; } = string.Empty;
    public string ManifestVersion { get; set; } = string.Empty;
    public string Environment { get; set; } = string.Empty;
    public string Classification { get; set; } = string.Empty;
    public Guid CustomerId { get; set; }
    public Guid ProjectId { get; set; }
    public Dictionary<string, int> MinimumCounts { get; set; } = [];
    public List<ApprovedSampleFile> ApprovedSampleFiles { get; set; } = [];
}

sealed class ApprovedSampleFile
{
    public string Path { get; set; } = string.Empty;
    public string Sha256 { get; set; } = string.Empty;
}
