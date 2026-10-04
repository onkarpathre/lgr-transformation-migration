[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$guard = Join-Path $PSScriptRoot '..\database\Assert-AzureDemoSqlBootstrapEvidence.ps1'
$resolver = Join-Path $PSScriptRoot '..\database\Resolve-NativeApplicationExecutablePath.ps1'
$sourceGrantsScript = Join-Path $PSScriptRoot '..\database\Configure-AzureDemoDatabasePrincipals.sql'
$guardSource = Get-Content -LiteralPath $guard -Raw
$resolverSource = Get-Content -LiteralPath $resolver -Raw
. $resolver
$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-bootstrap-evidence-{0}" -f [Guid]::NewGuid().ToString('N'))
$repository = Join-Path $temporaryDirectory 'repository'
$evidencePath = Join-Path $temporaryDirectory 'sql-bootstrap.json'
$grantsScript = Join-Path $temporaryDirectory 'Configure-AzureDemoDatabasePrincipals.sql'
$executorObjectId = [Guid] 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
$acceptedCount = 0
$rejectedCount = 0
$executableResolutionCount = 0
$cultureExecutionCount = 0
$isWindowsPlatform = [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT
$invariantCulture = [Globalization.CultureInfo]::InvariantCulture
$utf8NoBom = New-Object Text.UTF8Encoding($false)
$metadataFailurePrefix = 'Independent SQL bootstrap evidence rejected: '
$observedMetadataReasons = @{}
$expectedErrorActionPreference = $ErrorActionPreference
$nativeErrorPreference = Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue
$nativeErrorPreferenceSupported = $null -ne $nativeErrorPreference
$previousNativeErrorPreference = if ($nativeErrorPreferenceSupported) { $nativeErrorPreference.Value } else { $null }
$expectedNativeErrorPreference = $true
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

foreach ($fragment in @(
        '$timestampPropertyMatches = [regex]::Matches(',
        '$timestampTokenMatches = [regex]::Matches(',
        '$evidenceJson,',
        '[DateTimeOffset]::TryParseExact(',
        '[Globalization.CultureInfo]::InvariantCulture',
        '[Globalization.DateTimeStyles]::AssumeUniversal',
        '[Globalization.DateTimeStyles]::AdjustToUniversal',
        '$recordedAt.Offset -ne [TimeSpan]::Zero')) {
    if (-not $guardSource.Contains($fragment)) {
        throw "SQL bootstrap evidence guard is missing raw UTC timestamp contract fragment: $fragment"
    }
}
if ($guardSource -match "Get-EvidencePropertyValue\s+\`$evidence\s+'recordedAtUtc'") {
    throw 'SQL bootstrap evidence guard must not validate the materialised recordedAtUtc value returned by ConvertFrom-Json.'
}

foreach ($fragment in @(
        '$gitCandidates = @(Get-Command',
        '$resolvedGitExecutable = [string] (Resolve-NativeApplicationExecutablePath -Candidates $gitCandidates)',
        'PSNativeCommandUseErrorActionPreference',
        '$exitCode = $LASTEXITCODE',
        '[GIT_EXECUTABLE_UNAVAILABLE]',
        '[GIT_PROCESS_START_FAILED]',
        '[GIT_EXIT_1]',
        '[GIT_EXIT_NONZERO]')) {
    if (-not $guardSource.Contains($fragment)) {
        throw "SQL bootstrap evidence guard is missing native-Git contract fragment: $fragment"
    }
}
if ($guardSource -match '\$git\.Source') {
    throw 'SQL bootstrap evidence guard must invoke ApplicationInfo.Path rather than ApplicationInfo.Source.'
}

if ($guardSource -match '&\s+\$gitCandidates') {
    throw 'SQL bootstrap evidence guard must never pass an ApplicationInfo candidate array to the call operator.'
}
foreach ($fragment in @(
        '$candidate -is [System.Management.Automation.ApplicationInfo]',
        '$validCandidates[0].Path',
        '[string] $selectedPath',
        'Test-Path -LiteralPath $selectedPath -PathType Leaf',
        '[GIT_EXECUTABLE_RESOLUTION_INVALID]')) {
    if (-not $resolverSource.Contains($fragment)) {
        throw "Native-application resolver is missing its scalar first-candidate contract: $fragment"
    }
}
if ($resolverSource -match '(?im)(?:-join|\[string\]::Join)') {
    throw 'Native-application resolver must never join executable candidate paths.'
}

$nativeGitCandidates = @(Get-Command -Name git -CommandType Application -ErrorAction Stop)
[string] $nativeGitPath = [string] (Resolve-NativeApplicationExecutablePath -Candidates $nativeGitCandidates)

if ($nativeErrorPreferenceSupported) {
    Set-Variable -Name PSNativeCommandUseErrorActionPreference -Value $expectedNativeErrorPreference -Scope Script
}

function Invoke-TestGit([string[]] $Arguments) {
    $output = @(& $nativeGitPath -C $repository @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Test Git setup failed: $($Arguments -join ' ')."
    }
    return @($output | ForEach-Object { [string] $_ })
}

function Assert-ResolvedCandidatePath([string] $Name, [object[]] $Candidates, [string] $ExpectedPath) {
    $actualPath = Resolve-NativeApplicationExecutablePath -Candidates $Candidates
    if ($actualPath -isnot [string]) {
        throw "Native-application resolution case '$Name' did not return one scalar string."
    }
    if (-not [string]::Equals($actualPath, $ExpectedPath, [StringComparison]::Ordinal)) {
        throw "Native-application resolution case '$Name' did not preserve first-valid-candidate order."
    }

    $candidatePaths = @($Candidates | Where-Object { $_ -is [System.Management.Automation.ApplicationInfo] } | ForEach-Object { [string] $_.Path })
    if ($candidatePaths.Count -gt 1 -and
        [string]::Equals($actualPath, ($candidatePaths -join ' '), [StringComparison]::Ordinal)) {
        throw "Native-application resolution case '$Name' space-joined candidate paths."
    }
    $script:executableResolutionCount++
}

function Assert-InvalidCandidateResolution([string] $Name, [object[]] $Candidates) {
    $actualMessage = $null
    try {
        Resolve-NativeApplicationExecutablePath -Candidates $Candidates | Out-Null
    }
    catch {
        $actualMessage = $_.Exception.Message
    }
    $expectedMessage = 'SQL bootstrap evidence native Git executable resolution was invalid. [GIT_EXECUTABLE_RESOLUTION_INVALID]'
    if (-not [string]::Equals($actualMessage, $expectedMessage, [StringComparison]::Ordinal)) {
        throw "Native-application resolution case '$Name' did not fail with the safe invalid-resolution category."
    }
    $script:executableResolutionCount++
}

function Assert-PreferenceRestoration([string] $Name) {
    if ($ErrorActionPreference -ne $expectedErrorActionPreference) {
        throw "SQL bootstrap evidence case '$Name' did not restore ErrorActionPreference."
    }
    if ($nativeErrorPreferenceSupported) {
        $currentNativeErrorPreference = (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction Stop).Value
        if ($currentNativeErrorPreference -ne $expectedNativeErrorPreference) {
            throw "SQL bootstrap evidence case '$Name' did not restore PSNativeCommandUseErrorActionPreference."
        }
    }
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

function Format-CanonicalEvidenceTimestamp([DateTimeOffset] $Timestamp) {
    return $Timestamp.ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss.fffffff'Z'", $invariantCulture)
}

function Invoke-AcceptedCaseInCulture(
    [string] $CultureName,
    [string] $SourceCommit,
    [string] $ExpectedReleaseCommit
) {
    $originalCulture = [Threading.Thread]::CurrentThread.CurrentCulture
    $originalUiCulture = [Threading.Thread]::CurrentThread.CurrentUICulture
    try {
        $culture = [Globalization.CultureInfo]::GetCultureInfo($CultureName)
        [Threading.Thread]::CurrentThread.CurrentCulture = $culture
        [Threading.Thread]::CurrentThread.CurrentUICulture = $culture
        Assert-Accepted "canonical UTC timestamp under $CultureName" $SourceCommit $ExpectedReleaseCommit
        $script:cultureExecutionCount++
    }
    finally {
        [Threading.Thread]::CurrentThread.CurrentCulture = $originalCulture
        [Threading.Thread]::CurrentThread.CurrentUICulture = $originalUiCulture
    }
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
        recordedAtUtc = Format-CanonicalEvidenceTimestamp ([DateTimeOffset]::UtcNow)
        grantsScriptSha256 = (Get-FileHash -LiteralPath $grantsScript -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    foreach ($key in $Overrides.Keys) { $evidence[$key] = $Overrides[$key] }
    $evidenceJson = ($evidence | ConvertTo-Json) -replace "`r`n", "`n"
    [IO.File]::WriteAllText($evidencePath, $evidenceJson, $utf8NoBom)
}

function Invoke-Guard([string] $ExpectedReleaseCommit, [string] $GitExecutablePath = 'git') {
    & $guard -EvidencePath $evidencePath -ExpectedReleaseCommit $ExpectedReleaseCommit -RepositoryRoot $repository -GrantsScriptPath $grantsScript -ExpectedExecutorPrincipalObjectId $executorObjectId -MaximumEvidenceAgeDays 90 -GitExecutablePath $GitExecutablePath | Out-Null
}

function Assert-Accepted(
    [string] $Name,
    [string] $SourceCommit,
    [string] $ExpectedReleaseCommit,
    [hashtable] $Overrides = @{},
    [string] $GitExecutablePath = 'git'
) {
    Write-Evidence $SourceCommit $Overrides
    try {
        Invoke-Guard $ExpectedReleaseCommit $GitExecutablePath
        $script:acceptedCount++
    }
    catch {
        throw "Expected accepted SQL bootstrap evidence case '$Name' failed: $($_.Exception.Message)"
    }
    Assert-PreferenceRestoration $Name
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
    Assert-PreferenceRestoration $Name
    $script:rejectedCount++
}

New-Item -ItemType Directory -Path $repository -Force | Out-Null
try {
    & $nativeGitPath init --quiet $repository
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

    $spacedExecutableDirectory = Join-Path $temporaryDirectory 'native Git path with spaces'
    New-Item -ItemType Directory -Path $spacedExecutableDirectory -Force | Out-Null
    if ($isWindowsPlatform) {
        # Git for Windows is normally installed below Program Files, so use the
        # real native path without a batch wrapper that would consume the caret
        # in revision expressions such as HEAD^{commit}.
        $spacedGitExecutable = $nativeGitPath
        $alternateGitExecutable = Join-Path $spacedExecutableDirectory 'git candidate.cmd'
        [IO.File]::WriteAllText($alternateGitExecutable, "@exit /b 0`r`n", [Text.Encoding]::ASCII)
    }
    else {
        $spacedGitExecutable = Join-Path $spacedExecutableDirectory 'git wrapper'
        [IO.File]::WriteAllText($spacedGitExecutable, "#!/bin/sh`nexec `"$nativeGitPath`" `"`$@`"`n", $utf8NoBom)
        & chmod 700 -- $spacedGitExecutable
        if ($LASTEXITCODE -ne 0) { throw 'Could not permission the synthetic Git executable with spaces.' }
        $alternateGitExecutable = $spacedGitExecutable
    }

    $nativeGitApplication = @(Get-Command -Name $nativeGitPath -CommandType Application -ErrorAction Stop)[0]
    $alternateGitApplication = @(Get-Command -Name $alternateGitExecutable -CommandType Application -ErrorAction Stop)[0]
    Assert-ResolvedCandidatePath 'one Git candidate' @($nativeGitApplication) $nativeGitPath
    Assert-ResolvedCandidatePath 'two Git candidates select the first native path' @($nativeGitApplication, $alternateGitApplication) $nativeGitPath
    Assert-ResolvedCandidatePath 'two Git candidates preserve reversed order' @($alternateGitApplication, $nativeGitApplication) $alternateGitExecutable
    Assert-ResolvedCandidatePath 'non-ApplicationInfo candidate is filtered' @([pscustomobject] @{ Path = $alternateGitExecutable }, $nativeGitApplication) $nativeGitPath

    $staleCandidateExecutable = if ($isWindowsPlatform) {
        Join-Path $temporaryDirectory 'stale-git-candidate.cmd'
    }
    else {
        Join-Path $temporaryDirectory 'stale-git-candidate'
    }
    if ($isWindowsPlatform) {
        [IO.File]::WriteAllText($staleCandidateExecutable, "@exit /b 0`r`n", [Text.Encoding]::ASCII)
    }
    else {
        [IO.File]::WriteAllText($staleCandidateExecutable, "#!/bin/sh`nexit 0`n", $utf8NoBom)
        & chmod 700 -- $staleCandidateExecutable
        if ($LASTEXITCODE -ne 0) { throw 'Could not permission the stale synthetic Git candidate.' }
    }
    $staleGitApplication = @(Get-Command -Name $staleCandidateExecutable -CommandType Application -ErrorAction Stop)[0]
    Remove-Item -LiteralPath $staleCandidateExecutable -Force
    Assert-InvalidCandidateResolution 'resolved executable path no longer names a file' @($staleGitApplication)

    Assert-Accepted 'evidence commit equals release commit through ApplicationInfo.Path' $releaseCommit $releaseCommit @{} $nativeGitPath
    Assert-Accepted 'evidence commit is an ancestor through executable path containing spaces' $ancestorCommit $releaseCommit @{} $spacedGitExecutable
    Assert-Accepted 'current schema and unchanged grants hash' $ancestorCommit $releaseCommit
    Assert-Accepted 'valid evidence inside age limit' $ancestorCommit $releaseCommit @{ recordedAtUtc = Format-TestTimestamp ([DateTimeOffset]::UtcNow.AddDays(-89)) 0 }
    Assert-Accepted 'literal Z without fractional seconds' $ancestorCommit $releaseCommit @{
        recordedAtUtc = [DateTimeOffset]::UtcNow.ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", $invariantCulture)
    }
    Assert-Accepted 'literal Z with seven fractional digits' $ancestorCommit $releaseCommit @{
        recordedAtUtc = [DateTimeOffset]::UtcNow.ToString("yyyy-MM-dd'T'HH:mm:ss.fffffff'Z'", $invariantCulture)
    }
    Assert-Accepted 'explicit zero offset without fractional seconds' $ancestorCommit $releaseCommit @{
        recordedAtUtc = [DateTimeOffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:sszzz', $invariantCulture)
    }
    Assert-Accepted 'explicit zero offset with seven fractional digits' $ancestorCommit $releaseCommit @{
        recordedAtUtc = [DateTimeOffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffzzz', $invariantCulture)
    }
    Assert-Accepted 'real protected evidence explicit UTC timestamp shape' $ancestorCommit $releaseCommit @{
        recordedAtUtc = '2026-10-03T00:59:16.7133881+00:00'
    }
    Assert-Accepted 'DateTimeOffset round-trip producer output' $ancestorCommit $releaseCommit @{
        recordedAtUtc = [DateTimeOffset]::UtcNow.ToString('O', $invariantCulture)
    }
    foreach ($fractionalDigits in 1..7) {
        $timestamp = [DateTimeOffset]::UtcNow
        Assert-Accepted "literal Z UTC timestamp with $fractionalDigits fractional digits" $ancestorCommit $releaseCommit @{
            recordedAtUtc = Format-TestTimestamp $timestamp $fractionalDigits
        }
        Assert-Accepted "explicit zero offset UTC timestamp with $fractionalDigits fractional digits" $ancestorCommit $releaseCommit @{
            recordedAtUtc = $timestamp.ToString("yyyy-MM-dd'T'HH:mm:ss.$('f' * $fractionalDigits)zzz", $invariantCulture)
        }
    }
    foreach ($cultureName in @('en-US', 'ar-SA', 'th-TH')) {
        Invoke-AcceptedCaseInCulture $cultureName $ancestorCommit $releaseCommit
    }

    Assert-Rejected 'unrelated commit' $unrelatedCommit $releaseCommit 'The SQL bootstrap evidence provenance commit is not an ancestor of the expected release commit. [GIT_EXIT_1]'
    Assert-Rejected 'descendant evidence commit' $descendantCommit $releaseCommit 'The SQL bootstrap evidence provenance commit is not an ancestor of the expected release commit. [GIT_EXIT_1]'
    Assert-Rejected 'malformed evidence commit' 'not-a-commit' $releaseCommit ($metadataFailurePrefix + 'METADATA_SOURCE_COMMIT_FORMAT.')
    Assert-Rejected 'uppercase evidence commit' $ancestorCommit.ToUpperInvariant() $releaseCommit ($metadataFailurePrefix + 'METADATA_SOURCE_COMMIT_FORMAT.')
    Assert-Rejected 'missing evidence commit object' ('f' * 40) $releaseCommit 'The SQL bootstrap evidence provenance commit is missing from the checked-out repository. [GIT_EXIT_NONZERO]'
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
    Assert-Rejected 'positive non-zero offset timestamp' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_UTC_TIMESTAMP_SYNTAX.') @{ recordedAtUtc = '2026-10-03T12:00:00+01:00' }
    Assert-Rejected 'negative offset timestamp' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_UTC_TIMESTAMP_SYNTAX.') @{ recordedAtUtc = '2026-10-03T12:00:00-01:00' }
    Assert-Rejected 'non-zero half-hour offset timestamp' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_UTC_TIMESTAMP_SYNTAX.') @{ recordedAtUtc = '2026-10-03T12:00:00+05:30' }
    Assert-Rejected 'malformed offset timestamp' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_UTC_TIMESTAMP_SYNTAX.') @{ recordedAtUtc = '2026-10-03T12:00:00+0000' }
    Assert-Rejected 'lowercase z timestamp' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_UTC_TIMESTAMP_SYNTAX.') @{ recordedAtUtc = '2026-10-03T12:00:00z' }
    Assert-Rejected 'timestamp with eight fractional digits' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_UTC_TIMESTAMP_SYNTAX.') @{ recordedAtUtc = '2026-10-03T12:00:00.12345678Z' }
    Assert-Rejected 'timestamp with leading whitespace' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_UTC_TIMESTAMP_SYNTAX.') @{ recordedAtUtc = ' 2026-10-03T12:00:00Z' }
    Assert-Rejected 'timestamp with trailing whitespace' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_UTC_TIMESTAMP_SYNTAX.') @{ recordedAtUtc = '2026-10-03T12:00:00Z ' }
    Assert-Rejected 'malformed calendar date' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_UTC_TIMESTAMP_SYNTAX.') @{ recordedAtUtc = '2026-02-30T12:00:00Z' }
    Assert-Rejected 'malformed clock time' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_UTC_TIMESTAMP_SYNTAX.') @{ recordedAtUtc = '2026-10-03T24:00:00Z' }
    Assert-Rejected 'locale-specific timestamp' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_UTC_TIMESTAMP_SYNTAX.') @{ recordedAtUtc = '03/10/2026 12:00:00 +00:00' }

    Write-Evidence $ancestorCommit @{ recordedAtUtc = '2026-10-03T12:00:00+00:00' }
    $escapedTimestampJson = [IO.File]::ReadAllText($evidencePath).Replace('+00:00', '+00\u003a00')
    [IO.File]::WriteAllText($evidencePath, $escapedTimestampJson, $utf8NoBom)
    Assert-CurrentEvidenceRejected 'raw timestamp token changed by JSON materialisation' $releaseCommit ($metadataFailurePrefix + 'METADATA_UTC_TIMESTAMP_SYNTAX.') @{ recordedAtUtc = '2026-10-03T12:00:00+00:00' }

    $approvedGrantsHash = (Get-FileHash -LiteralPath $grantsScript -Algorithm SHA256).Hash.ToLowerInvariant()
    Assert-Rejected 'uppercase grants hash' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_GRANTS_HASH_FORMAT.') @{ grantsScriptSha256 = $approvedGrantsHash.ToUpperInvariant() }
    Assert-Rejected 'malformed grants hash' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_GRANTS_HASH_FORMAT.') @{ grantsScriptSha256 = 'not-a-sha256' }
    Add-Content -LiteralPath $grantsScript -Value '-- changed permission contract'
    Assert-Rejected 'changed grants hash' $ancestorCommit $releaseCommit ($metadataFailurePrefix + 'METADATA_GRANTS_HASH_MISMATCH.') @{ grantsScriptSha256 = $approvedGrantsHash }
    Copy-Item -LiteralPath $sourceGrantsScript -Destination $grantsScript -Force

    if ($isWindowsPlatform) {
        $exitOneGit = Join-Path $temporaryDirectory 'git-exit-one.cmd'
        $exitTwoGit = Join-Path $temporaryDirectory 'git-exit-two.cmd'
        [IO.File]::WriteAllText($exitOneGit, "@exit /b 1`r`n", [Text.Encoding]::ASCII)
        [IO.File]::WriteAllText($exitTwoGit, "@exit /b 2`r`n", [Text.Encoding]::ASCII)
        $invalidExecutable = Join-Path $temporaryDirectory 'git-invalid.exe'
        [IO.File]::WriteAllBytes($invalidExecutable, [byte[]] @(0, 1, 2, 3))
    }
    else {
        $exitOneGit = Join-Path $temporaryDirectory 'git-exit-one'
        $exitTwoGit = Join-Path $temporaryDirectory 'git-exit-two'
        $invalidExecutable = Join-Path $temporaryDirectory 'git-invalid'
        [IO.File]::WriteAllText($exitOneGit, "#!/bin/sh`nexit 1`n", $utf8NoBom)
        [IO.File]::WriteAllText($exitTwoGit, "#!/bin/sh`nexit 2`n", $utf8NoBom)
        [IO.File]::WriteAllText($invalidExecutable, "#!/definitely-missing-sql-evidence-interpreter`n", $utf8NoBom)
        & chmod 700 -- $exitOneGit $exitTwoGit $invalidExecutable
        if ($LASTEXITCODE -ne 0) { throw 'Could not permission the synthetic Git executables.' }
    }
    Assert-Rejected 'Git command returns exit 1' $ancestorCommit $releaseCommit 'SQL bootstrap evidence ancestry validation requires a complete checked-out Git repository. [GIT_EXIT_1]' @{} $exitOneGit
    Assert-Rejected 'Git command returns exit 2' $ancestorCommit $releaseCommit 'SQL bootstrap evidence ancestry validation requires a complete checked-out Git repository. [GIT_EXIT_NONZERO]' @{} $exitTwoGit
    Assert-Rejected 'Git process cannot start' $ancestorCommit $releaseCommit 'SQL bootstrap evidence Git process could not be started. [GIT_PROCESS_START_FAILED]' @{} $invalidExecutable
    Assert-Rejected 'missing Git executable' $ancestorCommit $releaseCommit 'SQL bootstrap evidence ancestry validation requires an available native Git executable. [GIT_EXECUTABLE_UNAVAILABLE]' @{} (Join-Path $temporaryDirectory 'missing-git')

    [IO.File]::WriteAllText($evidencePath, '{ invalid evidence JSON', $utf8NoBom)
    Assert-CurrentEvidenceRejected 'malformed evidence JSON' $releaseCommit ($metadataFailurePrefix + 'EVIDENCE_JSON_SYNTAX.')
    Remove-Item -LiteralPath $evidencePath -Force
    Assert-CurrentEvidenceRejected 'missing evidence file' $releaseCommit ($metadataFailurePrefix + 'EVIDENCE_FILE_UNAVAILABLE.')

    $completeRepository = $repository
    $shallowRepository = Join-Path $temporaryDirectory 'shallow-repository'
    $repositoryUri = 'file:///' + ($completeRepository.Replace('\', '/'))
    & $nativeGitPath clone --quiet --depth 1 $repositoryUri $shallowRepository
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
    if ($nativeErrorPreferenceSupported) {
        Set-Variable -Name PSNativeCommandUseErrorActionPreference -Value $previousNativeErrorPreference -Scope Script
    }
    if (Test-Path -LiteralPath $temporaryDirectory) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
}

Write-Output "Azure demo durable SQL bootstrap evidence guard passed $acceptedCount accepted, $rejectedCount fail-closed, $executableResolutionCount executable-resolution and $cultureExecutionCount culture-execution cases across $($requiredMetadataReasons.Count) safe metadata-rejection categories."
