[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $SubscriptionId,
    [Parameter(Mandatory)] [string] $ResourceGroupName,
    [Parameter(Mandatory)] [ValidateSet('Web', 'Api')] [string] $Workload,
    [Parameter(Mandatory)] [string] $AppName,
    [Parameter(Mandatory)] [string] $SlotName,
    [Parameter(Mandatory)] [string] $ArtifactRoot,
    [Parameter(Mandatory)] [string] $DeploymentManifestPath,
    [Parameter(Mandatory)] [string] $ExpectedSourceCommit,
    [Parameter(Mandatory)] [string] $EvidencePath,
    [string] $DeployedContentZipPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'AzureDemoStagingDeployment.ps1')
. (Join-Path $PSScriptRoot '..\build\AzureDemoDeploymentArtifactUtilities.ps1')

$temporaryZip = $null
$accessToken = $null
$target = $null
$failure = $null
try {
    Assert-AzureDemoDeploymentArtifact -ArtifactRoot $ArtifactRoot -ManifestPath $DeploymentManifestPath `
        -ExpectedSourceCommit $ExpectedSourceCommit | Out-Null
    $artifact = Assert-AzureDemoApplicationArtifact -ArtifactRoot $ArtifactRoot -Workload $Workload -ExpectedSourceCommit $ExpectedSourceCommit

    if ([string]::IsNullOrWhiteSpace($DeployedContentZipPath)) {
        $accountResult = Invoke-AzureDemoAzCommand -Operation 'Azure account lookup for deployed-content verification' -Arguments @(
            'account', 'show', '--query', '{id:id}', '--output', 'json', '--only-show-errors')
        $resourceResult = Invoke-AzureDemoAzCommand -Operation 'Azure staging slot lookup for deployed-content verification' -Arguments @(
            'webapp', 'show', '--subscription', $SubscriptionId, '--resource-group', $ResourceGroupName,
            '--name', $AppName, '--slot', $SlotName,
            '--query', '{id:id,name:name,resourceGroup:resourceGroup,type:type,defaultHostName:defaultHostName,enabledHostNames:enabledHostNames}',
            '--output', 'json', '--only-show-errors')
        $account = ConvertFrom-AzureDemoJson -Json $accountResult.Stdout -Operation 'Azure account lookup for deployed-content verification'
        $resource = ConvertFrom-AzureDemoJson -Json $resourceResult.Stdout -Operation 'Azure staging slot lookup for deployed-content verification'
        $target = Assert-AzureDemoStagingTarget -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName `
            -Workload $Workload -AppName $AppName -SlotName $SlotName -Account $account -Resource $resource

        $scmHosts = @($resource.enabledHostNames | Where-Object {
                [string] $_ -cmatch ('^(?i)' + [regex]::Escape("$AppName-$SlotName") + '(?:-[a-z0-9]+)?\.scm(?:\.[a-z0-9-]+)?\.azurewebsites\.net$')
            } | Sort-Object -Unique)
        if ($scmHosts.Count -ne 1) { throw 'Could not resolve exactly one approved staging SCM hostname from the Azure slot resource.' }

        $tokenResult = Invoke-AzureDemoAzCommand -Operation 'Microsoft Entra token acquisition for SCM verification' -Arguments @(
            'account', 'get-access-token', '--subscription', $SubscriptionId,
            '--resource', 'https://management.azure.com/', '--query', 'accessToken', '--output', 'tsv', '--only-show-errors')
        $accessToken = $tokenResult.Stdout.Trim()
        if ([string]::IsNullOrWhiteSpace($accessToken)) { throw 'Microsoft Entra token acquisition returned no SCM verification token.' }

        $temporaryZip = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-$($Workload.ToLowerInvariant())-wwwroot-$([Guid]::NewGuid().ToString('N')).zip")
        $scmUri = [uri] "https://$($scmHosts[0])/api/zip/site/wwwroot/"
        Invoke-WebRequest -Uri $scmUri -Headers @{ Authorization = "Bearer $accessToken" } `
            -OutFile $temporaryZip -UseBasicParsing -TimeoutSec 600
        if (-not (Test-Path -LiteralPath $temporaryZip -PathType Leaf) -or (Get-Item -LiteralPath $temporaryZip).Length -le 0) {
            throw 'Authenticated SCM content download returned no deployed ZIP snapshot.'
        }
        $DeployedContentZipPath = $temporaryZip
    }
    else {
        $expectedApp = if ($Workload -ceq 'Web') { $script:AzureDemoWebAppName } else { $script:AzureDemoApiAppName }
        $target = Assert-AzureDemoStagingTarget -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName `
            -Workload $Workload -AppName $AppName -SlotName $SlotName -Account ([pscustomobject]@{ id = $SubscriptionId }) `
            -Resource ([pscustomobject]@{
                id = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$expectedApp/slots/$SlotName"
                name = "$expectedApp/$SlotName"
                resourceGroup = $ResourceGroupName
                type = 'Microsoft.Web/sites/slots'
                defaultHostName = "$expectedApp-$SlotName.azurewebsites.net"
            })
    }

    Compare-AzureDemoDeployedZip -Workload $Workload -ExpectedZipPath $artifact.Path `
        -DeployedZipPath $DeployedContentZipPath -EvidencePath $EvidencePath `
        -SourceCommit $ExpectedSourceCommit -ResourceId $target.ResourceId | Out-Null
}
catch {
    $failure = $_.Exception.Message
    if (-not (Test-Path -LiteralPath $EvidencePath -PathType Leaf)) {
        $evidenceDirectory = Split-Path -Parent $EvidencePath
        if (-not [string]::IsNullOrWhiteSpace($evidenceDirectory)) { New-Item -ItemType Directory -Path $evidenceDirectory -Force | Out-Null }
        [ordered]@{
            schemaVersion = '1'
            capturedAtUtc = [DateTimeOffset]::UtcNow.ToString('O')
            status = 'FAIL'
            workload = $Workload
            sourceCommit = $ExpectedSourceCommit
            resourceId = if ($null -eq $target) { $null } else { $target.ResourceId }
            failure = $failure
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $EvidencePath -Encoding UTF8
    }
}
finally {
    Remove-Variable accessToken -ErrorAction SilentlyContinue
    if ($null -ne $temporaryZip) { Remove-Item -LiteralPath $temporaryZip -Force -ErrorAction SilentlyContinue }
}
if ($null -ne $failure) { throw $failure }
Write-Output "$Workload staging content matches the exact immutable ZIP application files."
