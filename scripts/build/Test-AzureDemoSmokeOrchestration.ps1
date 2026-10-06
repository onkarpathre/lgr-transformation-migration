[CmdletBinding()]
param(
    [switch] $InternalFixture,
    [int] $FixturePort,
    [ValidateSet('success', 'client-error', 'server-error', 'transport', 'assertion')] [string] $FixtureScenario = 'success',
    [string] $ReadyFile,
    [int] $RequestCount = 16
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

if ($InternalFixture) {
    $listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, $FixturePort)
    try {
        $listener.Start()
        [IO.File]::WriteAllText($ReadyFile, 'ready', [Text.UTF8Encoding]::new($false))
        for ($requestNumber = 0; $requestNumber -lt $RequestCount; $requestNumber++) {
            $client = $listener.AcceptTcpClient()
            try {
                $stream = $client.GetStream()
                $reader = [IO.StreamReader]::new($stream, [Text.Encoding]::ASCII, $false, 4096, $true)
                $requestLine = $reader.ReadLine()
                while (($line = $reader.ReadLine()) -ne $null -and $line.Length -gt 0) { }
                $parts = @($requestLine -split ' ')
                $target = if ($parts.Count -ge 2) { $parts[1] } else { '/' }
                $targetUri = [uri] "http://127.0.0.1$target"
                $path = $targetUri.AbsolutePath
                $logicalScheme = if ($targetUri.Query -match '(?:^|[?&])logicalScheme=([^&]+)') { [uri]::UnescapeDataString($Matches[1]) } else { 'https' }

                if ($FixtureScenario -eq 'transport' -and $path -eq '/health') {
                    continue
                }

                $status = 200
                if ($path -eq '/health' -and $FixtureScenario -eq 'client-error') { $status = 404 }
                if ($path -eq '/health' -and $FixtureScenario -eq 'server-error') { $status = 503 }
                $reason = switch ($status) { 200 { 'OK' } 302 { 'Redirect' } 404 { 'Not Found' } 503 { 'Unavailable' } default { 'Fixture' } }
                $body = 'fixture'
                $headers = [ordered]@{}
                if ($logicalScheme -eq 'http') {
                    $status = 302
                    $reason = 'Redirect'
                    $body = ''
                    $headers.Location = 'https://app-mtp-web-dev-uks-001-staging.azurewebsites.net' + $path
                }
                elseif ($path -eq '/') {
                    $body = '<html><h1>Sign in required</h1><p>Restricted synthetic non-production management demo</p><script src="/_next/static/chunks/app-12345678.js"></script></html>'
                    $headers['Content-Type'] = 'text/html; charset=utf-8'
                    $headers['Strict-Transport-Security'] = 'max-age=31536000'
                    $headers['Content-Security-Policy'] = "default-src 'self'; frame-ancestors 'none'"
                    $headers['X-Content-Type-Options'] = 'nosniff'
                    $headers['Referrer-Policy'] = 'no-referrer'
                    if ($FixtureScenario -ne 'assertion') { $headers['Permissions-Policy'] = 'camera=()' }
                    $headers['X-Frame-Options'] = 'DENY'
                }
                elseif ($path -eq '/inventory/servers') {
                    $body = '<html><h1>Sign in required</h1><p>Restricted synthetic non-production management demo</p></html>'
                    $headers['Content-Type'] = 'text/html; charset=utf-8'
                }
                elseif ($path -eq '/__azure_demo_route_that_must_not_exist__') {
                    $status = 404
                    $reason = 'Not Found'
                    $body = '<html><h1>Sign in required</h1><p>Restricted synthetic non-production management demo</p></html>'
                    $headers['Content-Type'] = 'text/html; charset=utf-8'
                }
                elseif ($path -like '/_next/static/*') {
                    $body = 'asset'
                    $headers['Content-Type'] = 'application/javascript'
                    $headers['Cache-Control'] = 'public, immutable'
                }
                elseif ($path -eq '/health/live') {
                    $headers['Content-Security-Policy'] = "default-src 'none'; frame-ancestors 'none'"
                    $headers['X-Content-Type-Options'] = 'nosniff'
                    $headers['Referrer-Policy'] = 'no-referrer'
                    $headers['X-Frame-Options'] = 'DENY'
                }

                $bodyBytes = [Text.Encoding]::UTF8.GetBytes($body)
                $responseText = "HTTP/1.1 $status $reason`r`nConnection: close`r`nContent-Length: $($bodyBytes.Length)`r`n"
                foreach ($header in $headers.GetEnumerator()) { $responseText += "$($header.Key): $($header.Value)`r`n" }
                $headerBytes = [Text.Encoding]::ASCII.GetBytes("$responseText`r`n")
                $stream.Write($headerBytes, 0, $headerBytes.Length)
                if ($bodyBytes.Length -gt 0) { $stream.Write($bodyBytes, 0, $bodyBytes.Length) }
                $stream.Flush()
            }
            finally { $client.Dispose() }
        }
    }
    finally { $listener.Stop() }
    return
}

$isPowerShell7 = $PSVersionTable.PSEdition -eq 'Core' -and $PSVersionTable.PSVersion.Major -ge 7
if (-not $isPowerShell7) {
    Write-Warning 'Running supplemental orchestration fixtures only. HTTP 4xx/5xx response normalization and SMK-20 require the separately wired Linux PowerShell 7 run.'
}

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).ProviderPath
$runner = Join-Path $repo 'scripts\smoke\Invoke-AzureDemoSmokeTests.ps1'
$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-smoke-orchestration-{0}" -f [Guid]::NewGuid().ToString('N'))
$utf8NoBom = [Text.UTF8Encoding]::new($false)
New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null

function Assert-True([bool] $Condition, [string] $Message) {
    if (-not $Condition) { throw $Message }
}

function Get-FreeLoopbackPort {
    $probe = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
    try { $probe.Start(); return ([Net.IPEndPoint] $probe.LocalEndpoint).Port } finally { $probe.Stop() }
}

function Get-Result([object[]] $Results, [string] $Id) {
    $matches = @($Results | Where-Object { $_.id -ceq $Id })
    Assert-True ($matches.Count -eq 1) "Expected exactly one $Id result."
    return $matches[0]
}

function Invoke-OrchestrationScenario([string] $Scenario, [bool] $RejectedEvidence) {
    $scenarioRoot = Join-Path $temporaryDirectory ("{0}-{1}" -f $Scenario, [Guid]::NewGuid().ToString('N'))
    $evidenceDirectory = Join-Path $scenarioRoot 'results'
    $protectedDirectory = Join-Path $scenarioRoot 'protected'
    New-Item -ItemType Directory -Path $evidenceDirectory -Force | Out-Null
    if ($RejectedEvidence) {
        New-Item -ItemType Directory -Path $protectedDirectory -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $protectedDirectory 'SMK-01.json'), '{}', $utf8NoBom)
    }
    $manifestPath = Join-Path $scenarioRoot 'deployment-artifact-manifest.json'
    $sourceCommit = '1111111111111111111111111111111111111111'
    [IO.File]::WriteAllText($manifestPath, '{"schemaVersion":"1","sourceCommit":"1111111111111111111111111111111111111111","artifacts":[]}', $utf8NoBom)

    $port = Get-FreeLoopbackPort
    $readyFile = Join-Path $scenarioRoot 'fixture.ready'
    $arguments = @('-NoLogo', '-NoProfile', '-File', $PSCommandPath, '-InternalFixture', '-FixturePort', [string] $port, '-FixtureScenario', $Scenario, '-ReadyFile', $readyFile, '-RequestCount', '16')
    $fixtureProcess = Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList $arguments -PassThru
    try {
        $deadline = [DateTimeOffset]::UtcNow.AddSeconds(10)
        while (-not (Test-Path -LiteralPath $readyFile) -and -not $fixtureProcess.HasExited -and [DateTimeOffset]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 25 }
        Assert-True (-not $fixtureProcess.HasExited) "The $Scenario fixture exited before readiness."
        Assert-True (Test-Path -LiteralPath $readyFile) "The $Scenario fixture did not become ready."

        $global:AzureDemoSmokeFixturePort = $port
        function global:Invoke-WebRequest {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory)] [uri] $Uri,
                [string] $Method = 'GET',
                [hashtable] $Headers = @{},
                [int] $MaximumRedirection = 5,
                [switch] $SkipHttpErrorCheck,
                [int] $TimeoutSec = 30
            )
            $localBuilder = [UriBuilder]::new('http', '127.0.0.1', $global:AzureDemoSmokeFixturePort, $Uri.AbsolutePath)
            $localBuilder.Query = 'logicalScheme=' + [uri]::EscapeDataString($Uri.Scheme)
            $parameters = @{
                Uri = $localBuilder.Uri
                Method = $Method
                Headers = $Headers
                MaximumRedirection = $MaximumRedirection
                TimeoutSec = $TimeoutSec
                ErrorAction = $ErrorActionPreference
            }
            if ($SkipHttpErrorCheck -and
                (Get-Command Microsoft.PowerShell.Utility\Invoke-WebRequest).Parameters.ContainsKey('SkipHttpErrorCheck')) {
                $parameters.SkipHttpErrorCheck = $true
            }
            if ((Get-Command Microsoft.PowerShell.Utility\Invoke-WebRequest).Parameters.ContainsKey('UseBasicParsing')) {
                $parameters.UseBasicParsing = $true
            }
            Microsoft.PowerShell.Utility\Invoke-WebRequest @parameters
        }

        $runnerFailed = $false
        try {
            $parameters = @{
                EvidenceDirectory = $evidenceDirectory
                WebBaseUri = 'https://app-mtp-web-dev-uks-001-staging.azurewebsites.net'
                VerifiedWebHost = 'app-mtp-web-dev-uks-001-staging.azurewebsites.net'
                VerifiedApiHost = 'app-mtp-api-dev-uks-001-staging.azurewebsites.net'
                TargetSubscriptionId = '633398e2-6c00-4bb7-a576-2db0d210ee77'
                TargetResourceGroupName = 'Onkar.Pathre'
                TargetWebAppName = 'app-mtp-web-dev-uks-001'
                TargetApiAppName = 'app-mtp-api-dev-uks-001'
                TargetSlotName = 'staging'
                ExpectedCommit = $sourceCommit
                ArtifactManifest = $manifestPath
                InfrastructureDeploymentId = '/subscriptions/633398e2-6c00-4bb7-a576-2db0d210ee77/resourceGroups/Onkar.Pathre/providers/Microsoft.Resources/deployments/local-fixture'
                PipelineDefinition = 'local-fixture'
                PipelineRunId = "orchestration-$Scenario"
                Execute = $true
            }
            if ($RejectedEvidence) { $parameters.ProtectedEvidenceDirectory = $protectedDirectory }
            & $runner @parameters 6>$null | Out-Null
        }
        catch { $runnerFailed = $true }
        finally {
            Remove-Item Function:\global:Invoke-WebRequest -ErrorAction SilentlyContinue
            Remove-Variable -Name AzureDemoSmokeFixturePort -Scope Global -ErrorAction SilentlyContinue
        }

        Assert-True $runnerFailed "The $Scenario run unexpectedly passed despite mandatory protected evidence being absent or rejected."
        $summaryPath = Join-Path $evidenceDirectory 'smoke-summary.json'
        Assert-True (Test-Path -LiteralPath $summaryPath -PathType Leaf) "The $Scenario run did not publish its summary before failing."
        $parsedSummary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
        $results = if ($parsedSummary -is [Collections.IEnumerable] -and $parsedSummary -isnot [string]) {
            @($parsedSummary | ForEach-Object { $_ })
        }
        else { @($parsedSummary) }
        Assert-True ($results.Count -eq 22) "The $Scenario run retained $($results.Count) results instead of 22."
        foreach ($id in 1..22 | ForEach-Object { 'SMK-{0:D2}' -f $_ }) {
            Assert-True (Test-Path -LiteralPath (Join-Path $evidenceDirectory "$id.json") -PathType Leaf) "$Scenario omitted $id evidence."
        }
        return [pscustomobject]@{ Results = $results; EvidenceDirectory = $evidenceDirectory }
    }
    finally {
        Remove-Item Function:\global:Invoke-WebRequest -ErrorAction SilentlyContinue
        Remove-Variable -Name AzureDemoSmokeFixturePort -Scope Global -ErrorAction SilentlyContinue
        if (-not $fixtureProcess.HasExited) {
            $fixtureProcess.Kill()
            [void] $fixtureProcess.WaitForExit(5000)
        }
        $fixtureProcess.Dispose()
    }
}

try {
    $success = Invoke-OrchestrationScenario -Scenario 'success' -RejectedEvidence $false
    $successfulAutomatedChecks = @('SMK-03', 'SMK-10', 'SMK-11')
    if ($isPowerShell7) { $successfulAutomatedChecks += @('SMK-02', 'SMK-20') }
    foreach ($id in $successfulAutomatedChecks) {
        $successfulResult = Get-Result $success.Results $id
        Assert-True ($successfulResult.status -ceq 'PASS') "$id did not pass the successful local orchestration fixture: $($successfulResult | ConvertTo-Json -Depth 7 -Compress)"
    }
    if (-not $isPowerShell7) {
        Assert-True ((Get-Result $success.Results 'SMK-20').failureCategories -ccontains 'harness-exception') 'Supplemental Windows execution did not retain SMK-20 as a PowerShell 7 runtime requirement.'
        Assert-True ((Get-Result $success.Results 'SMK-02').failureCategories -ccontains 'transport-failure') 'Supplemental Windows execution did not retain its known inability to normalize the required HTTP 404 route check.'
    }
    $redirect = Get-Result $success.Results 'SMK-01'
    Assert-True ($redirect.status -ceq 'FAIL') 'SMK-01 passed without mandatory lower-TLS evidence.'
    Assert-True ($redirect.failureCategories -ccontains 'missing-evidence') 'SMK-01 did not distinguish missing evidence.'
    $redirectHttp = @($redirect.diagnostics | Where-Object { $_.executionPhase -ceq 'http-request' })
    Assert-True ($redirectHttp.Count -eq 1 -and $redirectHttp[0].scheme -ceq 'http' -and $redirectHttp[0].httpStatus -eq 302) 'SMK-01 did not retain the actual HTTP redirect request and response.'
    $unexpectedHarnessFailures = @($success.Results | Where-Object {
            $_.failureCategories -ccontains 'harness-exception' -and ($isPowerShell7 -or $_.id -cne 'SMK-20')
        })
    Assert-True ($unexpectedHarnessFailures.Count -eq 0) 'Successful HTTP fixtures produced an unexpected harness exception.'

    if ($isPowerShell7) {
        $clientError = Invoke-OrchestrationScenario -Scenario 'client-error' -RejectedEvidence $false
        $clientHealth = Get-Result $clientError.Results 'SMK-02'
        Assert-True ($clientHealth.failureCategories -ccontains 'application-response-failure') 'HTTP 404 was not retained as an application response failure.'
        Assert-True (@($clientHealth.diagnostics | Where-Object { $_.httpStatus -eq 404 }).Count -gt 0) 'HTTP 404 status was lost.'

        $serverError = Invoke-OrchestrationScenario -Scenario 'server-error' -RejectedEvidence $false
        $serverHealth = Get-Result $serverError.Results 'SMK-02'
        Assert-True ($serverHealth.failureCategories -ccontains 'application-response-failure') 'HTTP 503 was not retained as an application response failure.'
        Assert-True (@($serverHealth.diagnostics | Where-Object { $_.httpStatus -eq 503 }).Count -gt 0) 'HTTP 503 status was lost.'
    }

    $transport = Invoke-OrchestrationScenario -Scenario 'transport' -RejectedEvidence $false
    Assert-True ((Get-Result $transport.Results 'SMK-02').failureCategories -ccontains 'transport-failure') 'Abrupt close was not classified as a transport failure.'
    Assert-True ((Get-Result $transport.Results 'SMK-22').status -ceq 'FAIL') 'Result collection stopped before SMK-22 after a transport failure.'

    $assertion = Invoke-OrchestrationScenario -Scenario 'assertion' -RejectedEvidence $false
    $headerResult = Get-Result $assertion.Results 'SMK-11'
    Assert-True ($headerResult.failureCategories -ccontains 'assertion-failure') 'A valid HTTP 200 with a missing required header was not classified as an assertion failure.'
    Assert-True (@($headerResult.diagnostics | Where-Object { $_.httpStatus -eq 200 }).Count -eq 2) 'Assertion failure did not preserve both HTTP 200 results.'

    $rejected = Invoke-OrchestrationScenario -Scenario 'success' -RejectedEvidence $true
    Assert-True ((Get-Result $rejected.Results 'SMK-01').failureCategories -ccontains 'rejected-evidence') 'Rejected evidence was not distinguished from missing evidence.'

    $serializedEvidence = Get-Content -LiteralPath (Join-Path $success.EvidenceDirectory 'smoke-summary.json') -Raw
    foreach ($forbidden in @('must-not-be-trusted', 'PlatformAdministrator', 'Authorization', 'Cookie', 'token=')) {
        Assert-True (-not $serializedEvidence.Contains($forbidden)) "Serialized orchestration evidence disclosed $forbidden."
    }

    $statusCoverage = if ($isPowerShell7) { '4xx, 5xx, ' } else { '' }
    Write-Output "PowerShell $($PSVersionTable.PSVersion) smoke orchestration regression passed redirect, successful response, ${statusCoverage}transport, assertion, evidence, continuation, redaction and publication fixtures."
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) { Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force }
}
