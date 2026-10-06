[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$pipelinePath = Join-Path $repo 'azure-pipelines.yml'
$pipeline = Get-Content -LiteralPath $pipelinePath -Raw
$subscriptionId = '633398e2-6c00-4bb7-a576-2db0d210ee77'
$tenantId = '11111111-2222-4333-8444-555555555555'
$resourceGroup = 'Onkar.Pathre'
$webApp = 'app-mtp-web-dev-uks-001'
$apiApp = 'app-mtp-api-dev-uks-001'
$resourceQuery = '{id:id,name:name,resourceGroup:resourceGroup,type:type,defaultHostName:defaultHostName}'

function Assert-True([bool] $Condition, [string] $Message) {
    if (-not $Condition) { throw $Message }
}

function Assert-ExactArguments([object[]] $Actual, [string[]] $Expected, [string] $Message) {
    $actualStrings = @($Actual | ForEach-Object { [string] $_ })
    if (($actualStrings -join [char] 31) -cne ($Expected -join [char] 31)) {
        throw "$Message Actual: $($actualStrings -join ' | ')."
    }
}

function Get-PipelineInlineScript([string] $DisplayName) {
    $pattern = '(?ms)^          - task: AzureCLI@2\r?\n            displayName: ' +
        [regex]::Escape($DisplayName) +
        '\r?\n.*?^              inlineScript: \|\r?\n(?<script>(?:^                .*?(?:\r?\n|$))+?)' +
        '(?=^          - |\z)'
    $match = [regex]::Match($pipeline, $pattern)
    if (-not $match.Success) { throw "Could not extract the pipeline caller: $DisplayName." }
    $scriptLines = @($match.Groups['script'].Value -split '\r?\n' | ForEach-Object {
            if ($_.StartsWith('                ', [StringComparison]::Ordinal)) { $_.Substring(16) } else { $_ }
        })
    return [string]::Join([Environment]::NewLine, $scriptLines)
}

function Expand-PipelineVariables([string] $ScriptText) {
    $values = [ordered]@{
        AZDEMO_SUBSCRIPTION_ID = $subscriptionId
        AZDEMO_ENTRA_TENANT_ID = $tenantId
        AZDEMO_RESOURCE_GROUP_NAME = $resourceGroup
        AZDEMO_WEB_APP_NAME = $webApp
        AZDEMO_API_APP_NAME = $apiApp
    }
    foreach ($name in $values.Keys) {
        $ScriptText = $ScriptText.Replace(('$(' + $name + ')'), [string] $values[$name])
    }
    return $ScriptText
}

function Get-CallerRecords([string] $RecordPath, [string] $Caller) {
    return @(Get-Content -LiteralPath $RecordPath | ForEach-Object { $_ | ConvertFrom-Json } |
        Where-Object { [string]::Equals([string] $_.caller, $Caller, [StringComparison]::Ordinal) })
}

function Assert-CallerCommands([object[]] $Records, [string] $Caller) {
    Assert-True ($Records.Count -eq 5) "$Caller did not execute exactly five Azure CLI queries."
    $accountQuery = @('account', 'show', '--query', '{id:id,tenantId:tenantId}', '--output', 'json', '--only-show-errors')
    Assert-ExactArguments @($Records[0].arguments) $accountQuery "$Caller changed the exact account query."

    $expected = @(
        @('webapp', 'show', '--subscription', $subscriptionId, '--resource-group', $resourceGroup, '--name', $webApp, '--query', $resourceQuery, '--output', 'json', '--only-show-errors'),
        @('webapp', 'show', '--subscription', $subscriptionId, '--resource-group', $resourceGroup, '--name', $webApp, '--slot', 'staging', '--query', $resourceQuery, '--output', 'json', '--only-show-errors'),
        @('webapp', 'show', '--subscription', $subscriptionId, '--resource-group', $resourceGroup, '--name', $apiApp, '--query', $resourceQuery, '--output', 'json', '--only-show-errors'),
        @('webapp', 'show', '--subscription', $subscriptionId, '--resource-group', $resourceGroup, '--name', $apiApp, '--slot', 'staging', '--query', $resourceQuery, '--output', 'json', '--only-show-errors')
    )
    for ($index = 0; $index -lt $expected.Count; $index++) {
        Assert-ExactArguments @($Records[$index + 1].arguments) @($expected[$index]) "$Caller changed Azure CLI query $($index + 1)."
    }

    foreach ($record in $Records) {
        $arguments = @($record.arguments | ForEach-Object { [string] $_ })
        Assert-True (($arguments -join ' ') -notmatch '^webapp deployment slot show(?: |$)') "$Caller retained the invalid deployment slot show sequence."
    }
    foreach ($productionIndex in @(1, 3)) {
        Assert-True (-not (@($Records[$productionIndex].arguments) -ccontains '--slot')) "$Caller added --slot to a production lookup."
    }
    foreach ($slotIndex in @(2, 4)) {
        $slotArguments = @($Records[$slotIndex].arguments | ForEach-Object { [string] $_ })
        $slotArgumentIndex = [Array]::IndexOf([string[]] $slotArguments, '--slot')
        Assert-True ($slotArgumentIndex -ge 0 -and $slotArgumentIndex + 1 -lt $slotArguments.Count -and $slotArguments[$slotArgumentIndex + 1] -ceq 'staging') "$Caller did not retain the exact staging slot argument."
    }
}

$callers = [ordered]@{
    Staging = Expand-PipelineVariables (Get-PipelineInlineScript 'Resolve and validate exact staging smoke targets')
    PreSwap = Expand-PipelineVariables (Get-PipelineInlineScript 'Resolve and validate exact production smoke targets')
}
foreach ($caller in $callers.GetEnumerator()) {
    Assert-True (-not $caller.Value.Contains("@('webapp', 'deployment', 'slot', 'show'")) "$($caller.Key) pipeline source retained the invalid slot lookup."
}

$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-pipeline-target-{0}" -f [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null
$recordPath = Join-Path $temporaryDirectory 'az-records.jsonl'
$stubScriptPath = Join-Path $temporaryDirectory 'az-stub.ps1'
$warningPath = Join-Path $temporaryDirectory 'warnings.txt'
$originalPath = $env:PATH
$environmentNames = @('AZ_STUB_RECORD_PATH', 'AZ_STUB_CALLER', 'AZ_STUB_MODE', 'AZ_STUB_SUBSCRIPTION_ID', 'AZ_STUB_TENANT_ID', 'AZ_STUB_RESOURCE_GROUP', 'AZ_STUB_WEB_APP', 'AZ_STUB_API_APP')
$originalEnvironment = @{}
foreach ($name in $environmentNames) { $originalEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
$initialStderrFiles = @(
    Get-ChildItem -LiteralPath ([IO.Path]::GetTempPath()) -Filter 'az-json-*.stderr' -File -ErrorAction SilentlyContinue |
        ForEach-Object { $_.FullName }
)

$stubBody = @'
$ErrorActionPreference = 'Stop'
$cliArguments = @($args | ForEach-Object { [string] $_ })
Add-Content -LiteralPath $env:AZ_STUB_RECORD_PATH -Value ([ordered]@{ caller = $env:AZ_STUB_CALLER; arguments = $cliArguments } | ConvertTo-Json -Compress) -Encoding UTF8

function Get-ArgumentValue([string] $Name) {
    $index = [Array]::IndexOf([string[]] $cliArguments, $Name)
    if ($index -lt 0 -or $index + 1 -ge $cliArguments.Count) { return $null }
    return $cliArguments[$index + 1]
}

if (($cliArguments -join ' ') -match '^webapp deployment slot show(?: |$)') {
    [Console]::Error.WriteLine('usage error: invalid synthetic slot lookup')
    exit 41
}

if ($cliArguments.Count -ge 2 -and $cliArguments[0] -ceq 'account' -and $cliArguments[1] -ceq 'show') {
    [Console]::Error.WriteLine('SENSITIVE-STUB-STDERR success diagnostic must remain isolated')
    [ordered]@{ id = $env:AZ_STUB_SUBSCRIPTION_ID; tenantId = $env:AZ_STUB_TENANT_ID } | ConvertTo-Json -Compress
    exit 0
}

if ($cliArguments.Count -ge 2 -and $cliArguments[0] -ceq 'webapp' -and $cliArguments[1] -ceq 'show') {
    $appName = Get-ArgumentValue '--name'
    $slotName = Get-ArgumentValue '--slot'
    $isSlot = -not [string]::IsNullOrWhiteSpace($slotName)
    $resourceSuffix = if ($isSlot) { "/slots/$slotName" } else { '' }
    $resourceName = if ($isSlot) { "$appName/$slotName" } else { $appName }
    $resourceType = if ($isSlot) { 'Microsoft.Web/sites/slots' } else { 'Microsoft.Web/sites' }
    $hostSlot = if ($isSlot) { "-$slotName" } else { '' }
    $hostName = "$appName$hostSlot-csdtetbtbeh3h7fy.uksouth-01.azurewebsites.net"
    $resource = [ordered]@{
        id = "/subscriptions/$($env:AZ_STUB_SUBSCRIPTION_ID)/resourceGroups/$($env:AZ_STUB_RESOURCE_GROUP)/providers/Microsoft.Web/sites/$appName$resourceSuffix"
        name = $resourceName
        resourceGroup = $env:AZ_STUB_RESOURCE_GROUP
        type = $resourceType
        defaultHostName = $hostName
    }
    if ($env:AZ_STUB_MODE -ceq 'fail-web-slot' -and $appName -ceq $env:AZ_STUB_WEB_APP -and $slotName -ceq 'staging') {
        $resource | ConvertTo-Json -Compress
        [Console]::Error.WriteLine('AuthorizationFailed SENSITIVE-STUB-STDERR token=must-not-escape')
        exit 17
    }
    [Console]::Error.WriteLine('SENSITIVE-STUB-STDERR success diagnostic must remain isolated')
    $resource | ConvertTo-Json -Compress
    exit 0
}

[Console]::Error.WriteLine('usage error: unexpected synthetic Azure CLI operation')
exit 42
'@

try {
    Set-Content -LiteralPath $stubScriptPath -Value $stubBody -Encoding UTF8
    if ($env:OS -eq 'Windows_NT') {
        $launcherPath = Join-Path $temporaryDirectory 'az.cmd'
        $powerShellPath = (Get-Process -Id $PID).Path
        Set-Content -LiteralPath $launcherPath -Value @(
            '@echo off',
            ('"{0}" -NoLogo -NoProfile -File "{1}" %*' -f $powerShellPath, $stubScriptPath),
            'exit /b %ERRORLEVEL%'
        ) -Encoding Ascii
    }
    else {
        $launcherPath = Join-Path $temporaryDirectory 'az'
        Set-Content -LiteralPath $launcherPath -Value ("#!/usr/bin/env pwsh`n" + $stubBody) -Encoding UTF8
        & chmod '+x' $launcherPath
        if ($LASTEXITCODE -ne 0) { throw 'Could not make the synthetic Azure CLI launcher executable.' }
    }

    $env:PATH = $temporaryDirectory + [IO.Path]::PathSeparator + $originalPath
    $env:AZ_STUB_RECORD_PATH = $recordPath
    $env:AZ_STUB_SUBSCRIPTION_ID = $subscriptionId
    $env:AZ_STUB_TENANT_ID = $tenantId
    $env:AZ_STUB_RESOURCE_GROUP = $resourceGroup
    $env:AZ_STUB_WEB_APP = $webApp
    $env:AZ_STUB_API_APP = $apiApp
    Set-Location $repo

    foreach ($caller in $callers.GetEnumerator()) {
        $env:AZ_STUB_CALLER = [string] $caller.Key
        $env:AZ_STUB_MODE = 'success-with-stderr'
        $savedErrorActionPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $result = @(Invoke-Expression $caller.Value)
        }
        finally { $ErrorActionPreference = $savedErrorActionPreference }
        Assert-True (-not (($result | Out-String).Contains('SENSITIVE-STUB-STDERR'))) "$($caller.Key) exposed native stderr."
        Assert-CallerCommands (Get-CallerRecords $recordPath $caller.Key) $caller.Key
    }

    foreach ($caller in $callers.GetEnumerator()) {
        $env:AZ_STUB_CALLER = "$($caller.Key)-Failure"
        $env:AZ_STUB_MODE = 'fail-web-slot'
        $failedClosed = $false
        $failureMessage = ''
        $savedErrorActionPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            try { Invoke-Expression $caller.Value 3> $warningPath | Out-Null }
            catch {
                $failedClosed = $true
                $failureMessage = $_.Exception.Message
            }
        }
        finally { $ErrorActionPreference = $savedErrorActionPreference }
        Assert-True $failedClosed "$($caller.Key) accepted a native nonzero Azure CLI exit."
        Assert-True ($failureMessage -ceq 'Web staging slot Azure CLI query failed with a nonzero exit code.') "$($caller.Key) did not preserve the resolver's bounded nonzero failure."
        $warningText = if (Test-Path -LiteralPath $warningPath) { Get-Content -LiteralPath $warningPath -Raw } else { '' }
        Assert-True ($warningText.Contains('operation=webapp-show; exitCode=17; errorCategory=authorization.')) "$($caller.Key) omitted bounded operation, exit-code or category diagnostics."
        Assert-True (-not $warningText.Contains('SENSITIVE-STUB-STDERR')) "$($caller.Key) printed unrestricted native stderr."
        Remove-Item -LiteralPath $warningPath -Force -ErrorAction SilentlyContinue
    }

    $remainingStderrFiles = @(
        Get-ChildItem -LiteralPath ([IO.Path]::GetTempPath()) -Filter 'az-json-*.stderr' -File -ErrorAction SilentlyContinue |
            Where-Object { $initialStderrFiles -notcontains $_.FullName }
    )
    Assert-True ($remainingStderrFiles.Count -eq 0) 'An Invoke-AzJson temporary stderr file was not removed.'
}
finally {
    Set-Location $repo
    $env:PATH = $originalPath
    foreach ($name in $environmentNames) { [Environment]::SetEnvironmentVariable($name, $originalEnvironment[$name], 'Process') }
    if (Test-Path -LiteralPath $temporaryDirectory) { Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force }
}

Write-Output 'Azure demo pipeline smoke-target CLI regression passed both actual callers, exact production/slot arguments, native stream separation, bounded diagnostics and nonzero fail-closed behavior.'
