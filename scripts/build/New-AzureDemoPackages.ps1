[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $OutputDirectory,
    [switch] $SkipRestore,
    [switch] $SkipTests
)

$ErrorActionPreference = 'Stop'
$utilities = Join-Path $PSScriptRoot 'AzureDemoPackageUtilities.ps1'
. $utilities
$repo = (Resolve-Path (Join-Path (Join-Path $PSScriptRoot '..') '..')).ProviderPath
$output = Assert-AzureDemoRepositoryOutputPath -RepositoryPath $repo -OutputPath $OutputDirectory
$npmCommand = if ([IO.Path]::DirectorySeparatorChar -eq '\') { 'npm.cmd' } else { 'npm' }

$nodeMajor = [int]((node --version).TrimStart('v').Split('.')[0])
if ($nodeMajor -ne 24) { throw 'Azure demo web packaging requires Node.js 24.' }
$sdkMajor = [int]((dotnet --version).Split('.')[0])
if ($sdkMajor -ne 10) { throw 'Azure demo API packaging requires .NET SDK 10.' }

New-Item -ItemType Directory -Path $output -Force | Out-Null
$stage = Join-Path $output 'stage'
if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
New-Item -ItemType Directory -Path $stage -Force | Out-Null

Push-Location $repo
try {
    if (-not $SkipRestore) {
        dotnet restore LgrTransformationMigration.sln --locked-mode
        if ($LASTEXITCODE) { throw 'Locked .NET restore failed.' }
        Push-Location 'src/web'
        try { & $npmCommand ci --ignore-scripts; if ($LASTEXITCODE) { throw 'npm ci failed.' } }
        finally { Pop-Location }
    }
    if (-not $SkipTests) {
        dotnet test LgrTransformationMigration.sln --configuration Release --no-restore --logger trx
        if ($LASTEXITCODE) { throw '.NET tests failed.' }
        Push-Location 'src/web'
        try {
            & $npmCommand run lint; if ($LASTEXITCODE) { throw 'Frontend lint failed.' }
            & $npmCommand run test:component; if ($LASTEXITCODE) { throw 'Frontend tests failed.' }
        } finally { Pop-Location }
    }

    $apiStage = Join-Path $stage 'api'
    dotnet publish src/api/LgrTransformationMigration.Api.csproj --configuration Release --no-restore --no-self-contained --output $apiStage
    if ($LASTEXITCODE) { throw 'API publish failed.' }

    $forbiddenApi = Get-ChildItem -LiteralPath $apiStage -Recurse -File | Where-Object {
        $_.Name -in @('appsettings.LocalTest.json', 'appsettings.Development.json', 'appsettings.Testing.json') -or $_.Name -like '*.pfx' -or $_.Name -like '*.user'
    }
    if ($forbiddenApi) { throw "API artifact contains prohibited files: $($forbiddenApi.FullName -join ', ')" }
    $apiConfigurationFiles = @(Get-ChildItem -LiteralPath $apiStage -Recurse -File | Where-Object { $_.Extension -in @('.json', '.config') })
    $prohibitedConfiguration = @($apiConfigurationFiles | Select-String -Pattern 'TrustServerCertificate=True|Password=|Authentication.{0,4}LocalTest' -CaseSensitive:$false)
    if ($prohibitedConfiguration.Count -gt 0) {
        $matchedFiles = @($prohibitedConfiguration | ForEach-Object Path | Sort-Object -Unique)
        throw "API artifact contains a prohibited local connection or identity setting in: $($matchedFiles -join ', ')"
    }

    Push-Location 'src/web'
    try {
        $env:NODE_ENV = 'production'
        & $npmCommand run build
        if ($LASTEXITCODE) { throw 'Next.js production build failed.' }
        $webStage = Join-Path $stage 'web'
        Copy-Item -LiteralPath '.next/standalone' -Destination $webStage -Recurse
        New-Item -ItemType Directory -Path (Join-Path $webStage '.next') -Force | Out-Null
        Copy-Item -LiteralPath '.next/static' -Destination (Join-Path $webStage '.next/static') -Recurse
        if (Test-Path -LiteralPath 'public') { Copy-Item -LiteralPath 'public' -Destination (Join-Path $webStage 'public') -Recurse }
    } finally { Pop-Location }

    $webStage = Join-Path $stage 'web'
    if (-not (Test-Path -LiteralPath (Join-Path $webStage 'server.js'))) { throw 'Web standalone artifact has no root server.js.' }
    $forbiddenWeb = Get-ChildItem -LiteralPath $webStage -Recurse -File | Where-Object {
        $_.Name -like '.env*' -or $_.FullName -match '[\\/]tests?[\\/]' -or $_.Name -eq 'appsettings.LocalTest.json'
    }
    if ($forbiddenWeb) { throw "Web artifact contains prohibited files: $($forbiddenWeb.FullName -join ', ')" }

    $priorPort = $env:PORT
    $priorHostname = $env:HOSTNAME
    $priorApiOrigin = $env:API_ORIGIN
    $env:PORT = '3127'
    $env:HOSTNAME = '127.0.0.1'
    $env:API_ORIGIN = 'http://127.0.0.1:9'
    $process = $null
    try {
        $start = @{ FilePath = 'node'; ArgumentList = 'server.js'; WorkingDirectory = $webStage; PassThru = $true }
        if ($env:OS -eq 'Windows_NT') { $start.WindowStyle = 'Hidden' }
        $process = Start-Process @start
        $root = $null
        foreach ($attempt in 1..30) {
            try { $root = Invoke-WebRequest -Uri 'http://127.0.0.1:3127/' -UseBasicParsing -TimeoutSec 2; break }
            catch { Start-Sleep -Milliseconds 500 }
        }
        if ($null -eq $root -or $root.StatusCode -ne 200) { throw 'Standalone web root did not start successfully.' }
        $deep = Invoke-WebRequest -Uri 'http://127.0.0.1:3127/inventory/servers' -UseBasicParsing -TimeoutSec 10
        if ($deep.StatusCode -ne 200) { throw 'Standalone deep route did not return 200.' }
        $notFound = Invoke-WebRequest -Uri 'http://127.0.0.1:3127/__azure_demo_route_that_must_not_exist__' `
            -UseBasicParsing -SkipHttpErrorCheck -TimeoutSec 10
        if ($notFound.StatusCode -ne 404) { throw 'Standalone nonexistent route did not return 404.' }
        foreach ($page in @($root, $deep, $notFound)) {
            if ($page.Content -notmatch 'Sign in required' -or
                $page.Content -notmatch 'Restricted synthetic non-production management demo' -or
                $page.Content -match '(?i)(?:<title>\s*500\b|\bInternal Server Error\b|\bApplication Error\b)') {
                throw 'Standalone page did not retain the production authentication contract or returned generic failure content.'
            }
        }
        $cspNonceTest = Join-Path $repo 'src/web/tests/production-csp-nonce.mjs'
        & node $cspNonceTest 'http://127.0.0.1:3127'
        if ($LASTEXITCODE) { throw 'Standalone production CSP nonce regression failed.' }
        $assetPath = [regex]::Match($root.Content, '/_next/static/[^"'']+\.(?:js|css)').Value
        if (-not $assetPath) { throw 'Standalone page did not reference a hashed static asset.' }
        $asset = Invoke-WebRequest -Uri "http://127.0.0.1:3127$assetPath" -UseBasicParsing -TimeoutSec 10
        if ($asset.StatusCode -ne 200 -or $asset.RawContentLength -eq 0 -or -not $asset.Headers.'Content-Type') { throw 'Standalone static asset validation failed.' }
    } finally {
        if ($process -and -not $process.HasExited) { Stop-Process -Id $process.Id -Force }
        $env:PORT = $priorPort
        $env:HOSTNAME = $priorHostname
        $env:API_ORIGIN = $priorApiOrigin
    }

    $apiZip = Join-Path $output 'api.zip'
    $webZip = Join-Path $output 'web.zip'
    New-AzureDemoDeterministicZip -SourceDirectory $apiStage -DestinationPath $apiZip
    New-AzureDemoDeterministicZip -SourceDirectory $webStage -DestinationPath $webZip

    $manifest = [ordered]@{
        schemaVersion = '1'
        sourceCommit = (git rev-parse HEAD).Trim()
        createdAtUtc = [DateTimeOffset]::UtcNow.ToString('O')
        nodeVersion = (node --version).Trim()
        dotnetSdkVersion = (dotnet --version).Trim()
        artifacts = @(
            [ordered]@{ name = 'api.zip'; sha256 = (Get-FileHash $apiZip -Algorithm SHA256).Hash.ToLowerInvariant() }
            [ordered]@{ name = 'web.zip'; sha256 = (Get-FileHash $webZip -Algorithm SHA256).Hash.ToLowerInvariant() }
        )
    }
    $manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $output 'application-artifact-manifest.json') -Encoding UTF8
    Remove-Item -LiteralPath $stage -Recurse -Force
} finally {
    Pop-Location
}
