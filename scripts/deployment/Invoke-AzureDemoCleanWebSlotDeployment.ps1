[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $SubscriptionId,
    [Parameter(Mandatory)] [string] $ResourceGroupName,
    [Parameter(Mandatory)] [string] $AppName,
    [Parameter(Mandatory)] [string] $SlotName,
    [Parameter(Mandatory)] [string] $ArtifactRoot,
    [Parameter(Mandatory)] [string] $DeploymentManifestPath,
    [Parameter(Mandatory)] [string] $ExpectedSourceCommit,
    [Parameter(Mandatory)] [string] $EvidencePath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'AzureDemoStagingDeployment.ps1')
. (Join-Path $PSScriptRoot '..\build\AzureDemoDeploymentArtifactUtilities.ps1')

$startedAt = [DateTimeOffset]::UtcNow
$artifact = $null
$target = $null
$deployExitCode = $null
$deploymentResponseSha256 = $null
$failure = $null
try {
    Assert-AzureDemoStagingTarget -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName `
        -Workload Web -AppName $AppName -SlotName $SlotName -Account ([pscustomobject]@{ id = $SubscriptionId }) `
        -Resource ([pscustomobject]@{
            id = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$AppName/slots/$SlotName"
            name = "$AppName/$SlotName"
            resourceGroup = $ResourceGroupName
            type = 'Microsoft.Web/sites/slots'
            defaultHostName = "$AppName-$SlotName.azurewebsites.net"
        }) | Out-Null

    Assert-AzureDemoDeploymentArtifact -ArtifactRoot $ArtifactRoot -ManifestPath $DeploymentManifestPath `
        -ExpectedSourceCommit $ExpectedSourceCommit | Out-Null
    $artifact = Assert-AzureDemoApplicationArtifact -ArtifactRoot $ArtifactRoot -Workload Web -ExpectedSourceCommit $ExpectedSourceCommit

    $versionResult = Invoke-AzureDemoAzCommand -Operation 'Azure CLI version preflight' -Arguments @('version', '--output', 'json')
    $version = ConvertFrom-AzureDemoJson -Json $versionResult.Stdout -Operation 'Azure CLI version preflight'
    $cliVersion = $null
    if (-not [Version]::TryParse([string] $version.'azure-cli', [ref] $cliVersion) -or $cliVersion -lt [Version] '2.48.1') {
        throw 'Azure CLI 2.48.1 or later is required for Microsoft Entra authenticated App Service deployment.'
    }
    $help = Invoke-AzureDemoAzCommand -Operation 'Azure CLI webapp deploy capability preflight' -Arguments @('webapp', 'deploy', '--help')
    foreach ($flag in @('--subscription', '--resource-group', '--name', '--slot', '--src-path', '--type', '--clean', '--async', '--restart', '--track-status', '--timeout')) {
        if ($help.Stdout.IndexOf($flag, [StringComparison]::Ordinal) -lt 0) { throw "Installed Azure CLI does not support required webapp deploy option $flag." }
    }

    $accountResult = Invoke-AzureDemoAzCommand -Operation 'Azure account lookup' -Arguments @(
        'account', 'show', '--query', '{id:id}', '--output', 'json', '--only-show-errors')
    $resourceResult = Invoke-AzureDemoAzCommand -Operation 'Azure web staging slot lookup' -Arguments @(
        'webapp', 'show', '--subscription', $SubscriptionId, '--resource-group', $ResourceGroupName,
        '--name', $AppName, '--slot', $SlotName,
        '--query', '{id:id,name:name,resourceGroup:resourceGroup,type:type,defaultHostName:defaultHostName,enabledHostNames:enabledHostNames}',
        '--output', 'json', '--only-show-errors')
    $account = ConvertFrom-AzureDemoJson -Json $accountResult.Stdout -Operation 'Azure account lookup'
    $resource = ConvertFrom-AzureDemoJson -Json $resourceResult.Stdout -Operation 'Azure web staging slot lookup'
    $target = Assert-AzureDemoStagingTarget -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName `
        -Workload Web -AppName $AppName -SlotName $SlotName -Account $account -Resource $resource

    $settingsResult = Invoke-AzureDemoAzCommand -Operation 'Azure web staging remote-build setting lookup' -Arguments @(
        'webapp', 'config', 'appsettings', 'list', '--subscription', $SubscriptionId,
        '--resource-group', $ResourceGroupName, '--name', $AppName, '--slot', $SlotName,
        '--query', "[?name=='SCM_DO_BUILD_DURING_DEPLOYMENT' || name=='ENABLE_ORYX_BUILD'].{name:name,value:value}",
        '--output', 'json', '--only-show-errors')
    $settingsObject = ConvertFrom-AzureDemoJson -Json $settingsResult.Stdout -Operation 'Azure web staging remote-build setting lookup'
    $settings = @(ConvertTo-AzureDemoObjectArray $settingsObject)
    $scmBuild = @($settings | Where-Object { [string] $_.name -ceq 'SCM_DO_BUILD_DURING_DEPLOYMENT' })
    $oryxBuild = @($settings | Where-Object { [string] $_.name -ceq 'ENABLE_ORYX_BUILD' })
    if ($scmBuild.Count -ne 1 -or [string] $scmBuild[0].value -cne 'false' -or
        @($oryxBuild | Where-Object { [string] $_.value -cne 'false' }).Count -gt 0) {
        throw 'Azure web staging deployment requires remote build and Oryx build to remain disabled.'
    }

    $deployArguments = @(
        'webapp', 'deploy', '--subscription', $SubscriptionId, '--resource-group', $ResourceGroupName,
        '--name', $AppName, '--slot', $SlotName, '--src-path', $artifact.Path,
        '--type', 'zip', '--clean', 'true', '--async', 'false', '--restart', 'true',
        '--track-status', 'true', '--timeout', '1800000', '--output', 'json', '--only-show-errors')
    $deployResult = Invoke-AzureDemoAzCommand -Operation 'Clean synchronous Azure web staging ZIP deployment' `
        -Arguments $deployArguments -AllowFailure
    $deployExitCode = $deployResult.ExitCode
    if (-not [string]::IsNullOrWhiteSpace($deployResult.Stdout)) {
        $deploymentResponseSha256 = Get-AzureDemoTextSha256 $deployResult.Stdout
    }
    if ($deployExitCode -ne 0) { throw "Clean synchronous Azure web staging ZIP deployment failed with Azure CLI exit code $deployExitCode." }
}
catch {
    $failure = $_.Exception.Message
}
finally {
    $evidenceDirectory = Split-Path -Parent $EvidencePath
    if (-not [string]::IsNullOrWhiteSpace($evidenceDirectory)) { New-Item -ItemType Directory -Path $evidenceDirectory -Force | Out-Null }
    [ordered]@{
        schemaVersion = '1'
        startedAtUtc = $startedAt.ToString('O')
        completedAtUtc = [DateTimeOffset]::UtcNow.ToString('O')
        status = if ($null -eq $failure) { 'PASS' } else { 'FAIL' }
        sourceCommit = $ExpectedSourceCommit
        artifactPath = if ($null -eq $artifact) { $null } else { 'application/web.zip' }
        artifactSha256 = if ($null -eq $artifact) { $null } else { $artifact.Sha256 }
        resourceId = if ($null -eq $target) { $null } else { $target.ResourceId }
        slot = $SlotName
        clean = $true
        asynchronous = $false
        trackStartupStatus = $true
        processExitCode = $deployExitCode
        deploymentResponseSha256 = $deploymentResponseSha256
        failure = $failure
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $EvidencePath -Encoding UTF8
}
if ($null -ne $failure) { throw $failure }
Write-Output 'Clean synchronous deployment completed for the exact approved web staging slot and immutable ZIP.'
