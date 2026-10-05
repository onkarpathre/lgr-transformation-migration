[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')] [string] $Configuration = 'Release',
    [switch] $NoBuild
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).ProviderPath
$project = Join-Path $repo 'src/api/LgrTransformationMigration.Api.csproj'
$projectAssets = Join-Path $repo 'src/api/obj/project.assets.json'
$toolManifest = Get-Content -LiteralPath (Join-Path $repo '.config/dotnet-tools.json') -Raw | ConvertFrom-Json
$toolVersion = [string] $toolManifest.tools.'dotnet-ef'.version
if ([string]::IsNullOrWhiteSpace($toolVersion) -or -not (Test-Path -LiteralPath $projectAssets -PathType Leaf)) {
    throw 'The pinned EF tool and restored API project assets are required before migration-context validation.'
}
$assets = Get-Content -LiteralPath $projectAssets -Raw | ConvertFrom-Json
$packageRoot = @($assets.packageFolders.psobject.Properties.Name)[0]
$dotnetEf = Join-Path $packageRoot "dotnet-ef/$toolVersion/tools/net8.0/any/dotnet-ef.dll"
if (-not (Test-Path -LiteralPath $dotnetEf -PathType Leaf)) {
    $toolHomes = @($env:DOTNET_CLI_HOME, $env:USERPROFILE, [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Select-Object -Unique
    $resolvedTool = $null
    foreach ($toolHome in $toolHomes) {
        $resolverCache = Join-Path $toolHome '.dotnet/toolResolverCache/1/dotnet-ef'
        if (-not (Test-Path -LiteralPath $resolverCache -PathType Leaf)) {
            continue
        }
        $resolvedTool = @(Get-Content -LiteralPath $resolverCache -Raw | ConvertFrom-Json |
            Where-Object { $_.Version -ceq $toolVersion -and (Test-Path -LiteralPath $_.PathToExecutable -PathType Leaf) } |
            Select-Object -First 1)[0]
        if ($null -ne $resolvedTool) {
            $dotnetEf = [string] $resolvedTool.PathToExecutable
            break
        }
    }
    if ($null -eq $resolvedTool) {
        throw "The pinned dotnet-ef $toolVersion tool is not restored."
    }
}
$temporaryRoot = Join-Path $repo "artifacts/ef-context-creation-$([Guid]::NewGuid().ToString('N'))"
$savedLocation = Get-Location
$environmentNames = @('DOTNET_ENVIRONMENT', 'ASPNETCORE_ENVIRONMENT', 'Authentication__Mode')
$savedEnvironment = @{}
foreach ($name in $environmentNames) {
    $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, [EnvironmentVariableTarget]::Process)
}

$environmentCases = @(
    [pscustomobject]@{ Name = 'unset'; DotNet = $null; AspNetCore = $null; Authentication = $null },
    [pscustomobject]@{ Name = 'Development LocalTest'; DotNet = 'Development'; AspNetCore = 'Development'; Authentication = 'LocalTest' },
    [pscustomobject]@{ Name = 'Testing LocalTest'; DotNet = 'Testing'; AspNetCore = 'Testing'; Authentication = 'LocalTest' },
    [pscustomobject]@{ Name = 'accidental LocalTest environment'; DotNet = 'LocalTest'; AspNetCore = 'LocalTest'; Authentication = 'LocalTest' }
)
$expectedMigrations = @(
    '20260823111854_InitialCreate',
    '20260824181918_AddDiscoveryImport',
    '20260909164944_AddSqlInventory',
    '20260910082037_AddInternalPrincipalAuditType',
    '20260915171019_AddSqlDiscoveryImportHistory',
    '20260916121802_EnforceDiscoveryImportRowTenantBatchOwnership',
    '20260917001712_AddSqlAssessments',
    '20260922151243_AddDependencyRegister'
)

try {
    New-Item -ItemType Directory -Path $temporaryRoot -ErrorAction Stop | Out-Null
    if (@(Get-ChildItem -LiteralPath $temporaryRoot -Force).Count -ne 0) {
        throw 'The EF migration context regression working directory is not empty.'
    }

    Set-Location $temporaryRoot
    foreach ($case in $environmentCases) {
        [Environment]::SetEnvironmentVariable('DOTNET_ENVIRONMENT', $case.DotNet, [EnvironmentVariableTarget]::Process)
        [Environment]::SetEnvironmentVariable('ASPNETCORE_ENVIRONMENT', $case.AspNetCore, [EnvironmentVariableTarget]::Process)
        [Environment]::SetEnvironmentVariable('Authentication__Mode', $case.Authentication, [EnvironmentVariableTarget]::Process)

        $arguments = @(
            $dotnetEf,
            'migrations', 'list',
            '--project', $project,
            '--startup-project', $project,
            '--context', 'LgrTransformationMigration.Api.Infrastructure.AppDbContext',
            '--configuration', $Configuration,
            '--no-connect',
            '--verbose'
        )
        if ($NoBuild) {
            $arguments += '--no-build'
        }

        $savedErrorPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $output = @(& dotnet @arguments 2>&1)
            $exitCode = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $savedErrorPreference
        }
        $diagnostic = ($output | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
        if ($exitCode -ne 0) {
            throw "EF migration context creation failed for $($case.Name) with exit code $exitCode. $diagnostic"
        }
        foreach ($migration in $expectedMigrations) {
            if ($diagnostic.IndexOf($migration, [StringComparison]::Ordinal) -lt 0) {
                throw "EF migration context creation did not discover $migration for $($case.Name)."
            }
        }
        if ($diagnostic.IndexOf("Using DbContext factory 'MigrationDbContextFactory'.", [StringComparison]::Ordinal) -lt 0) {
            throw "EF migration context creation did not select the dedicated factory for $($case.Name)."
        }
        if ($diagnostic.IndexOf('appsettings.LocalTest.json', [StringComparison]::OrdinalIgnoreCase) -ge 0 -or
            $diagnostic.IndexOf('Unable to create a DbContext', [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            throw "EF migration context creation entered web-host configuration for $($case.Name)."
        }
        if (@(Get-ChildItem -LiteralPath $temporaryRoot -Force).Count -ne 0) {
            throw "EF migration context creation wrote into its configuration-free working directory for $($case.Name)."
        }
    }
}
finally {
    Set-Location $savedLocation
    foreach ($name in $environmentNames) {
        [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name], [EnvironmentVariableTarget]::Process)
    }
    $artifactsRoot = [IO.Path]::GetFullPath((Join-Path $repo 'artifacts')).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $resolvedTemporaryRoot = [IO.Path]::GetFullPath($temporaryRoot)
    $requiredPrefix = $artifactsRoot + [IO.Path]::DirectorySeparatorChar
    if (-not $resolvedTemporaryRoot.StartsWith($requiredPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The EF migration context regression refused unsafe temporary-directory cleanup.'
    }
    if (Test-Path -LiteralPath $resolvedTemporaryRoot) {
        Remove-Item -LiteralPath $resolvedTemporaryRoot -Recurse -Force
    }
}

Write-Output 'EF migration context creation passed from an empty working directory for unset, Development, Testing and accidental LocalTest environments without database access.'
