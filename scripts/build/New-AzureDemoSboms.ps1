[CmdletBinding()]
param([Parameter(Mandatory)] [string] $OutputDirectory)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$output = [IO.Path]::GetFullPath($OutputDirectory)
if (-not $output.StartsWith($repo + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'OutputDirectory must be within the repository workspace.'
}
New-Item -ItemType Directory -Path $output -Force | Out-Null
Add-Type -AssemblyName System.Web.Extensions
$json = [Web.Script.Serialization.JavaScriptSerializer]::new()
$json.MaxJsonLength = [int]::MaxValue

function New-Bom([string] $Name, [array] $Components) {
    [pscustomobject][ordered]@{
        bomFormat = 'CycloneDX'
        specVersion = '1.5'
        serialNumber = "urn:uuid:$([guid]::NewGuid())"
        version = 1
        metadata = [ordered]@{
            timestamp = [DateTimeOffset]::UtcNow.ToString('O')
            component = [ordered]@{ type = 'application'; name = $Name; version = (git -C $repo rev-parse HEAD).Trim() }
        }
        components = $Components
    }
}

$lock = $json.DeserializeObject((Get-Content -LiteralPath (Join-Path $repo 'src/web/package-lock.json') -Raw))
$npmComponents = foreach ($entry in $lock['packages'].GetEnumerator() | Where-Object Key) {
    $name = ($entry.Key -replace '^.*node_modules/', '')
    if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($entry.Value['version'])) { continue }
    [pscustomobject][ordered]@{
        type = 'library'
        name = $name
        version = [string]$entry.Value['version']
        purl = "pkg:npm/$([uri]::EscapeDataString($name))@$([uri]::EscapeDataString([string]$entry.Value['version']))"
    }
}
$npmComponents = @($npmComponents | Sort-Object name, version -Unique)
(New-Bom 'lgr-transformation-migration-web' $npmComponents) | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $output 'web.cdx.json') -Encoding UTF8

$nuget = [Collections.Generic.Dictionary[string, object]]::new([StringComparer]::OrdinalIgnoreCase)
Get-ChildItem -LiteralPath $repo -Recurse -Filter project.assets.json | Where-Object {
    $_.FullName -match '[\\/]obj[\\/]project\.assets\.json$'
} | ForEach-Object {
    $assets = $json.DeserializeObject((Get-Content -LiteralPath $_.FullName -Raw))
    foreach ($library in $assets['libraries'].GetEnumerator()) {
        if ($library.Value['type'] -ne 'package') { continue }
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
