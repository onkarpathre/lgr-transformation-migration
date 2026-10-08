-- Tester-owned, read-only owner-run validation for the protected AzureDemo runtime identity.
-- Execute only from the approved private agent after platform/DBA approval.
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_NAME() <> N'sqldb-lgrtm-azdemo'
    THROW 51000, 'Refusing to validate any database except sqldb-lgrtm-azdemo.', 1;

IF HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'CONTROL') = 1
   OR HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'ALTER ANY USER') = 1
   OR HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'ALTER ANY SCHEMA') = 1
   OR HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'CREATE TABLE') = 1
    THROW 51001, 'Runtime identity has prohibited database control or DDL permission.', 1;

DECLARE @ExpectedMigrations table (MigrationId nvarchar(150) NOT NULL PRIMARY KEY);
INSERT INTO @ExpectedMigrations (MigrationId) VALUES
    (N'20260823111854_InitialCreate'),
    (N'20260824181918_AddDiscoveryImport'),
    (N'20260909164944_AddSqlInventory'),
    (N'20260910082037_AddInternalPrincipalAuditType'),
    (N'20260915171019_AddSqlDiscoveryImportHistory'),
    (N'20260916121802_EnforceDiscoveryImportRowTenantBatchOwnership'),
    (N'20260917001712_AddSqlAssessments'),
    (N'20260922151243_AddDependencyRegister');

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'__EFMigrationsHistory')
    THROW 51002, 'EF migration history is absent.', 1;

IF EXISTS (
    SELECT MigrationId FROM @ExpectedMigrations
    EXCEPT
    SELECT MigrationId FROM dbo.__EFMigrationsHistory
) OR EXISTS (
    SELECT MigrationId FROM dbo.__EFMigrationsHistory
    EXCEPT
    SELECT MigrationId FROM @ExpectedMigrations
)
    THROW 51003, 'EF migration history does not exactly match the candidate manifest.', 1;

DECLARE @SyntheticProject uniqueidentifier = '22222222-2222-2222-2222-222222222222';
IF NOT EXISTS (SELECT 1 FROM dbo.Projects WHERE Id = @SyntheticProject)
    THROW 51004, 'Approved synthetic project is absent.', 1;
IF NOT EXISTS (SELECT 1 FROM dbo.Applications WHERE ProjectId = @SyntheticProject)
   OR NOT EXISTS (SELECT 1 FROM dbo.Servers WHERE ProjectId = @SyntheticProject)
   OR NOT EXISTS (SELECT 1 FROM dbo.SqlInstances WHERE ProjectId = @SyntheticProject)
   OR NOT EXISTS (SELECT 1 FROM dbo.SqlDatabases WHERE ProjectId = @SyntheticProject)
   OR NOT EXISTS (SELECT 1 FROM dbo.SqlAssessments WHERE ProjectId = @SyntheticProject)
   OR NOT EXISTS (SELECT 1 FROM dbo.DependencyReferences WHERE ProjectId = @SyntheticProject)
   OR NOT EXISTS (SELECT 1 FROM dbo.Dependencies WHERE ProjectId = @SyntheticProject)
    THROW 51005, 'Required synthetic journey data is incomplete.', 1;

SELECT
    N'PASS' AS Status,
    DB_NAME() AS DatabaseName,
    ORIGINAL_LOGIN() AS RuntimePrincipal,
    (SELECT COUNT_BIG(*) FROM dbo.__EFMigrationsHistory) AS MigrationCount,
    (SELECT COUNT_BIG(*) FROM dbo.Applications WHERE ProjectId = @SyntheticProject) AS ApplicationCount,
    (SELECT COUNT_BIG(*) FROM dbo.Servers WHERE ProjectId = @SyntheticProject) AS ServerCount;
