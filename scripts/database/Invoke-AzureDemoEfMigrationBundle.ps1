[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ImmutableArtifactRoot,
    [Parameter(Mandatory)] [string] $DeploymentManifestPath,
    [Parameter(Mandatory)] [string] $ExpectedSourceCommit
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Linux)) {
    throw 'The reviewed EF migration bundle may be executed only on Linux.'
}

. (Join-Path $PSScriptRoot '../build/AzureDemoDeploymentArtifactUtilities.ps1')

function Invoke-ExactNativeProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $FilePath,
        [Parameter(Mandatory)] [AllowEmptyCollection()] [string[]] $ArgumentList,
        [Parameter(Mandatory)] [string] $Operation
    )

    if (-not [IO.Path]::IsPathRooted($FilePath)) {
        throw "$Operation requires an absolute executable path."
    }

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $FilePath
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $false
    $startInfo.RedirectStandardError = $false
    foreach ($argument in $ArgumentList) {
        $startInfo.ArgumentList.Add($argument)
    }

    $process = $null
    try {
        try {
            $process = [Diagnostics.Process]::Start($startInfo)
        }
        catch {
            throw "$Operation could not be launched as a native process."
        }
        if ($null -eq $process) {
            throw "$Operation did not return a native process."
        }

        try {
            $process.WaitForExit()
        }
        catch {
            throw "$Operation completion could not be observed."
        }
        if (-not $process.HasExited) {
            throw "$Operation completed without an exit status."
        }

        [int] $exitCode = 0
        $exitCodeRead = $false
        try {
            $exitCode = $process.ExitCode
            $exitCodeRead = $true
        }
        catch {
            throw "$Operation exit status could not be read."
        }
        if (-not $exitCodeRead) {
            throw "$Operation completed without an exit status."
        }
        return $exitCode
    }
    finally {
        if ($null -ne $process) {
            $process.Dispose()
        }
    }
}

function Get-RequiredLinuxUtility {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string] $Name)

    foreach ($candidate in @("/usr/bin/$Name", "/bin/$Name")) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }
    throw "Required Linux utility $Name is unavailable."
}

if (-not [IO.Path]::IsPathRooted($ImmutableArtifactRoot) -or
    -not [IO.Path]::IsPathRooted($DeploymentManifestPath)) {
    throw 'Migration execution requires explicit absolute immutable-artifact paths.'
}

$artifactRoot = [IO.Path]::GetFullPath($ImmutableArtifactRoot).TrimEnd([char[]] @('\', '/'))
$expectedBundlePath = Join-Path $artifactRoot 'migration/lgrtm-efbundle-linux-x64'
$bundlePath = Resolve-AzureDemoArtifactPath -ArtifactRoot $artifactRoot -Path $expectedBundlePath -PathType Leaf
$regularFileUtility = Get-RequiredLinuxUtility -Name 'test'
$regularFileExitCode = Invoke-ExactNativeProcess -FilePath $regularFileUtility -ArgumentList @('-f', $bundlePath) -Operation 'EF migration bundle regular-file validation'
if ($regularFileExitCode -ne 0) {
    throw 'The reviewed EF migration bundle is not a regular file.'
}

$deployment = Assert-AzureDemoDeploymentArtifact `
    -ArtifactRoot $artifactRoot `
    -ManifestPath $DeploymentManifestPath `
    -ExpectedSourceCommit $ExpectedSourceCommit
if (-not $bundlePath.Equals($expectedBundlePath, (Get-AzureDemoArtifactPathComparison)) -or
    -not $deployment.ArtifactRoot.Equals($artifactRoot.TrimEnd([char[]] @('\', '/')), (Get-AzureDemoArtifactPathComparison))) {
    throw 'The reviewed EF migration bundle is not the exact approved immutable-artifact payload.'
}

$connectionString = [Environment]::GetEnvironmentVariable('LGR_AZURE_DEMO_SQL_CONNECTION_STRING', [EnvironmentVariableTarget]::Process)
if ([string]::IsNullOrWhiteSpace($connectionString)) {
    throw 'The protected migration stage must supply LGR_AZURE_DEMO_SQL_CONNECTION_STRING.'
}

$approvedHashBeforePermissionChange = (Get-FileHash -LiteralPath $bundlePath -Algorithm SHA256).Hash
$chmod = Get-RequiredLinuxUtility -Name 'chmod'
$chmodExitCode = Invoke-ExactNativeProcess -FilePath $chmod -ArgumentList @('u+x', '--', $bundlePath) -Operation 'EF migration bundle permission adjustment'
if ($chmodExitCode -ne 0) {
    throw "EF migration bundle permission adjustment exited with code $chmodExitCode."
}

$postPermissionBundlePath = Resolve-AzureDemoArtifactPath -ArtifactRoot $artifactRoot -Path $expectedBundlePath -PathType Leaf
$regularFileExitCode = Invoke-ExactNativeProcess -FilePath $regularFileUtility -ArgumentList @('-f', $postPermissionBundlePath) -Operation 'EF migration bundle post-permission regular-file validation'
if ($regularFileExitCode -ne 0) {
    throw 'The reviewed EF migration bundle is not a regular file after permission adjustment.'
}
$mode = [IO.File]::GetUnixFileMode($postPermissionBundlePath)
if (($mode -band [IO.UnixFileMode]::UserExecute) -eq 0) {
    throw 'The reviewed EF migration bundle is not executable after permission adjustment.'
}
$approvedHashAfterPermissionChange = (Get-FileHash -LiteralPath $postPermissionBundlePath -Algorithm SHA256).Hash
if (-not [string]::Equals($approvedHashBeforePermissionChange, $approvedHashAfterPermissionChange, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'The reviewed EF migration bundle content changed during permission adjustment.'
}

$bundleExitCode = Invoke-ExactNativeProcess `
    -FilePath $postPermissionBundlePath `
    -ArgumentList @('--connection', $connectionString) `
    -Operation 'Reviewed EF migration bundle'
if ($bundleExitCode -ne 0) {
    throw "Reviewed EF migration bundle exited with code $bundleExitCode."
}

Write-Output 'Reviewed EF migration bundle completed successfully.'
