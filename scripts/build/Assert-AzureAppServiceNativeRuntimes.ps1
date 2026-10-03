[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [AllowEmptyCollection()]
    [AllowEmptyString()]
    [string[]] $RuntimeRows,

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

$runtimeIdentifiers = @()
foreach ($runtimeRow in @($RuntimeRows)) {
    if ([string]::IsNullOrWhiteSpace($runtimeRow)) {
        continue
    }

    if ($runtimeRow.IndexOf("`r", [StringComparison]::Ordinal) -ge 0 -or
        $runtimeRow.IndexOf("`n", [StringComparison]::Ordinal) -ge 0) {
        throw 'Azure App Service runtime discovery returned malformed TSV output.'
    }

    $tabIndex = $runtimeRow.IndexOf("`t", [StringComparison]::Ordinal)
    if ($tabIndex -lt 0) {
        throw 'Azure App Service runtime discovery returned malformed TSV output.'
    }

    $runtimeIdentifier = $runtimeRow.Substring(0, $tabIndex).Trim()
    if ([string]::IsNullOrWhiteSpace($runtimeIdentifier) -or
        -not [regex]::IsMatch($runtimeIdentifier, '^[A-Z][A-Z0-9]*\|[A-Za-z0-9][A-Za-z0-9._-]*$')) {
        throw 'Azure App Service runtime discovery returned malformed TSV output.'
    }

    $runtimeIdentifiers += $runtimeIdentifier
}

if ($runtimeIdentifiers.Count -eq 0) {
    throw 'Azure App Service runtime discovery returned no runtime identifiers.'
}

$missingRuntimes = @(
    foreach ($requiredRuntime in $requiredRuntimes) {
        if ($runtimeIdentifiers -notcontains $requiredRuntime) {
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
