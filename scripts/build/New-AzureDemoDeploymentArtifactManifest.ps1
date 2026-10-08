[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ArtifactRoot,
    [Parameter(Mandatory)] [string] $SourceCommit
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'AzureDemoDeploymentArtifactUtilities.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).ProviderPath
$head = (& git -C $repo rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $head -cne $SourceCommit) {
    throw 'Deployment artifact source commit does not match the exact checked-out repository HEAD.'
}

$manifestPath = New-AzureDemoDeploymentArtifactManifest -ArtifactRoot $ArtifactRoot -SourceCommit $SourceCommit
Write-Output "Created exact-commit deployment artifact manifest at $manifestPath."
