[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$connectionString = $env:LGR_AZURE_DEMO_SQL_CONNECTION_STRING
if ([string]::IsNullOrWhiteSpace($connectionString)) {
    throw 'The protected migration stage must supply LGR_AZURE_DEMO_SQL_CONNECTION_STRING.'
}

$builder = [System.Data.Common.DbConnectionStringBuilder]::new()
try {
    $builder.set_ConnectionString($connectionString)
}
catch {
    throw 'The protected migration connection string is invalid.'
}

function Get-ConnectionValue {
    param([Parameter(Mandatory = $true)][string[]] $Names)
    foreach ($name in $Names) {
        if ($builder.ContainsKey($name)) {
            return [string] $builder[$name]
        }
    }
    return ''
}

$server = (Get-ConnectionValue @('Server', 'Data Source')).Trim()
if ($server.StartsWith('tcp:', [StringComparison]::OrdinalIgnoreCase)) {
    $server = $server.Substring(4)
}
if ($server.Contains(',')) {
    $server = $server.Substring(0, $server.IndexOf(','))
}

$database = Get-ConnectionValue @('Database', 'Initial Catalog')
$authentication = Get-ConnectionValue @('Authentication')
$encrypt = Get-ConnectionValue @('Encrypt')
$trustServerCertificate = Get-ConnectionValue @('TrustServerCertificate')
$userId = Get-ConnectionValue @('User ID', 'UID')
$password = Get-ConnectionValue @('Password', 'PWD')
$parsedUserId = [Guid]::Empty

if (-not [string]::Equals($server, 'sql-mtp-dev-uks-001.database.windows.net', [StringComparison]::OrdinalIgnoreCase) -or
    -not [string]::Equals($database, 'sqldb-mtp-dev-uks-001', [StringComparison]::Ordinal) -or
    -not [string]::Equals($authentication, 'Active Directory Managed Identity', [StringComparison]::OrdinalIgnoreCase) -or
    -not [string]::Equals($encrypt, 'True', [StringComparison]::OrdinalIgnoreCase) -or
    -not [string]::Equals($trustServerCertificate, 'False', [StringComparison]::OrdinalIgnoreCase) -or
    -not [Guid]::TryParse($userId, [ref] $parsedUserId) -or
    $parsedUserId -eq [Guid]::Empty -or
    -not [string]::IsNullOrEmpty($password)) {
    throw 'Migration target guard rejected a connection that was not the exact passwordless MTP Azure SQL database.'
}

Write-Output 'Migration target guard accepted the exact approved MTP Azure SQL database.'
