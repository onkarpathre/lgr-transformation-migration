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
IF DATALENGTH(@ApiMainPrincipalName) <> DATALENGTH(N'app-mtp-api-dev-uks-001-c55a4')
   OR @ApiMainPrincipalName COLLATE Latin1_General_100_BIN2 <> N'app-mtp-api-dev-uks-001-c55a4' COLLATE Latin1_General_100_BIN2
   OR DATALENGTH(@ApiStagingPrincipalName) <> DATALENGTH(N'app-mtp-api-dev-uks-001/slots/staging-dbc2a')
   OR @ApiStagingPrincipalName COLLATE Latin1_General_100_BIN2 <> N'app-mtp-api-dev-uks-001/slots/staging-dbc2a' COLLATE Latin1_General_100_BIN2
   OR DATALENGTH(@MigrationPrincipalName) <> DATALENGTH(N'id-mtp-migration-dev-uks-001-9b984')
   OR @MigrationPrincipalName COLLATE Latin1_General_100_BIN2 <> N'id-mtp-migration-dev-uks-001-9b984' COLLATE Latin1_General_100_BIN2
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

DECLARE @ApiMainPrincipalObjectIdGuidText nvarchar(36) = CONVERT(nvarchar(36), @ApiMainPrincipalObjectId);
DECLARE @ApiStagingPrincipalObjectIdGuidText nvarchar(36) = CONVERT(nvarchar(36), @ApiStagingPrincipalObjectId);
DECLARE @MigrationPrincipalObjectIdGuidText nvarchar(36) = CONVERT(nvarchar(36), @MigrationPrincipalObjectId);

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'app-mtp-api-dev-uks-001-c55a4')
    EXEC(N'CREATE USER [app-mtp-api-dev-uks-001-c55a4] FROM EXTERNAL PROVIDER WITH OBJECT_ID=''' + @ApiMainPrincipalObjectIdGuidText + N''';');
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'app-mtp-api-dev-uks-001/slots/staging-dbc2a')
    EXEC(N'CREATE USER [app-mtp-api-dev-uks-001/slots/staging-dbc2a] FROM EXTERNAL PROVIDER WITH OBJECT_ID=''' + @ApiStagingPrincipalObjectIdGuidText + N''';');
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'id-mtp-migration-dev-uks-001-9b984')
    EXEC(N'CREATE USER [id-mtp-migration-dev-uks-001-9b984] FROM EXTERNAL PROVIDER WITH OBJECT_ID=''' + @MigrationPrincipalObjectIdGuidText + N''';');

GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::dbo TO [app-mtp-api-dev-uks-001-c55a4];
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::dbo TO [app-mtp-api-dev-uks-001/slots/staging-dbc2a];
DENY ALTER, CONTROL ON SCHEMA::dbo TO [app-mtp-api-dev-uks-001-c55a4];
DENY ALTER, CONTROL ON SCHEMA::dbo TO [app-mtp-api-dev-uks-001/slots/staging-dbc2a];

GRANT ALTER, CONTROL, REFERENCES ON SCHEMA::dbo TO [id-mtp-migration-dev-uks-001-9b984];
GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE FUNCTION, CREATE TYPE TO [id-mtp-migration-dev-uks-001-9b984];
DENY BACKUP DATABASE, BACKUP LOG TO [id-mtp-migration-dev-uks-001-9b984];

SELECT name, type_desc FROM sys.database_principals
WHERE name IN (N'app-mtp-api-dev-uks-001-c55a4', N'app-mtp-api-dev-uks-001/slots/staging-dbc2a', N'id-mtp-migration-dev-uks-001-9b984')
ORDER BY name;
