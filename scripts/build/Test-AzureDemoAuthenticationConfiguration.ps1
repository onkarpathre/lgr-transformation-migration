[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).ProviderPath
$packageScriptPath = Join-Path $repo 'scripts\build\New-AzureDemoPackages.ps1'
$packageScript = Get-Content -LiteralPath $packageScriptPath -Raw
$validatorPath = Join-Path $repo 'src\web\scripts\validate-azure-demo-auth-config.mjs'
$validatorInvocation = '& node $authValidator'
$validatorIndex = $packageScript.IndexOf($validatorInvocation, [StringComparison]::Ordinal)
$outputCreationIndex = $packageScript.IndexOf('New-Item -ItemType Directory -Path $output -Force', [StringComparison]::Ordinal)
$apiCompilationIndex = $packageScript.IndexOf('dotnet publish src/api/LgrTransformationMigration.Api.csproj', [StringComparison]::Ordinal)
$webCompilationIndex = $packageScript.IndexOf('& $npmCommand run build', [StringComparison]::Ordinal)

if (-not (Test-Path -LiteralPath $validatorPath -PathType Leaf)) {
    throw 'The reusable AzureDemo authentication configuration validator is missing.'
}
if ($validatorIndex -lt 0 -or $outputCreationIndex -le $validatorIndex -or
    $apiCompilationIndex -le $outputCreationIndex -or $webCompilationIndex -le $apiCompilationIndex) {
    throw 'Application packaging must validate authentication before output creation, API compilation, and the existing web build path.'
}
$validatedBuildSegment = $packageScript.Substring($validatorIndex, $webCompilationIndex - $validatorIndex)
if ($validatedBuildSegment -match '(?im)\$env:(?:NEXT_PUBLIC_ENTRA_TENANT_ID|NEXT_PUBLIC_ENTRA_CLIENT_ID|NEXT_PUBLIC_API_SCOPE|AZDEMO_API_CLIENT_ID)\s*=') {
    throw 'Application packaging changes an authentication setting after validation and before the web build.'
}

$powerShellPath = [string] (Get-Process -Id $PID).Path
if ([string]::IsNullOrWhiteSpace($powerShellPath) -or -not (Test-Path -LiteralPath $powerShellPath -PathType Leaf)) {
    throw 'The current PowerShell executable path is invalid.'
}

$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-auth-package-$([Guid]::NewGuid().ToString('N'))")
$outputDirectory = Join-Path $repo ('.codex-temp\auth-package-rejection-{0}' -f [Guid]::NewGuid().ToString('N'))
$validOutputDirectory = Join-Path $repo ('.codex-temp\auth-package-valid-{0}' -f [Guid]::NewGuid().ToString('N'))
$stdoutPath = Join-Path $temporaryDirectory 'stdout.txt'
$stderrPath = Join-Path $temporaryDirectory 'stderr.txt'
$settingNames = @(
    'NEXT_PUBLIC_ENTRA_TENANT_ID',
    'NEXT_PUBLIC_ENTRA_CLIENT_ID',
    'NEXT_PUBLIC_API_SCOPE',
    'AZDEMO_API_CLIENT_ID'
)
$priorValues = @{}
foreach ($settingName in $settingNames) {
    $priorValues[$settingName] = [Environment]::GetEnvironmentVariable($settingName, 'Process')
}
$priorPath = $env:PATH
$priorDotnetMarker = [Environment]::GetEnvironmentVariable('AUTH_DOTNET_MARKER', 'Process')
$priorNpmMarker = [Environment]::GetEnvironmentVariable('AUTH_NPM_MARKER', 'Process')

New-Item -ItemType Directory -Path $temporaryDirectory -Force | Out-Null
try {
    $env:NEXT_PUBLIC_ENTRA_TENANT_ID = 'd68cff79-a08e-4a81-b724-e3fdea2af74d'
    $env:NEXT_PUBLIC_ENTRA_CLIENT_ID = '9be061c9-bb94-4fdc-9347-edda6363af19'
    $env:AZDEMO_API_CLIENT_ID = 'a09f84de-7f30-4c53-86db-13b249597837'
    $env:NEXT_PUBLIC_API_SCOPE = '$(AZDEMO_API_SCOPE)'

    $nativeArguments = @('-NoLogo', '-NoProfile', '-NonInteractive')
    if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Windows)) {
        $nativeArguments += @('-ExecutionPolicy', 'Bypass')
    }
    $nativeArguments += @(
        '-File',
        $packageScriptPath,
        '-OutputDirectory',
        $outputDirectory,
        '-SkipRestore',
        '-SkipTests'
    )
    $priorErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & $powerShellPath @nativeArguments 1> $stdoutPath 2> $stderrPath
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $priorErrorActionPreference
    }

    if ($exitCode -eq 0) {
        throw 'The actual application package entry point accepted an unresolved authentication scope.'
    }
    if (Test-Path -LiteralPath $outputDirectory) {
        throw 'The actual application package entry point created package output before rejecting authentication configuration.'
    }
    $diagnostics = [IO.File]::ReadAllText($stdoutPath) + "`n" + [IO.File]::ReadAllText($stderrPath)
    if ($diagnostics -notmatch 'NEXT_PUBLIC_API_SCOPE') {
        throw 'The application package rejection did not name NEXT_PUBLIC_API_SCOPE.'
    }
    if ($diagnostics -notmatch 'unresolved\s+Azure\s+Pipelines\s+macro') {
        throw 'The application package rejection did not identify the unresolved macro.'
    }
    if ($diagnostics.Contains($env:AZDEMO_API_CLIENT_ID)) {
        throw 'The application package rejection disclosed an unrelated configured identifier.'
    }

    $shimDirectory = Join-Path $temporaryDirectory 'shims'
    $dotnetMarker = Join-Path $temporaryDirectory 'dotnet-reached.txt'
    $npmMarker = Join-Path $temporaryDirectory 'npm-reached.txt'
    New-Item -ItemType Directory -Path $shimDirectory -Force | Out-Null
    if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Windows)) {
        $dotnetShim = Join-Path $shimDirectory 'dotnet.cmd'
        $npmShim = Join-Path $shimDirectory 'npm.cmd'
        [IO.File]::WriteAllText($dotnetShim, @'
@echo off
if "%~1"=="--version" (
  echo 10.0.401
  exit /b 0
)
if not "%~1"=="publish" exit /b 90
set "previous="
set "output="
:arguments
if "%~1"=="" goto publish
if "%previous%"=="--output" set "output=%~1"
set "previous=%~1"
shift
goto arguments
:publish
if "%output%"=="" exit /b 91
if not exist "%output%" mkdir "%output%"
> "%output%\synthetic.dll" echo synthetic
> "%AUTH_DOTNET_MARKER%" echo reached
exit /b 0
'@, [Text.Encoding]::ASCII)
        [IO.File]::WriteAllText($npmShim, @'
@echo off
> "%AUTH_NPM_MARKER%" echo reached
exit /b 29
'@, [Text.Encoding]::ASCII)
    }
    else {
        $dotnetShim = Join-Path $shimDirectory 'dotnet'
        $npmShim = Join-Path $shimDirectory 'npm'
        [IO.File]::WriteAllText($dotnetShim, @'
#!/bin/sh
if [ "$1" = "--version" ]; then
  printf '10.0.401\n'
  exit 0
fi
if [ "$1" != "publish" ]; then exit 90; fi
output=''
previous=''
for argument in "$@"; do
  if [ "$previous" = "--output" ]; then output="$argument"; fi
  previous="$argument"
done
if [ -z "$output" ]; then exit 91; fi
mkdir -p "$output"
printf synthetic > "$output/synthetic.dll"
printf reached > "$AUTH_DOTNET_MARKER"
exit 0
'@, [Text.UTF8Encoding]::new($false))
        [IO.File]::WriteAllText($npmShim, @'
#!/bin/sh
printf reached > "$AUTH_NPM_MARKER"
exit 29
'@, [Text.UTF8Encoding]::new($false))
        & chmod +x $dotnetShim $npmShim
        if ($LASTEXITCODE) { throw 'Could not make package-entry command shims executable.' }
    }

    $env:PATH = "$shimDirectory$([IO.Path]::PathSeparator)$priorPath"
    $env:AUTH_DOTNET_MARKER = $dotnetMarker
    $env:AUTH_NPM_MARKER = $npmMarker
    $env:NEXT_PUBLIC_API_SCOPE = 'api://a09f84de-7f30-4c53-86db-13b249597837/lgr.access'
    $validStdoutPath = Join-Path $temporaryDirectory 'valid-stdout.txt'
    $validStderrPath = Join-Path $temporaryDirectory 'valid-stderr.txt'
    $validArguments = @('-NoLogo', '-NoProfile', '-NonInteractive')
    if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Windows)) {
        $validArguments += @('-ExecutionPolicy', 'Bypass')
    }
    $validArguments += @(
        '-File',
        $packageScriptPath,
        '-OutputDirectory',
        $validOutputDirectory,
        '-SkipRestore',
        '-SkipTests'
    )
    try {
        $ErrorActionPreference = 'Continue'
        & $powerShellPath @validArguments 1> $validStdoutPath 2> $validStderrPath
        $validExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $priorErrorActionPreference
    }
    $validDiagnostics = [IO.File]::ReadAllText($validStdoutPath) + "`n" + [IO.File]::ReadAllText($validStderrPath)
    if ($validExitCode -eq 0 -or
        -not (Test-Path -LiteralPath $dotnetMarker -PathType Leaf) -or
        -not (Test-Path -LiteralPath $npmMarker -PathType Leaf) -or
        $validDiagnostics -notmatch 'Next\.js production build failed') {
        throw 'Valid authentication configuration did not reach the existing API and web build paths with nonzero native failure propagation.'
    }
    if (Test-Path -LiteralPath (Join-Path $validOutputDirectory 'web.zip')) {
        throw 'Application packaging published web.zip after the controlled web build failure.'
    }
}
finally {
    foreach ($settingName in $settingNames) {
        [Environment]::SetEnvironmentVariable($settingName, $priorValues[$settingName], 'Process')
    }
    $env:PATH = $priorPath
    [Environment]::SetEnvironmentVariable('AUTH_DOTNET_MARKER', $priorDotnetMarker, 'Process')
    [Environment]::SetEnvironmentVariable('AUTH_NPM_MARKER', $priorNpmMarker, 'Process')
    if (Test-Path -LiteralPath $temporaryDirectory) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
    if (Test-Path -LiteralPath $outputDirectory) {
        Remove-Item -LiteralPath $outputDirectory -Recurse -Force
    }
    if (Test-Path -LiteralPath $validOutputDirectory) {
        Remove-Item -LiteralPath $validOutputDirectory -Recurse -Force
    }
}

Write-Output 'AzureDemo authentication configuration package-entry regression passed.'
