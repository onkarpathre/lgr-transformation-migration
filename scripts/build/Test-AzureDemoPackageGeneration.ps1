[CmdletBinding()]
param(
    [string] $PackageDirectory = 'artifacts/azure-demo-ci/packages',
    [string] $ExpectedSourceCommit
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path (Join-Path $PSScriptRoot '..') '..')).ProviderPath
$utilities = Join-Path $PSScriptRoot 'AzureDemoPackageUtilities.ps1'
$packageScript = Join-Path $PSScriptRoot 'New-AzureDemoPackages.ps1'
. $utilities
. (Join-Path $PSScriptRoot 'AzureDemoDeploymentArtifactUtilities.ps1')
. (Join-Path $repo 'scripts\deployment\AzureDemoStagingDeployment.ps1')
Add-Type -AssemblyName System.IO.Compression.FileSystem

if ([string]::IsNullOrWhiteSpace($ExpectedSourceCommit)) {
    $ExpectedSourceCommit = (& git -C $repo rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Could not establish the expected package source commit.' }
}

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
$manifestCreatedAt = ConvertTo-AzureDemoManifestUtcTimestamp -Value $manifest.createdAtUtc
if ($null -eq $manifestCreatedAt) {
    throw 'Application package manifest createdAtUtc is invalid.'
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

        $archive = [IO.Compression.ZipFile]::OpenRead($zipPath)
        try {
            $archiveFiles = @($archive.Entries | Where-Object {
                    -not $_.FullName.Replace('\', '/').EndsWith('/', [StringComparison]::Ordinal)
                })
            $entryTimestamps = @($archiveFiles | ForEach-Object {
                    $_.LastWriteTime.DateTime.ToString('yyyy-MM-ddTHH:mm:ss', [Globalization.CultureInfo]::InvariantCulture)
                } | Sort-Object -Unique)
            if ($archiveFiles.Count -eq 0 -or $entryTimestamps.Count -ne 1) {
                throw "$name must contain files with one uniform immutable entry timestamp."
            }
            $entryTimestamp = $archiveFiles[0].LastWriteTime
            $entryTimestampUtcWallClock = [DateTimeOffset]::new(
                $entryTimestamp.Year,
                $entryTimestamp.Month,
                $entryTimestamp.Day,
                $entryTimestamp.Hour,
                $entryTimestamp.Minute,
                $entryTimestamp.Second,
                [TimeSpan]::Zero)
            $expectedEntryTimestamp = ConvertTo-AzureDemoZipEntryTimestamp -Timestamp $manifestCreatedAt
            if ($entryTimestamp.Year -lt 2020 -or $entryTimestampUtcWallClock -ne $expectedEntryTimestamp) {
                throw "$name does not retain the package-creation timestamp bound to manifest createdAtUtc."
            }
        }
        finally { $archive.Dispose() }

        $expanded = Join-Path $regressionDirectory ([IO.Path]::GetFileNameWithoutExtension($name))
        Expand-Archive -LiteralPath $zipPath -DestinationPath $expanded
        $expandedFiles = @(Get-ChildItem -LiteralPath $expanded -Recurse -File -Force)
        if ($expandedFiles.Count -eq 0) {
            throw "$name contains no files."
        }
        $expandedTimestamps = @($expandedFiles | ForEach-Object {
                $_.LastWriteTime.ToString('yyyy-MM-ddTHH:mm:ss', [Globalization.CultureInfo]::InvariantCulture)
            } | Sort-Object -Unique)
        $expectedTimestampText = $expectedEntryTimestamp.ToString(
            'yyyy-MM-ddTHH:mm:ss', [Globalization.CultureInfo]::InvariantCulture)
        if ($expandedTimestamps.Count -ne 1 -or $expandedTimestamps[0] -cne $expectedTimestampText) {
            throw "$name extraction did not preserve the serialized UTC wall-clock components."
        }

        $repeatOne = Join-Path $regressionDirectory ("repeat-1-$name")
        $repeatTwo = Join-Path $regressionDirectory ("repeat-2-$name")
        $repeatArguments = @{ SourceDirectory = $expanded; EntryTimestamp = $entryTimestampUtcWallClock }
        New-AzureDemoDeterministicZip @repeatArguments -DestinationPath $repeatOne
        New-AzureDemoDeterministicZip @repeatArguments -DestinationPath $repeatTwo
        $repeatOneHash = (Get-FileHash -LiteralPath $repeatOne -Algorithm SHA256).Hash
        $repeatTwoHash = (Get-FileHash -LiteralPath $repeatTwo -Algorithm SHA256).Hash
        if ($repeatOneHash -ne $repeatTwoHash -or $repeatOneHash -ne (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash) {
            throw "$name generation is not reproducible for fixed payload bytes and one explicit entry timestamp."
        }

        $sameBucketZip = Join-Path $regressionDirectory ("same-time-bucket-$name")
        $nextBucketZip = Join-Path $regressionDirectory ("next-time-bucket-$name")
        New-AzureDemoDeterministicZip -SourceDirectory $expanded -DestinationPath $sameBucketZip `
            -EntryTimestamp $expectedEntryTimestamp.AddMilliseconds(1900)
        New-AzureDemoDeterministicZip -SourceDirectory $expanded -DestinationPath $nextBucketZip `
            -EntryTimestamp $expectedEntryTimestamp.AddSeconds(2)
        $sameBucketHash = (Get-FileHash -LiteralPath $sameBucketZip -Algorithm SHA256).Hash
        $nextBucketHash = (Get-FileHash -LiteralPath $nextBucketZip -Algorithm SHA256).Hash
        if ($sameBucketHash -cne $repeatOneHash) {
            throw "$name did not retain the documented ZIP two-second timestamp bucket."
        }
        if ($nextBucketHash -ceq $repeatOneHash) {
            throw "$name did not change bytes when the serialized entry timestamp changed."
        }

        $timezoneRejection = $null
        try {
            New-AzureDemoDeterministicZip -SourceDirectory $expanded `
                -DestinationPath (Join-Path $regressionDirectory ("non-utc-$name")) `
                -EntryTimestamp ([DateTimeOffset]::new(
                    $expectedEntryTimestamp.DateTime,
                    [TimeSpan]::FromHours(1)))
        }
        catch { $timezoneRejection = $_ }
        if ($null -eq $timezoneRejection -or
            $timezoneRejection.Exception.Message -cne 'ZIP entry timestamp must use a UTC offset.') {
            throw "$name did not reject timezone-ambiguous package timestamp input."
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

$deploymentManifestPath = Join-Path $packageRoot 'deployment-artifact-manifest.json'
$deployment = Assert-AzureDemoDeploymentArtifact `
    -ArtifactRoot $packageRoot `
    -ManifestPath $deploymentManifestPath `
    -ExpectedSourceCommit $ExpectedSourceCommit
$deploymentManifest = Get-Content -LiteralPath $deployment.ManifestPath -Raw | ConvertFrom-Json
$manifestPaths = @($deploymentManifest.artifacts | ForEach-Object { [string] $_.path })
foreach ($requiredPath in @(
        'seed/AzureDemo.DataTool.dll',
        'demo-data/azure-demo-seed-manifest.json',
        'samples/discovery/azure-migrate-server-report-demo.csv')) {
    if ($manifestPaths -cnotcontains $requiredPath) {
        throw "Deployment artifact manifest does not hash-protect required seed payload $requiredPath."
    }
}

Write-Output "Azure demo package regression passed repository-boundary, API/web ZIP timestamp serialization, rounding/timezone, exact-file manifest, SHA-256, fixed-input reproducibility and immutable-artifact checks for $($deployment.ArtifactCount) payload files."
