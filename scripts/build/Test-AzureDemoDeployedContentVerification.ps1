[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).ProviderPath
. (Join-Path $repo 'scripts\build\AzureDemoPackageUtilities.ps1')
. (Join-Path $repo 'scripts\deployment\AzureDemoStagingDeployment.ps1')

$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-content-regression-$([Guid]::NewGuid().ToString('N'))")
$sourceCommit = '1111111111111111111111111111111111111111'
$resourceId = '/subscriptions/633398e2-6c00-4bb7-a576-2db0d210ee77/resourceGroups/Onkar.Pathre/providers/Microsoft.Web/sites/app-mtp-web-dev-uks-001/slots/staging'
New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null

function New-TextFile([string] $Root, [string] $RelativePath, [string] $Content) {
    $path = Join-Path $Root $RelativePath
    New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
    [IO.File]::WriteAllText($path, $Content, [Text.UTF8Encoding]::new($false))
}

function New-WebTree([string] $Root, [string] $BuildId, [string] $ChunkContent, [switch] $CompressedDependencies, [switch] $MissingChunk) {
    New-Item -ItemType Directory -Path $Root -Force | Out-Null
    New-TextFile $Root 'server.js' 'server-entry'
    New-TextFile $Root '.next/BUILD_ID' $BuildId
    New-TextFile $Root '.next/server/app/page.js' 'page-entry'
    if (-not $MissingChunk) { New-TextFile $Root '.next/server/chunks/ssr/[root-of-the-server]__fixture._.js' $ChunkContent }
    New-TextFile $Root '.next/static/chunks/app-12345678.js' 'static-entry'
    if ($CompressedDependencies) { New-TextFile $Root 'node_modules.tar.gz' 'platform-compressed-dependency-fixture' }
    else { New-TextFile $Root 'node_modules/next/index.js' 'dependency-entry' }
}

function New-Zip([string] $Source, [string] $Destination) {
    New-AzureDemoDeterministicZip -SourceDirectory $Source -DestinationPath $Destination
    $archive = [IO.Compression.ZipFile]::OpenRead($Destination)
    try {
        foreach ($entry in $archive.Entries) {
            if ($entry.LastWriteTime.UtcDateTime -ne [datetime] '1980-01-01T00:00:00Z') {
                throw 'Synthetic regression ZIP did not retain the deterministic 1980 timestamp collision.'
            }
        }
    }
    finally { $archive.Dispose() }
}

function Assert-Rejected([scriptblock] $Action, [string] $Scenario) {
    $accepted = $false
    try { & $Action; $accepted = $true } catch { }
    if ($accepted) { throw "Deployed-content verification accepted $Scenario." }
}

try {
    $expectedOneRoot = Join-Path $temporaryDirectory 'expected-one'
    $expectedTwoRoot = Join-Path $temporaryDirectory 'expected-two'
    $deployedRoot = Join-Path $temporaryDirectory 'deployed'
    New-WebTree $expectedOneRoot 'BUILD00000000001' 'AAAA'
    New-WebTree $expectedTwoRoot 'BUILD00000000002' 'BBBB'
    New-WebTree $deployedRoot 'BUILD00000000002' 'BBBB' -CompressedDependencies
    $expectedOneZip = Join-Path $temporaryDirectory 'expected-one.zip'
    $expectedTwoZip = Join-Path $temporaryDirectory 'expected-two.zip'
    $deployedZip = Join-Path $temporaryDirectory 'deployed.zip'
    New-Zip $expectedOneRoot $expectedOneZip
    New-Zip $expectedTwoRoot $expectedTwoZip
    New-Zip $deployedRoot $deployedZip

    $firstInventory = @(Get-AzureDemoZipInventory $expectedOneZip)
    $secondInventory = @(Get-AzureDemoZipInventory $expectedTwoZip)
    foreach ($path in @('.next/BUILD_ID', '.next/server/chunks/ssr/[root-of-the-server]__fixture._.js')) {
        $first = @($firstInventory | Where-Object Path -CEQ $path)[0]
        $second = @($secondInventory | Where-Object Path -CEQ $path)[0]
        if ($first.Length -ne $second.Length -or $first.Sha256 -ceq $second.Sha256) {
            throw 'Successive-package fixture did not preserve identical path/size/timestamp with different content.'
        }
    }

    $passEvidence = Join-Path $temporaryDirectory 'pass.json'
    Compare-AzureDemoDeployedZip -Workload Web -ExpectedZipPath $expectedTwoZip -DeployedZipPath $deployedZip `
        -EvidencePath $passEvidence -SourceCommit $sourceCommit -ResourceId $resourceId | Out-Null
    $pass = Get-Content -LiteralPath $passEvidence -Raw | ConvertFrom-Json
    if ($pass.status -cne 'PASS' -or $pass.buildId.deployed -cne 'BUILD00000000002' -or
        $pass.dependencyTransformation.mode -cne 'platform-transformed-node-modules' -or
        [bool] $pass.dependencyTransformation.exactDependencyBytesCompared -or
        $pass.applicationVerification.expectedFingerprint -cne $pass.applicationVerification.deployedFingerprint -or
        $pass.applicationVerification.webFileEvidence.serverJs.expectedSha256 -cne $pass.applicationVerification.webFileEvidence.serverJs.deployedSha256 -or
        $pass.applicationVerification.webFileEvidence.serverPages.expectedFingerprint -cne $pass.applicationVerification.webFileEvidence.serverPages.deployedFingerprint -or
        $pass.applicationVerification.webFileEvidence.serverChunks.expectedFingerprint -cne $pass.applicationVerification.webFileEvidence.serverChunks.deployedFingerprint -or
        $pass.applicationVerification.webFileEvidence.staticAssets.expectedFingerprint -cne $pass.applicationVerification.webFileEvidence.staticAssets.deployedFingerprint) {
        throw 'Successful deployed-content evidence did not record build identity and explicit dependency transformation.'
    }

    Assert-Rejected {
        Compare-AzureDemoDeployedZip -Workload Web -ExpectedZipPath $expectedTwoZip -DeployedZipPath $expectedOneZip `
            -EvidencePath (Join-Path $temporaryDirectory 'stale.json') -SourceCommit $sourceCommit -ResourceId $resourceId | Out-Null
    } 'stale same-name, same-size and same-timestamp application files'

    $missingRoot = Join-Path $temporaryDirectory 'missing'
    New-WebTree $missingRoot 'BUILD00000000002' 'BBBB' -CompressedDependencies -MissingChunk
    $missingZip = Join-Path $temporaryDirectory 'missing.zip'
    New-Zip $missingRoot $missingZip
    Assert-Rejected {
        Compare-AzureDemoDeployedZip -Workload Web -ExpectedZipPath $expectedTwoZip -DeployedZipPath $missingZip `
            -EvidencePath (Join-Path $temporaryDirectory 'missing.json') -SourceCommit $sourceCommit -ResourceId $resourceId | Out-Null
    } 'missing square-bracket chunk'

    $changedBuildRoot = Join-Path $temporaryDirectory 'changed-build'
    New-WebTree $changedBuildRoot 'BUILD00000000009' 'BBBB' -CompressedDependencies
    $changedBuildZip = Join-Path $temporaryDirectory 'changed-build.zip'
    New-Zip $changedBuildRoot $changedBuildZip
    Assert-Rejected {
        Compare-AzureDemoDeployedZip -Workload Web -ExpectedZipPath $expectedTwoZip -DeployedZipPath $changedBuildZip `
            -EvidencePath (Join-Path $temporaryDirectory 'changed-build.json') -SourceCommit $sourceCommit -ResourceId $resourceId | Out-Null
    } 'changed Next.js build ID'

    foreach ($failureEvidence in @('stale.json', 'missing.json', 'changed-build.json')) {
        $failure = Get-Content -LiteralPath (Join-Path $temporaryDirectory $failureEvidence) -Raw | ConvertFrom-Json
        if ($failure.status -cne 'FAIL') { throw "$failureEvidence did not retain mismatch evidence." }
    }

    Write-Output 'Deployed-content regression passed exact SHA-256 reconciliation, explicit dependency transformation, deterministic timestamp/size collision, square-bracket chunk, missing chunk and changed build-ID gates.'
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) { Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force }
}
