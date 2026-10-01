[CmdletBinding()]
param(
    [Parameter(Mandatory)] [ValidateSet('AzureDemo')] [string] $Environment,
    [Parameter(Mandatory)] [ValidatePattern('^sqldb-mtp-dev-uks-001-reset-[a-z0-9]+$')] [string] $RestoredDatabaseName,
    [Parameter(Mandatory)] [ValidateSet('Onkar.Pathre')] [string] $ResourceGroupName,
    [Parameter(Mandatory)] [string] $ApprovedRestoreEvidenceId,
    [Parameter(Mandatory)] [string] $DbaApprovalReference
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ApprovedRestoreEvidenceId) -or [string]::IsNullOrWhiteSpace($DbaApprovalReference)) {
    throw 'Reset requires the approved new-database restore evidence and named DBA approval reference.'
}
# This command intentionally performs no restore, DELETE, DROP, EF Down, Blob purge, or Azure operation.
# Azure Platform/Operations must first restore the approved clean point to the exact new database above.
& (Join-Path $PSScriptRoot 'Invoke-AzureDemoSeed.ps1') -Environment $Environment -DatabaseName $RestoredDatabaseName -ResourceGroupName $ResourceGroupName
if ($LASTEXITCODE) { throw 'Reset seed reconciliation failed; demo access must remain frozen.' }
Write-Output "Reset reconciliation completed for evidence $ApprovedRestoreEvidenceId. Mandatory smoke tests remain outstanding."
