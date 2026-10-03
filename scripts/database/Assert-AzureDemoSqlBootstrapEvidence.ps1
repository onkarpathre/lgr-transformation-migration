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
$timestampPattern = '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{1,7})?Z$'
$timestampFormats = [string[]] @(
    "yyyy-MM-dd'T'HH:mm:ss'Z'",
    "yyyy-MM-dd'T'HH:mm:ss.f'Z'",
    "yyyy-MM-dd'T'HH:mm:ss.ff'Z'",
    "yyyy-MM-dd'T'HH:mm:ss.fff'Z'",
    "yyyy-MM-dd'T'HH:mm:ss.ffff'Z'",
    "yyyy-MM-dd'T'HH:mm:ss.fffff'Z'",
    "yyyy-MM-dd'T'HH:mm:ss.ffffff'Z'",
    "yyyy-MM-dd'T'HH:mm:ss.fffffff'Z'"
)
$timestampStyles = [Globalization.DateTimeStyles]::AssumeUniversal -bor [Globalization.DateTimeStyles]::AdjustToUniversal

function Deny-Metadata([string] $ReasonCode) {
    throw "Independent SQL bootstrap evidence rejected: $ReasonCode."
}

function Get-EvidencePropertyValue([object] $Evidence, [string] $PropertyName) {
    $property = $Evidence.PSObject.Properties[$PropertyName]
    if ($null -eq $property) {
        return $null
    }
    return $property.Value
}

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

$resolvedRepository = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$resolvedScript = (Resolve-Path -LiteralPath $GrantsScriptPath).Path
try {
    $resolvedEvidence = (Resolve-Path -LiteralPath $EvidencePath).Path
    $evidenceJson = Get-Content -LiteralPath $resolvedEvidence -Raw
}
catch {
    throw 'Independent SQL bootstrap evidence rejected: EVIDENCE_FILE_UNAVAILABLE.'
}
try {
    $evidence = $evidenceJson | ConvertFrom-Json
}
catch {
    throw 'Independent SQL bootstrap evidence rejected: EVIDENCE_JSON_SYNTAX.'
}

if ($null -eq $evidence -or -not [string]::Equals([string] (Get-EvidencePropertyValue $evidence 'schemaVersion'), '1', [StringComparison]::Ordinal)) {
    Deny-Metadata 'METADATA_SCHEMA_VERSION'
}
if (-not [string]::Equals([string] (Get-EvidencePropertyValue $evidence 'status'), 'PASS', [StringComparison]::Ordinal)) {
    Deny-Metadata 'METADATA_STATUS'
}

$sourceCommit = [string] (Get-EvidencePropertyValue $evidence 'sourceCommit')
if ($sourceCommit -cnotmatch $fullCommitPattern) {
    Deny-Metadata 'METADATA_SOURCE_COMMIT_FORMAT'
}
if (-not [string]::Equals([string] (Get-EvidencePropertyValue $evidence 'sqlServerFqdn'), 'sql-mtp-dev-uks-001.database.windows.net', [StringComparison]::Ordinal)) {
    Deny-Metadata 'METADATA_SQL_SERVER'
}
if (-not [string]::Equals([string] (Get-EvidencePropertyValue $evidence 'databaseName'), 'sqldb-mtp-dev-uks-001', [StringComparison]::Ordinal)) {
    Deny-Metadata 'METADATA_DATABASE'
}
if (-not [string]::Equals([string] (Get-EvidencePropertyValue $evidence 'migrationPrincipalName'), 'id-mtp-migration-dev-uks-001', [StringComparison]::Ordinal)) {
    Deny-Metadata 'METADATA_MIGRATION_IDENTITY_NAME'
}
if (-not [string]::Equals([string] (Get-EvidencePropertyValue $evidence 'migrationPrincipalClientId'), 'f77b1931-0954-4ae9-8f6b-de5f9cfdb2e7', [StringComparison]::Ordinal)) {
    Deny-Metadata 'METADATA_MIGRATION_CLIENT_ID'
}
if (-not [string]::Equals([string] (Get-EvidencePropertyValue $evidence 'migrationPrincipalObjectId'), '9b984b84-7ebe-45ca-9441-7b2f41fd8f6c', [StringComparison]::Ordinal)) {
    Deny-Metadata 'METADATA_MIGRATION_OBJECT_ID'
}

$executorObjectIdText = [string] (Get-EvidencePropertyValue $evidence 'executorPrincipalObjectId')
[Guid] $executorObjectId = [Guid]::Empty
[Guid] $expectedExecutorObjectId = $ExpectedExecutorPrincipalObjectId
$executorObjectIdParsed = -not [string]::IsNullOrWhiteSpace($executorObjectIdText) -and
    [Guid]::TryParse($executorObjectIdText, [ref] $executorObjectId)
if (-not $executorObjectIdParsed -or $executorObjectId -eq [Guid]::Empty) {
    Deny-Metadata 'METADATA_EXECUTOR_OBJECT_ID_FORMAT'
}
if ($executorObjectId -ne $expectedExecutorObjectId) {
    Deny-Metadata 'METADATA_EXECUTOR_OBJECT_ID_MISMATCH'
}
if ([string]::IsNullOrWhiteSpace([string] (Get-EvidencePropertyValue $evidence 'evidenceId'))) {
    Deny-Metadata 'METADATA_EVIDENCE_ID'
}
if ([string]::IsNullOrWhiteSpace([string] (Get-EvidencePropertyValue $evidence 'approvalReference'))) {
    Deny-Metadata 'METADATA_APPROVAL_REFERENCE'
}

# PowerShell 7 converts ISO-8601 JSON strings to DateTime objects. Validate and
# parse the original JSON token so its literal trailing Z and exact syntax are
# preserved consistently with Windows PowerShell 5.1.
$timestampPropertyMatches = [regex]::Matches(
    $evidenceJson,
    '(?<!\\)"recordedAtUtc"\s*:',
    [Text.RegularExpressions.RegexOptions]::CultureInvariant
)
$timestampTokenMatches = [regex]::Matches(
    $evidenceJson,
    '(?<!\\)"recordedAtUtc"\s*:\s*"(?<timestamp>[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{1,7})?Z)"',
    [Text.RegularExpressions.RegexOptions]::CultureInvariant
)
$recordedAtProperty = $evidence.PSObject.Properties['recordedAtUtc']
if ($null -eq $recordedAtProperty -or $timestampPropertyMatches.Count -ne 1 -or $timestampTokenMatches.Count -ne 1) {
    Deny-Metadata 'METADATA_UTC_TIMESTAMP_SYNTAX'
}
$recordedAtText = $timestampTokenMatches[0].Groups['timestamp'].Value
[DateTimeOffset] $recordedAt = [DateTimeOffset]::MinValue
$timestampParsed = $recordedAtText -cmatch $timestampPattern -and
    [DateTimeOffset]::TryParseExact(
        $recordedAtText,
        $timestampFormats,
        [Globalization.CultureInfo]::InvariantCulture,
        $timestampStyles,
        [ref] $recordedAt
    )
if (-not $timestampParsed) {
    Deny-Metadata 'METADATA_UTC_TIMESTAMP_SYNTAX'
}

$now = [DateTimeOffset]::UtcNow
if ($recordedAt -gt $now.Add($clockSkewTolerance)) {
    Deny-Metadata 'METADATA_FUTURE_TIMESTAMP'
}
if ($recordedAt -lt $now.AddDays(-$MaximumEvidenceAgeDays).Subtract($clockSkewTolerance)) {
    Deny-Metadata 'METADATA_EXPIRED_TIMESTAMP'
}

$currentGrantsHash = (Get-FileHash -LiteralPath $resolvedScript -Algorithm SHA256).Hash.ToLowerInvariant()
$grantsScriptHash = [string] (Get-EvidencePropertyValue $evidence 'grantsScriptSha256')
if ($grantsScriptHash -cnotmatch $sha256Pattern) {
    Deny-Metadata 'METADATA_GRANTS_HASH_FORMAT'
}
if (-not [string]::Equals($grantsScriptHash, $currentGrantsHash, [StringComparison]::Ordinal)) {
    Deny-Metadata 'METADATA_GRANTS_HASH_MISMATCH'
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

Require-SuccessfulGit @('-C', $resolvedRepository, 'cat-file', '-e', "$sourceCommit^{commit}") 'The SQL bootstrap evidence provenance commit is missing from the checked-out repository.' | Out-Null
Require-SuccessfulGit @('-C', $resolvedRepository, 'cat-file', '-e', "$ExpectedReleaseCommit^{commit}") 'The expected release commit is missing from the checked-out repository.' | Out-Null

$ancestry = Invoke-GitValidation @('-C', $resolvedRepository, 'merge-base', '--is-ancestor', $sourceCommit, $ExpectedReleaseCommit)
switch ($ancestry.ExitCode) {
    0 { }
    1 { throw 'The SQL bootstrap evidence provenance commit is not an ancestor of the expected release commit.' }
    default { throw 'SQL bootstrap evidence ancestry validation failed.' }
}

Write-Output 'Independent durable SQL Entra-administrator bootstrap evidence passed.'
