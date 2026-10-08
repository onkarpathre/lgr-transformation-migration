[CmdletBinding()]
param(
    [Parameter(Mandatory)] [ValidateSet('AzureDemo')] [string] $Environment,
    [Parameter(Mandatory)] [ValidatePattern('^sqldb-mtp-dev-uks-001(?:-reset-[a-z0-9]+)?$')] [string] $DatabaseName,
    [Parameter(Mandatory)] [ValidateSet('Onkar.Pathre')] [string] $ResourceGroupName,
    [Parameter(Mandatory)] [string] $ImmutableArtifactRoot,
    [Parameter(Mandatory)] [string] $ToolPath,
    [Parameter(Mandatory)] [string] $ManifestPath,
    [Parameter(Mandatory)] [string] $DeploymentManifestPath,
    [Parameter(Mandatory)] [ValidatePattern('^[0-9a-f]{40}$')] [string] $ExpectedSourceCommit
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ([string]::IsNullOrWhiteSpace($env:LGR_AZURE_DEMO_SQL_CONNECTION_STRING)) {
    throw 'The protected stage must supply LGR_AZURE_DEMO_SQL_CONNECTION_STRING without logging it.'
}
. (Join-Path $PSScriptRoot 'AzureDemoSeedArtifactContract.ps1')
$contract = Assert-AzureDemoSeedArtifactContract `
    -ImmutableArtifactRoot $ImmutableArtifactRoot `
    -ToolPath $ToolPath `
    -ManifestPath $ManifestPath `
    -DeploymentManifestPath $DeploymentManifestPath `
    -ExpectedSourceCommit $ExpectedSourceCommit

$availableRuntimes = @(& dotnet --list-runtimes 2>&1)
if ($LASTEXITCODE -ne 0 -or
    -not ($availableRuntimes -match '^Microsoft\.NETCore\.App 10\.[0-9.]+ \[') -or
    -not ($availableRuntimes -match '^Microsoft\.AspNetCore\.App 10\.[0-9.]+ \[')) {
    throw 'The protected seed agent does not provide the required .NET 10 shared runtimes.'
}
& dotnet $contract.ToolPath `
    --environment $Environment `
    --resource-group $ResourceGroupName `
    --database $DatabaseName `
    --artifact-root $contract.ArtifactRoot `
    --manifest $contract.ManifestPath
if ($LASTEXITCODE) { throw 'AzureDemo seed reconciliation failed.' }
