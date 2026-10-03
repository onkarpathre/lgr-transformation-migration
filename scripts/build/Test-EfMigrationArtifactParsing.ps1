[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path (Join-Path $PSScriptRoot '..') '..')).ProviderPath
. (Join-Path $PSScriptRoot 'AzureDemoPackageUtilities.ps1')

$project = 'src/api/LgrTransformationMigration.Api.csproj'
$context = 'LgrTransformationMigration.Api.Infrastructure.AppDbContext'
$validJson = @'
[
  {
    "id": "20260823111854_InitialCreate",
    "name": "InitialCreate",
    "safeName": "InitialCreate",
    "applied": null
  }
]
'@

function New-NativeResult {
    param(
        [int] $ExitCode = 0,
        [AllowEmptyString()] [string] $StdOut = '',
        [AllowEmptyString()] [string] $StdErr = ''
    )
    return [pscustomobject]@{ ExitCode = $ExitCode; StdOut = $StdOut; StdErr = $StdErr }
}

$passed = 0
function Assert-Accepted {
    param([string] $Name, $Result)
    $migrations = @(ConvertFrom-EfMigrationListNativeResult -Result $Result)
    if ($migrations.Count -ne 1 -or $migrations[0].name -cne 'InitialCreate') {
        throw "$Name did not return the expected validated migration."
    }
    $script:passed++
    Write-Output "PASS accepted: $Name"
}

function Assert-Rejected {
    param([string] $Name, $Result, [string] $ExpectedMessage)
    try {
        ConvertFrom-EfMigrationListNativeResult -Result $Result | Out-Null
        throw "$Name was unexpectedly accepted."
    }
    catch {
        if (-not $_.Exception.Message.Contains($ExpectedMessage)) {
            throw "$Name failed for an unexpected reason: $($_.Exception.Message)"
        }
    }
    $script:passed++
    Write-Output "PASS rejected: $Name"
}

function Assert-ContractRejected {
    param(
        [string] $Name,
        [string] $Project,
        [string] $StartupProject,
        [string] $DbContext,
        [string] $ExpectedMessage
    )
    try {
        Assert-EfMigrationArtifactInvocationContract -RepositoryPath $repo -Project $Project -StartupProject $StartupProject -DbContext $DbContext
        throw "$Name was unexpectedly accepted."
    }
    catch {
        if (-not $_.Exception.Message.Contains($ExpectedMessage)) {
            throw "$Name failed for an unexpected reason: $($_.Exception.Message)"
        }
    }
    $script:passed++
    Write-Output "PASS rejected: $Name"
}

Assert-EfMigrationArtifactInvocationContract -RepositoryPath $repo -Project $project -StartupProject $project -DbContext $context
$passed++
Write-Output 'PASS accepted: exact project, startup project and DbContext contract'

$hostExecutable = (Get-Process -Id $PID).Path
$capture = Invoke-AzureDemoNativeCommand -FilePath $hostExecutable -Arguments @(
    '-NoProfile',
    '-NonInteractive',
    '-Command',
    "[Console]::Out.Write('stdout-marker'); [Console]::Error.Write('stderr-marker'); exit 23"
)
if ($capture.ExitCode -ne 23 -or $capture.StdOut -cne 'stdout-marker' -or $capture.StdErr -cne 'stderr-marker') {
    throw 'Native process capture did not preserve stdout, stderr and exit code independently.'
}
$passed++
Write-Output 'PASS accepted: cross-platform native stdout, stderr and exit-code capture'

Assert-Accepted 'clean JSON' (New-NativeResult -StdOut $validJson)
Assert-Accepted 'observed build-message prefix' (New-NativeResult -StdOut "Build started...`nBuild succeeded.`n$validJson")
Assert-Accepted 'supported EF diagnostics' (New-NativeResult -StdOut "warn: Microsoft.EntityFrameworkCore.Model.Validation[10400]`n      Synthetic diagnostic detail.`n$validJson")
Assert-Accepted 'supported EF standard-error diagnostics' (New-NativeResult -StdOut $validJson -StdErr "info: Microsoft.EntityFrameworkCore.Infrastructure[10403]`n      Synthetic diagnostic detail.")

Assert-Rejected 'malformed JSON' (New-NativeResult -StdOut '[{"id":"one","name":"One"}') 'malformed JSON'
Assert-Rejected 'absent JSON' (New-NativeResult -StdOut 'Build succeeded.') 'no JSON document'
Assert-Rejected 'multiple JSON payloads' (New-NativeResult -StdOut "$validJson`n$validJson") 'multiple ambiguous JSON documents'
Assert-Rejected 'non-zero EF exit' (New-NativeResult -ExitCode 17 -StdOut $validJson -StdErr 'synthetic native failure') 'exit code 17'
Assert-Rejected 'empty migrations' (New-NativeResult -StdOut '[]') 'no migrations'
Assert-Rejected 'migration with empty name' (New-NativeResult -StdOut '[{"id":"20260823111854_InitialCreate","name":"","safeName":"InitialCreate","applied":null}]') 'non-empty id and name'
Assert-Rejected 'migration with non-string id' (New-NativeResult -StdOut '[{"id":20260823111854,"name":"InitialCreate","safeName":"InitialCreate","applied":null}]') 'non-empty id and name'
Assert-Rejected 'migration with unexpected JSON schema' (New-NativeResult -StdOut '[{"id":"20260823111854_InitialCreate","name":"InitialCreate","safeName":"InitialCreate","applied":null,"other":true}]') 'unexpected migration JSON schema'
Assert-Rejected 'unexpected trailing content' (New-NativeResult -StdOut "$validJson`nDone.") 'unexpected trailing content'
Assert-Rejected 'arbitrary prefix containing JSON punctuation' (New-NativeResult -StdOut "arbitrary { punctuation }`n$validJson") 'unsupported standard-output diagnostic content'
Assert-Rejected 'unsupported standard-error content' (New-NativeResult -StdOut $validJson -StdErr 'arbitrary native error') 'unsupported standard-error diagnostic content'

Assert-ContractRejected 'incorrect project' 'src/api/Other.csproj' $project $context 'project must be exactly'
Assert-ContractRejected 'incorrect startup project' $project 'src/api/Other.csproj' $context 'startup project must be exactly'
Assert-ContractRejected 'incorrect DbContext' $project $project 'OtherDbContext' 'DbContext must be exactly'

if ($passed -ne 20) {
    throw "EF migration artifact parsing regression executed $passed checks; expected 20."
}
Write-Output 'EF migration artifact parsing regression passed 20 fail-closed checks.'
