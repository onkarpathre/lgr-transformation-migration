:setvar ApiMainPrincipalObjectId "REQUIRED"
:setvar ApiStagingPrincipalObjectId "REQUIRED"
:setvar MigrationPrincipalObjectId "REQUIRED"

SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME() <> N'sqldb-lgrtm-azdemo'
    THROW 51000, 'AzureDemo principal bootstrap refuses an unexpected database.', 1;
IF '$(ApiMainPrincipalObjectId)' = 'REQUIRED' OR '$(ApiStagingPrincipalObjectId)' = 'REQUIRED' OR '$(MigrationPrincipalObjectId)' = 'REQUIRED'
    THROW 51001, 'All workload identity object IDs are required.', 1;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'id-lgrtm-api-azdemo')
    EXEC(N'CREATE USER [id-lgrtm-api-azdemo] FROM EXTERNAL PROVIDER WITH OBJECT_ID=''' + '$(ApiMainPrincipalObjectId)' + N''';');
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'id-lgrtm-api-staging-azdemo')
    EXEC(N'CREATE USER [id-lgrtm-api-staging-azdemo] FROM EXTERNAL PROVIDER WITH OBJECT_ID=''' + '$(ApiStagingPrincipalObjectId)' + N''';');
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'id-lgrtm-migration-azdemo')
    EXEC(N'CREATE USER [id-lgrtm-migration-azdemo] FROM EXTERNAL PROVIDER WITH OBJECT_ID=''' + '$(MigrationPrincipalObjectId)' + N''';');

GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::dbo TO [id-lgrtm-api-azdemo];
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::dbo TO [id-lgrtm-api-staging-azdemo];
DENY ALTER, CONTROL ON SCHEMA::dbo TO [id-lgrtm-api-azdemo];
DENY ALTER, CONTROL ON SCHEMA::dbo TO [id-lgrtm-api-staging-azdemo];

GRANT ALTER, CONTROL, REFERENCES ON SCHEMA::dbo TO [id-lgrtm-migration-azdemo];
GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE FUNCTION, CREATE TYPE TO [id-lgrtm-migration-azdemo];
DENY BACKUP DATABASE, BACKUP LOG TO [id-lgrtm-migration-azdemo];

SELECT name, type_desc FROM sys.database_principals
WHERE name IN (N'id-lgrtm-api-azdemo', N'id-lgrtm-api-staging-azdemo', N'id-lgrtm-migration-azdemo')
ORDER BY name;
