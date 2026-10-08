[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ArtifactRoot,
    [Parameter(Mandatory)] [string] $ManifestPath,
    [Parameter(Mandatory)] [string] $ExpectedSourceCommit
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'AzureDemoDeploymentArtifactUtilities.ps1')

$result = Assert-AzureDemoDeploymentArtifact -ArtifactRoot $ArtifactRoot -ManifestPath $ManifestPath -ExpectedSourceCommit $ExpectedSourceCommit
Write-Output "Deployment artifact validation passed for $($result.ArtifactCount) exact-commit payload files."
