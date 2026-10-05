[CmdletBinding()]
param(
    [switch] $InternalFixture,
    [int] $FixturePort,
    [int] $FixtureStatusCode,
    [string] $FixtureLocation,
    [string] $ReadyFile,
    [switch] $AbruptClose
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

if ($InternalFixture) {
    $listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, $FixturePort)
    try {
        $listener.Start()
        [IO.File]::WriteAllText($ReadyFile, 'ready', [Text.UTF8Encoding]::new($false))
        $client = $listener.AcceptTcpClient()
        try {
            $stream = $client.GetStream()
            $reader = [IO.StreamReader]::new($stream, [Text.Encoding]::ASCII, $false, 1024, $true)
            while (($line = $reader.ReadLine()) -ne $null -and $line.Length -gt 0) { }
            if (-not $AbruptClose) {
                $reason = if ($FixtureStatusCode -in 301, 302, 303, 307, 308) { 'Redirect' } elseif ($FixtureStatusCode -eq 200) { 'OK' } else { 'Fixture' }
                $headers = "HTTP/1.1 $FixtureStatusCode $reason`r`nConnection: close`r`nContent-Length: 0`r`n"
                if (-not [string]::IsNullOrWhiteSpace($FixtureLocation)) { $headers += "Location: $FixtureLocation`r`n" }
                $payload = [Text.Encoding]::ASCII.GetBytes("$headers`r`n")
                $stream.Write($payload, 0, $payload.Length)
                $stream.Flush()
            }
        }
        finally { $client.Dispose() }
    }
    finally { $listener.Stop() }
    return
}

if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion.Major -lt 7) {
    throw 'Azure demo HTTP smoke regression requires actual PowerShell 7 or later.'
}

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repo 'scripts\smoke\AzureDemoSmokeUtilities.ps1')

function Assert-True([bool] $Condition, [string] $Message) {
    if (-not $Condition) { throw $Message }
}

function Get-FreeLoopbackPort {
    $probe = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
    try { $probe.Start(); return ([Net.IPEndPoint] $probe.LocalEndpoint).Port } finally { $probe.Stop() }
}

function Invoke-FixtureRequest([int] $StatusCode, [string] $Location, [bool] $CloseAbruptly, [string] $Query = '') {
    $port = Get-FreeLoopbackPort
    $ready = Join-Path $temporaryDirectory ("ready-{0}" -f [Guid]::NewGuid().ToString('N'))
    $arguments = @('-NoLogo', '-NoProfile', '-File', $PSCommandPath, '-InternalFixture', '-FixturePort', [string] $port, '-FixtureStatusCode', [string] $StatusCode, '-ReadyFile', $ready)
    if (-not [string]::IsNullOrWhiteSpace($Location)) { $arguments += @('-FixtureLocation', $Location) }
    if ($CloseAbruptly) { $arguments += '-AbruptClose' }
    $process = Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList $arguments -PassThru
    try {
        $deadline = [DateTimeOffset]::UtcNow.AddSeconds(10)
        while (-not (Test-Path -LiteralPath $ready) -and [DateTimeOffset]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 25 }
        Assert-True (Test-Path -LiteralPath $ready) 'Local HTTP fixture did not become ready.'
        $uri = [uri] "http://127.0.0.1:$port/fixture$Query"
        $result = Invoke-AzureDemoSmokeHttpRequest -CheckId 'SMK-01' -Uri $uri
        $process.WaitForExit(10000) | Out-Null
        Assert-True $process.HasExited 'Local HTTP fixture did not exit.'
        Assert-True ($process.ExitCode -eq 0) 'Local HTTP fixture exited unsuccessfully.'
        return [pscustomobject]@{ Uri = $uri; Result = $result }
    }
    finally {
        if (-not $process.HasExited) { $process.Kill() }
        $process.Dispose()
    }
}

$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-smoke-http-{0}" -f [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null
try {
    foreach ($statusCode in 301, 302, 307, 308) {
        $fixture = Invoke-FixtureRequest $statusCode 'https://127.0.0.1/fixture' $false
        Assert-True $fixture.Result.TransportSucceeded "PowerShell 7 did not preserve HTTP $statusCode as an HTTP response."
        Assert-True ($fixture.Result.StatusCode -eq $statusCode) "PowerShell 7 changed HTTP $statusCode."
        Assert-True (Test-AzureDemoHttpsRedirectResponse -RequestUri $fixture.Uri -RequestResult $fixture.Result) "HTTP $statusCode was not accepted as the exact HTTPS redirect."
    }

    foreach ($statusCode in 200, 500) {
        $fixture = Invoke-FixtureRequest $statusCode '' $false
        Assert-True $fixture.Result.TransportSucceeded "HTTP $statusCode was misclassified as a transport failure."
        Assert-True (-not (Test-AzureDemoHttpsRedirectResponse -RequestUri $fixture.Uri -RequestResult $fixture.Result)) "Unrelated HTTP $statusCode was accepted as an HTTPS redirect."
    }

    $wrongLocation = Invoke-FixtureRequest 302 'https://other.invalid/fixture' $false
    Assert-True (-not (Test-AzureDemoHttpsRedirectResponse -RequestUri $wrongLocation.Uri -RequestResult $wrongLocation.Result)) 'Cross-host redirect was accepted.'

    $transportFailure = Invoke-FixtureRequest 200 '' $true '?token=must-not-appear'
    Assert-True (-not $transportFailure.Result.TransportSucceeded) 'Abrupt connection close was accepted as an HTTP response.'
    $diagnosticJson = $transportFailure.Result.Diagnostic | ConvertTo-Json -Compress
    Assert-True ($diagnosticJson.Contains('"checkId":"SMK-01"')) 'Redacted diagnostic omitted the check ID.'
    Assert-True ($diagnosticJson.Contains('"scheme":"http"')) 'Redacted diagnostic omitted the scheme.'
    Assert-True ($diagnosticJson.Contains('"hostname":"127.0.0.1"')) 'Redacted diagnostic omitted the hostname.'
    Assert-True ($diagnosticJson.Contains('"path":"/fixture"')) 'Redacted diagnostic omitted the path.'
    Assert-True ($diagnosticJson.Contains('"exceptionCategory":')) 'Redacted diagnostic omitted the exception category.'
    Assert-True (-not $diagnosticJson.Contains('must-not-appear')) 'Redacted diagnostic exposed the query string.'
    Assert-True (-not $diagnosticJson.Contains('token=')) 'Redacted diagnostic exposed a token-like query name.'
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) { Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force }
}

Write-Output 'PowerShell 7 HTTP smoke regression passed MaximumRedirection 0, SkipHttpErrorCheck, redirect, unrelated-status, transport-failure and redacted-diagnostic fixtures.'
