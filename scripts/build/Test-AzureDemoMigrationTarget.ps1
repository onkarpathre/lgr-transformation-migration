[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$guard = Join-Path $PSScriptRoot '..\database\Assert-AzureDemoMigrationTarget.ps1'
$valid = 'Server=tcp:sql-mtp-dev-uks-001.database.windows.net,1433;Database=sqldb-mtp-dev-uks-001;Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Managed Identity;User Id=aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
$previous = $env:LGR_AZURE_DEMO_SQL_CONNECTION_STRING
try {
    $env:LGR_AZURE_DEMO_SQL_CONNECTION_STRING = $valid
    & $guard | Out-Null

    $invalid = @(
        $valid.Replace('sql-mtp-dev-uks-001', 'sql-other'),
        $valid.Replace('sqldb-mtp-dev-uks-001', 'sqldb-other'),
        $valid.Replace('Encrypt=True', 'Encrypt=False'),
        $valid.Replace('TrustServerCertificate=False', 'TrustServerCertificate=True'),
        $valid.Replace('Active Directory Managed Identity', 'Active Directory Password'),
        ($valid + ';Password=prohibited')
    )
    foreach ($connectionString in $invalid) {
        $env:LGR_AZURE_DEMO_SQL_CONNECTION_STRING = $connectionString
        $accepted = $false
        try {
            & $guard | Out-Null
            $accepted = $true
        }
        catch {
            # Rejection is the required fail-closed result.
        }
        if ($accepted) {
            throw 'Migration target guard accepted an incorrect Azure SQL target or authentication mode.'
        }
    }
}
finally {
    $env:LGR_AZURE_DEMO_SQL_CONNECTION_STRING = $previous
}

Write-Output "Azure demo migration target guard passed one valid and $($invalid.Count) fail-closed cases."
