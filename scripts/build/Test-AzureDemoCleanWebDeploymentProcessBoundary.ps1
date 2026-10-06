[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-f]{40}$')]
    [string] $ExpectedSourceCommit
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).ProviderPath
$invoker = Join-Path $PSScriptRoot 'Invoke-AzureDemoCleanWebDeploymentRegression.ps1'
$actualRegression = Join-Path $PSScriptRoot 'Test-AzureDemoCleanWebDeployment.ps1'
$powerShellPath = (Get-Process -Id $PID).Path
$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-clean-process-$([Guid]::NewGuid().ToString('N'))")
$results = [Collections.Generic.List[object]]::new()

function ConvertTo-PowerShellLiteral([string] $Value) {
    return "'$($Value.Replace("'", "''"))'"
}

function Invoke-GeneratedCallerCase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [string] $TestScript,
        [Parameter(Mandatory)] [bool] $ExpectSuccess
    )

    $callerPath = Join-Path $temporaryDirectory "$Name-generated-caller.ps1"
    $stderrPath = Join-Path $temporaryDirectory "$Name.stderr"
    $caller = @"
`$ErrorActionPreference = 'Stop'
& $(ConvertTo-PowerShellLiteral $invoker) -ExpectedSourceCommit $(ConvertTo-PowerShellLiteral $ExpectedSourceCommit) -TestScriptPath $(ConvertTo-PowerShellLiteral $TestScript)
if (!(Test-Path -LiteralPath variable:\LASTEXITCODE)) {
    Write-Host '##vso[task.debug]`$LASTEXITCODE is not set.'
}
else {
    Write-Host ("##vso[task.debug]LASTEXITCODE: {0}" -f `$LASTEXITCODE)
    exit `$LASTEXITCODE
}
"@
    [IO.File]::WriteAllText($callerPath, $caller, [Text.UTF8Encoding]::new($false))

    $dotSourceCommand = ". $(ConvertTo-PowerShellLiteral $callerPath)"
    $priorErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $stdoutRows = @(& $powerShellPath -NoLogo -NoProfile -NonInteractive -Command $dotSourceCommand 2> $stderrPath)
    $outerExitCode = $LASTEXITCODE
    $ErrorActionPreference = $priorErrorActionPreference
    $stderrText = if (Test-Path -LiteralPath $stderrPath) { [IO.File]::ReadAllText($stderrPath) } else { '' }

    if ($ExpectSuccess -and $outerExitCode -ne 0) {
        $boundedStderr = $stderrText.Replace($temporaryDirectory, '<temporary-directory>')
        if ($boundedStderr.Length -gt 600) { $boundedStderr = $boundedStderr.Substring(0, 600) }
        throw "Generated caller success case exited $outerExitCode instead of 0; stderr: $boundedStderr"
    }
    if (-not $ExpectSuccess -and $outerExitCode -eq 0) {
        throw "Generated caller failure case $Name returned exit 0."
    }
    return [pscustomobject]@{
        Name = $Name
        ExitCode = $outerExitCode
        Stdout = [string]::Join([Environment]::NewLine, [string[]] $stdoutRows)
        StderrLength = $stderrText.Length
    }
}

New-Item -ItemType Directory -Path $temporaryDirectory -Force | Out-Null
try {
    $assertionFailure = Join-Path $temporaryDirectory 'assertion-failure.ps1'
    $nativeFailure = Join-Path $temporaryDirectory 'native-failure.ps1'
    $cleanupFailure = Join-Path $temporaryDirectory 'cleanup-failure.ps1'
    $missingScript = Join-Path $temporaryDirectory 'missing-regression.ps1'
    [IO.File]::WriteAllText($assertionFailure, "throw 'Synthetic assertion failure.'`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($nativeFailure, @'
$powerShellPath = (Get-Process -Id $PID).Path
& $powerShellPath -NoLogo -NoProfile -NonInteractive -Command 'exit 23'
$nativeExitCode = $LASTEXITCODE
if ($nativeExitCode -ne 23) { throw 'Synthetic native failure did not return exit 23.' }
exit $nativeExitCode
'@, [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($cleanupFailure, @'
try {
    Write-Output 'Synthetic work completed before cleanup.'
}
finally {
    throw 'Synthetic cleanup failure.'
}
'@, [Text.UTF8Encoding]::new($false))

    $results.Add((Invoke-GeneratedCallerCase -Name assertion -TestScript $assertionFailure -ExpectSuccess $false))
    $results.Add((Invoke-GeneratedCallerCase -Name native -TestScript $nativeFailure -ExpectSuccess $false))
    $results.Add((Invoke-GeneratedCallerCase -Name missing -TestScript $missingScript -ExpectSuccess $false))
    $results.Add((Invoke-GeneratedCallerCase -Name cleanup -TestScript $cleanupFailure -ExpectSuccess $false))
    $actual = Invoke-GeneratedCallerCase -Name actual -TestScript $actualRegression -ExpectSuccess $true
    $results.Add($actual)

    $expectedRuntime = $PSVersionTable.PSVersion.ToString()
    $expectedHash = (Get-FileHash -LiteralPath $actualRegression -Algorithm SHA256).Hash.ToLowerInvariant()
    foreach ($fragment in @(
            "sourceSha=$ExpectedSourceCommit",
            "runtimeVersion=$expectedRuntime",
            "testFileSha256=$expectedHash",
            'childExitCode=0',
            'Clean web deployment regression passed')) {
        if ($actual.Stdout.IndexOf($fragment, [StringComparison]::Ordinal) -lt 0) {
            throw "Generated caller success output is missing diagnostic fragment: $fragment"
        }
    }
    Write-Output $actual.Stdout
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
}

if (Test-Path -LiteralPath $temporaryDirectory) {
    throw 'Clean deployment process-boundary regression cleanup left its temporary directory behind.'
}
$summary = @($results | ForEach-Object { "$($_.Name)=$($_.ExitCode)" }) -join '; '
Write-Output "Azure DevOps generated-caller process-boundary regression passed: $summary."
