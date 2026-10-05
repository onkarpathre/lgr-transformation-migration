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
$regressionDriver = Join-Path $temporaryParent 'Invoke-EfBundleRegressionDriver.ps1'
$expectedRejectionExitCode = 86
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

function Invoke-FixtureNativeProcess {
    param(
        [Parameter(Mandatory)] [string] $FilePath,
        [Parameter(Mandatory)] [string[]] $ArgumentList
    )

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $FilePath
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in $ArgumentList) {
        $startInfo.ArgumentList.Add($argument)
    }

    $process = [Diagnostics.Process]::Start($startInfo)
    if ($null -eq $process) { throw 'Fixture creation did not return a native process.' }
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

function New-VerifiedSymbolicLink {
    param(
        [Parameter(Mandatory)] [string] $LinkPath,
        [Parameter(Mandatory)] [string] $TargetPath,
        [Parameter(Mandatory)] [string] $Scenario
    )

    $lnPath = @('/usr/bin/ln', '/bin/ln') | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($lnPath)) {
        throw "Symbolic-link fixture creation utility is unavailable for $Scenario."
    }
    $creation = Invoke-FixtureNativeProcess -FilePath $lnPath -ArgumentList @('-s', '--', $TargetPath, $LinkPath)
    if ($creation.ExitCode -ne 0) {
        throw "Symbolic-link fixture creation exited with code $($creation.ExitCode) for $Scenario."
    }

    $item = Get-Item -LiteralPath $LinkPath -Force -ErrorAction Stop
    $attributes = [IO.File]::GetAttributes($LinkPath)
    $recordedTargets = @($item.Target)
    if (($attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0 -or
        [string] $item.LinkType -cne 'SymbolicLink' -or
        $recordedTargets.Count -ne 1 -or
        -not [IO.Path]::GetFullPath([string] $recordedTargets[0]).Equals(
            [IO.Path]::GetFullPath($TargetPath),
            [StringComparison]::Ordinal)) {
        throw "Fixture creation returned zero but did not create a symbolic link for $Scenario."
    }
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
            '-File', $regressionDriver,
            '-Invoker', $invoker,
            '-ImmutableArtifactRoot', [string] $Artifact.Root,
            '-DeploymentManifestPath', [string] $Artifact.Manifest,
            '-ExpectedSourceCommit', $sourceCommit,
            '-ExpectedRejectionExitCode', [string] $expectedRejectionExitCode)) {
        $startInfo.ArgumentList.Add($argument)
    }

    $process = [Diagnostics.Process]::Start($startInfo)
    if ($null -eq $process) { throw 'Synthetic PowerShell invocation did not return a process.' }
    try {
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        $standardError = $stderr.GetAwaiter().GetResult()
        $exceptionType = $null
        $exceptionMessage = $null
        $recordPrefix = 'AZDEMO_TEST_REJECTION:'
        $recordLines = @($standardError -split "`r?`n" | Where-Object { $_.StartsWith($recordPrefix, [StringComparison]::Ordinal) })
        if ($recordLines.Count -eq 1) {
            try {
                $encodedRecord = $recordLines[0].Substring($recordPrefix.Length)
                $recordJson = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encodedRecord))
                $record = $recordJson | ConvertFrom-Json -ErrorAction Stop
                $exceptionType = [string] $record.type
                $exceptionMessage = [string] $record.message
            }
            catch {
                throw 'Synthetic PowerShell invocation returned an invalid rejection record.'
            }
        }
        elseif ($recordLines.Count -gt 1) {
            throw 'Synthetic PowerShell invocation returned multiple rejection records.'
        }

        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            StdOut = $stdout.GetAwaiter().GetResult()
            StdErr = $standardError
            ExceptionType = $exceptionType
            ExceptionMessage = $exceptionMessage
        }
    }
    finally {
        $process.Dispose()
    }
}

function Get-SafeFailureDiagnostic {
    param([Parameter(Mandatory)] $Result)

    $diagnostic = "exit=$($Result.ExitCode); exceptionType=$($Result.ExceptionType); exceptionMessage=$($Result.ExceptionMessage); stderr=$($Result.StdErr)"
    $diagnostic = $diagnostic.Replace($syntheticConnection, '<redacted-synthetic-connection>', [StringComparison]::Ordinal)
    $diagnostic = $diagnostic.Replace($temporaryParent, '<temporary-fixture-root>', [StringComparison]::Ordinal)
    if ($diagnostic.Length -gt 1200) { return $diagnostic.Substring(0, 1200) + '...' }
    return $diagnostic
}

function Assert-Rejected {
    param(
        [Parameter(Mandatory)] $Result,
        [Parameter(Mandatory)] [string] $ExpectedMessage,
        [Parameter(Mandatory)] [string] $Scenario
    )

    if ($Result.ExitCode -eq 0) {
        throw "EF migration bundle regression returned successfully instead of rejecting $Scenario."
    }
    if ($Result.ExitCode -ne $expectedRejectionExitCode -or [string]::IsNullOrWhiteSpace($Result.ExceptionType)) {
        throw "EF migration bundle regression encountered an unexpected process failure for $Scenario. $(Get-SafeFailureDiagnostic -Result $Result)"
    }
    if ([string]::IsNullOrWhiteSpace($Result.ExceptionMessage) -or
        -not $Result.ExceptionMessage.Contains($ExpectedMessage, [StringComparison]::Ordinal)) {
        throw "EF migration bundle regression encountered an unexpected exception for $Scenario. $(Get-SafeFailureDiagnostic -Result $Result)"
    }
}

New-Item -ItemType Directory -Path $temporaryParent -Force | Out-Null
try {
    $driverContent = @'
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $Invoker,
    [Parameter(Mandatory)] [string] $ImmutableArtifactRoot,
    [Parameter(Mandatory)] [string] $DeploymentManifestPath,
    [Parameter(Mandatory)] [string] $ExpectedSourceCommit,
    [Parameter(Mandatory)] [int] $ExpectedRejectionExitCode
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
try {
    & $Invoker `
        -ImmutableArtifactRoot $ImmutableArtifactRoot `
        -DeploymentManifestPath $DeploymentManifestPath `
        -ExpectedSourceCommit $ExpectedSourceCommit
    exit 0
}
catch {
    $record = [ordered]@{
        type = $_.Exception.GetType().FullName
        message = $_.Exception.Message
    }
    $json = $record | ConvertTo-Json -Compress
    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($json))
    [Console]::Error.WriteLine("AZDEMO_TEST_REJECTION:$encoded")
    exit $ExpectedRejectionExitCode
}
'@ -replace "`r`n", "`n"
    [IO.File]::WriteAllText($regressionDriver, $driverContent, [Text.UTF8Encoding]::new($false))

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
    Assert-Rejected -Result (Invoke-SyntheticBundle -Artifact $nonzero) -ExpectedMessage 'Reviewed EF migration bundle exited with code 23.' -Scenario 'a nonzero native-process exit'

    $missing = New-SyntheticBundleArtifact -Name 'missing executable' -Content ("#!/bin/sh`nexit 0`n")
    Remove-Item -LiteralPath $missing.Bundle -Force
    Assert-Rejected -Result (Invoke-SyntheticBundle -Artifact $missing) -ExpectedMessage 'A required immutable artifact path is missing or has the wrong type.' -Scenario 'a missing executable'

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
    Assert-Rejected -Result (Invoke-SyntheticBundle -Artifact $invalid) -ExpectedMessage 'Reviewed EF migration bundle could not be launched as a native process.' -Scenario 'an invalid executable format'
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
    Assert-Rejected -Result (Invoke-SyntheticBundle -Artifact $tampered) -ExpectedMessage 'Deployment artifact payload SHA-256 validation failed.' -Scenario 'artifact tampering'
    if ((Test-Path -LiteralPath $tamperMarker) -or
        (([IO.File]::GetUnixFileMode($tampered.Bundle) -band [IO.UnixFileMode]::UserExecute) -ne 0)) {
        throw 'Tampered artifact reached permission adjustment or execution.'
    }

    $linkExecutionMarker = Join-Path $temporaryParent 'bundle link execution marker.txt'
    $linkedPayload = "#!/bin/sh`nprintf 'executed' > $(ConvertTo-ShellSingleQuotedLiteral $linkExecutionMarker)`nexit 0`n"
    $outsideBundle = Join-Path $temporaryParent 'outside bundle'
    [IO.File]::WriteAllText($outsideBundle, $linkedPayload, [Text.UTF8Encoding]::new($false))
    Set-OwnerReadWriteOnly -Path $outsideBundle
    $linked = New-SyntheticBundleArtifact -Name 'symbolic link rejection' -Content $linkedPayload
    Remove-Item -LiteralPath $linked.Bundle -Force
    New-VerifiedSymbolicLink -LinkPath $linked.Bundle -TargetPath $outsideBundle -Scenario 'a bundle symbolic-link substitution'
    Assert-Rejected -Result (Invoke-SyntheticBundle -Artifact $linked) -ExpectedMessage 'Immutable artifact paths must not contain symbolic links or reparse points.' -Scenario 'a bundle symbolic-link substitution'
    if (Test-Path -LiteralPath $linkExecutionMarker) {
        throw 'Rejected bundle symbolic-link substitution launched its payload.'
    }

    $ancestorExecutionMarker = Join-Path $temporaryParent 'ancestor link execution marker.txt'
    $ancestorPayload = "#!/bin/sh`nprintf 'executed' > $(ConvertTo-ShellSingleQuotedLiteral $ancestorExecutionMarker)`nexit 0`n"
    $ancestorLinked = New-SyntheticBundleArtifact -Name 'ancestor symbolic link rejection' -Content $ancestorPayload
    $outsideMigrationDirectory = Join-Path $temporaryParent 'outside migration directory'
    New-Item -ItemType Directory -Path $outsideMigrationDirectory -Force | Out-Null
    $outsideAncestorBundle = Join-Path $outsideMigrationDirectory 'lgrtm-efbundle-linux-x64'
    [IO.File]::WriteAllText($outsideAncestorBundle, $ancestorPayload, [Text.UTF8Encoding]::new($false))
    Set-OwnerReadWriteOnly -Path $outsideAncestorBundle
    $linkedMigrationDirectory = Join-Path $ancestorLinked.Root 'migration'
    Remove-Item -LiteralPath $linkedMigrationDirectory -Recurse -Force
    New-VerifiedSymbolicLink -LinkPath $linkedMigrationDirectory -TargetPath $outsideMigrationDirectory -Scenario 'an ancestor-directory symbolic-link substitution'
    Assert-Rejected -Result (Invoke-SyntheticBundle -Artifact $ancestorLinked) -ExpectedMessage 'Immutable artifact paths must not contain symbolic links or reparse points.' -Scenario 'an ancestor-directory symbolic-link substitution'
    if (Test-Path -LiteralPath $ancestorExecutionMarker) {
        throw 'Rejected ancestor-directory symbolic-link substitution launched its payload.'
    }

    $rootExecutionMarker = Join-Path $temporaryParent 'root link execution marker.txt'
    $rootPayload = "#!/bin/sh`nprintf 'executed' > $(ConvertTo-ShellSingleQuotedLiteral $rootExecutionMarker)`nexit 0`n"
    $rootTarget = New-SyntheticBundleArtifact -Name 'root symbolic link target' -Content $rootPayload
    $linkedRoot = Join-Path $temporaryParent 'root symbolic link substitution'
    New-VerifiedSymbolicLink -LinkPath $linkedRoot -TargetPath $rootTarget.Root -Scenario 'an immutable-root symbolic-link substitution'
    $rootLinkedArtifact = [pscustomobject]@{
        Root = $linkedRoot
        Bundle = Join-Path $linkedRoot 'migration/lgrtm-efbundle-linux-x64'
        Manifest = Join-Path $linkedRoot 'deployment-artifact-manifest.json'
    }
    Assert-Rejected -Result (Invoke-SyntheticBundle -Artifact $rootLinkedArtifact) -ExpectedMessage 'Immutable artifact paths must not contain symbolic links or reparse points.' -Scenario 'an immutable-root symbolic-link substitution'
    if (Test-Path -LiteralPath $rootExecutionMarker) {
        throw 'Rejected immutable-root symbolic-link substitution launched its payload.'
    }

    $dangling = New-SyntheticBundleArtifact -Name 'dangling symbolic link rejection' -Content ("#!/bin/sh`nexit 0`n")
    Remove-Item -LiteralPath $dangling.Bundle -Force
    $missingLinkTarget = Join-Path $temporaryParent 'nonexistent bundle target'
    New-VerifiedSymbolicLink -LinkPath $dangling.Bundle -TargetPath $missingLinkTarget -Scenario 'a dangling bundle symbolic link'
    Assert-Rejected -Result (Invoke-SyntheticBundle -Artifact $dangling) -ExpectedMessage 'Immutable artifact paths must not contain symbolic links or reparse points.' -Scenario 'a dangling bundle symbolic link'

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

Write-Output 'Linux EF migration bundle execution regression passed permission, native launch, wait, exit, path, tamper, bundle/ancestor/root/dangling symlink, association and hash checks.'
