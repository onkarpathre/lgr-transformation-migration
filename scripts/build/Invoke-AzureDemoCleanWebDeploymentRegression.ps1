[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-f]{40}$')]
    [string] $ExpectedSourceCommit,
    [string] $TestScriptPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$TestScriptPath = if ([string]::IsNullOrWhiteSpace($TestScriptPath)) {
    Join-Path $PSScriptRoot 'Test-AzureDemoCleanWebDeployment.ps1'
}
else {
    $TestScriptPath
}
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).ProviderPath
if (-not (Test-Path -LiteralPath $TestScriptPath -PathType Leaf)) {
    throw 'Clean web deployment regression script is missing.'
}
$resolvedTestScript = (Resolve-Path -LiteralPath $TestScriptPath).ProviderPath

$sourceRows = @(& git -C $repo rev-parse HEAD)
$sourceExitCode = $LASTEXITCODE
if ($sourceExitCode -ne 0) {
    throw "Could not resolve the clean deployment regression source SHA (git exit code $sourceExitCode)."
}
$sourceSha = [string]::Join([Environment]::NewLine, [string[]] $sourceRows).Trim()
if ($sourceSha -cnotmatch '^[0-9a-f]{40}$' -or $sourceSha -cne $ExpectedSourceCommit) {
    throw 'Clean web deployment regression source SHA does not match the pipeline source version.'
}

$powerShellPath = (Get-Process -Id $PID).Path
$runtimeVersion = $PSVersionTable.PSVersion.ToString()
$testFileSha256 = (Get-FileHash -LiteralPath $resolvedTestScript -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Output ("Clean web deployment regression identity: sourceSha={0}; runtimeVersion={1}; testFileSha256={2}" -f `
        $sourceSha, $runtimeVersion, $testFileSha256)

& $powerShellPath -NoLogo -NoProfile -NonInteractive -File $resolvedTestScript
$childExitCode = $LASTEXITCODE
Write-Output ("Clean web deployment regression process: childExitCode={0}" -f $childExitCode)
if ($childExitCode -ne 0) {
    throw "Clean web deployment regression child failed with exit code $childExitCode."
}
