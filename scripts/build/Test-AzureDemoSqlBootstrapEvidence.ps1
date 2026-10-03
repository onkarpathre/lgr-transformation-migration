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

function Invoke-TestGit([string[]] $Arguments) {
    $output = @(& git -C $repository @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Test Git setup failed: $($Arguments -join ' ')."
    }
    return @($output | ForEach-Object { [string] $_ })
}

function New-TestCommit([string] $Content, [string] $Message) {
    Set-Content -LiteralPath (Join-Path $repository 'history.txt') -Value $Content -Encoding UTF8
    Invoke-TestGit @('add', 'history.txt') | Out-Null
    Invoke-TestGit @('commit', '-m', $Message) | Out-Null
    $commitOutput = @(Invoke-TestGit @('rev-parse', 'HEAD'))
    return $commitOutput[0].Trim()
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
        recordedAtUtc = [DateTimeOffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')
        grantsScriptSha256 = (Get-FileHash -LiteralPath $grantsScript -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    foreach ($key in $Overrides.Keys) { $evidence[$key] = $Overrides[$key] }
    $evidence | ConvertTo-Json | Set-Content -LiteralPath $evidencePath -Encoding UTF8
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

function Assert-Rejected([string] $Name, [string] $SourceCommit, [string] $ExpectedReleaseCommit, [hashtable] $Overrides = @{}, [string] $GitExecutablePath = 'git') {
    Write-Evidence $SourceCommit $Overrides
    try {
        Invoke-Guard $ExpectedReleaseCommit $GitExecutablePath
    }
    catch {
        $script:rejectedCount++
        return
    }
    throw "SQL bootstrap evidence guard accepted invalid case '$Name'."
}

New-Item -ItemType Directory -Path $repository -Force | Out-Null
try {
    & git init --quiet $repository
    if ($LASTEXITCODE -ne 0) { throw 'Could not create the isolated Git evidence-test repository.' }
    Invoke-TestGit @('config', 'user.email', 'sql-evidence@example.invalid') | Out-Null
    Invoke-TestGit @('config', 'user.name', 'SQL Evidence Regression') | Out-Null
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
    Assert-Accepted 'valid evidence inside age limit' $ancestorCommit $releaseCommit @{ recordedAtUtc = [DateTimeOffset]::UtcNow.AddDays(-89).ToString('yyyy-MM-ddTHH:mm:ssZ') }

    Assert-Rejected 'unrelated commit' $unrelatedCommit $releaseCommit
    Assert-Rejected 'descendant evidence commit' $descendantCommit $releaseCommit
    Assert-Rejected 'malformed evidence commit' 'not-a-commit' $releaseCommit
    Assert-Rejected 'uppercase evidence commit' $ancestorCommit.ToUpperInvariant() $releaseCommit
    Assert-Rejected 'missing evidence commit object' ('f' * 40) $releaseCommit
    Assert-Rejected 'wrong schema version' $ancestorCommit $releaseCommit @{ schemaVersion = '2' }
    Assert-Rejected 'non-PASS status' $ancestorCommit $releaseCommit @{ status = 'PENDING' }
    Assert-Rejected 'wrong SQL server' $ancestorCommit $releaseCommit @{ sqlServerFqdn = 'sql-other.database.windows.net' }
    Assert-Rejected 'wrong database' $ancestorCommit $releaseCommit @{ databaseName = 'sqldb-other' }
    Assert-Rejected 'wrong migration identity name' $ancestorCommit $releaseCommit @{ migrationPrincipalName = 'id-other' }
    Assert-Rejected 'wrong migration client ID' $ancestorCommit $releaseCommit @{ migrationPrincipalClientId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' }
    Assert-Rejected 'wrong migration object ID' $ancestorCommit $releaseCommit @{ migrationPrincipalObjectId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc' }
    Assert-Rejected 'wrong executor object ID' $ancestorCommit $releaseCommit @{ executorPrincipalObjectId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd' }
    Assert-Rejected 'empty evidence ID' $ancestorCommit $releaseCommit @{ evidenceId = ' ' }
    Assert-Rejected 'empty approval reference' $ancestorCommit $releaseCommit @{ approvalReference = '' }
    Assert-Rejected 'expired evidence' $ancestorCommit $releaseCommit @{ recordedAtUtc = [DateTimeOffset]::UtcNow.AddDays(-91).ToString('yyyy-MM-ddTHH:mm:ssZ') }
    Assert-Rejected 'future evidence' $ancestorCommit $releaseCommit @{ recordedAtUtc = [DateTimeOffset]::UtcNow.AddMinutes(6).ToString('yyyy-MM-ddTHH:mm:ssZ') }
    Assert-Rejected 'malformed timestamp' $ancestorCommit $releaseCommit @{ recordedAtUtc = 'not-a-timestamp' }
    Assert-Rejected 'timezone-ambiguous timestamp' $ancestorCommit $releaseCommit @{ recordedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss') }

    $approvedGrantsHash = (Get-FileHash -LiteralPath $grantsScript -Algorithm SHA256).Hash.ToLowerInvariant()
    Assert-Rejected 'uppercase grants hash' $ancestorCommit $releaseCommit @{ grantsScriptSha256 = $approvedGrantsHash.ToUpperInvariant() }
    Add-Content -LiteralPath $grantsScript -Value '-- changed permission contract'
    Assert-Rejected 'changed grants hash' $ancestorCommit $releaseCommit @{ grantsScriptSha256 = $approvedGrantsHash }
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
    Assert-Rejected 'Git command failure' $ancestorCommit $releaseCommit @{} $failingGit
    Assert-Rejected 'missing Git executable' $ancestorCommit $releaseCommit @{} (Join-Path $temporaryDirectory 'missing-git')

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
        Assert-Rejected 'shallow or incomplete history' $shallowHead $shallowHead
    }
    finally {
        $repository = $completeRepository
    }
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
}

Write-Output "Azure demo durable SQL bootstrap evidence guard passed $acceptedCount accepted and $rejectedCount fail-closed cases."
