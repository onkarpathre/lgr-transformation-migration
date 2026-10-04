[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $AuthenticatedClientId,
    [Parameter(Mandatory)] [string] $AuthenticatedObjectId,
    [Parameter(Mandatory)] [string] $AuthenticatedTenantId,
    [Parameter(Mandatory)] [string] $AccessToken,
    [Parameter(Mandatory)] [string] $ExpectedTenantId,
    [Parameter(Mandatory)] [string] $ServiceConnectionName,
    [Parameter(Mandatory)] [string] $SourceBranch,
    [Parameter(Mandatory)] [string] $ReleaseCommit,
    [Parameter(Mandatory)] [string] $MigrationManifestPath,
    [Parameter(Mandatory)] [string] $SqlServerFqdn,
    [Parameter(Mandatory)] [string] $DatabaseName,
    [Parameter(Mandatory)] [string] $ResourceGroupName
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$expectedClientId = 'f77b1931-0954-4ae9-8f6b-de5f9cfdb2e7'
$expectedObjectId = '9b984b84-7ebe-45ca-9441-7b2f41fd8f6c'
$expectedPrincipalName = 'id-mtp-migration-dev-uks-001'
$expectedServiceConnection = 'sc-mtp-azure-demo-migration-dev-v2'
$expectedBranch = 'refs/heads/release/azure-demo-v1'
$expectedServer = 'sql-mtp-dev-uks-001.database.windows.net'
$expectedDatabase = 'sqldb-mtp-dev-uks-001'
$expectedResourceGroup = 'Onkar.Pathre'

if (-not [string]::Equals($env:AZDEMO_MIGRATION_PRINCIPAL_CLIENT_ID, $expectedClientId, [StringComparison]::OrdinalIgnoreCase) -or
    -not [string]::Equals($env:AZDEMO_MIGRATION_PRINCIPAL_NAME, $expectedPrincipalName, [StringComparison]::Ordinal) -or
    -not [string]::Equals($env:AZDEMO_MIGRATION_PRINCIPAL_OBJECT_ID, $expectedObjectId, [StringComparison]::OrdinalIgnoreCase) -or
    -not [string]::Equals($env:AZDEMO_MIGRATION_WIF_SERVICE_CONNECTION, $expectedServiceConnection, [StringComparison]::Ordinal)) {
    throw 'Migration identity guard rejected missing or substituted approved migration variables.'
}

function Assert-ExactGuid([string] $Name, [string] $Actual, [string] $Expected) {
    $parsed = [Guid]::Empty
    if (-not [Guid]::TryParse($Actual, [ref] $parsed) -or
        -not [string]::Equals($parsed.ToString(), $Expected, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Migration identity guard rejected the $Name."
    }
}

function ConvertFrom-Base64Url([string] $Value) {
    $base64 = $Value.Replace('-', '+').Replace('_', '/')
    $remainder = $base64.Length % 4
    if ($remainder -ne 0) {
        $base64 += '=' * (4 - $remainder)
    }
    try {
        return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($base64))
    }
    catch {
        throw 'Migration identity guard rejected an invalid access-token payload.'
    }
}

Assert-ExactGuid 'authenticated client ID' $AuthenticatedClientId $expectedClientId
Assert-ExactGuid 'authenticated object ID' $AuthenticatedObjectId $expectedObjectId
Assert-ExactGuid 'authenticated tenant ID' $AuthenticatedTenantId $ExpectedTenantId

if (-not [string]::Equals($ServiceConnectionName, $expectedServiceConnection, [StringComparison]::Ordinal) -or
    -not [string]::Equals($SourceBranch, $expectedBranch, [StringComparison]::Ordinal) -or
    -not [string]::Equals($SqlServerFqdn, $expectedServer, [StringComparison]::OrdinalIgnoreCase) -or
    -not [string]::Equals($DatabaseName, $expectedDatabase, [StringComparison]::Ordinal) -or
    -not [string]::Equals($ResourceGroupName, $expectedResourceGroup, [StringComparison]::Ordinal)) {
    throw 'Migration identity guard rejected an unapproved service connection, branch, SQL target or resource group.'
}

if ($ReleaseCommit -notmatch '^[0-9a-f]{40}$') {
    throw 'Migration identity guard requires a full lowercase release commit.'
}

$tokenParts = @($AccessToken.Split('.'))
if ($tokenParts.Count -ne 3) {
    throw 'Migration identity guard rejected an invalid access token.'
}
try {
    $claims = ConvertFrom-Base64Url $tokenParts[1] | ConvertFrom-Json
}
catch {
    throw 'Migration identity guard rejected an unreadable access-token payload.'
}

$tokenClientId = if ($claims.PSObject.Properties.Name -contains 'azp' -and -not [string]::IsNullOrWhiteSpace([string] $claims.azp)) {
    [string] $claims.azp
} else {
    [string] $claims.appid
}
$audience = [string] $claims.aud
Assert-ExactGuid 'token client ID' $tokenClientId $expectedClientId
Assert-ExactGuid 'token object ID' ([string] $claims.oid) $expectedObjectId
Assert-ExactGuid 'token tenant ID' ([string] $claims.tid) $ExpectedTenantId
if (-not [string]::Equals($audience.TrimEnd('/'), 'https://database.windows.net', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Migration identity guard rejected an access token for the wrong audience.'
}

$manifestPath = (Resolve-Path -LiteralPath $MigrationManifestPath).Path
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($manifest.schemaVersion -ne '1' -or
    $manifest.sourceCommit -cne $ReleaseCommit -or
    $manifest.targetRuntime -ne 'linux-x64' -or
    $manifest.startupMigration -ne $false -or
    $manifest.rollbackPolicy -ne 'forward-fix-or-approved-PITR-to-new-database' -or
    @($manifest.migrations).Count -lt 1) {
    throw 'Migration identity guard rejected a migration manifest outside the approved release contract.'
}

$expectedArtifacts = @('lgrtm-efbundle-linux-x64', 'lgrtm-migrations-idempotent.sql')
$artifacts = @($manifest.artifacts)
if ($artifacts.Count -ne $expectedArtifacts.Count -or
    @($artifacts | Where-Object { $_.name -notin $expectedArtifacts }).Count -ne 0) {
    throw 'Migration identity guard rejected an unexpected migration artifact set.'
}
foreach ($artifact in $artifacts) {
    $artifactPath = Join-Path (Split-Path -Parent $manifestPath) ([string] $artifact.name)
    if (-not (Test-Path -LiteralPath $artifactPath -PathType Leaf) -or
        [string] $artifact.sha256 -notmatch '^[0-9a-f]{64}$' -or
        -not [string]::Equals((Get-FileHash -LiteralPath $artifactPath -Algorithm SHA256).Hash, [string] $artifact.sha256, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Migration identity guard rejected a missing or hash-mismatched migration artifact.'
    }
}

Write-Output 'Migration identity, tenant, release and artifact guard passed.'
