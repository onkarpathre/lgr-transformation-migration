$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot '..\build\AzureDemoDeploymentArtifactUtilities.ps1')

function Assert-AzureDemoSeedArtifactContract {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $ImmutableArtifactRoot,
        [Parameter(Mandatory)] [string] $ToolPath,
        [Parameter(Mandatory)] [string] $ManifestPath,
        [Parameter(Mandatory)] [string] $DeploymentManifestPath,
        [Parameter(Mandatory)] [string] $ExpectedSourceCommit
    )

    $deployment = Assert-AzureDemoDeploymentArtifact `
        -ArtifactRoot $ImmutableArtifactRoot `
        -ManifestPath $DeploymentManifestPath `
        -ExpectedSourceCommit $ExpectedSourceCommit
    $resolvedTool = Resolve-AzureDemoArtifactPath -ArtifactRoot $deployment.ArtifactRoot -Path $ToolPath -PathType Leaf
    $resolvedSeedManifest = Resolve-AzureDemoArtifactPath -ArtifactRoot $deployment.ArtifactRoot -Path $ManifestPath -PathType Leaf
    $comparison = Get-AzureDemoArtifactPathComparison

    $expectedToolPath = Join-Path $deployment.ArtifactRoot 'seed/AzureDemo.DataTool.dll'
    $expectedManifestPath = Join-Path $deployment.ArtifactRoot 'demo-data/azure-demo-seed-manifest.json'
    if (-not $resolvedTool.Equals($expectedToolPath, $comparison) -or
        -not $resolvedSeedManifest.Equals($expectedManifestPath, $comparison)) {
        throw 'Seed execution requires the exact packaged tool and approved immutable manifest paths.'
    }

    $entryAssemblies = @(Get-ChildItem -LiteralPath $deployment.ArtifactRoot -Recurse -File -Filter 'AzureDemo.DataTool.dll')
    if ($entryAssemblies.Count -ne 1 -or
        -not $entryAssemblies[0].FullName.Equals($resolvedTool, $comparison)) {
        throw 'Immutable artifact must contain exactly one published AzureDemo.DataTool entry assembly.'
    }

    return [pscustomobject]@{
        ArtifactRoot = $deployment.ArtifactRoot
        ToolPath = $resolvedTool
        ManifestPath = $resolvedSeedManifest
        DeploymentManifestPath = $deployment.ManifestPath
        SourceCommit = $deployment.SourceCommit
    }
}
