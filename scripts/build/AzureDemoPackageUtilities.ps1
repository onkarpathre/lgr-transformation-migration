$ErrorActionPreference = 'Stop'

function Get-AzureDemoCanonicalPath {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string] $Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'A non-empty path is required.'
    }

    try {
        $absolutePath = [IO.Path]::GetFullPath($Path)
    }
    catch {
        throw 'The supplied path could not be resolved to an absolute path.'
    }

    $missingComponents = New-Object 'System.Collections.Generic.Stack[string]'
    $existingPath = $absolutePath
    while (-not (Test-Path -LiteralPath $existingPath)) {
        $leaf = [IO.Path]::GetFileName($existingPath)
        $parent = [IO.Path]::GetDirectoryName($existingPath)
        if ([string]::IsNullOrEmpty($leaf) -or [string]::IsNullOrEmpty($parent) -or $parent -eq $existingPath) {
            throw 'The supplied path has no resolvable existing ancestor.'
        }
        $missingComponents.Push($leaf)
        $existingPath = $parent
    }

    $resolvedPath = (Resolve-Path -LiteralPath $existingPath).ProviderPath
    foreach ($component in $missingComponents) {
        $resolvedPath = Join-Path $resolvedPath $component
    }

    return [IO.Path]::GetFullPath($resolvedPath)
}

function Assert-AzureDemoRepositoryOutputPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $RepositoryPath,
        [Parameter(Mandatory)] [string] $OutputPath
    )

    $repository = (Get-AzureDemoCanonicalPath -Path $RepositoryPath).TrimEnd([char[]] @('\', '/'))
    $output = (Get-AzureDemoCanonicalPath -Path $OutputPath).TrimEnd([char[]] @('\', '/'))
    $comparison = if ([IO.Path]::DirectorySeparatorChar -eq '\') {
        [StringComparison]::OrdinalIgnoreCase
    }
    else {
        [StringComparison]::Ordinal
    }
    $repositoryPrefix = $repository + [IO.Path]::DirectorySeparatorChar

    if ($output.Equals($repository, $comparison) -or -not $output.StartsWith($repositoryPrefix, $comparison)) {
        throw 'OutputDirectory must be within the repository workspace.'
    }
    if ((Test-Path -LiteralPath $output) -and -not (Test-Path -LiteralPath $output -PathType Container)) {
        throw 'OutputDirectory must resolve to a directory.'
    }

    return $output
}

function New-AzureDemoDeterministicZip {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $SourceDirectory,
        [Parameter(Mandatory)] [string] $DestinationPath
    )

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $source = (Get-AzureDemoCanonicalPath -Path $SourceDirectory).TrimEnd([char[]] @('\', '/'))
    if (-not (Test-Path -LiteralPath $source -PathType Container)) {
        throw 'ZIP source directory does not exist.'
    }
    $files = @(Get-ChildItem -LiteralPath $source -Recurse -File -Force | Sort-Object {
            $_.FullName.Substring($source.Length).TrimStart([char[]] @('\', '/')).Replace('\', '/')
        })
    if ($files.Count -eq 0) {
        throw 'ZIP source directory contains no files.'
    }

    $destination = [IO.Path]::GetFullPath($DestinationPath)
    $destinationParent = [IO.Path]::GetDirectoryName($destination)
    if (-not (Test-Path -LiteralPath $destinationParent -PathType Container)) {
        New-Item -ItemType Directory -Path $destinationParent -Force | Out-Null
    }
    if (Test-Path -LiteralPath $destination) {
        Remove-Item -LiteralPath $destination -Force
    }

    $fixedTimestamp = [DateTimeOffset]::Parse('1980-01-01T00:00:00+00:00', [Globalization.CultureInfo]::InvariantCulture)
    $fileStream = [IO.File]::Open($destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    $archive = $null
    try {
        $archive = New-Object IO.Compression.ZipArchive($fileStream, [IO.Compression.ZipArchiveMode]::Create, $false)
        foreach ($file in $files) {
            $entryName = $file.FullName.Substring($source.Length).TrimStart([char[]] @('\', '/')).Replace('\', '/')
            $entry = $archive.CreateEntry($entryName, [IO.Compression.CompressionLevel]::Optimal)
            $entry.LastWriteTime = $fixedTimestamp
            $inputStream = $file.OpenRead()
            $entryStream = $entry.Open()
            try {
                $inputStream.CopyTo($entryStream)
            }
            finally {
                $entryStream.Dispose()
                $inputStream.Dispose()
            }
        }
    }
    finally {
        if ($null -ne $archive) { $archive.Dispose() }
        $fileStream.Dispose()
    }
}
