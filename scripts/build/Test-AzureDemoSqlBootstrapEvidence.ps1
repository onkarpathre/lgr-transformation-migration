[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$guard = Join-Path $PSScriptRoot '..\database\Assert-AzureDemoSqlBootstrapEvidence.ps1'
$sourceGrantsScript = Join-Path $PSScriptRoot '..\database\Configure-AzureDemoDatabasePrincipals.sql'
$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-bootstrap-evidence-{0}" -f [Guid]::NewGuid().ToString('N'))
$repository = Join-Path $temporaryDirectory 'repository'
$evidencePath = Join-Path $temporaryDirectory 'sql-bootstrap.json'
$grantsScript = Join-Path $temporaryDirectory 'Configure-AzureDemoDatabasePrincipals.sql'
$executorObjectId = [Guid] 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
$acceptedCount = 0
$rejectedCount = 0
$isWindowsPlatform = [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT
$invariantCulture = [Globalization.CultureInfo]::InvariantCulture
$utf8NoBom = New-Object Text.UTF8Encoding($false)
$metadataFailurePrefix = 'Independent SQL bootstrap evidence rejected: '
$observedMetadataReasons = @{}
$requiredMetadataReasons = @(
    'METADATA_SCHEMA_VERSION',
    'METADATA_STATUS',
    'METADATA_SOURCE_COMMIT_FORMAT',
    'METADATA_SQL_SERVER',
    'METADATA_DATABASE',
    'METADATA_MIGRATION_IDENTITY_NAME',
    'METADATA_MIGRATION_CLIENT_ID',
    'METADATA_MIGRATION_OBJECT_ID',
    'METADATA_EXECUTOR_OBJECT_ID_FORMAT',
    'METADATA_EXECUTOR_OBJECT_ID_MISMATCH',
    'METADATA_EVIDENCE_ID',
    'METADATA_APPROVAL_REFERENCE',
    'METADATA_UTC_TIMESTAMP_SYNTAX',
    'METADATA_FUTURE_TIMESTAMP',
    'METADATA_EXPIRED_TIMESTAMP',
    'METADATA_GRANTS_HASH_FORMAT',
    'METADATA_GRANTS_HASH_MISMATCH'
)

function Invoke-TestGit([string[]] $Arguments) {
    $output = @(& git -C $repository @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Test Git setup failed: $($Arguments -join ' ')."
    }
    return @($output | ForEach-Object { [string] $_ })
}

function New-TestCommit([string] $Content, [string] $Message) {
    [IO.File]::WriteAllText((Join-Path $repository 'history.txt'), "$Content`n", $utf8NoBom)
    Invoke-TestGit @('add', 'history.txt') | Out-Null
    Invoke-TestGit @('commit', '-m', $Message) | Out-Null
    $commitOutput = @(Invoke-TestGit @('rev-parse', 'HEAD'))
    return $commitOutput[0].Trim()
}

function Format-TestTimestamp([DateTimeOffset] $Timestamp, [int] $FractionalDigits = 7) {
    $format = if ($FractionalDigits -eq 0) {
        "yyyy-MM-dd'T'HH:mm:ss'Z'"
    }
    else {
        "yyyy-MM-dd'T'HH:mm:ss.$('f' * $FractionalDigits)'Z'"
    }
    return $Timestamp.ToUniversalTime().ToString($format, $invariantCulture)
}

function Write-Evidence([string] $SourceCommit, [hashtable] $Overrides = @{}) {
    $evidence = [ordered]@{
        schemaVersion = '1'
        status = 'PASS'
        sourceCommit = $SourceCommit
        sqlServerFqdn = 'sql-mtp-dev-uks-001.database.windows.net'
        databaseName = 'sqldb-mtp-dev-uks-001'
        migrationPrincipalName = 'id-mtp-migration-dev-uks-001'
        migrationPrincipalClientId = 'f77b1931-0954-4ae9-8f6b-de5f9cfdb2e7'
        migrationPrincipalObjectId = '9b984b84-7ebe-45ca-9441-7b2f41fd8f6c'
        executorPrincipalObjectId = $executorObjectId.ToString()
        evidenceId = 'SYNTHETIC-DBA-EVIDENCE'
        approvalReference = 'SYNTHETIC-DBA-APPROVAL'
        recordedAtUtc = Format-TestTimestamp ([DateTimeOffset]::UtcNow)
        grantsScriptSha256 = (Get-FileHash -LiteralPath $grantsScript -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    foreach ($key in $Overrides.Keys) { $evidence[$key] = $Overrides[$key] }
    $evidenceJson = ($evidence | ConvertTo-Json) -replace "`r`n", "`n"
    [IO.File]::WriteAllText($evidencePath, $evidenceJson, $utf8NoBom)
}

function Invoke-Guard([string] $ExpectedReleaseCommit, [string] $GitExecutablePath = 'git') {
    & $guard -EvidencePath $evidencePath -ExpectedReleaseCommit $ExpectedReleaseCommit -RepositoryRoot $repository -GrantsScriptPath $grantsScript -ExpectedExecutorPrincipalObjectId $executorObjectId -MaximumEvidenceAgeDays 90 -GitExecutablePath $GitExecutablePath | Out-Null
}

function Assert-Accepted([string] $Name, [string] $SourceCommit, [string] $ExpectedReleaseCommit, [hashtable] $Overrides = @{}) {
    Write-Evidence $SourceCommit $Overrides
    try {
        Invoke-Guard $ExpectedReleaseCommit
        $script:acceptedCount++
    }
    catch {
        throw "Expected accepted SQL bootstrap evidence case '$Name' failed: $($_.Exception.Message)"
    }
}

function Assert-SafeFailure([string] $Name, [string] $ActualMessage, [string] $ExpectedMessage, [hashtable] $Overrides) {
    $protectedValues = @(
        'SYNTHETIC-DBA-EVIDENCE',
        'SYNTHETIC-DBA-APPROVAL',
        'sql-mtp-dev-uks-001.database.windows.net',
        'sqldb-mtp-dev-uks-001',
        'id-mtp-migration-dev-uks-001',
        'f77b1931-0954-4ae9-8f6b-de5f9cfdb2e7',
        '9b984b84-7ebe-45ca-9441-7b2f41fd8f6c',
        $executorObjectId.ToString()
    )
    foreach ($overrideValue in $Overrides.Values) {
        if ($null -ne $overrideValue -and -not [string]::IsNullOrWhiteSpace([string] $overrideValue)) {
            $protectedValues += [string] $overrideValue
        }
    }
    foreach ($protectedValue in $protectedValues) {
        if ($ActualMessage.Contains($protectedValue)) {
            throw "Rejected SQL bootstrap evidence case '$Name' leaked protected fixture material."
        }
    }

    if (-not [string]::Equals($ActualMessage, $ExpectedMessage, [StringComparison]::Ordinal)) {
        throw "Rejected SQL bootstrap evidence case '$Name' returned an unexpected safe category; expected '$ExpectedMessage'."
    }

    if ($ActualMessage.StartsWith($metadataFailurePrefix, [StringComparison]::Ordinal)) {
        $reason = $ActualMessage.Substring($metadataFailurePrefix.Length).TrimEnd('.')
        if ($reason.StartsWith('METADATA_', [StringComparison]::Ordinal)) {
            $script:observedMetadataReasons[$reason] = $true
        }
    }
}

function Assert-Rejected(
    [string] $Name,
    [string] $SourceCommit,
    [string] $ExpectedReleaseCommit,
    [string] $ExpectedMessage,
    [hashtable] $Overrides = @{},
    [string] $GitExecutablePath = 'git'
) {
    Write-Evidence $SourceCommit $Overrides
    Assert-CurrentEvidenceRejected $Name $ExpectedReleaseCommit $ExpectedMessage $Overrides $GitExecutablePath
}

function Assert-CurrentEvidenceRejected(
    [string] $Name,
    [string] $ExpectedReleaseCommit,
    [string] $ExpectedMessage,
    [hashtable] $ProtectedOverrides = @{},
    [string] $GitExecutablePath = 'git'
) {
    $actualMessage = $null
    try {
        Invoke-Guard $ExpectedReleaseCommit $GitExecutablePath
    }
    catch {
        $actualMessage = $_.Exception.Message
    }
    if ($null -eq $actualMessage) {
        throw "SQL bootstrap evidence guard accepted invalid case '$Name'."
    }
    Assert-SafeFailure $Name $actualMessage $ExpectedMessage $ProtectedOverrides
    $script:rejectedCount++
}

New-Item -ItemType Directory -Path $repository -Force | Out-Null
try {
    & git init --quiet $repository
    if ($LASTEXITCODE -ne 0) { throw 'Could not create the isolated Git evidence-test repository.' }
    Invoke-TestGit @('config', 'user.email', 'sql-evidence@example.invalid') | Out-Null
    Invoke-TestGit @('config', 'user.name', 'SQL Evidence Regression') | Out-Null
    Invoke-TestGit @('config', 'core.autocrlf', 'false') | Out-Null
    $ancestorCommit = New-TestCommit 'ancestor' 'ancestor bootstrap'
    $releaseCommit = New-TestCommit 'release' 'descendant release'

    Invoke-TestGit @('checkout', '--quiet', '-b', 'unrelated', $ancestorCommit) | Out-Null
    $unrelatedCommit = New-TestCommit 'unrelated' 'unrelated evidence'
    Invoke-TestGit @('checkout', '--quiet', '--detach', $releaseCommit) | Out-Null
    Invoke-TestGit @('branch', '-D', 'unrelated') | Out-Null
    Invoke-TestGit @('checkout', '--quiet', '-b', 'descendant') | Out-Null
    $descendantCommit = New-TestCommit 'descendant' 'future evidence'
    Invoke-TestGit @('checkout', '--quiet', '--detach', $releaseCommit) | Out-Null
    Invoke-TestGit @('branch', '-D', 'descendant') | Out-Null

    Copy-Item -LiteralPath $sourceGrantsScript -Destination $grantsScript

    Assert-Accepted 'evidence commit equals release commit' $releaseCommit $releaseCommit
    Assert-Accepted 'evidence commit is an ancestor' $ancestorCommit $releaseCommit
    Assert-Accepted 'current schema and unchanged grants hash' $ancestorCommit $releaseCommit
    Assert-Accepted 'valid evidence inside age limit' $ancestorCommit $releaseCommit @{ recordedAtUtc = Format-TestTimestamp ([DateTimeOffset]::UtcNow.AddDays(-89)) 0 }
    foreach ($fractionalDigits in 1..6) {
        Assert-Accepted "UTC timestamp with $fractionalDigits fractional digits" $ancestorCommit $releaseCommit @{
            recordedAtUtc = Format-TestTimestamp ([DateTimeOffset]::UtcNow) $fractionalDigits
        }
    }

    Assert-Rejected 'unrelated commit' $unrelatedCommit $releaseCommit 'The SQL bootstrap evidence provenance commit is not an ancestor of the expected release commit.'
    Assert-Rejected 'descendant evidence commit' $descendantCommit $releaseCommit 'The SQL bootstrap evidence provenance commit is not an ancestor of the expected release commit.'
    Assert-Rejected 'malformed evidence commit' 'not-a-commit' $releaseCommit ($metadataFailurePrefix + 'METADATA_SOURCE_COMMIT_FORMAT.')
    Assert-Rejected 'uppercase evidence commit' $ancestorCommit.ToUpperInvariant() $releaseCommit ($metadataFailurePrefix + 'METADATA_SOURCE_COMMIT_FORMAT.')
    Assert-Rejected 'missing evidence commit object' ('f' * 40) $releaseCommit 'The SQL bootstrap evidence provenance commit is missing from the checked-out repository.'
    Assert-Rejected 'checked-out HEAD differs from expected release' $ancestorCommit $ancestorCommit 'The checked-out repository HEAD does not match the immutable expected release commit.'
    Assert-Rejected 'wrong schema version' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_SCHEMA_VERSION.') @{ schemaVersion = '2' }
    Assert-Rejected 'non-PASS status' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_STATUS.') @{ status = 'PENDING' }
    Assert-Rejected 'wrong SQL server' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_SQL_SERVER.') @{ sqlServerFqdn = 'sql-other.database.windows.net' }
    Assert-Rejected 'wrong database' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_DATABASE.') @{ databaseName = 'sqldb-other' }
    Assert-Rejected 'wrong migration identity name' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_MIGRATION_IDENTITY_NAME.') @{ migrationPrincipalName = 'id-other' }
    Assert-Rejected 'wrong migration client ID' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_MIGRATION_CLIENT_ID.') @{ migrationPrincipalClientId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' }
    Assert-Rejected 'wrong migration object ID' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_MIGRATION_OBJECT_ID.') @{ migrationPrincipalObjectId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc' }
    Assert-Rejected 'empty executor object ID' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_EXECUTOR_OBJECT_ID_FORMAT.') @{ executorPrincipalObjectId = '' }
    Assert-Rejected 'malformed executor object ID' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_EXECUTOR_OBJECT_ID_FORMAT.') @{ executorPrincipalObjectId = 'not-a-guid' }
    Assert-Rejected 'empty GUID executor object ID' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_EXECUTOR_OBJECT_ID_FORMAT.') @{ executorPrincipalObjectId = [Guid]::Empty.ToString() }
    Assert-Rejected 'wrong executor object ID' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_EXECUTOR_OBJECT_ID_MISMATCH.') @{ executorPrincipalObjectId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd' }
    Assert-Rejected 'empty evidence ID' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_EVIDENCE_ID.') @{ evidenceId = ' ' }
    Assert-Rejected 'empty approval reference' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_APPROVAL_REFERENCE.') @{ approvalReference = '' }
    Assert-Rejected 'expired evidence' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_EXPIRED_TIMESTAMP.') @{ recordedAtUtc = Format-TestTimestamp ([DateTimeOffset]::UtcNow.AddDays(-91)) 0 }
    Assert-Rejected 'future evidence' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_FUTURE_TIMESTAMP.') @{ recordedAtUtc = Format-TestTimestamp ([DateTimeOffset]::UtcNow.AddMinutes(6)) 0 }
    Assert-Rejected 'malformed timestamp' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_UTC_TIMESTAMP_SYNTAX.') @{ recordedAtUtc = 'not-a-timestamp' }
    Assert-Rejected 'timezone-ambiguous timestamp' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_UTC_TIMESTAMP_SYNTAX.') @{ recordedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss', $invariantCulture) }
    Assert-Rejected 'offset timestamp' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_UTC_TIMESTAMP_SYNTAX.') @{ recordedAtUtc = [DateTimeOffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:sszzz', $invariantCulture) }
    Assert-Rejected 'timestamp with eight fractional digits' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_UTC_TIMESTAMP_SYNTAX.') @{ recordedAtUtc = '2026-10-03T12:00:00.12345678Z' }

    $approvedGrantsHash = (Get-FileHash -LiteralPath $grantsScript -Algorithm SHA256).Hash.ToLowerInvariant()
    Assert-Rejected 'uppercase grants hash' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_GRANTS_HASH_FORMAT.') @{ grantsScriptSha256 = $approvedGrantsHash.ToUpperInvariant() }
    Assert-Rejected 'malformed grants hash' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_GRANTS_HASH_FORMAT.') @{ grantsScriptSha256 = 'not-a-sha256' }
    Add-Content -LiteralPath $grantsScript -Value '-- changed permission contract'
    Assert-Rejected 'changed grants hash' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_GRANTS_HASH_MISMATCH.') @{ grantsScriptSha256 = $approvedGrantsHash }
    Copy-Item -LiteralPath $sourceGrantsScript -Destination $grantsScript -Force

    if ($isWindowsPlatform) {
        $failingGit = Join-Path $temporaryDirectory 'git-failure.cmd'
        Set-Content -LiteralPath $failingGit -Value '@exit /b 2' -Encoding ASCII
    }
    else {
        $failingGit = Join-Path $temporaryDirectory 'git-failure'
        Set-Content -LiteralPath $failingGit -Value "#!/bin/sh`nexit 2" -Encoding UTF8
        & chmod 700 -- $failingGit
        if ($LASTEXITCODE -ne 0) { throw 'Could not permission the synthetic failing Git executable.' }
    }
    Assert-Rejected 'Git command failure' $ancestorCommit $releaseCommit 'SQL bootstrap evidence ancestry validation requires a complete checked-out Git repository.' @{} $failingGit
    Assert-Rejected 'missing Git executable' $ancestorCommit $releaseCommit 'SQL bootstrap evidence ancestry validation requires an available native Git executable.' @{} (Join-Path $temporaryDirectory 'missing-git')

    [IO.File]::WriteAllText($evidencePath, '{ invalid evidence JSON', $utf8NoBom)
    Assert-CurrentEvidenceRejected 'malformed evidence JSON' $releaseCommit ($metadataFailurePrefix + 'EVIDENCE_JSON_SYNTAX.')
    Remove-Item -LiteralPath $evidencePath -Force
    Assert-CurrentEvidenceRejected 'missing evidence file' $releaseCommit ($metadataFailurePrefix + 'EVIDENCE_FILE_UNAVAILABLE.')

    $completeRepository = $repository
    $shallowRepository = Join-Path $temporaryDirectory 'shallow-repository'
    $repositoryUri = 'file:///' + ($completeRepository.Replace('\', '/'))
    & git clone --quiet --depth 1 $repositoryUri $shallowRepository
    if ($LASTEXITCODE -ne 0) { throw 'Could not create the isolated shallow Git evidence-test repository.' }
    try {
        $repository = $shallowRepository
        $shallowHeadOutput = @(& git -C $repository rev-parse HEAD)
        if ($LASTEXITCODE -ne 0) { throw 'Could not resolve the shallow evidence-test repository HEAD.' }
        $shallowHead = $shallowHeadOutput[0].Trim()
        Assert-Rejected 'shallow or incomplete history' $shallowHead $shallowHead 'SQL bootstrap evidence ancestry validation rejects shallow or incomplete repository history.'
    }
    finally {
        $repository = $completeRepository
    }

    $missingMetadataReasons = @($requiredMetadataReasons | Where-Object { -not $observedMetadataReasons.ContainsKey($_) })
    $unexpectedMetadataReasons = @($observedMetadataReasons.Keys | Where-Object { $_ -notin $requiredMetadataReasons })
    if ($missingMetadataReasons.Count -ne 0 -or $unexpectedMetadataReasons.Count -ne 0) {
        throw "Metadata-rejection coverage is incomplete or unexpected. Missing=$($missingMetadataReasons -join ','); Unexpected=$($unexpectedMetadataReasons -join ',')."
    }
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
}

Write-Output "Azure demo durable SQL bootstrap evidence guard passed $acceptedCount accepted and $rejectedCount fail-closed cases across $($requiredMetadataReasons.Count) safe metadata-rejection categories."
