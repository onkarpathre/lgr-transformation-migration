[CmdletBinding()]
param([Parameter(Mandatory)] [string] $OutputDirectory)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$output = [IO.Path]::GetFullPath($OutputDirectory)
$pathComparison = if ([IO.Path]::DirectorySeparatorChar -eq '\') { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
if (-not $output.StartsWith($repo + [IO.Path]::DirectorySeparatorChar, $pathComparison)) {
    throw 'OutputDirectory must be within the repository workspace.'
}
New-Item -ItemType Directory -Path $output -Force | Out-Null

function ConvertFrom-JsonDocument([string] $Content) {
    $parameters = @{ InputObject = $Content }
    $convertFromJson = Get-Command ConvertFrom-Json
    if ($convertFromJson.Parameters.ContainsKey('Depth')) {
        $parameters.Depth = 100
    }
    if ($convertFromJson.Parameters.ContainsKey('AsHashtable')) {
        $parameters.AsHashtable = $true
    }
    else {
        $Content = [regex]::Replace($Content, '(?<=[{,])(?<space>\s*)""(?<colon>\s*:)', '${space}"__lgr_empty_json_property__"${colon}')
        $parameters.InputObject = $Content
    }
    ConvertFrom-Json @parameters
}

function Get-JsonPropertyValue([object] $Object, [string] $Name) {
    if ($null -eq $Object) { return $null }
    if ($Object -is [Collections.IDictionary]) { return $Object[$Name] }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    $property.Value
}

function Get-JsonObjectEntries([object] $Object, [string] $Description) {
    if ($null -eq $Object) { throw "$Description was not present in its locked dependency document." }
    if ($Object -is [Collections.IDictionary]) {
        return @($Object.GetEnumerator() | ForEach-Object {
            $key = if ($_.Key -eq '__lgr_empty_json_property__') { '' } else { $_.Key }
            [pscustomobject]@{ Key = $key; Value = $_.Value }
        })
    }
    @($Object.PSObject.Properties | ForEach-Object {
        $key = if ($_.Name -eq '__lgr_empty_json_property__') { '' } else { $_.Name }
        [pscustomobject]@{ Key = $key; Value = $_.Value }
    })
}

$commit = (git -C $repo rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($commit)) {
    throw 'The repository commit could not be resolved for SBOM metadata.'
}

function Get-DeterministicSerialNumber([string] $Name) {
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes("$Name|$commit"))
    }
    finally {
        $sha256.Dispose()
    }
    $guidBytes = [byte[]]::new(16)
    [Array]::Copy($hash, $guidBytes, $guidBytes.Length)
    $guidBytes[7] = ($guidBytes[7] -band 0x0f) -bor 0x50
    $guidBytes[8] = ($guidBytes[8] -band 0x3f) -bor 0x80
    "urn:uuid:$([guid]::new($guidBytes).ToString())"
}

function New-Bom([string] $Name, [array] $Components) {
    [pscustomobject][ordered]@{
        bomFormat = 'CycloneDX'
        specVersion = '1.5'
        serialNumber = Get-DeterministicSerialNumber $Name
        version = 1
        metadata = [ordered]@{
            timestamp = [DateTimeOffset]::UtcNow.ToString('O')
            component = [ordered]@{ type = 'application'; name = $Name; version = $commit }
        }
        components = $Components
    }
}

$lock = ConvertFrom-JsonDocument (Get-Content -LiteralPath (Join-Path $repo 'src/web/package-lock.json') -Raw)
$packages = Get-JsonPropertyValue $lock 'packages'
$npmComponents = foreach ($entry in Get-JsonObjectEntries $packages 'The package-lock packages object' | Where-Object Key) {
    $name = ($entry.Key -replace '^.*node_modules/', '')
    $version = [string](Get-JsonPropertyValue $entry.Value 'version')
    if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($version)) { continue }
    [pscustomobject][ordered]@{
        type = 'library'
        name = $name
        version = $version
        purl = "pkg:npm/$([uri]::EscapeDataString($name))@$([uri]::EscapeDataString($version))"
    }
}
$npmComponents = @($npmComponents | Sort-Object name, version -Unique)
if ($npmComponents.Count -eq 0) { throw 'No locked npm dependencies were available for the web SBOM.' }
(New-Bom 'lgr-transformation-migration-web' $npmComponents) | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $output 'web.cdx.json') -Encoding UTF8

$nuget = [Collections.Generic.Dictionary[string, object]]::new([StringComparer]::OrdinalIgnoreCase)
Get-ChildItem -LiteralPath $repo -Recurse -Filter project.assets.json | Where-Object {
    $_.FullName -match '[\\/]obj[\\/]project\.assets\.json$'
} | ForEach-Object {
    $assets = ConvertFrom-JsonDocument (Get-Content -LiteralPath $_.FullName -Raw)
    $libraries = Get-JsonPropertyValue $assets 'libraries'
    foreach ($library in Get-JsonObjectEntries $libraries "The libraries object in $($_.FullName)") {
        if ((Get-JsonPropertyValue $library.Value 'type') -ne 'package') { continue }
        $parts = $library.Key -split '/', 2
        if ($parts.Count -ne 2) { continue }
        $nuget[$library.Key] = [pscustomobject][ordered]@{
            type = 'library'
            name = $parts[0]
            version = $parts[1]
            purl = "pkg:nuget/$([uri]::EscapeDataString($parts[0]))@$([uri]::EscapeDataString($parts[1]))"
        }
    }
}
if ($nuget.Count -eq 0) { throw 'No restored NuGet dependency assets were available for the API SBOM.' }
$nugetComponents = @($nuget.Values | Sort-Object name, version)
(New-Bom 'lgr-transformation-migration-api' $nugetComponents) | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $output 'api.cdx.json') -Encoding UTF8

Write-Output "Generated CycloneDX inventories for $($npmComponents.Count) npm and $($nugetComponents.Count) NuGet components."
