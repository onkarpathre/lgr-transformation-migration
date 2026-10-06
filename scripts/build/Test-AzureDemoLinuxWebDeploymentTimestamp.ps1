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

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).ProviderPath
. (Join-Path $repo 'scripts\build\AzureDemoPackageUtilities.ps1')

$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-linux-rsync-$([Guid]::NewGuid().ToString('N'))")
$legacyTimestamp = [DateTimeOffset] '1980-01-01T00:00:00+00:00'
$correctedTimestamp = [DateTimeOffset] '2026-10-06T12:34:56+00:00'
$expectedBuildId = 'SyIeOuurTS_H-Clua5oW0'
$staleBuildId = 'Xwvb4L_dSTn4jJilCsPfY'

function Resolve-RequiredApplicationPath([string] $Name) {
    try {
        $commands = @(
            Get-Command -Name $Name -CommandType Application -ErrorAction Stop
        )
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

function New-TestApplication([string] $Directory, [string] $Name) {
    New-Item -ItemType Directory -Path $Directory -Force | Out-Null
    $path = Join-Path $Directory $Name
    [IO.File]::WriteAllText($path, @'
#!/bin/sh
printf '%s|%s|%s\n' "$#" "$1" "$2"
exit 0
'@, [Text.UTF8Encoding]::new($false))
    $mode = [IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite -bor [IO.UnixFileMode]::UserExecute -bor `
        [IO.UnixFileMode]::GroupRead -bor [IO.UnixFileMode]::GroupExecute -bor `
        [IO.UnixFileMode]::OtherRead -bor [IO.UnixFileMode]::OtherExecute
    [IO.File]::SetUnixFileMode($path, $mode)
    return $path
}

function Test-ApplicationResolution([string] $Root) {
    $originalPath = $env:PATH
    try {
        $singleName = "azdemo-single-$([Guid]::NewGuid().ToString('N'))"
        $singleDirectory = Join-Path $Root 'single'
        $singleExecutable = New-TestApplication -Directory $singleDirectory -Name $singleName
        $env:PATH = $singleDirectory
        $resolvedSingle = Resolve-RequiredApplicationPath -Name $singleName
        if ($resolvedSingle -cne $singleExecutable) {
            throw 'Single executable discovery did not return the only PATH match.'
        }

        $multipleName = "azdemo-multiple-$([Guid]::NewGuid().ToString('N'))"
        $firstDirectory = Join-Path $Root 'multiple-first'
        $secondDirectory = Join-Path $Root 'multiple-second'
        $firstExecutable = New-TestApplication -Directory $firstDirectory -Name $multipleName
        New-TestApplication -Directory $secondDirectory -Name $multipleName | Out-Null
        $env:PATH = $firstDirectory + [IO.Path]::PathSeparator + $secondDirectory
        $multipleCommands = @(Get-Command -Name $multipleName -CommandType Application -ErrorAction Stop)
        if ($multipleCommands.Count -ne 2) {
            throw "Two-match executable fixture resolved $($multipleCommands.Count) applications instead of 2."
        }
        $resolvedMultiple = Resolve-RequiredApplicationPath -Name $multipleName
        if ($resolvedMultiple -cne $firstExecutable) {
            throw 'Multiple executable discovery did not preserve PATH precedence.'
        }

        $env:PATH = $firstDirectory + [IO.Path]::PathSeparator + $firstDirectory
        $resolvedDuplicate = Resolve-RequiredApplicationPath -Name $multipleName
        if ($resolvedDuplicate -cne $firstExecutable) {
            throw 'Duplicate PATH entries changed deterministic executable selection.'
        }

        $missingName = "azdemo-missing-$([Guid]::NewGuid().ToString('N'))"
        $missingDirectory = Join-Path $Root 'missing'
        New-Item -ItemType Directory -Path $missingDirectory -Force | Out-Null
        $env:PATH = $missingDirectory
        $missingFailure = $null
        try { Resolve-RequiredApplicationPath -Name $missingName | Out-Null }
        catch { $missingFailure = $_ }
        if ($null -eq $missingFailure -or
            $missingFailure.Exception.Message -cne "Required $missingName executable was not found.") {
            throw 'Missing executable discovery did not fail with the required deterministic error.'
        }

        $spacedName = "azdemo-spaced-$([Guid]::NewGuid().ToString('N'))"
        $spacedDirectory = Join-Path $Root 'path containing spaces'
        $spacedExecutable = New-TestApplication -Directory $spacedDirectory -Name $spacedName
        $env:PATH = $spacedDirectory
        $resolvedSpaced = Resolve-RequiredApplicationPath -Name $spacedName
        $probeArguments = @('first argument', 'second argument')
        $probeRows = @(& $resolvedSpaced @probeArguments)
        $probeExitCode = $LASTEXITCODE
        if ($probeExitCode -ne 0 -or $resolvedSpaced -cne $spacedExecutable -or
            $probeRows.Count -ne 1 -or [string] $probeRows[0] -cne '2|first argument|second argument') {
            throw 'Executable discovery or invocation split a path or argument containing spaces.'
        }
    }
    finally {
        $env:PATH = $originalPath
    }
}

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

function Invoke-TestRsync([string] $RsyncPath, [string] $Source, [string] $Destination) {
    $stderrPath = Join-Path $temporaryDirectory ("rsync-$([Guid]::NewGuid().ToString('N')).stderr")
    try {
        $sourceArgument = $Source.TrimEnd([char[]] @('/', '\')) + [IO.Path]::DirectorySeparatorChar
        $destinationArgument = $Destination.TrimEnd([char[]] @('/', '\')) + [IO.Path]::DirectorySeparatorChar
        $rsyncArguments = @(
            '-a', '--delete', '--itemize-changes', '--out-format=%i|%n', '--',
            $sourceArgument, $destinationArgument)
        $rows = @(& $RsyncPath @rsyncArguments 2> $stderrPath)
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
    Test-ApplicationResolution -Root (Join-Path $temporaryDirectory 'application-resolution')
    $rsyncPath = Resolve-RequiredApplicationPath -Name 'rsync'

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
    $legacyRsync = @(Invoke-TestRsync -RsyncPath $rsyncPath -Source $legacyExtract -Destination $deployedRoot)
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

    $correctedRsync = @(Invoke-TestRsync -RsyncPath $rsyncPath -Source $correctedExtract -Destination $deployedRoot)
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
