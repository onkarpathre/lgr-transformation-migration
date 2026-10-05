[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).ProviderPath
. (Join-Path $repo 'scripts\smoke\AzureDemoSmokeEvidenceContract.ps1')

function Assert-True([bool] $Condition, [string] $Message) {
    if (-not $Condition) { throw $Message }
}

$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-smoke-evidence-{0}" -f [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null
$utf8NoBom = [Text.UTF8Encoding]::new($false)

$context = [ordered]@{
    CheckId = 'SMK-05'
    ExpectedSourceCommit = '1111111111111111111111111111111111111111'
    ExpectedArtifactManifestSha256 = '2222222222222222222222222222222222222222222222222222222222222222'
    ExpectedInfrastructureDeploymentId = '/subscriptions/633398e2-6c00-4bb7-a576-2db0d210ee77/resourceGroups/Onkar.Pathre/providers/Microsoft.Resources/deployments/mtp-azure-demo-123'
    ExpectedPipelineDefinition = 'mtp-azure-demo-deploy'
    ExpectedPipelineRunId = '123'
    ExpectedSubscriptionId = '633398e2-6c00-4bb7-a576-2db0d210ee77'
    ExpectedResourceGroup = 'Onkar.Pathre'
    ExpectedWebApp = 'app-mtp-web-dev-uks-001'
    ExpectedApiApp = 'app-mtp-api-dev-uks-001'
    ExpectedSlot = 'staging'
    ExpectedWebHost = 'app-mtp-web-dev-uks-001-staging-token.uksouth-01.azurewebsites.net'
    ExpectedApiHost = 'app-mtp-api-dev-uks-001-staging-token.uksouth-01.azurewebsites.net'
}

function New-Attachment([string] $Name, [string] $Content) {
    $attachments = Join-Path $temporaryDirectory 'attachments'
    New-Item -ItemType Directory -Path $attachments -Force | Out-Null
    $path = Join-Path $attachments $Name
    [IO.File]::WriteAllText($path, $Content, $utf8NoBom)
    return [pscustomobject]@{
        RelativePath = "attachments/$Name"
        Sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    }
}

function New-Evidence([string] $CheckId, [hashtable] $Overrides = @{}) {
    $requirement = Get-AzureDemoSmokeEvidenceRequirement -CheckId $CheckId
    $attachment = New-Attachment "$CheckId-result.json" '{"executed":true,"assertions":"sanitized"}'
    $record = [ordered]@{
        schemaVersion = '1'
        evidenceClass = 'protected-runtime'
        checkId = $CheckId
        status = 'PASS'
        sourceCommit = $context.ExpectedSourceCommit
        artifactManifestSha256 = $context.ExpectedArtifactManifestSha256
        infrastructureDeploymentId = $context.ExpectedInfrastructureDeploymentId
        target = [ordered]@{
            subscriptionId = $context.ExpectedSubscriptionId
            resourceGroup = $context.ExpectedResourceGroup
            webApp = $context.ExpectedWebApp
            apiApp = $context.ExpectedApiApp
            slot = $context.ExpectedSlot
            webHost = $context.ExpectedWebHost
            apiHost = $context.ExpectedApiHost
        }
        origin = [ordered]@{
            pipelineDefinition = $context.ExpectedPipelineDefinition
            pipelineRunId = $context.ExpectedPipelineRunId
            producerType = 'automated'
            producerId = 'fixture-producer'
            procedureReference = 'scripts/smoke/protected-procedure'
        }
        execution = [ordered]@{
            startedAtUtc = [DateTimeOffset]::UtcNow.AddMinutes(-1).ToString('O')
            completedAtUtc = [DateTimeOffset]::UtcNow.ToString('O')
            location = $requirement.Location
            identityKind = $requirement.IdentityKind
            correlationId = 'fixture-correlation'
            syntheticFixture = $false
        }
        assertions = @($requirement.Assertions | ForEach-Object {
                [ordered]@{ id = $_; status = 'PASS'; evidencePath = $attachment.RelativePath; evidenceSha256 = $attachment.Sha256 }
            })
        previousRelease = $null
    }
    foreach ($key in $Overrides.Keys) { $record[$key] = $Overrides[$key] }
    return $record
}

function Write-Evidence([object] $Evidence) {
    $path = Join-Path $temporaryDirectory "$($Evidence.checkId).json"
    [IO.File]::WriteAllText($path, ($Evidence | ConvertTo-Json -Depth 12), $utf8NoBom)
    return $path
}

function Invoke-Validation([string] $EvidencePath, [hashtable] $Expected = $context) {
    Assert-AzureDemoSmokeEvidence -EvidencePath $EvidencePath -EvidenceRoot $temporaryDirectory @Expected | Out-Null
}

function Assert-Rejected([string] $Name, [scriptblock] $Action, [string] $Category) {
    $rejected = $false
    try { & $Action } catch {
        $rejected = $true
        if (-not $_.Exception.Message.Contains($Category)) {
            throw "Evidence case '$Name' failed with an unexpected safe category: $($_.Exception.Message)"
        }
    }
    if (-not $rejected) { throw "Evidence case '$Name' was unexpectedly accepted." }
}

try {
    $protectedIds = @('SMK-01', 'SMK-04', 'SMK-05', 'SMK-06', 'SMK-07', 'SMK-08', 'SMK-09', 'SMK-12', 'SMK-13', 'SMK-14', 'SMK-15', 'SMK-16', 'SMK-17', 'SMK-18', 'SMK-19', 'SMK-21', 'SMK-22')
    foreach ($protectedId in $protectedIds) { Get-AzureDemoSmokeEvidenceRequirement -CheckId $protectedId | Out-Null }
    Assert-True ($protectedIds.Count -eq 17) 'Protected evidence catalogue must retain exactly the 17 approved hybrid/specialist checks.'
    Assert-Rejected 'automated-only check used as protected evidence' { Get-AzureDemoSmokeEvidenceRequirement -CheckId 'SMK-20' | Out-Null } 'no protected-evidence requirement'

    $timestampProbeJson = '{"startedAtUtc":"2026-10-05T12:34:56.1234567Z"}'
    $plainTimestampProbe = $timestampProbeJson | ConvertFrom-Json
    $preservedTimestampProbe = ConvertFrom-AzureDemoSmokeEvidenceJson -Json $timestampProbeJson -SyntaxCategory 'PROBE_JSON_SYNTAX'
    $plainTimestampType = Get-AzureDemoSafeRuntimeTypeName $plainTimestampProbe.startedAtUtc
    $preservedTimestampType = Get-AzureDemoSafeRuntimeTypeName $preservedTimestampProbe.startedAtUtc
    Assert-True ($preservedTimestampProbe.startedAtUtc -is [string]) "String-preserving JSON parsing returned unexpected runtime type $preservedTimestampType."
    Write-Output "Smoke evidence timestamp deserialization types: default=$plainTimestampType; preserved=$preservedTimestampType; edition=$($PSVersionTable.PSEdition); version=$($PSVersionTable.PSVersion)."

    $validPath = Write-Evidence (New-Evidence 'SMK-05')
    Invoke-Validation $validPath

    $validSecond = [DateTimeOffset]::UtcNow.AddMinutes(-2).ToString("yyyy-MM-dd'T'HH:mm:ss", [Globalization.CultureInfo]::InvariantCulture)
    foreach ($zoneSuffix in @('Z', '+00:00')) {
        foreach ($fractionalDigits in 0..7) {
            $fraction = if ($fractionalDigits -eq 0) { '' } else { '.' + '1234567'.Substring(0, $fractionalDigits) }
            $validTimestamp = "$validSecond$fraction$zoneSuffix"
            $timestampEvidence = New-Evidence 'SMK-05'
            $timestampEvidence.execution.startedAtUtc = $validTimestamp
            $timestampEvidence.execution.completedAtUtc = $validTimestamp
            Invoke-Validation (Write-Evidence $timestampEvidence)
        }
    }

    Assert-Rejected 'missing evidence' { Invoke-Validation (Join-Path $temporaryDirectory 'missing.json') } 'required immutable artifact path'
    $malformedPath = Join-Path $temporaryDirectory 'SMK-05.json'
    [IO.File]::WriteAllText($malformedPath, '{ invalid', $utf8NoBom)
    Assert-Rejected 'malformed evidence' { Invoke-Validation $malformedPath } 'EVIDENCE_JSON_SYNTAX'

    foreach ($invalidTimestampCase in @(
            @{ Name = 'nonzero positive offset'; Value = '2026-10-05T12:34:56+01:00'; Category = 'EXECUTION_TIMESTAMP_SYNTAX' },
            @{ Name = 'nonzero negative offset'; Value = '2026-10-05T12:34:56-01:00'; Category = 'EXECUTION_TIMESTAMP_SYNTAX' },
            @{ Name = 'missing timezone'; Value = '2026-10-05T12:34:56'; Category = 'EXECUTION_TIMESTAMP_SYNTAX' },
            @{ Name = 'invalid calendar date'; Value = '2026-02-30T12:34:56Z'; Category = 'EXECUTION_TIMESTAMP_SYNTAX' },
            @{ Name = 'leading whitespace'; Value = ' 2026-10-05T12:34:56Z'; Category = 'EXECUTION_TIMESTAMP_SYNTAX' },
            @{ Name = 'trailing whitespace'; Value = '2026-10-05T12:34:56Z '; Category = 'EXECUTION_TIMESTAMP_SYNTAX' },
            @{ Name = 'excessive fractional precision'; Value = '2026-10-05T12:34:56.12345678Z'; Category = 'EXECUTION_TIMESTAMP_SYNTAX' }
        )) {
        $invalidTimestampEvidence = New-Evidence 'SMK-05'
        $invalidTimestampEvidence.execution.startedAtUtc = $invalidTimestampCase.Value
        $invalidTimestampEvidence.execution.completedAtUtc = $invalidTimestampCase.Value
        $invalidTimestampPath = Write-Evidence $invalidTimestampEvidence
        Assert-Rejected $invalidTimestampCase.Name { Invoke-Validation $invalidTimestampPath } $invalidTimestampCase.Category
    }

    $numericTimestamp = New-Evidence 'SMK-05'
    $numericTimestamp.execution.startedAtUtc = 12345
    Assert-Rejected 'numeric started timestamp' { Invoke-Validation (Write-Evidence $numericTimestamp) } 'EXECUTION_TIMESTAMP_TYPE (field=startedAtUtc; runtimeType='

    $booleanTimestamp = New-Evidence 'SMK-05'
    $booleanTimestamp.execution.completedAtUtc = $false
    Assert-Rejected 'boolean completed timestamp' { Invoke-Validation (Write-Evidence $booleanTimestamp) } 'EXECUTION_TIMESTAMP_TYPE (field=completedAtUtc; runtimeType=System.Boolean)'

    $orderedTimestampBase = [DateTimeOffset]::UtcNow.AddMinutes(-3)
    $reversedTimestamps = New-Evidence 'SMK-05'
    $reversedTimestamps.execution.startedAtUtc = $orderedTimestampBase.AddMinutes(1).ToString('O')
    $reversedTimestamps.execution.completedAtUtc = $orderedTimestampBase.ToString('O')
    Assert-Rejected 'completed before started' { Invoke-Validation (Write-Evidence $reversedTimestamps) } 'EXECUTION_TIMESTAMP_ORDER'

    $futureTimestamps = New-Evidence 'SMK-05'
    $futureTimestamps.execution.startedAtUtc = [DateTimeOffset]::UtcNow.AddMinutes(9).ToString('O')
    $futureTimestamps.execution.completedAtUtc = [DateTimeOffset]::UtcNow.AddMinutes(10).ToString('O')
    Assert-Rejected 'excessive future timestamp' { Invoke-Validation (Write-Evidence $futureTimestamps) } 'EXECUTION_TIMESTAMP_FUTURE'

    $wrongCommitPath = Write-Evidence (New-Evidence 'SMK-05' @{ sourceCommit = ('3' * 40) })
    Assert-Rejected 'wrong commit' { Invoke-Validation $wrongCommitPath } 'RELEASE_PROVENANCE'
    $wrongArtifactPath = Write-Evidence (New-Evidence 'SMK-05' @{ artifactManifestSha256 = ('4' * 64) })
    Assert-Rejected 'wrong artifact' { Invoke-Validation $wrongArtifactPath } 'RELEASE_PROVENANCE'

    $substitutedTarget = New-Evidence 'SMK-05'
    $substitutedTarget.target.webHost = 'substituted.azurewebsites.net'
    $substitutedTargetPath = Write-Evidence $substitutedTarget
    Assert-Rejected 'substituted target' { Invoke-Validation $substitutedTargetPath } 'TARGET_PROVENANCE'

    $wrongRun = New-Evidence 'SMK-05'
    $wrongRun.origin.pipelineRunId = '999'
    $wrongRunPath = Write-Evidence $wrongRun
    Assert-Rejected 'wrong pipeline origin' { Invoke-Validation $wrongRunPath } 'EVIDENCE_ORIGIN'

    $wrongLocation = New-Evidence 'SMK-05'
    $wrongLocation.execution.location = 'substituted-location'
    Assert-Rejected 'wrong execution location' { Invoke-Validation (Write-Evidence $wrongLocation) } 'EXECUTION_PROVENANCE'

    $wrongIdentity = New-Evidence 'SMK-05'
    $wrongIdentity.execution.identityKind = 'substituted-identity'
    Assert-Rejected 'wrong execution identity' { Invoke-Validation (Write-Evidence $wrongIdentity) } 'EXECUTION_PROVENANCE'

    $fixtureEvidence = New-Evidence 'SMK-05'
    $fixtureEvidence.execution.syntheticFixture = $true
    $fixturePath = Write-Evidence $fixtureEvidence
    Assert-Rejected 'synthetic fixture substituted for protected evidence' { Invoke-Validation $fixturePath } 'EXECUTION_PROVENANCE'

    $missingAssertion = New-Evidence 'SMK-05'
    $missingAssertion.assertions = @($missingAssertion.assertions | Select-Object -Skip 1)
    $missingAssertionPath = Write-Evidence $missingAssertion
    Assert-Rejected 'missing acceptance assertion' { Invoke-Validation $missingAssertionPath } 'ASSERTION_SET'

    $badAttachment = New-Evidence 'SMK-05'
    $badAttachment.assertions[0].evidenceSha256 = ('5' * 64)
    $badAttachmentPath = Write-Evidence $badAttachment
    Assert-Rejected 'wrong attachment hash' { Invoke-Validation $badAttachmentPath } 'ASSERTION_ATTACHMENT_HASH'

    $previousManifest = [ordered]@{ schemaVersion = '1'; sourceCommit = ('6' * 40); createdAtUtc = [DateTimeOffset]::UtcNow.AddDays(-1).ToString('O'); artifacts = @([ordered]@{ path = 'application/api.zip'; sha256 = ('7' * 64) }) }
    $previousManifestPath = Join-Path $temporaryDirectory 'previous-release-manifest.json'
    [IO.File]::WriteAllText($previousManifestPath, ($previousManifest | ConvertTo-Json -Depth 6), $utf8NoBom)
    $previousManifestHash = (Get-FileHash -LiteralPath $previousManifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $rehearsal = New-Evidence 'SMK-19'
    $rehearsal.previousRelease = [ordered]@{
        sourceCommit = $previousManifest.sourceCommit
        artifactManifestSha256 = $previousManifestHash
        deploymentEvidenceReference = 'protected-deployment-record/previous'
        manifestPath = 'previous-release-manifest.json'
        manifestSha256 = $previousManifestHash
        rehearsalApprovalReference = 'protected-change/rehearsal'
    }
    $rehearsalPath = Write-Evidence $rehearsal
    $rehearsalContext = @{} + $context
    $rehearsalContext.CheckId = 'SMK-19'
    Invoke-Validation $rehearsalPath $rehearsalContext

    $currentAsPrevious = New-Evidence 'SMK-19'
    $currentAsPrevious.previousRelease = [ordered]@{
        sourceCommit = $context.ExpectedSourceCommit
        artifactManifestSha256 = $context.ExpectedArtifactManifestSha256
        deploymentEvidenceReference = 'invalid/current'
        manifestPath = 'previous-release-manifest.json'
        manifestSha256 = $previousManifestHash
        rehearsalApprovalReference = 'invalid/current'
    }
    $currentAsPreviousPath = Write-Evidence $currentAsPrevious
    Assert-Rejected 'current release substituted for rollback target' { Invoke-Validation $currentAsPreviousPath $rehearsalContext } 'PREVIOUS_RELEASE_PROVENANCE'
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) { Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force }
}

Write-Output 'Azure demo smoke evidence contract passed valid protected-runtime and previous-release fixtures; Z/+00:00 timestamps at 0-7 fractional digits; timestamp type, syntax, ordering and future-time rejection; plus all retained missing, malformed, substitution, identity/location, assertion, attachment and fixture rejection cases.'
