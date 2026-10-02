[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$guard = Join-Path $PSScriptRoot '..\database\Assert-AzureDemoSqlBootstrapEvidence.ps1'
$grantsScript = Join-Path $PSScriptRoot '..\database\Configure-AzureDemoDatabasePrincipals.sql'
$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-bootstrap-evidence-{0}" -f [Guid]::NewGuid().ToString('N'))
$evidencePath = Join-Path $temporaryDirectory 'sql-bootstrap.json'
$commit = '0123456789abcdef0123456789abcdef01234567'

function Write-Evidence([hashtable] $Overrides = @{}) {
    $evidence = [ordered]@{
        schemaVersion = '1'
        status = 'PASS'
        sourceCommit = $commit
        sqlServerFqdn = 'sql-mtp-dev-uks-001.database.windows.net'
        databaseName = 'sqldb-mtp-dev-uks-001'
        migrationPrincipalName = 'id-mtp-migration-dev-uks-001'
        migrationPrincipalClientId = 'f77b1931-0954-4ae9-8f6b-de5f9cfdb2e7'
        migrationPrincipalObjectId = '9b984b84-7ebe-45ca-9441-7b2f41fd8f6c'
        executorPrincipalObjectId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
        evidenceId = 'SYNTHETIC-DBA-EVIDENCE'
        approvalReference = 'SYNTHETIC-DBA-APPROVAL'
        recordedAtUtc = [DateTimeOffset]::UtcNow.ToString('O')
        grantsScriptSha256 = (Get-FileHash -LiteralPath $grantsScript -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    foreach ($key in $Overrides.Keys) { $evidence[$key] = $Overrides[$key] }
    $evidence | ConvertTo-Json | Set-Content -LiteralPath $evidencePath -Encoding UTF8
}

New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null
try {
    Write-Evidence
    & $guard -EvidencePath $evidencePath -ExpectedSourceCommit $commit -GrantsScriptPath $grantsScript | Out-Null
    $invalidCases = @(
        @{ status = 'PENDING' },
        @{ sourceCommit = 'fedcba9876543210fedcba9876543210fedcba98' },
        @{ migrationPrincipalName = 'id-other' },
        @{ migrationPrincipalClientId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' },
        @{ migrationPrincipalObjectId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc' },
        @{ grantsScriptSha256 = ('0' * 64) }
    )
    foreach ($invalidCase in $invalidCases) {
        Write-Evidence $invalidCase
        $accepted = $false
        try {
            & $guard -EvidencePath $evidencePath -ExpectedSourceCommit $commit -GrantsScriptPath $grantsScript | Out-Null
            $accepted = $true
        }
        catch { }
        if ($accepted) { throw 'SQL bootstrap evidence guard accepted stale or substituted evidence.' }
    }
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
}

Write-Output "Azure demo SQL bootstrap evidence guard passed one valid and $($invalidCases.Count) fail-closed cases."
