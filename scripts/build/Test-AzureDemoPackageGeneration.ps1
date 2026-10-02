[CmdletBinding()]
param(
    [string] $PackageDirectory = 'artifacts/azure-demo-ci/packages'
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path (Join-Path $PSScriptRoot '..') '..')).ProviderPath
$utilities = Join-Path $PSScriptRoot 'AzureDemoPackageUtilities.ps1'
$packageScript = Join-Path $PSScriptRoot 'New-AzureDemoPackages.ps1'
. $utilities

$packageRoot = Assert-AzureDemoRepositoryOutputPath -RepositoryPath $repo -OutputPath $PackageDirectory
$expectedPackageRoot = Get-AzureDemoCanonicalPath -Path (Join-Path $repo 'artifacts/azure-demo-ci/packages')
$pathComparison = if ([IO.Path]::DirectorySeparatorChar -eq '\') {
    [StringComparison]::OrdinalIgnoreCase
}
else {
    [StringComparison]::Ordinal
}
if (-not $packageRoot.Equals($expectedPackageRoot, $pathComparison)) {
    throw 'Package regression must use the exact repository-contained CI package directory.'
}

function Assert-PackagePathRejected([string] $Candidate, [string] $Scenario) {
    try {
        & $packageScript -OutputDirectory $Candidate -SkipRestore -SkipTests
        throw "Package generation accepted the $Scenario output path."
    }
    catch {
        if (-not $_.Exception.Message.Contains('OutputDirectory must be within the repository workspace.')) {
            throw "Package generation rejected the $Scenario path for an unexpected reason: $($_.Exception.Message)"
        }
    }
    if (Test-Path -LiteralPath $Candidate) {
        throw "Package generation created the rejected $Scenario output path."
    }
    Write-Output "Rejected $Scenario output before package generation."
}

$outsidePath = Join-Path ([IO.Path]::GetTempPath()) "lgr-azure-demo-package-regression-$([Guid]::NewGuid().ToString('N'))"
$siblingPath = Join-Path ($repo + "-prefix-confusion-$([Guid]::NewGuid().ToString('N'))") 'artifacts/azure-demo-ci/packages/application'
Assert-PackagePathRejected -Candidate $outsidePath -Scenario 'outside-repository'
Assert-PackagePathRejected -Candidate $siblingPath -Scenario 'similarly prefixed sibling'

$applicationDirectory = Join-Path $packageRoot 'application'
$acceptedPath = Assert-AzureDemoRepositoryOutputPath -RepositoryPath $repo -OutputPath $applicationDirectory
if (-not $acceptedPath.Equals((Get-AzureDemoCanonicalPath -Path $applicationDirectory), $pathComparison)) {
    throw 'The exact in-repository CI application package directory was not accepted canonically.'
}
Write-Output 'Accepted the exact repository-contained CI application package directory.'

$manifestPath = Join-Path $applicationDirectory 'application-artifact-manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw 'Application package manifest is missing.'
}
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if (@($manifest.artifacts).Count -ne 2) {
    throw 'Application package manifest must contain exactly the API and web ZIP evidence.'
}

$regressionDirectory = Join-Path $packageRoot '.package-regression'
if (Test-Path -LiteralPath $regressionDirectory) {
    Remove-Item -LiteralPath $regressionDirectory -Recurse -Force
}
New-Item -ItemType Directory -Path $regressionDirectory -Force | Out-Null
try {
    foreach ($name in @('api.zip', 'web.zip')) {
        $artifactEvidence = @($manifest.artifacts | Where-Object { $_.name -eq $name })
        if ($artifactEvidence.Count -ne 1 -or [string] $artifactEvidence[0].sha256 -notmatch '^[0-9a-f]{64}$') {
            throw "Manifest SHA-256 evidence is invalid for $name."
        }

        $zipPath = Join-Path $applicationDirectory $name
        if (-not (Test-Path -LiteralPath $zipPath -PathType Leaf) -or (Get-Item -LiteralPath $zipPath).Length -le 0) {
            throw "$name is missing or empty."
        }
        $actualHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actualHash -ne [string] $artifactEvidence[0].sha256) {
            throw "Manifest SHA-256 does not match $name."
        }

        $expanded = Join-Path $regressionDirectory ([IO.Path]::GetFileNameWithoutExtension($name))
        Expand-Archive -LiteralPath $zipPath -DestinationPath $expanded
        $expandedFiles = @(Get-ChildItem -LiteralPath $expanded -Recurse -File -Force)
        if ($expandedFiles.Count -eq 0) {
            throw "$name contains no files."
        }

        $repeatOne = Join-Path $regressionDirectory ("repeat-1-$name")
        $repeatTwo = Join-Path $regressionDirectory ("repeat-2-$name")
        New-AzureDemoDeterministicZip -SourceDirectory $expanded -DestinationPath $repeatOne
        New-AzureDemoDeterministicZip -SourceDirectory $expanded -DestinationPath $repeatTwo
        $repeatOneHash = (Get-FileHash -LiteralPath $repeatOne -Algorithm SHA256).Hash
        $repeatTwoHash = (Get-FileHash -LiteralPath $repeatTwo -Algorithm SHA256).Hash
        if ($repeatOneHash -ne $repeatTwoHash -or $repeatOneHash -ne (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash) {
            throw "$name generation is not deterministic when source timestamps are excluded."
        }
    }

    if (-not (Test-Path -LiteralPath (Join-Path $regressionDirectory 'api/LgrTransformationMigration.Api.dll') -PathType Leaf)) {
        throw 'API ZIP is readable but does not contain the API DLL at its root.'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $regressionDirectory 'web/server.js') -PathType Leaf)) {
        throw 'Web ZIP is readable but does not contain server.js at its root.'
    }
}
finally {
    if (Test-Path -LiteralPath $regressionDirectory) {
        Remove-Item -LiteralPath $regressionDirectory -Recurse -Force
    }
}

Write-Output 'Azure demo package regression passed repository-boundary, ZIP, manifest, SHA-256 and deterministic-generation checks.'
