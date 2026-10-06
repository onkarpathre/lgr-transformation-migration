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

function ConvertTo-AzureDemoZipEntryTimestamp {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [DateTimeOffset] $Timestamp)

    if ($Timestamp.Offset -ne [TimeSpan]::Zero) {
        throw 'ZIP entry timestamp must use a UTC offset.'
    }
    if ($Timestamp.Year -lt 1980 -or $Timestamp.Year -gt 2107) {
        throw 'ZIP entry timestamp must be within the supported DOS date range.'
    }

    # ZIP stores a timezone-free DOS wall clock at two-second precision. The
    # application-package contract writes UTC components and deliberately
    # truncates, rather than converts, those components for serialization.
    return [DateTimeOffset]::new(
        $Timestamp.Year,
        $Timestamp.Month,
        $Timestamp.Day,
        $Timestamp.Hour,
        $Timestamp.Minute,
        ($Timestamp.Second - ($Timestamp.Second % 2)),
        [TimeSpan]::Zero)
}

function New-AzureDemoDeterministicZip {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $SourceDirectory,
        [Parameter(Mandatory)] [string] $DestinationPath,
        [DateTimeOffset] $EntryTimestamp = [DateTimeOffset]::MinValue
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

    if ($EntryTimestamp -eq [DateTimeOffset]::MinValue) {
        $EntryTimestamp = [DateTimeOffset]::Parse('1980-01-01T00:00:00+00:00', [Globalization.CultureInfo]::InvariantCulture)
    }
    $zipTimestamp = ConvertTo-AzureDemoZipEntryTimestamp -Timestamp $EntryTimestamp
    $fileStream = [IO.File]::Open($destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    $archive = $null
    try {
        $archive = New-Object IO.Compression.ZipArchive($fileStream, [IO.Compression.ZipArchiveMode]::Create, $false)
        foreach ($file in $files) {
            $entryName = $file.FullName.Substring($source.Length).TrimStart([char[]] @('\', '/')).Replace('\', '/')
            $entry = $archive.CreateEntry($entryName, [IO.Compression.CompressionLevel]::Optimal)
            $entry.LastWriteTime = $zipTimestamp
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

function ConvertTo-AzureDemoWindowsCommandLineArgument {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [AllowEmptyString()] [string] $Argument)

    if ($Argument.Length -gt 0 -and $Argument -notmatch '[\s"]') {
        return $Argument
    }

    $quoted = New-Object Text.StringBuilder
    [void] $quoted.Append('"')
    $backslashes = 0
    foreach ($character in $Argument.ToCharArray()) {
        if ($character -eq '\') {
            $backslashes++
            continue
        }
        if ($character -eq '"') {
            [void] $quoted.Append(('\' * (($backslashes * 2) + 1)))
            [void] $quoted.Append('"')
            $backslashes = 0
            continue
        }
        if ($backslashes -gt 0) {
            [void] $quoted.Append(('\' * $backslashes))
            $backslashes = 0
        }
        [void] $quoted.Append($character)
    }
    if ($backslashes -gt 0) {
        [void] $quoted.Append(('\' * ($backslashes * 2)))
    }
    [void] $quoted.Append('"')
    return $quoted.ToString()
}

function Invoke-AzureDemoNativeCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $FilePath,
        [Parameter(Mandatory)] [AllowEmptyCollection()] [string[]] $Arguments
    )

    $startInfo = New-Object Diagnostics.ProcessStartInfo
    $startInfo.FileName = $FilePath
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    if ($null -ne $startInfo.PSObject.Properties['ArgumentList']) {
        foreach ($argument in $Arguments) {
            [void] $startInfo.ArgumentList.Add($argument)
        }
    }
    else {
        $startInfo.Arguments = (($Arguments | ForEach-Object {
                    ConvertTo-AzureDemoWindowsCommandLineArgument -Argument $_
                }) -join ' ')
    }

    $process = New-Object Diagnostics.Process
    $process.StartInfo = $startInfo
    try {
        if (-not $process.Start()) {
            throw "Native command could not be started: $FilePath"
        }
        $standardOutputTask = $process.StandardOutput.ReadToEndAsync()
        $standardErrorTask = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        $standardOutput = $standardOutputTask.GetAwaiter().GetResult()
        $standardError = $standardErrorTask.GetAwaiter().GetResult()

        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            StdOut = $standardOutput
            StdErr = $standardError
        }
    }
    finally {
        $process.Dispose()
    }
}

function Format-AzureDemoNativeCommandFailure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Operation,
        [Parameter(Mandatory)] $Result
    )

    $details = @()
    if (-not [string]::IsNullOrWhiteSpace([string] $Result.StdErr)) {
        $details += "stderr: $(([string] $Result.StdErr).Trim())"
    }
    if (-not [string]::IsNullOrWhiteSpace([string] $Result.StdOut)) {
        $details += "stdout: $(([string] $Result.StdOut).Trim())"
    }
    $suffix = if ($details.Count -gt 0) { ' ' + ($details -join ' ') } else { '' }
    return "$Operation failed with exit code $($Result.ExitCode).$suffix"
}

function Assert-EfMigrationArtifactInvocationContract {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $RepositoryPath,
        [Parameter(Mandatory)] [string] $Project,
        [Parameter(Mandatory)] [string] $StartupProject,
        [Parameter(Mandatory)] [string] $DbContext
    )

    $expectedProject = 'src/api/LgrTransformationMigration.Api.csproj'
    $expectedContext = 'LgrTransformationMigration.Api.Infrastructure.AppDbContext'
    if ($Project -cne $expectedProject) {
        throw "EF migration artifact project must be exactly $expectedProject."
    }
    if ($StartupProject -cne $expectedProject) {
        throw "EF migration artifact startup project must be exactly $expectedProject."
    }
    if ($DbContext -cne $expectedContext) {
        throw "EF migration artifact DbContext must be exactly $expectedContext."
    }

    $projectPath = Join-Path $RepositoryPath $expectedProject
    $contextPath = Join-Path $RepositoryPath 'src/api/Infrastructure/AppDbContext.cs'
    if (-not (Test-Path -LiteralPath $projectPath -PathType Leaf)) {
        throw 'The approved EF migration artifact project does not exist.'
    }
    if (-not (Test-Path -LiteralPath $contextPath -PathType Leaf)) {
        throw 'The approved EF migration artifact DbContext source does not exist.'
    }
    $contextSource = Get-Content -LiteralPath $contextPath -Raw
    if ($contextSource -notmatch '(?m)^namespace LgrTransformationMigration\.Api\.Infrastructure;\s*$' -or
        $contextSource -notmatch '(?m)^public sealed class AppDbContext\s*\(') {
        throw 'The approved EF migration artifact DbContext declaration could not be verified.'
    }
}

function Assert-SupportedEfDiagnosticText {
    [CmdletBinding()]
    param(
        [AllowEmptyString()] [string] $Text,
        [Parameter(Mandatory)] [string] $StreamName
    )

    $expectingLoggerContinuation = $false
    foreach ($line in ($Text -split '\r?\n')) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        if ($line -cmatch '^Build (?:started\.\.\.|succeeded\.)$') {
            $expectingLoggerContinuation = $false
            continue
        }
        if ($line -cmatch '^(?:warn|info): Microsoft\.EntityFrameworkCore\.[A-Za-z0-9_.]+\[[0-9]+\]$') {
            $expectingLoggerContinuation = $true
            continue
        }
        if ($expectingLoggerContinuation -and $line -cmatch '^ {6}\S.*$') {
            continue
        }
        if ($line -cmatch "^The Entity Framework tools version '[0-9]+\.[0-9]+\.[0-9]+' is older than that of the runtime '[0-9]+\.[0-9]+\.[0-9]+'. Update the tools for the latest features and bug fixes\. See https://aka\.ms/AAc1fbw for more information\.$") {
            $expectingLoggerContinuation = $false
            continue
        }
        throw "EF migration enumeration emitted unsupported $StreamName diagnostic content."
    }
}

function Get-EfJsonDocumentBoundary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Text,
        [Parameter(Mandatory)] [int] $StartIndex
    )

    $containers = New-Object 'System.Collections.Generic.Stack[char]'
    $inString = $false
    $escaped = $false
    for ($index = $StartIndex; $index -lt $Text.Length; $index++) {
        $character = $Text[$index]
        if ($inString) {
            if ($escaped) {
                $escaped = $false
            }
            elseif ($character -eq '\') {
                $escaped = $true
            }
            elseif ($character -eq '"') {
                $inString = $false
            }
            continue
        }

        if ($character -eq '"') {
            $inString = $true
            continue
        }
        if ($character -eq '[' -or $character -eq '{') {
            $containers.Push($character)
            continue
        }
        if ($character -eq ']' -or $character -eq '}') {
            if ($containers.Count -eq 0) {
                throw 'EF migration enumeration returned malformed JSON.'
            }
            $opening = $containers.Pop()
            if (($opening -eq '[' -and $character -ne ']') -or
                ($opening -eq '{' -and $character -ne '}')) {
                throw 'EF migration enumeration returned malformed JSON.'
            }
            if ($containers.Count -eq 0) {
                return $index
            }
        }
    }

    throw 'EF migration enumeration returned malformed JSON.'
}

function ConvertFrom-EfMigrationListNativeResult {
    [CmdletBinding()]
    param([Parameter(Mandatory)] $Result)

    if ([int] $Result.ExitCode -ne 0) {
        throw (Format-AzureDemoNativeCommandFailure -Operation 'EF migration enumeration' -Result $Result)
    }

    $standardOutput = [string] $Result.StdOut
    if ($standardOutput.Length -gt 0 -and $standardOutput[0] -eq [char] 0xfeff) {
        $standardOutput = $standardOutput.Substring(1)
    }
    Assert-SupportedEfDiagnosticText -Text ([string] $Result.StdErr) -StreamName 'standard-error'

    $documentStartMatch = [regex]::Match($standardOutput, '(?m)^[ \t]*[\[\{]')
    if (-not $documentStartMatch.Success) {
        throw 'EF migration enumeration returned no JSON document.'
    }
    $openingOffset = $documentStartMatch.Value.IndexOfAny([char[]] @('[', '{'))
    $documentStart = $documentStartMatch.Index + $openingOffset
    $diagnosticPrefix = $standardOutput.Substring(0, $documentStart)
    Assert-SupportedEfDiagnosticText -Text $diagnosticPrefix -StreamName 'standard-output'

    if ($standardOutput[$documentStart] -ne '[') {
        throw 'EF migration enumeration JSON root must be an array.'
    }
    $documentEnd = Get-EfJsonDocumentBoundary -Text $standardOutput -StartIndex $documentStart
    $json = $standardOutput.Substring($documentStart, ($documentEnd - $documentStart) + 1)
    $trailingContent = $standardOutput.Substring($documentEnd + 1)
    if (-not [string]::IsNullOrWhiteSpace($trailingContent)) {
        if ($trailingContent -match '^\s*[\[\{]') {
            throw 'EF migration enumeration returned multiple ambiguous JSON documents.'
        }
        throw 'EF migration enumeration returned unexpected trailing content.'
    }

    try {
        $parsedJson = $json | ConvertFrom-Json -ErrorAction Stop
        $migrations = @($parsedJson | ForEach-Object { $_ })
    }
    catch {
        throw 'EF migration enumeration returned malformed JSON.'
    }
    if ($migrations.Count -eq 0) {
        throw 'EF migration enumeration returned no migrations.'
    }

    $ids = @{}
    $names = @{}
    foreach ($migration in $migrations) {
        if ($null -eq $migration -or
            -not ($migration.PSObject.Properties.Name -ccontains 'id') -or
            -not ($migration.PSObject.Properties.Name -ccontains 'name') -or
            -not ($migration.id -is [string]) -or
            -not ($migration.name -is [string]) -or
            [string]::IsNullOrWhiteSpace([string] $migration.id) -or
            [string]::IsNullOrWhiteSpace([string] $migration.name)) {
            throw 'EF migration enumeration returned a migration without a non-empty id and name.'
        }
        $propertyNames = @(($migration.PSObject.Properties.Name | Sort-Object) -join '|')
        if ($propertyNames.Count -ne 1 -or $propertyNames[0] -cne 'applied|id|name|safeName' -or
            -not ($migration.safeName -is [string]) -or
            [string]::IsNullOrWhiteSpace([string] $migration.safeName) -or
            $null -ne $migration.applied) {
            throw 'EF migration enumeration returned an unexpected migration JSON schema.'
        }
        $id = [string] $migration.id
        $name = [string] $migration.name
        if ($id -cnotmatch '^[0-9]{14}_.+$') {
            throw 'EF migration enumeration returned an invalid migration identifier.'
        }
        if ($ids.ContainsKey($id) -or $names.ContainsKey($name)) {
            throw 'EF migration enumeration returned duplicate migration identifiers or names.'
        }
        $ids[$id] = $true
        $names[$name] = $true
    }

    return $migrations
}
