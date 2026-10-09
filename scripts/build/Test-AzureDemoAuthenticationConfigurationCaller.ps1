[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$scriptPath = Join-Path $PSScriptRoot 'Test-AzureDemoAuthenticationConfiguration.ps1'
$source = [IO.File]::ReadAllText($scriptPath)
$powerShellPath = [string] (Get-Process -Id $PID).Path
if ([string]::IsNullOrWhiteSpace($powerShellPath) -or -not (Test-Path -LiteralPath $powerShellPath -PathType Leaf)) {
    throw 'The current PowerShell executable path is invalid.'
}

$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-auth-caller-$([Guid]::NewGuid().ToString('N'))")
New-Item -ItemType Directory -Path $temporaryDirectory -Force | Out-Null

function New-MutatedScript([string] $Name, [string] $Content) {
    $path = Join-Path $PSScriptRoot (".azdemo-auth-caller-{0}-{1}.ps1" -f $Name, [Guid]::NewGuid().ToString('N'))
    [IO.File]::WriteAllText($path, $Content, [Text.UTF8Encoding]::new($false))
    return $path
}

function Invoke-PowerShellTaskCaller([string] $Name, [string] $TargetScript) {
    $callerPath = Join-Path $temporaryDirectory ("caller-$Name.ps1")
    $stdoutPath = Join-Path $temporaryDirectory ("stdout-$Name.txt")
    $stderrPath = Join-Path $temporaryDirectory ("stderr-$Name.txt")
    $escapedTarget = $TargetScript.Replace("'", "''")
    $caller = @"
& '$escapedTarget'
if ((Test-Path -LiteralPath variable:\LASTEXITCODE)) { exit `$LASTEXITCODE }
"@
    [IO.File]::WriteAllText($callerPath, $caller, [Text.UTF8Encoding]::new($false))
    $arguments = @('-NoLogo', '-NoProfile', '-NonInteractive')
    if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Windows)) {
        $arguments += @('-ExecutionPolicy', 'Bypass')
    }
    $arguments += @('-File', $callerPath)
    $priorErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & $powerShellPath @arguments 1> $stdoutPath 2> $stderrPath
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $priorErrorActionPreference
    }
    return [pscustomobject]@{
        ExitCode = $exitCode
        Diagnostics = [IO.File]::ReadAllText($stdoutPath) + "`n" + [IO.File]::ReadAllText($stderrPath)
    }
}

$mutatedScripts = [Collections.Generic.List[string]]::new()
try {
    $normal = Invoke-PowerShellTaskCaller -Name 'success' -TargetScript $scriptPath
    if ($normal.ExitCode -ne 0 -or $normal.Diagnostics -notmatch 'package-entry regression passed') {
        throw "The PowerShell@2 caller did not preserve authentication regression success: exit=$($normal.ExitCode)."
    }

    $assertionSource = $source.Replace(
        "Write-Output 'AzureDemo authentication configuration package-entry regression passed.'",
        "throw 'Injected authentication regression assertion failure.'")
    if ($assertionSource -ceq $source) { throw 'Could not create the assertion-failure fixture.' }
    $assertionScript = New-MutatedScript -Name 'assertion' -Content $assertionSource
    $mutatedScripts.Add($assertionScript)

    $cleanupMarker = "}`r`n`r`nWrite-Output 'AzureDemo authentication configuration package-entry regression passed.'"
    if (-not $source.Contains($cleanupMarker)) {
        $cleanupMarker = "}`n`nWrite-Output 'AzureDemo authentication configuration package-entry regression passed.'"
    }
    $cleanupSource = $source.Replace(
        $cleanupMarker,
        "    throw 'Injected authentication regression cleanup failure.'`r`n}`r`n`r`nWrite-Output 'AzureDemo authentication configuration package-entry regression passed.'")
    if ($cleanupSource -ceq $source) { throw 'Could not create the cleanup-failure fixture.' }
    $cleanupScript = New-MutatedScript -Name 'cleanup' -Content $cleanupSource
    $mutatedScripts.Add($cleanupScript)

    if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Windows)) {
        $childMarker = '> "%AUTH_DOTNET_MARKER%" echo reached' + "`r`nexit /b 0"
        $childReplacement = '> "%AUTH_DOTNET_MARKER%" echo reached' + "`r`nexit /b 87"
    }
    else {
        $childMarker = 'printf reached > "$AUTH_DOTNET_MARKER"' + "`nexit 0"
        $childReplacement = 'printf reached > "$AUTH_DOTNET_MARKER"' + "`nexit 87"
    }
    $childSource = $source.Replace($childMarker, $childReplacement)
    if ($childSource -ceq $source) { throw 'Could not create the unexpected-child-failure fixture.' }
    $childScript = New-MutatedScript -Name 'child' -Content $childSource
    $mutatedScripts.Add($childScript)

    foreach ($scenario in @(
            @{ Name = 'assertion'; Path = $assertionScript },
            @{ Name = 'cleanup'; Path = $cleanupScript },
            @{ Name = 'unexpected-child'; Path = $childScript })) {
        $result = Invoke-PowerShellTaskCaller -Name $scenario.Name -TargetScript $scenario.Path
        if ($result.ExitCode -eq 0) {
            throw "The PowerShell@2 caller masked the injected $($scenario.Name) failure."
        }
    }
}
finally {
    foreach ($path in $mutatedScripts) {
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
    }
    if (Test-Path -LiteralPath $temporaryDirectory) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
}

Write-Output 'AzureDemo authentication regression passed the PowerShell@2 generated-caller success and failure contract.'
