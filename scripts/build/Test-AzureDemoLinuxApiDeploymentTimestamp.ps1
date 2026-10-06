[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Linux)) {
    throw 'The API deployment timestamp regression requires a real Linux host.'
}
if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'The API deployment timestamp regression requires PowerShell 7 or later.'
}

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).ProviderPath
. (Join-Path $repo 'scripts\build\AzureDemoPackageUtilities.ps1')

$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-linux-api-rsync-$([Guid]::NewGuid().ToString('N'))")
$legacyTimestamp = [DateTimeOffset] '1980-01-01T00:00:00+00:00'
$packageTimestamp = [DateTimeOffset] '2026-10-06T12:34:57.9000000+00:00'
$sameBucketTimestamp = [DateTimeOffset] '2026-10-06T12:34:56.1000000+00:00'
$nextBucketTimestamp = [DateTimeOffset] '2026-10-06T12:34:58.0000000+00:00'
$expectedSerializedTimestamp = ConvertTo-AzureDemoZipEntryTimestamp -Timestamp $packageTimestamp
$binaryNames = @('LgrTransformationMigration.Api.dll', 'LgrTransformationMigration.Api.pdb')

function Resolve-RequiredApplicationPath([string] $Name) {
    try {
        $commands = @(Get-Command -Name $Name -CommandType Application -ErrorAction Stop)
    }
    catch [Management.Automation.CommandNotFoundException] {
        throw "Required $Name executable was not found."
    }
    if ($commands.Count -eq 0) {
        throw "Required $Name executable was not found."
    }

    [Management.Automation.ApplicationInfo] $command = $commands[0]
    $applicationPath = [string] $command.Path
    if ([string]::IsNullOrWhiteSpace($applicationPath) -or
        -not (Test-Path -LiteralPath $applicationPath -PathType Leaf)) {
        throw "Resolved $Name executable path is invalid."
    }
    return $applicationPath
}

function New-SyntheticBinaryFile([string] $Root, [string] $Name, [byte] $Marker, [int] $Length) {
    New-Item -ItemType Directory -Path $Root -Force | Out-Null
    $bytes = New-Object byte[] $Length
    for ($index = 0; $index -lt $bytes.Length; $index++) {
        $bytes[$index] = [byte] (($Marker + $index) % 251)
    }
    $path = Join-Path $Root $Name
    [IO.File]::WriteAllBytes($path, $bytes)
    (Get-Item -LiteralPath $path).LastWriteTimeUtc = $legacyTimestamp.UtcDateTime
}

function New-SyntheticApiTree([string] $Root, [byte] $Marker) {
    # These fixtures model opaque binary deployment files, not assemblies.
    New-SyntheticBinaryFile -Root $Root -Name $binaryNames[0] -Marker $Marker -Length 4096
    New-SyntheticBinaryFile -Root $Root -Name $binaryNames[1] -Marker ([byte] ($Marker + 17)) -Length 2048
}

function Get-ChangedApiFiles([string] $ExpectedRoot, [string] $ActualRoot) {
    $changed = [Collections.Generic.List[string]]::new()
    foreach ($name in $binaryNames) {
        $expectedPath = Join-Path $ExpectedRoot $name
        $actualPath = Join-Path $ActualRoot $name
        if (-not (Test-Path -LiteralPath $actualPath -PathType Leaf) -or
            (Get-Item -LiteralPath $expectedPath).Length -ne (Get-Item -LiteralPath $actualPath).Length -or
            (Get-FileHash -LiteralPath $expectedPath -Algorithm SHA256).Hash -cne
                (Get-FileHash -LiteralPath $actualPath -Algorithm SHA256).Hash) {
            $changed.Add($name)
        }
    }
    return @($changed)
}

function Get-ZipWallClockTimestamps([string] $ZipPath) {
    $archive = [IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        return @($archive.Entries | Where-Object {
                -not $_.FullName.Replace('\', '/').EndsWith('/', [StringComparison]::Ordinal)
            } | ForEach-Object {
                $_.LastWriteTime.DateTime.ToString('yyyy-MM-ddTHH:mm:ss', [Globalization.CultureInfo]::InvariantCulture)
            } | Sort-Object -Unique)
    }
    finally { $archive.Dispose() }
}

function Assert-ExtractedWallClock([string] $Root, [DateTimeOffset] $Expected) {
    $actual = @(Get-ChildItem -LiteralPath $Root -Recurse -File -Force | ForEach-Object {
            $_.LastWriteTime.ToString('yyyy-MM-ddTHH:mm:ss', [Globalization.CultureInfo]::InvariantCulture)
        } | Sort-Object -Unique)
    $expectedText = $Expected.ToString('yyyy-MM-ddTHH:mm:ss', [Globalization.CultureInfo]::InvariantCulture)
    if ($actual.Count -ne 1 -or $actual[0] -cne $expectedText) {
        throw "ZIP extraction did not preserve expected wall-clock timestamp $expectedText."
    }
}

function Invoke-TestRsync([string] $RsyncPath, [string] $Source, [string] $Destination) {
    $stderrPath = Join-Path $temporaryDirectory ("rsync-$([Guid]::NewGuid().ToString('N')).stderr")
    try {
        $sourceArgument = $Source.TrimEnd([char[]] @('/', '\')) + [IO.Path]::DirectorySeparatorChar
        $destinationArgument = $Destination.TrimEnd([char[]] @('/', '\')) + [IO.Path]::DirectorySeparatorChar
        $arguments = @('-a', '--delete', '--itemize-changes', '--out-format=%i|%n', '--',
            $sourceArgument, $destinationArgument)
        $rows = @(& $RsyncPath @arguments 2> $stderrPath)
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            $stderrLength = if (Test-Path -LiteralPath $stderrPath) { (Get-Item -LiteralPath $stderrPath).Length } else { 0 }
            throw "Linux API rsync fixture failed with exit code $exitCode and stderrLength=$stderrLength."
        }
        return @($rows | ForEach-Object { [string] $_ })
    }
    finally { Remove-Item -LiteralPath $stderrPath -Force -ErrorAction SilentlyContinue }
}

New-Item -ItemType Directory -Path $temporaryDirectory -Force | Out-Null
try {
    $rsyncPath = Resolve-RequiredApplicationPath -Name 'rsync'
    $expectedRoot = Join-Path $temporaryDirectory 'expected'
    $deployedRoot = Join-Path $temporaryDirectory 'deployed'
    New-SyntheticApiTree -Root $expectedRoot -Marker 65
    New-SyntheticApiTree -Root $deployedRoot -Marker 83

    $initialChanges = @(Get-ChangedApiFiles -ExpectedRoot $expectedRoot -ActualRoot $deployedRoot)
    $expectedBinaryNames = (($binaryNames | Sort-Object) -join '|')
    if ((($initialChanges | Sort-Object) -join '|') -cne $expectedBinaryNames) {
        throw 'Synthetic API collision fixture must start with changed DLL and PDB content.'
    }
    foreach ($name in $binaryNames) {
        $expectedFile = Get-Item -LiteralPath (Join-Path $expectedRoot $name)
        $deployedFile = Get-Item -LiteralPath (Join-Path $deployedRoot $name)
        if ($expectedFile.Length -ne $deployedFile.Length -or
            $expectedFile.LastWriteTimeUtc -ne $deployedFile.LastWriteTimeUtc) {
            throw "$name did not retain identical length and timestamp metadata."
        }
    }

    $legacyZip = Join-Path $temporaryDirectory 'api-legacy-fixed-timestamp.zip'
    New-AzureDemoDeterministicZip -SourceDirectory $expectedRoot -DestinationPath $legacyZip
    $legacyZipTimestamps = @(Get-ZipWallClockTimestamps -ZipPath $legacyZip)
    if ($legacyZipTimestamps.Count -ne 1 -or $legacyZipTimestamps[0] -cne '1980-01-01T00:00:00') {
        throw 'Legacy API ZIP did not serialize one fixed 1980 timestamp.'
    }
    $legacyExtract = Join-Path $temporaryDirectory 'legacy-extract'
    [IO.Compression.ZipFile]::ExtractToDirectory($legacyZip, $legacyExtract)
    Assert-ExtractedWallClock -Root $legacyExtract -Expected $legacyTimestamp
    $legacyRows = @(Invoke-TestRsync -RsyncPath $rsyncPath -Source $legacyExtract -Destination $deployedRoot)
    $legacyTransfers = @($legacyRows | Where-Object { $_ -cmatch '^>f' })
    $afterLegacy = @(Get-ChangedApiFiles -ExpectedRoot $expectedRoot -ActualRoot $deployedRoot)
    if ($legacyTransfers.Count -ne 0 -or $afterLegacy.Count -ne 2) {
        throw 'Equal API timestamps and lengths did not reproduce stale DLL/PDB copying.'
    }

    $packageZip = Join-Path $temporaryDirectory 'api-package-timestamp.zip'
    New-AzureDemoDeterministicZip -SourceDirectory $expectedRoot -DestinationPath $packageZip `
        -EntryTimestamp $packageTimestamp
    $packageHashBefore = (Get-FileHash -LiteralPath $packageZip -Algorithm SHA256).Hash
    $packageZipTimestamps = @(Get-ZipWallClockTimestamps -ZipPath $packageZip)
    $expectedTimestampText = $expectedSerializedTimestamp.ToString(
        'yyyy-MM-ddTHH:mm:ss', [Globalization.CultureInfo]::InvariantCulture)
    if ($packageZipTimestamps.Count -ne 1 -or $packageZipTimestamps[0] -cne $expectedTimestampText) {
        throw 'API ZIP did not truncate UTC package time to the expected two-second wall clock.'
    }

    $sameBucketZip = Join-Path $temporaryDirectory 'api-same-time-bucket.zip'
    $nextBucketZip = Join-Path $temporaryDirectory 'api-next-time-bucket.zip'
    New-AzureDemoDeterministicZip -SourceDirectory $expectedRoot -DestinationPath $sameBucketZip `
        -EntryTimestamp $sameBucketTimestamp
    New-AzureDemoDeterministicZip -SourceDirectory $expectedRoot -DestinationPath $nextBucketZip `
        -EntryTimestamp $nextBucketTimestamp
    if ((Get-FileHash -LiteralPath $sameBucketZip -Algorithm SHA256).Hash -cne $packageHashBefore) {
        throw 'Same-time-bucket API package inputs did not serialize to the same fixed-input bytes.'
    }
    if ((Get-FileHash -LiteralPath $nextBucketZip -Algorithm SHA256).Hash -ceq $packageHashBefore) {
        throw 'A different serialized API package timestamp did not change ZIP bytes.'
    }

    $nonUtcRejection = $null
    try {
        New-AzureDemoDeterministicZip -SourceDirectory $expectedRoot `
            -DestinationPath (Join-Path $temporaryDirectory 'api-non-utc.zip') `
            -EntryTimestamp ([DateTimeOffset] '2026-10-06T13:34:57.9000000+01:00')
    }
    catch { $nonUtcRejection = $_ }
    if ($null -eq $nonUtcRejection -or
        $nonUtcRejection.Exception.Message -cne 'ZIP entry timestamp must use a UTC offset.') {
        throw 'API packaging did not reject a non-UTC timestamp before serialization.'
    }

    $packageExtract = Join-Path $temporaryDirectory 'package-extract'
    [IO.Compression.ZipFile]::ExtractToDirectory($packageZip, $packageExtract)
    Assert-ExtractedWallClock -Root $packageExtract -Expected $expectedSerializedTimestamp
    $correctedRows = @(Invoke-TestRsync -RsyncPath $rsyncPath -Source $packageExtract -Destination $deployedRoot)
    $correctedTransfers = @($correctedRows | Where-Object { $_ -cmatch '^>f' })
    $correctedTransferPaths = @($correctedTransfers | ForEach-Object { ([string] $_).Split('|', 2)[1] } | Sort-Object)
    $afterCorrection = @(Get-ChangedApiFiles -ExpectedRoot $expectedRoot -ActualRoot $deployedRoot)
    if ($afterCorrection.Count -ne 0 -or
        ($correctedTransferPaths -join '|') -cne $expectedBinaryNames) {
        throw 'The package timestamp did not force both synthetic API binaries to update.'
    }
    if ((Get-FileHash -LiteralPath $packageZip -Algorithm SHA256).Hash -cne $packageHashBefore) {
        throw 'The Linux API correction simulation mutated the immutable package ZIP.'
    }

    Write-Output ("Linux API rsync simulation reproduced stale equal-path/length/timestamp DLL and PDB bytes " +
        "and corrected both with immutable ZIP timestamp $expectedTimestampText; ZIP two-second rounding, " +
        'same-bucket collision and non-UTC rejection passed. This is not live Azure proof.')
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
}

if (Test-Path -LiteralPath $temporaryDirectory) {
    throw 'Linux API deployment timestamp regression cleanup left its temporary directory behind.'
}
exit 0
