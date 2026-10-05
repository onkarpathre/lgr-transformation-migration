[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string] $RuntimeJson,

    [Parameter(Mandatory)]
    [int] $CommandExitCode
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$requiredRuntimes = @(
    'NODE|24-lts',
    'DOTNETCORE|10.0'
)

if ($CommandExitCode -ne 0) {
    throw 'Azure App Service runtime discovery failed; required native runtimes could not be validated.'
}

if ([string]::IsNullOrWhiteSpace($RuntimeJson)) {
    throw 'Azure App Service runtime discovery returned empty JSON output.'
}

try {
    $runtimeCatalogue = ConvertFrom-Json -InputObject $RuntimeJson -ErrorAction Stop
}
catch {
    throw 'Azure App Service runtime discovery returned malformed JSON output.'
}

if ($runtimeCatalogue -isnot [Array]) {
    throw 'Azure App Service runtime discovery returned a JSON value that is not an array.'
}
if ($runtimeCatalogue.Count -eq 0) {
    throw 'Azure App Service runtime discovery returned an empty runtime catalogue.'
}

$linuxRuntimeIdentifiers = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
foreach ($runtime in $runtimeCatalogue) {
    if ($null -eq $runtime -or $runtime -isnot [pscustomobject]) {
        throw 'Azure App Service runtime discovery returned a malformed runtime object.'
    }

    $configProperty = $runtime.PSObject.Properties['config']
    $osProperty = $runtime.PSObject.Properties['os']
    if ($null -eq $configProperty -or
        $null -eq $osProperty -or
        $configProperty.Value -isnot [string] -or
        $osProperty.Value -isnot [string] -or
        [string]::IsNullOrWhiteSpace($configProperty.Value) -or
        [string]::IsNullOrWhiteSpace($osProperty.Value) -or
        -not [regex]::IsMatch($configProperty.Value, '^[A-Za-z][A-Za-z0-9]*\|[A-Za-z0-9][A-Za-z0-9._-]*$')) {
        throw 'Azure App Service runtime discovery returned a runtime object with malformed config or os fields.'
    }

    if ($osProperty.Value -ceq 'Linux') {
        [void] $linuxRuntimeIdentifiers.Add($configProperty.Value)
    }
}

$missingRuntimes = @(
    foreach ($requiredRuntime in $requiredRuntimes) {
        if (-not $linuxRuntimeIdentifiers.Contains($requiredRuntime)) {
            $requiredRuntime
        }
    }
)
if ($missingRuntimes.Count -gt 0) {
    throw "Required native App Service runtime unavailable: $($missingRuntimes -join ', ')."
}

foreach ($requiredRuntime in $requiredRuntimes) {
    Write-Output "Validated required native App Service runtime: $requiredRuntime"
}
