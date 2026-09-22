<#
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-01", "C-02", "C-03", "C-04", "C-06"]
  functional_requirements: ["F-01", "F-02", "F-03", "F-04", "F-05", "F-07", "F-15"]
  non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-04", "NF-05", "NF-06", "NF-08", "NF-09", "NF-10", "NF-11", "NF-12", "NF-13"]
  risks: ["R-01", "R-02", "R-03", "R-06", "R-09", "R-11"]
  assumptions: ["A-01", "A-02", "A-03", "A-05", "A-06", "A-08", "A-11", "A-13", "A-15", "A-16", "A-18"]
  dependencies: ["D-01", "D-03", "D-04", "D-05", "D-07", "D-08", "D-10", "D-11", "D-13"]
  issues: ["I-01", "I-02", "I-03", "I-04", "I-06", "I-08"]
  open_questions: ["Q-01", "Q-02", "Q-06", "Q-09"]
  approvals:
    - "Authorised Test Authority, Slices 2-4: https://github.com/onkarpathre/lgr-transformation-migration/pull/8#pullrequestreview-5221828015"

Tester-owned Windows PowerShell SQL Server assurance harness for consolidated
PH3-SQL-001 Slices 3 and 4. It is pinned to the exact candidate commit, approved
local SQL Express instance, and one fresh Retry01 database. It fails closed unless
DB_ID proves that database is server-side nonexistent. It never drops or deletes
the database, changes SQL Server configuration/security, or accesses any other
database beyond master for the existence gate and the named isolated database.

The authorised Down/reapply rehearsal exports the synthetic assessment business
rows in memory, verifies the earlier inventory/history rows remain unchanged,
reapplies every migration, restores the synthetic assessment rows, verifies their
business-data checksum, and leaves the database fully migrated for inspection.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $Server,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $Database
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ExpectedServer = 'localhost\SQLEXPRESS'
$ExpectedDatabase = 'LgrTransformationMigration_Ph3Sql_Slices34_Assurance_20260921_Retry01'
$ExpectedBranch = 'feature/ph3-sql-remaining-implementation'
$ExpectedHead = '09276007d2dfb0a6b175a256e4a535031b5d6ced'
$PreviousMigration = '20260916121802_EnforceDiscoveryImportRowTenantBatchOwnership'
$ExpectedMigrations = @(
    '20260823111854_InitialCreate',
    '20260824181918_AddDiscoveryImport',
    '20260909164944_AddSqlInventory',
    '20260910082037_AddInternalPrincipalAuditType',
    '20260915171019_AddSqlDiscoveryImportHistory',
    '20260916121802_EnforceDiscoveryImportRowTenantBatchOwnership',
    '20260917001712_AddSqlAssessments'
)
$AllowedWorktreeEntries = @(
    ' M src/web/next-env.d.ts',
    '?? docs/implementation/PH3_SQL_Slices34_Test_Evidence_Pack.md',
    '?? src/web/tests/TesterSqlBrowserJourneyContracts.test.tsx',
    '?? tests/sqlserver/PH3_SQL_Slices34_Assurance.ps1'
)

$RepositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$ApiProject = Join-Path $RepositoryRoot 'src\api\LgrTransformationMigration.Api.csproj'
$Ef = 'C:\Users\onkar\.dotnet\tools\dotnet-ef.exe'
$RunId = [DateTimeOffset]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
$ResultDirectory = Join-Path $RepositoryRoot (Join-Path 'TestResults' ("PH3_SQL_Slices34_Assurance_{0}" -f $RunId))
$PlanDirectory = Join-Path $ResultDirectory 'execution-plans'
$ResultPath = Join-Path $ResultDirectory 'result.json'
$Steps = [Collections.ArrayList]::new()
$Defects = [Collections.ArrayList]::new()
$Plans = [Collections.ArrayList]::new()
$NativeWarnings = [Collections.ArrayList]::new()
$ExitCode = 2
$DatabaseConnectionString = $null
$SavedConnectionString = [Environment]::GetEnvironmentVariable('ConnectionStrings__LgrDatabase', 'Process')
$SavedDotnetEnvironment = [Environment]::GetEnvironmentVariable('DOTNET_ENVIRONMENT', 'Process')
$SavedAspnetcoreEnvironment = [Environment]::GetEnvironmentVariable('ASPNETCORE_ENVIRONMENT', 'Process')

$Result = [ordered]@{
    schemaVersion = '1.0'
    workItem = 'PH3-SQL-001-REMAINING-SLICES-3-4'
    testerRole = 'Tester Agent'
    approval = 'https://github.com/onkarpathre/lgr-transformation-migration/pull/8#pullrequestreview-5221828015'
    startedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
    completedAtUtc = $null
    outcome = 'BLOCKED'
    outcomeReason = 'Harness did not reach a terminal state.'
    repository = [ordered]@{ expectedBranch = $ExpectedBranch; actualBranch = $null; expectedHead = $ExpectedHead; actualHead = $null }
    target = [ordered]@{ server = $ExpectedServer; database = $ExpectedDatabase; authentication = 'Windows Integrated'; automaticallyDeleted = $false }
    expectedMigrations = $ExpectedMigrations
    migrationHistory = [ordered]@{}
    schemaEvidence = $null
    isolationEvidence = $null
    concurrencyEvidence = $null
    historyEvidence = $null
    rollbackEvidence = $null
    executionPlans = $Plans
    nativeWarnings = $NativeWarnings
    steps = $Steps
    defects = $Defects
    databaseLeftFullyMigrated = $false
    databaseAutomaticallyDroppedOrDeleted = $false
    resultFile = $ResultPath
}

function Add-Step([string] $Name, [ValidateSet('PASS','FAIL','BLOCKED')][string] $Outcome, [string] $Detail, [object] $Evidence = $null) {
    $null = $Steps.Add([ordered]@{ name = $Name; outcome = $Outcome; atUtc = [DateTimeOffset]::UtcNow.ToString('o'); detail = $Detail; evidence = $Evidence })
    Write-Host ("[{0}] {1}: {2}" -f $Outcome, $Name, $Detail)
}

function Fail([string] $Message) { throw [InvalidOperationException]::new("PH3_FAIL::{0}" -f $Message) }
function Block([string] $Message) { throw [InvalidOperationException]::new("PH3_BLOCKED::{0}" -f $Message) }
function Assert-True([bool] $Condition, [string] $Message) { if (-not $Condition) { Fail $Message } }

function New-ConnectionString([string] $Catalog) {
    $builder = [Data.SqlClient.SqlConnectionStringBuilder]::new()
    $builder['Data Source'] = $ExpectedServer
    $builder['Initial Catalog'] = $Catalog
    $builder['Integrated Security'] = $true
    $builder['Encrypt'] = $true
    $builder['TrustServerCertificate'] = $true
    $builder['Connect Timeout'] = 15
    $builder['Application Name'] = 'PH3 SQL Slices34 Assurance'
    return $builder.ConnectionString
}

function Invoke-Table([string] $Sql, [string] $ConnectionString = $DatabaseConnectionString, [hashtable] $Parameters = @{}) {
    $connection = [Data.SqlClient.SqlConnection]::new($ConnectionString)
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandTimeout = 60
        $command.CommandText = $Sql
        foreach ($entry in $Parameters.GetEnumerator()) { $null = $command.Parameters.AddWithValue($entry.Key, $entry.Value) }
        $table = [Data.DataTable]::new()
        $reader = $command.ExecuteReader()
        try { $table.Load($reader) } finally { $reader.Dispose() }
        return ,$table
    }
    finally { $connection.Dispose() }
}

function Invoke-Scalar([string] $Sql, [string] $ConnectionString = $DatabaseConnectionString, [hashtable] $Parameters = @{}) {
    $connection = [Data.SqlClient.SqlConnection]::new($ConnectionString)
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandTimeout = 60
        $command.CommandText = $Sql
        foreach ($entry in $Parameters.GetEnumerator()) { $null = $command.Parameters.AddWithValue($entry.Key, $entry.Value) }
        return $command.ExecuteScalar()
    }
    finally { $connection.Dispose() }
}

function Invoke-NonQuery([string] $Sql, [string] $ConnectionString = $DatabaseConnectionString) {
    $connection = [Data.SqlClient.SqlConnection]::new($ConnectionString)
    try { $connection.Open(); $command = $connection.CreateCommand(); $command.CommandTimeout = 60; $command.CommandText = $Sql; return $command.ExecuteNonQuery() }
    finally { $connection.Dispose() }
}

function Assert-SqlRejected([string] $Name, [string] $Sql, [int[]] $AllowedNumbers) {
    try { $null = Invoke-NonQuery $Sql; Fail ("{0} unexpectedly succeeded." -f $Name) }
    catch [Data.SqlClient.SqlException] {
        Assert-True ($_.Exception.Number -in $AllowedNumbers) ("{0} failed with unexpected SQL error {1}." -f $Name, $_.Exception.Number)
        return [ordered]@{ name = $Name; rejected = $true; sqlError = $_.Exception.Number }
    }
}

function Invoke-Native([string] $Name, [string] $File, [string[]] $Arguments) {
    $output = @()
    $nativeErrorActionPreference = $ErrorActionPreference
    try {
        # Windows PowerShell 5.1 represents native stderr as ErrorRecord objects.
        # Keep those records non-terminating until the native exit code and every
        # stderr line have been assessed explicitly below.
        $ErrorActionPreference = 'Continue'
        $output = @(& $File @Arguments 2>&1)
        $code = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $nativeErrorActionPreference
    }

    $lines = [Collections.Generic.List[string]]::new()
    $stderr = [Collections.Generic.List[string]]::new()
    foreach ($item in $output) {
        $line = [string] $item
        $lines.Add($line)
        if ($item -is [Management.Automation.ErrorRecord]) { $stderr.Add($line) }
        if (-not [string]::IsNullOrWhiteSpace($line)) { Write-Host $line }
    }

    if ($code -ne 0) {
        Fail ("{0} exited {1}. Native output: {2}" -f $Name, $code, [string]::Join(' | ', $lines))
    }

    $toleratedWarnings = [Collections.Generic.List[string]]::new()
    foreach ($line in $stderr) {
        if ($line -match '^.+\s+: warning NU1900: Error occurred while getting package vulnerability data: .+$') {
            $toleratedWarnings.Add($line)
            $null = $NativeWarnings.Add([ordered]@{ command = $Name; code = 'NU1900'; detail = $line })
        }
        else {
            Fail ("{0} wrote unexpected stderr with exit code 0: {1}" -f $Name, $line)
        }
    }

    $detail = if ($toleratedWarnings.Count -gt 0) {
        "Command completed with exit code 0; retained {0} tolerated NU1900 advisory-feed warning(s)." -f $toleratedWarnings.Count
    }
    else {
        'Command completed with exit code 0 and no stderr.'
    }
    Add-Step $Name PASS $detail ([ordered]@{ executable = [IO.Path]::GetFileName($File); arguments = $Arguments; output = [string]::Join([Environment]::NewLine, $lines); toleratedWarnings = $toleratedWarnings.ToArray() })
    return [string]::Join([Environment]::NewLine, $lines)
}

function Assert-NativeArgumentRoundTrip {
    $probePath = Join-Path $ResultDirectory 'native-argument-probe.js'
    $probeSource = @'
var args = WScript.Arguments;
WScript.Echo(args.length);
for (var index = 0; index < args.length; index++) {
    WScript.Echo(index + "|" + args(index).length + "|" + args(index));
}
'@
    [IO.File]::WriteAllText($probePath, $probeSource, [Text.UTF8Encoding]::new($false))

    $logicalArguments = [string[]] @(
        '//nologo',
        $probePath,
        'value containing spaces',
        'key=value;second=two;third=three',
        'PH3 SQL Slices34 Assurance'
    )
    $output = Invoke-Native -Name 'Native argument-array smoke test' -File (Join-Path $env:SystemRoot 'System32\cscript.exe') -Arguments $logicalArguments
    $actual = @($output -split '\r?\n')
    $payload = [string[]] $logicalArguments[2..4]
    $expected = @('3')
    for ($index = 0; $index -lt $payload.Count; $index++) {
        $expected += ("{0}|{1}|{2}" -f $index, $payload[$index].Length, $payload[$index])
    }
    Assert-True ($actual.Count -eq $expected.Count) 'Native argument smoke returned an unexpected argument count.'
    for ($index = 0; $index -lt $expected.Count; $index++) {
        Assert-True ($actual[$index] -ceq $expected[$index]) ("Native argument smoke mismatch at output line {0}." -f $index)
    }
    Add-Step 'Native argument identity' PASS 'Arguments containing spaces, semicolons and Slices34 each remained one exact child-process argument.' ([ordered]@{ logicalArguments = $payload; probe = $probePath })
}

function Get-MigrationHistory {
    $table = Invoke-Table 'SELECT [MigrationId] FROM [dbo].[__EFMigrationsHistory] ORDER BY [MigrationId];'
    return @($table.Rows | ForEach-Object { [string] $_.MigrationId })
}

function Assert-Migrations([string] $Phase) {
    $actual = @(Get-MigrationHistory)
    Assert-True ($actual.Count -eq $ExpectedMigrations.Count) ("{0}: expected {1} migrations, found {2}." -f $Phase, $ExpectedMigrations.Count, $actual.Count)
    for ($i = 0; $i -lt $ExpectedMigrations.Count; $i++) { Assert-True ($actual[$i] -ceq $ExpectedMigrations[$i]) ("{0}: migration order mismatch at {1}." -f $Phase, $i) }
    return $actual
}

function Capture-Plan([string] $Name, [string] $Query) {
    $connection = [Data.SqlClient.SqlConnection]::new($DatabaseConnectionString)
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandTimeout = 60
        $command.CommandText = "SET STATISTICS XML ON;`n{0}`nSET STATISTICS XML OFF;" -f $Query
        $reader = $command.ExecuteReader()
        $xml = $null
        try {
            do {
                while ($reader.Read()) {
                    for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                        $value = if ($reader.IsDBNull($i)) { $null } else { [string] $reader.GetValue($i) }
                        if ($value -and $value.Contains('ShowPlanXML')) { $xml = $value }
                    }
                }
            } while ($reader.NextResult())
        }
        finally { $reader.Dispose() }
        Assert-True (-not [string]::IsNullOrWhiteSpace($xml)) ("No SQL Server plan was returned for {0}." -f $Name)
        $path = Join-Path $PlanDirectory ("{0}.sqlplan" -f $Name)
        [IO.File]::WriteAllText($path, $xml, [Text.UTF8Encoding]::new($false))
        $entry = [ordered]@{ name = $Name; path = $path; bytes = ([IO.FileInfo]::new($path)).Length; missingIndex = $xml.Contains('<MissingIndexes>') }
        $null = $Plans.Add($entry)
        return $entry
    }
    finally { $connection.Dispose() }
}

function Restore-Assessments([Data.DataTable] $Backup) {
    $bulk = [Data.SqlClient.SqlBulkCopy]::new($DatabaseConnectionString)
    try {
        $bulk.DestinationTableName = '[dbo].[SqlAssessments]'
        foreach ($column in $Backup.Columns) { if ($column.ColumnName -ne 'RowVersion') { $null = $bulk.ColumnMappings.Add($column.ColumnName, $column.ColumnName) } }
        $bulk.WriteToServer($Backup)
    }
    finally { $bulk.Dispose() }
}

try {
    New-Item -ItemType Directory -Path $PlanDirectory -Force | Out-Null
    Set-Location -LiteralPath $RepositoryRoot

    if ($Server -cne $ExpectedServer) { Block ("Server must equal '{0}'." -f $ExpectedServer) }
    if ($Database -cne $ExpectedDatabase) { Block ("Database must equal '{0}'." -f $ExpectedDatabase) }
    if (-not (Test-Path -LiteralPath $Ef -PathType Leaf)) { Block ("Pinned dotnet-ef 10.0.11 was not found at {0}." -f $Ef) }

    $Result.repository.actualBranch = (& git branch --show-current).Trim()
    $Result.repository.actualHead = (& git rev-parse HEAD).Trim()
    Assert-True ($LASTEXITCODE -eq 0) 'Could not read Git HEAD.'
    if ($Result.repository.actualBranch -cne $ExpectedBranch) { Block 'Repository branch does not match the approved branch.' }
    if ($Result.repository.actualHead -cne $ExpectedHead) { Block 'Repository HEAD does not match the exact approved candidate.' }
    & git merge-base --is-ancestor 93aada7b4b8fffcdb7bfefb2223d4974b6a9de4c $ExpectedHead
    $slice3Ancestor = $LASTEXITCODE
    & git merge-base --is-ancestor a1df3449d3f06bdff513437e88ca5209a30a426b $ExpectedHead
    $slice4Ancestor = $LASTEXITCODE
    Assert-True ($slice3Ancestor -eq 0 -and $slice4Ancestor -eq 0) 'Slice 3 or Slice 4 implementation commit is not an ancestor.'
    $unexpected = @(& git status --porcelain=v1 | Where-Object { $_ -notin $AllowedWorktreeEntries })
    if ($unexpected.Count -gt 0) { Block ("Unexpected worktree changes: {0}" -f ($unexpected -join '; ')) }
    $nextEnvHash = (& git hash-object 'src/web/next-env.d.ts').Trim()
    $nextEnvHeadHash = (& git rev-parse 'HEAD:src/web/next-env.d.ts').Trim()
    Assert-True ($nextEnvHash -ceq $nextEnvHeadHash) 'next-env.d.ts differs from the exact candidate despite the allowed stat-only worktree entry.'
    Add-Step 'Exact candidate and worktree gate' PASS 'Exact branch/HEAD and both implementation ancestors confirmed; only Tester-owned artefacts are present.'

    Assert-NativeArgumentRoundTrip

    $master = New-ConnectionString 'master'
    $existing = Invoke-Scalar 'SELECT DB_ID(@database);' $master @{ '@database' = $ExpectedDatabase }
    if ($null -ne $existing -and $existing -isnot [DBNull]) { Block ("Database '{0}' already exists; no reuse or cleanup is permitted." -f $ExpectedDatabase) }
    Add-Step 'Server-side fresh database gate' PASS 'Parameterized DB_ID returned NULL before any migration command.'

    $DatabaseConnectionString = New-ConnectionString $ExpectedDatabase
    $connectionBuilder = [Data.SqlClient.SqlConnectionStringBuilder]::new($DatabaseConnectionString)
    Assert-True ([string] $connectionBuilder['Application Name'] -ceq 'PH3 SQL Slices34 Assurance') 'The exact SQL application-name value was not preserved.'
    [Environment]::SetEnvironmentVariable('ConnectionStrings__LgrDatabase', $DatabaseConnectionString, 'Process')
    [Environment]::SetEnvironmentVariable('DOTNET_ENVIRONMENT', 'Production', 'Process')
    [Environment]::SetEnvironmentVariable('ASPNETCORE_ENVIRONMENT', 'Production', 'Process')
    # Keep the structured connection string in the process environment. Passing it
    # through dotnet-ef's forwarding command line on Windows PowerShell 5.1 caused
    # its spaced Application Name value to be reparsed into separate CLI tokens.
    $efArgs = [string[]] @('database','update','--project',$ApiProject,'--startup-project',$ApiProject,'--configuration','Release','--no-build')
    $null = Invoke-Native -Name 'Apply all current migrations' -File $Ef -Arguments $efArgs
    $Result.migrationHistory.initial = @(Assert-Migrations 'Initial apply')

    $schema = Invoke-Table @'
SELECT
 (SELECT COUNT(*) FROM sys.tables WHERE name = 'SqlAssessments') AS AssessmentTable,
 (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID('dbo.SqlAssessments') AND name = 'RowVersion' AND system_type_id = 189) AS RowVersionColumn,
 (SELECT COUNT(*) FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID('dbo.SqlAssessments') AND name IN ('CK_SqlAssessments_ExactlyOneTarget','CK_SqlAssessments_AssessmentStatus','CK_SqlAssessments_ReadinessStatus','CK_SqlAssessments_TargetPlatform','CK_SqlAssessments_MigrationApproach')) AS Checks,
 (SELECT COUNT(*) FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.SqlAssessments') AND name IN ('UX_SqlAssessments_Owner_Active_Instance','UX_SqlAssessments_Owner_Active_Database','IX_SqlAssessments_Owner_Filter')) AS Indexes,
 (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID('dbo.SqlAssessments') AND delete_referential_action = 0) AS RestrictForeignKeys,
 (SELECT COUNT(*) FROM sys.foreign_key_columns WHERE constraint_object_id IN (SELECT object_id FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID('dbo.SqlAssessments'))) AS ForeignKeyColumns;
'@
    $schemaRow = $schema.Rows[0]
    Assert-True ($schemaRow.AssessmentTable -eq 1 -and $schemaRow.RowVersionColumn -eq 1) 'SqlAssessments table/rowversion schema is incomplete.'
    Assert-True ($schemaRow.Checks -eq 5 -and $schemaRow.Indexes -eq 3 -and $schemaRow.RestrictForeignKeys -eq 3 -and $schemaRow.ForeignKeyColumns -eq 8) 'Approved checks, indexes, or composite foreign keys are incomplete.'
    $Result.schemaEvidence = [ordered]@{ assessmentTable = 1; rowversion = 1; checks = 5; indexes = 3; restrictForeignKeys = 3; foreignKeyColumns = 8 }
    Add-Step 'Approved assessment schema' PASS 'Table, SQL rowversion, five checks, three indexes and three tenant-leading Restrict foreign keys are present.' $Result.schemaEvidence

    $null = Invoke-NonQuery @'
DECLARE @Now datetimeoffset = SYSUTCDATETIME();
INSERT INTO dbo.Customers (Id,Name,Code,Status,CreatedAt,UpdatedAt) VALUES
('94000000-0000-0000-0000-000000000001','Assurance Customer A','S34A','Active',@Now,@Now),
('94000000-0000-0000-0000-000000000002','Assurance Customer B','S34B','Active',@Now,@Now);
INSERT INTO dbo.Projects (Id,CustomerId,Name,Description,Status,PlannedStartDate,PlannedEndDate,CreatedAt,UpdatedAt) VALUES
('94000000-0000-0000-0000-000000000011','94000000-0000-0000-0000-000000000001','Assurance Project A','Synthetic','Active',NULL,NULL,@Now,@Now),
('94000000-0000-0000-0000-000000000012','94000000-0000-0000-0000-000000000002','Assurance Project B','Synthetic','Active',NULL,NULL,@Now,@Now);
INSERT INTO dbo.Servers (Id,CustomerId,ProjectId,Hostname,Environment,OperatingSystem,IpAddress,VCores,MemoryMb,AllocatedStorageGb,PowerStatus,MigrationStatus,CreatedAt,UpdatedAt) VALUES
('94000000-0000-0000-0000-000000000021','94000000-0000-0000-0000-000000000001','94000000-0000-0000-0000-000000000011','S34-SQL-A','Test','Synthetic','192.0.2.41',4,8192,100,'On','Not Started',@Now,@Now),
('94000000-0000-0000-0000-000000000022','94000000-0000-0000-0000-000000000002','94000000-0000-0000-0000-000000000012','S34-SQL-B','Test','Synthetic','192.0.2.42',4,8192,100,'On','Not Started',@Now,@Now);
INSERT INTO dbo.SqlInstances (Id,CustomerId,ProjectId,ServerId,InstanceName,NormalizedInstanceName,SqlVersion,Edition,Port,ServiceStatus,DiscoverySource,ServiceAccountName,LastDiscoveredAt,LastImportBatchId,LastImportedAt,CreatedAt,UpdatedAt,CreatedBy,UpdatedBy,IsDeleted,DeletedAt,DeletedBy) VALUES
('94000000-0000-0000-0000-000000000031','94000000-0000-0000-0000-000000000001','94000000-0000-0000-0000-000000000011','94000000-0000-0000-0000-000000000021','S34A','S34A','SQL Server 2022','Standard',1433,'Running','Manual',NULL,@Now,NULL,NULL,@Now,@Now,'assurance','assurance',0,NULL,NULL),
('94000000-0000-0000-0000-000000000032','94000000-0000-0000-0000-000000000002','94000000-0000-0000-0000-000000000012','94000000-0000-0000-0000-000000000022','S34B','S34B','SQL Server 2022','Standard',1433,'Running','Manual',NULL,@Now,NULL,NULL,@Now,@Now,'assurance','assurance',0,NULL,NULL);
INSERT INTO dbo.SqlDatabases (Id,CustomerId,ProjectId,SqlInstanceId,Name,NormalizedName,SizeMb,CompatibilityLevel,RecoveryModel,Collation,Status,LastImportBatchId,LastImportedAt,CreatedAt,UpdatedAt,CreatedBy,UpdatedBy,IsDeleted,DeletedAt,DeletedBy) VALUES
('94000000-0000-0000-0000-000000000041','94000000-0000-0000-0000-000000000001','94000000-0000-0000-0000-000000000011','94000000-0000-0000-0000-000000000031','AssuranceDb','ASSURANCEDB',512,160,'Full','Latin1_General_100_CI_AS_SC','Online',NULL,NULL,@Now,@Now,'assurance','assurance',0,NULL,NULL);
INSERT INTO dbo.SqlAssessments (Id,CustomerId,ProjectId,SqlInstanceId,SqlDatabaseId,AssessmentStatus,ReadinessStatus,TargetPlatform,TargetSqlVersion,MigrationApproach,Blockers,Findings,Notes,AssessedAt,CreatedAt,CreatedBy,UpdatedAt,UpdatedBy,IsDeleted,DeletedAt,DeletedBy) VALUES
('94000000-0000-0000-0000-000000000051','94000000-0000-0000-0000-000000000001','94000000-0000-0000-0000-000000000011','94000000-0000-0000-0000-000000000031',NULL,'InProgress','AtRisk','AzureSqlManagedInstance',NULL,'ToBeDetermined','Synthetic blocker','Synthetic finding','Synthetic note',@Now,@Now,'assurance',@Now,'assurance',0,NULL,NULL);
'@

    $isolation = [Collections.ArrayList]::new()
    $null = $isolation.Add((Assert-SqlRejected 'cross-tenant assessment target' @"
INSERT dbo.SqlAssessments (Id,CustomerId,ProjectId,SqlInstanceId,SqlDatabaseId,AssessmentStatus,ReadinessStatus,Blockers,Findings,Notes,CreatedAt,CreatedBy,UpdatedAt,UpdatedBy,IsDeleted)
VALUES (NEWID(),'94000000-0000-0000-0000-000000000001','94000000-0000-0000-0000-000000000011','94000000-0000-0000-0000-000000000032',NULL,'NotStarted','NotAssessed','','','',SYSUTCDATETIME(),'assurance',SYSUTCDATETIME(),'assurance',0);
"@ @(547)))
    $null = $isolation.Add((Assert-SqlRejected 'assessment XOR constraint' @"
INSERT dbo.SqlAssessments (Id,CustomerId,ProjectId,SqlInstanceId,SqlDatabaseId,AssessmentStatus,ReadinessStatus,Blockers,Findings,Notes,CreatedAt,CreatedBy,UpdatedAt,UpdatedBy,IsDeleted)
VALUES (NEWID(),'94000000-0000-0000-0000-000000000001','94000000-0000-0000-0000-000000000011',NULL,NULL,'NotStarted','NotAssessed','','','',SYSUTCDATETIME(),'assurance',SYSUTCDATETIME(),'assurance',0);
"@ @(547)))
    $null = $isolation.Add((Assert-SqlRejected 'controlled assessment value' @"
INSERT dbo.SqlAssessments (Id,CustomerId,ProjectId,SqlInstanceId,SqlDatabaseId,AssessmentStatus,ReadinessStatus,Blockers,Findings,Notes,CreatedAt,CreatedBy,UpdatedAt,UpdatedBy,IsDeleted)
VALUES (NEWID(),'94000000-0000-0000-0000-000000000001','94000000-0000-0000-0000-000000000011',NULL,'94000000-0000-0000-0000-000000000041','Recommended','NotAssessed','','','',SYSUTCDATETIME(),'assurance',SYSUTCDATETIME(),'assurance',0);
"@ @(547)))
    $Result.isolationEvidence = $isolation
    Add-Step 'Tenant/project and controlled-value rejection' PASS 'SQL Server rejected cross-tenant ownership, target XOR and an unapproved controlled value.' $isolation

    $oldVersion = [byte[]] (Invoke-Scalar "SELECT RowVersion FROM dbo.SqlAssessments WHERE Id='94000000-0000-0000-0000-000000000051';")
    $currentUpdate = Invoke-NonQuery ("UPDATE dbo.SqlAssessments SET Notes='rowversion-current', UpdatedAt=SYSUTCDATETIME() WHERE Id='94000000-0000-0000-0000-000000000051' AND RowVersion=0x{0};" -f ([BitConverter]::ToString($oldVersion).Replace('-','')))
    $staleUpdate = Invoke-NonQuery ("UPDATE dbo.SqlAssessments SET Notes='rowversion-stale' WHERE Id='94000000-0000-0000-0000-000000000051' AND RowVersion=0x{0};" -f ([BitConverter]::ToString($oldVersion).Replace('-','')))
    Assert-True ($currentUpdate -eq 1 -and $staleUpdate -eq 0) 'SQL rowversion did not reject the stale update.'

    $duplicateSql = @"
WAITFOR DELAY '00:00:01';
INSERT dbo.SqlAssessments (Id,CustomerId,ProjectId,SqlInstanceId,SqlDatabaseId,AssessmentStatus,ReadinessStatus,Blockers,Findings,Notes,CreatedAt,CreatedBy,UpdatedAt,UpdatedBy,IsDeleted)
VALUES (@Id,'94000000-0000-0000-0000-000000000001','94000000-0000-0000-0000-000000000011',NULL,'94000000-0000-0000-0000-000000000041','NotStarted','NotAssessed','','','',SYSUTCDATETIME(),'assurance',SYSUTCDATETIME(),'assurance',0);
"@
    $connections = @([Data.SqlClient.SqlConnection]::new($DatabaseConnectionString), [Data.SqlClient.SqlConnection]::new($DatabaseConnectionString))
    $commands = @()
    $operations = @()
    try {
        foreach ($connection in $connections) { $connection.Open(); $command = $connection.CreateCommand(); $command.CommandTimeout = 30; $command.CommandText = $duplicateSql; $null = $command.Parameters.Add('@Id',[Data.SqlDbType]::UniqueIdentifier); $commands += $command }
        $commands[0].Parameters['@Id'].Value = [guid] '94000000-0000-0000-0000-000000000052'
        $commands[1].Parameters['@Id'].Value = [guid] '94000000-0000-0000-0000-000000000053'
        $operations = @($commands[0].BeginExecuteNonQuery(), $commands[1].BeginExecuteNonQuery())
        $outcomes = @()
        for ($i = 0; $i -lt 2; $i++) {
            try { $outcomes += [ordered]@{ outcome = 'inserted'; rows = $commands[$i].EndExecuteNonQuery($operations[$i]) } }
            catch [Data.SqlClient.SqlException] { $outcomes += [ordered]@{ outcome = 'rejected'; sqlError = $_.Exception.Number } }
        }
    }
    finally { foreach ($command in $commands) { $command.Dispose() }; foreach ($connection in $connections) { $connection.Dispose() } }
    $inserted = @($outcomes | Where-Object outcome -eq 'inserted').Count
    $rejected = @($outcomes | Where-Object outcome -eq 'rejected').Count
    $duplicateCount = [int] (Invoke-Scalar "SELECT COUNT(*) FROM dbo.SqlAssessments WHERE CustomerId='94000000-0000-0000-0000-000000000001' AND ProjectId='94000000-0000-0000-0000-000000000011' AND SqlDatabaseId='94000000-0000-0000-0000-000000000041' AND IsDeleted=0;")
    Assert-True ($inserted -eq 1 -and $rejected -eq 1 -and $duplicateCount -eq 1) 'Concurrent active-target uniqueness did not produce exactly one winner.'
    $Result.concurrencyEvidence = [ordered]@{ currentRowVersionUpdate = $currentUpdate; staleRowVersionUpdate = $staleUpdate; concurrentOutcomes = $outcomes; activeDatabaseAssessments = $duplicateCount }
    Add-Step 'Rowversion and concurrent uniqueness' PASS 'Current update won, stale update affected zero rows, and exactly one concurrent active assessment insert succeeded.' $Result.concurrencyEvidence

    $null = Invoke-NonQuery @'
DECLARE @Now datetimeoffset = SYSUTCDATETIME();
INSERT dbo.ImportBatches (Id,CustomerId,ProjectId,SourceType,OriginalFileName,StoredFileName,FileHash,FileSizeBytes,Status,UploadedBy,UploadedAt,PreviewedAt,CommittedAt,TotalRows,ValidRows,CreateCount,UpdateCount,UnchangedCount,WarningCount,RejectCount,Notes,CommitIdempotencyKeyHash,CommitResultJson)
VALUES ('94000000-0000-0000-0000-000000000061','94000000-0000-0000-0000-000000000001','94000000-0000-0000-0000-000000000011','SqlDatabaseCsvV1','synthetic.csv',NULL,REPLICATE('A',64),128,'Committed','assurance',@Now,@Now,@Now,1,1,0,1,0,0,0,NULL,NULL,NULL);
INSERT dbo.SqlDatabaseDiscoverySnapshots (Id,CustomerId,ProjectId,SqlDatabaseId,ImportBatchId,SqlInstanceId,Name,SizeMb,CompatibilityLevel,RecoveryModel,Collation,Status,ImportedAt)
VALUES ('94000000-0000-0000-0000-000000000062','94000000-0000-0000-0000-000000000001','94000000-0000-0000-0000-000000000011','94000000-0000-0000-0000-000000000041','94000000-0000-0000-0000-000000000061','94000000-0000-0000-0000-000000000031','AssuranceDb',512,160,'Full','Latin1_General_100_CI_AS_SC','Online',@Now);
'@
    $historyCount = [int] (Invoke-Scalar "SELECT COUNT(*) FROM dbo.SqlDatabaseDiscoverySnapshots WHERE Id='94000000-0000-0000-0000-000000000062';")
    Assert-True ($historyCount -eq 1) 'Representative immutable-history row was not retained.'
    $Result.historyEvidence = [ordered]@{ databaseSnapshots = $historyCount; ownerLeadingIndex = 'IX_SqlDatabaseDiscoverySnapshots_Owner_History' }
    Add-Step 'Representative discovery history' PASS 'Synthetic tenant-owned database history is related through composite foreign keys and retained.' $Result.historyEvidence

    $null = Capture-Plan 'paged-assessment-filter' "SELECT Id,AssessmentStatus,ReadinessStatus,RowVersion FROM dbo.SqlAssessments WHERE CustomerId='94000000-0000-0000-0000-000000000001' AND ProjectId='94000000-0000-0000-0000-000000000011' AND IsDeleted=0 ORDER BY Id OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;"
    $null = Capture-Plan 'database-history' "SELECT Id,ImportedAt,Status FROM dbo.SqlDatabaseDiscoverySnapshots WHERE CustomerId='94000000-0000-0000-0000-000000000001' AND ProjectId='94000000-0000-0000-0000-000000000011' AND SqlDatabaseId='94000000-0000-0000-0000-000000000041' ORDER BY ImportedAt DESC,Id OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;"
    Add-Step 'Representative SQL execution plans' PASS 'Captured SQL Server STATISTICS XML plans for assessment paging and database history.' $Plans

    $assessmentBackup = Invoke-Table 'SELECT Id,CustomerId,ProjectId,SqlInstanceId,SqlDatabaseId,AssessmentStatus,ReadinessStatus,TargetPlatform,TargetSqlVersion,MigrationApproach,Blockers,Findings,Notes,AssessedAt,CreatedAt,CreatedBy,UpdatedAt,UpdatedBy,IsDeleted,DeletedAt,DeletedBy,RowVersion FROM dbo.SqlAssessments ORDER BY Id;'
    $assessmentChecksumBefore = Invoke-Scalar "SELECT CHECKSUM_AGG(BINARY_CHECKSUM(Id,CustomerId,ProjectId,SqlInstanceId,SqlDatabaseId,AssessmentStatus,ReadinessStatus,TargetPlatform,TargetSqlVersion,MigrationApproach,Blockers,Findings,Notes,AssessedAt,CreatedAt,CreatedBy,UpdatedAt,UpdatedBy,IsDeleted,DeletedAt,DeletedBy)) FROM dbo.SqlAssessments;"
    $inventoryChecksumBefore = Invoke-Scalar "SELECT CHECKSUM_AGG(BINARY_CHECKSUM(Id,CustomerId,ProjectId,InstanceName,NormalizedInstanceName,IsDeleted)) FROM dbo.SqlInstances;"
    $historyChecksumBefore = Invoke-Scalar 'SELECT CHECKSUM_AGG(BINARY_CHECKSUM(Id,CustomerId,ProjectId,SqlDatabaseId,ImportBatchId,ImportedAt)) FROM dbo.SqlDatabaseDiscoverySnapshots;'
    $rollbackArgs = [string[]] @('database','update',$PreviousMigration,'--project',$ApiProject,'--startup-project',$ApiProject,'--configuration','Release','--no-build')
    $null = Invoke-Native -Name 'Authorised rollback to pre-assessment boundary' -File $Ef -Arguments $rollbackArgs
    Assert-True ([int] (Invoke-Scalar "SELECT COUNT(*) FROM sys.tables WHERE object_id=OBJECT_ID('dbo.SqlAssessments');") -eq 0) 'SqlAssessments unexpectedly remained at the rollback boundary.'
    Assert-True ($inventoryChecksumBefore -eq (Invoke-Scalar "SELECT CHECKSUM_AGG(BINARY_CHECKSUM(Id,CustomerId,ProjectId,InstanceName,NormalizedInstanceName,IsDeleted)) FROM dbo.SqlInstances;")) 'Inventory changed during rollback.'
    Assert-True ($historyChecksumBefore -eq (Invoke-Scalar 'SELECT CHECKSUM_AGG(BINARY_CHECKSUM(Id,CustomerId,ProjectId,SqlDatabaseId,ImportBatchId,ImportedAt)) FROM dbo.SqlDatabaseDiscoverySnapshots;')) 'Discovery history changed during rollback.'
    $null = Invoke-Native -Name 'Reapply all current migrations' -File $Ef -Arguments $efArgs
    Restore-Assessments $assessmentBackup
    $assessmentChecksumAfter = Invoke-Scalar "SELECT CHECKSUM_AGG(BINARY_CHECKSUM(Id,CustomerId,ProjectId,SqlInstanceId,SqlDatabaseId,AssessmentStatus,ReadinessStatus,TargetPlatform,TargetSqlVersion,MigrationApproach,Blockers,Findings,Notes,AssessedAt,CreatedAt,CreatedBy,UpdatedAt,UpdatedBy,IsDeleted,DeletedAt,DeletedBy)) FROM dbo.SqlAssessments;"
    Assert-True ($assessmentChecksumBefore -eq $assessmentChecksumAfter) 'Assessment business data was not recovered exactly after reapply.'
    $Result.migrationHistory.final = @(Assert-Migrations 'Final reapply')
    $Result.rollbackEvidence = [ordered]@{ assessmentRowsExportedAndRecovered = $assessmentBackup.Rows.Count; assessmentChecksumBefore = $assessmentChecksumBefore; assessmentChecksumAfter = $assessmentChecksumAfter; inventoryUnchanged = $true; historyUnchanged = $true }
    $Result.databaseLeftFullyMigrated = $true
    Add-Step 'Rollback, reapply and data recovery' PASS 'Earlier inventory/history remained unchanged; synthetic assessment business rows were exported, restored, checksummed and the database was left fully migrated.' $Result.rollbackEvidence

    $Result.outcome = 'PASS'
    $Result.outcomeReason = 'All authorised consolidated Slices 3-4 SQL Server assurance checks passed.'
    $ExitCode = 0
}
catch {
    $message = [string] $_.Exception.Message
    if ($message.StartsWith('PH3_BLOCKED::')) { $Result.outcome = 'BLOCKED'; $Result.outcomeReason = $message.Substring(13); $ExitCode = 2; Add-Step 'Harness terminal state' BLOCKED $Result.outcomeReason }
    else { $Result.outcome = 'FAIL'; $Result.outcomeReason = $message.Replace('PH3_FAIL::',''); $ExitCode = 1; $null = $Defects.Add([ordered]@{ message = $Result.outcomeReason; type = $_.Exception.GetType().FullName }); Add-Step 'Harness terminal state' FAIL $Result.outcomeReason }
}
finally {
    [Environment]::SetEnvironmentVariable('ConnectionStrings__LgrDatabase', $SavedConnectionString, 'Process')
    [Environment]::SetEnvironmentVariable('DOTNET_ENVIRONMENT', $SavedDotnetEnvironment, 'Process')
    [Environment]::SetEnvironmentVariable('ASPNETCORE_ENVIRONMENT', $SavedAspnetcoreEnvironment, 'Process')
    Set-Location -LiteralPath $RepositoryRoot
    $Result.completedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
    try { New-Item -ItemType Directory -Path $ResultDirectory -Force | Out-Null; [IO.File]::WriteAllText($ResultPath, ($Result | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false)); Write-Host ("Evidence: {0}" -f $ResultPath) }
    catch { Write-Host ("Could not write evidence: {0}" -f $_.Exception.Message); if ($ExitCode -eq 0) { $ExitCode = 1 } }
}

exit $ExitCode
