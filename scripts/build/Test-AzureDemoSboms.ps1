[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$generator = Join-Path $PSScriptRoot 'New-AzureDemoSboms.ps1'
$output = Join-Path $repo 'artifacts\azure-demo-ci\sbom'
$generatorText = Get-Content -LiteralPath $generator -Raw

$prohibitedReferences = @(
    ('System.Web' + '.Extensions'),
    ('JavaScript' + 'Serializer')
)
foreach ($reference in $prohibitedReferences) {
    if ($generatorText.Contains($reference)) {
        throw "The SBOM generator retains the prohibited cross-platform reference: $reference"
    }
}
if (-not $generatorText.Contains('ConvertFrom-Json') -or -not $generatorText.Contains('ConvertTo-Json -Depth 8')) {
    throw 'The SBOM generator must use native PowerShell JSON processing with an explicit serialization depth.'
}
if (-not $generatorText.Contains("`$parameters.Depth = 100") -or -not $generatorText.Contains("`$parameters.AsHashtable = `$true")) {
    throw 'The SBOM generator must set an adequate PowerShell 7 deserialization depth and support JSON object keys losslessly.'
}

function ConvertFrom-JsonDocument([string] $Content) {
    $parameters = @{ InputObject = $Content }
    if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey('Depth')) {
        $parameters.Depth = 100
    }
    ConvertFrom-Json @parameters
}

function Assert-Bom([object] $Bom, [string] $ExpectedName, [string] $ExpectedCommit, [int] $ExpectedComponentCount, [string] $Path) {
    if ($Bom.bomFormat -ne 'CycloneDX' -or $Bom.specVersion -ne '1.5' -or $Bom.version -ne 1) {
        throw "$Path does not retain the approved CycloneDX schema fields."
    }
    if ($Bom.serialNumber -notmatch '^urn:uuid:[0-9a-fA-F-]{36}$') {
        throw "$Path does not contain a valid UUID serial number."
    }
    $parsedTimestamp = [DateTimeOffset]::MinValue
    if (-not [DateTimeOffset]::TryParse([string]$Bom.metadata.timestamp, [ref]$parsedTimestamp)) {
        throw "$Path does not contain a valid metadata timestamp."
    }
    if ($Bom.metadata.component.type -ne 'application' -or $Bom.metadata.component.name -ne $ExpectedName -or $Bom.metadata.component.version -ne $ExpectedCommit) {
        throw "$Path does not contain the required application metadata."
    }
    $components = @($Bom.components)
    if ($components.Count -ne $ExpectedComponentCount) {
        throw "$Path contains $($components.Count) components; expected the locked baseline total $ExpectedComponentCount."
    }
    foreach ($component in $components) {
        if ($component.type -ne 'library' -or [string]::IsNullOrWhiteSpace([string]$component.name) -or
            [string]::IsNullOrWhiteSpace([string]$component.version) -or [string]::IsNullOrWhiteSpace([string]$component.purl)) {
            throw "$Path contains a dependency without the required type, name, version or purl."
        }
    }
    $ordered = @($components | Sort-Object name, version -Unique)
    if (($components | ConvertTo-Json -Depth 4 -Compress) -ne ($ordered | ConvertTo-Json -Depth 4 -Compress)) {
        throw "$Path dependency components are not uniquely and deterministically ordered."
    }
}

function Assert-ComponentVersion([object] $Bom, [string] $Name, [string] $Version, [string] $PackageType) {
    $expectedPurl = "pkg:$PackageType/$([uri]::EscapeDataString($Name))@$([uri]::EscapeDataString($Version))"
    $matches = @($Bom.components | Where-Object { $_.name -eq $Name -and $_.version -eq $Version -and $_.purl -eq $expectedPurl })
    if ($matches.Count -ne 1) {
        throw "The SBOM does not contain exactly one locked $Name $Version component with purl $expectedPurl."
    }
}

& $generator -OutputDirectory $output
$expectedOutputPrefix = [IO.Path]::GetFullPath($output) + [IO.Path]::DirectorySeparatorChar
$webPath = [IO.Path]::GetFullPath((Join-Path $output 'web.cdx.json'))
$apiPath = [IO.Path]::GetFullPath((Join-Path $output 'api.cdx.json'))
foreach ($path in @($webPath, $apiPath)) {
    if (-not $path.StartsWith($expectedOutputPrefix, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "The expected SBOM was not generated inside artifacts/azure-demo-ci/sbom: $path"
    }
}

$commit = (git -C $repo rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0) { throw 'The expected SBOM commit could not be resolved.' }
$firstWebText = Get-Content -LiteralPath $webPath -Raw
$firstApiText = Get-Content -LiteralPath $apiPath -Raw
$firstWeb = ConvertFrom-JsonDocument $firstWebText
$firstApi = ConvertFrom-JsonDocument $firstApiText
Assert-Bom $firstWeb 'lgr-transformation-migration-web' $commit 522 $webPath
Assert-Bom $firstApi 'lgr-transformation-migration-api' $commit 107 $apiPath
Assert-ComponentVersion $firstWeb '@vitest/mocker' '4.1.11' 'npm'
Assert-ComponentVersion $firstWeb 'next' '16.3.8' 'npm'
Assert-ComponentVersion $firstWeb 'react' '19.2.8' 'npm'
Assert-ComponentVersion $firstWeb 'typescript' '5.9.3' 'npm'
Assert-ComponentVersion $firstApi 'Azure.Identity' '1.17.1' 'nuget'
Assert-ComponentVersion $firstApi 'Microsoft.EntityFrameworkCore.Design' '10.0.11' 'nuget'
Assert-ComponentVersion $firstApi 'Microsoft.EntityFrameworkCore.SqlServer' '10.0.11' 'nuget'

& $generator -OutputDirectory $output
$secondWeb = ConvertFrom-JsonDocument (Get-Content -LiteralPath $webPath -Raw)
$secondApi = ConvertFrom-JsonDocument (Get-Content -LiteralPath $apiPath -Raw)
Assert-Bom $secondWeb 'lgr-transformation-migration-web' $commit 522 $webPath
Assert-Bom $secondApi 'lgr-transformation-migration-api' $commit 107 $apiPath
foreach ($pair in @(@($firstWeb, $secondWeb), @($firstApi, $secondApi))) {
    if ($pair[0].serialNumber -ne $pair[1].serialNumber) {
        throw 'Repeated SBOM generation changed the deterministic serial number.'
    }
    if (($pair[0].components | ConvertTo-Json -Depth 4 -Compress) -ne ($pair[1].components | ConvertTo-Json -Depth 4 -Compress)) {
        throw 'Repeated SBOM generation changed dependency content or ordering.'
    }
}

$outsideRepository = Join-Path ([IO.Path]::GetTempPath()) "lgr-sbom-outside-$([guid]::NewGuid().ToString('N'))"
$outsideRejected = $false
try {
    & $generator -OutputDirectory $outsideRepository
}
catch {
    if ($_.Exception.Message -notlike '*must be within the repository workspace*') { throw }
    $outsideRejected = $true
}
if (-not $outsideRejected) { throw 'The SBOM generator accepted an output directory outside the repository.' }
if (Test-Path -LiteralPath $outsideRepository) { throw 'The rejected outside-repository output directory was created.' }

Write-Output "Azure demo SBOM regression passed for $(@($secondApi.components).Count) API and $(@($secondWeb.components).Count) web components; timestamps are intentionally generated evidence metadata."
