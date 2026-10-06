[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Linux)) {
    throw 'The web deployment timestamp regression requires a real Linux host.'
}
if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'The web deployment timestamp regression requires PowerShell 7 or later.'
}
$rsync = Get-Command rsync -CommandType Application -ErrorAction SilentlyContinue
if ($null -eq $rsync) { throw 'The web deployment timestamp regression requires Linux rsync.' }

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).ProviderPath
. (Join-Path $repo 'scripts\build\AzureDemoPackageUtilities.ps1')

$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-linux-rsync-$([Guid]::NewGuid().ToString('N'))")
$legacyTimestamp = [DateTimeOffset] '1980-01-01T00:00:00+00:00'
$correctedTimestamp = [DateTimeOffset] '2026-10-06T12:34:56+00:00'
$expectedBuildId = 'SyIeOuurTS_H-Clua5oW0'
$staleBuildId = 'Xwvb4L_dSTn4jJilCsPfY'

function New-TextFile([string] $Root, [string] $RelativePath, [string] $Content) {
    $path = Join-Path $Root $RelativePath
    New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
    [IO.File]::WriteAllText($path, $Content, [Text.UTF8Encoding]::new($false))
}

function New-CollisionTree([string] $Root, [string] $BuildId, [char] $Marker) {
    New-Item -ItemType Directory -Path $Root -Force | Out-Null
    New-TextFile $Root 'server.js' 'unchanged-server-entry'
    New-TextFile $Root '.next/BUILD_ID' $BuildId
    foreach ($index in 1..20) {
        New-TextFile $Root ('.next/server/app/route-{0:d3}/page.js' -f $index) `
            (('{0:d3}:' -f $index) + ([string] $Marker * 32))
    }
    foreach ($index in 1..25) {
        New-TextFile $Root ('.next/server/chunks/chunk-{0:d3}.js' -f $index) `
            (('{0:d3}:' -f $index) + ([string] $Marker * 32))
    }
    foreach ($index in 1..20) {
        New-TextFile $Root ('.next/static/chunks/app-{0:d3}.js' -f $index) `
            (('{0:d3}:' -f $index) + ([string] $Marker * 32))
    }
    foreach ($file in Get-ChildItem -LiteralPath $Root -Recurse -File -Force) {
        $file.LastWriteTimeUtc = $legacyTimestamp.UtcDateTime
    }
}

function Get-ChangedFiles([string] $ExpectedRoot, [string] $ActualRoot) {
    $changes = [Collections.Generic.List[string]]::new()
    foreach ($expected in Get-ChildItem -LiteralPath $ExpectedRoot -Recurse -File -Force) {
        $relative = $expected.FullName.Substring($ExpectedRoot.Length).TrimStart([char[]] @('/', '\')).Replace('\', '/')
        $actual = Join-Path $ActualRoot $relative
        if (-not (Test-Path -LiteralPath $actual -PathType Leaf) -or
            $expected.Length -ne (Get-Item -LiteralPath $actual).Length -or
            (Get-FileHash -LiteralPath $expected.FullName -Algorithm SHA256).Hash -cne (Get-FileHash -LiteralPath $actual -Algorithm SHA256).Hash) {
            $changes.Add($relative)
        }
    }
    return @($changes)
}

function Expand-TestZip([string] $ZipPath, [string] $Destination) {
    [IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $Destination)
}

function Invoke-TestRsync([string] $Source, [string] $Destination) {
    $stderrPath = Join-Path $temporaryDirectory ("rsync-$([Guid]::NewGuid().ToString('N')).stderr")
    try {
        $sourceArgument = $Source.TrimEnd([char[]] @('/', '\')) + [IO.Path]::DirectorySeparatorChar
        $destinationArgument = $Destination.TrimEnd([char[]] @('/', '\')) + [IO.Path]::DirectorySeparatorChar
        $rows = @(& $rsync.Source '-a' '--delete' '--itemize-changes' '--out-format=%i|%n' '--' `
                $sourceArgument $destinationArgument 2> $stderrPath)
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            $stderrLength = if (Test-Path -LiteralPath $stderrPath) { (Get-Item -LiteralPath $stderrPath).Length } else { 0 }
            throw "Linux rsync fixture failed with exit code $exitCode and stderrLength=$stderrLength."
        }
        return @($rows | ForEach-Object { [string] $_ })
    }
    finally { Remove-Item -LiteralPath $stderrPath -Force -ErrorAction SilentlyContinue }
}

New-Item -ItemType Directory -Path $temporaryDirectory -Force | Out-Null
try {
    if ($expectedBuildId.Length -ne $staleBuildId.Length) {
        throw 'Observed BUILD_ID fixtures must have identical lengths.'
    }

    $expectedRoot = Join-Path $temporaryDirectory 'expected'
    $deployedRoot = Join-Path $temporaryDirectory 'deployed'
    New-CollisionTree -Root $expectedRoot -BuildId $expectedBuildId -Marker 'E'
    New-CollisionTree -Root $deployedRoot -BuildId $staleBuildId -Marker 'S'

    $initialChanges = @(Get-ChangedFiles -ExpectedRoot $expectedRoot -ActualRoot $deployedRoot)
    if ($initialChanges.Count -ne 66 -or $initialChanges -cnotcontains '.next/BUILD_ID') {
        throw "Linux collision fixture must start with exactly 66 equal-length changed application files; observed $($initialChanges.Count)."
    }
    foreach ($relative in $initialChanges) {
        $expectedFile = Get-Item -LiteralPath (Join-Path $expectedRoot $relative)
        $actualFile = Get-Item -LiteralPath (Join-Path $deployedRoot $relative)
        if ($expectedFile.Length -ne $actualFile.Length -or $expectedFile.LastWriteTimeUtc -ne $actualFile.LastWriteTimeUtc) {
            throw 'Linux collision fixture did not retain identical path, length and timestamp metadata.'
        }
    }

    $legacyZip = Join-Path $temporaryDirectory 'legacy-fixed-timestamp.zip'
    New-AzureDemoDeterministicZip -SourceDirectory $expectedRoot -DestinationPath $legacyZip
    $legacyExtract = Join-Path $temporaryDirectory 'legacy-extract'
    Expand-TestZip -ZipPath $legacyZip -Destination $legacyExtract
    $legacyRsync = @(Invoke-TestRsync -Source $legacyExtract -Destination $deployedRoot)
    $legacyTransferredFiles = @($legacyRsync | Where-Object { $_ -cmatch '^>f' })
    $afterLegacy = @(Get-ChangedFiles -ExpectedRoot $expectedRoot -ActualRoot $deployedRoot)
    if ($legacyTransferredFiles.Count -ne 0 -or $afterLegacy.Count -ne 66 -or
        (Get-Content -LiteralPath (Join-Path $deployedRoot '.next/BUILD_ID') -Raw).Trim() -cne $staleBuildId) {
        throw 'The fixed-timestamp rsync simulation did not reproduce stale equal-length application bytes and BUILD_ID.'
    }

    $correctedZip = Join-Path $temporaryDirectory 'deployment-timestamp.zip'
    New-AzureDemoDeterministicZip -SourceDirectory $expectedRoot -DestinationPath $correctedZip `
        -EntryTimestamp $correctedTimestamp
    $correctedZipHashBefore = (Get-FileHash -LiteralPath $correctedZip -Algorithm SHA256).Hash
    $correctedExtract = Join-Path $temporaryDirectory 'corrected-extract'
    Expand-TestZip -ZipPath $correctedZip -Destination $correctedExtract
    $correctedTimestamps = @(Get-ChildItem -LiteralPath $correctedExtract -Recurse -File -Force |
            ForEach-Object { $_.LastWriteTime.ToString('yyyy-MM-ddTHH:mm:ss', [Globalization.CultureInfo]::InvariantCulture) } |
            Sort-Object -Unique)
    if ($correctedTimestamps.Count -ne 1 -or $correctedTimestamps[0] -cne '2026-10-06T12:34:56') {
        throw 'Corrected ZIP extraction did not retain the deployment-specific timestamp on Linux.'
    }

    $correctedRsync = @(Invoke-TestRsync -Source $correctedExtract -Destination $deployedRoot)
    $transferredFiles = @($correctedRsync | Where-Object { $_ -cmatch '^>f' })
    $afterCorrection = @(Get-ChangedFiles -ExpectedRoot $expectedRoot -ActualRoot $deployedRoot)
    if ($afterCorrection.Count -ne 0 -or $transferredFiles.Count -ne 67 -or
        (Get-Content -LiteralPath (Join-Path $deployedRoot '.next/BUILD_ID') -Raw).Trim() -cne $expectedBuildId) {
        throw 'The deployment-specific timestamp did not force all expected Linux rsync file updates.'
    }
    $correctedZipHashAfter = (Get-FileHash -LiteralPath $correctedZip -Algorithm SHA256).Hash
    if ($correctedZipHashBefore -cne $correctedZipHashAfter) {
        throw 'The Linux correction simulation mutated the immutable web ZIP bytes.'
    }

    Write-Output ("Linux rsync simulation reproduced 66 stale equal-path/length/timestamp files " +
        "(legacyItemizedRows=$($legacyRsync.Count)) and corrected them with one immutable package timestamp " +
        "(transferredFiles=$($transferredFiles.Count)); this is not real Azure execution.")
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
}

if (Test-Path -LiteralPath $temporaryDirectory) {
    throw 'Linux web deployment timestamp regression cleanup left its temporary directory behind.'
}
exit 0
