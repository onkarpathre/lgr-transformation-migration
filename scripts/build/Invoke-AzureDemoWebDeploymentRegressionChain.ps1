[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-f]{40}$')]
    [string] $ExpectedSourceCommit,
    [string] $PackageDirectory = 'artifacts/azure-demo-ci/packages'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$powerShellPath = [string] (Get-Process -Id $PID).Path
if ([string]::IsNullOrWhiteSpace($powerShellPath) -or
    -not (Test-Path -LiteralPath $powerShellPath -PathType Leaf)) {
    throw 'The current PowerShell executable path is invalid.'
}

$testCases = @(
    [pscustomobject]@{
        Name = 'linux-web-deployment-timestamp'
        Script = Join-Path $PSScriptRoot 'Test-AzureDemoLinuxWebDeploymentTimestamp.ps1'
        Arguments = @()
    },
    [pscustomobject]@{
        Name = 'clean-web-deployment'
        Script = Join-Path $PSScriptRoot 'Test-AzureDemoCleanWebDeployment.ps1'
        Arguments = @()
    },
    [pscustomobject]@{
        Name = 'generated-caller-process-boundary'
        Script = Join-Path $PSScriptRoot 'Test-AzureDemoCleanWebDeploymentProcessBoundary.ps1'
        Arguments = @('-ExpectedSourceCommit', $ExpectedSourceCommit)
    },
    [pscustomobject]@{
        Name = 'deployed-content-verification'
        Script = Join-Path $PSScriptRoot 'Test-AzureDemoDeployedContentVerification.ps1'
        Arguments = @()
    },
    [pscustomobject]@{
        Name = 'package-generation'
        Script = Join-Path $PSScriptRoot 'Test-AzureDemoPackageGeneration.ps1'
        Arguments = @('-PackageDirectory', $PackageDirectory, '-ExpectedSourceCommit', $ExpectedSourceCommit)
    },
    [pscustomobject]@{
        Name = 'pipeline-structure'
        Script = Join-Path $PSScriptRoot 'Test-AzurePipelineStructure.ps1'
        Arguments = @()
    }
)

$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-web-regression-chain-$([Guid]::NewGuid().ToString('N'))")
$results = [Collections.Generic.List[object]]::new()
New-Item -ItemType Directory -Path $temporaryDirectory -Force | Out-Null
try {
    foreach ($testCase in $testCases) {
        $stdoutPath = Join-Path $temporaryDirectory "$($testCase.Name).stdout"
        $stderrPath = Join-Path $temporaryDirectory "$($testCase.Name).stderr"
        $exitCode = 1
        if (-not (Test-Path -LiteralPath $testCase.Script -PathType Leaf)) {
            [IO.File]::WriteAllText($stderrPath, 'Regression script is missing.', [Text.UTF8Encoding]::new($false))
        }
        else {
            $nativeArguments = @('-NoLogo', '-NoProfile', '-NonInteractive')
            if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Windows)) {
                $nativeArguments += @('-ExecutionPolicy', 'Bypass')
            }
            $nativeArguments += @('-File', [string] $testCase.Script) +
                @($testCase.Arguments | ForEach-Object { [string] $_ })
            $priorErrorActionPreference = $ErrorActionPreference
            try {
                $ErrorActionPreference = 'Continue'
                & $powerShellPath @nativeArguments 1> $stdoutPath 2> $stderrPath
                $exitCode = $LASTEXITCODE
            }
            finally {
                $ErrorActionPreference = $priorErrorActionPreference
            }
        }

        $stdout = if (Test-Path -LiteralPath $stdoutPath) { [IO.File]::ReadAllText($stdoutPath) } else { '' }
        $stderr = if (Test-Path -LiteralPath $stderrPath) { [IO.File]::ReadAllText($stderrPath) } else { '' }
        if (-not [string]::IsNullOrWhiteSpace($stdout)) {
            Write-Output ("--- {0} stdout ---`n{1}" -f $testCase.Name, $stdout.TrimEnd())
        }
        if (-not [string]::IsNullOrWhiteSpace($stderr)) {
            $boundedStderr = if ($stderr.Length -le 4000) { $stderr } else { $stderr.Substring(0, 4000) }
            Write-Warning ("{0} stderr (length={1}):`n{2}" -f $testCase.Name, $stderr.Length, $boundedStderr.TrimEnd())
        }
        $results.Add([pscustomobject]@{
                Name = [string] $testCase.Name
                ExitCode = $exitCode
                StdoutLength = $stdout.Length
                StderrLength = $stderr.Length
            })
        Write-Output ("Web deployment regression result: name={0}; exitCode={1}; stdoutLength={2}; stderrLength={3}" -f `
                $testCase.Name, $exitCode, $stdout.Length, $stderr.Length)
    }
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
}

if (Test-Path -LiteralPath $temporaryDirectory) {
    throw 'Web deployment regression chain cleanup left its temporary directory behind.'
}
$failures = @($results | Where-Object { $_.ExitCode -ne 0 })
$summary = @($results | ForEach-Object { "$($_.Name)=$($_.ExitCode)" }) -join '; '
if ($failures.Count -gt 0) {
    Write-Error -ErrorAction Continue "Web deployment regression chain failed after all checks completed: $summary."
    exit 1
}
Write-Output "Web deployment regression chain passed after all checks completed: $summary."
exit 0
