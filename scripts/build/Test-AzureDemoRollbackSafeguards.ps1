[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$guard = Join-Path $PSScriptRoot 'Assert-AzureDemoRollbackTarget.ps1'
$release = '38add95edf8b63a552a29a6d6625336de92ea896'
$valid = @{
    SourceBranch = 'refs/heads/release/azure-demo-v1'
    SourceVersion = $release
    ReleaseIdentifier = $release
    DeploymentEnvironmentName = 'mtp-azure-demo-dev'
    ResourceGroupName = 'Onkar.Pathre'
    WebAppName = 'app-mtp-web-dev-uks-001'
    ExpectedWebAppName = 'app-mtp-web-dev-uks-001'
    ApiAppName = 'app-mtp-api-dev-uks-001'
    ExpectedApiAppName = 'app-mtp-api-dev-uks-001'
    WebSlotName = 'staging'
    ApiSlotName = 'staging'
    TargetSlotName = 'production'
}

& $guard @valid | Out-Null

$negativeCases = @(
    @{ Name = 'wrong branch'; Key = 'SourceBranch'; Value = 'refs/heads/main' },
    @{ Name = 'missing immutable release identifier'; Key = 'ReleaseIdentifier'; Value = 'not-a-release' },
    @{ Name = 'mismatched immutable release identifier'; Key = 'ReleaseIdentifier'; Value = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' },
    @{ Name = 'production environment'; Key = 'DeploymentEnvironmentName'; Value = 'production' },
    @{ Name = 'incorrect resource group'; Key = 'ResourceGroupName'; Value = 'unrelated-rg' },
    @{ Name = 'unrelated web application'; Key = 'WebAppName'; Value = 'app-other-web' },
    @{ Name = 'unrelated API application'; Key = 'ApiAppName'; Value = 'app-other-api' },
    @{ Name = 'unapproved expected web application'; Key = 'ExpectedWebAppName'; Value = 'app-unapproved-web-dev-uks-001' },
    @{ Name = 'unapproved expected API application'; Key = 'ExpectedApiAppName'; Value = 'app-unapproved-api-dev-uks-001' },
    @{ Name = 'incorrect web source slot'; Key = 'WebSlotName'; Value = 'production' },
    @{ Name = 'incorrect API source slot'; Key = 'ApiSlotName'; Value = 'production' },
    @{ Name = 'incorrect target slot'; Key = 'TargetSlotName'; Value = 'staging' }
)

foreach ($case in $negativeCases) {
    $arguments = @{} + $valid
    $arguments[$case.Key] = $case.Value
    $accepted = $false
    try {
        & $guard @arguments | Out-Null
        $accepted = $true
    }
    catch {
        # Rejection is the required fail-closed result.
    }
    if ($accepted) {
        throw "Rollback safeguard accepted $($case.Name)."
    }
}

Write-Output "Azure demo rollback safeguards passed one valid and $($negativeCases.Count) fail-closed target cases."
