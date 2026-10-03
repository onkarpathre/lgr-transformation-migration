[CmdletBinding()]
param(
    [Parameter(Mandatory)] [ValidateSet('AzureDemo')] [string] $Environment,
    [Parameter(Mandatory)] [ValidatePattern('^sqldb-mtp-dev-uks-001(?:-reset-[a-z0-9]+)?$')] [string] $DatabaseName,
    [Parameter(Mandatory)] [ValidateSet('Onkar.Pathre')] [string] $ResourceGroupName,
    [string] $ManifestPath = 'demo-data/azure-demo-seed-manifest.json'
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($env:LGR_AZURE_DEMO_SQL_CONNECTION_STRING)) {
    throw 'The protected stage must supply LGR_AZURE_DEMO_SQL_CONNECTION_STRING without logging it.'
}
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$manifest = (Resolve-Path (Join-Path $repo $ManifestPath)).Path
dotnet run --project (Join-Path $repo 'tools/AzureDemo.DataTool/AzureDemo.DataTool.csproj') --configuration Release --no-restore -- --environment $Environment --resource-group $ResourceGroupName --database $DatabaseName --manifest $manifest
if ($LASTEXITCODE) { throw 'AzureDemo seed reconciliation failed.' }
