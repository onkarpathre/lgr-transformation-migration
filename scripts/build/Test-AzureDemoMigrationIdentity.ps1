[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$guard = Join-Path $PSScriptRoot '..\database\Assert-AzureDemoMigrationIdentity.ps1'
$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-migration-identity-{0}" -f [Guid]::NewGuid().ToString('N'))
$commit = '0123456789abcdef0123456789abcdef01234567'
$tenantId = '11111111-2222-4333-8444-555555555555'
$clientId = 'f77b1931-0954-4ae9-8f6b-de5f9cfdb2e7'
$objectId = '9b984b84-7ebe-45ca-9441-7b2f41fd8f6c'
$migrationVariables = @(
    'AZDEMO_MIGRATION_PRINCIPAL_CLIENT_ID',
    'AZDEMO_MIGRATION_PRINCIPAL_NAME',
    'AZDEMO_MIGRATION_PRINCIPAL_OBJECT_ID',
    'AZDEMO_MIGRATION_WIF_SERVICE_CONNECTION'
)
$savedEnvironment = @{}
foreach ($name in $migrationVariables) {
    $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, [EnvironmentVariableTarget]::Process)
}

function ConvertTo-Base64Url([string] $Value) {
    return [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Value)).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

function New-TestToken([string] $TokenClientId = $clientId, [string] $TokenObjectId = $objectId, [string] $TokenTenantId = $tenantId, [string] $Audience = 'https://database.windows.net/') {
    $header = ConvertTo-Base64Url '{"alg":"none","typ":"JWT"}'
    $payload = ConvertTo-Base64Url ([ordered]@{ azp = $TokenClientId; oid = $TokenObjectId; tid = $TokenTenantId; aud = $Audience } | ConvertTo-Json -Compress)
    return "$header.$payload.synthetic-signature"
}

function Invoke-Guard([hashtable] $Overrides = @{}) {
    $arguments = @{
        AuthenticatedClientId = $clientId
        AuthenticatedObjectId = $objectId
        AuthenticatedTenantId = $tenantId
        AccessToken = (New-TestToken)
        ExpectedTenantId = $tenantId
        ServiceConnectionName = 'sc-mtp-azure-demo-migration-dev-v2'
        SourceBranch = 'refs/heads/release/azure-demo-v1'
        ReleaseCommit = $commit
        MigrationManifestPath = (Join-Path $temporaryDirectory 'migration-manifest.json')
        SqlServerFqdn = 'sql-mtp-dev-uks-001.database.windows.net'
        DatabaseName = 'sqldb-mtp-dev-uks-001'
        ResourceGroupName = 'Onkar.Pathre'
    }
    foreach ($key in $Overrides.Keys) { $arguments[$key] = $Overrides[$key] }
    & $guard @arguments | Out-Null
}

New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null
try {
    $env:AZDEMO_MIGRATION_PRINCIPAL_CLIENT_ID = $clientId
    $env:AZDEMO_MIGRATION_PRINCIPAL_NAME = 'id-mtp-migration-dev-uks-001'
    $env:AZDEMO_MIGRATION_PRINCIPAL_OBJECT_ID = $objectId
    $env:AZDEMO_MIGRATION_WIF_SERVICE_CONNECTION = 'sc-mtp-azure-demo-migration-dev-v2'
    $bundlePath = Join-Path $temporaryDirectory 'lgrtm-efbundle-linux-x64'
    $scriptPath = Join-Path $temporaryDirectory 'lgrtm-migrations-idempotent.sql'
    Set-Content -LiteralPath $bundlePath -Value 'synthetic bundle' -NoNewline
    Set-Content -LiteralPath $scriptPath -Value 'synthetic SQL' -NoNewline
    $manifest = [ordered]@{
        schemaVersion = '1'
        sourceCommit = $commit
        targetRuntime = 'linux-x64'
        startupMigration = $false
        rollbackPolicy = 'forward-fix-or-approved-PITR-to-new-database'
        migrations = @('SyntheticMigration')
        artifacts = @(
            [ordered]@{ name = 'lgrtm-efbundle-linux-x64'; sha256 = (Get-FileHash $bundlePath -Algorithm SHA256).Hash.ToLowerInvariant() }
            [ordered]@{ name = 'lgrtm-migrations-idempotent.sql'; sha256 = (Get-FileHash $scriptPath -Algorithm SHA256).Hash.ToLowerInvariant() }
        )
    }
    $manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $temporaryDirectory 'migration-manifest.json') -Encoding UTF8

    Invoke-Guard
    $invalidCases = @(
        @{ AuthenticatedClientId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' },
        @{ AuthenticatedObjectId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' },
        @{ AuthenticatedTenantId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc' },
        @{ AccessToken = (New-TestToken -TokenClientId 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') },
        @{ AccessToken = (New-TestToken -TokenObjectId 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb') },
        @{ AccessToken = (New-TestToken -TokenTenantId 'cccccccc-cccc-4ccc-8ccc-cccccccccccc') },
        @{ AccessToken = (New-TestToken -Audience 'https://management.azure.com/') },
        @{ ServiceConnectionName = 'sc-mtp-azure-demo-migration-dev' },
        @{ ServiceConnectionName = 'sc-mtp-azure-demo-dev' },
        @{ SourceBranch = 'refs/heads/fix/mtp-azure-demo-reconciliation' },
        @{ ReleaseCommit = 'short' },
        @{ SqlServerFqdn = 'sql-other.database.windows.net' },
        @{ DatabaseName = 'sqldb-other' },
        @{ ResourceGroupName = 'other-rg' }
    )
    foreach ($invalidCase in $invalidCases) {
        $accepted = $false
        try {
            Invoke-Guard $invalidCase
            $accepted = $true
        }
        catch {
            if ($_.Exception.Message.Contains((New-TestToken))) {
                throw 'Migration identity guard disclosed an access token in its rejection.'
            }
        }
        if ($accepted) { throw 'Migration identity guard accepted an invalid identity or deployment target.' }
    }

    $manifest.sourceCommit = 'fedcba9876543210fedcba9876543210fedcba98'
    $manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $temporaryDirectory 'migration-manifest.json') -Encoding UTF8
    $acceptedManifest = $false
    try { Invoke-Guard; $acceptedManifest = $true } catch { }
    if ($acceptedManifest) { throw 'Migration identity guard accepted a manifest for a different release commit.' }
}
finally {
    foreach ($name in $migrationVariables) {
        [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name], [EnvironmentVariableTarget]::Process)
    }
    if (Test-Path -LiteralPath $temporaryDirectory) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
}

Write-Output "Azure demo migration identity guard passed one valid and $($invalidCases.Count + 1) fail-closed cases."
