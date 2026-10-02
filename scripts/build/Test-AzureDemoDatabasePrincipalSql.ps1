[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$scriptPath = Join-Path $PSScriptRoot '..\database\Configure-AzureDemoDatabasePrincipals.sql'
$sql = Get-Content -LiteralPath $scriptPath -Raw
$requiredVariables = @(
    'DatabaseName',
    'ApiMainPrincipalName',
    'ApiStagingPrincipalName',
    'MigrationPrincipalName',
    'ApiMainPrincipalObjectId',
    'ApiStagingPrincipalObjectId',
    'MigrationPrincipalObjectId'
)
$expectedNames = [ordered]@{
    DatabaseName = 'sqldb-mtp-dev-uks-001'
    ApiMainPrincipalName = 'id-mtp-api-dev-uks-001'
    ApiStagingPrincipalName = 'id-mtp-api-staging-dev-uks-001'
    MigrationPrincipalName = 'id-mtp-migration-dev-uks-001'
}
$validVariables = [ordered]@{
    DatabaseName = $expectedNames.DatabaseName
    ApiMainPrincipalName = $expectedNames.ApiMainPrincipalName
    ApiStagingPrincipalName = $expectedNames.ApiStagingPrincipalName
    MigrationPrincipalName = $expectedNames.MigrationPrincipalName
    ApiMainPrincipalObjectId = '11111111-1111-4111-8111-111111111111'
    ApiStagingPrincipalObjectId = '22222222-2222-4222-8222-222222222222'
    MigrationPrincipalObjectId = '33333333-3333-4333-8333-333333333333'
}

function Expand-SqlCmdVariables([string] $Text, [Collections.IDictionary] $Variables) {
    return [regex]::Replace($Text, '\$\(([A-Za-z][A-Za-z0-9_]*)\)', {
            param($match)
            $name = $match.Groups[1].Value
            if ($Variables.Contains($name)) { return [string] $Variables[$name] }
            return $match.Value
        })
}

function Get-GuardValue([string] $RenderedSql, [string] $VariableName) {
    $pattern = "(?m)^DECLARE @$([regex]::Escape($VariableName))(?:Text)? nvarchar\([0-9]+\) = N'([^']*)';\r?$"
    $match = [regex]::Match($RenderedSql, $pattern)
    if (-not $match.Success) { throw "Unable to read rendered guard value for $VariableName." }
    return $match.Groups[1].Value
}

function Test-Guard([string] $RenderedSql, [string] $ActualDatabaseName) {
    if ($ActualDatabaseName -cne $expectedNames.DatabaseName) { return $false }
    foreach ($name in $expectedNames.Keys) {
        if ((Get-GuardValue $RenderedSql $name) -cne $expectedNames[$name]) { return $false }
    }

    $objectIds = [Collections.Generic.HashSet[Guid]]::new()
    foreach ($name in @('ApiMainPrincipalObjectId', 'ApiStagingPrincipalObjectId', 'MigrationPrincipalObjectId')) {
        $value = Get-GuardValue $RenderedSql $name
        $parsed = [Guid]::Empty
        if ($value.Length -ne 36 -or -not [Guid]::TryParseExact($value, 'D', [ref] $parsed) -or $parsed -eq [Guid]::Empty) {
            return $false
        }
        [void] $objectIds.Add($parsed)
    }
    return $objectIds.Count -eq 3
}

function Copy-Variables([Collections.IDictionary] $Source) {
    $copy = [ordered]@{}
    foreach ($key in $Source.Keys) { $copy[$key] = $Source[$key] }
    return $copy
}

$setvarLines = @([regex]::Matches($sql, '(?im)^\s*:setvar\s+[^\r\n]+$'))
if ($setvarLines.Count -ne 0) {
    throw "The grants script contains $($setvarLines.Count) internal :setvar assignment(s); externally supplied values would be overridden."
}
foreach ($name in $requiredVariables) {
    $requiredOverridePattern = '(?im)^\s*:setvar\s+{0}\s+["'']?REQUIRED' -f [regex]::Escape($name)
    if ($sql -match $requiredOverridePattern) {
        throw "The prohibited internal :setvar $name REQUIRED override returned."
    }
    if ([regex]::Matches($sql, "\$\($([regex]::Escape($name))\)").Count -ne 1) {
        throw "The grants script must bind required SQLCMD variable $name exactly once."
    }
}

$rendered = Expand-SqlCmdVariables $sql $validVariables
foreach ($name in $requiredVariables) {
    if ((Get-GuardValue $rendered $name) -cne $validVariables[$name]) {
        throw "Supplied SQLCMD value $name did not reach the SQL guard unchanged."
    }
}
if (-not (Test-Guard $rendered $expectedNames.DatabaseName)) { throw 'The SQL guard rejected the exact valid MTP database and principals.' }
if (Test-Guard $rendered 'sqldb-other-dev-uks-001') { throw 'The SQL guard accepted the wrong connected database.' }

$invalidCases = [Collections.Generic.List[object]]::new()
$wrongDatabase = Copy-Variables $validVariables; $wrongDatabase.DatabaseName = 'sqldb-other-dev-uks-001'; $invalidCases.Add([pscustomobject]@{ Name = 'wrong supplied database'; Variables = $wrongDatabase })
foreach ($name in $requiredVariables) {
    $missing = Copy-Variables $validVariables; $missing.Remove($name); $invalidCases.Add([pscustomobject]@{ Name = "missing/unresolved $name"; Variables = $missing })
    $empty = Copy-Variables $validVariables; $empty[$name] = ''; $invalidCases.Add([pscustomobject]@{ Name = "empty $name"; Variables = $empty })
    $required = Copy-Variables $validVariables; $required[$name] = 'REQUIRED'; $invalidCases.Add([pscustomobject]@{ Name = "substituted $name"; Variables = $required })
}
foreach ($name in @('ApiMainPrincipalName', 'ApiStagingPrincipalName', 'MigrationPrincipalName')) {
    $wrongName = Copy-Variables $validVariables; $wrongName[$name] = "wrong-$name"; $invalidCases.Add([pscustomobject]@{ Name = "wrong $name"; Variables = $wrongName })
}
foreach ($invalidObjectId in @('not-a-guid', '00000000-0000-0000-0000-000000000000', '11111111-1111-4111-8111-111111111111-extra')) {
    $invalidId = Copy-Variables $validVariables; $invalidId.ApiMainPrincipalObjectId = $invalidObjectId; $invalidCases.Add([pscustomobject]@{ Name = "invalid object ID $invalidObjectId"; Variables = $invalidId })
}
$duplicateIds = Copy-Variables $validVariables; $duplicateIds.ApiStagingPrincipalObjectId = $duplicateIds.ApiMainPrincipalObjectId; $invalidCases.Add([pscustomobject]@{ Name = 'duplicate object IDs'; Variables = $duplicateIds })

foreach ($invalidCase in $invalidCases) {
    $invalidRendered = Expand-SqlCmdVariables $sql $invalidCase.Variables
    if (Test-Guard $invalidRendered $expectedNames.DatabaseName) {
        $values = @($requiredVariables | ForEach-Object { "$_=$(Get-GuardValue $invalidRendered $_)" }) -join '; '
        throw "The SQL guard accepted invalid case: $($invalidCase.Name). Rendered values: $values"
    }
}

$requiredSqlFragments = @(
    "IF DB_NAME() <> N'sqldb-mtp-dev-uks-001'",
    "DATALENGTH(@DatabaseName) <> DATALENGTH(N'sqldb-mtp-dev-uks-001')",
    "@DatabaseName COLLATE Latin1_General_100_BIN2 <> N'sqldb-mtp-dev-uks-001' COLLATE Latin1_General_100_BIN2",
    "DATALENGTH(@ApiMainPrincipalName) <> DATALENGTH(N'id-mtp-api-dev-uks-001')",
    "@ApiMainPrincipalName COLLATE Latin1_General_100_BIN2 <> N'id-mtp-api-dev-uks-001' COLLATE Latin1_General_100_BIN2",
    "DATALENGTH(@ApiStagingPrincipalName) <> DATALENGTH(N'id-mtp-api-staging-dev-uks-001')",
    "@ApiStagingPrincipalName COLLATE Latin1_General_100_BIN2 <> N'id-mtp-api-staging-dev-uks-001' COLLATE Latin1_General_100_BIN2",
    "DATALENGTH(@MigrationPrincipalName) <> DATALENGTH(N'id-mtp-migration-dev-uks-001')",
    "@MigrationPrincipalName COLLATE Latin1_General_100_BIN2 <> N'id-mtp-migration-dev-uks-001' COLLATE Latin1_General_100_BIN2",
    'DECLARE @ApiMainPrincipalObjectId uniqueidentifier = TRY_CONVERT(uniqueidentifier, @ApiMainPrincipalObjectIdText);',
    'DECLARE @ApiStagingPrincipalObjectId uniqueidentifier = TRY_CONVERT(uniqueidentifier, @ApiStagingPrincipalObjectIdText);',
    'DECLARE @MigrationPrincipalObjectId uniqueidentifier = TRY_CONVERT(uniqueidentifier, @MigrationPrincipalObjectIdText);',
    'DATALENGTH(@ApiMainPrincipalObjectIdText) <> 72',
    'DATALENGTH(@ApiStagingPrincipalObjectIdText) <> 72',
    'DATALENGTH(@MigrationPrincipalObjectIdText) <> 72',
    '@ApiMainPrincipalObjectId IS NULL',
    '@ApiStagingPrincipalObjectId IS NULL',
    '@MigrationPrincipalObjectId IS NULL',
    '@ApiMainPrincipalObjectId = CAST(0x00000000000000000000000000000000 AS uniqueidentifier)',
    '@ApiStagingPrincipalObjectId = CAST(0x00000000000000000000000000000000 AS uniqueidentifier)',
    '@MigrationPrincipalObjectId = CAST(0x00000000000000000000000000000000 AS uniqueidentifier)',
    '@ApiMainPrincipalObjectId = @ApiStagingPrincipalObjectId',
    '@ApiMainPrincipalObjectId = @MigrationPrincipalObjectId',
    '@ApiStagingPrincipalObjectId = @MigrationPrincipalObjectId',
    "THROW 51000, 'AzureDemo principal bootstrap refuses an unexpected database.', 1;",
    "THROW 51001, 'AzureDemo principal bootstrap refuses unexpected physical principal names.', 1;",
    "THROW 51002, 'All workload identity object IDs must be non-empty, non-zero GUIDs.', 1;",
    "THROW 51003, 'Workload identity object IDs must be distinct.', 1;",
    'DECLARE @ApiMainPrincipalObjectIdGuidText nvarchar(36) = CONVERT(nvarchar(36), @ApiMainPrincipalObjectId);',
    'DECLARE @ApiStagingPrincipalObjectIdGuidText nvarchar(36) = CONVERT(nvarchar(36), @ApiStagingPrincipalObjectId);',
    'DECLARE @MigrationPrincipalObjectIdGuidText nvarchar(36) = CONVERT(nvarchar(36), @MigrationPrincipalObjectId);',
    "IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'id-mtp-api-dev-uks-001')",
    "IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'id-mtp-api-staging-dev-uks-001')",
    "IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'id-mtp-migration-dev-uks-001')",
    'GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::dbo TO [id-mtp-api-dev-uks-001];',
    'GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::dbo TO [id-mtp-api-staging-dev-uks-001];',
    'DENY ALTER, CONTROL ON SCHEMA::dbo TO [id-mtp-api-dev-uks-001];',
    'DENY ALTER, CONTROL ON SCHEMA::dbo TO [id-mtp-api-staging-dev-uks-001];',
    'GRANT ALTER, CONTROL, REFERENCES ON SCHEMA::dbo TO [id-mtp-migration-dev-uks-001];',
    'GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE FUNCTION, CREATE TYPE TO [id-mtp-migration-dev-uks-001];',
    'DENY BACKUP DATABASE, BACKUP LOG TO [id-mtp-migration-dev-uks-001];'
)
foreach ($fragment in $requiredSqlFragments) {
    if ([regex]::Matches($sql, [regex]::Escape($fragment)).Count -ne 1) {
        throw "The exact reviewed principal or least-privilege SQL contract changed: $fragment"
    }
}
$expectedCreateUserStatements = @(
    "EXEC(N'CREATE USER [id-mtp-api-dev-uks-001] FROM EXTERNAL PROVIDER WITH OBJECT_ID=''' + @ApiMainPrincipalObjectIdGuidText + N''';');",
    "EXEC(N'CREATE USER [id-mtp-api-staging-dev-uks-001] FROM EXTERNAL PROVIDER WITH OBJECT_ID=''' + @ApiStagingPrincipalObjectIdGuidText + N''';');",
    "EXEC(N'CREATE USER [id-mtp-migration-dev-uks-001] FROM EXTERNAL PROVIDER WITH OBJECT_ID=''' + @MigrationPrincipalObjectIdGuidText + N''';');"
)
$execStatements = @([regex]::Matches($sql, '(?im)^\s*EXEC\s*\([^\r\n]+\);\s*$') | ForEach-Object { $_.Value.Trim() })
if ($execStatements.Count -ne $expectedCreateUserStatements.Count) {
    throw "The grants script must contain exactly $($expectedCreateUserStatements.Count) structurally reviewed EXEC statements; found $($execStatements.Count)."
}
foreach ($statement in $execStatements) {
    if ($statement -match '(?i)\b(?:CONVERT|CAST)\s*\(') {
        throw "CONVERT or CAST function calls are prohibited inside EXEC concatenation: $statement"
    }
}
for ($index = 0; $index -lt $expectedCreateUserStatements.Count; $index++) {
    if ($execStatements[$index] -cne $expectedCreateUserStatements[$index]) {
        throw "CREATE USER EXEC statement $($index + 1) does not use the exact supported literal-plus-precomputed-GUID-text expression shape."
    }
}
$firstMutation = $sql.IndexOf('IF NOT EXISTS (SELECT 1 FROM sys.database_principals', [StringComparison]::Ordinal)
$lastGuard = $sql.IndexOf("THROW 51003, 'Workload identity object IDs must be distinct.', 1;", [StringComparison]::Ordinal)
if ($firstMutation -lt 0 -or $lastGuard -lt 0 -or $lastGuard -ge $firstMutation) {
    throw 'Every database, principal-name and object-ID guard must precede the first contained-user mutation.'
}
$precomputedGuidDeclarations = @(
    'DECLARE @ApiMainPrincipalObjectIdGuidText nvarchar(36) = CONVERT(nvarchar(36), @ApiMainPrincipalObjectId);',
    'DECLARE @ApiStagingPrincipalObjectIdGuidText nvarchar(36) = CONVERT(nvarchar(36), @ApiStagingPrincipalObjectId);',
    'DECLARE @MigrationPrincipalObjectIdGuidText nvarchar(36) = CONVERT(nvarchar(36), @MigrationPrincipalObjectId);'
)
foreach ($declaration in $precomputedGuidDeclarations) {
    $declarationPosition = $sql.IndexOf($declaration, [StringComparison]::Ordinal)
    if ($declarationPosition -le $lastGuard -or $declarationPosition -ge $firstMutation) {
        throw "Validated GUID text must be precomputed after all guards and before the first contained-user mutation: $declaration"
    }
}
if ($sql -match "(?i)OBJECT_ID\s*=\s*'?[0-9a-f]{8}-[0-9a-f-]{27}") {
    throw 'The grants script contains a hard-coded identity object ID.'
}

Write-Output "Azure demo database-principal SQLCMD contract passed: seven external variables preserved, correct database accepted, $($invalidCases.Count + 1) invalid guard cases rejected, and three CREATE USER statements use precomputed GUID text in the supported EXEC expression shape."
