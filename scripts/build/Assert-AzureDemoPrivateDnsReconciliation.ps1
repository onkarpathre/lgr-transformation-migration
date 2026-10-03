[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $LinksJson,

    [Parameter(Mandatory = $true)]
    [string] $ExpectedLinkName,

    [Parameter(Mandatory = $true)]
    [string] $ExpectedVirtualNetworkId
)

$ErrorActionPreference = 'Stop'

function Normalize-ResourceId([object] $Value) {
    if ($null -eq $Value) {
        return ''
    }

    return ([string] $Value).Trim().TrimEnd('/').ToLowerInvariant()
}

if ([string]::IsNullOrWhiteSpace($LinksJson)) {
    throw 'SQL private DNS virtual-network-link inventory was empty.'
}

try {
    $links = @(ConvertFrom-Json -InputObject $LinksJson -ErrorAction Stop)
}
catch {
    throw "SQL private DNS virtual-network-link inventory was not valid JSON: $($_.Exception.Message)"
}

if ($links.Count -eq 0 -or $null -eq $links[0]) {
    throw 'The required SQL private DNS virtual-network link is missing.'
}

$exactLinks = @($links | Where-Object { $_.name -ceq $ExpectedLinkName })
if ($exactLinks.Count -ne 1) {
    throw "Expected exactly one SQL private DNS virtual-network link named '$ExpectedLinkName'; found $($exactLinks.Count)."
}

$expectedVirtualNetwork = Normalize-ResourceId $ExpectedVirtualNetworkId
$exactLinkVirtualNetwork = Normalize-ResourceId $exactLinks[0].virtualNetwork.id
if ($exactLinkVirtualNetwork -ne $expectedVirtualNetwork) {
    throw "SQL private DNS link '$ExpectedLinkName' does not target the exact approved virtual network."
}

if ($exactLinks[0].registrationEnabled -isnot [bool] -or $exactLinks[0].registrationEnabled -ne $false) {
    throw "SQL private DNS link '$ExpectedLinkName' must have registrationEnabled=false."
}

if ($exactLinks[0].provisioningState -cne 'Succeeded') {
    throw "SQL private DNS link '$ExpectedLinkName' must have provisioningState=Succeeded."
}

$targetLinks = @($links | Where-Object {
        (Normalize-ResourceId $_.virtualNetwork.id) -eq $expectedVirtualNetwork
    })
if ($targetLinks.Count -ne 1) {
    throw "Expected exactly one SQL private DNS link to the approved virtual network; found $($targetLinks.Count)."
}

Write-Output "SQL private DNS reconciliation preflight passed for '$ExpectedLinkName'."
