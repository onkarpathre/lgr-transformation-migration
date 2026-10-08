[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).ProviderPath
. (Join-Path $repo 'scripts\build\AzureDemoPackageUtilities.ps1')

$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-package-time-$([Guid]::NewGuid().ToString('N'))")
$source = Join-Path $temporaryDirectory 'source'
$extract = Join-Path $temporaryDirectory 'extract'
$firstTimestamp = [DateTimeOffset] '2026-10-06T12:34:57.9000000+00:00'
$sameBucketTimestamp = [DateTimeOffset] '2026-10-06T12:34:56.1000000+00:00'
$nextBucketTimestamp = [DateTimeOffset] '2026-10-06T12:34:58.0000000+00:00'
$expectedSerializedTimestamp = ConvertTo-AzureDemoZipEntryTimestamp -Timestamp $firstTimestamp

function New-SyntheticBinary([string] $Path, [byte] $Marker, [int] $Length) {
    $bytes = New-Object byte[] $Length
    for ($index = 0; $index -lt $bytes.Length; $index++) {
        $bytes[$index] = [byte] (($Marker + $index) % 251)
    }
    [IO.File]::WriteAllBytes($Path, $bytes)
}

function Get-ZipTimestampText([string] $Path) {
    $archive = [IO.Compression.ZipFile]::OpenRead($Path)
    try {
        $timestamps = @($archive.Entries | Where-Object {
                -not $_.FullName.Replace('\', '/').EndsWith('/', [StringComparison]::Ordinal)
            } | ForEach-Object {
                $_.LastWriteTime.DateTime.ToString('yyyy-MM-ddTHH:mm:ss', [Globalization.CultureInfo]::InvariantCulture)
            } | Sort-Object -Unique)
        if ($timestamps.Count -ne 1) { throw 'ZIP did not serialize one uniform file timestamp.' }
        return $timestamps[0]
    }
    finally { $archive.Dispose() }
}

New-Item -ItemType Directory -Path $source -Force | Out-Null
try {
    # These fixed byte arrays are binary collision fixtures, not assemblies.
    New-SyntheticBinary -Path (Join-Path $source 'LgrTransformationMigration.Api.dll') -Marker 65 -Length 4096
    New-SyntheticBinary -Path (Join-Path $source 'LgrTransformationMigration.Api.pdb') -Marker 82 -Length 2048

    $firstZip = Join-Path $temporaryDirectory 'first.zip'
    $sameBucketZip = Join-Path $temporaryDirectory 'same-bucket.zip'
    $nextBucketZip = Join-Path $temporaryDirectory 'next-bucket.zip'
    New-AzureDemoDeterministicZip -SourceDirectory $source -DestinationPath $firstZip -EntryTimestamp $firstTimestamp
    New-AzureDemoDeterministicZip -SourceDirectory $source -DestinationPath $sameBucketZip -EntryTimestamp $sameBucketTimestamp
    New-AzureDemoDeterministicZip -SourceDirectory $source -DestinationPath $nextBucketZip -EntryTimestamp $nextBucketTimestamp

    $expectedTimestampText = $expectedSerializedTimestamp.ToString(
        'yyyy-MM-ddTHH:mm:ss', [Globalization.CultureInfo]::InvariantCulture)
    if ((Get-ZipTimestampText -Path $firstZip) -cne $expectedTimestampText) {
        throw 'ZIP did not truncate its UTC package timestamp to two-second precision.'
    }
    $firstHash = (Get-FileHash -LiteralPath $firstZip -Algorithm SHA256).Hash
    if ((Get-FileHash -LiteralPath $sameBucketZip -Algorithm SHA256).Hash -cne $firstHash) {
        throw 'Fixed inputs within one ZIP time bucket did not produce identical bytes.'
    }
    if ((Get-FileHash -LiteralPath $nextBucketZip -Algorithm SHA256).Hash -ceq $firstHash) {
        throw 'Changing the serialized ZIP timestamp did not change package bytes.'
    }

    [IO.Compression.ZipFile]::ExtractToDirectory($firstZip, $extract)
    $extractedTimestamps = @(Get-ChildItem -LiteralPath $extract -Recurse -File -Force | ForEach-Object {
            $_.LastWriteTime.ToString('yyyy-MM-ddTHH:mm:ss', [Globalization.CultureInfo]::InvariantCulture)
        } | Sort-Object -Unique)
    if ($extractedTimestamps.Count -ne 1 -or $extractedTimestamps[0] -cne $expectedTimestampText) {
        throw 'ZIP extraction did not preserve serialized UTC wall-clock components.'
    }

    $timezoneRejection = $null
    try {
        New-AzureDemoDeterministicZip -SourceDirectory $source `
            -DestinationPath (Join-Path $temporaryDirectory 'non-utc.zip') `
            -EntryTimestamp ([DateTimeOffset] '2026-10-06T13:34:57.9000000+01:00')
    }
    catch { $timezoneRejection = $_ }
    if ($null -eq $timezoneRejection -or
        $timezoneRejection.Exception.Message -cne 'ZIP entry timestamp must use a UTC offset.') {
        throw 'ZIP creation did not reject a non-UTC package timestamp.'
    }

    Write-Output ("Application ZIP timestamp semantics passed UTC wall-clock serialization/extraction at $expectedTimestampText, " +
        'two-second truncation, same-bucket collision, next-bucket byte change and non-UTC rejection; wall-clock metadata is not a uniqueness guarantee.')
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
}

if (Test-Path -LiteralPath $temporaryDirectory) {
    throw 'Application ZIP timestamp regression cleanup left its temporary directory behind.'
}
exit 0
