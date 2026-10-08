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

function Invoke-FixtureRequest(
    [int] $StatusCode,
    [string] $Location,
    [bool] $CloseAbruptly,
    [string] $Query = '',
    [bool] $FailAfterReady = $false
) {
    $port = Get-FreeLoopbackPort
    $ready = Join-Path $temporaryDirectory ("ready-{0}" -f [Guid]::NewGuid().ToString('N'))
    $arguments = @('-NoLogo', '-NoProfile', '-File', $PSCommandPath, '-InternalFixture', '-FixturePort', [string] $port, '-FixtureStatusCode', [string] $StatusCode, '-ReadyFile', $ready)
    if (-not [string]::IsNullOrWhiteSpace($Location)) { $arguments += @('-FixtureLocation', $Location) }
    if ($CloseAbruptly) { $arguments += '-AbruptClose' }
    $process = Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList $arguments -PassThru
    try {
        $deadline = [DateTimeOffset]::UtcNow.AddSeconds(10)
        while (-not (Test-Path -LiteralPath $ready) -and -not $process.HasExited -and [DateTimeOffset]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 25 }
        if ($process.HasExited) { throw "Local HTTP fixture exited before readiness with code $($process.ExitCode)." }
        Assert-True (Test-Path -LiteralPath $ready) 'Local HTTP fixture did not become ready.'
        if ($FailAfterReady) { throw 'Synthetic local HTTP fixture cleanup failure.' }
        $uri = [uri] "http://127.0.0.1:$port/fixture$Query"
        $requestHeaders = if ($CloseAbruptly) { @{ Authorization = 'Bearer must-not-appear'; Cookie = 'session=must-not-appear' } } else { @{} }
        $result = Invoke-AzureDemoSmokeHttpRequest -CheckId 'SMK-01' -Uri $uri -Headers $requestHeaders
        Assert-True ($process.WaitForExit(10000)) 'Local HTTP fixture did not exit.'
        Assert-True ($process.ExitCode -eq 0) 'Local HTTP fixture exited unsuccessfully.'
        return [pscustomobject]@{ Uri = $uri; Result = $result }
    }
    finally {
        $fixtureTerminated = $true
        if (-not $process.HasExited) {
            $process.Kill()
            $fixtureTerminated = $process.WaitForExit(5000)
        }
        $process.Dispose()
        if (Test-Path -LiteralPath $ready) { Remove-Item -LiteralPath $ready -Force }
        Assert-True $fixtureTerminated 'Local HTTP fixture could not be terminated during cleanup.'
    }
}

function Format-SafeFixtureDiagnostic([object] $Fixture) {
    $diagnostic = $Fixture.Result.Diagnostic
    return 'runtime={0}; returnedType={1}; responseType={2}; transportSucceeded={3}; status={4}; errorVariableType={5}; errorObjects={6}; exceptionType={7}; exceptionCategory={8}' -f
        $diagnostic.runtimeVersion,
        $Fixture.Result.GetType().FullName,
        $diagnostic.resultType,
        $Fixture.Result.TransportSucceeded,
        $(if ($null -eq $Fixture.Result.StatusCode) { 'none' } else { $Fixture.Result.StatusCode }),
        $diagnostic.errorVariableType,
        $diagnostic.errorObjects,
        $diagnostic.exceptionType,
        $diagnostic.exceptionCategory
}

function Invoke-TerminatingErrorCaptureFixture {
    [CmdletBinding()]
    param()

    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
        [InvalidOperationException]::new('redacted-fixture-error'),
        'SyntheticTerminatingError',
        [System.Management.Automation.ErrorCategory]::InvalidOperation,
        $null)
    $PSCmdlet.ThrowTerminatingError($errorRecord)
}

function Assert-ErrorObjectClassification {
    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
        [InvalidOperationException]::new('redacted-fixture-error'),
        'SyntheticErrorRecord',
        [System.Management.Automation.ErrorCategory]::InvalidOperation,
        $null)
    $errorRecordClassification = Get-AzureDemoSmokeErrorObjectClassification -InputObject $errorRecord -Origin 'error-variable'
    Assert-True ($errorRecordClassification.Kind -eq 'error-record') 'A real ErrorRecord was not classified as an ErrorRecord.'
    Assert-True ($errorRecordClassification.FullyQualifiedErrorId -eq 'SyntheticErrorRecord') 'A real ErrorRecord lost its error identity.'

    $exception = [InvalidOperationException]::new('redacted-fixture-error')
    $exceptionClassification = Get-AzureDemoSmokeErrorObjectClassification -InputObject $exception -Origin 'error-variable'
    Assert-True ($exceptionClassification.Kind -eq 'exception') 'A real Exception was not classified as an Exception.'
    Assert-True ($null -eq $exceptionClassification.ErrorRecord) 'A raw Exception was assigned an ErrorRecord it did not contain.'

    $nullClassification = Get-AzureDemoSmokeErrorObjectClassification -InputObject $null -Origin 'error-variable'
    Assert-True ($nullClassification.Kind -eq 'null') 'A null error object was not classified explicitly.'

    $unexpectedObject = [pscustomobject]@{ Shape = 'synthetic-unexpected' }
    $unexpectedClassification = Get-AzureDemoSmokeErrorObjectClassification -InputObject $unexpectedObject -Origin 'error-variable'
    Assert-True ($unexpectedClassification.Kind -eq 'unexpected') 'An unexpected error object was not classified explicitly.'

    $capturedErrors = @()
    $caughtError = $null
    try {
        Invoke-TerminatingErrorCaptureFixture -ErrorAction SilentlyContinue -ErrorVariable capturedErrors
    }
    catch {
        $caughtError = $_
    }

    $capturedItems = @($capturedErrors)
    Assert-True ($capturedItems.Count -eq 1) 'The terminating ErrorVariable fixture did not capture exactly one object.'
    Assert-True ($capturedItems[0] -is [Exception]) 'The terminating ErrorVariable fixture did not capture an Exception object.'
    Assert-True ($caughtError -is [System.Management.Automation.ErrorRecord]) 'The terminating fixture catch path did not receive an ErrorRecord.'
    $capturedClassification = Get-AzureDemoSmokeErrorObjectClassification -InputObject $capturedItems[0] -Origin 'error-variable'
    Assert-True ($capturedClassification.Kind -eq 'exception') 'The terminating ErrorVariable object was not classified as an Exception.'
    Assert-True ($capturedClassification.ErrorRecord -is [System.Management.Automation.ErrorRecord]) 'The terminating ErrorVariable exception did not retain its embedded ErrorRecord.'

    $fixtureUri = [uri] 'http://127.0.0.1/fixture'
    $syntheticResponse = [pscustomobject]@{ StatusCode = 200; Headers = @{}; Content = ''; RawContentLength = 0L }
    $unexpectedErrors = [Collections.ArrayList]::new()
    [void] $unexpectedErrors.Add($unexpectedObject)
    $unexpectedResult = Resolve-AzureDemoSmokeHttpResult -CheckId 'SMK-01' -Uri $fixtureUri `
        -PipelineOutput @($syntheticResponse) -CapturedErrors $unexpectedErrors -TerminatingError $null
    Assert-True (-not $unexpectedResult.TransportSucceeded) 'An unexpected captured error object was treated as success.'
    Assert-True ($unexpectedResult.Diagnostic.exceptionCategory -eq 'unexpected-error-object') 'An unexpected captured error object lost its failure category.'

    $nestedErrors = [Collections.ArrayList]::new()
    [void] $nestedErrors.Add([Collections.ArrayList]::new())
    $nestedResult = Resolve-AzureDemoSmokeHttpResult -CheckId 'SMK-01' -Uri $fixtureUri `
        -PipelineOutput @($syntheticResponse) -CapturedErrors $nestedErrors -TerminatingError $null
    Assert-True (-not $nestedResult.TransportSucceeded) 'A nested captured collection was treated as success.'
    Assert-True ($nestedResult.Diagnostic.exceptionCategory -eq 'unexpected-error-object') 'A nested captured collection lost its failure category.'

    $nullErrors = [Collections.ArrayList]::new()
    [void] $nullErrors.Add($null)
    $nullResult = Resolve-AzureDemoSmokeHttpResult -CheckId 'SMK-01' -Uri $fixtureUri `
        -PipelineOutput @($syntheticResponse) -CapturedErrors $nullErrors -TerminatingError $null
    Assert-True (-not $nullResult.TransportSucceeded) 'A null captured error object was treated as success.'
    Assert-True ($nullResult.Diagnostic.exceptionCategory -eq 'null-error-object') 'A null captured error object lost its failure category.'

    $invalidStatusResult = Resolve-AzureDemoSmokeHttpResult -CheckId 'SMK-01' -Uri $fixtureUri `
        -PipelineOutput @([pscustomobject]@{ StatusCode = 'not-a-status'; Headers = @{}; Content = ''; RawContentLength = 0L }) `
        -CapturedErrors ([Collections.ArrayList]::new()) -TerminatingError $null
    Assert-True (-not $invalidStatusResult.TransportSucceeded) 'A response with an invalid status shape was treated as success.'
    Assert-True ($invalidStatusResult.Diagnostic.exceptionCategory -eq 'unexpected-output') 'An invalid response status shape lost its failure category.'

    $httpFailureException = [InvalidOperationException]::new('redacted-fixture-error')
    $httpFailureResponse = [pscustomobject]@{ StatusCode = 500; Headers = @{} }
    $httpFailureException | Add-Member -NotePropertyName Response -NotePropertyValue $httpFailureResponse
    $httpFailureRecord = [System.Management.Automation.ErrorRecord]::new(
        $httpFailureException,
        'SyntheticHttpFailure',
        [System.Management.Automation.ErrorCategory]::InvalidOperation,
        $null)
    $httpFailureErrors = [Collections.ArrayList]::new()
    [void] $httpFailureErrors.Add($httpFailureRecord)
    $httpFailureResult = Resolve-AzureDemoSmokeHttpResult -CheckId 'SMK-01' -Uri $fixtureUri `
        -PipelineOutput @() -CapturedErrors $httpFailureErrors -TerminatingError $null
    Assert-True (-not $httpFailureResult.TransportSucceeded) 'An exception-carried HTTP 500 response was treated as transport success.'
    Assert-True ($httpFailureResult.StatusCode -eq 500) 'An exception-carried HTTP 500 response lost its status.'

    $redirectException = [InvalidOperationException]::new('redacted-fixture-error')
    $redirectExceptionResponse = [pscustomobject]@{ StatusCode = 302; Headers = @{ Location = 'https://127.0.0.1/fixture' } }
    $redirectException | Add-Member -NotePropertyName Response -NotePropertyValue $redirectExceptionResponse
    $wrongIdentityRecord = [System.Management.Automation.ErrorRecord]::new(
        $redirectException,
        'MaximumRedirectExceeded',
        [System.Management.Automation.ErrorCategory]::InvalidOperation,
        $null)
    $wrongIdentityErrors = [Collections.ArrayList]::new()
    [void] $wrongIdentityErrors.Add($wrongIdentityRecord)
    $wrongIdentityResult = Resolve-AzureDemoSmokeHttpResult -CheckId 'SMK-01' -Uri $fixtureUri `
        -PipelineOutput @() -CapturedErrors $wrongIdentityErrors -TerminatingError $null
    Assert-True (-not $wrongIdentityResult.TransportSucceeded) 'A redirect response with the wrong full error identity was accepted.'
    Assert-True ($wrongIdentityResult.StatusCode -eq 302) 'A rejected exception-carried redirect lost its observed HTTP status.'

    $terminatingResult = Resolve-AzureDemoSmokeHttpResult -CheckId 'SMK-01' -Uri $fixtureUri `
        -PipelineOutput @() -CapturedErrors $capturedErrors -TerminatingError $caughtError
    Assert-True (-not $terminatingResult.TransportSucceeded) 'A terminating request error was treated as success.'
    Assert-True ($terminatingResult.Diagnostic.errorObjects.Contains('error-variable:exception:')) 'The ErrorVariable exception origin was omitted from safe diagnostics.'
    Assert-True ($terminatingResult.Diagnostic.errorObjects.Contains('catch:error-record:')) 'The catch ErrorRecord origin was omitted from safe diagnostics.'

    Write-Output ('Terminating ErrorVariable fixture: outerType={0}; itemTypes={1}; catchType={2}; resultCategory={3}' -f
        (Get-AzureDemoSmokeSafeTypeName -InputObject $capturedErrors),
        (($capturedItems | ForEach-Object { Get-AzureDemoSmokeSafeTypeName -InputObject $_ }) -join ','),
        (Get-AzureDemoSmokeSafeTypeName -InputObject $caughtError),
        $terminatingResult.Diagnostic.exceptionCategory)
}

Assert-ErrorObjectClassification

$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-smoke-http-{0}" -f [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null
try {
    foreach ($statusCode in 301, 302, 307, 308) {
        $fixture = Invoke-FixtureRequest $statusCode 'https://127.0.0.1/fixture' $false
        $safeDiagnostic = Format-SafeFixtureDiagnostic $fixture
        Write-Output "HTTP $statusCode fixture: $safeDiagnostic"
        Assert-True $fixture.Result.TransportSucceeded "PowerShell 7 did not preserve HTTP $statusCode as an HTTP response. $safeDiagnostic"
        Assert-True ($fixture.Result.StatusCode -eq $statusCode) "PowerShell 7 changed HTTP $statusCode. $safeDiagnostic"
        Assert-True (Test-AzureDemoHttpsRedirectResponse -RequestUri $fixture.Uri -RequestResult $fixture.Result) "HTTP $statusCode was not accepted as the exact HTTPS redirect. $safeDiagnostic"
    }

    foreach ($statusCode in 200, 500) {
        $fixture = Invoke-FixtureRequest $statusCode '' $false
        $safeDiagnostic = Format-SafeFixtureDiagnostic $fixture
        Write-Output "HTTP $statusCode fixture: $safeDiagnostic"
        Assert-True $fixture.Result.TransportSucceeded "HTTP $statusCode was misclassified as a transport failure. $safeDiagnostic"
        Assert-True (-not (Test-AzureDemoHttpsRedirectResponse -RequestUri $fixture.Uri -RequestResult $fixture.Result)) "Unrelated HTTP $statusCode was accepted as an HTTPS redirect. $safeDiagnostic"
    }

    $wrongLocation = Invoke-FixtureRequest 302 'https://other.invalid/fixture' $false
    Assert-True (-not (Test-AzureDemoHttpsRedirectResponse -RequestUri $wrongLocation.Uri -RequestResult $wrongLocation.Result)) 'Cross-host redirect was accepted.'

    $transportFailure = Invoke-FixtureRequest 200 '' $true '?token=must-not-appear'
    $transportDiagnostic = Format-SafeFixtureDiagnostic $transportFailure
    Write-Output "Abrupt-close fixture: $transportDiagnostic"
    Assert-True (-not $transportFailure.Result.TransportSucceeded) "Abrupt connection close was accepted as an HTTP response. $transportDiagnostic"
    $diagnosticJson = $transportFailure.Result.Diagnostic | ConvertTo-Json -Compress
    Assert-True ($diagnosticJson.Contains('"checkId":"SMK-01"')) 'Redacted diagnostic omitted the check ID.'
    Assert-True ($diagnosticJson.Contains('"executionPhase":"http-request"')) 'Redacted diagnostic omitted the execution phase.'
    Assert-True ($diagnosticJson.Contains('"scheme":"http"')) 'Redacted diagnostic omitted the scheme.'
    Assert-True ($diagnosticJson.Contains('"hostname":"127.0.0.1"')) 'Redacted diagnostic omitted the hostname.'
    Assert-True ($diagnosticJson.Contains('"path":"/fixture"')) 'Redacted diagnostic omitted the path.'
    Assert-True ($diagnosticJson.Contains('"exceptionCategory":')) 'Redacted diagnostic omitted the exception category.'
    Assert-True ($diagnosticJson.Contains('"exceptionType":')) 'Redacted diagnostic omitted the exception type.'
    Assert-True ($diagnosticJson.Contains('"errorIdentifier":')) 'Redacted diagnostic omitted the sanitized error identifier.'
    Assert-True (-not $diagnosticJson.Contains('must-not-appear')) 'Redacted diagnostic exposed the query string.'
    Assert-True (-not $diagnosticJson.Contains('token=')) 'Redacted diagnostic exposed a token-like query name.'
    Assert-True (-not $diagnosticJson.Contains('Authorization')) 'Redacted diagnostic exposed an authorization header name.'
    Assert-True (-not $diagnosticJson.Contains('Cookie')) 'Redacted diagnostic exposed a cookie header name.'
    Assert-True (-not $transportDiagnostic.Contains('must-not-appear')) 'Safe fixture diagnostic exposed a sensitive value.'

    $arrayHeaders = [pscustomobject]@{ Headers = @{ 'Content-Type' = [string[]] @('application/json') } }
    Assert-True ((Get-AzureDemoSmokeHeaderValue -Response $arrayHeaders -Name 'content-type') -ceq 'application/json') 'Case-insensitive array-valued headers were not normalized safely.'

    $unsafeError = [System.Management.Automation.ErrorRecord]::new(
        [InvalidOperationException]::new('token=must-not-appear'),
        'unsafe identifier with spaces and token=must-not-appear',
        [System.Management.Automation.ErrorCategory]::InvalidOperation,
        $null)
    Assert-True ((Get-AzureDemoSmokeSafeErrorIdentifier -ErrorObject $unsafeError) -ceq 'unavailable') 'An unsafe error identifier was not suppressed.'

    $cleanupFailureObserved = $false
    try {
        Invoke-FixtureRequest 200 '' $false '' $true | Out-Null
    }
    catch {
        $cleanupFailureObserved = $true
    }
    Assert-True $cleanupFailureObserved 'The synthetic fixture failure did not occur.'
    Assert-True (@(Get-ChildItem -LiteralPath $temporaryDirectory -Force).Count -eq 0) 'Fixture readiness files were not cleaned after successful and failed execution.'
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) { Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force }
}

Assert-True (-not (Test-Path -LiteralPath $temporaryDirectory)) 'The HTTP fixture temporary directory was not cleaned.'

Write-Output 'PowerShell 7 HTTP smoke regression passed MaximumRedirection 0, SkipHttpErrorCheck, redirect, unrelated-status, transport-failure, error-object-shape, redacted-diagnostic and cleanup fixtures.'
