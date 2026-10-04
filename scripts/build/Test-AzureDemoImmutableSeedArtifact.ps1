[CmdletBinding()]
param(
    [string] $PackageDirectory = 'artifacts/azure-demo-ci/packages',
    [string] $ExpectedSourceCommit
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).ProviderPath
. (Join-Path $PSScriptRoot 'AzureDemoDeploymentArtifactUtilities.ps1')
. (Join-Path $repo 'scripts/data/AzureDemoSeedArtifactContract.ps1')

if ([string]::IsNullOrWhiteSpace($ExpectedSourceCommit)) {
    $ExpectedSourceCommit = (& git -C $repo rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Could not establish the immutable seed expected source commit.' }
}

$packageRoot = if ([IO.Path]::IsPathRooted($PackageDirectory)) {
    [IO.Path]::GetFullPath($PackageDirectory)
}
else {
    [IO.Path]::GetFullPath((Join-Path $repo $PackageDirectory))
}
$manifestPath = Join-Path $packageRoot 'deployment-artifact-manifest.json'
$toolPath = Join-Path $packageRoot 'seed/AzureDemo.DataTool.dll'
$seedManifestPath = Join-Path $packageRoot 'demo-data/azure-demo-seed-manifest.json'
$null = Assert-AzureDemoSeedArtifactContract `
    -ImmutableArtifactRoot $packageRoot `
    -ToolPath $toolPath `
    -ManifestPath $seedManifestPath `
    -DeploymentManifestPath $manifestPath `
    -ExpectedSourceCommit $ExpectedSourceCommit

$pipeline = Get-Content -LiteralPath (Join-Path $repo 'azure-pipelines.yml') -Raw
$packageScript = Get-Content -LiteralPath (Join-Path $repo 'scripts/build/New-AzureDemoSeedArtifact.ps1') -Raw
$seedScript = Get-Content -LiteralPath (Join-Path $repo 'scripts/data/Invoke-AzureDemoSeed.ps1') -Raw
$resetScript = Get-Content -LiteralPath (Join-Path $repo 'scripts/data/Invoke-AzureDemoReset.ps1') -Raw
$dataTool = Get-Content -LiteralPath (Join-Path $repo 'tools/AzureDemo.DataTool/Program.cs') -Raw

foreach ($fragment in @(
        '[Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Linux)',
        'dotnet restore $project --locked-mode',
        'dotnet publish $project --configuration Release --no-self-contained --no-restore',
        "'AzureDemo.DataTool.deps.json'",
        "'AzureDemo.DataTool.runtimeconfig.json'",
        "Join-Path `$packageRoot 'seed'",
        "Join-Path `$packageRoot 'demo-data'",
        "Join-Path `$packageRoot 'samples'")) {
    if (-not $packageScript.Contains($fragment)) {
        throw "Immutable seed package generator is missing required contract: $fragment"
    }
}

$packageStart = $pipeline.IndexOf('- stage: Package', [StringComparison]::Ordinal)
$packageEnd = $pipeline.IndexOf('- stage: PreDeploymentGate', [StringComparison]::Ordinal)
$deploymentStart = $pipeline.IndexOf('- stage: MigrateAndDeploySlots', [StringComparison]::Ordinal)
$deploymentEnd = $pipeline.IndexOf('- stage: ReleaseApproval', [StringComparison]::Ordinal)
if ($packageStart -lt 0 -or $packageEnd -le $packageStart -or $deploymentStart -lt 0 -or $deploymentEnd -le $deploymentStart) {
    throw 'Immutable seed regression could not identify Package or protected deployment boundaries.'
}
$packageStage = $pipeline.Substring($packageStart, $packageEnd - $packageStart)
$deploymentStage = $pipeline.Substring($deploymentStart, $deploymentEnd - $deploymentStart)
foreach ($fragment in @(
        'New-AzureDemoSeedArtifact.ps1',
        'New-AzureDemoDeploymentArtifactManifest.ps1',
        'Assert-AzureDemoDeploymentArtifact.ps1',
        'Test-AzureDemoImmutableSeedArtifact.ps1')) {
    if (-not $packageStage.Contains($fragment)) { throw "Package stage is missing immutable seed control $fragment." }
}
foreach ($fragment in @(
        "-ImmutableArtifactRoot '`$(Pipeline.Workspace)/azure-demo-immutable'",
        "-ToolPath '`$(Pipeline.Workspace)/azure-demo-immutable/seed/AzureDemo.DataTool.dll'",
        "-ManifestPath '`$(Pipeline.Workspace)/azure-demo-immutable/demo-data/azure-demo-seed-manifest.json'",
        "-DeploymentManifestPath '`$(Pipeline.Workspace)/azure-demo-immutable/deployment-artifact-manifest.json'",
        "-ExpectedSourceCommit '`$(Build.SourceVersion)'")) {
    if (-not $deploymentStage.Contains($fragment)) { throw "Protected seed task is missing immutable execution argument $fragment." }
}
if ($deploymentStage -match '(?i)\bdotnet\s+(?:run|restore|build)\b' -or
    $deploymentStage.Contains('tools/AzureDemo.DataTool/AzureDemo.DataTool.csproj') -or
    $deploymentStage.Contains('tools\AzureDemo.DataTool\AzureDemo.DataTool.csproj')) {
    throw 'Protected deployment must not run, restore or build source for seed reconciliation.'
}
if ($seedScript -match '(?i)\bdotnet\s+(?:run|restore|build)\b' -or
    $seedScript.Contains('AzureDemo.DataTool.csproj') -or
    $seedScript.Contains('Build.SourcesDirectory') -or
    $seedScript.Contains('FindRepositoryRoot')) {
    throw 'Seed wrapper contains a source, restore or build fallback.'
}
foreach ($fragment in @(
        'dotnet --list-runtimes',
        '^Microsoft\.NETCore\.App 10\.[0-9.]+ \[',
        '^Microsoft\.AspNetCore\.App 10\.[0-9.]+ \[')) {
    if (-not $seedScript.Contains($fragment)) {
        throw "Seed wrapper does not fail closed on required .NET 10 shared runtime $fragment."
    }
}
foreach ($fragment in @('ImmutableArtifactRoot', 'ToolPath', 'ManifestPath', 'DeploymentManifestPath', 'ExpectedSourceCommit')) {
    if (-not $resetScript.Contains("-$fragment `$$fragment")) {
        throw "Reset does not forward immutable seed argument $fragment."
    }
}
if ($resetScript -match '(?i)\bdotnet\s+(?:run|restore|build)\b' -or $resetScript.Contains('AzureDemo.DataTool.csproj')) {
    throw 'Reset contains a source, restore or build fallback.'
}
if ($dataTool.Contains('FindRepositoryRoot') -or -not $dataTool.Contains('Required("--artifact-root")')) {
    throw 'Published data tool still depends on repository-root discovery.'
}

$idempotentGuards = [regex]::Matches($dataTool, 'if \(!await database\.[A-Za-z]+\.AnyAsync\(x => x\.Id == [a-zA-Z]+Id\)\)')
$idempotentAdds = [regex]::Matches($dataTool, 'database\.[A-Za-z]+\.Add\(new ')
if ($idempotentGuards.Count -ne 5 -or $idempotentAdds.Count -ne 5 -or
    [regex]::Matches($dataTool, 'SaveChangesAsync\(\)').Count -ne 1 -or
    $dataTool -match '(?i)ExecuteDelete|RemoveRange|Database\.Migrate|EnsureCreated') {
    throw 'Repeated seed execution is not protected by the expected five stable-ID existence guards and single reconciliation save.'
}

foreach ($text in @($pipeline, $packageScript, $seedScript, $resetScript)) {
    if ($text -match '(?im)^\s*(?:Write-(?:Host|Output)|echo)\b[^\r\n]*(?:connection.?string|access.?token|idtoken|federated.?token|evidence contents)') {
        throw 'Immutable seed implementation contains a command that could print a secret or evidence content.'
    }
}

$temporaryParent = Join-Path ([IO.Path]::GetTempPath()) "azdemo-immutable-seed-regression-$([Guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $temporaryParent -Force | Out-Null
try {
    function New-SyntheticArtifact([string] $Name) {
        $root = Join-Path $temporaryParent $Name
        New-Item -ItemType Directory -Path (Join-Path $root 'seed') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'demo-data') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'samples/discovery') -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $root 'seed/AzureDemo.DataTool.dll'), 'synthetic-entry-assembly')
        [IO.File]::WriteAllText((Join-Path $root 'demo-data/azure-demo-seed-manifest.json'), '{"classification":"synthetic"}')
        [IO.File]::WriteAllText((Join-Path $root 'samples/discovery/azure-migrate-server-report-demo.csv'), 'synthetic,sample')
        $null = New-AzureDemoDeploymentArtifactManifest -ArtifactRoot $root -SourceCommit $ExpectedSourceCommit
        return $root
    }

    function Assert-Rejected([scriptblock] $Action, [string] $Scenario) {
        $accepted = $false
        try { & $Action | Out-Null; $accepted = $true } catch { }
        if ($accepted) { throw "Immutable seed contract accepted $Scenario." }
    }

    $missingToolRoot = New-SyntheticArtifact 'missing-tool'
    Remove-Item -LiteralPath (Join-Path $missingToolRoot 'seed/AzureDemo.DataTool.dll') -Force
    Assert-Rejected { Assert-AzureDemoSeedArtifactContract -ImmutableArtifactRoot $missingToolRoot -ToolPath (Join-Path $missingToolRoot 'seed/AzureDemo.DataTool.dll') -ManifestPath (Join-Path $missingToolRoot 'demo-data/azure-demo-seed-manifest.json') -DeploymentManifestPath (Join-Path $missingToolRoot 'deployment-artifact-manifest.json') -ExpectedSourceCommit $ExpectedSourceCommit } 'a missing published entry assembly'

    $missingManifestRoot = New-SyntheticArtifact 'missing-manifest'
    Remove-Item -LiteralPath (Join-Path $missingManifestRoot 'demo-data/azure-demo-seed-manifest.json') -Force
    Assert-Rejected { Assert-AzureDemoSeedArtifactContract -ImmutableArtifactRoot $missingManifestRoot -ToolPath (Join-Path $missingManifestRoot 'seed/AzureDemo.DataTool.dll') -ManifestPath (Join-Path $missingManifestRoot 'demo-data/azure-demo-seed-manifest.json') -DeploymentManifestPath (Join-Path $missingManifestRoot 'deployment-artifact-manifest.json') -ExpectedSourceCommit $ExpectedSourceCommit } 'a missing seed manifest'

    $modifiedRoot = New-SyntheticArtifact 'modified'
    Add-Content -LiteralPath (Join-Path $modifiedRoot 'seed/AzureDemo.DataTool.dll') -Value 'modified'
    Assert-Rejected { Assert-AzureDemoDeploymentArtifact -ArtifactRoot $modifiedRoot -ManifestPath (Join-Path $modifiedRoot 'deployment-artifact-manifest.json') -ExpectedSourceCommit $ExpectedSourceCommit } 'modified artifact content'

    $addedRoot = New-SyntheticArtifact 'added'
    [IO.File]::WriteAllText((Join-Path $addedRoot 'seed/substituted.dll'), 'added')
    Assert-Rejected { Assert-AzureDemoDeploymentArtifact -ArtifactRoot $addedRoot -ManifestPath (Join-Path $addedRoot 'deployment-artifact-manifest.json') -ExpectedSourceCommit $ExpectedSourceCommit } 'an added seed file'

    $traversalRoot = New-SyntheticArtifact 'traversal'
    $traversalManifest = Get-Content -LiteralPath (Join-Path $traversalRoot 'deployment-artifact-manifest.json') -Raw | ConvertFrom-Json
    $traversalManifest.artifacts[0].path = '../escape.dll'
    $traversalManifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $traversalRoot 'deployment-artifact-manifest.json') -Encoding UTF8
    Assert-Rejected { Assert-AzureDemoDeploymentArtifact -ArtifactRoot $traversalRoot -ManifestPath (Join-Path $traversalRoot 'deployment-artifact-manifest.json') -ExpectedSourceCommit $ExpectedSourceCommit } 'manifest path traversal'

    $outsideRoot = New-SyntheticArtifact 'outside'
    $outsideTool = Join-Path $temporaryParent 'outside-tool.dll'
    [IO.File]::WriteAllText($outsideTool, 'outside')
    Assert-Rejected { Assert-AzureDemoSeedArtifactContract -ImmutableArtifactRoot $outsideRoot -ToolPath $outsideTool -ManifestPath (Join-Path $outsideRoot 'demo-data/azure-demo-seed-manifest.json') -DeploymentManifestPath (Join-Path $outsideRoot 'deployment-artifact-manifest.json') -ExpectedSourceCommit $ExpectedSourceCommit } 'a tool path outside the immutable root'
    Assert-Rejected { Assert-AzureDemoSeedArtifactContract -ImmutableArtifactRoot $outsideRoot -ToolPath (Join-Path $outsideRoot '../outside-tool.dll') -ManifestPath (Join-Path $outsideRoot 'demo-data/azure-demo-seed-manifest.json') -DeploymentManifestPath (Join-Path $outsideRoot 'deployment-artifact-manifest.json') -ExpectedSourceCommit $ExpectedSourceCommit } 'a traversing tool path'

    $commitRoot = New-SyntheticArtifact 'commit-mismatch'
    $wrongCommit = if ($ExpectedSourceCommit -ceq ('a' * 40)) { 'b' * 40 } else { 'a' * 40 }
    Assert-Rejected { Assert-AzureDemoDeploymentArtifact -ArtifactRoot $commitRoot -ManifestPath (Join-Path $commitRoot 'deployment-artifact-manifest.json') -ExpectedSourceCommit $wrongCommit } 'a source-commit mismatch'
}
finally {
    if (Test-Path -LiteralPath $temporaryParent) {
        Remove-Item -LiteralPath $temporaryParent -Recurse -Force
    }
}

Write-Output 'Immutable seed artifact regression passed Package publish, complete hash manifest, protected execution, reset, idempotency and fail-closed path/content checks.'
