[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).ProviderPath
. (Join-Path $repo 'scripts\build\AzureDemoPackageUtilities.ps1')
. (Join-Path $repo 'scripts\build\AzureDemoDeploymentArtifactUtilities.ps1')
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

function New-WebTree {
    param(
        [Parameter(Mandatory)] [string] $Root,
        [Parameter(Mandatory)] [string] $BuildId,
        [Parameter(Mandatory)] [string] $ChunkContent,
        [ValidateSet('Expanded', 'None', 'node_modules.tar.gz', 'node_modules.tgz', 'node_modules.tar.zst', 'node_modules.zip')]
        [string] $DependencyRepresentation = 'Expanded',
        [string] $DependencyArchivePath,
        [switch] $CompressedDependencies,
        [switch] $MissingChunk
    )
    New-Item -ItemType Directory -Path $Root -Force | Out-Null
    New-TextFile $Root 'server.js' 'server-entry'
    New-TextFile $Root '.next/BUILD_ID' $BuildId
    New-TextFile $Root '.next/server/app/page.js' 'page-entry'
    if (-not $MissingChunk) { New-TextFile $Root '.next/server/chunks/ssr/[root-of-the-server]__fixture._.js' $ChunkContent }
    New-TextFile $Root '.next/static/chunks/app-12345678.js' 'static-entry'
    if ($CompressedDependencies) { $DependencyRepresentation = 'node_modules.tar.gz' }
    if ($DependencyRepresentation -ceq 'Expanded') {
        New-TextFile $Root 'node_modules/next/index.js' 'dependency-entry'
    }
    elseif ($DependencyRepresentation -cne 'None') {
        $destination = Join-Path $Root $DependencyRepresentation
        if ([string]::IsNullOrWhiteSpace($DependencyArchivePath)) {
            New-SyntheticBinaryFile $Root $DependencyRepresentation 37 128
        }
        else {
            New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
            Copy-Item -LiteralPath $DependencyArchivePath -Destination $destination
        }
    }
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

function New-TimestampBoundZip([string] $Source, [string] $Destination, [DateTimeOffset] $EntryTimestamp) {
    New-AzureDemoDeterministicZip -SourceDirectory $Source -DestinationPath $Destination -EntryTimestamp $EntryTimestamp
}

function Invoke-NativeFixtureCommand {
    param(
        [Parameter(Mandatory)] [string] $FilePath,
        [Parameter(Mandatory)] [string[]] $Arguments,
        [Parameter(Mandatory)] [string] $Operation
    )

    $stdoutPath = Join-Path $temporaryDirectory ("native-$([Guid]::NewGuid().ToString('N')).stdout")
    $stderrPath = Join-Path $temporaryDirectory ("native-$([Guid]::NewGuid().ToString('N')).stderr")
    $priorErrorActionPreference = $ErrorActionPreference
    try {
        try {
            $ErrorActionPreference = 'Continue'
            & $FilePath @Arguments 1> $stdoutPath 2> $stderrPath
            $exitCode = $LASTEXITCODE
        }
        finally { $ErrorActionPreference = $priorErrorActionPreference }
        return [pscustomobject]@{
            ExitCode = $exitCode
            Stdout = if (Test-Path -LiteralPath $stdoutPath) { [IO.File]::ReadAllText($stdoutPath) } else { '' }
            Stderr = if (Test-Path -LiteralPath $stderrPath) { [IO.File]::ReadAllText($stderrPath) } else { '' }
            Operation = $Operation
        }
    }
    finally {
        Remove-Item -LiteralPath $stdoutPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $stderrPath -Force -ErrorAction SilentlyContinue
    }
}

function Resolve-ValidatedFixtureExecutable {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [string[]] $ValidationArguments
    )

    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $candidatePaths = [Collections.Generic.List[string]]::new()
    foreach ($command in @(Get-Command -Name $Name -All -CommandType Application -ErrorAction SilentlyContinue)) {
        $candidate = if ([string]::IsNullOrWhiteSpace([string] $command.Path)) { [string] $command.Source } else { [string] $command.Path }
        if ([string]::IsNullOrWhiteSpace($candidate) -or -not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
        $resolved = (Resolve-Path -LiteralPath $candidate).ProviderPath
        if ($seen.Add($resolved)) { $candidatePaths.Add($resolved) }
    }

    foreach ($candidatePath in $candidatePaths) {
        $validation = Invoke-NativeFixtureCommand -FilePath $candidatePath -Arguments $ValidationArguments -Operation "$Name executable validation"
        if ($validation.ExitCode -eq 0) {
            return [pscustomobject]@{
                Path = $candidatePath
                CandidateCount = $candidatePaths.Count
                VersionOutput = ([string]::Join("`n", @($validation.Stdout.Trim(), $validation.Stderr.Trim()))).Trim()
            }
        }
    }
    return $null
}

function New-RealZstandardDependencyArchive {
    param([Parameter(Mandatory)] [string] $Root)

    $tarExecutable = Resolve-ValidatedFixtureExecutable -Name 'tar' -ValidationArguments @('--version')
    $zstdExecutable = Resolve-ValidatedFixtureExecutable -Name 'zstd' -ValidationArguments @('--version')
    if ($null -eq $tarExecutable -or $null -eq $zstdExecutable) { return $null }

    $payloadRoot = Join-Path $Root 'zstd-payload'
    New-TextFile $payloadRoot 'node_modules/next/index.js' 'real-zstandard-dependency-entry'
    $tarPath = Join-Path $Root 'node_modules.tar'
    $zstdPath = Join-Path $Root 'node_modules.tar.zst'
    $tarResult = Invoke-NativeFixtureCommand -FilePath $tarExecutable.Path `
        -Arguments @('-cf', $tarPath, '-C', $payloadRoot, 'node_modules') -Operation 'Zstandard fixture TAR creation'
    if ($tarResult.ExitCode -ne 0) { throw "Zstandard fixture TAR creation failed with exit code $($tarResult.ExitCode)." }
    $zstdResult = Invoke-NativeFixtureCommand -FilePath $zstdExecutable.Path `
        -Arguments @('--quiet', '--force', '-o', $zstdPath, $tarPath) -Operation 'Zstandard fixture compression'
    if ($zstdResult.ExitCode -ne 0) { throw "Zstandard fixture compression failed with exit code $($zstdResult.ExitCode)." }
    $testResult = Invoke-NativeFixtureCommand -FilePath $zstdExecutable.Path `
        -Arguments @('--quiet', '--test', $zstdPath) -Operation 'Zstandard fixture integrity test'
    if ($testResult.ExitCode -ne 0) { throw "Zstandard fixture integrity test failed with exit code $($testResult.ExitCode)." }
    if (-not (Test-Path -LiteralPath $zstdPath -PathType Leaf) -or (Get-Item -LiteralPath $zstdPath).Length -le 0) {
        throw 'Zstandard fixture compression returned no non-empty archive.'
    }
    return [pscustomobject]@{
        Path = $zstdPath
        TarExecutable = $tarExecutable
        ZstdExecutable = $zstdExecutable
        CompressionExitCode = $zstdResult.ExitCode
        IntegrityTestExitCode = $testResult.ExitCode
    }
}

function New-ProductionCallerArtifact {
    param(
        [Parameter(Mandatory)] [string] $ArtifactRoot,
        [Parameter(Mandatory)] [string] $ExpectedTree,
        [Parameter(Mandatory)] [DateTimeOffset] $EntryTimestamp
    )

    $applicationRoot = Join-Path $ArtifactRoot 'application'
    New-Item -ItemType Directory -Path $applicationRoot -Force | Out-Null
    $webZip = Join-Path $applicationRoot 'web.zip'
    New-TimestampBoundZip -Source $ExpectedTree -Destination $webZip -EntryTimestamp $EntryTimestamp
    [ordered]@{
        schemaVersion = '1'
        sourceCommit = $sourceCommit
        createdAtUtc = $EntryTimestamp.ToString('O')
        nodeVersion = 'v24.0.0'
        dotnetSdkVersion = '10.0.100'
        artifacts = @([ordered]@{
                name = 'web.zip'
                sha256 = (Get-FileHash -LiteralPath $webZip -Algorithm SHA256).Hash.ToLowerInvariant()
            })
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $applicationRoot 'application-artifact-manifest.json') -Encoding UTF8
    $deploymentManifest = New-AzureDemoDeploymentArtifactManifest -ArtifactRoot $ArtifactRoot -SourceCommit $sourceCommit
    return [pscustomobject]@{ WebZip = $webZip; DeploymentManifest = $deploymentManifest }
}

function Invoke-ProductionVerifierProcess {
    param(
        [Parameter(Mandatory)] [string] $ArtifactRoot,
        [Parameter(Mandatory)] [string] $DeploymentManifestPath,
        [Parameter(Mandatory)] [string] $DeployedZipPath,
        [Parameter(Mandatory)] [string] $EvidencePath
    )

    $powerShellPath = [string] (Get-Process -Id $PID).Path
    if ([string]::IsNullOrWhiteSpace($powerShellPath) -or -not (Test-Path -LiteralPath $powerShellPath -PathType Leaf)) {
        throw 'The current PowerShell executable path is invalid.'
    }
    $stdoutPath = "$EvidencePath.stdout"
    $stderrPath = "$EvidencePath.stderr"
    $arguments = @('-NoLogo', '-NoProfile', '-NonInteractive')
    if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Windows)) {
        $arguments += @('-ExecutionPolicy', 'Bypass')
    }
    $arguments += @(
        '-File', (Join-Path $repo 'scripts\deployment\Invoke-AzureDemoSlotContentVerification.ps1'),
        '-SubscriptionId', '633398e2-6c00-4bb7-a576-2db0d210ee77',
        '-ResourceGroupName', 'Onkar.Pathre',
        '-Workload', 'Web',
        '-AppName', 'app-mtp-web-dev-uks-001',
        '-SlotName', 'staging',
        '-ArtifactRoot', $ArtifactRoot,
        '-DeploymentManifestPath', $DeploymentManifestPath,
        '-ExpectedSourceCommit', $sourceCommit,
        '-EvidencePath', $EvidencePath,
        '-DeployedContentZipPath', $DeployedZipPath)
    $priorErrorActionPreference = $ErrorActionPreference
    try {
        try {
            $ErrorActionPreference = 'Continue'
            & $powerShellPath @arguments 1> $stdoutPath 2> $stderrPath
            $exitCode = $LASTEXITCODE
        }
        finally { $ErrorActionPreference = $priorErrorActionPreference }
        return [pscustomobject]@{
            ExitCode = $exitCode
            Stdout = if (Test-Path -LiteralPath $stdoutPath) { [IO.File]::ReadAllText($stdoutPath) } else { '' }
            Stderr = if (Test-Path -LiteralPath $stderrPath) { [IO.File]::ReadAllText($stderrPath) } else { '' }
        }
    }
    finally {
        Remove-Item -LiteralPath $stdoutPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $stderrPath -Force -ErrorAction SilentlyContinue
    }
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
        $pass.dependencyTransformation.archiveIntegrityValidation.status -cne 'not-performed' -or
        [bool] $pass.dependencyTransformation.archiveIntegrityValidation.performed -or
        (@($pass.dependencyTransformation.archiveIntegrityValidation.recognizedArchivePaths) -join '|') -cne 'node_modules.tar.gz' -or
        [string]::IsNullOrWhiteSpace([string] $pass.dependencyTransformation.archiveIntegrityValidation.limitation) -or
        @($pass.dependencyTransformation.payloadValidation.emptyDeployedArchives).Count -ne 0 -or
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

    foreach ($representation in @('Expanded', 'node_modules.tar.gz', 'node_modules.tgz', 'node_modules.zip')) {
        $representationRoot = Join-Path $temporaryDirectory ("supported-" + $representation.Replace('.', '-'))
        New-WebTree -Root $representationRoot -BuildId 'BUILD00000000002' -ChunkContent 'BBBB' `
            -DependencyRepresentation $representation
        $representationZip = "$representationRoot.zip"
        New-Zip $representationRoot $representationZip
        $representationEvidencePath = "$representationRoot.json"
        Compare-AzureDemoDeployedZip -Workload Web -ExpectedZipPath $expectedTwoZip -DeployedZipPath $representationZip `
            -EvidencePath $representationEvidencePath -SourceCommit $sourceCommit -ResourceId $resourceId | Out-Null
        $representationEvidence = Get-Content -LiteralPath $representationEvidencePath -Raw | ConvertFrom-Json
        if ($representationEvidence.status -cne 'PASS' -or
            @($representationEvidence.applicationVerification.missing).Count -ne 0 -or
            @($representationEvidence.applicationVerification.changed).Count -ne 0 -or
            @($representationEvidence.applicationVerification.unexpected).Count -ne 0 -or
            @($representationEvidence.applicationVerification.requiredFailures).Count -ne 0) {
            throw "Existing dependency representation $representation did not remain supported."
        }
        if ($representation -ceq 'Expanded') {
            if ($representationEvidence.dependencyTransformation.archiveIntegrityValidation.status -cne 'not-applicable') {
                throw 'Expanded node_modules evidence incorrectly reported archive integrity validation.'
            }
        }
        elseif ($representationEvidence.dependencyTransformation.archiveIntegrityValidation.status -cne 'not-performed' -or
            (@($representationEvidence.dependencyTransformation.archiveIntegrityValidation.recognizedArchivePaths) -join '|') -cne $representation) {
            throw "Archive representation $representation did not retain the explicit archive-integrity limitation."
        }
    }

    $missingDependencyRoot = Join-Path $temporaryDirectory 'missing-dependency'
    New-WebTree -Root $missingDependencyRoot -BuildId 'BUILD00000000002' -ChunkContent 'BBBB' -DependencyRepresentation None
    $missingDependencyZip = Join-Path $temporaryDirectory 'missing-dependency.zip'
    $missingDependencyEvidencePath = Join-Path $temporaryDirectory 'missing-dependency.json'
    New-Zip $missingDependencyRoot $missingDependencyZip
    Assert-Rejected {
        Compare-AzureDemoDeployedZip -Workload Web -ExpectedZipPath $expectedTwoZip -DeployedZipPath $missingDependencyZip `
            -EvidencePath $missingDependencyEvidencePath -SourceCommit $sourceCommit -ResourceId $resourceId | Out-Null
    } 'a missing dependency payload'
    $missingDependencyEvidence = Get-Content -LiteralPath $missingDependencyEvidencePath -Raw | ConvertFrom-Json
    if ((@($missingDependencyEvidence.applicationVerification.requiredFailures) -join '|') -cne 'dependency-payload-missing') {
        throw 'Missing dependency evidence did not retain the required dependency-payload-missing failure.'
    }

    foreach ($archiveName in @('node_modules.tar.gz', 'node_modules.tgz', 'node_modules.tar.zst', 'node_modules.zip')) {
        $emptyRoot = Join-Path $temporaryDirectory ("empty-" + $archiveName.Replace('.', '-'))
        New-WebTree -Root $emptyRoot -BuildId 'BUILD00000000002' -ChunkContent 'BBBB' -DependencyRepresentation $archiveName
        [IO.File]::WriteAllBytes((Join-Path $emptyRoot $archiveName), [byte[]]::new(0))
        $emptyZip = "$emptyRoot.zip"
        $emptyEvidencePath = "$emptyRoot.json"
        New-Zip $emptyRoot $emptyZip
        Assert-Rejected {
            Compare-AzureDemoDeployedZip -Workload Web -ExpectedZipPath $expectedTwoZip -DeployedZipPath $emptyZip `
                -EvidencePath $emptyEvidencePath -SourceCommit $sourceCommit -ResourceId $resourceId | Out-Null
        } "an empty $archiveName dependency payload"
        $emptyEvidence = Get-Content -LiteralPath $emptyEvidencePath -Raw | ConvertFrom-Json
        if ((@($emptyEvidence.applicationVerification.requiredFailures) -join '|') -cne "deployed-empty-dependency-archive:$archiveName" -or
            (@($emptyEvidence.dependencyTransformation.payloadValidation.emptyDeployedArchives) -join '|') -cne $archiveName) {
            throw "Empty dependency archive evidence was incomplete for $archiveName."
        }
    }

    foreach ($unexpectedDependencyPath in @(
            'node_modules.tar.zstd',
            'node_modules-copy.tar.zst',
            'nested/node_modules.tar.zst',
            'Node_Modules.tar.zst')) {
        $scenarioName = $unexpectedDependencyPath.Replace('/', '-').Replace('.', '-')
        $unexpectedDependencyRoot = Join-Path $temporaryDirectory "unexpected-dependency-$scenarioName"
        New-WebTree -Root $unexpectedDependencyRoot -BuildId 'BUILD00000000002' -ChunkContent 'BBBB' -DependencyRepresentation None
        New-SyntheticBinaryFile $unexpectedDependencyRoot $unexpectedDependencyPath 51 128
        $unexpectedDependencyZip = "$unexpectedDependencyRoot.zip"
        $unexpectedDependencyEvidencePath = "$unexpectedDependencyRoot.json"
        New-Zip $unexpectedDependencyRoot $unexpectedDependencyZip
        Assert-Rejected {
            Compare-AzureDemoDeployedZip -Workload Web -ExpectedZipPath $expectedTwoZip -DeployedZipPath $unexpectedDependencyZip `
                -EvidencePath $unexpectedDependencyEvidencePath -SourceCommit $sourceCommit -ResourceId $resourceId | Out-Null
        } "the unsupported dependency-like path $unexpectedDependencyPath"
        $unexpectedDependencyEvidence = Get-Content -LiteralPath $unexpectedDependencyEvidencePath -Raw | ConvertFrom-Json
        if ((@($unexpectedDependencyEvidence.applicationVerification.unexpected) -join '|') -cne $unexpectedDependencyPath -or
            (@($unexpectedDependencyEvidence.applicationVerification.requiredFailures) -join '|') -cne 'dependency-payload-missing') {
            throw "Unsupported dependency-like path was not rejected exactly: $unexpectedDependencyPath."
        }
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
    $staleEvidence = Get-Content -LiteralPath (Join-Path $temporaryDirectory 'stale.json') -Raw | ConvertFrom-Json
    $missingApplicationEvidence = Get-Content -LiteralPath (Join-Path $temporaryDirectory 'missing.json') -Raw | ConvertFrom-Json
    $unexpectedApplicationEvidence = Get-Content -LiteralPath (Join-Path $temporaryDirectory 'unknown-extra.json') -Raw | ConvertFrom-Json
    if (@($staleEvidence.applicationVerification.changed).Count -eq 0 -or
        (@($missingApplicationEvidence.applicationVerification.missing) -join '|') -cne '.next/server/chunks/ssr/[root-of-the-server]__fixture._.js' -or
        (@($unexpectedApplicationEvidence.applicationVerification.unexpected) -join '|') -cne 'unexpected-platform-file.toml') {
        throw 'Web changed, missing and unexpected application-file evidence was incomplete.'
    }

    $callerExpectedRoot = Join-Path $temporaryDirectory 'caller-expected'
    $callerDeployedRoot = Join-Path $temporaryDirectory 'caller-deployed'
    $callerMissingDependencyRoot = Join-Path $temporaryDirectory 'caller-missing-dependency'
    New-WebTree -Root $callerExpectedRoot -BuildId 'BUILD00000000002' -ChunkContent 'BBBB'
    New-WebTree -Root $callerDeployedRoot -BuildId 'BUILD00000000002' -ChunkContent 'BBBB'
    New-WebTree -Root $callerMissingDependencyRoot -BuildId 'BUILD00000000002' -ChunkContent 'BBBB' -DependencyRepresentation None
    $callerArtifactRoot = Join-Path $temporaryDirectory 'caller-artifact'
    $callerArtifact = New-ProductionCallerArtifact -ArtifactRoot $callerArtifactRoot -ExpectedTree $callerExpectedRoot `
        -EntryTimestamp ([DateTimeOffset]::UtcNow)
    $callerDeployedZip = Join-Path $temporaryDirectory 'caller-deployed.zip'
    $callerMissingDependencyZip = Join-Path $temporaryDirectory 'caller-missing-dependency.zip'
    New-Zip $callerDeployedRoot $callerDeployedZip
    New-Zip $callerMissingDependencyRoot $callerMissingDependencyZip
    $callerPassEvidencePath = Join-Path $temporaryDirectory 'caller-pass.json'
    $callerPassProcess = Invoke-ProductionVerifierProcess -ArtifactRoot $callerArtifactRoot `
        -DeploymentManifestPath $callerArtifact.DeploymentManifest -DeployedZipPath $callerDeployedZip `
        -EvidencePath $callerPassEvidencePath
    if ($callerPassProcess.ExitCode -ne 0) {
        throw "Production verifier caller pass scenario exited $($callerPassProcess.ExitCode): $($callerPassProcess.Stderr)"
    }
    $callerPassEvidence = Get-Content -LiteralPath $callerPassEvidencePath -Raw | ConvertFrom-Json
    if ($callerPassEvidence.status -cne 'PASS' -or $callerPassEvidence.sourceCommit -cne $sourceCommit -or
        $callerPassEvidence.resourceId -cne $resourceId -or
        $callerPassEvidence.expectedZipSha256 -cne (Get-FileHash -LiteralPath $callerArtifact.WebZip -Algorithm SHA256).Hash.ToLowerInvariant()) {
        throw 'Production verifier caller did not retain target, source-commit and immutable ZIP-hash binding.'
    }

    $callerFailEvidencePath = Join-Path $temporaryDirectory 'caller-fail.json'
    $callerFailProcess = Invoke-ProductionVerifierProcess -ArtifactRoot $callerArtifactRoot `
        -DeploymentManifestPath $callerArtifact.DeploymentManifest -DeployedZipPath $callerMissingDependencyZip `
        -EvidencePath $callerFailEvidencePath
    $callerFailEvidence = Get-Content -LiteralPath $callerFailEvidencePath -Raw | ConvertFrom-Json
    if ($callerFailProcess.ExitCode -eq 0 -or $callerFailEvidence.status -cne 'FAIL' -or
        (@($callerFailEvidence.applicationVerification.requiredFailures) -join '|') -cne 'dependency-payload-missing') {
        throw 'Production verifier caller did not return a non-zero process exit for a missing dependency payload.'
    }

    $zstandardFixture = New-RealZstandardDependencyArchive -Root $temporaryDirectory
    $zstandardStatus = 'EXECUTED'
    if ($null -eq $zstandardFixture) {
        if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Linux)) {
            throw 'Linux deployed-content verification requires validated tar and zstd executables for the real Zstandard fixture.'
        }
        $zstandardStatus = 'LINUX_CI_PENDING'
        Write-Warning 'Real Zstandard dependency regression is LINUX_CI_PENDING because validated tar and zstd executables are unavailable on this non-Linux host.'
    }
    else {
        $zstandardExpectedRoot = Join-Path $temporaryDirectory 'zstandard-expected'
        $zstandardDeployedRoot = Join-Path $temporaryDirectory 'zstandard-deployed'
        New-WebTree -Root $zstandardExpectedRoot -BuildId 'BUILD00000000002' -ChunkContent 'BBBB'
        New-WebTree -Root $zstandardDeployedRoot -BuildId 'BUILD00000000002' -ChunkContent 'BBBB' `
            -DependencyRepresentation 'node_modules.tar.zst' -DependencyArchivePath $zstandardFixture.Path
        $zstandardExpectedZip = Join-Path $temporaryDirectory 'zstandard-expected.zip'
        $zstandardDeployedZip = Join-Path $temporaryDirectory 'zstandard-deployed.zip'
        New-Zip $zstandardExpectedRoot $zstandardExpectedZip
        New-Zip $zstandardDeployedRoot $zstandardDeployedZip
        $zstandardEvidencePath = Join-Path $temporaryDirectory 'zstandard-pass.json'
        Compare-AzureDemoDeployedZip -Workload Web -ExpectedZipPath $zstandardExpectedZip -DeployedZipPath $zstandardDeployedZip `
            -EvidencePath $zstandardEvidencePath -SourceCommit $sourceCommit -ResourceId $resourceId | Out-Null
        $zstandardEvidence = Get-Content -LiteralPath $zstandardEvidencePath -Raw | ConvertFrom-Json
        if ($zstandardEvidence.status -cne 'PASS' -or
            (@($zstandardEvidence.applicationVerification.unexpected) -join '|') -cne '' -or
            (@($zstandardEvidence.applicationVerification.requiredFailures) -join '|') -cne '' -or
            (@($zstandardEvidence.dependencyTransformation.deployedPaths) -join '|') -cne 'node_modules.tar.zst' -or
            [bool] $zstandardEvidence.dependencyTransformation.exactDependencyBytesCompared -or
            [bool] $zstandardEvidence.dependencyTransformation.archiveIntegrityValidation.performed -or
            $zstandardEvidence.dependencyTransformation.archiveIntegrityValidation.status -cne 'not-performed' -or
            (@($zstandardEvidence.dependencyTransformation.archiveIntegrityValidation.recognizedArchivePaths) -join '|') -cne 'node_modules.tar.zst' -or
            [string] $zstandardEvidence.dependencyTransformation.archiveIntegrityValidation.limitation -cnotmatch 'do not validate dependency archive format/frame integrity') {
            throw 'Real Zstandard dependency evidence did not retain exact classification and archive-integrity limitations.'
        }

        $zstandardCallerArtifactRoot = Join-Path $temporaryDirectory 'zstandard-caller-artifact'
        $zstandardCallerArtifact = New-ProductionCallerArtifact -ArtifactRoot $zstandardCallerArtifactRoot `
            -ExpectedTree $zstandardExpectedRoot -EntryTimestamp ([DateTimeOffset]::UtcNow)
        $zstandardCallerEvidencePath = Join-Path $temporaryDirectory 'zstandard-caller.json'
        $zstandardCallerProcess = Invoke-ProductionVerifierProcess -ArtifactRoot $zstandardCallerArtifactRoot `
            -DeploymentManifestPath $zstandardCallerArtifact.DeploymentManifest -DeployedZipPath $zstandardDeployedZip `
            -EvidencePath $zstandardCallerEvidencePath
        if ($zstandardCallerProcess.ExitCode -ne 0) {
            throw "Production verifier rejected the real Zstandard dependency fixture with exit code $($zstandardCallerProcess.ExitCode): $($zstandardCallerProcess.Stderr)"
        }
        $zstandardCallerEvidence = Get-Content -LiteralPath $zstandardCallerEvidencePath -Raw | ConvertFrom-Json
        if ($zstandardCallerEvidence.status -cne 'PASS' -or
            (@($zstandardCallerEvidence.dependencyTransformation.deployedPaths) -join '|') -cne 'node_modules.tar.zst') {
            throw 'Production verifier caller did not classify the real root Zstandard payload as a dependency transformation.'
        }
        Write-Output ("Real Zstandard dependency fixture passed native compression/test and production caller checks: tar={0}; zstd={1}; zstdCandidates={2}; compressionExit={3}; integrityTestExit={4}." -f `
                $zstandardFixture.TarExecutable.Path, $zstandardFixture.ZstdExecutable.Path,
                $zstandardFixture.ZstdExecutable.CandidateCount, $zstandardFixture.CompressionExitCode,
                $zstandardFixture.IntegrityTestExitCode)
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

    Write-Output "Deployed-content regression passed exact API/Web path-length-SHA256 reconciliation, supported dependency representations, missing/empty/near-name rejection, production caller exit behavior, bounded Web Oryx metadata, explicit dependency transformation, timestamp/size collision, square-bracket chunk and changed build-ID gates; ZstandardStatus=$zstandardStatus."
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) { Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force }
}
