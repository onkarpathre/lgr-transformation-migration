[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $OutputDirectory,
    [string] $OfflineDotNetEfPath
)

$ErrorActionPreference = 'Stop'
$utilities = Join-Path $PSScriptRoot 'AzureDemoPackageUtilities.ps1'
. $utilities
$repo = (Resolve-Path (Join-Path (Join-Path $PSScriptRoot '..') '..')).ProviderPath
$output = Assert-AzureDemoRepositoryOutputPath -RepositoryPath $repo -OutputPath $OutputDirectory
New-Item -ItemType Directory -Path $output -Force | Out-Null
$apiLock = Join-Path $repo 'src/api/packages.lock.json'
$lockBackup = [IO.Path]::GetTempFileName()
Copy-Item -LiteralPath $apiLock -Destination $lockBackup -Force
$project = 'src/api/LgrTransformationMigration.Api.csproj'
$startupProject = 'src/api/LgrTransformationMigration.Api.csproj'
$dbContext = 'LgrTransformationMigration.Api.Infrastructure.AppDbContext'
Assert-EfMigrationArtifactInvocationContract -RepositoryPath $repo -Project $project -StartupProject $startupProject -DbContext $dbContext

function Invoke-CheckedEfCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Operation,
        [Parameter(Mandatory)] [string[]] $Arguments
    )

    $result = Invoke-AzureDemoNativeCommand -FilePath $ef -Arguments @($efPrefix + $Arguments)
    if ([int] $result.ExitCode -ne 0) {
        throw (Format-AzureDemoNativeCommandFailure -Operation $Operation -Result $result)
    }
    if (-not [string]::IsNullOrWhiteSpace([string] $result.StdOut)) {
        Write-Output ([string] $result.StdOut).TrimEnd()
    }
    if (-not [string]::IsNullOrWhiteSpace([string] $result.StdErr)) {
        Write-Warning ([string] $result.StdErr).TrimEnd()
    }
}

Push-Location $repo
try {
    dotnet restore LgrTransformationMigration.sln --locked-mode
    if ($LASTEXITCODE) { throw 'Locked restore failed.' }
    if ($OfflineDotNetEfPath) {
        $ef = (Resolve-Path -LiteralPath $OfflineDotNetEfPath).Path
        $efPrefix = @()
    } else {
        dotnet tool restore
        if ($LASTEXITCODE) { throw 'Pinned local tool restore failed.' }
        $ef = 'dotnet'
        $efPrefix = @('tool', 'run', 'dotnet-ef')
    }
    $efVersionResult = Invoke-AzureDemoNativeCommand -FilePath $ef -Arguments @($efPrefix + '--version')
    if ([int] $efVersionResult.ExitCode -ne 0) {
        throw (Format-AzureDemoNativeCommandFailure -Operation 'dotnet-ef version validation' -Result $efVersionResult)
    }
    if (-not [string]::IsNullOrWhiteSpace([string] $efVersionResult.StdErr)) {
        throw 'dotnet-ef version validation emitted unexpected standard-error content.'
    }
    $efVersionOutput = ([string] $efVersionResult.StdOut).Trim()
    if ($efVersionOutput -cne '10.0.11' -and
        $efVersionOutput -cne "Entity Framework Core .NET Command-line Tools`r`n10.0.11" -and
        $efVersionOutput -cne "Entity Framework Core .NET Command-line Tools`n10.0.11") {
        throw 'EF migration artifacts require exactly dotnet-ef 10.0.11.'
    }
    dotnet build $project --configuration Release --no-restore
    if ($LASTEXITCODE) { throw 'Explicit Release build for EF migration artifacts failed.' }

    $efTargetArguments = @(
        '--project', $project,
        '--startup-project', $startupProject,
        '--context', $dbContext,
        '--configuration', 'Release'
    )
    $bundle = Join-Path $output 'lgrtm-efbundle-linux-x64'
    Invoke-CheckedEfCommand -Operation 'EF migration bundle creation' -Arguments @(
        'migrations', 'bundle'
        $efTargetArguments
        '--target-runtime', 'linux-x64'
        '--output', $bundle
        '--force'
    )
    $script = Join-Path $output 'lgrtm-migrations-idempotent.sql'
    Invoke-CheckedEfCommand -Operation 'EF idempotent script creation' -Arguments @(
        'migrations', 'script'
        $efTargetArguments
        '--idempotent'
        '--output', $script
    )
    $migrationListResult = Invoke-AzureDemoNativeCommand -FilePath $ef -Arguments @(
        $efPrefix
        'migrations', 'list'
        $efTargetArguments
        '--no-build'
        '--no-connect'
        '--json'
    )
    $migrations = @(ConvertFrom-EfMigrationListNativeResult -Result $migrationListResult)
    $manifest = [ordered]@{
        schemaVersion = '1'
        sourceCommit = (git rev-parse HEAD).Trim()
        createdAtUtc = [DateTimeOffset]::UtcNow.ToString('O')
        targetRuntime = 'linux-x64'
        startupMigration = $false
        rollbackPolicy = 'forward-fix-or-approved-PITR-to-new-database'
        migrations = @($migrations | ForEach-Object { [string] $_.name })
        artifacts = @(
            [ordered]@{ name = [IO.Path]::GetFileName($bundle); sha256 = (Get-FileHash $bundle -Algorithm SHA256).Hash.ToLowerInvariant() }
            [ordered]@{ name = [IO.Path]::GetFileName($script); sha256 = (Get-FileHash $script -Algorithm SHA256).Hash.ToLowerInvariant() }
        )
    }
    $manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $output 'migration-manifest.json') -Encoding UTF8
} finally {
    Pop-Location
    Copy-Item -LiteralPath $lockBackup -Destination $apiLock -Force
    Remove-Item -LiteralPath $lockBackup -Force
}
