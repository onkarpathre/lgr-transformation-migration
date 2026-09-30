[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $OutputDirectory,
    [string] $OfflineDotNetEfPath
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$output = [IO.Path]::GetFullPath($OutputDirectory)
if (-not $output.StartsWith($repo + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'OutputDirectory must be within the repository workspace.'
}
New-Item -ItemType Directory -Path $output -Force | Out-Null
$apiLock = Join-Path $repo 'src/api/packages.lock.json'
$lockBackup = [IO.Path]::GetTempFileName()
Copy-Item -LiteralPath $apiLock -Destination $lockBackup -Force

Push-Location $repo
try {
    dotnet restore LgrTransformationMigration.sln --locked-mode
    if ($LASTEXITCODE) { throw 'Locked restore failed.' }
    if ($OfflineDotNetEfPath) {
        $ef = (Resolve-Path -LiteralPath $OfflineDotNetEfPath).Path
    } else {
        dotnet tool restore
        if ($LASTEXITCODE) { throw 'Pinned local tool restore failed.' }
        $ef = 'dotnet'
    }
    $bundle = Join-Path $output 'lgrtm-efbundle-linux-x64'
    if ($OfflineDotNetEfPath) {
        & $ef migrations bundle --project src/api/LgrTransformationMigration.Api.csproj --configuration Release --target-runtime linux-x64 --output $bundle --force
    } else {
        & $ef tool run dotnet-ef migrations bundle --project src/api/LgrTransformationMigration.Api.csproj --configuration Release --target-runtime linux-x64 --output $bundle --force
    }
    if ($LASTEXITCODE) { throw 'EF migration bundle creation failed.' }
    $script = Join-Path $output 'lgrtm-migrations-idempotent.sql'
    if ($OfflineDotNetEfPath) {
        & $ef migrations script --project src/api/LgrTransformationMigration.Api.csproj --configuration Release --idempotent --output $script
    } else {
        & $ef tool run dotnet-ef migrations script --project src/api/LgrTransformationMigration.Api.csproj --configuration Release --idempotent --output $script
    }
    if ($LASTEXITCODE) { throw 'EF idempotent script creation failed.' }
    if ($OfflineDotNetEfPath) {
        $migrationJson = & $ef migrations list --project src/api/LgrTransformationMigration.Api.csproj --configuration Release --no-connect --json
    } else {
        $migrationJson = & $ef tool run dotnet-ef migrations list --project src/api/LgrTransformationMigration.Api.csproj --configuration Release --no-connect --json
    }
    $migrations = $migrationJson | ConvertFrom-Json
    if ($LASTEXITCODE) { throw 'EF migration enumeration failed.' }
    $manifest = [ordered]@{
        schemaVersion = '1'
        sourceCommit = (git rev-parse HEAD).Trim()
        createdAtUtc = [DateTimeOffset]::UtcNow.ToString('O')
        targetRuntime = 'linux-x64'
        startupMigration = $false
        rollbackPolicy = 'forward-fix-or-approved-PITR-to-new-database'
        migrations = @($migrations | ForEach-Object { $_.name })
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
