[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Linux)) {
    throw 'The EF migration bundle execution regression must run under real PowerShell on Linux.'
}

$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).ProviderPath
$invoker = (Resolve-Path (Join-Path $repo 'scripts/database/Invoke-AzureDemoEfMigrationBundle.ps1')).ProviderPath
. (Join-Path $repo 'scripts/build/AzureDemoDeploymentArtifactUtilities.ps1')

$sourceCommit = '0123456789abcdef0123456789abcdef01234567'
$syntheticConnection = 'synthetic connection value with spaces'
$temporaryParent = Join-Path ([IO.Path]::GetTempPath()) "azdemo EF bundle regression $([Guid]::NewGuid().ToString('N'))"
$pwshPath = (Get-Process -Id $PID).Path
$savedConnection = [Environment]::GetEnvironmentVariable('LGR_AZURE_DEMO_SQL_CONNECTION_STRING', [EnvironmentVariableTarget]::Process)
$savedPath = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::Process)

function ConvertTo-ShellSingleQuotedLiteral {
    param([Parameter(Mandatory)] [string] $Value)
    return "'" + $Value.Replace("'", "'`"'`"'") + "'"
}

function Set-OwnerReadWriteOnly {
    param([Parameter(Mandatory)] [string] $Path)
    [IO.File]::SetUnixFileMode($Path, [IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite)
}

function Set-OwnerExecutable {
    param([Parameter(Mandatory)] [string] $Path)
    [IO.File]::SetUnixFileMode(
        $Path,
        [IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite -bor [IO.UnixFileMode]::UserExecute)
}

function New-SyntheticBundleArtifact {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [string] $Content
    )

    $root = Join-Path $temporaryParent $Name
    $migrationDirectory = Join-Path $root 'migration'
    New-Item -ItemType Directory -Path $migrationDirectory -Force | Out-Null
    $bundle = Join-Path $migrationDirectory 'lgrtm-efbundle-linux-x64'
    [IO.File]::WriteAllText($bundle, $Content, [Text.UTF8Encoding]::new($false))
    Set-OwnerReadWriteOnly -Path $bundle
    $manifest = New-AzureDemoDeploymentArtifactManifest -ArtifactRoot $root -SourceCommit $sourceCommit
    return [pscustomobject]@{ Root = $root; Bundle = $bundle; Manifest = $manifest }
}

function Invoke-SyntheticBundle {
    param([Parameter(Mandatory)] $Artifact)

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $pwshPath
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in @(
            '-NoLogo',
            '-NoProfile',
            '-File', $invoker,
            '-ImmutableArtifactRoot', [string] $Artifact.Root,
            '-DeploymentManifestPath', [string] $Artifact.Manifest,
            '-ExpectedSourceCommit', $sourceCommit)) {
        $startInfo.ArgumentList.Add($argument)
    }

    $process = [Diagnostics.Process]::Start($startInfo)
    if ($null -eq $process) { throw 'Synthetic PowerShell invocation did not return a process.' }
    try {
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            StdOut = $stdout.GetAwaiter().GetResult()
            StdErr = $stderr.GetAwaiter().GetResult()
        }
    }
    finally {
        $process.Dispose()
    }
}

function Assert-Failed {
    param(
        [Parameter(Mandatory)] $Result,
        [Parameter(Mandatory)] [string] $ExpectedMessage,
        [Parameter(Mandatory)] [string] $Scenario
    )

    if ($Result.ExitCode -eq 0 -or -not $Result.StdErr.Contains($ExpectedMessage, [StringComparison]::Ordinal)) {
        throw "EF migration bundle regression did not fail closed for $Scenario."
    }
}

New-Item -ItemType Directory -Path $temporaryParent -Force | Out-Null
try {
    [Environment]::SetEnvironmentVariable('LGR_AZURE_DEMO_SQL_CONNECTION_STRING', $syntheticConnection, [EnvironmentVariableTarget]::Process)

    $successMarker = Join-Path $temporaryParent 'successful execution marker.txt'
    $successScript = @"
#!/bin/sh
if [ "`$1" != "--connection" ]; then exit 91; fi
if [ "`$2" != "$syntheticConnection" ]; then exit 92; fi
sleep 1
printf 'completed' > $(ConvertTo-ShellSingleQuotedLiteral $successMarker)
exit 0
"@ -replace "`r`n", "`n"
    $successful = New-SyntheticBundleArtifact -Name 'successful native execution with spaces' -Content $successScript
    $modeBefore = [IO.File]::GetUnixFileMode($successful.Bundle)
    if (($modeBefore -band [IO.UnixFileMode]::UserExecute) -ne 0) {
        throw 'Successful fixture unexpectedly started with executable permission.'
    }
    $hashBefore = (Get-FileHash -LiteralPath $successful.Bundle -Algorithm SHA256).Hash
    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    $successResult = Invoke-SyntheticBundle -Artifact $successful
    $stopwatch.Stop()
    if ($successResult.ExitCode -ne 0 -or
        -not (Test-Path -LiteralPath $successMarker -PathType Leaf) -or
        $stopwatch.ElapsedMilliseconds -lt 800 -or
        -not $successResult.StdOut.Contains('Reviewed EF migration bundle completed successfully.', [StringComparison]::Ordinal)) {
        throw 'The harmless native bundle did not execute successfully and synchronously.'
    }
    $modeAfter = [IO.File]::GetUnixFileMode($successful.Bundle)
    if (($modeAfter -band [IO.UnixFileMode]::UserExecute) -eq 0) {
        throw 'The downloaded bundle fixture was not made executable.'
    }
    $hashAfter = (Get-FileHash -LiteralPath $successful.Bundle -Algorithm SHA256).Hash
    if (-not [string]::Equals($hashBefore, $hashAfter, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Bundle content hash changed when executable permission was established.'
    }

    $nonzero = New-SyntheticBundleArtifact -Name 'nonzero process exit' -Content ("#!/bin/sh`nexit 23`n")
    Assert-Failed -Result (Invoke-SyntheticBundle -Artifact $nonzero) -ExpectedMessage 'Reviewed EF migration bundle exited with code 23.' -Scenario 'a nonzero native-process exit'

    $missing = New-SyntheticBundleArtifact -Name 'missing executable' -Content ("#!/bin/sh`nexit 0`n")
    Remove-Item -LiteralPath $missing.Bundle -Force
    Assert-Failed -Result (Invoke-SyntheticBundle -Artifact $missing) -ExpectedMessage 'A required immutable artifact path is missing or has the wrong type.' -Scenario 'a missing executable'

    $associationDirectory = Join-Path $temporaryParent 'association trap'
    New-Item -ItemType Directory -Path $associationDirectory -Force | Out-Null
    $associationMarker = Join-Path $temporaryParent 'association fallback marker.txt'
    $associationTrap = Join-Path $associationDirectory 'xdg-open'
    [IO.File]::WriteAllText(
        $associationTrap,
        "#!/bin/sh`nprintf 'called' > $(ConvertTo-ShellSingleQuotedLiteral $associationMarker)`nexit 0`n",
        [Text.UTF8Encoding]::new($false))
    Set-OwnerExecutable -Path $associationTrap
    [Environment]::SetEnvironmentVariable('PATH', "$associationDirectory$([IO.Path]::PathSeparator)$savedPath", [EnvironmentVariableTarget]::Process)
    $invalid = New-SyntheticBundleArtifact -Name 'invalid executable format' -Content 'not a native executable or script'
    Assert-Failed -Result (Invoke-SyntheticBundle -Artifact $invalid) -ExpectedMessage 'Reviewed EF migration bundle could not be launched as a native process.' -Scenario 'an invalid executable format'
    if (Test-Path -LiteralPath $associationMarker) {
        throw 'Invalid native execution fell back to xdg-open.'
    }

    $tamperMarker = Join-Path $temporaryParent 'tampered execution marker.txt'
    $tampered = New-SyntheticBundleArtifact -Name 'tampered artifact' -Content ("#!/bin/sh`nexit 0`n")
    [IO.File]::WriteAllText(
        $tampered.Bundle,
        "#!/bin/sh`nprintf 'executed' > $(ConvertTo-ShellSingleQuotedLiteral $tamperMarker)`nexit 0`n",
        [Text.UTF8Encoding]::new($false))
    Set-OwnerReadWriteOnly -Path $tampered.Bundle
    Assert-Failed -Result (Invoke-SyntheticBundle -Artifact $tampered) -ExpectedMessage 'Deployment artifact payload SHA-256 validation failed.' -Scenario 'artifact tampering'
    if ((Test-Path -LiteralPath $tamperMarker) -or
        (([IO.File]::GetUnixFileMode($tampered.Bundle) -band [IO.UnixFileMode]::UserExecute) -ne 0)) {
        throw 'Tampered artifact reached permission adjustment or execution.'
    }

    $outsideBundle = Join-Path $temporaryParent 'outside bundle'
    [IO.File]::WriteAllText($outsideBundle, "#!/bin/sh`nexit 0`n", [Text.UTF8Encoding]::new($false))
    $linked = New-SyntheticBundleArtifact -Name 'symbolic link rejection' -Content ("#!/bin/sh`nexit 0`n")
    Remove-Item -LiteralPath $linked.Bundle -Force
    $null = [IO.File]::CreateSymbolicLink($linked.Bundle, $outsideBundle)
    Assert-Failed -Result (Invoke-SyntheticBundle -Artifact $linked) -ExpectedMessage 'Immutable artifact paths must not contain symbolic links or reparse points.' -Scenario 'a symbolic-link substitution'

    $invokerText = Get-Content -LiteralPath $invoker -Raw
    foreach ($prohibited in @('xdg-open', 'Invoke-Item', 'Start-Process', 'UseShellExecute = $true')) {
        if ($invokerText.Contains($prohibited, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Native migration invoker contains prohibited file-association behavior: $prohibited"
        }
    }
    foreach ($required in @(
            '$startInfo.UseShellExecute = $false',
            '$startInfo.ArgumentList.Add($argument)',
            '$process.WaitForExit()',
            '$process.ExitCode',
            "@('u+x', '--', `$bundlePath)",
            'Get-FileHash -LiteralPath $postPermissionBundlePath -Algorithm SHA256')) {
        if (-not $invokerText.Contains($required, [StringComparison]::Ordinal)) {
            throw "Native migration invoker is missing required execution behavior: $required"
        }
    }
}
finally {
    [Environment]::SetEnvironmentVariable('LGR_AZURE_DEMO_SQL_CONNECTION_STRING', $savedConnection, [EnvironmentVariableTarget]::Process)
    [Environment]::SetEnvironmentVariable('PATH', $savedPath, [EnvironmentVariableTarget]::Process)
    if (Test-Path -LiteralPath $temporaryParent) {
        Remove-Item -LiteralPath $temporaryParent -Recurse -Force
    }
}

Write-Output 'Linux EF migration bundle execution regression passed permission, native launch, wait, exit, path, tamper, symlink, association and hash checks.'
