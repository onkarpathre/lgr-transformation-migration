[CmdletBinding()]
param([Parameter(Mandatory)] [string] $PackageDirectory)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'AzureDemoPackageUtilities.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).ProviderPath
$packageRoot = Assert-AzureDemoRepositoryOutputPath -RepositoryPath $repo -OutputPath $PackageDirectory
$expectedPackageRoot = Get-AzureDemoCanonicalPath -Path (Join-Path $repo 'artifacts/azure-demo-ci/packages')
$comparison = if ([IO.Path]::DirectorySeparatorChar -eq '\') { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
if (-not $packageRoot.Equals($expectedPackageRoot, $comparison)) {
    throw 'Seed packaging must use the exact repository-contained immutable package root.'
}
if ([int]((dotnet --version).Split('.')[0]) -ne 10) {
    throw 'Azure demo seed packaging requires .NET SDK 10.'
}
if (-not [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Linux)) {
    throw 'Azure demo seed packaging must run on the Linux Package agent.'
}

$seedDirectory = Join-Path $packageRoot 'seed'
$demoDataDirectory = Join-Path $packageRoot 'demo-data'
$samplesDirectory = Join-Path $packageRoot 'samples'
foreach ($directory in @($seedDirectory, $demoDataDirectory, $samplesDirectory)) {
    if (Test-Path -LiteralPath $directory) { Remove-Item -LiteralPath $directory -Recurse -Force }
}
New-Item -ItemType Directory -Path $seedDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $demoDataDirectory -Force | Out-Null

$project = 'tools/AzureDemo.DataTool/AzureDemo.DataTool.csproj'
Push-Location $repo
try {
    dotnet restore $project --locked-mode
    if ($LASTEXITCODE) { throw 'Locked Linux seed-tool restore failed.' }
    dotnet publish $project --configuration Release --no-self-contained --no-restore --output $seedDirectory
    if ($LASTEXITCODE) { throw 'Framework-dependent Linux seed-tool publish failed.' }
}
finally {
    Pop-Location
}

$entryAssembly = Join-Path $seedDirectory 'AzureDemo.DataTool.dll'
if (-not (Test-Path -LiteralPath $entryAssembly -PathType Leaf) -or (Get-Item -LiteralPath $entryAssembly).Length -le 0) {
    throw 'Published AzureDemo.DataTool entry assembly is missing or empty.'
}
foreach ($requiredRuntimeFile in @('AzureDemo.DataTool.deps.json', 'AzureDemo.DataTool.runtimeconfig.json')) {
    if (-not (Test-Path -LiteralPath (Join-Path $seedDirectory $requiredRuntimeFile) -PathType Leaf)) {
        throw "Published seed artifact is missing required runtime metadata $requiredRuntimeFile."
    }
}
$entryAssemblies = @(Get-ChildItem -LiteralPath $seedDirectory -Recurse -File -Filter 'AzureDemo.DataTool.dll')
if ($entryAssemblies.Count -ne 1) {
    throw 'Published seed artifact must contain exactly one AzureDemo.DataTool entry assembly.'
}
$forbiddenToolFiles = @(Get-ChildItem -LiteralPath $seedDirectory -Recurse -Force | Where-Object {
        $_.Name -in @('.git', 'obj', 'project.assets.json', 'packages.lock.json') -or
        $_.Extension -in @('.cs', '.csproj', '.sln', '.slnx', '.user', '.pfx', '.publishsettings')
})
if ($forbiddenToolFiles.Count -ne 0) {
    throw 'Published seed artifact contains source, restore, source-control or secret-bearing files.'
}

$sourceManifest = Join-Path $repo 'demo-data/azure-demo-seed-manifest.json'
$targetManifest = Join-Path $demoDataDirectory 'azure-demo-seed-manifest.json'
Copy-Item -LiteralPath $sourceManifest -Destination $targetManifest
$manifest = Get-Content -LiteralPath $sourceManifest -Raw | ConvertFrom-Json
if ($manifest.schemaVersion -cne '1' -or $manifest.environment -cne 'AzureDemo' -or $manifest.classification -cne 'synthetic') {
    throw 'Seed packaging rejected an unapproved synthetic manifest.'
}

foreach ($sample in @($manifest.approvedSampleFiles)) {
    $relativePath = [string] $sample.path
    if ([string]::IsNullOrWhiteSpace($relativePath) -or [IO.Path]::IsPathRooted($relativePath) -or
        $relativePath -match '(^|[\\/])\.\.?([\\/]|$)') {
        throw 'Seed manifest contains an unsafe approved sample path.'
    }
    $sourceSample = [IO.Path]::GetFullPath((Join-Path $repo $relativePath))
    $repoPrefix = $repo.TrimEnd([char[]] @('\', '/')) + [IO.Path]::DirectorySeparatorChar
    if (-not $sourceSample.StartsWith($repoPrefix, $comparison) -or -not (Test-Path -LiteralPath $sourceSample -PathType Leaf)) {
        throw 'Approved synthetic sample is absent or outside the repository.'
    }
    $actualHash = (Get-FileHash -LiteralPath $sourceSample -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -cne [string] $sample.sha256) {
        throw 'Approved synthetic sample SHA-256 does not match the seed manifest.'
    }
    $targetSample = Join-Path $packageRoot $relativePath
    New-Item -ItemType Directory -Path (Split-Path -Parent $targetSample) -Force | Out-Null
    Copy-Item -LiteralPath $sourceSample -Destination $targetSample
}

Write-Output 'Published immutable framework-dependent Linux AzureDemo seed tool and approved synthetic manifest inputs.'
