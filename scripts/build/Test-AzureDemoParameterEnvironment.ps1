[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$requiredVariables = @(
    'AZDEMO_OWNER',
    'AZDEMO_COST_CENTRE',
    'AZDEMO_EXPIRY_DATE',
    'AZDEMO_ENTRA_TENANT_ID',
    'AZDEMO_SPA_CLIENT_ID',
    'AZDEMO_API_CLIENT_ID',
    'AZDEMO_SQL_ADMIN_OBJECT_ID',
    'AZDEMO_SQL_ADMIN_NAME',
    'AZDEMO_DEPLOYMENT_PRINCIPAL_OBJECT_ID',
    'AZDEMO_MIGRATION_PRINCIPAL_OBJECT_ID',
    'AZDEMO_ALERT_EMAIL'
)

$guidVariables = @(
    'AZDEMO_ENTRA_TENANT_ID',
    'AZDEMO_SPA_CLIENT_ID',
    'AZDEMO_API_CLIENT_ID',
    'AZDEMO_SQL_ADMIN_OBJECT_ID',
    'AZDEMO_DEPLOYMENT_PRINCIPAL_OBJECT_ID',
    'AZDEMO_MIGRATION_PRINCIPAL_OBJECT_ID'
)

$missingVariables = @()
$invalidVariables = @()
$values = @{}

function Add-InvalidVariable([string] $Name) {
    if ($script:invalidVariables -notcontains $Name) {
        $script:invalidVariables += $Name
    }
}

foreach ($name in $requiredVariables) {
    $value = [Environment]::GetEnvironmentVariable($name, [EnvironmentVariableTarget]::Process)
    if ([string]::IsNullOrWhiteSpace($value)) {
        $missingVariables += $name
        continue
    }

    $values[$name] = $value
    if ($value -match '\$\([A-Za-z_][A-Za-z0-9_.-]*\)') {
        Add-InvalidVariable $name
    }
}

foreach ($name in $guidVariables) {
    if (-not $values.ContainsKey($name)) {
        continue
    }

    $parsedGuid = [Guid]::Empty
    if (-not [Guid]::TryParse($values[$name], [ref] $parsedGuid) -or $parsedGuid -eq [Guid]::Empty) {
        Add-InvalidVariable $name
    }
}

if ($values.ContainsKey('AZDEMO_EXPIRY_DATE')) {
    $expiryDate = [DateTime]::MinValue
    $isExactDate = $values['AZDEMO_EXPIRY_DATE'] -match '^\d{4}-\d{2}-\d{2}$' -and
        [DateTime]::TryParseExact(
            $values['AZDEMO_EXPIRY_DATE'],
            'yyyy-MM-dd',
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::None,
            [ref] $expiryDate)
    if (-not $isExactDate -or $expiryDate.Date -le [DateTime]::UtcNow.Date) {
        Add-InvalidVariable 'AZDEMO_EXPIRY_DATE'
    }
}

if ($values.ContainsKey('AZDEMO_ALERT_EMAIL')) {
    $email = $values['AZDEMO_ALERT_EMAIL']
    $isValidEmail = $email -match '^[^@\s]+@[^@\s]+\.[^@\s]+$'
    if ($isValidEmail) {
        try {
            $mailAddress = [System.Net.Mail.MailAddress]::new($email)
            $isValidEmail = $mailAddress.Address -ceq $email
        }
        catch {
            $isValidEmail = $false
        }
    }

    if (-not $isValidEmail) {
        Add-InvalidVariable 'AZDEMO_ALERT_EMAIL'
    }
}

if ($missingVariables.Count -gt 0 -or $invalidVariables.Count -gt 0) {
    $problems = @()
    if ($missingVariables.Count -gt 0) {
        $problems += "missing: $((@($missingVariables | Sort-Object -Unique)) -join ', ')"
    }
    if ($invalidVariables.Count -gt 0) {
        $problems += "invalid: $((@($invalidVariables | Sort-Object -Unique)) -join ', ')"
    }

    throw "Azure demo parameter environment validation failed ($($problems -join '; '))."
}

Write-Output "Azure demo parameter environment validation passed for $($requiredVariables.Count) required variables."
