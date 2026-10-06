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

function New-SyntheticBinaryFile([string] $Root, [string] $RelativePath, [byte] $Marker, [int] $Length) {
    $path = Join-Path $Root $RelativePath
    New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
    $bytes = New-Object byte[] $Length
    for ($index = 0; $index -lt $bytes.Length; $index++) {
        $bytes[$index] = [byte] (($Marker + $index) % 251)
    }
    [IO.File]::WriteAllBytes($path, $bytes)
}

function New-ApiTree([string] $Root, [byte] $Marker, [switch] $MissingPdb, [switch] $UnexpectedFile) {
    New-Item -ItemType Directory -Path $Root -Force | Out-Null
    # These bounded byte fixtures are intentionally not deployable assemblies.
    New-SyntheticBinaryFile $Root 'LgrTransformationMigration.Api.dll' $Marker 4096
    if (-not $MissingPdb) {
        New-SyntheticBinaryFile $Root 'LgrTransformationMigration.Api.pdb' ([byte] ($Marker + 17)) 2048
    }
    if ($UnexpectedFile) {
        New-SyntheticBinaryFile $Root 'unexpected.metadata' ([byte] ($Marker + 31)) 64
    }
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
    New-TextFile $deployedRoot 'oryx-manifest.toml' "OperationId = 'platform-fixture'`nPlatformName = 'nodejs'`n"
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
        @($pass.platformMetadata.files).Count -ne 1 -or
        $pass.platformMetadata.files[0].path -cne 'oryx-manifest.toml' -or
        [string] $pass.platformMetadata.files[0].sha256 -cnotmatch '^[0-9a-f]{64}$' -or
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

    $unknownExtraRoot = Join-Path $temporaryDirectory 'unknown-extra'
    New-WebTree $unknownExtraRoot 'BUILD00000000002' 'BBBB' -CompressedDependencies
    New-TextFile $unknownExtraRoot 'oryx-manifest.toml' "OperationId = 'platform-fixture'`n"
    New-TextFile $unknownExtraRoot 'unexpected-platform-file.toml' "OperationId = 'unknown'`n"
    $unknownExtraZip = Join-Path $temporaryDirectory 'unknown-extra.zip'
    New-Zip $unknownExtraRoot $unknownExtraZip
    Assert-Rejected {
        Compare-AzureDemoDeployedZip -Workload Web -ExpectedZipPath $expectedTwoZip -DeployedZipPath $unknownExtraZip `
            -EvidencePath (Join-Path $temporaryDirectory 'unknown-extra.json') -SourceCommit $sourceCommit -ResourceId $resourceId | Out-Null
    } 'an unknown additional platform file'

    $invalidManifestRoot = Join-Path $temporaryDirectory 'invalid-platform-metadata'
    New-WebTree $invalidManifestRoot 'BUILD00000000002' 'BBBB' -CompressedDependencies
    New-TextFile $invalidManifestRoot 'oryx-manifest.toml' ''
    $invalidManifestZip = Join-Path $temporaryDirectory 'invalid-platform-metadata.zip'
    New-Zip $invalidManifestRoot $invalidManifestZip
    Assert-Rejected {
        Compare-AzureDemoDeployedZip -Workload Web -ExpectedZipPath $expectedTwoZip -DeployedZipPath $invalidManifestZip `
            -EvidencePath (Join-Path $temporaryDirectory 'invalid-platform-metadata.json') -SourceCommit $sourceCommit -ResourceId $resourceId | Out-Null
    } 'an empty root oryx-manifest.toml'

    $packagedManifestRoot = Join-Path $temporaryDirectory 'packaged-platform-metadata'
    New-WebTree $packagedManifestRoot 'BUILD00000000002' 'BBBB'
    New-TextFile $packagedManifestRoot 'oryx-manifest.toml' "OperationId = 'must-not-be-packaged'`n"
    $packagedManifestZip = Join-Path $temporaryDirectory 'packaged-platform-metadata.zip'
    New-Zip $packagedManifestRoot $packagedManifestZip
    Assert-Rejected {
        Compare-AzureDemoDeployedZip -Workload Web -ExpectedZipPath $packagedManifestZip -DeployedZipPath $deployedZip `
            -EvidencePath (Join-Path $temporaryDirectory 'packaged-platform-metadata.json') -SourceCommit $sourceCommit -ResourceId $resourceId | Out-Null
    } 'oryx-manifest.toml supplied by the immutable application package'

    foreach ($failureEvidence in @('stale.json', 'missing.json', 'changed-build.json', 'unknown-extra.json', 'packaged-platform-metadata.json')) {
        $failure = Get-Content -LiteralPath (Join-Path $temporaryDirectory $failureEvidence) -Raw | ConvertFrom-Json
        if ($failure.status -cne 'FAIL') { throw "$failureEvidence did not retain mismatch evidence." }
    }

    $apiExpectedRoot = Join-Path $temporaryDirectory 'api-expected'
    $apiStaleRoot = Join-Path $temporaryDirectory 'api-stale'
    New-ApiTree -Root $apiExpectedRoot -Marker 65
    New-ApiTree -Root $apiStaleRoot -Marker 83
    $apiExpectedZip = Join-Path $temporaryDirectory 'api-expected.zip'
    $apiStaleZip = Join-Path $temporaryDirectory 'api-stale.zip'
    New-Zip $apiExpectedRoot $apiExpectedZip
    New-Zip $apiStaleRoot $apiStaleZip
    $apiExpectedInventory = @(Get-AzureDemoZipInventory $apiExpectedZip)
    $apiStaleInventory = @(Get-AzureDemoZipInventory $apiStaleZip)
    foreach ($path in @('LgrTransformationMigration.Api.dll', 'LgrTransformationMigration.Api.pdb')) {
        $expectedBinary = @($apiExpectedInventory | Where-Object Path -CEQ $path)[0]
        $staleBinary = @($apiStaleInventory | Where-Object Path -CEQ $path)[0]
        if ($expectedBinary.Length -ne $staleBinary.Length -or $expectedBinary.Sha256 -ceq $staleBinary.Sha256) {
            throw "$path fixture must retain equal length with different synthetic binary content."
        }
    }

    $apiPassEvidencePath = Join-Path $temporaryDirectory 'api-pass.json'
    Compare-AzureDemoDeployedZip -Workload Api -ExpectedZipPath $apiExpectedZip -DeployedZipPath $apiExpectedZip `
        -EvidencePath $apiPassEvidencePath -SourceCommit $sourceCommit `
        -ResourceId $resourceId.Replace('app-mtp-web', 'app-mtp-api') | Out-Null
    $apiPassEvidence = Get-Content -LiteralPath $apiPassEvidencePath -Raw | ConvertFrom-Json
    if ($apiPassEvidence.status -cne 'PASS' -or
        $apiPassEvidence.applicationVerification.expectedFileCount -ne $apiExpectedInventory.Count -or
        $apiPassEvidence.applicationVerification.deployedFileCount -ne $apiExpectedInventory.Count -or
        @($apiPassEvidence.applicationVerification.missing).Count -ne 0 -or
        @($apiPassEvidence.applicationVerification.changed).Count -ne 0 -or
        @($apiPassEvidence.applicationVerification.unexpected).Count -ne 0 -or
        $apiPassEvidence.platformMetadata.mode -cne 'none' -or
        $apiPassEvidence.dependencyTransformation.mode -cne 'none') {
        throw 'Successful API verification did not derive its exact complete file set from the immutable package.'
    }

    $apiMismatchEvidencePath = Join-Path $temporaryDirectory 'api-equal-size-content-mismatch.json'
    Assert-Rejected {
        Compare-AzureDemoDeployedZip -Workload Api -ExpectedZipPath $apiExpectedZip -DeployedZipPath $apiStaleZip `
            -EvidencePath $apiMismatchEvidencePath -SourceCommit $sourceCommit `
            -ResourceId $resourceId.Replace('app-mtp-web', 'app-mtp-api') | Out-Null
    } 'equal-size DLL and PDB content mismatches'
    $apiMismatchEvidence = Get-Content -LiteralPath $apiMismatchEvidencePath -Raw | ConvertFrom-Json
    $changedApiPaths = @($apiMismatchEvidence.applicationVerification.changed | ForEach-Object { [string] $_.path } | Sort-Object)
    if ($apiMismatchEvidence.status -cne 'FAIL' -or
        ($changedApiPaths -join '|') -cne 'LgrTransformationMigration.Api.dll|LgrTransformationMigration.Api.pdb' -or
        @($apiMismatchEvidence.applicationVerification.missing).Count -ne 0 -or
        @($apiMismatchEvidence.applicationVerification.unexpected).Count -ne 0) {
        throw 'API equal-size mismatch evidence did not identify exactly the synthetic DLL and PDB.'
    }
    foreach ($changedBinary in @($apiMismatchEvidence.applicationVerification.changed)) {
        if ($changedBinary.expectedLength -ne $changedBinary.deployedLength -or
            [string] $changedBinary.expectedSha256 -ceq [string] $changedBinary.deployedSha256) {
            throw 'API mismatch evidence did not retain equal length and different SHA-256 values.'
        }
    }

    $apiMissingRoot = Join-Path $temporaryDirectory 'api-missing'
    New-ApiTree -Root $apiMissingRoot -Marker 65 -MissingPdb
    $apiMissingZip = Join-Path $temporaryDirectory 'api-missing.zip'
    New-Zip $apiMissingRoot $apiMissingZip
    Assert-Rejected {
        Compare-AzureDemoDeployedZip -Workload Api -ExpectedZipPath $apiExpectedZip -DeployedZipPath $apiMissingZip `
            -EvidencePath (Join-Path $temporaryDirectory 'api-missing.json') -SourceCommit $sourceCommit `
            -ResourceId $resourceId.Replace('app-mtp-web', 'app-mtp-api') | Out-Null
    } 'a missing API PDB'

    $apiUnexpectedRoot = Join-Path $temporaryDirectory 'api-unexpected'
    New-ApiTree -Root $apiUnexpectedRoot -Marker 65 -UnexpectedFile
    $apiUnexpectedZip = Join-Path $temporaryDirectory 'api-unexpected.zip'
    New-Zip $apiUnexpectedRoot $apiUnexpectedZip
    Assert-Rejected {
        Compare-AzureDemoDeployedZip -Workload Api -ExpectedZipPath $apiExpectedZip -DeployedZipPath $apiUnexpectedZip `
            -EvidencePath (Join-Path $temporaryDirectory 'api-unexpected.json') -SourceCommit $sourceCommit `
            -ResourceId $resourceId.Replace('app-mtp-web', 'app-mtp-api') | Out-Null
    } 'an unexpected API metadata file'
    $apiMissingEvidence = Get-Content -LiteralPath (Join-Path $temporaryDirectory 'api-missing.json') -Raw | ConvertFrom-Json
    $apiUnexpectedEvidence = Get-Content -LiteralPath (Join-Path $temporaryDirectory 'api-unexpected.json') -Raw | ConvertFrom-Json
    if ((@($apiMissingEvidence.applicationVerification.missing | ForEach-Object { [string] $_ }) -join '|') -cne 'LgrTransformationMigration.Api.pdb' -or
        (@($apiUnexpectedEvidence.applicationVerification.unexpected | ForEach-Object { [string] $_ }) -join '|') -cne 'unexpected.metadata') {
        throw 'API verification did not fail closed for the exact missing and unexpected paths.'
    }

    Write-Output 'Deployed-content regression passed exact API/Web path-length-SHA256 reconciliation, equal-size synthetic DLL/PDB mismatch rejection, API missing/unexpected rejection, bounded Web Oryx metadata, explicit dependency transformation, timestamp/size collision, square-bracket chunk and changed build-ID gates.'
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) { Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force }
}
