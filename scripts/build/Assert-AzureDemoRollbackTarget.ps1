[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $SourceBranch,
    [Parameter(Mandatory = $true)][string] $SourceVersion,
    [Parameter(Mandatory = $true)][string] $ReleaseIdentifier,
    [Parameter(Mandatory = $true)][string] $DeploymentEnvironmentName,
    [Parameter(Mandatory = $true)][string] $ResourceGroupName,
    [Parameter(Mandatory = $true)][string] $WebAppName,
    [Parameter(Mandatory = $true)][string] $ExpectedWebAppName,
    [Parameter(Mandatory = $true)][string] $ApiAppName,
    [Parameter(Mandatory = $true)][string] $ExpectedApiAppName,
    [Parameter(Mandatory = $true)][string] $WebSlotName,
    [Parameter(Mandatory = $true)][string] $ApiSlotName,
    [Parameter(Mandatory = $true)][string] $TargetSlotName
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Assert-ExactValue {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $Actual,
        [Parameter(Mandatory = $true)][string] $Expected
    )

    if (-not [string]::Equals($Actual, $Expected, [StringComparison]::Ordinal)) {
        throw "Rollback guard rejected $Name."
    }
}

Assert-ExactValue -Name 'release branch' -Actual $SourceBranch -Expected 'refs/heads/release/azure-demo-v1'

if ($ReleaseIdentifier -notmatch '^[0-9a-fA-F]{40}$') {
    throw 'Rollback guard requires an explicit immutable 40-character Git release identifier.'
}
if (-not [string]::Equals($ReleaseIdentifier, $SourceVersion, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Rollback guard rejected a release identifier that does not match the running source version.'
}

Assert-ExactValue -Name 'deployment environment' -Actual $DeploymentEnvironmentName -Expected 'mtp-azure-demo-dev'
Assert-ExactValue -Name 'resource group' -Actual $ResourceGroupName -Expected 'Onkar.Pathre'
Assert-ExactValue -Name 'expected web application' -Actual $ExpectedWebAppName -Expected 'app-mtp-web-dev-uks-001'
Assert-ExactValue -Name 'expected API application' -Actual $ExpectedApiAppName -Expected 'app-mtp-api-dev-uks-001'
Assert-ExactValue -Name 'web application' -Actual $WebAppName -Expected $ExpectedWebAppName
Assert-ExactValue -Name 'API application' -Actual $ApiAppName -Expected $ExpectedApiAppName
Assert-ExactValue -Name 'web source slot' -Actual $WebSlotName -Expected 'staging'
Assert-ExactValue -Name 'API source slot' -Actual $ApiSlotName -Expected 'staging'
Assert-ExactValue -Name 'target slot' -Actual $TargetSlotName -Expected 'production'

if ([string]::Equals($ExpectedWebAppName, $ExpectedApiAppName, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Rollback guard requires distinct web and API applications.'
}

Write-Output "Rollback guard accepted immutable release $($ReleaseIdentifier.ToLowerInvariant()) for the restricted mtp-azure-demo-dev target."
