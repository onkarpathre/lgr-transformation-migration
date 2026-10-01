:setvar DatabaseName "REQUIRED"
:setvar ApiMainPrincipalName "REQUIRED"
:setvar ApiStagingPrincipalName "REQUIRED"
:setvar MigrationPrincipalName "REQUIRED"
:setvar ApiMainPrincipalObjectId "REQUIRED"
:setvar ApiStagingPrincipalObjectId "REQUIRED"
:setvar MigrationPrincipalObjectId "REQUIRED"

SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME() <> N'$(DatabaseName)' OR N'$(DatabaseName)' <> N'sqldb-mtp-dev-uks-001'
    THROW 51000, 'AzureDemo principal bootstrap refuses an unexpected database.', 1;
IF N'$(ApiMainPrincipalName)' <> N'id-mtp-api-dev-uks-001'
   OR N'$(ApiStagingPrincipalName)' <> N'id-mtp-api-staging-dev-uks-001'
   OR N'$(MigrationPrincipalName)' <> N'id-mtp-migration-dev-uks-001'
    THROW 51001, 'AzureDemo principal bootstrap refuses unexpected physical principal names.', 1;
IF '$(ApiMainPrincipalObjectId)' = 'REQUIRED' OR '$(ApiStagingPrincipalObjectId)' = 'REQUIRED' OR '$(MigrationPrincipalObjectId)' = 'REQUIRED'
    THROW 51002, 'All workload identity object IDs are required.', 1;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'id-mtp-api-dev-uks-001')
    EXEC(N'CREATE USER [id-mtp-api-dev-uks-001] FROM EXTERNAL PROVIDER WITH OBJECT_ID=''' + '$(ApiMainPrincipalObjectId)' + N''';');
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'id-mtp-api-staging-dev-uks-001')
    EXEC(N'CREATE USER [id-mtp-api-staging-dev-uks-001] FROM EXTERNAL PROVIDER WITH OBJECT_ID=''' + '$(ApiStagingPrincipalObjectId)' + N''';');
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'id-mtp-migration-dev-uks-001')
    EXEC(N'CREATE USER [id-mtp-migration-dev-uks-001] FROM EXTERNAL PROVIDER WITH OBJECT_ID=''' + '$(MigrationPrincipalObjectId)' + N''';');

GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::dbo TO [id-mtp-api-dev-uks-001];
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::dbo TO [id-mtp-api-staging-dev-uks-001];
DENY ALTER, CONTROL ON SCHEMA::dbo TO [id-mtp-api-dev-uks-001];
DENY ALTER, CONTROL ON SCHEMA::dbo TO [id-mtp-api-staging-dev-uks-001];

GRANT ALTER, CONTROL, REFERENCES ON SCHEMA::dbo TO [id-mtp-migration-dev-uks-001];
GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE FUNCTION, CREATE TYPE TO [id-mtp-migration-dev-uks-001];
DENY BACKUP DATABASE, BACKUP LOG TO [id-mtp-migration-dev-uks-001];

SELECT name, type_desc FROM sys.database_principals
WHERE name IN (N'id-mtp-api-dev-uks-001', N'id-mtp-api-staging-dev-uks-001', N'id-mtp-migration-dev-uks-001')
ORDER BY name;
