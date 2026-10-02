SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @DatabaseName nvarchar(128) = N'$(DatabaseName)';
DECLARE @ApiMainPrincipalName nvarchar(128) = N'$(ApiMainPrincipalName)';
DECLARE @ApiStagingPrincipalName nvarchar(128) = N'$(ApiStagingPrincipalName)';
DECLARE @MigrationPrincipalName nvarchar(128) = N'$(MigrationPrincipalName)';
DECLARE @ApiMainPrincipalObjectIdText nvarchar(4000) = N'$(ApiMainPrincipalObjectId)';
DECLARE @ApiStagingPrincipalObjectIdText nvarchar(4000) = N'$(ApiStagingPrincipalObjectId)';
DECLARE @MigrationPrincipalObjectIdText nvarchar(4000) = N'$(MigrationPrincipalObjectId)';

IF DB_NAME() <> N'sqldb-mtp-dev-uks-001'
   OR DATALENGTH(@DatabaseName) <> DATALENGTH(N'sqldb-mtp-dev-uks-001')
   OR @DatabaseName COLLATE Latin1_General_100_BIN2 <> N'sqldb-mtp-dev-uks-001' COLLATE Latin1_General_100_BIN2
    THROW 51000, 'AzureDemo principal bootstrap refuses an unexpected database.', 1;
IF DATALENGTH(@ApiMainPrincipalName) <> DATALENGTH(N'id-mtp-api-dev-uks-001')
   OR @ApiMainPrincipalName COLLATE Latin1_General_100_BIN2 <> N'id-mtp-api-dev-uks-001' COLLATE Latin1_General_100_BIN2
   OR DATALENGTH(@ApiStagingPrincipalName) <> DATALENGTH(N'id-mtp-api-staging-dev-uks-001')
   OR @ApiStagingPrincipalName COLLATE Latin1_General_100_BIN2 <> N'id-mtp-api-staging-dev-uks-001' COLLATE Latin1_General_100_BIN2
   OR DATALENGTH(@MigrationPrincipalName) <> DATALENGTH(N'id-mtp-migration-dev-uks-001')
   OR @MigrationPrincipalName COLLATE Latin1_General_100_BIN2 <> N'id-mtp-migration-dev-uks-001' COLLATE Latin1_General_100_BIN2
    THROW 51001, 'AzureDemo principal bootstrap refuses unexpected physical principal names.', 1;

DECLARE @ApiMainPrincipalObjectId uniqueidentifier = TRY_CONVERT(uniqueidentifier, @ApiMainPrincipalObjectIdText);
DECLARE @ApiStagingPrincipalObjectId uniqueidentifier = TRY_CONVERT(uniqueidentifier, @ApiStagingPrincipalObjectIdText);
DECLARE @MigrationPrincipalObjectId uniqueidentifier = TRY_CONVERT(uniqueidentifier, @MigrationPrincipalObjectIdText);
IF DATALENGTH(@ApiMainPrincipalObjectIdText) <> 72
   OR DATALENGTH(@ApiStagingPrincipalObjectIdText) <> 72
   OR DATALENGTH(@MigrationPrincipalObjectIdText) <> 72
   OR @ApiMainPrincipalObjectId IS NULL
   OR @ApiStagingPrincipalObjectId IS NULL
   OR @MigrationPrincipalObjectId IS NULL
   OR @ApiMainPrincipalObjectId = CAST(0x00000000000000000000000000000000 AS uniqueidentifier)
   OR @ApiStagingPrincipalObjectId = CAST(0x00000000000000000000000000000000 AS uniqueidentifier)
   OR @MigrationPrincipalObjectId = CAST(0x00000000000000000000000000000000 AS uniqueidentifier)
    THROW 51002, 'All workload identity object IDs must be non-empty, non-zero GUIDs.', 1;
IF @ApiMainPrincipalObjectId = @ApiStagingPrincipalObjectId
   OR @ApiMainPrincipalObjectId = @MigrationPrincipalObjectId
   OR @ApiStagingPrincipalObjectId = @MigrationPrincipalObjectId
    THROW 51003, 'Workload identity object IDs must be distinct.', 1;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'id-mtp-api-dev-uks-001')
    EXEC(N'CREATE USER [id-mtp-api-dev-uks-001] FROM EXTERNAL PROVIDER WITH OBJECT_ID=''' + CONVERT(nvarchar(36), @ApiMainPrincipalObjectId) + N''';');
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'id-mtp-api-staging-dev-uks-001')
    EXEC(N'CREATE USER [id-mtp-api-staging-dev-uks-001] FROM EXTERNAL PROVIDER WITH OBJECT_ID=''' + CONVERT(nvarchar(36), @ApiStagingPrincipalObjectId) + N''';');
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'id-mtp-migration-dev-uks-001')
    EXEC(N'CREATE USER [id-mtp-migration-dev-uks-001] FROM EXTERNAL PROVIDER WITH OBJECT_ID=''' + CONVERT(nvarchar(36), @MigrationPrincipalObjectId) + N''';');

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
