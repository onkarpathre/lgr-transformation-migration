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
    - "Authorised Test Authority Ashish Tester, 11 September 2026, exact commit and isolated localhost SQL Express assurance scope: https://github.com/onkarpathre/lgr-transformation-migration/issues/4#issuecomment-5639746843"
    - "Authorised Test Authority Ashish, 15 September 2026, phase-level RetryNN recovery approval beginning with exact Retry01: https://github.com/onkarpathre/lgr-transformation-migration/issues/4#issuecomment-5672361217"

Tester-owned, manual SQL Server runtime assurance harness for PH3-SQL-001 Slice 1.

The script is deliberately fail-closed. It can target only the exact approved local
SQL Server Express instance and new isolated database. It never drops the database,
changes server security/configuration, or cleans up test data. The final database is
left fully migrated for its owner to inspect and later dispose of under separate
authority.

The phase-level approval permits a later, unused RetryNN only after the preceding
run fails. Retry04 failed with its database retained untouched; its immutable result
is TestResults/PH3_SQL_Slice1_Assurance_20260915T073438999Z/result.json. This harness
is therefore advanced to exact Retry05. Each execution remains pinned to one literal
$ExpectedDatabase value and uses an ordinal case-sensitive equality gate. Advancing
to a later RetryNN requires a Tester-owned source update and static revalidation;
prefix matching is prohibited.
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
$ExpectedDatabase = 'LgrTransformationMigration_Ph3Sql_Assurance_20260915_Retry05'
$FailedPredecessorDatabase = 'LgrTransformationMigration_Ph3Sql_Assurance_20260915_Retry04'
$FailedPredecessorResult = 'TestResults/PH3_SQL_Slice1_Assurance_20260915T073438999Z/result.json'
$ExpectedBranch = 'feature/ph3-sql-implementation'
$ExpectedHead = '284ebacc5633db0da940b206f6eeebf0d61447af'
$ExpectedSqlVersion = '16.0.1000.6'
$PreviousMigrationBoundary = '20260824181918_AddDiscoveryImport'
$ExpectedMigrations = @(
    '20260823111854_InitialCreate',
    '20260824181918_AddDiscoveryImport',
    '20260909164944_AddSqlInventory',
    '20260910082037_AddInternalPrincipalAuditType'
)
$FixtureNames = [ordered]@{
    BaselineInstance = 'BASELINE_INSTANCE_A1'
    BaselineDatabase = 'BaselineDatabaseA1'
    CrossCustomerInstanceAttempt = 'NEG_FK_INSTANCE_CROSS_CUSTOMER'
    CrossProjectInstanceAttempt = 'NEG_FK_INSTANCE_CROSS_PROJECT'
    PortBelowInstanceAttempt = 'NEG_CHECK_PORT_BELOW'
    PortAboveInstanceAttempt = 'NEG_CHECK_PORT_ABOVE'
    CrossCustomerDatabaseParentInstance = 'PARENT_DB_CROSS_CUSTOMER'
    CrossProjectDatabaseParentInstance = 'PARENT_DB_CROSS_PROJECT'
    NegativeSizeDatabaseParentInstance = 'PARENT_DB_NEGATIVE_SIZE'
    CompatibilityLowDatabaseParentInstance = 'PARENT_DB_COMPATIBILITY_LOW'
    CompatibilityHighDatabaseParentInstance = 'PARENT_DB_COMPATIBILITY_HIGH'
    CrossCustomerDatabaseAttempt = 'NegFkDatabaseCrossCustomer'
    CrossProjectDatabaseAttempt = 'NegFkDatabaseCrossProject'
    NegativeSizeDatabaseAttempt = 'NegCheckDatabaseSize'
    CompatibilityLowDatabaseAttempt = 'NegCheckDatabaseCompatibilityLow'
    CompatibilityHighDatabaseAttempt = 'NegCheckDatabaseCompatibilityHigh'
    InstanceDuplicateBaseline = 'DuplicateInstanceKey'
    InstanceDuplicateAttempt = ' duplicateinstancekey '
    DatabaseDuplicateParentInstance = 'PARENT_DB_DUPLICATE'
    DatabaseDuplicateBaseline = 'DuplicateDatabaseKey'
    DatabaseDuplicateAttempt = ' duplicatedatabasekey '
    AliasInstanceBaseline = 'DEFAULT'
    AliasInstanceAttempt = 'default'
    UnicodeDatabaseParentInstance = 'PARENT_DB_UNICODE'
    ConcurrentInstance = 'ConcurrentInstanceKey'
}

$RepositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$SolutionPath = Join-Path $RepositoryRoot 'LgrTransformationMigration.sln'
$ApiProjectPath = Join-Path $RepositoryRoot 'src\api\LgrTransformationMigration.Api.csproj'
$RunId = [DateTimeOffset]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
$ResultsDirectory = Join-Path $RepositoryRoot (Join-Path 'TestResults' ("PH3_SQL_Slice1_Assurance_{0}" -f $RunId))
$ResultPath = Join-Path $ResultsDirectory 'result.json'
$PlansDirectory = Join-Path $ResultsDirectory 'execution-plans'

$Steps = New-Object System.Collections.ArrayList
$SchemaInspections = New-Object System.Collections.ArrayList
$ExecutionPlans = New-Object System.Collections.ArrayList
$Result = [ordered]@{
    schemaVersion = '1.0'
    workItem = 'PH3-SQL-001-slice-1-sql-server-runtime-assurance'
    testerRole = 'Tester Agent'
    approval = 'https://github.com/onkarpathre/lgr-transformation-migration/issues/4#issuecomment-5672361217'
    recovery = [ordered]@{
        phaseLevelApproval = 'https://github.com/onkarpathre/lgr-transformation-migration/issues/4#issuecomment-5672361217'
        failedPredecessorDatabase = $FailedPredecessorDatabase
        failedPredecessorOutcome = 'FAIL'
        failedPredecessorReason = 'Concurrent duplicate test persisted 0 active rows; expected exactly one.'
        failedPredecessorResult = $FailedPredecessorResult
        failedPredecessorRetainedUntouched = $true
        authorisedRetryDatabase = $ExpectedDatabase
    }
    startedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
    completedAtUtc = $null
    outcome = 'BLOCKED'
    outcomeReason = 'Harness did not reach a terminal result.'
    repository = [ordered]@{
        expectedBranch = $ExpectedBranch
        actualBranch = $null
        expectedHead = $ExpectedHead
        actualHead = $null
    }
    target = [ordered]@{
        server = $ExpectedServer
        database = $ExpectedDatabase
        authentication = 'Windows Integrated Authentication'
        trustServerCertificate = $true
        connectionStringRecorded = $false
    }
    expectedMigrations = $ExpectedMigrations
    previousMigrationBoundary = $PreviousMigrationBoundary
    serverEvidence = $null
    testSummaries = [ordered]@{}
    migrationHistory = [ordered]@{}
    normalizationEvidence = $null
    concurrencyEvidence = $null
    schemaInspections = $SchemaInspections
    executionPlans = $ExecutionPlans
    steps = $Steps
    databaseLeftFullyMigrated = $false
    databaseAutomaticallyDroppedOrDeleted = $false
    resultFile = $ResultPath
}

$PreviousLocation = Get-Location
$SavedEnvironment = [ordered]@{}
$ExitCode = 2

function ConvertTo-MeaningfulMessage {
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string] $Message,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Fallback
    )

    if ([string]::IsNullOrWhiteSpace($Message)) {
        return $Fallback
    }

    return $Message
}

function Write-Evidence {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('INFO', 'PASS', 'FAIL', 'BLOCKED')]
        [string] $Status,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string] $Message
    )

    $safeMessage = ConvertTo-MeaningfulMessage -Message $Message -Fallback 'No evidence message was provided.'
    $timestamp = [DateTimeOffset]::UtcNow.ToString('o')
    Write-Host ("[{0}] [{1}] {2}" -f $timestamp, $Status, $safeMessage)
}

function Add-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('PASS', 'FAIL', 'BLOCKED')]
        [string] $Outcome,

        [Parameter(Mandatory = $true)]
        [string] $Detail,

        [AllowNull()]
        [object] $Evidence = $null,

        [AllowNull()]
        [string] $StartedAtUtc = $null
    )

    $record = [ordered]@{
        name = $Name
        outcome = $Outcome
        startedAtUtc = if ($null -eq $StartedAtUtc) { [DateTimeOffset]::UtcNow.ToString('o') } else { $StartedAtUtc }
        completedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
        detail = $Detail
        evidence = $Evidence
    }
    $null = $Steps.Add($record)
    Write-Evidence -Status $Outcome -Message ("{0}: {1}" -f $Name, $Detail)
}

function Throw-Blocked {
    param([Parameter(Mandatory = $true)][string] $Message)
    throw [System.InvalidOperationException]::new("PH3_BLOCKED::{0}" -f $Message)
}

function Throw-Fail {
    param([Parameter(Mandatory = $true)][string] $Message)
    throw [System.InvalidOperationException]::new("PH3_FAIL::{0}" -f $Message)
}

function Assert-Condition {
    param(
        [Parameter(Mandatory = $true)]
        [bool] $Condition,

        [Parameter(Mandatory = $true)]
        [string] $Message
    )

    if (-not $Condition) {
        Throw-Fail -Message $Message
    }
}

function Save-ProcessEnvironmentValue {
    param([Parameter(Mandatory = $true)][string] $Name)

    $item = Get-Item -LiteralPath ("Env:{0}" -f $Name) -ErrorAction SilentlyContinue
    $SavedEnvironment[$Name] = [ordered]@{
        existed = $null -ne $item
        value = if ($null -eq $item) { $null } else { $item.Value }
    }
}

function Restore-ProcessEnvironment {
    foreach ($entry in $SavedEnvironment.GetEnumerator()) {
        if ([bool] $entry.Value.existed) {
            [Environment]::SetEnvironmentVariable($entry.Key, [string] $entry.Value.value, 'Process')
        }
        else {
            [Environment]::SetEnvironmentVariable($entry.Key, $null, 'Process')
        }
    }
}

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $true)]
        [string] $FilePath,

        [Parameter(Mandatory = $true)]
        [string[]] $Arguments,

        [ValidateSet('FAIL', 'BLOCKED')]
        [string] $FailureOutcome = 'FAIL'
    )

    $started = [DateTimeOffset]::UtcNow.ToString('o')
    Write-Evidence -Status INFO -Message ("Starting {0}." -f $Name)
    $outputLines = New-Object 'System.Collections.Generic.List[string]'
    $exit = $null
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        # Windows PowerShell represents native stderr as ErrorRecord objects. Capture
        # those records without allowing a legitimate blank line to become a
        # terminating error under the harness-wide Stop preference.
        $ErrorActionPreference = 'Continue'
        & $FilePath @Arguments 2>&1 | ForEach-Object {
            $line = [string] $_
            $outputLines.Add($line)
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                Write-Evidence -Status INFO -Message $line
            }
        }
        $exit = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    $output = [string]::Join([Environment]::NewLine, [string[]] $outputLines)
    $evidence = [ordered]@{
        executable = [System.IO.Path]::GetFileName($FilePath)
        arguments = $Arguments
        exitCode = $exit
        output = $output
    }

    if ($exit -ne 0) {
        Add-Step -Name $Name -Outcome $FailureOutcome -Detail ("Command exited {0}." -f $exit) -Evidence $evidence -StartedAtUtc $started
        if ($FailureOutcome -eq 'BLOCKED') {
            Throw-Blocked -Message ("{0} exited {1}." -f $Name, $exit)
        }
        Throw-Fail -Message ("{0} exited {1}." -f $Name, $exit)
    }

    Add-Step -Name $Name -Outcome PASS -Detail 'Command completed with exit code 0.' -Evidence $evidence -StartedAtUtc $started
    return $output
}

function Get-TestSummary {
    param([Parameter(Mandatory = $true)][string] $Output)

    $matches = [regex]::Matches(
        $Output,
        'Failed:\s*(?<failed>\d+),\s*Passed:\s*(?<passed>\d+),\s*Skipped:\s*(?<skipped>\d+),\s*Total:\s*(?<total>\d+)',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    $summary = [ordered]@{ failed = 0; passed = 0; skipped = 0; total = 0; assemblies = $matches.Count }
    foreach ($match in $matches) {
        $summary.failed += [int] $match.Groups['failed'].Value
        $summary.passed += [int] $match.Groups['passed'].Value
        $summary.skipped += [int] $match.Groups['skipped'].Value
        $summary.total += [int] $match.Groups['total'].Value
    }
    return $summary
}

function Assert-TestSummary {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $Output,
        [Parameter(Mandatory = $true)][int] $ExpectedPassed
    )

    $summary = Get-TestSummary -Output $Output
    Assert-Condition -Condition ($summary.assemblies -gt 0) -Message ("{0} emitted no parseable test summary." -f $Name)
    Assert-Condition -Condition ($summary.failed -eq 0) -Message ("{0} reported {1} failed tests." -f $Name, $summary.failed)
    Assert-Condition -Condition ($summary.skipped -eq 0) -Message ("{0} reported {1} skipped tests." -f $Name, $summary.skipped)
    Assert-Condition -Condition ($summary.passed -eq $ExpectedPassed) -Message ("{0} passed {1}; expected exactly {2}." -f $Name, $summary.passed, $ExpectedPassed)
    Assert-Condition -Condition ($summary.total -eq $ExpectedPassed) -Message ("{0} total was {1}; expected exactly {2}." -f $Name, $summary.total, $ExpectedPassed)
    Write-Evidence -Status PASS -Message ("{0}: {1}/{1} passed, 0 failed, 0 skipped." -f $Name, $ExpectedPassed)
    return $summary
}

function New-ConnectionString {
    param(
        [Parameter(Mandatory = $true)][string] $InitialCatalog
    )

    $builder = [System.Data.SqlClient.SqlConnectionStringBuilder]::new()
    $builder['Data Source'] = $ExpectedServer
    $builder['Initial Catalog'] = $InitialCatalog
    $builder['Integrated Security'] = $true
    $builder['Encrypt'] = $true
    $builder['TrustServerCertificate'] = $true
    $builder['Application Name'] = 'PH3-SQL-001 Slice1 Assurance'
    $builder['Connect Timeout'] = 15
    Assert-Condition -Condition ($builder['Data Source'] -ceq $ExpectedServer) -Message 'Connection builder changed the approved server name.'
    Assert-Condition -Condition ($builder['Initial Catalog'] -ceq $InitialCatalog) -Message 'Connection builder changed the approved database name.'
    Assert-Condition -Condition ([bool] $builder['Integrated Security']) -Message 'Integrated Security is not enabled.'
    Assert-Condition -Condition ([bool] $builder['TrustServerCertificate']) -Message 'TrustServerCertificate is not enabled.'
    return $builder.ConnectionString
}

function New-SqlParameterSpec {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][System.Data.SqlDbType] $Type,
        [AllowNull()][object] $Value,
        [int] $Size = 0
    )

    if ($Type -in @([System.Data.SqlDbType]::Binary, [System.Data.SqlDbType]::VarBinary, [System.Data.SqlDbType]::Image)) {
        if ($null -ne $Value -and $Value -isnot [System.Byte[]]) {
            Throw-Fail -Message ("Binary SQL parameter '{0}' must be supplied as System.Byte[]; received {1}." -f $Name, $Value.GetType().FullName)
        }

        [System.Byte[]] $binaryValue = $Value
        return [pscustomobject]@{ Name = $Name; Type = $Type; Value = $binaryValue; Size = $Size }
    }

    return [pscustomobject]@{ Name = $Name; Type = $Type; Value = $Value; Size = $Size }
}

function Add-SqlParameters {
    param(
        [Parameter(Mandatory = $true)][System.Data.SqlClient.SqlCommand] $Command,
        [object[]] $Parameters = @()
    )

    foreach ($spec in $Parameters) {
        $parameter = $Command.Parameters.Add([string] $spec.Name, [System.Data.SqlDbType] $spec.Type)
        if ([int] $spec.Size -gt 0) {
            $parameter.Size = [int] $spec.Size
        }
        if ($null -eq $spec.Value) {
            $parameter.Value = [DBNull]::Value
        }
        elseif ([System.Data.SqlDbType] $spec.Type -in @([System.Data.SqlDbType]::Binary, [System.Data.SqlDbType]::VarBinary, [System.Data.SqlDbType]::Image)) {
            if ($spec.Value -isnot [System.Byte[]]) {
                Throw-Fail -Message ("Binary SQL parameter '{0}' lost its System.Byte[] type before provider assignment; received {1}." -f $spec.Name, $spec.Value.GetType().FullName)
            }

            [System.Byte[]] $binaryValue = $spec.Value
            $parameter.Value = $binaryValue
        }
        else {
            $parameter.Value = $spec.Value
        }
    }
}

function Assert-BinaryProviderParameterPreservation {
    [System.Byte[]] $expectedValue = [System.Byte[]] (0, 1, 2, 3, 4, 5, 6, 255)
    $command = New-Object System.Data.SqlClient.SqlCommand
    try {
        Add-SqlParameters -Command $command -Parameters @(
            (New-SqlParameterSpec -Name '@RowVersionSmoke' -Type Binary -Value $expectedValue -Size 8)
        )

        $parameter = $command.Parameters['@RowVersionSmoke']
        Assert-Condition -Condition ($parameter.SqlDbType -eq [System.Data.SqlDbType]::Binary) -Message 'Binary provider-parameter smoke test did not retain SqlDbType.Binary.'
        Assert-Condition -Condition ($parameter.Size -eq 8) -Message 'Binary provider-parameter smoke test did not retain size 8.'
        Assert-Condition -Condition ($parameter.Value.GetType() -eq [System.Byte[]]) -Message ("Binary provider-parameter smoke test produced {0}; expected System.Byte[]." -f $parameter.Value.GetType().FullName)
        Assert-Condition -Condition ([BitConverter]::ToString($expectedValue) -ceq [BitConverter]::ToString([System.Byte[]] $parameter.Value)) -Message 'Binary provider-parameter smoke test changed the byte sequence.'

        Add-Step -Name 'Binary provider-parameter preservation smoke test' -Outcome PASS -Detail 'Without opening a SQL connection, SqlDbType.Binary size 8 retained an exact System.Byte[] Value; PowerShell did not expand it to System.Object[].'
    }
    finally {
        $command.Dispose()
    }
}

function Open-ExactDatabaseConnection {
    $connection = New-Object System.Data.SqlClient.SqlConnection (New-ConnectionString -InitialCatalog $ExpectedDatabase)
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = 'SELECT DB_NAME();'
        $actualDatabase = [string] $command.ExecuteScalar()
        if ($actualDatabase -cne $ExpectedDatabase) {
            $connection.Dispose()
            Throw-Blocked -Message ("Connected to unexpected database '{0}'." -f $actualDatabase)
        }
        return $connection
    }
    catch {
        if ($connection.State -ne [System.Data.ConnectionState]::Closed) {
            $connection.Close()
        }
        $connection.Dispose()
        throw
    }
}

function Invoke-SqlQuery {
    param(
        [Parameter(Mandatory = $true)][string] $Sql,
        [object[]] $Parameters = @()
    )

    $connection = Open-ExactDatabaseConnection
    try {
        $command = $connection.CreateCommand()
        $command.CommandTimeout = 30
        $command.CommandText = $Sql
        Add-SqlParameters -Command $command -Parameters $Parameters
        $reader = $command.ExecuteReader()
        try {
            $rows = New-Object System.Collections.ArrayList
            while ($reader.Read()) {
                $row = [ordered]@{}
                for ($index = 0; $index -lt $reader.FieldCount; $index++) {
                    $value = $reader.GetValue($index)
                    if ($value -is [DBNull]) {
                        $row[$reader.GetName($index)] = $null
                    }
                    elseif ($value -is [System.Byte[]]) {
                        [System.Byte[]] $binaryValue = $value
                        $row[$reader.GetName($index)] = $binaryValue
                    }
                    else {
                        $row[$reader.GetName($index)] = $value
                    }
                }
                $null = $rows.Add([pscustomobject] $row)
            }
            return @($rows)
        }
        finally {
            $reader.Dispose()
        }
    }
    finally {
        $connection.Dispose()
    }
}

function Invoke-SqlScalar {
    param(
        [Parameter(Mandatory = $true)][string] $Sql,
        [object[]] $Parameters = @()
    )

    $connection = Open-ExactDatabaseConnection
    try {
        $command = $connection.CreateCommand()
        $command.CommandTimeout = 30
        $command.CommandText = $Sql
        Add-SqlParameters -Command $command -Parameters $Parameters
        $value = $command.ExecuteScalar()
        if ($value -is [DBNull]) {
            return $null
        }
        if ($value -is [System.Byte[]]) {
            [System.Byte[]] $binaryValue = $value
            return ,$binaryValue
        }
        return $value
    }
    finally {
        $connection.Dispose()
    }
}

function Invoke-SqlNonQuery {
    param(
        [Parameter(Mandatory = $true)][string] $Sql,
        [object[]] $Parameters = @()
    )

    $connection = Open-ExactDatabaseConnection
    try {
        $command = $connection.CreateCommand()
        $command.CommandTimeout = 30
        $command.CommandText = $Sql
        Add-SqlParameters -Command $command -Parameters $Parameters
        return $command.ExecuteNonQuery()
    }
    finally {
        $connection.Dispose()
    }
}

function Find-SqlException {
    param([Parameter(Mandatory = $true)][System.Exception] $Exception)

    $candidate = $Exception
    while ($null -ne $candidate) {
        if ($candidate -is [System.Data.SqlClient.SqlException]) {
            return $candidate
        }
        $candidate = $candidate.InnerException
    }
    return $null
}

function Assert-SqlFailure {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][scriptblock] $Action,
        [Parameter(Mandatory = $true)][int[]] $ExpectedNumbers,
        [AllowNull()][string] $ExpectedMessageFragment = $null
    )

    $caught = $null
    try {
        $null = & $Action
    }
    catch {
        $caught = $_.Exception
    }

    if ($null -eq $caught) {
        Throw-Fail -Message ("{0} unexpectedly succeeded." -f $Name)
    }
    $sqlException = Find-SqlException -Exception $caught
    if ($null -eq $sqlException) {
        Throw-Fail -Message ("{0} failed with a non-SQL exception: {1}" -f $Name, $caught.Message)
    }
    Assert-Condition -Condition ($ExpectedNumbers -contains $sqlException.Number) -Message ("{0} returned SQL error {1}; expected {2}." -f $Name, $sqlException.Number, ($ExpectedNumbers -join '/'))
    if (-not [string]::IsNullOrWhiteSpace($ExpectedMessageFragment)) {
        Assert-Condition -Condition ($sqlException.Message.IndexOf($ExpectedMessageFragment, [StringComparison]::Ordinal) -ge 0) -Message ("{0} did not identify expected constraint/index '{1}'." -f $Name, $ExpectedMessageFragment)
    }
    Write-Evidence -Status PASS -Message ("{0}: SQL Server rejected the write with error {1}." -f $Name, $sqlException.Number)
    return [ordered]@{ name = $Name; sqlErrorNumber = $sqlException.Number; message = $sqlException.Message }
}

function Assert-ExactSet {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string[]] $Expected,
        [Parameter(Mandatory = $true)][string[]] $Actual
    )

    $expectedSorted = @($Expected | Sort-Object)
    $actualSorted = @($Actual | Sort-Object)
    Assert-Condition -Condition (($expectedSorted -join '|') -ceq ($actualSorted -join '|')) -Message ("{0} mismatch. Expected [{1}], actual [{2}]." -f $Name, ($expectedSorted -join ', '), ($actualSorted -join ', '))
}

function Assert-MigrationHistory {
    param(
        [Parameter(Mandatory = $true)][string] $Phase,
        [Parameter(Mandatory = $true)][string[]] $Expected
    )

    $rows = @(Invoke-SqlQuery -Sql 'SELECT [MigrationId] FROM [dbo].[__EFMigrationsHistory] ORDER BY [MigrationId];')
    $actual = @($rows | ForEach-Object { [string] $_.MigrationId })
    Assert-ExactSet -Name ("{0} migration history" -f $Phase) -Expected $Expected -Actual $actual
    Write-Evidence -Status PASS -Message ("{0}: migration history contains exactly {1} expected migration(s)." -f $Phase, $Expected.Count)
    return $actual
}

function Assert-EfNoPendingMigrations {
    param([Parameter(Mandatory = $true)][string] $Output)

    foreach ($failurePattern in @(
        'Continuing without the information provided by the database',
        'error occurred while accessing the database',
        'unable to connect',
        'Cannot generate SSPI context'
    )) {
        Assert-Condition -Condition (-not [regex]::IsMatch($Output, [regex]::Escape($failurePattern), [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) -Message ("EF migration status was unavailable: output contained '{0}'." -f $failurePattern)
    }
    Assert-Condition -Condition (-not [regex]::IsMatch($Output, '\(Pending\)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) -Message 'EF reports one or more pending migrations.'
    foreach ($migration in $ExpectedMigrations) {
        $count = [regex]::Matches($Output, [regex]::Escape($migration)).Count
        Assert-Condition -Condition ($count -eq 1) -Message ("EF migration list contains '{0}' {1} times; expected once." -f $migration, $count)
    }
    Write-Evidence -Status PASS -Message 'EF reports all four migrations applied and no pending migration.'
}

function Get-TableColumns {
    param([Parameter(Mandatory = $true)][string] $QualifiedTable)

    return @(Invoke-SqlQuery -Sql @'
SELECT
    c.column_id AS ColumnOrder,
    c.name AS ColumnName,
    ty.name AS DataType,
    CASE
        WHEN ty.name IN (N'nvarchar', N'nchar') AND c.max_length <> -1 THEN c.max_length / 2
        WHEN ty.name IN (N'varchar', N'char', N'varbinary', N'binary') THEN c.max_length
        ELSE NULL
    END AS LogicalMaxLength,
    c.is_nullable AS IsNullable,
    c.is_identity AS IsIdentity,
    c.is_computed AS IsComputed
FROM sys.columns AS c
INNER JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(@QualifiedTable, N'U')
ORDER BY c.column_id;
'@ -Parameters @(
        (New-SqlParameterSpec -Name '@QualifiedTable' -Type NVarChar -Value $QualifiedTable -Size 260)
    ))
}

function Assert-Columns {
    param(
        [Parameter(Mandatory = $true)][string] $QualifiedTable,
        [Parameter(Mandatory = $true)][object[]] $ExpectedColumns
    )

    $actual = @(Get-TableColumns -QualifiedTable $QualifiedTable)
    Assert-Condition -Condition ($actual.Count -eq $ExpectedColumns.Count) -Message ("{0} has {1} columns; expected exactly {2}." -f $QualifiedTable, $actual.Count, $ExpectedColumns.Count)
    Assert-ExactSet -Name ("{0} columns" -f $QualifiedTable) -Expected @($ExpectedColumns | ForEach-Object { [string] $_.Name }) -Actual @($actual | ForEach-Object { [string] $_.ColumnName })

    foreach ($expected in $ExpectedColumns) {
        $matches = @($actual | Where-Object { $_.ColumnName -ceq [string] $expected.Name })
        Assert-Condition -Condition ($matches.Count -eq 1) -Message ("{0}.{1} was not found exactly once." -f $QualifiedTable, $expected.Name)
        $column = $matches[0]
        $actualType = [string] $column.DataType
        $allowedTypes = @([string] $expected.Type)
        if ($expected.Contains('AlternateType')) {
            $allowedTypes += [string] $expected.AlternateType
        }
        Assert-Condition -Condition ($allowedTypes -contains $actualType) -Message ("{0}.{1} type is {2}; expected {3}." -f $QualifiedTable, $expected.Name, $actualType, ($allowedTypes -join '/'))
        Assert-Condition -Condition ([bool] $column.IsNullable -eq [bool] $expected.Nullable) -Message ("{0}.{1} nullability differs from the EF migration." -f $QualifiedTable, $expected.Name)
        Assert-Condition -Condition (-not [bool] $column.IsIdentity) -Message ("{0}.{1} unexpectedly became an identity column." -f $QualifiedTable, $expected.Name)
        Assert-Condition -Condition (-not [bool] $column.IsComputed) -Message ("{0}.{1} unexpectedly became a computed column." -f $QualifiedTable, $expected.Name)
        if ($expected.Contains('MaxLength')) {
            Assert-Condition -Condition ([int] $column.LogicalMaxLength -eq [int] $expected.MaxLength) -Message ("{0}.{1} maximum length is {2}; expected {3}." -f $QualifiedTable, $expected.Name, $column.LogicalMaxLength, $expected.MaxLength)
        }
    }
    return $actual
}

function Get-KeyRows {
    param([Parameter(Mandatory = $true)][string] $QualifiedTable)

    return @(Invoke-SqlQuery -Sql @'
SELECT
    kc.name AS ConstraintName,
    kc.type_desc AS ConstraintType,
    ic.key_ordinal AS ColumnOrder,
    c.name AS ColumnName
FROM sys.key_constraints AS kc
INNER JOIN sys.index_columns AS ic
    ON ic.object_id = kc.parent_object_id
   AND ic.index_id = kc.unique_index_id
   AND ic.key_ordinal > 0
INNER JOIN sys.columns AS c
    ON c.object_id = ic.object_id
   AND c.column_id = ic.column_id
WHERE kc.parent_object_id = OBJECT_ID(@QualifiedTable, N'U')
ORDER BY kc.name, ic.key_ordinal;
'@ -Parameters @(
        (New-SqlParameterSpec -Name '@QualifiedTable' -Type NVarChar -Value $QualifiedTable -Size 260)
    ))
}

function Assert-Keys {
    param(
        [Parameter(Mandatory = $true)][string] $QualifiedTable,
        [Parameter(Mandatory = $true)][object[]] $ExpectedKeys,
        [switch] $AllowAdditional
    )

    $rows = @(Get-KeyRows -QualifiedTable $QualifiedTable)
    $groups = @($rows | Group-Object ConstraintName)
    if (-not $AllowAdditional) {
        Assert-ExactSet -Name ("{0} keys" -f $QualifiedTable) -Expected @($ExpectedKeys | ForEach-Object { [string] $_.Name }) -Actual @($groups | ForEach-Object { [string] $_.Name })
    }
    foreach ($expected in $ExpectedKeys) {
        $group = @($groups | Where-Object { $_.Name -ceq [string] $expected.Name })
        Assert-Condition -Condition ($group.Count -eq 1) -Message ("Key {0} was not found on {1}." -f $expected.Name, $QualifiedTable)
        $orderedRows = @($group[0].Group | Sort-Object ColumnOrder)
        $actualColumns = @($orderedRows | ForEach-Object { [string] $_.ColumnName }) -join ','
        Assert-Condition -Condition ($actualColumns -ceq [string] $expected.Columns) -Message ("Key {0} columns are {1}; expected {2}." -f $expected.Name, $actualColumns, $expected.Columns)
        Assert-Condition -Condition ([string] $orderedRows[0].ConstraintType -ceq [string] $expected.Type) -Message ("Key {0} type differs from the EF migration." -f $expected.Name)
    }
    return $rows
}

function Get-ForeignKeyRows {
    param([Parameter(Mandatory = $true)][string] $QualifiedTable)

    return @(Invoke-SqlQuery -Sql @'
SELECT
    fk.name AS ConstraintName,
    fkc.constraint_column_id AS ColumnOrder,
    pc.name AS ParentColumn,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS ReferencedSchema,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    rc.name AS ReferencedColumn,
    fk.delete_referential_action_desc AS DeleteAction,
    fk.is_disabled AS IsDisabled,
    fk.is_not_trusted AS IsNotTrusted
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc ON fkc.constraint_object_id = fk.object_id
INNER JOIN sys.columns AS pc
    ON pc.object_id = fk.parent_object_id
   AND pc.column_id = fkc.parent_column_id
INNER JOIN sys.columns AS rc
    ON rc.object_id = fk.referenced_object_id
   AND rc.column_id = fkc.referenced_column_id
WHERE fk.parent_object_id = OBJECT_ID(@QualifiedTable, N'U')
ORDER BY fk.name, fkc.constraint_column_id;
'@ -Parameters @(
        (New-SqlParameterSpec -Name '@QualifiedTable' -Type NVarChar -Value $QualifiedTable -Size 260)
    ))
}

function Assert-ForeignKeys {
    param(
        [Parameter(Mandatory = $true)][string] $QualifiedTable,
        [Parameter(Mandatory = $true)][object[]] $ExpectedForeignKeys
    )

    $rows = @(Get-ForeignKeyRows -QualifiedTable $QualifiedTable)
    $groups = @($rows | Group-Object ConstraintName)
    Assert-ExactSet -Name ("{0} foreign keys" -f $QualifiedTable) -Expected @($ExpectedForeignKeys | ForEach-Object { [string] $_.Name }) -Actual @($groups | ForEach-Object { [string] $_.Name })
    foreach ($expected in $ExpectedForeignKeys) {
        $group = @($groups | Where-Object { $_.Name -ceq [string] $expected.Name })
        Assert-Condition -Condition ($group.Count -eq 1) -Message ("Foreign key {0} was not found." -f $expected.Name)
        $orderedRows = @($group[0].Group | Sort-Object ColumnOrder)
        Assert-Condition -Condition ((@($orderedRows | ForEach-Object { [string] $_.ParentColumn }) -join ',') -ceq [string] $expected.ParentColumns) -Message ("Foreign key {0} parent columns differ." -f $expected.Name)
        Assert-Condition -Condition ((@($orderedRows | ForEach-Object { [string] $_.ReferencedColumn }) -join ',') -ceq [string] $expected.ReferencedColumns) -Message ("Foreign key {0} referenced columns differ." -f $expected.Name)
        Assert-Condition -Condition (("{0}.{1}" -f $orderedRows[0].ReferencedSchema, $orderedRows[0].ReferencedTable) -ceq [string] $expected.ReferencedTable) -Message ("Foreign key {0} referenced table differs." -f $expected.Name)
        Assert-Condition -Condition ([string] $orderedRows[0].DeleteAction -ceq 'NO_ACTION') -Message ("Foreign key {0} is not restrictive." -f $expected.Name)
        Assert-Condition -Condition (-not [bool] $orderedRows[0].IsDisabled) -Message ("Foreign key {0} is disabled." -f $expected.Name)
        Assert-Condition -Condition (-not [bool] $orderedRows[0].IsNotTrusted) -Message ("Foreign key {0} is not trusted." -f $expected.Name)
    }
    return $rows
}

function Get-CheckConstraints {
    param([Parameter(Mandatory = $true)][string] $QualifiedTable)

    return @(Invoke-SqlQuery -Sql @'
SELECT
    cc.name AS ConstraintName,
    cc.definition AS Definition,
    cc.is_disabled AS IsDisabled,
    cc.is_not_trusted AS IsNotTrusted
FROM sys.check_constraints AS cc
WHERE cc.parent_object_id = OBJECT_ID(@QualifiedTable, N'U')
ORDER BY cc.name;
'@ -Parameters @(
        (New-SqlParameterSpec -Name '@QualifiedTable' -Type NVarChar -Value $QualifiedTable -Size 260)
    ))
}

function Assert-CheckConstraints {
    param(
        [Parameter(Mandatory = $true)][string] $QualifiedTable,
        [Parameter(Mandatory = $true)][string[]] $ExpectedNames
    )

    $rows = @(Get-CheckConstraints -QualifiedTable $QualifiedTable)
    Assert-ExactSet -Name ("{0} check constraints" -f $QualifiedTable) -Expected $ExpectedNames -Actual @($rows | ForEach-Object { [string] $_.ConstraintName })
    foreach ($row in $rows) {
        Assert-Condition -Condition (-not [bool] $row.IsDisabled) -Message ("Check constraint {0} is disabled." -f $row.ConstraintName)
        Assert-Condition -Condition (-not [bool] $row.IsNotTrusted) -Message ("Check constraint {0} is not trusted." -f $row.ConstraintName)
        Assert-Condition -Condition (-not [string]::IsNullOrWhiteSpace([string] $row.Definition)) -Message ("Check constraint {0} has no definition." -f $row.ConstraintName)
    }
    return $rows
}

function Get-IndexRows {
    param([Parameter(Mandatory = $true)][string] $QualifiedTable)

    return @(Invoke-SqlQuery -Sql @'
SELECT
    i.name AS IndexName,
    i.is_unique AS IsUnique,
    i.has_filter AS HasFilter,
    i.filter_definition AS FilterDefinition,
    ic.key_ordinal AS ColumnOrder,
    c.name AS ColumnName
FROM sys.indexes AS i
INNER JOIN sys.index_columns AS ic
    ON ic.object_id = i.object_id
   AND ic.index_id = i.index_id
   AND ic.key_ordinal > 0
INNER JOIN sys.columns AS c
    ON c.object_id = ic.object_id
   AND c.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(@QualifiedTable, N'U')
  AND i.is_primary_key = 0
  AND i.is_unique_constraint = 0
  AND i.is_hypothetical = 0
ORDER BY i.name, ic.key_ordinal;
'@ -Parameters @(
        (New-SqlParameterSpec -Name '@QualifiedTable' -Type NVarChar -Value $QualifiedTable -Size 260)
    ))
}

function Normalize-FilterDefinition {
    param([AllowNull()][string] $Definition)
    if ($null -eq $Definition) { return '' }
    return [regex]::Replace($Definition, '[\s\(\)\[\]]', '').ToUpperInvariant()
}

function Assert-Indexes {
    param(
        [Parameter(Mandatory = $true)][string] $QualifiedTable,
        [Parameter(Mandatory = $true)][object[]] $ExpectedIndexes
    )

    $rows = @(Get-IndexRows -QualifiedTable $QualifiedTable)
    $groups = @($rows | Group-Object IndexName)
    Assert-ExactSet -Name ("{0} non-key indexes" -f $QualifiedTable) -Expected @($ExpectedIndexes | ForEach-Object { [string] $_.Name }) -Actual @($groups | ForEach-Object { [string] $_.Name })
    foreach ($expected in $ExpectedIndexes) {
        $group = @($groups | Where-Object { $_.Name -ceq [string] $expected.Name })
        Assert-Condition -Condition ($group.Count -eq 1) -Message ("Index {0} was not found." -f $expected.Name)
        $orderedRows = @($group[0].Group | Sort-Object ColumnOrder)
        Assert-Condition -Condition ((@($orderedRows | ForEach-Object { [string] $_.ColumnName }) -join ',') -ceq [string] $expected.Columns) -Message ("Index {0} columns differ." -f $expected.Name)
        Assert-Condition -Condition ([bool] $orderedRows[0].IsUnique -eq [bool] $expected.Unique) -Message ("Index {0} uniqueness differs." -f $expected.Name)
        $expectedFilter = [string] $expected.Filter
        if ([string]::IsNullOrWhiteSpace($expectedFilter)) {
            Assert-Condition -Condition (-not [bool] $orderedRows[0].HasFilter) -Message ("Index {0} unexpectedly has a filter." -f $expected.Name)
        }
        else {
            Assert-Condition -Condition ([bool] $orderedRows[0].HasFilter) -Message ("Index {0} is missing its required filter." -f $expected.Name)
            Assert-Condition -Condition ((Normalize-FilterDefinition -Definition ([string] $orderedRows[0].FilterDefinition)) -ceq (Normalize-FilterDefinition -Definition $expectedFilter)) -Message ("Index {0} filter differs from the EF migration." -f $expected.Name)
        }
    }
    return $rows
}

function Assert-Schema {
    param([Parameter(Mandatory = $true)][string] $Phase)

    $instanceColumns = @(
        [ordered]@{ Name = 'Id'; Type = 'uniqueidentifier'; Nullable = $false },
        [ordered]@{ Name = 'CustomerId'; Type = 'uniqueidentifier'; Nullable = $false },
        [ordered]@{ Name = 'ProjectId'; Type = 'uniqueidentifier'; Nullable = $false },
        [ordered]@{ Name = 'ServerId'; Type = 'uniqueidentifier'; Nullable = $false },
        [ordered]@{ Name = 'InstanceName'; Type = 'nvarchar'; Nullable = $false; MaxLength = 128 },
        [ordered]@{ Name = 'NormalizedInstanceName'; Type = 'nvarchar'; Nullable = $false; MaxLength = 128 },
        [ordered]@{ Name = 'SqlVersion'; Type = 'nvarchar'; Nullable = $false; MaxLength = 100 },
        [ordered]@{ Name = 'Edition'; Type = 'nvarchar'; Nullable = $false; MaxLength = 100 },
        [ordered]@{ Name = 'Port'; Type = 'int'; Nullable = $true },
        [ordered]@{ Name = 'ServiceStatus'; Type = 'nvarchar'; Nullable = $false; MaxLength = 50 },
        [ordered]@{ Name = 'DiscoverySource'; Type = 'nvarchar'; Nullable = $false; MaxLength = 100 },
        [ordered]@{ Name = 'ServiceAccountName'; Type = 'nvarchar'; Nullable = $true; MaxLength = 256 },
        [ordered]@{ Name = 'LastDiscoveredAt'; Type = 'datetimeoffset'; Nullable = $true },
        [ordered]@{ Name = 'LastImportBatchId'; Type = 'uniqueidentifier'; Nullable = $true },
        [ordered]@{ Name = 'LastImportedAt'; Type = 'datetimeoffset'; Nullable = $true },
        [ordered]@{ Name = 'CreatedAt'; Type = 'datetimeoffset'; Nullable = $false },
        [ordered]@{ Name = 'UpdatedAt'; Type = 'datetimeoffset'; Nullable = $false },
        [ordered]@{ Name = 'CreatedBy'; Type = 'nvarchar'; Nullable = $false; MaxLength = 200 },
        [ordered]@{ Name = 'UpdatedBy'; Type = 'nvarchar'; Nullable = $false; MaxLength = 200 },
        [ordered]@{ Name = 'IsDeleted'; Type = 'bit'; Nullable = $false },
        [ordered]@{ Name = 'DeletedAt'; Type = 'datetimeoffset'; Nullable = $true },
        [ordered]@{ Name = 'DeletedBy'; Type = 'nvarchar'; Nullable = $true; MaxLength = 200 },
        [ordered]@{ Name = 'RowVersion'; Type = 'timestamp'; AlternateType = 'rowversion'; Nullable = $false }
    )
    $databaseColumns = @(
        [ordered]@{ Name = 'Id'; Type = 'uniqueidentifier'; Nullable = $false },
        [ordered]@{ Name = 'CustomerId'; Type = 'uniqueidentifier'; Nullable = $false },
        [ordered]@{ Name = 'ProjectId'; Type = 'uniqueidentifier'; Nullable = $false },
        [ordered]@{ Name = 'SqlInstanceId'; Type = 'uniqueidentifier'; Nullable = $false },
        [ordered]@{ Name = 'Name'; Type = 'nvarchar'; Nullable = $false; MaxLength = 128 },
        [ordered]@{ Name = 'NormalizedName'; Type = 'nvarchar'; Nullable = $false; MaxLength = 128 },
        [ordered]@{ Name = 'SizeMb'; Type = 'bigint'; Nullable = $false },
        [ordered]@{ Name = 'CompatibilityLevel'; Type = 'int'; Nullable = $false },
        [ordered]@{ Name = 'RecoveryModel'; Type = 'nvarchar'; Nullable = $false; MaxLength = 30 },
        [ordered]@{ Name = 'Collation'; Type = 'nvarchar'; Nullable = $true; MaxLength = 128 },
        [ordered]@{ Name = 'Status'; Type = 'nvarchar'; Nullable = $false; MaxLength = 50 },
        [ordered]@{ Name = 'LastImportBatchId'; Type = 'uniqueidentifier'; Nullable = $true },
        [ordered]@{ Name = 'LastImportedAt'; Type = 'datetimeoffset'; Nullable = $true },
        [ordered]@{ Name = 'CreatedAt'; Type = 'datetimeoffset'; Nullable = $false },
        [ordered]@{ Name = 'UpdatedAt'; Type = 'datetimeoffset'; Nullable = $false },
        [ordered]@{ Name = 'CreatedBy'; Type = 'nvarchar'; Nullable = $false; MaxLength = 200 },
        [ordered]@{ Name = 'UpdatedBy'; Type = 'nvarchar'; Nullable = $false; MaxLength = 200 },
        [ordered]@{ Name = 'IsDeleted'; Type = 'bit'; Nullable = $false },
        [ordered]@{ Name = 'DeletedAt'; Type = 'datetimeoffset'; Nullable = $true },
        [ordered]@{ Name = 'DeletedBy'; Type = 'nvarchar'; Nullable = $true; MaxLength = 200 },
        [ordered]@{ Name = 'RowVersion'; Type = 'timestamp'; AlternateType = 'rowversion'; Nullable = $false }
    )
    $instanceKeys = @(
        [ordered]@{ Name = 'PK_SqlInstances'; Type = 'PRIMARY_KEY_CONSTRAINT'; Columns = 'Id' },
        [ordered]@{ Name = 'AK_SqlInstances_CustomerId_ProjectId_Id'; Type = 'UNIQUE_CONSTRAINT'; Columns = 'CustomerId,ProjectId,Id' }
    )
    $databaseKeys = @(
        [ordered]@{ Name = 'PK_SqlDatabases'; Type = 'PRIMARY_KEY_CONSTRAINT'; Columns = 'Id' },
        [ordered]@{ Name = 'AK_SqlDatabases_CustomerId_ProjectId_Id'; Type = 'UNIQUE_CONSTRAINT'; Columns = 'CustomerId,ProjectId,Id' }
    )
    $instanceForeignKeys = @(
        [ordered]@{ Name = 'FK_SqlInstances_ImportBatches_CustomerId_ProjectId_LastImportBatchId'; ParentColumns = 'CustomerId,ProjectId,LastImportBatchId'; ReferencedTable = 'dbo.ImportBatches'; ReferencedColumns = 'CustomerId,ProjectId,Id' },
        [ordered]@{ Name = 'FK_SqlInstances_Projects_CustomerId_ProjectId'; ParentColumns = 'CustomerId,ProjectId'; ReferencedTable = 'dbo.Projects'; ReferencedColumns = 'CustomerId,Id' },
        [ordered]@{ Name = 'FK_SqlInstances_Servers_CustomerId_ProjectId_ServerId'; ParentColumns = 'CustomerId,ProjectId,ServerId'; ReferencedTable = 'dbo.Servers'; ReferencedColumns = 'CustomerId,ProjectId,Id' }
    )
    $databaseForeignKeys = @(
        [ordered]@{ Name = 'FK_SqlDatabases_ImportBatches_CustomerId_ProjectId_LastImportBatchId'; ParentColumns = 'CustomerId,ProjectId,LastImportBatchId'; ReferencedTable = 'dbo.ImportBatches'; ReferencedColumns = 'CustomerId,ProjectId,Id' },
        [ordered]@{ Name = 'FK_SqlDatabases_Projects_CustomerId_ProjectId'; ParentColumns = 'CustomerId,ProjectId'; ReferencedTable = 'dbo.Projects'; ReferencedColumns = 'CustomerId,Id' },
        [ordered]@{ Name = 'FK_SqlDatabases_SqlInstances_CustomerId_ProjectId_SqlInstanceId'; ParentColumns = 'CustomerId,ProjectId,SqlInstanceId'; ReferencedTable = 'dbo.SqlInstances'; ReferencedColumns = 'CustomerId,ProjectId,Id' }
    )
    $instanceIndexes = @(
        [ordered]@{ Name = 'IX_SqlInstances_CustomerId_ProjectId_LastImportBatchId'; Columns = 'CustomerId,ProjectId,LastImportBatchId'; Unique = $false; Filter = $null },
        [ordered]@{ Name = 'IX_SqlInstances_Owner_Active_Name'; Columns = 'CustomerId,ProjectId,IsDeleted,NormalizedInstanceName'; Unique = $false; Filter = $null },
        [ordered]@{ Name = 'IX_SqlInstances_Owner_Active_ServiceStatus'; Columns = 'CustomerId,ProjectId,IsDeleted,ServiceStatus'; Unique = $false; Filter = $null },
        [ordered]@{ Name = 'UX_SqlInstances_Owner_Server_NormalizedName_Active'; Columns = 'CustomerId,ProjectId,ServerId,NormalizedInstanceName'; Unique = $true; Filter = '[IsDeleted] = 0' }
    )
    $databaseIndexes = @(
        [ordered]@{ Name = 'IX_SqlDatabases_CustomerId_ProjectId_LastImportBatchId'; Columns = 'CustomerId,ProjectId,LastImportBatchId'; Unique = $false; Filter = $null },
        [ordered]@{ Name = 'IX_SqlDatabases_Owner_Active_Name'; Columns = 'CustomerId,ProjectId,IsDeleted,NormalizedName'; Unique = $false; Filter = $null },
        [ordered]@{ Name = 'IX_SqlDatabases_Owner_Active_Status'; Columns = 'CustomerId,ProjectId,IsDeleted,Status'; Unique = $false; Filter = $null },
        [ordered]@{ Name = 'UX_SqlDatabases_Owner_Instance_NormalizedName_Active'; Columns = 'CustomerId,ProjectId,SqlInstanceId,NormalizedName'; Unique = $true; Filter = '[IsDeleted] = 0' }
    )

    $inspection = [ordered]@{
        phase = $Phase
        inspectedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
        sqlInstances = [ordered]@{
            columns = @(Assert-Columns -QualifiedTable 'dbo.SqlInstances' -ExpectedColumns $instanceColumns)
            keys = @(Assert-Keys -QualifiedTable 'dbo.SqlInstances' -ExpectedKeys $instanceKeys)
            foreignKeys = @(Assert-ForeignKeys -QualifiedTable 'dbo.SqlInstances' -ExpectedForeignKeys $instanceForeignKeys)
            checkConstraints = @(Assert-CheckConstraints -QualifiedTable 'dbo.SqlInstances' -ExpectedNames @('CK_SqlInstances_Port'))
            indexes = @(Assert-Indexes -QualifiedTable 'dbo.SqlInstances' -ExpectedIndexes $instanceIndexes)
        }
        sqlDatabases = [ordered]@{
            columns = @(Assert-Columns -QualifiedTable 'dbo.SqlDatabases' -ExpectedColumns $databaseColumns)
            keys = @(Assert-Keys -QualifiedTable 'dbo.SqlDatabases' -ExpectedKeys $databaseKeys)
            foreignKeys = @(Assert-ForeignKeys -QualifiedTable 'dbo.SqlDatabases' -ExpectedForeignKeys $databaseForeignKeys)
            checkConstraints = @(Assert-CheckConstraints -QualifiedTable 'dbo.SqlDatabases' -ExpectedNames @('CK_SqlDatabases_CompatibilityLevel', 'CK_SqlDatabases_SizeMb'))
            indexes = @(Assert-Indexes -QualifiedTable 'dbo.SqlDatabases' -ExpectedIndexes $databaseIndexes)
        }
        parentAlternateKeys = [ordered]@{
            projects = @(Assert-Keys -QualifiedTable 'dbo.Projects' -ExpectedKeys @([ordered]@{ Name = 'AK_Projects_CustomerId_Id'; Type = 'UNIQUE_CONSTRAINT'; Columns = 'CustomerId,Id' }) -AllowAdditional)
            servers = @(Assert-Keys -QualifiedTable 'dbo.Servers' -ExpectedKeys @([ordered]@{ Name = 'AK_Servers_CustomerId_ProjectId_Id'; Type = 'UNIQUE_CONSTRAINT'; Columns = 'CustomerId,ProjectId,Id' }) -AllowAdditional)
            importBatches = @(Assert-Keys -QualifiedTable 'dbo.ImportBatches' -ExpectedKeys @([ordered]@{ Name = 'AK_ImportBatches_CustomerId_ProjectId_Id'; Type = 'UNIQUE_CONSTRAINT'; Columns = 'CustomerId,ProjectId,Id' }) -AllowAdditional)
        }
        auditColumns = @()
    }

    $auditColumns = @(Get-TableColumns -QualifiedTable 'dbo.AuditEvents' | Where-Object { $_.ColumnName -in @('CorrelationId', 'ActorPrincipalType') })
    Assert-ExactSet -Name 'dbo.AuditEvents Phase 3 columns' -Expected @('CorrelationId', 'ActorPrincipalType') -Actual @($auditColumns | ForEach-Object { [string] $_.ColumnName })
    foreach ($column in $auditColumns) {
        $expectedLength = if ($column.ColumnName -ceq 'CorrelationId') { 100 } else { 20 }
        Assert-Condition -Condition ([string] $column.DataType -ceq 'nvarchar') -Message ("AuditEvents.{0} is not nvarchar." -f $column.ColumnName)
        Assert-Condition -Condition ([bool] $column.IsNullable) -Message ("AuditEvents.{0} is unexpectedly non-nullable." -f $column.ColumnName)
        Assert-Condition -Condition ([int] $column.LogicalMaxLength -eq $expectedLength) -Message ("AuditEvents.{0} maximum length differs." -f $column.ColumnName)
    }
    $inspection.auditColumns = $auditColumns
    $null = $SchemaInspections.Add($inspection)
    Write-Evidence -Status PASS -Message ("{0}: exact Phase 3 tables, columns, keys, foreign keys, check constraints and indexes match the EF migration." -f $Phase)
    return $inspection
}

function ConvertTo-ApprovedInstanceName {
    param([Parameter(Mandatory = $true)][string] $Value)
    $display = $Value.Trim().Normalize([Text.NormalizationForm]::FormC)
    if ($display.Length -eq 0 -or $display.Length -gt 128) {
        Throw-Fail -Message 'Harness supplied an invalid deterministic instance display name.'
    }
    $normalized = $display.ToUpperInvariant()
    if ($normalized -in @('DEFAULT', '(DEFAULT)', 'MSSQLSERVER')) {
        return 'MSSQLSERVER'
    }
    return $normalized
}

function ConvertTo-ApprovedDatabaseName {
    param([Parameter(Mandatory = $true)][string] $Value)
    $display = $Value.Trim().Normalize([Text.NormalizationForm]::FormC)
    if ($display.Length -eq 0 -or $display.Length -gt 128) {
        Throw-Fail -Message 'Harness supplied an invalid deterministic database display name.'
    }
    return $display.ToUpperInvariant()
}

function Get-UnicodeCodePoints {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Value
    )

    return (($Value.ToCharArray() | ForEach-Object { 'U+{0:X4}' -f [int] $_ }) -join ' ')
}

function New-UnicodeFormCFixture {
    return [ordered]@{
        composed = "Caf$([char] 0x00E9)"
        decomposed = "Caf$([char] 0x0065)$([char] 0x0301)"
    }
}

function Assert-UnicodeFormCFixture {
    $fixture = New-UnicodeFormCFixture
    $composed = [string] $fixture.composed
    $decomposed = [string] $fixture.decomposed
    $composedBeforeCodePoints = Get-UnicodeCodePoints -Value $composed
    $decomposedBeforeCodePoints = Get-UnicodeCodePoints -Value $decomposed

    Assert-Condition -Condition ($composedBeforeCodePoints -ceq 'U+0043 U+0061 U+0066 U+00E9') -Message 'Composed Unicode fixture does not contain exact code point U+00E9.'
    Assert-Condition -Condition ($decomposedBeforeCodePoints -ceq 'U+0043 U+0061 U+0066 U+0065 U+0301') -Message 'Decomposed Unicode fixture does not contain exact code points U+0065 U+0301.'
    Assert-Condition -Condition (-not [string]::Equals($composed, $decomposed, [StringComparison]::Ordinal)) -Message 'Unicode fixtures must be ordinally different before Form C normalization.'

    $composedFormC = $composed.Normalize([Text.NormalizationForm]::FormC)
    $decomposedFormC = $decomposed.Normalize([Text.NormalizationForm]::FormC)
    $composedAfterFormCCodePoints = Get-UnicodeCodePoints -Value $composedFormC
    $decomposedAfterFormCCodePoints = Get-UnicodeCodePoints -Value $decomposedFormC
    Assert-Condition -Condition ([string]::Equals($composedFormC, $decomposedFormC, [StringComparison]::Ordinal)) -Message 'Unicode fixture smoke test did not converge after Form C normalization.'
    Assert-Condition -Condition ($composedAfterFormCCodePoints -ceq 'U+0043 U+0061 U+0066 U+00E9') -Message 'Composed Unicode fixture changed unexpectedly after Form C normalization.'
    Assert-Condition -Condition ($decomposedAfterFormCCodePoints -ceq 'U+0043 U+0061 U+0066 U+00E9') -Message 'Decomposed Unicode fixture did not compose to exact code point U+00E9.'

    $composedApproved = ConvertTo-ApprovedDatabaseName -Value $composed
    $decomposedApproved = ConvertTo-ApprovedDatabaseName -Value $decomposed
    $composedApprovedCodePoints = Get-UnicodeCodePoints -Value $composedApproved
    $decomposedApprovedCodePoints = Get-UnicodeCodePoints -Value $decomposedApproved
    Assert-Condition -Condition ([string]::Equals($composedApproved, $decomposedApproved, [StringComparison]::Ordinal)) -Message 'Approved Unicode normalization did not converge in the no-SQL smoke test.'
    Assert-Condition -Condition ($composedApprovedCodePoints -ceq 'U+0043 U+0041 U+0046 U+00C9') -Message 'Approved composed normalization code points differ from the contract.'
    Assert-Condition -Condition ($decomposedApprovedCodePoints -ceq 'U+0043 U+0041 U+0046 U+00C9') -Message 'Approved decomposed normalization code points differ from the contract.'

    $evidence = [ordered]@{
        composedBeforeCodePoints = $composedBeforeCodePoints
        decomposedBeforeCodePoints = $decomposedBeforeCodePoints
        initiallyOrdinallyDifferent = $true
        composedAfterFormCCodePoints = $composedAfterFormCCodePoints
        decomposedAfterFormCCodePoints = $decomposedAfterFormCCodePoints
        formCConverged = $true
        composedAfterApprovedNormalizationCodePoints = $composedApprovedCodePoints
        decomposedAfterApprovedNormalizationCodePoints = $decomposedApprovedCodePoints
        approvedNormalizationConverged = $true
    }
    Add-Step -Name 'Unicode Form C fixture smoke test' -Outcome PASS -Detail 'Without SQL access, the exact composed/decomposed fixtures were initially different and converged after Form C normalization.' -Evidence $evidence
    return $evidence
}

$InstanceInsertSql = @'
INSERT INTO [dbo].[SqlInstances]
(
    [Id], [CustomerId], [ProjectId], [ServerId], [InstanceName], [NormalizedInstanceName],
    [SqlVersion], [Edition], [Port], [ServiceStatus], [DiscoverySource], [ServiceAccountName],
    [LastDiscoveredAt], [LastImportBatchId], [LastImportedAt], [CreatedAt], [UpdatedAt],
    [CreatedBy], [UpdatedBy], [IsDeleted], [DeletedAt], [DeletedBy]
)
VALUES
(
    @Id, @CustomerId, @ProjectId, @ServerId, @InstanceName, @NormalizedInstanceName,
    @SqlVersion, @Edition, @Port, @ServiceStatus, @DiscoverySource, NULL,
    NULL, NULL, NULL, @CreatedAt, @UpdatedAt, @Actor, @Actor, 0, NULL, NULL
);
'@

$DatabaseInsertSql = @'
INSERT INTO [dbo].[SqlDatabases]
(
    [Id], [CustomerId], [ProjectId], [SqlInstanceId], [Name], [NormalizedName],
    [SizeMb], [CompatibilityLevel], [RecoveryModel], [Collation], [Status],
    [LastImportBatchId], [LastImportedAt], [CreatedAt], [UpdatedAt], [CreatedBy],
    [UpdatedBy], [IsDeleted], [DeletedAt], [DeletedBy]
)
VALUES
(
    @Id, @CustomerId, @ProjectId, @SqlInstanceId, @Name, @NormalizedName,
    @SizeMb, @CompatibilityLevel, @RecoveryModel, @Collation, @Status,
    NULL, NULL, @CreatedAt, @UpdatedAt, @Actor, @Actor, 0, NULL, NULL
);
'@

function Get-InstanceParameters {
    param(
        [Parameter(Mandatory = $true)][guid] $Id,
        [Parameter(Mandatory = $true)][guid] $CustomerId,
        [Parameter(Mandatory = $true)][guid] $ProjectId,
        [Parameter(Mandatory = $true)][guid] $ServerId,
        [Parameter(Mandatory = $true)][string] $InstanceName,
        [AllowNull()][object] $Port = 1433
    )

    $normalized = ConvertTo-ApprovedInstanceName -Value $InstanceName
    return @(
        (New-SqlParameterSpec -Name '@Id' -Type UniqueIdentifier -Value $Id),
        (New-SqlParameterSpec -Name '@CustomerId' -Type UniqueIdentifier -Value $CustomerId),
        (New-SqlParameterSpec -Name '@ProjectId' -Type UniqueIdentifier -Value $ProjectId),
        (New-SqlParameterSpec -Name '@ServerId' -Type UniqueIdentifier -Value $ServerId),
        (New-SqlParameterSpec -Name '@InstanceName' -Type NVarChar -Value $InstanceName -Size 128),
        (New-SqlParameterSpec -Name '@NormalizedInstanceName' -Type NVarChar -Value $normalized -Size 128),
        (New-SqlParameterSpec -Name '@SqlVersion' -Type NVarChar -Value '16.0.1000.6' -Size 100),
        (New-SqlParameterSpec -Name '@Edition' -Type NVarChar -Value 'Synthetic Express' -Size 100),
        (New-SqlParameterSpec -Name '@Port' -Type Int -Value $Port),
        (New-SqlParameterSpec -Name '@ServiceStatus' -Type NVarChar -Value 'Running' -Size 50),
        (New-SqlParameterSpec -Name '@DiscoverySource' -Type NVarChar -Value 'PH3-SQL-001-Assurance' -Size 100),
        (New-SqlParameterSpec -Name '@CreatedAt' -Type DateTimeOffset -Value ([DateTimeOffset]::Parse('2026-09-11T12:00:00+00:00'))),
        (New-SqlParameterSpec -Name '@UpdatedAt' -Type DateTimeOffset -Value ([DateTimeOffset]::Parse('2026-09-11T12:00:00+00:00'))),
        (New-SqlParameterSpec -Name '@Actor' -Type NVarChar -Value 'synthetic-ph3-sql-tester' -Size 200)
    )
}

function Get-DatabaseParameters {
    param(
        [Parameter(Mandatory = $true)][guid] $Id,
        [Parameter(Mandatory = $true)][guid] $CustomerId,
        [Parameter(Mandatory = $true)][guid] $ProjectId,
        [Parameter(Mandatory = $true)][guid] $SqlInstanceId,
        [Parameter(Mandatory = $true)][string] $Name,
        [long] $SizeMb = 1024,
        [int] $CompatibilityLevel = 160
    )

    $normalized = ConvertTo-ApprovedDatabaseName -Value $Name
    return @(
        (New-SqlParameterSpec -Name '@Id' -Type UniqueIdentifier -Value $Id),
        (New-SqlParameterSpec -Name '@CustomerId' -Type UniqueIdentifier -Value $CustomerId),
        (New-SqlParameterSpec -Name '@ProjectId' -Type UniqueIdentifier -Value $ProjectId),
        (New-SqlParameterSpec -Name '@SqlInstanceId' -Type UniqueIdentifier -Value $SqlInstanceId),
        (New-SqlParameterSpec -Name '@Name' -Type NVarChar -Value $Name -Size 128),
        (New-SqlParameterSpec -Name '@NormalizedName' -Type NVarChar -Value $normalized -Size 128),
        (New-SqlParameterSpec -Name '@SizeMb' -Type BigInt -Value $SizeMb),
        (New-SqlParameterSpec -Name '@CompatibilityLevel' -Type Int -Value $CompatibilityLevel),
        (New-SqlParameterSpec -Name '@RecoveryModel' -Type NVarChar -Value 'Full' -Size 30),
        (New-SqlParameterSpec -Name '@Collation' -Type NVarChar -Value 'Synthetic-Collation-Metadata' -Size 128),
        (New-SqlParameterSpec -Name '@Status' -Type NVarChar -Value 'Online' -Size 50),
        (New-SqlParameterSpec -Name '@CreatedAt' -Type DateTimeOffset -Value ([DateTimeOffset]::Parse('2026-09-11T12:00:00+00:00'))),
        (New-SqlParameterSpec -Name '@UpdatedAt' -Type DateTimeOffset -Value ([DateTimeOffset]::Parse('2026-09-11T12:00:00+00:00'))),
        (New-SqlParameterSpec -Name '@Actor' -Type NVarChar -Value 'synthetic-ph3-sql-tester' -Size 200)
    )
}

function Assert-NormalizedProviderParameterPreservation {
    $command = New-Object System.Data.SqlClient.SqlCommand
    try {
        Add-SqlParameters -Command $command -Parameters (Get-InstanceParameters `
            -Id ([guid] '93000000-0000-0000-0000-000000009901') `
            -CustomerId ([guid] '93000000-0000-0000-0000-000000009902') `
            -ProjectId ([guid] '93000000-0000-0000-0000-000000009903') `
            -ServerId ([guid] '93000000-0000-0000-0000-000000009904') `
            -InstanceName 'default')

        $instanceParameter = $command.Parameters['@NormalizedInstanceName']
        Assert-Condition -Condition ($instanceParameter.SqlDbType -eq [System.Data.SqlDbType]::NVarChar) -Message 'Normalized SQL Instance provider parameter is not NVarChar.'
        Assert-Condition -Condition ($instanceParameter.Size -eq 128) -Message 'Normalized SQL Instance provider parameter size is not 128.'
        Assert-Condition -Condition ($instanceParameter.Value.GetType() -eq [string]) -Message 'Normalized SQL Instance provider parameter is not a String.'
        Assert-Condition -Condition ([string]::Equals([string] $instanceParameter.Value, 'MSSQLSERVER', [StringComparison]::Ordinal)) -Message 'Normalized SQL Instance provider parameter did not retain exact canonical MSSQLSERVER.'

        $command.Parameters.Clear()
        $unicodeFixture = New-UnicodeFormCFixture
        Add-SqlParameters -Command $command -Parameters (Get-DatabaseParameters `
            -Id ([guid] '93000000-0000-0000-0000-000000009905') `
            -CustomerId ([guid] '93000000-0000-0000-0000-000000009902') `
            -ProjectId ([guid] '93000000-0000-0000-0000-000000009903') `
            -SqlInstanceId ([guid] '93000000-0000-0000-0000-000000009906') `
            -Name ([string] $unicodeFixture.decomposed))

        $databaseParameter = $command.Parameters['@NormalizedName']
        Assert-Condition -Condition ($databaseParameter.SqlDbType -eq [System.Data.SqlDbType]::NVarChar) -Message 'Normalized SQL Database provider parameter is not NVarChar.'
        Assert-Condition -Condition ($databaseParameter.Size -eq 128) -Message 'Normalized SQL Database provider parameter size is not 128.'
        Assert-Condition -Condition ($databaseParameter.Value.GetType() -eq [string]) -Message 'Normalized SQL Database provider parameter is not a String.'
        Assert-Condition -Condition ((Get-UnicodeCodePoints -Value ([string] $databaseParameter.Value)) -ceq 'U+0043 U+0041 U+0046 U+00C9') -Message 'Normalized SQL Database provider parameter did not retain exact canonical Form C code points.'

        Add-Step -Name 'Normalized provider-parameter preservation smoke test' -Outcome PASS -Detail 'Without opening a SQL connection, canonical SQL Instance and Database normalized keys reached NVarChar(128) provider parameters as exact non-empty String values.'
    }
    finally {
        $command.Dispose()
    }
}

function Assert-NegativeFixtureIsolation {
    param([Parameter(Mandatory = $true)][hashtable] $Ids)

    $allIdentifierValues = @($Ids.Values | ForEach-Object { ([guid] $_).ToString('D') })
    $distinctIdentifierValues = @($allIdentifierValues | Sort-Object -Unique)
    Assert-Condition -Condition ($allIdentifierValues.Count -eq $distinctIdentifierValues.Count) -Message 'Synthetic fixture identifiers are not globally unique.'

    $singleConstraintInstanceNames = @(
        $FixtureNames.CrossCustomerInstanceAttempt,
        $FixtureNames.CrossProjectInstanceAttempt,
        $FixtureNames.PortBelowInstanceAttempt,
        $FixtureNames.PortAboveInstanceAttempt
    )
    $singleConstraintInstanceKeys = @($singleConstraintInstanceNames | ForEach-Object { ConvertTo-ApprovedInstanceName -Value $_ })
    Assert-Condition -Condition ($singleConstraintInstanceKeys.Count -eq @($singleConstraintInstanceKeys | Sort-Object -Unique).Count) -Message 'Single-constraint SQL Instance negative fixtures reuse a normalized name.'

    $singleConstraintDatabaseNames = @(
        $FixtureNames.CrossCustomerDatabaseAttempt,
        $FixtureNames.CrossProjectDatabaseAttempt,
        $FixtureNames.NegativeSizeDatabaseAttempt,
        $FixtureNames.CompatibilityLowDatabaseAttempt,
        $FixtureNames.CompatibilityHighDatabaseAttempt
    )
    $singleConstraintDatabaseKeys = @($singleConstraintDatabaseNames | ForEach-Object { ConvertTo-ApprovedDatabaseName -Value $_ })
    Assert-Condition -Condition ($singleConstraintDatabaseKeys.Count -eq @($singleConstraintDatabaseKeys | Sort-Object -Unique).Count) -Message 'Single-constraint SQL Database negative fixtures reuse a normalized name.'

    $negativeParentIds = @(
        $Ids.ServerCrossCustomerTarget,
        $Ids.ServerCrossProjectTarget,
        $Ids.ServerPortBelow,
        $Ids.ServerPortAbove,
        $Ids.InstanceCrossCustomerDatabaseParent,
        $Ids.InstanceCrossProjectDatabaseParent,
        $Ids.InstanceNegativeSizeDatabaseParent,
        $Ids.InstanceCompatibilityLowDatabaseParent,
        $Ids.InstanceCompatibilityHighDatabaseParent,
        $Ids.ServerInstanceDuplicate,
        $Ids.InstanceDatabaseDuplicateParent,
        $Ids.ServerAlias,
        $Ids.InstanceUnicodeDatabaseParent,
        $Ids.ServerConcurrent
    ) | ForEach-Object { ([guid] $_).ToString('D') }
    Assert-Condition -Condition ($negativeParentIds.Count -eq @($negativeParentIds | Sort-Object -Unique).Count) -Message 'Negative tests reuse a parent relationship outside their intentional collision pair.'

    Assert-Condition -Condition ((ConvertTo-ApprovedInstanceName -Value $FixtureNames.InstanceDuplicateBaseline) -ceq (ConvertTo-ApprovedInstanceName -Value $FixtureNames.InstanceDuplicateAttempt)) -Message 'SQL Instance uniqueness fixture does not isolate the intended normalized-name collision.'
    Assert-Condition -Condition ((ConvertTo-ApprovedDatabaseName -Value $FixtureNames.DatabaseDuplicateBaseline) -ceq (ConvertTo-ApprovedDatabaseName -Value $FixtureNames.DatabaseDuplicateAttempt)) -Message 'SQL Database uniqueness fixture does not isolate the intended normalized-name collision.'
    Assert-Condition -Condition ($FixtureNames.AliasInstanceBaseline -cne $FixtureNames.AliasInstanceAttempt) -Message 'DEFAULT alias fixture inputs must be ordinally distinct.'
    Assert-Condition -Condition ([string]::Equals($FixtureNames.AliasInstanceBaseline, $FixtureNames.AliasInstanceAttempt, [StringComparison]::OrdinalIgnoreCase)) -Message 'DEFAULT alias fixture inputs must differ only by case.'
    $aliasBaselineNormalized = ConvertTo-ApprovedInstanceName -Value $FixtureNames.AliasInstanceBaseline
    $aliasAttemptNormalized = ConvertTo-ApprovedInstanceName -Value $FixtureNames.AliasInstanceAttempt
    Assert-Condition -Condition ($aliasBaselineNormalized -ceq 'MSSQLSERVER') -Message 'DEFAULT alias baseline did not normalize to canonical MSSQLSERVER.'
    Assert-Condition -Condition ($aliasAttemptNormalized -ceq 'MSSQLSERVER') -Message 'default alias attempt did not normalize to canonical MSSQLSERVER.'
    Assert-Condition -Condition ($aliasBaselineNormalized -ceq $aliasAttemptNormalized) -Message 'DEFAULT/default alias fixture does not isolate the intended normalized-name collision.'

    return [ordered]@{
        globallyUniqueIdentifiers = $allIdentifierValues.Count
        singleConstraintInstanceNames = $singleConstraintInstanceKeys.Count
        singleConstraintDatabaseNames = $singleConstraintDatabaseKeys.Count
        dedicatedNegativeParents = $negativeParentIds.Count
        intentionalNormalizedCollisionPairs = 3
    }
}

function Seed-SyntheticParents {
    param(
        [Parameter(Mandatory = $true)][hashtable] $Ids
    )

    $timestamp = [DateTimeOffset]::Parse('2026-09-11T12:00:00+00:00')
    $customerSql = @'
INSERT INTO [dbo].[Customers] ([Id], [Name], [Code], [Status], [CreatedAt], [UpdatedAt])
VALUES (@Id, @Name, @Code, N'Active', @CreatedAt, @UpdatedAt);
'@
    $projectSql = @'
INSERT INTO [dbo].[Projects]
    ([Id], [CustomerId], [Name], [Description], [Status], [PlannedStartDate], [PlannedEndDate], [CreatedAt], [UpdatedAt])
VALUES
    (@Id, @CustomerId, @Name, N'Deterministic synthetic SQL assurance project', N'Active', NULL, NULL, @CreatedAt, @UpdatedAt);
'@
    $serverSql = @'
INSERT INTO [dbo].[Servers]
(
    [Id], [CustomerId], [ProjectId], [Hostname], [Environment], [OperatingSystem],
    [IpAddress], [VCores], [MemoryMb], [AllocatedStorageGb], [PowerStatus],
    [MigrationStatus], [CreatedAt], [UpdatedAt], [MigrationScope], [MigrationStrategy]
)
VALUES
(
    @Id, @CustomerId, @ProjectId, @Hostname, N'Test', N'Synthetic Windows',
    @IpAddress, 4, 8192, 256, N'Running', N'NotStarted', @CreatedAt,
    @UpdatedAt, N'AssessmentOnly', N'Undecided'
);
'@

    foreach ($customer in @(
        [ordered]@{ Id = $Ids.CustomerA; Name = 'Synthetic Assurance Customer A'; Code = 'PH3SQLSYNTHA' },
        [ordered]@{ Id = $Ids.CustomerB; Name = 'Synthetic Assurance Customer B'; Code = 'PH3SQLSYNTHB' }
    )) {
        $null = Invoke-SqlNonQuery -Sql $customerSql -Parameters @(
            (New-SqlParameterSpec -Name '@Id' -Type UniqueIdentifier -Value $customer.Id),
            (New-SqlParameterSpec -Name '@Name' -Type NVarChar -Value $customer.Name -Size 200),
            (New-SqlParameterSpec -Name '@Code' -Type NVarChar -Value $customer.Code -Size 50),
            (New-SqlParameterSpec -Name '@CreatedAt' -Type DateTimeOffset -Value $timestamp),
            (New-SqlParameterSpec -Name '@UpdatedAt' -Type DateTimeOffset -Value $timestamp)
        )
    }

    foreach ($project in @(
        [ordered]@{ Id = $Ids.ProjectA1; CustomerId = $Ids.CustomerA; Name = 'Synthetic Project A1' },
        [ordered]@{ Id = $Ids.ProjectA2; CustomerId = $Ids.CustomerA; Name = 'Synthetic Project A2' },
        [ordered]@{ Id = $Ids.ProjectB1; CustomerId = $Ids.CustomerB; Name = 'Synthetic Project B1' }
    )) {
        $null = Invoke-SqlNonQuery -Sql $projectSql -Parameters @(
            (New-SqlParameterSpec -Name '@Id' -Type UniqueIdentifier -Value $project.Id),
            (New-SqlParameterSpec -Name '@CustomerId' -Type UniqueIdentifier -Value $project.CustomerId),
            (New-SqlParameterSpec -Name '@Name' -Type NVarChar -Value $project.Name -Size 200),
            (New-SqlParameterSpec -Name '@CreatedAt' -Type DateTimeOffset -Value $timestamp),
            (New-SqlParameterSpec -Name '@UpdatedAt' -Type DateTimeOffset -Value $timestamp)
        )
    }

    foreach ($serverRecord in @(
        [ordered]@{ Id = $Ids.ServerA1; CustomerId = $Ids.CustomerA; ProjectId = $Ids.ProjectA1; Hostname = 'ph3-synth-a1-baseline'; IpAddress = '192.0.2.21' },
        [ordered]@{ Id = $Ids.ServerA2; CustomerId = $Ids.CustomerA; ProjectId = $Ids.ProjectA2; Hostname = 'ph3-synth-a2-baseline'; IpAddress = '192.0.2.22' },
        [ordered]@{ Id = $Ids.ServerB1; CustomerId = $Ids.CustomerB; ProjectId = $Ids.ProjectB1; Hostname = 'ph3-synth-b1-baseline'; IpAddress = '192.0.2.23' },
        [ordered]@{ Id = $Ids.ServerCrossCustomerTarget; CustomerId = $Ids.CustomerA; ProjectId = $Ids.ProjectA1; Hostname = 'ph3-synth-cross-customer-target'; IpAddress = '192.0.2.24' },
        [ordered]@{ Id = $Ids.ServerCrossProjectTarget; CustomerId = $Ids.CustomerA; ProjectId = $Ids.ProjectA1; Hostname = 'ph3-synth-cross-project-target'; IpAddress = '192.0.2.25' },
        [ordered]@{ Id = $Ids.ServerPortBelow; CustomerId = $Ids.CustomerA; ProjectId = $Ids.ProjectA1; Hostname = 'ph3-synth-port-below'; IpAddress = '192.0.2.26' },
        [ordered]@{ Id = $Ids.ServerPortAbove; CustomerId = $Ids.CustomerA; ProjectId = $Ids.ProjectA1; Hostname = 'ph3-synth-port-above'; IpAddress = '192.0.2.27' },
        [ordered]@{ Id = $Ids.ServerCrossCustomerDatabaseParent; CustomerId = $Ids.CustomerA; ProjectId = $Ids.ProjectA1; Hostname = 'ph3-synth-db-cross-customer'; IpAddress = '192.0.2.28' },
        [ordered]@{ Id = $Ids.ServerCrossProjectDatabaseParent; CustomerId = $Ids.CustomerA; ProjectId = $Ids.ProjectA1; Hostname = 'ph3-synth-db-cross-project'; IpAddress = '192.0.2.29' },
        [ordered]@{ Id = $Ids.ServerNegativeSizeDatabaseParent; CustomerId = $Ids.CustomerA; ProjectId = $Ids.ProjectA1; Hostname = 'ph3-synth-db-negative-size'; IpAddress = '192.0.2.30' },
        [ordered]@{ Id = $Ids.ServerCompatibilityLowDatabaseParent; CustomerId = $Ids.CustomerA; ProjectId = $Ids.ProjectA1; Hostname = 'ph3-synth-db-compat-low'; IpAddress = '192.0.2.31' },
        [ordered]@{ Id = $Ids.ServerCompatibilityHighDatabaseParent; CustomerId = $Ids.CustomerA; ProjectId = $Ids.ProjectA1; Hostname = 'ph3-synth-db-compat-high'; IpAddress = '192.0.2.32' },
        [ordered]@{ Id = $Ids.ServerInstanceDuplicate; CustomerId = $Ids.CustomerA; ProjectId = $Ids.ProjectA1; Hostname = 'ph3-synth-instance-duplicate'; IpAddress = '192.0.2.33' },
        [ordered]@{ Id = $Ids.ServerDatabaseDuplicateParent; CustomerId = $Ids.CustomerA; ProjectId = $Ids.ProjectA1; Hostname = 'ph3-synth-db-duplicate'; IpAddress = '192.0.2.34' },
        [ordered]@{ Id = $Ids.ServerUnicodeDatabaseParent; CustomerId = $Ids.CustomerA; ProjectId = $Ids.ProjectA2; Hostname = 'ph3-synth-db-unicode'; IpAddress = '192.0.2.35' },
        [ordered]@{ Id = $Ids.ServerConcurrent; CustomerId = $Ids.CustomerA; ProjectId = $Ids.ProjectA1; Hostname = 'ph3-synth-concurrent'; IpAddress = '192.0.2.36' },
        [ordered]@{ Id = $Ids.ServerAlias; CustomerId = $Ids.CustomerA; ProjectId = $Ids.ProjectA2; Hostname = 'ph3-synth-alias'; IpAddress = '192.0.2.37' }
    )) {
        $null = Invoke-SqlNonQuery -Sql $serverSql -Parameters @(
            (New-SqlParameterSpec -Name '@Id' -Type UniqueIdentifier -Value $serverRecord.Id),
            (New-SqlParameterSpec -Name '@CustomerId' -Type UniqueIdentifier -Value $serverRecord.CustomerId),
            (New-SqlParameterSpec -Name '@ProjectId' -Type UniqueIdentifier -Value $serverRecord.ProjectId),
            (New-SqlParameterSpec -Name '@Hostname' -Type NVarChar -Value $serverRecord.Hostname -Size 253),
            (New-SqlParameterSpec -Name '@IpAddress' -Type NVarChar -Value $serverRecord.IpAddress -Size 45),
            (New-SqlParameterSpec -Name '@CreatedAt' -Type DateTimeOffset -Value $timestamp),
            (New-SqlParameterSpec -Name '@UpdatedAt' -Type DateTimeOffset -Value $timestamp)
        )
    }
    Write-Evidence -Status PASS -Message 'Inserted deterministic synthetic customers, projects and servers only in the isolated database.'
}

function Invoke-ConstraintAndRelationshipTests {
    param([Parameter(Mandatory = $true)][hashtable] $Ids)

    $evidence = New-Object System.Collections.ArrayList
    $inserted = Invoke-SqlNonQuery -Sql $InstanceInsertSql -Parameters (Get-InstanceParameters -Id $Ids.InstanceA1 -CustomerId $Ids.CustomerA -ProjectId $Ids.ProjectA1 -ServerId $Ids.ServerA1 -InstanceName $FixtureNames.BaselineInstance)
    Assert-Condition -Condition ($inserted -eq 1) -Message 'Valid same-owner SQL Instance insert did not affect exactly one row.'
    $inserted = Invoke-SqlNonQuery -Sql $DatabaseInsertSql -Parameters (Get-DatabaseParameters -Id $Ids.DatabaseA1 -CustomerId $Ids.CustomerA -ProjectId $Ids.ProjectA1 -SqlInstanceId $Ids.InstanceA1 -Name $FixtureNames.BaselineDatabase)
    Assert-Condition -Condition ($inserted -eq 1) -Message 'Valid same-owner SQL Database insert did not affect exactly one row.'
    $relationshipCount = [int] (Invoke-SqlScalar -Sql @'
SELECT COUNT_BIG(*)
FROM [dbo].[Servers] AS s
INNER JOIN [dbo].[SqlInstances] AS i
    ON i.[CustomerId] = s.[CustomerId] AND i.[ProjectId] = s.[ProjectId] AND i.[ServerId] = s.[Id]
INNER JOIN [dbo].[SqlDatabases] AS d
    ON d.[CustomerId] = i.[CustomerId] AND d.[ProjectId] = i.[ProjectId] AND d.[SqlInstanceId] = i.[Id]
WHERE s.[CustomerId] = @CustomerId AND s.[ProjectId] = @ProjectId
  AND s.[Id] = @ServerId AND i.[Id] = @InstanceId AND d.[Id] = @DatabaseId;
'@ -Parameters @(
        (New-SqlParameterSpec -Name '@CustomerId' -Type UniqueIdentifier -Value $Ids.CustomerA),
        (New-SqlParameterSpec -Name '@ProjectId' -Type UniqueIdentifier -Value $Ids.ProjectA1),
        (New-SqlParameterSpec -Name '@ServerId' -Type UniqueIdentifier -Value $Ids.ServerA1),
        (New-SqlParameterSpec -Name '@InstanceId' -Type UniqueIdentifier -Value $Ids.InstanceA1),
        (New-SqlParameterSpec -Name '@DatabaseId' -Type UniqueIdentifier -Value $Ids.DatabaseA1)
    ))
    Assert-Condition -Condition ($relationshipCount -eq 1) -Message 'Valid Server -> SQL Instance -> SQL Database relationship was not found exactly once.'
    Write-Evidence -Status PASS -Message 'Valid same-customer/project Server -> SQL Instance -> SQL Database relationship succeeded.'

    foreach ($parentInstance in @(
        [ordered]@{ Id = $Ids.InstanceCrossCustomerDatabaseParent; ServerId = $Ids.ServerCrossCustomerDatabaseParent; Name = $FixtureNames.CrossCustomerDatabaseParentInstance },
        [ordered]@{ Id = $Ids.InstanceCrossProjectDatabaseParent; ServerId = $Ids.ServerCrossProjectDatabaseParent; Name = $FixtureNames.CrossProjectDatabaseParentInstance },
        [ordered]@{ Id = $Ids.InstanceNegativeSizeDatabaseParent; ServerId = $Ids.ServerNegativeSizeDatabaseParent; Name = $FixtureNames.NegativeSizeDatabaseParentInstance },
        [ordered]@{ Id = $Ids.InstanceCompatibilityLowDatabaseParent; ServerId = $Ids.ServerCompatibilityLowDatabaseParent; Name = $FixtureNames.CompatibilityLowDatabaseParentInstance },
        [ordered]@{ Id = $Ids.InstanceCompatibilityHighDatabaseParent; ServerId = $Ids.ServerCompatibilityHighDatabaseParent; Name = $FixtureNames.CompatibilityHighDatabaseParentInstance },
        [ordered]@{ Id = $Ids.InstanceDatabaseDuplicateParent; ServerId = $Ids.ServerDatabaseDuplicateParent; Name = $FixtureNames.DatabaseDuplicateParentInstance }
    )) {
        $inserted = Invoke-SqlNonQuery -Sql $InstanceInsertSql -Parameters (Get-InstanceParameters -Id $parentInstance.Id -CustomerId $Ids.CustomerA -ProjectId $Ids.ProjectA1 -ServerId $parentInstance.ServerId -InstanceName $parentInstance.Name)
        Assert-Condition -Condition ($inserted -eq 1) -Message ("Dedicated SQL Database parent fixture '{0}' did not affect exactly one row." -f $parentInstance.Name)
    }

    $inserted = Invoke-SqlNonQuery -Sql $InstanceInsertSql -Parameters (Get-InstanceParameters -Id $Ids.InstanceDuplicateBaseline -CustomerId $Ids.CustomerA -ProjectId $Ids.ProjectA1 -ServerId $Ids.ServerInstanceDuplicate -InstanceName $FixtureNames.InstanceDuplicateBaseline)
    Assert-Condition -Condition ($inserted -eq 1) -Message 'Dedicated SQL Instance uniqueness baseline did not affect exactly one row.'
    $inserted = Invoke-SqlNonQuery -Sql $DatabaseInsertSql -Parameters (Get-DatabaseParameters -Id $Ids.DatabaseDuplicateBaseline -CustomerId $Ids.CustomerA -ProjectId $Ids.ProjectA1 -SqlInstanceId $Ids.InstanceDatabaseDuplicateParent -Name $FixtureNames.DatabaseDuplicateBaseline)
    Assert-Condition -Condition ($inserted -eq 1) -Message 'Dedicated SQL Database uniqueness baseline did not affect exactly one row.'

    $null = $evidence.Add((Assert-SqlFailure -Name 'Cross-customer Server -> SQL Instance relationship' -ExpectedNumbers @(547) -ExpectedMessageFragment 'FK_SqlInstances_Servers_CustomerId_ProjectId_ServerId' -Action {
        Invoke-SqlNonQuery -Sql $InstanceInsertSql -Parameters (Get-InstanceParameters -Id $Ids.CrossCustomerInstanceAttempt -CustomerId $Ids.CustomerB -ProjectId $Ids.ProjectB1 -ServerId $Ids.ServerCrossCustomerTarget -InstanceName $FixtureNames.CrossCustomerInstanceAttempt)
    }))
    $null = $evidence.Add((Assert-SqlFailure -Name 'Cross-project Server -> SQL Instance relationship' -ExpectedNumbers @(547) -ExpectedMessageFragment 'FK_SqlInstances_Servers_CustomerId_ProjectId_ServerId' -Action {
        Invoke-SqlNonQuery -Sql $InstanceInsertSql -Parameters (Get-InstanceParameters -Id $Ids.CrossProjectInstanceAttempt -CustomerId $Ids.CustomerA -ProjectId $Ids.ProjectA2 -ServerId $Ids.ServerCrossProjectTarget -InstanceName $FixtureNames.CrossProjectInstanceAttempt)
    }))
    $null = $evidence.Add((Assert-SqlFailure -Name 'Cross-customer SQL Instance -> SQL Database relationship' -ExpectedNumbers @(547) -ExpectedMessageFragment 'FK_SqlDatabases_SqlInstances_CustomerId_ProjectId_SqlInstanceId' -Action {
        Invoke-SqlNonQuery -Sql $DatabaseInsertSql -Parameters (Get-DatabaseParameters -Id $Ids.CrossCustomerDatabaseAttempt -CustomerId $Ids.CustomerB -ProjectId $Ids.ProjectB1 -SqlInstanceId $Ids.InstanceCrossCustomerDatabaseParent -Name $FixtureNames.CrossCustomerDatabaseAttempt)
    }))
    $null = $evidence.Add((Assert-SqlFailure -Name 'Cross-project SQL Instance -> SQL Database relationship' -ExpectedNumbers @(547) -ExpectedMessageFragment 'FK_SqlDatabases_SqlInstances_CustomerId_ProjectId_SqlInstanceId' -Action {
        Invoke-SqlNonQuery -Sql $DatabaseInsertSql -Parameters (Get-DatabaseParameters -Id $Ids.CrossProjectDatabaseAttempt -CustomerId $Ids.CustomerA -ProjectId $Ids.ProjectA2 -SqlInstanceId $Ids.InstanceCrossProjectDatabaseParent -Name $FixtureNames.CrossProjectDatabaseAttempt)
    }))
    $null = $evidence.Add((Assert-SqlFailure -Name 'Port below approved range' -ExpectedNumbers @(547) -ExpectedMessageFragment 'CK_SqlInstances_Port' -Action {
        Invoke-SqlNonQuery -Sql $InstanceInsertSql -Parameters (Get-InstanceParameters -Id $Ids.PortBelowInstanceAttempt -CustomerId $Ids.CustomerA -ProjectId $Ids.ProjectA1 -ServerId $Ids.ServerPortBelow -InstanceName $FixtureNames.PortBelowInstanceAttempt -Port 0)
    }))
    $null = $evidence.Add((Assert-SqlFailure -Name 'Port above approved range' -ExpectedNumbers @(547) -ExpectedMessageFragment 'CK_SqlInstances_Port' -Action {
        Invoke-SqlNonQuery -Sql $InstanceInsertSql -Parameters (Get-InstanceParameters -Id $Ids.PortAboveInstanceAttempt -CustomerId $Ids.CustomerA -ProjectId $Ids.ProjectA1 -ServerId $Ids.ServerPortAbove -InstanceName $FixtureNames.PortAboveInstanceAttempt -Port 65536)
    }))
    $null = $evidence.Add((Assert-SqlFailure -Name 'Negative SQL Database size' -ExpectedNumbers @(547) -ExpectedMessageFragment 'CK_SqlDatabases_SizeMb' -Action {
        Invoke-SqlNonQuery -Sql $DatabaseInsertSql -Parameters (Get-DatabaseParameters -Id $Ids.NegativeSizeDatabaseAttempt -CustomerId $Ids.CustomerA -ProjectId $Ids.ProjectA1 -SqlInstanceId $Ids.InstanceNegativeSizeDatabaseParent -Name $FixtureNames.NegativeSizeDatabaseAttempt -SizeMb -1)
    }))
    $null = $evidence.Add((Assert-SqlFailure -Name 'Compatibility level below approved range' -ExpectedNumbers @(547) -ExpectedMessageFragment 'CK_SqlDatabases_CompatibilityLevel' -Action {
        Invoke-SqlNonQuery -Sql $DatabaseInsertSql -Parameters (Get-DatabaseParameters -Id $Ids.CompatibilityLowDatabaseAttempt -CustomerId $Ids.CustomerA -ProjectId $Ids.ProjectA1 -SqlInstanceId $Ids.InstanceCompatibilityLowDatabaseParent -Name $FixtureNames.CompatibilityLowDatabaseAttempt -CompatibilityLevel 79)
    }))
    $null = $evidence.Add((Assert-SqlFailure -Name 'Compatibility level above approved range' -ExpectedNumbers @(547) -ExpectedMessageFragment 'CK_SqlDatabases_CompatibilityLevel' -Action {
        Invoke-SqlNonQuery -Sql $DatabaseInsertSql -Parameters (Get-DatabaseParameters -Id $Ids.CompatibilityHighDatabaseAttempt -CustomerId $Ids.CustomerA -ProjectId $Ids.ProjectA1 -SqlInstanceId $Ids.InstanceCompatibilityHighDatabaseParent -Name $FixtureNames.CompatibilityHighDatabaseAttempt -CompatibilityLevel 201)
    }))
    $null = $evidence.Add((Assert-SqlFailure -Name 'Normalized active SQL Instance duplicate' -ExpectedNumbers @(2601, 2627) -ExpectedMessageFragment 'UX_SqlInstances_Owner_Server_NormalizedName_Active' -Action {
        Invoke-SqlNonQuery -Sql $InstanceInsertSql -Parameters (Get-InstanceParameters -Id $Ids.InstanceDuplicateAttempt -CustomerId $Ids.CustomerA -ProjectId $Ids.ProjectA1 -ServerId $Ids.ServerInstanceDuplicate -InstanceName $FixtureNames.InstanceDuplicateAttempt)
    }))
    $null = $evidence.Add((Assert-SqlFailure -Name 'Normalized active SQL Database duplicate' -ExpectedNumbers @(2601, 2627) -ExpectedMessageFragment 'UX_SqlDatabases_Owner_Instance_NormalizedName_Active' -Action {
        Invoke-SqlNonQuery -Sql $DatabaseInsertSql -Parameters (Get-DatabaseParameters -Id $Ids.DatabaseDuplicateAttempt -CustomerId $Ids.CustomerA -ProjectId $Ids.ProjectA1 -SqlInstanceId $Ids.InstanceDatabaseDuplicateParent -Name $FixtureNames.DatabaseDuplicateAttempt)
    }))

    return [ordered]@{
        validRelationshipCount = $relationshipCount
        expectedSqlRejections = @($evidence)
    }
}

function Invoke-RowVersionTest {
    param([Parameter(Mandatory = $true)][hashtable] $Ids)

    [System.Byte[]] $original = Invoke-SqlScalar -Sql 'SELECT [RowVersion] FROM [dbo].[SqlInstances] WHERE [Id] = @Id;' -Parameters @(
        (New-SqlParameterSpec -Name '@Id' -Type UniqueIdentifier -Value $Ids.InstanceA1)
    )
    Assert-Condition -Condition ($original.GetType() -eq [System.Byte[]]) -Message 'Initial SQL Instance rowversion was not preserved as System.Byte[].'
    Assert-Condition -Condition ($original.Length -eq 8) -Message 'Initial SQL Instance rowversion is not eight bytes.'
    $updatedRows = Invoke-SqlNonQuery -Sql @'
UPDATE [dbo].[SqlInstances]
SET [Edition] = @Edition, [UpdatedAt] = @UpdatedAt
WHERE [Id] = @Id AND [RowVersion] = @RowVersion;
'@ -Parameters @(
        (New-SqlParameterSpec -Name '@Edition' -Type NVarChar -Value 'Synthetic Express Updated' -Size 100),
        (New-SqlParameterSpec -Name '@UpdatedAt' -Type DateTimeOffset -Value ([DateTimeOffset]::Parse('2026-09-11T12:01:00+00:00'))),
        (New-SqlParameterSpec -Name '@Id' -Type UniqueIdentifier -Value $Ids.InstanceA1),
        (New-SqlParameterSpec -Name '@RowVersion' -Type Binary -Value $original -Size 8)
    )
    Assert-Condition -Condition ($updatedRows -eq 1) -Message 'Current rowversion update did not affect exactly one row.'

    [System.Byte[]] $current = Invoke-SqlScalar -Sql 'SELECT [RowVersion] FROM [dbo].[SqlInstances] WHERE [Id] = @Id;' -Parameters @(
        (New-SqlParameterSpec -Name '@Id' -Type UniqueIdentifier -Value $Ids.InstanceA1)
    )
    Assert-Condition -Condition ($current.GetType() -eq [System.Byte[]]) -Message 'Updated SQL Instance rowversion was not preserved as System.Byte[].'
    Assert-Condition -Condition ($current.Length -eq 8) -Message 'Updated SQL Instance rowversion is not eight bytes.'
    $originalHex = ([BitConverter]::ToString($original)).Replace('-', '')
    $currentHex = ([BitConverter]::ToString($current)).Replace('-', '')
    Assert-Condition -Condition ($originalHex -cne $currentHex) -Message 'SQL Server rowversion did not change after update.'

    $staleRows = Invoke-SqlNonQuery -Sql @'
UPDATE [dbo].[SqlInstances]
SET [Edition] = @Edition, [UpdatedAt] = @UpdatedAt
WHERE [Id] = @Id AND [RowVersion] = @StaleRowVersion;
'@ -Parameters @(
        (New-SqlParameterSpec -Name '@Edition' -Type NVarChar -Value 'Stale Update Must Not Apply' -Size 100),
        (New-SqlParameterSpec -Name '@UpdatedAt' -Type DateTimeOffset -Value ([DateTimeOffset]::Parse('2026-09-11T12:02:00+00:00'))),
        (New-SqlParameterSpec -Name '@Id' -Type UniqueIdentifier -Value $Ids.InstanceA1),
        (New-SqlParameterSpec -Name '@StaleRowVersion' -Type Binary -Value $original -Size 8)
    )
    Assert-Condition -Condition ($staleRows -eq 0) -Message 'Stale rowversion update was not rejected.'
    Write-Evidence -Status PASS -Message 'SQL Server changed rowversion after update and rejected the stale conditional update.'
    return [ordered]@{
        originalHex = $originalHex
        currentHex = $currentHex
        currentUpdateRows = $updatedRows
        staleUpdateRows = $staleRows
    }
}

function Invoke-CollationAndNormalizationTest {
    param([Parameter(Mandatory = $true)][hashtable] $Ids)

    $collation = [string] (Invoke-SqlScalar -Sql 'SELECT CONVERT(nvarchar(128), DATABASEPROPERTYEX(DB_NAME(), N''Collation''));')
    Assert-Condition -Condition (-not [string]::IsNullOrWhiteSpace($collation)) -Message 'Database collation was not reported.'
    $caseInsensitive = [int] (Invoke-SqlScalar -Sql 'SELECT CASE WHEN CONVERT(nvarchar(128), N''ph3sqlcase'') = CONVERT(nvarchar(128), N''PH3SQLCASE'') THEN 1 ELSE 0 END;')
    $databaseCaseInsensitiveComparison = $caseInsensitive -eq 1

    Assert-Condition -Condition ((ConvertTo-ApprovedInstanceName -Value $FixtureNames.AliasInstanceBaseline) -ceq 'MSSQLSERVER') -Message 'Approved DEFAULT alias normalization differs from source rules.'
    Assert-Condition -Condition ((ConvertTo-ApprovedInstanceName -Value $FixtureNames.AliasInstanceAttempt) -ceq 'MSSQLSERVER') -Message 'Approved default alias normalization differs from source rules.'
    $unicodeFixture = New-UnicodeFormCFixture
    $composed = [string] $unicodeFixture.composed
    $decomposed = [string] $unicodeFixture.decomposed
    $composedNormalized = ConvertTo-ApprovedDatabaseName -Value $composed
    $decomposedNormalized = ConvertTo-ApprovedDatabaseName -Value $decomposed
    Assert-Condition -Condition ([string]::Equals($composedNormalized, $decomposedNormalized, [StringComparison]::Ordinal)) -Message 'Unicode Form C normalization did not converge composed and decomposed names.'

    $null = Invoke-SqlNonQuery -Sql $InstanceInsertSql -Parameters (Get-InstanceParameters -Id $Ids.CaseInstance -CustomerId $Ids.CustomerA -ProjectId $Ids.ProjectA2 -ServerId $Ids.ServerAlias -InstanceName $FixtureNames.AliasInstanceBaseline)
    $aliasRejection = Assert-SqlFailure -Name 'Case-variant DEFAULT alias normalized duplicate' -ExpectedNumbers @(2601, 2627) -ExpectedMessageFragment 'UX_SqlInstances_Owner_Server_NormalizedName_Active' -Action {
        Invoke-SqlNonQuery -Sql $InstanceInsertSql -Parameters (Get-InstanceParameters -Id $Ids.AliasInstanceAttempt -CustomerId $Ids.CustomerA -ProjectId $Ids.ProjectA2 -ServerId $Ids.ServerAlias -InstanceName $FixtureNames.AliasInstanceAttempt)
    }
    $null = Invoke-SqlNonQuery -Sql $InstanceInsertSql -Parameters (Get-InstanceParameters -Id $Ids.InstanceUnicodeDatabaseParent -CustomerId $Ids.CustomerA -ProjectId $Ids.ProjectA2 -ServerId $Ids.ServerUnicodeDatabaseParent -InstanceName $FixtureNames.UnicodeDatabaseParentInstance)
    $null = Invoke-SqlNonQuery -Sql $DatabaseInsertSql -Parameters (Get-DatabaseParameters -Id $Ids.UnicodeDatabase -CustomerId $Ids.CustomerA -ProjectId $Ids.ProjectA2 -SqlInstanceId $Ids.InstanceUnicodeDatabaseParent -Name $composed)
    $unicodeRejection = Assert-SqlFailure -Name 'Unicode Form C database duplicate' -ExpectedNumbers @(2601, 2627) -ExpectedMessageFragment 'UX_SqlDatabases_Owner_Instance_NormalizedName_Active' -Action {
        Invoke-SqlNonQuery -Sql $DatabaseInsertSql -Parameters (Get-DatabaseParameters -Id $Ids.UnicodeDatabaseAttempt -CustomerId $Ids.CustomerA -ProjectId $Ids.ProjectA2 -SqlInstanceId $Ids.InstanceUnicodeDatabaseParent -Name $decomposed)
    }
    Write-Evidence -Status PASS -Message ("Approved trim/Form-C/invariant-uppercase/default-alias normalization and collation-independent normalized duplicate rejection passed under {0}; database case-insensitive comparison observed: {1}." -f $collation, $databaseCaseInsensitiveComparison)
    return [ordered]@{
        databaseCollation = $collation
        databaseCaseInsensitiveComparison = $databaseCaseInsensitiveComparison
        defaultAliasNormalized = 'MSSQLSERVER'
        composedNormalized = $composedNormalized
        decomposedNormalized = $decomposedNormalized
        composedBeforeCodePoints = Get-UnicodeCodePoints -Value $composed
        decomposedBeforeCodePoints = Get-UnicodeCodePoints -Value $decomposed
        composedAfterNormalizationCodePoints = Get-UnicodeCodePoints -Value $composedNormalized
        decomposedAfterNormalizationCodePoints = Get-UnicodeCodePoints -Value $decomposedNormalized
        aliasDuplicateRejection = $aliasRejection
        unicodeDuplicateRejection = $unicodeRejection
    }
}

function Invoke-ConcurrentDuplicateTest {
    param([Parameter(Mandatory = $true)][hashtable] $Ids)

    $connection1 = $null
    $connection2 = $null
    $command1 = $null
    $command2 = $null
    try {
        $connection1 = Open-ExactDatabaseConnection
        $connection2 = Open-ExactDatabaseConnection
        $command1 = $connection1.CreateCommand()
        $command2 = $connection2.CreateCommand()
        $command1.CommandTimeout = 30
        $command2.CommandTimeout = 30
        $concurrentSql = "WAITFOR DELAY '00:00:01';`r`n{0}" -f $InstanceInsertSql
        $command1.CommandText = $concurrentSql
        $command2.CommandText = $concurrentSql
        $normalizedName = ConvertTo-ApprovedInstanceName -Value $FixtureNames.ConcurrentInstance
        Add-SqlParameters -Command $command1 -Parameters (Get-InstanceParameters -Id $Ids.ConcurrentInstance1 -CustomerId $Ids.CustomerA -ProjectId $Ids.ProjectA1 -ServerId $Ids.ServerConcurrent -InstanceName $FixtureNames.ConcurrentInstance)
        Add-SqlParameters -Command $command2 -Parameters (Get-InstanceParameters -Id $Ids.ConcurrentInstance2 -CustomerId $Ids.CustomerA -ProjectId $Ids.ProjectA1 -ServerId $Ids.ServerConcurrent -InstanceName $FixtureNames.ConcurrentInstance)
        Assert-Condition -Condition ([string]::Equals([string] $command1.Parameters['@NormalizedInstanceName'].Value, $normalizedName, [StringComparison]::Ordinal)) -Message 'Concurrent writer 1 did not receive the exact approved normalized key.'
        Assert-Condition -Condition ([string]::Equals([string] $command2.Parameters['@NormalizedInstanceName'].Value, $normalizedName, [StringComparison]::Ordinal)) -Message 'Concurrent writer 2 did not receive the exact approved normalized key.'

        $startedAt = [DateTimeOffset]::UtcNow.ToString('o')
        $async1 = $command1.BeginExecuteNonQuery()
        $async2 = $command2.BeginExecuteNonQuery()
        $outcomes = New-Object System.Collections.ArrayList
        foreach ($operation in @(
            [ordered]@{ Name = 'writer-1'; Command = $command1; Async = $async1 },
            [ordered]@{ Name = 'writer-2'; Command = $command2; Async = $async2 }
        )) {
            try {
                $rows = $operation.Command.EndExecuteNonQuery($operation.Async)
                $null = $outcomes.Add([ordered]@{ writer = $operation.Name; outcome = 'INSERTED'; rows = $rows; sqlErrorNumber = $null })
            }
            catch {
                $sqlException = Find-SqlException -Exception $_.Exception
                if ($null -eq $sqlException) { throw }
                $null = $outcomes.Add([ordered]@{ writer = $operation.Name; outcome = 'REJECTED'; rows = 0; sqlErrorNumber = $sqlException.Number; message = $sqlException.Message })
            }
        }

        $concurrentEvidence = [ordered]@{
            startedAtUtc = $startedAt
            completedAtUtc = $null
            synchronization = 'Both asynchronous commands used the same one-second SQL WAITFOR gate.'
            normalizedName = $normalizedName
            outcomes = @($outcomes)
            persistedConflictRows = $null
        }
        $Result.concurrencyEvidence['concurrentDuplicateCreate'] = $concurrentEvidence

        $successes = @($outcomes | Where-Object { $_.outcome -ceq 'INSERTED' -and $_.rows -eq 1 })
        $rejections = @($outcomes | Where-Object { $_.outcome -ceq 'REJECTED' -and $_.sqlErrorNumber -in @(2601, 2627) })
        Assert-Condition -Condition ($successes.Count -eq 1) -Message ("Concurrent duplicate test produced {0} successful inserts; expected exactly one." -f $successes.Count)
        Assert-Condition -Condition ($rejections.Count -eq 1) -Message ("Concurrent duplicate test produced {0} unique-index rejections; expected exactly one." -f $rejections.Count)
        $persisted = [int] (Invoke-SqlScalar -Sql @'
SELECT COUNT_BIG(*) FROM [dbo].[SqlInstances]
WHERE [CustomerId] = @CustomerId AND [ProjectId] = @ProjectId AND [ServerId] = @ServerId
  AND [NormalizedInstanceName] = @NormalizedName AND [IsDeleted] = 0;
'@ -Parameters @(
            (New-SqlParameterSpec -Name '@CustomerId' -Type UniqueIdentifier -Value $Ids.CustomerA),
            (New-SqlParameterSpec -Name '@ProjectId' -Type UniqueIdentifier -Value $Ids.ProjectA1),
            (New-SqlParameterSpec -Name '@ServerId' -Type UniqueIdentifier -Value $Ids.ServerConcurrent),
            (New-SqlParameterSpec -Name '@NormalizedName' -Type NVarChar -Value $normalizedName -Size 128)
        ))
        $concurrentEvidence.persistedConflictRows = $persisted
        $concurrentEvidence.completedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
        Assert-Condition -Condition ($persisted -eq 1) -Message ("Concurrent duplicate test persisted {0} active rows; expected exactly one." -f $persisted)
        Write-Evidence -Status PASS -Message 'Controlled concurrent duplicate-create test allowed one insert and rejected one conflict.'
        return $concurrentEvidence
    }
    finally {
        if ($null -ne $command1) { $command1.Dispose() }
        if ($null -ne $command2) { $command2.Dispose() }
        if ($null -ne $connection1) { $connection1.Dispose() }
        if ($null -ne $connection2) { $connection2.Dispose() }
    }
}

function Get-PlanAnalysis {
    param(
        [Parameter(Mandatory = $true)][xml] $Plan,
        [Parameter(Mandatory = $true)][string] $PlanPath
    )

    $namespace = $Plan.DocumentElement.NamespaceURI
    $manager = New-Object System.Xml.XmlNamespaceManager $Plan.NameTable
    $manager.AddNamespace('sp', $namespace)
    $relOps = @($Plan.SelectNodes('//sp:RelOp', $manager))
    $operatorCounts = [ordered]@{}
    foreach ($relOp in $relOps) {
        $physical = [string] $relOp.GetAttribute('PhysicalOp')
        if (-not $operatorCounts.Contains($physical)) { $operatorCounts[$physical] = 0 }
        $operatorCounts[$physical] = [int] $operatorCounts[$physical] + 1
    }
    $scans = @($relOps | Where-Object { ([string] $_.GetAttribute('PhysicalOp')).EndsWith('Scan', [StringComparison]::OrdinalIgnoreCase) }).Count
    $seeks = @($relOps | Where-Object { ([string] $_.GetAttribute('PhysicalOp')).EndsWith('Seek', [StringComparison]::OrdinalIgnoreCase) }).Count
    $keyLookups = @($Plan.SelectNodes('//sp:IndexScan[@Lookup="1"]', $manager)).Count
    $missingIndexes = New-Object System.Collections.ArrayList
    foreach ($missing in @($Plan.SelectNodes('//sp:MissingIndex', $manager))) {
        $columns = New-Object System.Collections.ArrayList
        foreach ($columnGroup in @($missing.SelectNodes('sp:ColumnGroup', $manager))) {
            foreach ($column in @($columnGroup.SelectNodes('sp:Column', $manager))) {
                $null = $columns.Add([ordered]@{
                    usage = [string] $columnGroup.GetAttribute('Usage')
                    column = [string] $column.GetAttribute('Name')
                })
            }
        }
        $null = $missingIndexes.Add([ordered]@{
            impact = [string] $missing.ParentNode.GetAttribute('Impact')
            database = [string] $missing.GetAttribute('Database')
            schema = [string] $missing.GetAttribute('Schema')
            table = [string] $missing.GetAttribute('Table')
            columns = @($columns)
        })
    }
    return [ordered]@{
        planFile = $PlanPath
        scans = $scans
        seeks = $seeks
        keyLookups = $keyLookups
        missingIndexRecommendations = @($missingIndexes)
        physicalOperators = $operatorCounts
    }
}

function Capture-ActualExecutionPlan {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $Sql,
        [object[]] $Parameters = @()
    )

    $connection = Open-ExactDatabaseConnection
    $statisticsEnabled = $false
    try {
        $toggle = $connection.CreateCommand()
        $toggle.CommandText = 'SET STATISTICS XML ON;'
        $null = $toggle.ExecuteNonQuery()
        $statisticsEnabled = $true
        $toggle.Dispose()

        $command = $connection.CreateCommand()
        $command.CommandTimeout = 30
        $command.CommandText = $Sql
        Add-SqlParameters -Command $command -Parameters $Parameters
        $reader = $command.ExecuteReader()
        $planXml = $null
        try {
            do {
                while ($reader.Read()) {
                    if ($reader.FieldCount -eq 1) {
                        $candidate = $reader.GetValue(0)
                        $candidateText = if ($candidate -is [System.Data.SqlTypes.SqlXml]) { $candidate.Value } else { [string] $candidate }
                        if ($candidateText.IndexOf('<ShowPlanXML', [StringComparison]::Ordinal) -ge 0) {
                            $planXml = $candidateText
                        }
                    }
                }
            } while ($reader.NextResult())
        }
        finally {
            $reader.Dispose()
            $command.Dispose()
        }
        Assert-Condition -Condition (-not [string]::IsNullOrWhiteSpace($planXml)) -Message ("No actual execution plan was returned for {0}." -f $Name)
        [xml] $plan = $planXml
        $fileName = ("{0}.sqlplan" -f ([regex]::Replace($Name, '[^A-Za-z0-9_-]', '_')))
        $planPath = Join-Path $PlansDirectory $fileName
        [System.IO.File]::WriteAllText($planPath, $plan.OuterXml, (New-Object System.Text.UTF8Encoding($false)))
        $analysis = Get-PlanAnalysis -Plan $plan -PlanPath $planPath
        $analysis['name'] = $Name
        $null = $ExecutionPlans.Add($analysis)
        Write-Evidence -Status PASS -Message ("Actual plan {0}: scans={1}, seeks={2}, key lookups={3}, missing-index recommendations={4}." -f $Name, $analysis.scans, $analysis.seeks, $analysis.keyLookups, $analysis.missingIndexRecommendations.Count)
        return $analysis
    }
    finally {
        if ($statisticsEnabled -and $connection.State -eq [System.Data.ConnectionState]::Open) {
            $toggleOff = $connection.CreateCommand()
            $toggleOff.CommandText = 'SET STATISTICS XML OFF;'
            $null = $toggleOff.ExecuteNonQuery()
            $toggleOff.Dispose()
        }
        $connection.Dispose()
    }
}

function Assert-RollbackBoundary {
    $history = @(Assert-MigrationHistory -Phase 'Rollback boundary' -Expected $ExpectedMigrations[0..1])
    $phase3TableCount = [int] (Invoke-SqlScalar -Sql @'
SELECT
    CASE WHEN OBJECT_ID(N'dbo.SqlInstances', N'U') IS NULL
           AND OBJECT_ID(N'dbo.SqlDatabases', N'U') IS NULL
         THEN 0 ELSE 1 END;
'@)
    Assert-Condition -Condition ($phase3TableCount -eq 0) -Message 'Phase 3 SQL tables remained after rollback to the approved baseline.'
    $phase3AuditColumnCount = [int] (Invoke-SqlScalar -Sql @'
SELECT COUNT_BIG(*)
FROM sys.columns
WHERE object_id = OBJECT_ID(N'dbo.AuditEvents', N'U')
  AND name IN (N'CorrelationId', N'ActorPrincipalType');
'@)
    Assert-Condition -Condition ($phase3AuditColumnCount -eq 0) -Message 'Phase 3 AuditEvents columns remained after rollback.'
    $phase3AlternateKeyCount = [int] (Invoke-SqlScalar -Sql @'
SELECT COUNT_BIG(*)
FROM sys.key_constraints
WHERE name IN
(
    N'AK_Projects_CustomerId_Id',
    N'AK_Servers_CustomerId_ProjectId_Id',
    N'AK_ImportBatches_CustomerId_ProjectId_Id'
);
'@)
    Assert-Condition -Condition ($phase3AlternateKeyCount -eq 0) -Message 'Phase 3 alternate keys remained after rollback.'
    Write-Evidence -Status PASS -Message 'Rollback reached the approved AddDiscoveryImport boundary and removed only the expected Phase 3 schema.'
    return [ordered]@{
        history = $history
        phase3TablesPresent = $false
        phase3AuditColumnsPresent = $false
        phase3AlternateKeysPresent = $false
    }
}

function Set-HarnessFailure {
    param(
        [Parameter(Mandatory = $true)]
        [System.Exception] $Exception
    )

    $originalExceptionMessage = [string] $Exception.Message
    $safeExceptionMessage = ConvertTo-MeaningfulMessage `
        -Message $originalExceptionMessage `
        -Fallback ("Harness failed because exception type '{0}' did not provide a message." -f $Exception.GetType().FullName)

    if ($safeExceptionMessage.StartsWith('PH3_BLOCKED::', [StringComparison]::Ordinal)) {
        $Result.outcome = 'BLOCKED'
        $Result.outcomeReason = ConvertTo-MeaningfulMessage `
            -Message $safeExceptionMessage.Substring('PH3_BLOCKED::'.Length) `
            -Fallback ("Harness reported BLOCKED without detail. Original exception message: '{0}'." -f $originalExceptionMessage)
        $script:ExitCode = 2
        Write-Evidence -Status BLOCKED -Message $Result.outcomeReason
        return
    }

    $Result.outcome = 'FAIL'
    $Result.outcomeReason = if ($safeExceptionMessage.StartsWith('PH3_FAIL::', [StringComparison]::Ordinal)) {
        ConvertTo-MeaningfulMessage `
            -Message $safeExceptionMessage.Substring('PH3_FAIL::'.Length) `
            -Fallback ("Harness reported FAIL without detail. Original exception message: '{0}'." -f $originalExceptionMessage)
    }
    else {
        $safeExceptionMessage
    }
    $script:ExitCode = 1
    Write-Evidence -Status FAIL -Message $Result.outcomeReason
}

try {
    New-Item -ItemType Directory -Path $ResultsDirectory -Force | Out-Null
    New-Item -ItemType Directory -Path $PlansDirectory -Force | Out-Null
    Write-Evidence -Status INFO -Message ("Evidence will be written under {0}." -f $ResultsDirectory)

    if ($Server -cne $ExpectedServer) {
        Add-Step -Name 'Exact server target gate' -Outcome BLOCKED -Detail ("Supplied server '{0}' is not the approved server '{1}'." -f $Server, $ExpectedServer)
        Throw-Blocked -Message 'Unexpected server argument.'
    }
    if ($Database -cne $ExpectedDatabase) {
        Add-Step -Name 'Exact database target gate' -Outcome BLOCKED -Detail ("Supplied database '{0}' is not the approved database '{1}'." -f $Database, $ExpectedDatabase)
        Throw-Blocked -Message 'Unexpected database argument.'
    }
    Add-Step -Name 'Exact SQL target arguments' -Outcome PASS -Detail 'Server and database exactly match the authorised values.'

    Set-Location -LiteralPath $RepositoryRoot
    $actualBranch = (& git branch --show-current 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) { Throw-Blocked -Message 'Unable to read the repository branch.' }
    $actualHead = (& git rev-parse HEAD 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) { Throw-Blocked -Message 'Unable to read repository HEAD.' }
    $Result.repository.actualBranch = $actualBranch
    $Result.repository.actualHead = $actualHead
    if ($actualBranch -cne $ExpectedBranch) {
        Add-Step -Name 'Repository branch gate' -Outcome BLOCKED -Detail ("Actual branch '{0}' does not match '{1}'." -f $actualBranch, $ExpectedBranch)
        Throw-Blocked -Message 'Repository branch mismatch.'
    }
    if ($actualHead -cne $ExpectedHead) {
        Add-Step -Name 'Repository HEAD gate' -Outcome BLOCKED -Detail ("Actual HEAD '{0}' does not match '{1}'." -f $actualHead, $ExpectedHead)
        Throw-Blocked -Message 'Repository HEAD mismatch.'
    }
    Add-Step -Name 'Repository branch and HEAD gate' -Outcome PASS -Detail 'Exact authorised branch and commit confirmed before any SQL access.'

    $unicodeFixtureEvidence = Assert-UnicodeFormCFixture
    $Result.normalizationEvidence = [ordered]@{
        fixtureSmoke = $unicodeFixtureEvidence
        sqlServer = $null
    }

    Assert-BinaryProviderParameterPreservation
    Assert-NormalizedProviderParameterPreservation

    $dotnet = Get-Command dotnet -CommandType Application -ErrorAction SilentlyContinue
    if ($null -eq $dotnet) { Throw-Blocked -Message 'dotnet is not installed or not on PATH.' }
    $dotnetEf = Get-Command dotnet-ef -CommandType Application -ErrorAction SilentlyContinue
    if ($null -eq $dotnetEf) { Throw-Blocked -Message 'Pinned dotnet-ef is not installed or not on PATH; no tool restore is performed by this harness.' }
    $efVersion = Invoke-NativeCommand -Name 'dotnet-ef version prerequisite' -FilePath $dotnetEf.Source -Arguments @('--version') -FailureOutcome BLOCKED
    Assert-Condition -Condition ([regex]::IsMatch($efVersion, '(^|\s)10\.0\.11($|\s)')) -Message 'dotnet-ef is not the repository-pinned 10.0.11 version.'

    Save-ProcessEnvironmentValue -Name 'ConnectionStrings__LgrDatabase'
    Save-ProcessEnvironmentValue -Name 'DOTNET_ENVIRONMENT'
    Save-ProcessEnvironmentValue -Name 'ASPNETCORE_ENVIRONMENT'
    $databaseConnectionString = New-ConnectionString -InitialCatalog $ExpectedDatabase
    [Environment]::SetEnvironmentVariable('ConnectionStrings__LgrDatabase', $databaseConnectionString, 'Process')
    [Environment]::SetEnvironmentVariable('DOTNET_ENVIRONMENT', 'Production', 'Process')
    [Environment]::SetEnvironmentVariable('ASPNETCORE_ENVIRONMENT', 'Production', 'Process')
    Add-Step -Name 'EF process environment' -Outcome PASS -Detail 'The exact isolated connection string is held only in the process environment and is not printed or persisted.'

    $buildOutput = Invoke-NativeCommand -Name 'Complete Release build' -FilePath $dotnet.Source -Arguments @('build', $SolutionPath, '--configuration', 'Release')
    Assert-Condition -Condition ([regex]::IsMatch($buildOutput, '0 Error\(s\)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) -Message 'Release build output did not report zero errors.'

    $fullTestOutput = Invoke-NativeCommand -Name 'Complete 169-test suite' -FilePath $dotnet.Source -Arguments @('test', $SolutionPath, '--configuration', 'Release', '--no-build', '--no-restore')
    $fullTestSummary = Assert-TestSummary -Name 'Complete suite' -Output $fullTestOutput -ExpectedPassed 169
    $Result.testSummaries['complete'] = $fullTestSummary

    $sqlInventoryFilter = 'FullyQualifiedName~SqlInventoryRulesTests|FullyQualifiedName~SqlInventoryApiTests'
    $sqlInventoryOutput = Invoke-NativeCommand -Name 'Focused SQL Inventory tests' -FilePath $dotnet.Source -Arguments @('test', $SolutionPath, '--configuration', 'Release', '--no-build', '--no-restore', '--filter', $sqlInventoryFilter)
    $sqlInventorySummary = Assert-TestSummary -Name 'Focused SQL Inventory suite' -Output $sqlInventoryOutput -ExpectedPassed 35
    $Result.testSummaries['sqlInventory'] = $sqlInventorySummary

    $adr008Filter = 'FullyQualifiedName~IdentityAuthorizationTests|FullyQualifiedName~SqlInventoryAuthorizationTests'
    $adr008Output = Invoke-NativeCommand -Name 'Focused ADR-008 tests' -FilePath $dotnet.Source -Arguments @('test', $SolutionPath, '--configuration', 'Release', '--no-build', '--no-restore', '--filter', $adr008Filter)
    $adr008Summary = Assert-TestSummary -Name 'Focused ADR-008 suite' -Output $adr008Output -ExpectedPassed 79
    $Result.testSummaries['adr008'] = $adr008Summary

    $efCommonArguments = @('--project', $ApiProjectPath, '--startup-project', $ApiProjectPath, '--context', 'AppDbContext', '--configuration', 'Release', '--no-build')
    $modelOutput = Invoke-NativeCommand -Name 'EF pending-model-change validation' -FilePath $dotnetEf.Source -Arguments (@('migrations', 'has-pending-model-changes') + $efCommonArguments)
    Assert-Condition -Condition ([regex]::IsMatch($modelOutput, 'No changes have been made to the model since the last migration\.', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) -Message 'EF did not report a clean model snapshot.'
    Write-Evidence -Status PASS -Message 'EF reports no pending model changes.'

    $preMutationBranch = (& git branch --show-current 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) { Throw-Blocked -Message 'Unable to recheck the repository branch before SQL mutation.' }
    $preMutationHead = (& git rev-parse HEAD 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) { Throw-Blocked -Message 'Unable to recheck repository HEAD before SQL mutation.' }
    if ($preMutationBranch -cne $ExpectedBranch -or $preMutationHead -cne $ExpectedHead) {
        Throw-Blocked -Message 'Repository branch or HEAD changed after the initial gate; no SQL mutation was attempted.'
    }
    Add-Step -Name 'Immediate pre-mutation repository gate' -Outcome PASS -Detail 'Exact authorised branch and HEAD reconfirmed immediately before the master DB_ID check.'

    $masterConnectionString = New-ConnectionString -InitialCatalog 'master'
    $masterConnection = New-Object System.Data.SqlClient.SqlConnection $masterConnectionString
    try {
        $masterConnection.Open()
        $serverCommand = $masterConnection.CreateCommand()
        $serverCommand.CommandText = @'
SELECT
    DB_NAME() AS CurrentDatabase,
    CONVERT(nvarchar(128), SERVERPROPERTY(N'ProductVersion')) AS ProductVersion,
    CONVERT(nvarchar(128), SERVERPROPERTY(N'Edition')) AS Edition,
    CONVERT(int, SERVERPROPERTY(N'EngineEdition')) AS EngineEdition,
    CONVERT(nvarchar(128), SERVERPROPERTY(N'InstanceName')) AS InstanceName,
    ORIGINAL_LOGIN() AS OriginalLogin,
    SUSER_SNAME() AS EffectiveLogin;
'@
        $serverReader = $serverCommand.ExecuteReader()
        try {
            Assert-Condition -Condition $serverReader.Read() -Message 'SQL Server returned no server identity row.'
            $serverEvidence = [ordered]@{
                currentDatabase = [string] $serverReader['CurrentDatabase']
                productVersion = [string] $serverReader['ProductVersion']
                edition = [string] $serverReader['Edition']
                engineEdition = [int] $serverReader['EngineEdition']
                instanceName = [string] $serverReader['InstanceName']
                originalLogin = [string] $serverReader['OriginalLogin']
                effectiveLogin = [string] $serverReader['EffectiveLogin']
            }
        }
        finally {
            $serverReader.Dispose()
            $serverCommand.Dispose()
        }
        if ($serverEvidence.currentDatabase -cne 'master') { Throw-Blocked -Message 'Read-only preflight did not connect to master.' }
        if ($serverEvidence.productVersion -cne $ExpectedSqlVersion) { Throw-Blocked -Message ("Unexpected SQL Server version '{0}'." -f $serverEvidence.productVersion) }
        if ($serverEvidence.engineEdition -ne 4 -or $serverEvidence.edition.IndexOf('Express Edition', [StringComparison]::OrdinalIgnoreCase) -lt 0) { Throw-Blocked -Message ("Unexpected SQL Server edition '{0}'." -f $serverEvidence.edition) }
        if ($serverEvidence.instanceName -cne 'SQLEXPRESS') { Throw-Blocked -Message ("Unexpected SQL Server instance '{0}'." -f $serverEvidence.instanceName) }
        $Result.serverEvidence = $serverEvidence
        Add-Step -Name 'SQL Server identity gate' -Outcome PASS -Detail 'Connected read-only to master on SQL Server 16.0.1000.6 Express SQLEXPRESS using Integrated Security.' -Evidence $serverEvidence

        $existenceCommand = $masterConnection.CreateCommand()
        $existenceCommand.CommandText = 'SELECT DB_ID(@DatabaseName);'
        Add-SqlParameters -Command $existenceCommand -Parameters @(
            (New-SqlParameterSpec -Name '@DatabaseName' -Type NVarChar -Value $ExpectedDatabase -Size 128)
        )
        $databaseId = $existenceCommand.ExecuteScalar()
        $existenceCommand.Dispose()
        if ($databaseId -isnot [DBNull] -and $null -ne $databaseId) {
            Add-Step -Name 'Isolated database non-existence gate' -Outcome BLOCKED -Detail 'The exact assurance database already exists; no mutation was attempted.' -Evidence ([ordered]@{ databaseId = [int] $databaseId })
            Throw-Blocked -Message 'The isolated database already exists and this harness never drops or reuses it.'
        }
        Add-Step -Name 'Isolated database non-existence gate' -Outcome PASS -Detail 'Parameterised DB_ID check on master confirms the exact assurance database does not exist.'
    }
    catch {
        if ($_.Exception.Message.StartsWith('PH3_', [StringComparison]::Ordinal)) { throw }
        Throw-Blocked -Message ("Unable to complete the read-only SQL Server/master preflight: {0}" -f $_.Exception.Message)
    }
    finally {
        $masterConnection.Dispose()
    }

    $applyOutput = Invoke-NativeCommand -Name 'Apply all EF Core migrations to new isolated database' -FilePath $dotnetEf.Source -Arguments (@('database', 'update') + $efCommonArguments)
    $initialHistory = @(Assert-MigrationHistory -Phase 'Initial full migration' -Expected $ExpectedMigrations)
    $Result.migrationHistory['initialFullMigration'] = $initialHistory
    $migrationListOutput = Invoke-NativeCommand -Name 'EF applied/pending migration report' -FilePath $dotnetEf.Source -Arguments (@('migrations', 'list') + $efCommonArguments)
    Assert-EfNoPendingMigrations -Output $migrationListOutput
    $initialSchema = Assert-Schema -Phase 'Initial full migration'

    $ids = @{
        CustomerA = [guid] '93000000-0000-0000-0000-000000000001'
        CustomerB = [guid] '93000000-0000-0000-0000-000000000002'
        ProjectA1 = [guid] '93000000-0000-0000-0000-000000000011'
        ProjectA2 = [guid] '93000000-0000-0000-0000-000000000012'
        ProjectB1 = [guid] '93000000-0000-0000-0000-000000000013'
        ServerA1 = [guid] '93000000-0000-0000-0000-000000000021'
        ServerA2 = [guid] '93000000-0000-0000-0000-000000000022'
        ServerB1 = [guid] '93000000-0000-0000-0000-000000000023'
        ServerCrossCustomerTarget = [guid] '93000000-0000-0000-0000-000000000024'
        ServerCrossProjectTarget = [guid] '93000000-0000-0000-0000-000000000025'
        ServerPortBelow = [guid] '93000000-0000-0000-0000-000000000026'
        ServerPortAbove = [guid] '93000000-0000-0000-0000-000000000027'
        ServerCrossCustomerDatabaseParent = [guid] '93000000-0000-0000-0000-000000000028'
        ServerCrossProjectDatabaseParent = [guid] '93000000-0000-0000-0000-000000000029'
        ServerNegativeSizeDatabaseParent = [guid] '93000000-0000-0000-0000-000000000030'
        ServerCompatibilityLowDatabaseParent = [guid] '93000000-0000-0000-0000-000000000031'
        ServerCompatibilityHighDatabaseParent = [guid] '93000000-0000-0000-0000-000000000032'
        ServerInstanceDuplicate = [guid] '93000000-0000-0000-0000-000000000033'
        ServerDatabaseDuplicateParent = [guid] '93000000-0000-0000-0000-000000000034'
        ServerUnicodeDatabaseParent = [guid] '93000000-0000-0000-0000-000000000035'
        ServerConcurrent = [guid] '93000000-0000-0000-0000-000000000036'
        ServerAlias = [guid] '93000000-0000-0000-0000-000000000037'
        InstanceA1 = [guid] '93000000-0000-0000-0000-000000000101'
        InstanceCrossCustomerDatabaseParent = [guid] '93000000-0000-0000-0000-000000000102'
        InstanceCrossProjectDatabaseParent = [guid] '93000000-0000-0000-0000-000000000103'
        InstanceNegativeSizeDatabaseParent = [guid] '93000000-0000-0000-0000-000000000104'
        InstanceCompatibilityLowDatabaseParent = [guid] '93000000-0000-0000-0000-000000000105'
        CaseInstance = [guid] '93000000-0000-0000-0000-000000000106'
        InstanceCompatibilityHighDatabaseParent = [guid] '93000000-0000-0000-0000-000000000107'
        ConcurrentInstance1 = [guid] '93000000-0000-0000-0000-000000000108'
        ConcurrentInstance2 = [guid] '93000000-0000-0000-0000-000000000109'
        InstanceDuplicateBaseline = [guid] '93000000-0000-0000-0000-000000000110'
        InstanceDatabaseDuplicateParent = [guid] '93000000-0000-0000-0000-000000000111'
        InstanceUnicodeDatabaseParent = [guid] '93000000-0000-0000-0000-000000000112'
        CrossCustomerInstanceAttempt = [guid] '93000000-0000-0000-0000-000000000201'
        CrossProjectInstanceAttempt = [guid] '93000000-0000-0000-0000-000000000202'
        PortBelowInstanceAttempt = [guid] '93000000-0000-0000-0000-000000000203'
        PortAboveInstanceAttempt = [guid] '93000000-0000-0000-0000-000000000204'
        InstanceDuplicateAttempt = [guid] '93000000-0000-0000-0000-000000000205'
        AliasInstanceAttempt = [guid] '93000000-0000-0000-0000-000000000207'
        CrossCustomerDatabaseAttempt = [guid] '93000000-0000-0000-0000-000000000301'
        CrossProjectDatabaseAttempt = [guid] '93000000-0000-0000-0000-000000000302'
        NegativeSizeDatabaseAttempt = [guid] '93000000-0000-0000-0000-000000000303'
        CompatibilityLowDatabaseAttempt = [guid] '93000000-0000-0000-0000-000000000304'
        CompatibilityHighDatabaseAttempt = [guid] '93000000-0000-0000-0000-000000000305'
        DatabaseDuplicateAttempt = [guid] '93000000-0000-0000-0000-000000000306'
        UnicodeDatabaseAttempt = [guid] '93000000-0000-0000-0000-000000000307'
        DatabaseA1 = [guid] '93000000-0000-0000-0000-000000000401'
        UnicodeDatabase = [guid] '93000000-0000-0000-0000-000000000402'
        DatabaseDuplicateBaseline = [guid] '93000000-0000-0000-0000-000000000403'
    }
    $fixtureIsolation = Assert-NegativeFixtureIsolation -Ids $ids
    Add-Step -Name 'Deterministic negative-fixture isolation' -Outcome PASS -Detail 'All identifiers are globally unique; each single-constraint probe has a unique normalized name and dedicated parent; intentional uniqueness pairs are explicit.' -Evidence $fixtureIsolation
    Seed-SyntheticParents -Ids $ids
    $constraintEvidence = Invoke-ConstraintAndRelationshipTests -Ids $ids
    $Result.concurrencyEvidence = Invoke-RowVersionTest -Ids $ids
    $Result.normalizationEvidence['sqlServer'] = Invoke-CollationAndNormalizationTest -Ids $ids
    $concurrentEvidence = Invoke-ConcurrentDuplicateTest -Ids $ids
    $Result.concurrencyEvidence['concurrentDuplicateCreate'] = $concurrentEvidence
    Add-Step -Name 'SQL Server relationship and constraint matrix' -Outcome PASS -Detail 'Valid relationships succeeded; cross-scope, range and normalized duplicate writes were rejected.' -Evidence $constraintEvidence

    $commonPlanParameters = @(
        (New-SqlParameterSpec -Name '@CustomerId' -Type UniqueIdentifier -Value $ids.CustomerA),
        (New-SqlParameterSpec -Name '@ProjectId' -Type UniqueIdentifier -Value $ids.ProjectA1),
        (New-SqlParameterSpec -Name '@Offset' -Type Int -Value 0),
        (New-SqlParameterSpec -Name '@PageSize' -Type Int -Value 50)
    )
    $null = Capture-ActualExecutionPlan -Name 'paged-sql-instances' -Sql @'
SELECT [Id], [ServerId], [InstanceName], [NormalizedInstanceName], [ServiceStatus], [RowVersion]
FROM [dbo].[SqlInstances]
WHERE [CustomerId] = @CustomerId AND [ProjectId] = @ProjectId AND [IsDeleted] = 0
ORDER BY [NormalizedInstanceName], [Id]
OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
'@ -Parameters $commonPlanParameters
    $null = Capture-ActualExecutionPlan -Name 'paged-sql-databases' -Sql @'
SELECT [Id], [SqlInstanceId], [Name], [NormalizedName], [Status], [RowVersion]
FROM [dbo].[SqlDatabases]
WHERE [CustomerId] = @CustomerId AND [ProjectId] = @ProjectId AND [IsDeleted] = 0
ORDER BY [NormalizedName], [Id]
OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
'@ -Parameters $commonPlanParameters
    $null = Capture-ActualExecutionPlan -Name 'server-instance-database-relationships' -Sql @'
SELECT s.[Id] AS [ServerId], i.[Id] AS [SqlInstanceId], d.[Id] AS [SqlDatabaseId]
FROM [dbo].[Servers] AS s
INNER JOIN [dbo].[SqlInstances] AS i
    ON i.[CustomerId] = s.[CustomerId] AND i.[ProjectId] = s.[ProjectId] AND i.[ServerId] = s.[Id]
LEFT JOIN [dbo].[SqlDatabases] AS d
    ON d.[CustomerId] = i.[CustomerId] AND d.[ProjectId] = i.[ProjectId]
   AND d.[SqlInstanceId] = i.[Id] AND d.[IsDeleted] = 0
WHERE s.[CustomerId] = @CustomerId AND s.[ProjectId] = @ProjectId AND i.[IsDeleted] = 0;
'@ -Parameters @(
        (New-SqlParameterSpec -Name '@CustomerId' -Type UniqueIdentifier -Value $ids.CustomerA),
        (New-SqlParameterSpec -Name '@ProjectId' -Type UniqueIdentifier -Value $ids.ProjectA1)
    )
    Add-Step -Name 'Actual SQL Server execution plans' -Outcome PASS -Detail 'Captured and analysed actual plans for paged instance/database lists and the relationship query.' -Evidence @($ExecutionPlans)

    $preRollbackHistory = @(Assert-MigrationHistory -Phase 'Pre-rollback safety gate' -Expected $ExpectedMigrations)
    $exactDatabase = [string] (Invoke-SqlScalar -Sql 'SELECT DB_NAME();')
    Assert-Condition -Condition ($exactDatabase -ceq $ExpectedDatabase) -Message 'Pre-rollback database identity changed unexpectedly.'
    $rollbackOutput = Invoke-NativeCommand -Name 'Rollback rehearsal to approved previous migration boundary' -FilePath $dotnetEf.Source -Arguments (@('database', 'update', $PreviousMigrationBoundary) + $efCommonArguments)
    $rollbackEvidence = Assert-RollbackBoundary
    $Result.migrationHistory['rollbackBoundary'] = $rollbackEvidence.history

    $reapplyOutput = Invoke-NativeCommand -Name 'Reapply all EF Core migrations after rollback' -FilePath $dotnetEf.Source -Arguments (@('database', 'update') + $efCommonArguments)
    $recoveredHistory = @(Assert-MigrationHistory -Phase 'Post-reapply recovery' -Expected $ExpectedMigrations)
    $Result.migrationHistory['postReapplyRecovery'] = $recoveredHistory
    $recoveredSchema = Assert-Schema -Phase 'Post-reapply recovery'
    $finalMigrationListOutput = Invoke-NativeCommand -Name 'Final EF applied/pending migration report' -FilePath $dotnetEf.Source -Arguments (@('migrations', 'list') + $efCommonArguments)
    Assert-EfNoPendingMigrations -Output $finalMigrationListOutput
    $finalDatabase = [string] (Invoke-SqlScalar -Sql 'SELECT DB_NAME();')
    Assert-Condition -Condition ($finalDatabase -ceq $ExpectedDatabase) -Message 'Final database identity changed unexpectedly.'
    $Result.databaseLeftFullyMigrated = $true
    Add-Step -Name 'Rollback/reapply recovery' -Outcome PASS -Detail 'The isolated database returned to the exact four-migration schema and is retained fully migrated for owner inspection.' -Evidence ([ordered]@{ rollback = $rollbackEvidence; finalHistory = $recoveredHistory })

    $Result.outcome = 'PASS'
    $Result.outcomeReason = 'All authorised PH3-SQL-001 Slice 1 SQL Server and regression assurance checks passed.'
    $ExitCode = 0
    Write-Evidence -Status PASS -Message 'PH3-SQL-001 Slice 1 assurance completed; the isolated database remains fully migrated for owner inspection.'
}
catch {
    Set-HarnessFailure -Exception $_.Exception
}
finally {
    Restore-ProcessEnvironment
    Set-Location -LiteralPath $PreviousLocation
    $Result.outcomeReason = ConvertTo-MeaningfulMessage `
        -Message ([string] $Result.outcomeReason) `
        -Fallback ("Harness ended with outcome '{0}' but did not provide a reason." -f $Result.outcome)
    $Result.completedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
    try {
        $json = $Result | ConvertTo-Json -Depth 20
        [System.IO.File]::WriteAllText($ResultPath, $json, (New-Object System.Text.UTF8Encoding($false)))
        Write-Evidence -Status INFO -Message ("Machine-readable result: {0}" -f $ResultPath)
    }
    catch {
        Write-Evidence -Status FAIL -Message ("Could not write machine-readable result: {0}" -f $_.Exception.Message)
        if ($ExitCode -eq 0) { $ExitCode = 1 }
    }
}

exit $ExitCode
