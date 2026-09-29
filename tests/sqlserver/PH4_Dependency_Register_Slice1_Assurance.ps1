<#
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-03", "C-05", "C-09"]
  functional_requirements: ["F-04", "F-05", "F-06", "F-10", "F-11", "F-15"]
  non_functional_requirements: ["NF-01", "NF-02", "NF-04", "NF-06", "NF-08", "NF-09", "NF-10", "NF-11"]
  risks: ["R-01", "R-02", "R-03", "R-06", "R-07", "R-09"]
  assumptions: ["A-02", "A-06", "A-07", "A-08", "A-11", "A-13", "A-18"]
  dependencies: ["D-01", "D-04", "D-08", "D-11", "D-13"]
  issues: ["I-04", "I-06", "I-07", "I-08"]
  open_questions: ["Q-01", "Q-02", "Q-09"]
  approvals:
    - "Phase 4 Test Services approval retained in docs/approvals/PH4_Architecture_Approval_Evidence.json and bound to architecture commit 985099c2ec05e3307bdc770af4a97e6e28df8c6e."

Tester-owned SQL Server assurance harness for PH4-DEP-001 Slice 1. The harness:

- is pinned to exact repair commit d57239c0f5b79eb1f6da50a9b288c8cea7425a97;
- accepts only a named local SQL Express instance and the exact new OwnerRun03
  database pinned below;
- queries only master for local-server identity and parameterised DB_ID absence;
- refuses to run if the target database already exists;
- never drops or automatically deletes a database and never changes SQL Server
  configuration, security, logins or permissions;
- uses only deterministic synthetic records;
- applies migrations from empty to the preceding migration, then Slice 1 Up;
- verifies provider constraints, composite isolation FKs, filtered uniqueness,
  computed keys, rowversion concurrency and Restrict delete behaviour;
- performs the authorised disposable Down/reapply rehearsal and leaves the
  database fully migrated for inspection.

Run only under the retained Phase 4 Test Services approval. A connection or
identity failure is BLOCKED and performs no database creation. A schema or
constraint failure after creation is FAIL and the database is retained.
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

$ExpectedBranch = 'feature/ph4-dependency-register-implementation'
$ExpectedHead = 'd57239c0f5b79eb1f6da50a9b288c8cea7425a97'
$ExpectedDatabase = 'LgrTransformationMigration_PH4_Slice1_Assurance_d57239c_OwnerRun03'
$PreviousMigration = '20260917001712_AddSqlAssessments'
$CurrentMigration = '20260922151243_AddDependencyRegister'
$AllowedUncommittedPaths = @(
    '?? docs/implementation/PH4_Dependency_Register_Slice1_Test_Evidence_Pack.md',
    '?? src/web/tests/TesterDependencyBrowserJourneyContracts.test.tsx',
    ' M tests/api.integration/DependencyRegisterApiTests.cs',
    ' M tests/api.unit/DependencyRulesTests.cs',
    ' M tests/TestData/dependencies/slice1-fixture-manifest.json',
    '?? tests/sqlserver/PH4_Dependency_Register_Slice1_Assurance.ps1'
)
$ApprovalPath = 'docs/approvals/PH4_Architecture_Approval_Evidence.json'
$RepositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$ApiProject = Join-Path $RepositoryRoot 'src\api\LgrTransformationMigration.Api.csproj'
$ResultRoot = Join-Path $RepositoryRoot 'TestResults'
$RunId = [DateTimeOffset]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
$ResultDirectory = Join-Path $ResultRoot ("PH4_Dependency_Register_Slice1_SQL_{0}" -f $RunId)
$ResultPath = Join-Path $ResultDirectory 'result.json'
$Steps = [Collections.ArrayList]::new()
$Defects = [Collections.ArrayList]::new()
$ExitCode = 2
$DatabaseCreated = $false
$DatabaseConnectionString = $null
$SavedConnectionString = [Environment]::GetEnvironmentVariable('ConnectionStrings__LgrDatabase', 'Process')
$SavedDotnetEnvironment = [Environment]::GetEnvironmentVariable('DOTNET_ENVIRONMENT', 'Process')
$SavedAspnetcoreEnvironment = [Environment]::GetEnvironmentVariable('ASPNETCORE_ENVIRONMENT', 'Process')

$Result = [ordered]@{
    schemaVersion = '1.0'
    workItem = 'PH4-DEP-001-SLICE-1'
    testerRole = 'Tester Agent'
    approval = $ApprovalPath
    startedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
    completedAtUtc = $null
    outcome = 'BLOCKED'
    outcomeReason = 'Harness did not reach a terminal state.'
    repository = [ordered]@{
        expectedBranch = $ExpectedBranch
        actualBranch = $null
        expectedHead = $ExpectedHead
        actualHead = $null
    }
    target = [ordered]@{
        requestedServer = $Server
        verifiedMachine = $null
        verifiedInstance = $null
        database = $Database
        authentication = 'Windows Integrated'
        existedBeforeRun = $null
        automaticallyDeleted = $false
    }
    migrations = [ordered]@{
        previous = $PreviousMigration
        current = $CurrentMigration
        finalHistory = @()
    }
    schemaEvidence = $null
    constraintEvidence = $null
    concurrencyEvidence = $null
    rollbackEvidence = $null
    steps = $Steps
    defects = $Defects
    databaseCreated = $false
    databaseLeftFullyMigrated = $false
    databaseAutomaticallyDroppedOrDeleted = $false
    resultFile = $ResultPath
}

function Add-Step(
    [string] $Name,
    [ValidateSet('PASS', 'FAIL', 'BLOCKED')]
    [string] $Outcome,
    [string] $Detail,
    [object] $Evidence = $null
) {
    $null = $Steps.Add([ordered]@{
        name = $Name
        outcome = $Outcome
        atUtc = [DateTimeOffset]::UtcNow.ToString('o')
        detail = $Detail
        evidence = $Evidence
    })
    Write-Host ("[{0}] {1}: {2}" -f $Outcome, $Name, $Detail)
}

function Fail([string] $Message) {
    throw [InvalidOperationException]::new("PH4_FAIL::{0}" -f $Message)
}

function Block([string] $Message) {
    throw [InvalidOperationException]::new("PH4_BLOCKED::{0}" -f $Message)
}

function Assert-True([bool] $Condition, [string] $Message) {
    if (-not $Condition) {
        Fail $Message
    }
}

function Test-SqlNull([object] $Value) {
    return $null -eq $Value -or $Value -is [DBNull]
}

function ConvertTo-RequiredInt32([object] $Value, [string] $EvidenceName) {
    if (Test-SqlNull $Value) {
        Fail ("{0} returned SQL NULL; required integer evidence is missing." -f $EvidenceName)
    }

    try {
        return [Convert]::ToInt32($Value, [Globalization.CultureInfo]::InvariantCulture)
    }
    catch {
        Fail ("{0} is not valid Int32 evidence: {1}" -f $EvidenceName, $_.Exception.Message)
    }
}

function ConvertTo-NullableChecksum([object] $Value, [long] $RowCount, [string] $EvidenceName) {
    if ($RowCount -eq 0) {
        Assert-True (Test-SqlNull $Value) ("{0} was non-NULL for an empty table." -f $EvidenceName)
        return $null
    }

    if (Test-SqlNull $Value) {
        Fail ("{0} returned SQL NULL for {1} retained row(s)." -f $EvidenceName, $RowCount)
    }

    return ConvertTo-RequiredInt32 $Value $EvidenceName
}

function New-ConnectionString([string] $Catalog) {
    $builder = [Data.SqlClient.SqlConnectionStringBuilder]::new()
    $builder['Data Source'] = $Server
    $builder['Initial Catalog'] = $Catalog
    $builder['Integrated Security'] = $true
    $builder['Encrypt'] = $true
    $builder['TrustServerCertificate'] = $true
    $builder['Connect Timeout'] = 15
    $builder['Application Name'] = 'PH4 Dependency Register Slice1 Assurance'
    return $builder.ConnectionString
}

function Invoke-Table(
    [string] $Sql,
    [string] $ConnectionString = $DatabaseConnectionString,
    [hashtable] $Parameters = @{}
) {
    $connection = [Data.SqlClient.SqlConnection]::new($ConnectionString)
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandTimeout = 60
        $command.CommandText = $Sql
        foreach ($entry in $Parameters.GetEnumerator()) {
            $null = $command.Parameters.AddWithValue($entry.Key, $entry.Value)
        }
        $table = [Data.DataTable]::new()
        $reader = $command.ExecuteReader()
        try {
            $table.Load($reader)
        }
        finally {
            $reader.Dispose()
        }
        return ,$table
    }
    finally {
        $connection.Dispose()
    }
}

function Invoke-Scalar(
    [string] $Sql,
    [string] $ConnectionString = $DatabaseConnectionString,
    [hashtable] $Parameters = @{}
) {
    $connection = [Data.SqlClient.SqlConnection]::new($ConnectionString)
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandTimeout = 60
        $command.CommandText = $Sql
        foreach ($entry in $Parameters.GetEnumerator()) {
            $null = $command.Parameters.AddWithValue($entry.Key, $entry.Value)
        }
        return $command.ExecuteScalar()
    }
    finally {
        $connection.Dispose()
    }
}

function Invoke-NonQuery(
    [string] $Sql,
    [string] $ConnectionString = $DatabaseConnectionString,
    [hashtable] $Parameters = @{}
) {
    $connection = [Data.SqlClient.SqlConnection]::new($ConnectionString)
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandTimeout = 60
        $command.CommandText = $Sql
        foreach ($entry in $Parameters.GetEnumerator()) {
            $null = $command.Parameters.AddWithValue($entry.Key, $entry.Value)
        }
        return $command.ExecuteNonQuery()
    }
    finally {
        $connection.Dispose()
    }
}

function Assert-SqlRejected(
    [string] $Name,
    [string] $Sql,
    [int[]] $AllowedNumbers
) {
    try {
        $null = Invoke-NonQuery $Sql
        Fail ("{0} unexpectedly succeeded." -f $Name)
    }
    catch [Data.SqlClient.SqlException] {
        Assert-True ($_.Exception.Number -in $AllowedNumbers) (
            "{0} failed with unexpected SQL error {1}." -f $Name, $_.Exception.Number)
        return [ordered]@{
            name = $Name
            rejected = $true
            sqlError = $_.Exception.Number
        }
    }
}

function Invoke-Native(
    [string] $Name,
    [string] $File,
    [string[]] $Arguments
) {
    $savedPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& $File @Arguments 2>&1)
        $code = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $savedPreference
    }

    $lines = @($output | ForEach-Object { [string] $_ })
    foreach ($line in $lines) {
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            Write-Host $line
        }
    }
    if ($code -ne 0) {
        Fail ("{0} exited {1}. Output: {2}" -f $Name, $code, [string]::Join(' | ', $lines))
    }

    $unexpectedErrors = @($lines | Where-Object {
        $_ -match '(?i)\berror\b' -and $_ -notmatch 'warning NU1900'
    })
    if ($unexpectedErrors.Count -gt 0) {
        Fail ("{0} emitted error text with exit code 0: {1}" -f $Name, [string]::Join(' | ', $unexpectedErrors))
    }
    Add-Step $Name PASS 'Native command completed successfully.' ([ordered]@{
        executable = [IO.Path]::GetFileName($File)
        arguments = $Arguments
        output = [string]::Join([Environment]::NewLine, $lines)
    })
    return [string]::Join([Environment]::NewLine, $lines)
}

function Invoke-EfUpdate([string] $Migration, [string] $Name) {
    $arguments = @(
        'database', 'update', $Migration,
        '--project', $ApiProject,
        '--startup-project', $ApiProject,
        '--configuration', 'Release',
        '--no-build'
    )
    $null = Invoke-Native -Name $Name -File $script:DotnetEf -Arguments $arguments
}

function Get-MigrationHistory {
    $table = Invoke-Table 'SELECT [MigrationId] FROM [dbo].[__EFMigrationsHistory] ORDER BY [MigrationId];'
    return @($table.Rows | ForEach-Object { [string] $_.MigrationId })
}

function Assert-ObjectExists([string] $Type, [string] $Name) {
    $count = [int] (Invoke-Scalar @'
SELECT COUNT_BIG(*)
FROM sys.objects
WHERE [type] = @type AND [name] = @name;
'@ -Parameters @{ '@type' = $Type; '@name' = $Name })
    Assert-True ($count -eq 1) ("Expected SQL object {0} ({1}) was not found exactly once." -f $Name, $Type)
}

function Get-LegacyFingerprint {
    $table = Invoke-Table @'
SELECT
    (SELECT COUNT_BIG(*) FROM dbo.Customers) AS CustomerCount,
    (SELECT COUNT_BIG(*) FROM dbo.Projects) AS ProjectCount,
    (SELECT COUNT_BIG(*) FROM dbo.Applications) AS ApplicationCount,
    (SELECT CHECKSUM_AGG(BINARY_CHECKSUM(Id, Name, Code, Status)) FROM dbo.Customers) AS CustomerChecksum,
    (SELECT CHECKSUM_AGG(BINARY_CHECKSUM(Id, CustomerId, Name, Status)) FROM dbo.Projects) AS ProjectChecksum,
    (SELECT CHECKSUM_AGG(BINARY_CHECKSUM(Id, CustomerId, ProjectId, Name, MigrationStatus)) FROM dbo.Applications) AS ApplicationChecksum;
'@
    $row = $table.Rows[0]
    $customerCount = [long] $row.CustomerCount
    $projectCount = [long] $row.ProjectCount
    $applicationCount = [long] $row.ApplicationCount
    return [ordered]@{
        customerCount = $customerCount
        projectCount = $projectCount
        applicationCount = $applicationCount
        customerChecksum = ConvertTo-NullableChecksum $row.CustomerChecksum $customerCount 'Customers CHECKSUM_AGG'
        projectChecksum = ConvertTo-NullableChecksum $row.ProjectChecksum $projectCount 'Projects CHECKSUM_AGG'
        applicationChecksum = ConvertTo-NullableChecksum $row.ApplicationChecksum $applicationCount 'Applications CHECKSUM_AGG'
    }
}

function Assert-FingerprintEqual(
    [Collections.IDictionary] $Expected,
    [Collections.IDictionary] $Actual,
    [string] $Phase
) {
    foreach ($key in $Expected.Keys) {
        Assert-True ($Expected[$key] -eq $Actual[$key]) (
            "{0}: legacy fingerprint field {1} changed from {2} to {3}." -f
                $Phase, $key, $Expected[$key], $Actual[$key])
    }
}

function Test-SimultaneousDuplicateConstraint {
    $connectionOne = [Data.SqlClient.SqlConnection]::new($DatabaseConnectionString)
    $connectionTwo = [Data.SqlClient.SqlConnection]::new($DatabaseConnectionString)
    $transactionOne = $null
    $transactionTwo = $null
    try {
        $connectionOne.Open()
        $connectionTwo.Open()
        $transactionOne = $connectionOne.BeginTransaction()
        $transactionTwo = $connectionTwo.BeginTransaction()

        $sql = @'
INSERT INTO dbo.Dependencies
    (Id, CustomerId, ProjectId, SourceType, SourceApplicationId,
     TargetType, TargetServerId, DependencyType, Criticality,
     Description, BusinessContext, ConfirmationStatus, ConfirmedAt,
     ConfirmedBy, IsArchived, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy)
VALUES
    (@id, '11111111-1111-1111-1111-111111111111',
     '22222222-2222-2222-2222-222222222222', 'Application',
     '55555555-5555-5555-5555-555555555100', 'Server',
     'bbbbbbbb-bbbb-bbbb-bbbb-000000000001', 'OperationalSequence',
     'Mandatory', N'Concurrent synthetic edge', NULL, 'Unconfirmed',
     NULL, NULL, 0, SYSUTCDATETIME(), N'ph4-tester',
     SYSUTCDATETIME(), N'ph4-tester');
'@

        $commandOne = $connectionOne.CreateCommand()
        $commandOne.Transaction = $transactionOne
        $commandOne.CommandTimeout = 30
        $commandOne.CommandText = $sql
        $null = $commandOne.Parameters.AddWithValue('@id', [Guid] '55555555-5555-5555-5555-555555555201')
        Assert-True ($commandOne.ExecuteNonQuery() -eq 1) 'First concurrent insert did not affect one row.'

        $commandTwo = $connectionTwo.CreateCommand()
        $commandTwo.Transaction = $transactionTwo
        $commandTwo.CommandTimeout = 30
        $commandTwo.CommandText = $sql
        $null = $commandTwo.Parameters.AddWithValue('@id', [Guid] '55555555-5555-5555-5555-555555555202')
        $taskTwo = $commandTwo.ExecuteNonQueryAsync()
        Start-Sleep -Milliseconds 300
        Assert-True (-not $taskTwo.IsCompleted) 'Second equivalent insert did not wait on the first transaction as expected.'
        $transactionOne.Commit()
        $transactionOne = $null

        try {
            $null = $taskTwo.GetAwaiter().GetResult()
            Fail 'Second simultaneous equivalent dependency unexpectedly committed.'
        }
        catch [Data.SqlClient.SqlException] {
            Assert-True ($_.Exception.Number -in @(2601, 2627)) (
                "Second simultaneous insert failed with unexpected SQL error {0}." -f $_.Exception.Number)
        }
        $transactionTwo.Rollback()
        $transactionTwo = $null
        return [ordered]@{
            firstCommitted = $true
            secondRejected = $true
            allowedSqlErrors = @(2601, 2627)
        }
    }
    finally {
        if ($null -ne $transactionOne) {
            try { $transactionOne.Rollback() } catch { }
        }
        if ($null -ne $transactionTwo) {
            try { $transactionTwo.Rollback() } catch { }
        }
        $connectionOne.Dispose()
        $connectionTwo.Dispose()
    }
}

try {
    New-Item -ItemType Directory -Force -Path $ResultDirectory | Out-Null
    Set-Location $RepositoryRoot

    if ($Server -notmatch '^(localhost|\.|\(local\))\\SQLEXPRESS(01)?$') {
        Block 'Server must be an explicitly local SQLEXPRESS or SQLEXPRESS01 named instance.'
    }
    if ($Database -cne $ExpectedDatabase) {
        Block ("Database must be the exact authorised fresh OwnerRun03 target {0}." -f $ExpectedDatabase)
    }

    $branch = (& git branch --show-current).Trim()
    $head = (& git rev-parse HEAD).Trim()
    $Result.repository.actualBranch = $branch
    $Result.repository.actualHead = $head
    if ($branch -cne $ExpectedBranch -or $head -cne $ExpectedHead) {
        Block ("Expected {0} at {1}; found {2} at {3}." -f $ExpectedBranch, $ExpectedHead, $branch, $head)
    }
    $status = @(& git status --porcelain=v1 --untracked-files=all)
    $unexpectedStatus = @($status | Where-Object { $_ -cnotin $AllowedUncommittedPaths })
    if ($unexpectedStatus.Count -gt 0) {
        Block ("Worktree contains changes other than this Tester harness: {0}" -f [string]::Join(' | ', $unexpectedStatus))
    }
    Add-Step 'Exact commit and worktree gate' PASS 'Branch/HEAD are exact; no unrelated worktree change is present.'

    $approval = Get-Content -Raw -Encoding UTF8 (Join-Path $RepositoryRoot $ApprovalPath) | ConvertFrom-Json
    $required = @('ProductPRB', 'IndependentTDA', 'InformationSecurity', 'DependencySME', 'TestServices')
    foreach ($decision in $required) {
        $entry = @($approval.requiredChecks | Where-Object { $_.RequiredDecision -ceq $decision -and $_.Found -eq $true })
        Assert-True ($entry.Count -eq 1) ("Approval evidence is missing required decision {0}." -f $decision)
    }
    Assert-True ($approval.approvedPackageCommit -ceq '985099c2ec05e3307bdc770af4a97e6e28df8c6e') 'Approval evidence is bound to an unexpected package commit.'
    Add-Step 'Phase 4 approval gate' PASS 'All five retained decisions are present at the approved architecture commit.'

    $dotnetEfCommand = Get-Command dotnet-ef -CommandType Application -ErrorAction SilentlyContinue
    if ($null -eq $dotnetEfCommand) {
        Block 'Pinned dotnet-ef is not installed or not on PATH; this harness does not restore tools.'
    }
    $script:DotnetEf = $dotnetEfCommand.Source
    $efVersion = Invoke-Native -Name 'dotnet-ef version prerequisite' -File $script:DotnetEf -Arguments @('--version')
    Assert-True ($efVersion -match '(^|\s)10\.0\.11($|\s)') 'dotnet-ef is not the repository-pinned 10.0.11 version.'

    $masterConnectionString = New-ConnectionString 'master'
    try {
        $serverIdentity = Invoke-Table @'
SELECT
    CAST(SERVERPROPERTY('MachineName') AS nvarchar(128)) AS MachineName,
    CAST(SERVERPROPERTY('InstanceName') AS nvarchar(128)) AS InstanceName,
    CAST(SERVERPROPERTY('EngineEdition') AS int) AS EngineEdition,
    CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(128)) AS ProductVersion;
'@ -ConnectionString $masterConnectionString
    }
    catch {
        Block ("Local SQL identity preflight failed before database lookup or creation: {0}" -f $_.Exception.Message)
    }
    $identity = $serverIdentity.Rows[0]
    $Result.target.verifiedMachine = [string] $identity.MachineName
    $Result.target.verifiedInstance = [string] $identity.InstanceName
    Assert-True ([string]::Equals([string] $identity.MachineName, $env:COMPUTERNAME, [StringComparison]::OrdinalIgnoreCase)) 'Connected SQL Server machine is not the local machine.'
    Assert-True ([int] $identity.EngineEdition -eq 4) 'Connected SQL Server is not SQL Express.'
    Assert-True ([string]::Equals([string] $identity.InstanceName, ($Server -replace '^.*\\', ''), [StringComparison]::OrdinalIgnoreCase)) 'Connected SQL instance does not match the requested local named instance.'
    Add-Step 'Local SQL Server identity' PASS 'Machine, named instance and Express edition are verified.' ([ordered]@{
        machine = [string] $identity.MachineName
        instance = [string] $identity.InstanceName
        productVersion = [string] $identity.ProductVersion
    })

    $databaseId = Invoke-Scalar 'SELECT DB_ID(@databaseName);' -ConnectionString $masterConnectionString -Parameters @{ '@databaseName' = $Database }
    $exists = $databaseId -ne $null -and $databaseId -ne [DBNull]::Value
    $Result.target.existedBeforeRun = $exists
    if ($exists) {
        Block 'The authorised target must be a fresh, previously nonexistent database. No existing database was accessed.'
    }
    Add-Step 'Fresh database non-existence gate' PASS 'Parameterized DB_ID returned NULL; the named database is fresh.'

    $DatabaseConnectionString = New-ConnectionString $Database
    [Environment]::SetEnvironmentVariable('ConnectionStrings__LgrDatabase', $DatabaseConnectionString, 'Process')
    [Environment]::SetEnvironmentVariable('DOTNET_ENVIRONMENT', 'Testing', 'Process')
    [Environment]::SetEnvironmentVariable('ASPNETCORE_ENVIRONMENT', 'Testing', 'Process')

    Invoke-EfUpdate -Migration $PreviousMigration -Name 'EF Up from empty to preceding migration'
    $DatabaseCreated = $true
    $Result.databaseCreated = $true
    $historyAtPrevious = @(Get-MigrationHistory)
    Assert-True ($historyAtPrevious[-1] -ceq $PreviousMigration) 'Preceding migration was not the latest applied migration after the first Up.'
    Assert-True ($historyAtPrevious -notcontains $CurrentMigration) 'Slice 1 migration was already applied at the preceding-migration gate.'
    Add-Step 'Preceding migration boundary' PASS 'Fresh database reached the exact preceding migration without Slice 1 schema.'

    Invoke-EfUpdate -Migration $CurrentMigration -Name 'EF Slice 1 migration Up'
    $historyAtCurrent = @(Get-MigrationHistory)
    Assert-True ($historyAtCurrent[-1] -ceq $CurrentMigration) 'Slice 1 migration is not the latest applied migration.'

    foreach ($object in @(
        @{ Type = 'UQ'; Name = 'AK_Applications_CustomerId_ProjectId_Id' },
        @{ Type = 'UQ'; Name = 'AK_Dependencies_CustomerId_ProjectId_Id' },
        @{ Type = 'UQ'; Name = 'AK_DependencyReferences_CustomerId_ProjectId_Id' },
        @{ Type = 'C'; Name = 'CK_Dependencies_SourceEndpoint' },
        @{ Type = 'C'; Name = 'CK_Dependencies_TargetEndpoint' },
        @{ Type = 'U'; Name = 'Dependencies' },
        @{ Type = 'U'; Name = 'DependencyReferences' },
        @{ Type = 'U'; Name = 'DependencyPolicies' },
        @{ Type = 'U'; Name = 'DependencyPolicyRules' },
        @{ Type = 'U'; Name = 'DependencyGraphStates' }
    )) {
        Assert-ObjectExists -Type $object.Type -Name $object.Name
    }

    $computed = Invoke-Table @'
SELECT c.[name], c.is_computed, c.is_nullable, TYPE_NAME(c.user_type_id) AS SqlType,
       cc.is_persisted AS IsPersisted
FROM sys.columns c
LEFT JOIN sys.computed_columns cc
  ON cc.object_id = c.object_id AND cc.column_id = c.column_id
WHERE c.object_id = OBJECT_ID(N'dbo.Dependencies')
  AND c.[name] IN (N'SourceEndpointKey', N'TargetEndpointKey', N'RowVersion')
ORDER BY c.[name];
'@
    Assert-True ($computed.Rows.Count -eq 3) 'Computed-key/rowversion schema did not return three expected columns.'
    $computedColumnEvidence = [Collections.ArrayList]::new()
    foreach ($row in $computed.Rows) {
        $columnName = [string] $row.name
        $sqlType = [string] $row.SqlType
        $isComputed = ConvertTo-RequiredInt32 $row.is_computed ("{0}.is_computed" -f $columnName)
        $isNullable = ConvertTo-RequiredInt32 $row.is_nullable ("{0}.is_nullable" -f $columnName)
        $isPersisted = if (Test-SqlNull $row.IsPersisted) {
            $null
        }
        else {
            ConvertTo-RequiredInt32 $row.IsPersisted ("{0}.is_persisted" -f $columnName)
        }

        if ($columnName -eq 'RowVersion') {
            Assert-True ($sqlType -eq 'timestamp') 'Dependencies.RowVersion is not SQL Server rowversion/timestamp.'
            Assert-True ($isComputed -eq 0 -and $isNullable -eq 0) 'Dependencies.RowVersion is unexpectedly computed or nullable.'
            Assert-True (Test-SqlNull $row.IsPersisted) 'Dependencies.RowVersion unexpectedly has computed-column persistence metadata.'
        }
        else {
            Assert-True ($columnName -in @('SourceEndpointKey', 'TargetEndpointKey')) 'Unexpected column was returned by the computed-key metadata query.'
            Assert-True (-not (Test-SqlNull $row.IsPersisted)) ("{0}.is_persisted evidence is missing." -f $columnName)
            Assert-True ($isComputed -eq 1 -and $isPersisted -eq 1) ("{0} is not computed and persisted." -f $columnName)
        }
        $null = $computedColumnEvidence.Add([ordered]@{
            name = $columnName
            sqlType = $sqlType
            computed = [bool] $isComputed
            persisted = $isPersisted
            nullable = [bool] $isNullable
        })
    }
    $filteredIndexes = [int] (Invoke-Scalar @'
SELECT COUNT_BIG(*)
FROM sys.indexes
WHERE object_id IN (OBJECT_ID(N'dbo.Dependencies'), OBJECT_ID(N'dbo.DependencyReferences'), OBJECT_ID(N'dbo.DependencyPolicies'))
  AND is_unique = 1 AND has_filter = 1;
'@)
    Assert-True ($filteredIndexes -eq 3) 'Expected exactly three filtered unique dependency indexes.'
    $endpointUniqueIndexCount = [int] (Invoke-Scalar @'
SELECT COUNT_BIG(*)
FROM sys.indexes
WHERE object_id = OBJECT_ID(N'dbo.Dependencies')
  AND [name] = N'UX_Dependencies_Owner_Endpoints_Type_Active'
  AND is_unique = 1
  AND has_filter = 1
  AND filter_definition IS NOT NULL;
'@)
    Assert-True ($endpointUniqueIndexCount -eq 1) 'The filtered unique active endpoint index was not found exactly once.'
    $policyProjectCount = [int] (Invoke-Scalar @'
SELECT COUNT_BIG(*)
FROM dbo.Projects p
WHERE EXISTS (SELECT 1 FROM dbo.DependencyGraphStates s WHERE s.CustomerId = p.CustomerId AND s.ProjectId = p.Id)
  AND EXISTS (SELECT 1 FROM dbo.DependencyPolicies policy WHERE policy.CustomerId = p.CustomerId AND policy.ProjectId = p.Id AND policy.IsActive = 1);
'@)
    $projectCount = [int] (Invoke-Scalar 'SELECT COUNT_BIG(*) FROM dbo.Projects;')
    Assert-True ($policyProjectCount -eq $projectCount) 'Not every existing project received graph state and one active policy.'
    $Result.schemaEvidence = [ordered]@{
        migrationCount = $historyAtCurrent.Count
        computedColumns = @($computedColumnEvidence)
        filteredUniqueIndexCount = $filteredIndexes
        endpointCheckConstraintsVerified = $true
        endpointUniqueIndexVerified = $true
        projectFoundationCount = $policyProjectCount
    }
    Add-Step 'SQL Server schema contract' PASS 'Tables, keys, persisted computed endpoint keys, rowversion, filtered indexes and project foundation are present.' $Result.schemaEvidence

    $null = Invoke-NonQuery @'
INSERT INTO dbo.Customers (Id, Name, Code, Status, CreatedAt, UpdatedAt)
VALUES ('55555555-5555-5555-5555-555555555001', N'PH4 Synthetic Customer B', N'PH4B', N'Active', SYSUTCDATETIME(), SYSUTCDATETIME());

INSERT INTO dbo.Projects (Id, CustomerId, Name, Description, Status, PlannedStartDate, PlannedEndDate, CreatedAt, UpdatedAt)
VALUES ('55555555-5555-5555-5555-555555555002', '55555555-5555-5555-5555-555555555001', N'PH4 Synthetic Project B', N'Synthetic isolation fixture only.', N'Active', NULL, NULL, SYSUTCDATETIME(), SYSUTCDATETIME());

INSERT INTO dbo.Applications
    (Id, CustomerId, ProjectId, Name, Environment, Description, Criticality,
     ApplicationType, CurrentVersion, MigrationScope, MigrationStrategy,
     MigrationStatus, CreatedAt, UpdatedAt)
VALUES
    ('55555555-5555-5555-5555-555555555100', '11111111-1111-1111-1111-111111111111',
     '22222222-2222-2222-2222-222222222222', N'PH4 Synthetic Source', N'Test',
     N'Synthetic provider-constraint fixture only.', N'Low', N'Custom', N'1',
     N'In Scope', N'Retain', N'Not Started', SYSUTCDATETIME(), SYSUTCDATETIME()),
    ('55555555-5555-5555-5555-555555555101', '55555555-5555-5555-5555-555555555001',
     '55555555-5555-5555-5555-555555555002', N'PH4 Foreign Synthetic App', N'Test',
     N'Synthetic isolation fixture only.', N'Low', N'Custom', N'1',
     N'In Scope', N'Retain', N'Not Started', SYSUTCDATETIME(), SYSUTCDATETIME());

INSERT INTO dbo.DependencyReferences
    (Id, CustomerId, ProjectId, ReferenceType, Name, NormalizedName, Description,
     ResolutionStatus, IsArchived, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy)
VALUES
    ('55555555-5555-5555-5555-555555555110', '11111111-1111-1111-1111-111111111111',
     '22222222-2222-2222-2222-222222222222', 'Api', N'PH4 Synthetic API',
     N'PH4 SYNTHETIC API', N'Inert synthetic label.', 'Resolved', 0,
     SYSUTCDATETIME(), N'ph4-tester', SYSUTCDATETIME(), N'ph4-tester');

INSERT INTO dbo.Dependencies
    (Id, CustomerId, ProjectId, SourceType, SourceApplicationId,
     TargetType, TargetReferenceId, DependencyType, Criticality,
     Description, BusinessContext, ConfirmationStatus, ConfirmedAt,
     ConfirmedBy, IsArchived, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy)
VALUES
    ('55555555-5555-5555-5555-555555555120', '11111111-1111-1111-1111-111111111111',
     '22222222-2222-2222-2222-222222222222', 'Application',
     '55555555-5555-5555-5555-555555555100', 'DependencyReference',
     '55555555-5555-5555-5555-555555555110', 'ApiCall', 'Mandatory',
     N'Synthetic dependency.', N'Synthetic assurance context.', 'Confirmed',
     SYSUTCDATETIME(), N'ph4-tester', 0, SYSUTCDATETIME(), N'ph4-tester',
     SYSUTCDATETIME(), N'ph4-tester');
'@

    $computedKeys = Invoke-Table @'
SELECT SourceEndpointKey, TargetEndpointKey, DATALENGTH(RowVersion) AS RowVersionBytes
FROM dbo.Dependencies
WHERE Id = '55555555-5555-5555-5555-555555555120';
'@
    Assert-True ($computedKeys.Rows.Count -eq 1) 'The valid seeded dependency row was not returned exactly once.'
    Assert-True (-not (Test-SqlNull $computedKeys.Rows[0].SourceEndpointKey)) 'A valid seeded dependency produced a NULL SourceEndpointKey.'
    Assert-True (-not (Test-SqlNull $computedKeys.Rows[0].TargetEndpointKey)) 'A valid seeded dependency produced a NULL TargetEndpointKey.'
    $computedSourceKey = [string] $computedKeys.Rows[0].SourceEndpointKey
    $computedTargetKey = [string] $computedKeys.Rows[0].TargetEndpointKey
    Assert-True ($computedSourceKey -ceq 'A:55555555555555555555555555555100') 'Source computed endpoint key is incorrect.'
    Assert-True ($computedTargetKey -ceq 'R:55555555555555555555555555555110') 'Target computed endpoint key is incorrect.'
    Assert-True ([int] $computedKeys.Rows[0].RowVersionBytes -eq 8) 'Dependency rowversion is not eight bytes.'

    $rejections = [Collections.ArrayList]::new()
    $null = $rejections.Add((Assert-SqlRejected 'controlled dependency type' @'
INSERT INTO dbo.Dependencies
    (Id, CustomerId, ProjectId, SourceType, SourceApplicationId, TargetType,
     TargetServerId, DependencyType, Criticality, ConfirmationStatus,
     IsArchived, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy)
VALUES
    (NEWID(), '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222',
     'Application', '55555555-5555-5555-5555-555555555100', 'Server',
     'bbbbbbbb-bbbb-bbbb-bbbb-000000000001', 'UnknownType', 'Mandatory',
     'Unconfirmed', 0, SYSUTCDATETIME(), N'ph4-tester', SYSUTCDATETIME(), N'ph4-tester');
'@ @(547)))
    $null = $rejections.Add((Assert-SqlRejected 'endpoint XOR/type coherence' @'
INSERT INTO dbo.Dependencies
    (Id, CustomerId, ProjectId, SourceType, SourceApplicationId, TargetType,
     TargetApplicationId, DependencyType, Criticality, ConfirmationStatus,
     IsArchived, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy)
VALUES
    (NEWID(), '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222',
     'Application', '55555555-5555-5555-5555-555555555100', 'Server',
     'aaaaaaaa-aaaa-aaaa-aaaa-000000000001', 'Service', 'Mandatory',
     'Unconfirmed', 0, SYSUTCDATETIME(), N'ph4-tester', SYSUTCDATETIME(), N'ph4-tester');
'@ @(547)))
    $null = $rejections.Add((Assert-SqlRejected 'self dependency' @'
INSERT INTO dbo.Dependencies
    (Id, CustomerId, ProjectId, SourceType, SourceApplicationId, TargetType,
     TargetApplicationId, DependencyType, Criticality, ConfirmationStatus,
     IsArchived, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy)
VALUES
    (NEWID(), '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222',
     'Application', '55555555-5555-5555-5555-555555555100', 'Application',
     '55555555-5555-5555-5555-555555555100', 'Service', 'Mandatory',
     'Unconfirmed', 0, SYSUTCDATETIME(), N'ph4-tester', SYSUTCDATETIME(), N'ph4-tester');
'@ @(547)))
    $null = $rejections.Add((Assert-SqlRejected 'cross-customer/project composite target FK' @'
INSERT INTO dbo.Dependencies
    (Id, CustomerId, ProjectId, SourceType, SourceApplicationId, TargetType,
     TargetApplicationId, DependencyType, Criticality, ConfirmationStatus,
     IsArchived, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy)
VALUES
    (NEWID(), '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222',
     'Application', '55555555-5555-5555-5555-555555555100', 'Application',
     '55555555-5555-5555-5555-555555555101', 'Service', 'Mandatory',
     'Unconfirmed', 0, SYSUTCDATETIME(), N'ph4-tester', SYSUTCDATETIME(), N'ph4-tester');
'@ @(547)))
    $null = $rejections.Add((Assert-SqlRejected 'active duplicate dependency' @'
INSERT INTO dbo.Dependencies
    (Id, CustomerId, ProjectId, SourceType, SourceApplicationId, TargetType,
     TargetReferenceId, DependencyType, Criticality, ConfirmationStatus,
     IsArchived, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy)
VALUES
    (NEWID(), '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222',
     'Application', '55555555-5555-5555-5555-555555555100', 'DependencyReference',
     '55555555-5555-5555-5555-555555555110', 'ApiCall', 'Advisory',
     'Unconfirmed', 0, SYSUTCDATETIME(), N'ph4-tester', SYSUTCDATETIME(), N'ph4-tester');
'@ @(2601, 2627)))
    $null = $rejections.Add((Assert-SqlRejected 'reference Restrict delete' @'
DELETE FROM dbo.DependencyReferences WHERE Id = '55555555-5555-5555-5555-555555555110';
'@ @(547)))
    $null = $rejections.Add((Assert-SqlRejected 'canonical asset Restrict delete' @'
DELETE FROM dbo.Applications WHERE Id = '55555555-5555-5555-5555-555555555100';
'@ @(547)))

    $originalVersion = [byte[]] (Invoke-Scalar @'
SELECT RowVersion FROM dbo.Dependencies WHERE Id = '55555555-5555-5555-5555-555555555120';
'@)
    $firstUpdate = Invoke-NonQuery @'
UPDATE dbo.Dependencies
SET Description = N'First rowversion update', UpdatedAt = SYSUTCDATETIME()
WHERE Id = '55555555-5555-5555-5555-555555555120' AND RowVersion = @version;
'@ -Parameters @{ '@version' = $originalVersion }
    $staleUpdate = Invoke-NonQuery @'
UPDATE dbo.Dependencies
SET Description = N'Stale update must not apply', UpdatedAt = SYSUTCDATETIME()
WHERE Id = '55555555-5555-5555-5555-555555555120' AND RowVersion = @version;
'@ -Parameters @{ '@version' = $originalVersion }
    Assert-True ($firstUpdate -eq 1 -and $staleUpdate -eq 0) 'SQL rowversion did not reject the stale update.'

    $simultaneous = Test-SimultaneousDuplicateConstraint
    $Result.constraintEvidence = [ordered]@{
        computedSourceKey = $computedSourceKey
        computedTargetKey = $computedTargetKey
        rejections = $rejections
        restrictDeleteVerified = $true
        crossScopeCompositeFkVerified = $true
    }
    $Result.concurrencyEvidence = [ordered]@{
        optimisticFirstWriteRows = $firstUpdate
        optimisticStaleWriteRows = $staleUpdate
        simultaneousEquivalentInsert = $simultaneous
    }
    Add-Step 'SQL Server provider constraints' PASS 'Controlled values, XOR, self, composite isolation FK, filtered duplicate uniqueness and Restrict deletes rejected invalid writes.' $Result.constraintEvidence
    Add-Step 'SQL Server concurrency' PASS 'Rowversion rejected a stale update and a simultaneous equivalent insert resolved to one commit plus one unique-key rejection.' $Result.concurrencyEvidence

    $legacyBeforeDown = Get-LegacyFingerprint
    Invoke-EfUpdate -Migration $PreviousMigration -Name 'Authorised disposable Down to preceding migration'
    $dependenciesAfterDown = [int] (Invoke-Scalar "SELECT COUNT_BIG(*) FROM sys.tables WHERE [name] = N'Dependencies';")
    Assert-True ($dependenciesAfterDown -eq 0) 'Dependencies table remained after authorised Down.'
    $applicationKeyAfterDown = [int] (Invoke-Scalar "SELECT COUNT_BIG(*) FROM sys.key_constraints WHERE [name] = N'AK_Applications_CustomerId_ProjectId_Id';")
    Assert-True ($applicationKeyAfterDown -eq 0) 'Application alternate key remained after authorised Down.'
    $legacyAfterDown = Get-LegacyFingerprint
    Assert-FingerprintEqual -Expected $legacyBeforeDown -Actual $legacyAfterDown -Phase 'Down'

    Invoke-EfUpdate -Migration $CurrentMigration -Name 'EF Slice 1 migration reapply'
    $legacyAfterReapply = Get-LegacyFingerprint
    Assert-FingerprintEqual -Expected $legacyBeforeDown -Actual $legacyAfterReapply -Phase 'Reapply'
    $finalHistory = @(Get-MigrationHistory)
    Assert-True ($finalHistory[-1] -ceq $CurrentMigration) 'Database is not left at the Slice 1 migration after reapply.'
    $finalFoundation = [int] (Invoke-Scalar @'
SELECT COUNT_BIG(*)
FROM dbo.Projects p
WHERE EXISTS (SELECT 1 FROM dbo.DependencyGraphStates s WHERE s.CustomerId = p.CustomerId AND s.ProjectId = p.Id)
  AND EXISTS (SELECT 1 FROM dbo.DependencyPolicies policy WHERE policy.CustomerId = p.CustomerId AND policy.ProjectId = p.Id AND policy.IsActive = 1);
'@)
    Assert-True ($finalFoundation -eq [int] $legacyAfterReapply.projectCount) 'Reapply did not restore dependency foundation for every retained project.'
    $Result.migrations.finalHistory = $finalHistory
    $Result.rollbackEvidence = [ordered]@{
        legacyBeforeDown = $legacyBeforeDown
        legacyAfterDown = $legacyAfterDown
        legacyAfterReapply = $legacyAfterReapply
        dependencyTableRemovedByDown = $true
        applicationAlternateKeyRemovedByDown = $true
        finalFoundationProjectCount = $finalFoundation
    }
    $Result.databaseLeftFullyMigrated = $true
    Add-Step 'Authorised Down/reapply rehearsal' PASS 'Down removed only Slice 1 structures, retained legacy fingerprints, and reapply restored all project foundations.' $Result.rollbackEvidence

    $Result.outcome = 'PASS'
    $Result.outcomeReason = 'All authorised fresh local SQL Server Slice 1 assurance steps passed.'
    $ExitCode = 0
}
catch {
    $message = $_.Exception.Message
    if ($message.StartsWith('PH4_BLOCKED::', [StringComparison]::Ordinal)) {
        $detail = $message.Substring('PH4_BLOCKED::'.Length)
        Add-Step 'Harness terminal state' BLOCKED $detail
        $Result.outcome = 'BLOCKED'
        $Result.outcomeReason = $detail
        $ExitCode = 2
    }
    else {
        $detail = if ($message.StartsWith('PH4_FAIL::', [StringComparison]::Ordinal)) {
            $message.Substring('PH4_FAIL::'.Length)
        }
        else {
            $message
        }
        $null = $Defects.Add([ordered]@{
            severity = 'High'
            summary = $detail
            exceptionType = $_.Exception.GetType().FullName
        })
        Add-Step 'Harness terminal state' FAIL $detail
        $Result.outcome = 'FAIL'
        $Result.outcomeReason = $detail
        $ExitCode = 1
    }
}
finally {
    [Environment]::SetEnvironmentVariable('ConnectionStrings__LgrDatabase', $SavedConnectionString, 'Process')
    [Environment]::SetEnvironmentVariable('DOTNET_ENVIRONMENT', $SavedDotnetEnvironment, 'Process')
    [Environment]::SetEnvironmentVariable('ASPNETCORE_ENVIRONMENT', $SavedAspnetcoreEnvironment, 'Process')
    $Result.completedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
    $Result.databaseCreated = $DatabaseCreated
    $Result.databaseAutomaticallyDroppedOrDeleted = $false
    New-Item -ItemType Directory -Force -Path $ResultDirectory | Out-Null
    $Result | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $ResultPath -Encoding UTF8
    Write-Host ("Result: {0}" -f $ResultPath)
    Write-Host 'The harness never drops or automatically deletes the database.'
}

exit $ExitCode
