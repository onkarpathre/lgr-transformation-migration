[CmdletBinding()]
param([Parameter(Mandatory)] [string] $ArtifactDirectory)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ArtifactDirectory).Path
$manifestPath = Join-Path $root 'application-artifact-manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath)) { throw 'Application artifact manifest is missing.' }
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
foreach ($artifact in $manifest.artifacts) {
    $path = Join-Path $root $artifact.name
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing artifact $($artifact.name)." }
    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $artifact.sha256) { throw "Hash mismatch for $($artifact.name)." }
}

$scan = Join-Path $root 'scan'
if (Test-Path -LiteralPath $scan) { Remove-Item -LiteralPath $scan -Recurse -Force }
New-Item -ItemType Directory -Path $scan -Force | Out-Null
try {
    foreach ($name in @('api.zip', 'web.zip')) {
        $target = Join-Path $scan ([IO.Path]::GetFileNameWithoutExtension($name))
        Expand-Archive -LiteralPath (Join-Path $root $name) -DestinationPath $target
    }
    if (-not (Test-Path -LiteralPath (Join-Path $scan 'api/LgrTransformationMigration.Api.dll'))) { throw 'API DLL is not at ZIP root.' }
    if (-not (Test-Path -LiteralPath (Join-Path $scan 'web/server.js'))) { throw 'Web server.js is not at ZIP root.' }
    $forbidden = Get-ChildItem -LiteralPath $scan -Recurse -File | Where-Object {
        $_.Name -in @('appsettings.LocalTest.json', 'appsettings.Development.json', 'appsettings.Testing.json') -or $_.Name -like '.env*' -or $_.Name -like '*.pfx' -or $_.Name -like '*.publishsettings'
    }
    if ($forbidden) { throw "Prohibited artifact content: $($forbidden.FullName -join ', ')" }
    $configurationFiles = @(Get-ChildItem -LiteralPath $scan -Recurse -File | Where-Object { $_.Extension -in @('.json', '.config') })
    $prohibitedConfiguration = @($configurationFiles | Select-String -Pattern 'TrustServerCertificate=True|Password=|Authentication.{0,4}LocalTest' -CaseSensitive:$false)
    if ($prohibitedConfiguration.Count -gt 0) {
        $matchedFiles = @($prohibitedConfiguration | ForEach-Object Path | Sort-Object -Unique)
        throw "Artifact contains a prohibited local connection or identity setting in: $($matchedFiles -join ', ')"
    }
}
finally {
    if (Test-Path -LiteralPath $scan) { Remove-Item -LiteralPath $scan -Recurse -Force }
}
Write-Output 'Azure demo application artifacts passed hash, root-layout and prohibited-file checks.'
