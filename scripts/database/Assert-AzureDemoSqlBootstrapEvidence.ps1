[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $EvidencePath,
    [Parameter(Mandatory)] [string] $ExpectedReleaseCommit,
    [Parameter(Mandatory)] [string] $RepositoryRoot,
    [Parameter(Mandatory)] [string] $GrantsScriptPath,
    [Parameter(Mandatory)] [Guid] $ExpectedExecutorPrincipalObjectId,
    [ValidateRange(1, 90)] [int] $MaximumEvidenceAgeDays = 90,
    [string] $GitExecutablePath = 'git'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$clockSkewTolerance = [TimeSpan]::FromMinutes(5)
$fullCommitPattern = '^[0-9a-f]{40}$'
$sha256Pattern = '^[0-9a-f]{64}$'

function Invoke-GitValidation([string[]] $Arguments) {
    try {
        $git = Get-Command -Name $GitExecutablePath -CommandType Application -ErrorAction Stop
    }
    catch {
        throw 'SQL bootstrap evidence ancestry validation requires an available native Git executable.'
    }

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& $git.Source @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    catch {
        throw 'SQL bootstrap evidence Git validation could not be executed.'
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = @($output | ForEach-Object { [string] $_ })
    }
}

function Require-SuccessfulGit([string[]] $Arguments, [string] $FailureMessage) {
    $result = Invoke-GitValidation $Arguments
    if ($result.ExitCode -ne 0) {
        throw $FailureMessage
    }
    return $result
}

if ($ExpectedReleaseCommit -cnotmatch $fullCommitPattern) {
    throw 'SQL bootstrap evidence requires a full lowercase expected release commit.'
}
if ($ExpectedExecutorPrincipalObjectId -eq [Guid]::Empty) {
    throw 'SQL bootstrap evidence requires the exact non-empty executor SQL-administrator object ID.'
}

$resolvedEvidence = (Resolve-Path -LiteralPath $EvidencePath).Path
$resolvedRepository = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$resolvedScript = (Resolve-Path -LiteralPath $GrantsScriptPath).Path
$evidence = Get-Content -LiteralPath $resolvedEvidence -Raw | ConvertFrom-Json
$executorObjectId = [Guid]::Empty
$recordedAt = [DateTimeOffset]::MinValue
$recordedAtText = [string] $evidence.recordedAtUtc
$timestampFormats = [string[]] @("yyyy-MM-dd'T'HH:mm:ss'Z'", "yyyy-MM-dd'T'HH:mm:ss.FFFFFFF'Z'")
$timestampStyles = [Globalization.DateTimeStyles]::AssumeUniversal -bor [Globalization.DateTimeStyles]::AdjustToUniversal
$timestampIsUtc = $recordedAtText -match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,7})?Z$' -and
    [DateTimeOffset]::TryParseExact($recordedAtText, $timestampFormats, [Globalization.CultureInfo]::InvariantCulture, $timestampStyles, [ref] $recordedAt)
$now = [DateTimeOffset]::UtcNow
$currentGrantsHash = (Get-FileHash -LiteralPath $resolvedScript -Algorithm SHA256).Hash.ToLowerInvariant()

if ($evidence.schemaVersion -cne '1' -or
    $evidence.status -cne 'PASS' -or
    [string] $evidence.sourceCommit -cnotmatch $fullCommitPattern -or
    $evidence.sqlServerFqdn -ne 'sql-mtp-dev-uks-001.database.windows.net' -or
    $evidence.databaseName -ne 'sqldb-mtp-dev-uks-001' -or
    $evidence.migrationPrincipalName -ne 'id-mtp-migration-dev-uks-001' -or
    $evidence.migrationPrincipalClientId -ne 'f77b1931-0954-4ae9-8f6b-de5f9cfdb2e7' -or
    $evidence.migrationPrincipalObjectId -ne '9b984b84-7ebe-45ca-9441-7b2f41fd8f6c' -or
    -not [Guid]::TryParse([string] $evidence.executorPrincipalObjectId, [ref] $executorObjectId) -or
    $executorObjectId -ne $ExpectedExecutorPrincipalObjectId -or
    [string]::IsNullOrWhiteSpace([string] $evidence.evidenceId) -or
    [string]::IsNullOrWhiteSpace([string] $evidence.approvalReference) -or
    -not $timestampIsUtc -or
    $recordedAt -gt $now.Add($clockSkewTolerance) -or
    $recordedAt -lt $now.AddDays(-$MaximumEvidenceAgeDays).Subtract($clockSkewTolerance) -or
    [string] $evidence.grantsScriptSha256 -cnotmatch $sha256Pattern -or
    [string] $evidence.grantsScriptSha256 -cne $currentGrantsHash) {
    throw 'Independent SQL bootstrap evidence is absent, expired, stale or does not match the approved target, principals and grants script.'
}

$repositoryCheck = Require-SuccessfulGit @('-C', $resolvedRepository, 'rev-parse', '--is-inside-work-tree') 'SQL bootstrap evidence ancestry validation requires a complete checked-out Git repository.'
if (($repositoryCheck.Output -join '').Trim() -cne 'true') {
    throw 'SQL bootstrap evidence ancestry validation requires a complete checked-out Git repository.'
}

$shallowCheck = Require-SuccessfulGit @('-C', $resolvedRepository, 'rev-parse', '--is-shallow-repository') 'SQL bootstrap evidence ancestry validation could not determine repository history completeness.'
if (($shallowCheck.Output -join '').Trim() -cne 'false') {
    throw 'SQL bootstrap evidence ancestry validation rejects shallow or incomplete repository history.'
}

$headCheck = Require-SuccessfulGit @('-C', $resolvedRepository, 'rev-parse', '--verify', 'HEAD^{commit}') 'SQL bootstrap evidence ancestry validation could not resolve the checked-out release commit.'
if (($headCheck.Output -join '').Trim() -cne $ExpectedReleaseCommit) {
    throw 'The checked-out repository HEAD does not match the immutable expected release commit.'
}

Require-SuccessfulGit @('-C', $resolvedRepository, 'cat-file', '-e', "$($evidence.sourceCommit)^{commit}") 'The SQL bootstrap evidence provenance commit is missing from the checked-out repository.' | Out-Null
Require-SuccessfulGit @('-C', $resolvedRepository, 'cat-file', '-e', "$ExpectedReleaseCommit^{commit}") 'The expected release commit is missing from the checked-out repository.' | Out-Null

$ancestry = Invoke-GitValidation @('-C', $resolvedRepository, 'merge-base', '--is-ancestor', [string] $evidence.sourceCommit, $ExpectedReleaseCommit)
switch ($ancestry.ExitCode) {
    0 { }
    1 { throw 'The SQL bootstrap evidence provenance commit is not an ancestor of the expected release commit.' }
    default { throw 'SQL bootstrap evidence ancestry validation failed.' }
}

Write-Output 'Independent durable SQL Entra-administrator bootstrap evidence passed.'
