$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

. (Join-Path $PSScriptRoot '..\build\AzureDemoDeploymentArtifactUtilities.ps1')

function Get-AzureDemoSmokeEvidenceRequirement {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string] $CheckId)

    $requirements = [ordered]@{
        'SMK-01' = @{ Location = 'outside-authorized-private-network'; IdentityKind = 'anonymous-external'; Assertions = @('minimum-tls-rejected') }
        'SMK-04' = @{ Location = 'outside-authorized-private-network'; IdentityKind = 'anonymous-external'; Assertions = @('public-api-unreachable-or-denied', 'no-api-metadata-disclosed') }
        'SMK-05' = @{ Location = 'sweden-managed-pool'; IdentityKind = 'deployment-agent-and-runtime-identities'; Assertions = @('api-private-resolution', 'sql-private-resolution', 'key-vault-private-resolution', 'blob-private-resolution', 'approved-identity-access', 'unapproved-identity-denial') }
        'SMK-06' = @{ Location = 'assigned-user-browser'; IdentityKind = 'assigned-workforce-user'; Assertions = @('pkce-s256-completed', 'exact-tenant-audience-client-scope', 'assigned-user-enforced', 'token-absent-from-url-storage-logs') }
        'SMK-07' = @{ Location = 'sweden-managed-pool'; IdentityKind = 'untrusted-token-client'; Assertions = @('missing-token-denied', 'expired-token-denied', 'wrong-tenant-denied', 'wrong-audience-denied', 'disallowed-client-denied', 'www-authenticate-on-401', 'no-authentication-fallback') }
        'SMK-08' = @{ Location = 'sweden-managed-pool'; IdentityKind = 'anonymous-or-assigned-user'; Assertions = @('all-prohibited-headers-tested', 'no-authority-change', 'header-values-redacted') }
        'SMK-09' = @{ Location = 'assigned-user-browser'; IdentityKind = 'assigned-workforce-user'; Assertions = @('authorized-project-succeeds', 'foreign-project-non-enumerating-denial', 'unassigned-project-non-enumerating-denial') }
        'SMK-12' = @{ Location = 'sweden-managed-pool'; IdentityKind = 'controlled-operations-identity'; Assertions = @('live-remains-process-only', 'ready-and-web-return-503', 'alert-and-trace-observed', 'no-dependency-details-disclosed') }
        'SMK-13' = @{ Location = 'sweden-managed-pool'; IdentityKind = 'separated-sql-identities'; Assertions = @('runtime-dml-succeeds', 'runtime-ddl-denied', 'runtime-user-creation-denied', 'migration-rights-match-reviewed-contract') }
        'SMK-14' = @{ Location = 'sweden-managed-pool'; IdentityKind = 'runtime-managed-identity'; Assertions = @('approved-key-vault-read-succeeds', 'approved-blob-read-succeeds', 'administration-denied', 'cross-container-project-denied', 'public-access-denied') }
        'SMK-15' = @{ Location = 'sweden-managed-pool'; IdentityKind = 'migration-and-runtime-identities'; Assertions = @('migration-history-exact', 'schema-checks-pass', 'seed-counts-and-checksum-exact', 'no-startup-migration-or-seed') }
        'SMK-16' = @{ Location = 'assigned-user-browser'; IdentityKind = 'assigned-workforce-user'; Assertions = @('approved-synthetic-csv-scans-and-previews', 'malformed-file-denied', 'oversized-file-denied', 'wrong-type-file-denied', 'tenant-object-path-exact', 'audit-evidence-recorded') }
        'SMK-17' = @{ Location = 'assigned-user-browser'; IdentityKind = 'assigned-workforce-user'; Assertions = @('browser-web-api-sql-trace-correlated', 'payload-token-secret-header-redaction') }
        'SMK-18' = @{ Location = 'sweden-managed-pool'; IdentityKind = 'monitoring-operator'; Assertions = @('synthetic-alert-delivered-to-named-owner', 'sampling-active', 'retention-active', 'daily-cap-active') }
        'SMK-19' = @{ Location = 'protected-rehearsal'; IdentityKind = 'human-approved-release-operator'; Assertions = @('unhealthy-candidate-blocked', 'no-direct-main-deployment', 'swap-back-restored-previous-release') }
        'SMK-21' = @{ Location = 'assigned-user-browser'; IdentityKind = 'independent-tester'; Assertions = @('j01-pass', 'j02-pass', 'j03-pass', 'j04-pass', 'j05-pass', 'j06-pass', 'j07-pass', 'j08-pass', 'j09-pass', 'excluded-capabilities-not-presented') }
        'SMK-22' = @{ Location = 'independent-review-workstation'; IdentityKind = 'independent-tester'; Assertions = @('no-azure-provisioning-path', 'no-migration-execution-path', 'no-direct-discovery-api-path', 'no-ai-path', 'no-multi-cloud-path', 'no-external-customer-access-path') }
    }

    if (-not $requirements.Contains($CheckId)) {
        throw "Smoke evidence contract has no protected-evidence requirement for $CheckId."
    }
    return $requirements[$CheckId]
}

function Test-AzureDemoUtcTimestamp {
    param([string] $Value, [ref] $Parsed)
    if ($Value -cnotmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,7})?(?:Z|\+00:00)$') { return $false }
    $timestamp = [DateTimeOffset]::MinValue
    if (-not [DateTimeOffset]::TryParse($Value, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind, [ref] $timestamp) -or $timestamp.Offset -ne [TimeSpan]::Zero) {
        return $false
    }
    $Parsed.Value = $timestamp
    return $true
}

function Assert-AzureDemoExactProperties {
    param([object] $Value, [string[]] $Expected, [string] $Category)
    if ($null -eq $Value) { throw "Smoke evidence rejected: $Category." }
    $actual = @(($Value.PSObject.Properties.Name | Sort-Object) -join '|')
    $expectedNames = @(($Expected | Sort-Object) -join '|')
    if ($actual.Count -ne 1 -or $expectedNames.Count -ne 1 -or $actual[0] -cne $expectedNames[0]) {
        throw "Smoke evidence rejected: $Category."
    }
}

function Assert-AzureDemoSmokeEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $EvidencePath,
        [Parameter(Mandatory)] [string] $EvidenceRoot,
        [Parameter(Mandatory)] [string] $CheckId,
        [Parameter(Mandatory)] [string] $ExpectedSourceCommit,
        [Parameter(Mandatory)] [string] $ExpectedArtifactManifestSha256,
        [Parameter(Mandatory)] [string] $ExpectedInfrastructureDeploymentId,
        [Parameter(Mandatory)] [string] $ExpectedPipelineDefinition,
        [Parameter(Mandatory)] [string] $ExpectedPipelineRunId,
        [Parameter(Mandatory)] [string] $ExpectedSubscriptionId,
        [Parameter(Mandatory)] [string] $ExpectedResourceGroup,
        [Parameter(Mandatory)] [string] $ExpectedWebApp,
        [Parameter(Mandatory)] [string] $ExpectedApiApp,
        [Parameter(Mandatory)] [ValidateSet('production', 'staging')] [string] $ExpectedSlot,
        [Parameter(Mandatory)] [string] $ExpectedWebHost,
        [Parameter(Mandatory)] [string] $ExpectedApiHost
    )

    if ($CheckId -cnotmatch '^SMK-(?:0[1-9]|1[0-9]|2[0-2])$' -or
        $ExpectedSourceCommit -cnotmatch '^[0-9a-f]{40}$' -or
        $ExpectedArtifactManifestSha256 -cnotmatch '^[0-9a-f]{64}$' -or
        [string]::IsNullOrWhiteSpace($ExpectedInfrastructureDeploymentId) -or
        [string]::IsNullOrWhiteSpace($ExpectedPipelineDefinition) -or
        [string]::IsNullOrWhiteSpace($ExpectedPipelineRunId)) {
        throw 'Smoke evidence validator received an invalid expected release context.'
    }

    $requirement = Get-AzureDemoSmokeEvidenceRequirement -CheckId $CheckId
    $resolvedRoot = (Resolve-Path -LiteralPath $EvidenceRoot).ProviderPath
    $resolvedEvidence = Resolve-AzureDemoArtifactPath -ArtifactRoot $resolvedRoot -Path ([IO.Path]::GetFullPath($EvidencePath)) -PathType Leaf
    try { $evidence = Get-Content -LiteralPath $resolvedEvidence -Raw | ConvertFrom-Json -ErrorAction Stop } catch { throw 'Smoke evidence rejected: EVIDENCE_JSON_SYNTAX.' }

    Assert-AzureDemoExactProperties $evidence @('schemaVersion', 'evidenceClass', 'checkId', 'status', 'sourceCommit', 'artifactManifestSha256', 'infrastructureDeploymentId', 'target', 'origin', 'execution', 'assertions', 'previousRelease') 'EVIDENCE_SCHEMA'
    if ($evidence.schemaVersion -cne '1' -or $evidence.evidenceClass -cne 'protected-runtime' -or $evidence.checkId -cne $CheckId -or $evidence.status -cne 'PASS') {
        throw 'Smoke evidence rejected: EVIDENCE_ID_OR_STATUS.'
    }
    if ($evidence.sourceCommit -cne $ExpectedSourceCommit -or $evidence.artifactManifestSha256 -cne $ExpectedArtifactManifestSha256 -or $evidence.infrastructureDeploymentId -cne $ExpectedInfrastructureDeploymentId) {
        throw 'Smoke evidence rejected: RELEASE_PROVENANCE.'
    }

    Assert-AzureDemoExactProperties $evidence.target @('subscriptionId', 'resourceGroup', 'webApp', 'apiApp', 'slot', 'webHost', 'apiHost') 'TARGET_SCHEMA'
    if (-not [string]::Equals([string] $evidence.target.subscriptionId, $ExpectedSubscriptionId, [StringComparison]::OrdinalIgnoreCase) -or
        $evidence.target.resourceGroup -cne $ExpectedResourceGroup -or $evidence.target.webApp -cne $ExpectedWebApp -or $evidence.target.apiApp -cne $ExpectedApiApp -or
        $evidence.target.slot -cne $ExpectedSlot -or $evidence.target.webHost -cne $ExpectedWebHost -or $evidence.target.apiHost -cne $ExpectedApiHost) {
        throw 'Smoke evidence rejected: TARGET_PROVENANCE.'
    }

    Assert-AzureDemoExactProperties $evidence.origin @('pipelineDefinition', 'pipelineRunId', 'producerType', 'producerId', 'procedureReference') 'ORIGIN_SCHEMA'
    if ($evidence.origin.pipelineDefinition -cne $ExpectedPipelineDefinition -or $evidence.origin.pipelineRunId -cne $ExpectedPipelineRunId -or
        [string] $evidence.origin.producerType -cnotmatch '^(?:automated|tester-observed|specialist-observed)$' -or
        [string]::IsNullOrWhiteSpace([string] $evidence.origin.producerId) -or [string]::IsNullOrWhiteSpace([string] $evidence.origin.procedureReference)) {
        throw 'Smoke evidence rejected: EVIDENCE_ORIGIN.'
    }

    Assert-AzureDemoExactProperties $evidence.execution @('startedAtUtc', 'completedAtUtc', 'location', 'identityKind', 'correlationId', 'syntheticFixture') 'EXECUTION_SCHEMA'
    $started = [DateTimeOffset]::MinValue
    $completed = [DateTimeOffset]::MinValue
    if (-not (Test-AzureDemoUtcTimestamp ([string] $evidence.execution.startedAtUtc) ([ref] $started)) -or
        -not (Test-AzureDemoUtcTimestamp ([string] $evidence.execution.completedAtUtc) ([ref] $completed)) -or
        $completed -lt $started -or $completed -gt [DateTimeOffset]::UtcNow.AddMinutes(5) -or
        $evidence.execution.location -cne $requirement.Location -or $evidence.execution.identityKind -cne $requirement.IdentityKind -or
        [string]::IsNullOrWhiteSpace([string] $evidence.execution.correlationId) -or $evidence.execution.syntheticFixture -isnot [bool] -or $evidence.execution.syntheticFixture) {
        throw 'Smoke evidence rejected: EXECUTION_PROVENANCE.'
    }

    $assertions = @($evidence.assertions)
    $requiredAssertions = @($requirement.Assertions)
    if ($assertions.Count -ne $requiredAssertions.Count) { throw 'Smoke evidence rejected: ASSERTION_SET.' }
    $seenAssertions = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($assertion in $assertions) {
        Assert-AzureDemoExactProperties $assertion @('id', 'status', 'evidencePath', 'evidenceSha256') 'ASSERTION_SCHEMA'
        $assertionId = [string] $assertion.id
        if ($assertion.status -cne 'PASS' -or -not $seenAssertions.Add($assertionId) -or $requiredAssertions -cnotcontains $assertionId -or
            [string] $assertion.evidenceSha256 -cnotmatch '^[0-9a-f]{64}$') {
            throw 'Smoke evidence rejected: ASSERTION_RESULT.'
        }
        $attachmentPath = Join-Path $resolvedRoot ([string] $assertion.evidencePath).Replace('/', [IO.Path]::DirectorySeparatorChar)
        $resolvedAttachment = Resolve-AzureDemoArtifactPath -ArtifactRoot $resolvedRoot -Path ([IO.Path]::GetFullPath($attachmentPath)) -PathType Leaf
        if ($resolvedAttachment.Equals($resolvedEvidence, [StringComparison]::OrdinalIgnoreCase)) { throw 'Smoke evidence rejected: ASSERTION_ATTACHMENT.' }
        $attachmentHash = (Get-FileHash -LiteralPath $resolvedAttachment -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($attachmentHash -cne [string] $assertion.evidenceSha256) { throw 'Smoke evidence rejected: ASSERTION_ATTACHMENT_HASH.' }
    }
    if (@($requiredAssertions | Where-Object { -not $seenAssertions.Contains($_) }).Count -ne 0) { throw 'Smoke evidence rejected: ASSERTION_SET.' }

    if ($CheckId -eq 'SMK-19') {
        Assert-AzureDemoExactProperties $evidence.previousRelease @('sourceCommit', 'artifactManifestSha256', 'deploymentEvidenceReference', 'manifestPath', 'manifestSha256', 'rehearsalApprovalReference') 'PREVIOUS_RELEASE_SCHEMA'
        if ([string] $evidence.previousRelease.sourceCommit -cnotmatch '^[0-9a-f]{40}$' -or
            [string] $evidence.previousRelease.artifactManifestSha256 -cnotmatch '^[0-9a-f]{64}$' -or
            $evidence.previousRelease.sourceCommit -ceq $ExpectedSourceCommit -or $evidence.previousRelease.artifactManifestSha256 -ceq $ExpectedArtifactManifestSha256 -or
            [string]::IsNullOrWhiteSpace([string] $evidence.previousRelease.deploymentEvidenceReference) -or
            [string]::IsNullOrWhiteSpace([string] $evidence.previousRelease.rehearsalApprovalReference) -or
            [string] $evidence.previousRelease.manifestSha256 -cnotmatch '^[0-9a-f]{64}$') {
            throw 'Smoke evidence rejected: PREVIOUS_RELEASE_PROVENANCE.'
        }
        $previousManifestPath = Join-Path $resolvedRoot ([string] $evidence.previousRelease.manifestPath).Replace('/', [IO.Path]::DirectorySeparatorChar)
        $resolvedPreviousManifest = Resolve-AzureDemoArtifactPath -ArtifactRoot $resolvedRoot -Path ([IO.Path]::GetFullPath($previousManifestPath)) -PathType Leaf
        $previousManifestHash = (Get-FileHash -LiteralPath $resolvedPreviousManifest -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($previousManifestHash -cne [string] $evidence.previousRelease.manifestSha256 -or $previousManifestHash -cne [string] $evidence.previousRelease.artifactManifestSha256) {
            throw 'Smoke evidence rejected: PREVIOUS_RELEASE_MANIFEST_HASH.'
        }
        try { $previousManifest = Get-Content -LiteralPath $resolvedPreviousManifest -Raw | ConvertFrom-Json -ErrorAction Stop } catch { throw 'Smoke evidence rejected: PREVIOUS_RELEASE_MANIFEST_JSON.' }
        if ($previousManifest.sourceCommit -cne [string] $evidence.previousRelease.sourceCommit) { throw 'Smoke evidence rejected: PREVIOUS_RELEASE_MANIFEST_COMMIT.' }
    }
    elseif ($null -ne $evidence.previousRelease) {
        throw 'Smoke evidence rejected: UNEXPECTED_PREVIOUS_RELEASE.'
    }

    return [pscustomobject]@{
        CheckId = $CheckId
        ProducerType = [string] $evidence.origin.producerType
        ProducerId = [string] $evidence.origin.producerId
        CorrelationId = [string] $evidence.execution.correlationId
    }
}
