[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $EvidencePath,
    [Parameter(Mandatory)] [string] $ExpectedSourceCommit,
    [Parameter(Mandatory)] [string] $GrantsScriptPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ($ExpectedSourceCommit -notmatch '^[0-9a-f]{40}$') {
    throw 'SQL bootstrap evidence requires a full lowercase release commit.'
}

$resolvedEvidence = (Resolve-Path -LiteralPath $EvidencePath).Path
$resolvedScript = (Resolve-Path -LiteralPath $GrantsScriptPath).Path
$evidence = Get-Content -LiteralPath $resolvedEvidence -Raw | ConvertFrom-Json
$executorObjectId = [Guid]::Empty
$recordedAt = [DateTimeOffset]::MinValue

if ($evidence.schemaVersion -ne '1' -or
    $evidence.status -ne 'PASS' -or
    $evidence.sourceCommit -cne $ExpectedSourceCommit -or
    $evidence.sqlServerFqdn -ne 'sql-mtp-dev-uks-001.database.windows.net' -or
    $evidence.databaseName -ne 'sqldb-mtp-dev-uks-001' -or
    $evidence.migrationPrincipalName -ne 'id-mtp-migration-dev-uks-001' -or
    $evidence.migrationPrincipalClientId -ne 'f77b1931-0954-4ae9-8f6b-de5f9cfdb2e7' -or
    $evidence.migrationPrincipalObjectId -ne '9b984b84-7ebe-45ca-9441-7b2f41fd8f6c' -or
    -not [Guid]::TryParse([string] $evidence.executorPrincipalObjectId, [ref] $executorObjectId) -or
    $executorObjectId -eq [Guid]::Empty -or
    [string]::IsNullOrWhiteSpace([string] $evidence.evidenceId) -or
    [string]::IsNullOrWhiteSpace([string] $evidence.approvalReference) -or
    -not [DateTimeOffset]::TryParse([string] $evidence.recordedAtUtc, [ref] $recordedAt) -or
    -not [string]::Equals((Get-FileHash -LiteralPath $resolvedScript -Algorithm SHA256).Hash, [string] $evidence.grantsScriptSha256, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Independent SQL bootstrap evidence is absent, stale or does not match the approved principals and grants script.'
}

Write-Output 'Independent SQL Entra-administrator bootstrap evidence passed.'
