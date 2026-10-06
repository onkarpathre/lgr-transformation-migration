[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).ProviderPath
. (Join-Path $repo 'scripts\build\AzureDemoPackageUtilities.ps1')
. (Join-Path $repo 'scripts\build\AzureDemoDeploymentArtifactUtilities.ps1')
$deploymentScript = Join-Path $repo 'scripts\deployment\Invoke-AzureDemoCleanWebSlotDeployment.ps1'
$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-clean-deploy-$([Guid]::NewGuid().ToString('N'))")
$artifactRoot = Join-Path $temporaryDirectory 'artifact'
$applicationRoot = Join-Path $artifactRoot 'application'
$stageRoot = Join-Path $temporaryDirectory 'stage'
$sourceCommit = '1111111111111111111111111111111111111111'
$recordPath = Join-Path $temporaryDirectory 'az-records.jsonl'
$originalPath = $env:PATH
$originalRecordPath = $env:AZ_STUB_RECORD_PATH
$originalMode = $env:AZ_STUB_MODE
$successMessage = $null

function New-TextFile([string] $Root, [string] $RelativePath, [string] $Content) {
    $path = Join-Path $Root $RelativePath
    New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
    [IO.File]::WriteAllText($path, $Content, [Text.UTF8Encoding]::new($false))
}

try {
    New-Item -ItemType Directory -Path $applicationRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null
    New-TextFile $stageRoot 'server.js' 'server-entry'
    New-TextFile $stageRoot '.next/BUILD_ID' 'BUILD00000000001'
    New-TextFile $stageRoot '.next/server/app/page.js' 'page-entry'
    New-TextFile $stageRoot '.next/server/chunks/ssr/[root-of-the-server]__fixture._.js' 'chunk-entry'
    New-TextFile $stageRoot '.next/static/chunks/app-12345678.js' 'static-entry'
    New-TextFile $stageRoot 'node_modules/next/index.js' 'dependency-entry'
    $webZip = Join-Path $applicationRoot 'web.zip'
    New-AzureDemoDeterministicZip -SourceDirectory $stageRoot -DestinationPath $webZip
    $apiZip = Join-Path $applicationRoot 'api.zip'
    New-AzureDemoDeterministicZip -SourceDirectory $stageRoot -DestinationPath $apiZip
    [ordered]@{
        schemaVersion = '1'
        sourceCommit = $sourceCommit
        createdAtUtc = [DateTimeOffset]::UtcNow.ToString('O')
        nodeVersion = 'v24.0.0'
        dotnetSdkVersion = '10.0.100'
        artifacts = @(
            [ordered]@{ name = 'api.zip'; sha256 = (Get-FileHash $apiZip -Algorithm SHA256).Hash.ToLowerInvariant() },
            [ordered]@{ name = 'web.zip'; sha256 = (Get-FileHash $webZip -Algorithm SHA256).Hash.ToLowerInvariant() }
        )
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $applicationRoot 'application-artifact-manifest.json') -Encoding UTF8
    $deploymentManifest = New-AzureDemoDeploymentArtifactManifest -ArtifactRoot $artifactRoot -SourceCommit $sourceCommit

    $stubScript = Join-Path $temporaryDirectory 'az-stub.ps1'
    $stubBody = @'
$arguments = @($args | ForEach-Object { [string] $_ })
Add-Content -LiteralPath $env:AZ_STUB_RECORD_PATH -Value ([ordered]@{ arguments = $arguments } | ConvertTo-Json -Compress) -Encoding UTF8
$command = $arguments -join ' '
if ($command -ceq 'version --output json') { '{"azure-cli":"2.80.0"}'; exit 0 }
if ($command -ceq 'webapp deploy --help') { '--subscription --resource-group --name --slot --src-path --type --clean --async --restart --track-status --timeout'; exit 0 }
if ($command -match '^account show ') { '{"id":"633398e2-6c00-4bb7-a576-2db0d210ee77"}'; exit 0 }
if ($command -match '^webapp show ') {
  '{"id":"/subscriptions/633398e2-6c00-4bb7-a576-2db0d210ee77/resourceGroups/Onkar.Pathre/providers/Microsoft.Web/sites/app-mtp-web-dev-uks-001/slots/staging","name":"app-mtp-web-dev-uks-001/staging","resourceGroup":"Onkar.Pathre","type":"Microsoft.Web/sites/slots","defaultHostName":"app-mtp-web-dev-uks-001-staging-csdtetbtbeh3h7fy.uksouth-01.azurewebsites.net","enabledHostNames":["app-mtp-web-dev-uks-001-staging-csdtetbtbeh3h7fy.scm.uksouth-01.azurewebsites.net"]}'
  exit 0
}
if ($command -match '^webapp config appsettings list ') { '[{"name":"SCM_DO_BUILD_DURING_DEPLOYMENT","value":"false"}]'; exit 0 }
if ($command -match '^webapp deploy ') {
  if ($env:AZ_STUB_MODE -ceq 'deploy-failure') { [Console]::Error.WriteLine('synthetic deployment failure'); exit 17 }
  '{"id":"deployment-fixture","status":4,"complete":true}'
  exit 0
}
[Console]::Error.WriteLine('unexpected Azure CLI invocation')
exit 42
'@
    [IO.File]::WriteAllText($stubScript, $stubBody, [Text.UTF8Encoding]::new($false))
    if ($env:OS -eq 'Windows_NT') {
        $launcher = Join-Path $temporaryDirectory 'az.cmd'
        [IO.File]::WriteAllLines($launcher, @(
                '@echo off',
                ('"{0}" -NoLogo -NoProfile -File "{1}" %*' -f (Get-Process -Id $PID).Path, $stubScript),
                'exit /b %ERRORLEVEL%'), [Text.Encoding]::ASCII)
    }
    else {
        $launcher = Join-Path $temporaryDirectory 'az'
        [IO.File]::WriteAllText($launcher, "#!/usr/bin/env pwsh`n$stubBody", [Text.UTF8Encoding]::new($false))
        & chmod '+x' $launcher
        $chmodExitCode = $LASTEXITCODE
        if ($chmodExitCode -ne 0) { throw "Could not make Azure CLI fixture executable (exit code $chmodExitCode)." }
    }
    $env:PATH = $temporaryDirectory + [IO.Path]::PathSeparator + $originalPath
    $env:AZ_STUB_RECORD_PATH = $recordPath

    $valid = @{
        SubscriptionId = '633398e2-6c00-4bb7-a576-2db0d210ee77'
        ResourceGroupName = 'Onkar.Pathre'
        AppName = 'app-mtp-web-dev-uks-001'
        SlotName = 'staging'
        ArtifactRoot = $artifactRoot
        DeploymentManifestPath = $deploymentManifest
        ExpectedSourceCommit = $sourceCommit
        EvidencePath = (Join-Path $temporaryDirectory 'deployment-success.json')
    }
    $env:AZ_STUB_MODE = 'success'
    & $deploymentScript @valid | Out-Null
    $records = @(Get-Content -LiteralPath $recordPath | ForEach-Object { $_ | ConvertFrom-Json })
    $deploy = @($records | Where-Object {
            $commandArguments = @($_.arguments | ForEach-Object { [string] $_ })
            $commandArguments.Count -ge 2 -and $commandArguments[0] -ceq 'webapp' -and $commandArguments[1] -ceq 'deploy' -and
                $commandArguments -ccontains '--src-path'
        })
    if ($deploy.Count -ne 1) {
        $observedCommands = @($records | ForEach-Object { @($_.arguments | ForEach-Object { [string] $_ }) -join ' ' }) -join '; '
        throw "Clean deployment did not execute exactly once. Observed: $observedCommands"
    }
    $arguments = @($deploy[0].arguments | ForEach-Object { [string] $_ })
    foreach ($pair in @(
            @('--subscription', '633398e2-6c00-4bb7-a576-2db0d210ee77'),
            @('--resource-group', 'Onkar.Pathre'), @('--name', 'app-mtp-web-dev-uks-001'),
            @('--slot', 'staging'), @('--type', 'zip'), @('--clean', 'true'),
            @('--async', 'false'), @('--restart', 'true'), @('--track-status', 'true'),
            @('--timeout', '1800000'))) {
        $index = [Array]::IndexOf([string[]] $arguments, $pair[0])
        if ($index -lt 0 -or $index + 1 -ge $arguments.Count -or $arguments[$index + 1] -cne $pair[1]) {
            throw "Clean deployment changed required target or completion option $($pair[0])."
        }
    }
    $successEvidence = Get-Content -LiteralPath $valid.EvidencePath -Raw | ConvertFrom-Json
    if ($successEvidence.status -cne 'PASS' -or $successEvidence.processExitCode -ne 0 -or -not [bool] $successEvidence.clean -or [bool] $successEvidence.asynchronous) {
        throw 'Successful clean deployment evidence did not retain completion semantics.'
    }

    $negativeTargets = @(
        @{ Key = 'SubscriptionId'; Value = '00000000-0000-0000-0000-000000000000' },
        @{ Key = 'ResourceGroupName'; Value = 'Other.Group' },
        @{ Key = 'AppName'; Value = 'app-mtp-web-prod-uks-001' },
        @{ Key = 'SlotName'; Value = 'production' }
    )
    foreach ($case in $negativeTargets) {
        $call = @{} + $valid
        $call[$case.Key] = $case.Value
        $call.EvidencePath = Join-Path $temporaryDirectory "rejected-$($case.Key).json"
        $rejection = $null
        try { & $deploymentScript @call | Out-Null } catch { $rejection = $_ }
        if ($null -eq $rejection) { throw "Clean deployment accepted unexpected target field $($case.Key)." }
        if ($rejection.Exception.Message -cne 'Azure demo staging target guard rejected an unexpected subscription, resource group, application or slot.') {
            throw "Clean deployment rejected unexpected target field $($case.Key) for the wrong reason: $($rejection.Exception.Message)"
        }
    }

    $env:AZ_STUB_MODE = 'deploy-failure'
    $failureCall = @{} + $valid
    $failureCall.EvidencePath = Join-Path $temporaryDirectory 'deployment-failure.json'
    $deploymentFailure = $null
    try { & $deploymentScript @failureCall | Out-Null } catch { $deploymentFailure = $_ }
    if ($null -eq $deploymentFailure) { throw 'Clean deployment accepted a nonzero Azure CLI deployment exit.' }
    if ($deploymentFailure.Exception.Message -cne 'Clean synchronous Azure web staging ZIP deployment failed with Azure CLI exit code 17.') {
        throw "Clean deployment rejected the exit-17 fixture for the wrong reason: $($deploymentFailure.Exception.Message)"
    }
    $failureEvidenceJson = Get-Content -LiteralPath $failureCall.EvidencePath -Raw
    $failureEvidence = $failureEvidenceJson | ConvertFrom-Json
    if ($failureEvidence.status -cne 'FAIL' -or $failureEvidence.processExitCode -ne 17 -or
        $failureEvidence.failure -cne 'Clean synchronous Azure web staging ZIP deployment failed with Azure CLI exit code 17.') {
        throw "Clean deployment did not retain the immediate Azure CLI failure exit code: $($failureEvidence | ConvertTo-Json -Compress)."
    }
    if ($failureEvidenceJson.IndexOf('synthetic deployment failure', [StringComparison]::OrdinalIgnoreCase) -ge 0) {
        throw 'Clean deployment evidence disclosed native Azure CLI stderr.'
    }

    $successMessage = "Clean web deployment regression passed exact artifact selection, target rejection, synchronous clean CLI options and nonzero exit evidence for $($negativeTargets.Count) invalid targets."
}
finally {
    $env:PATH = $originalPath
    $env:AZ_STUB_RECORD_PATH = $originalRecordPath
    $env:AZ_STUB_MODE = $originalMode
    if (Test-Path -LiteralPath $temporaryDirectory) { Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force }
}

if (Test-Path -LiteralPath $temporaryDirectory) { throw 'Clean deployment regression cleanup left its temporary directory behind.' }
if ($env:PATH -cne $originalPath -or $env:AZ_STUB_RECORD_PATH -cne $originalRecordPath -or $env:AZ_STUB_MODE -cne $originalMode) {
    throw 'Clean deployment regression cleanup did not restore its process environment.'
}
Write-Output $successMessage
exit 0
