[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$validator = Join-Path $PSScriptRoot 'Assert-AzureAppServiceNativeRuntimes.ps1'
$expectedSuccessOutput = @(
    'Validated required native App Service runtime: NODE|24-lts',
    'Validated required native App Service runtime: DOTNETCORE|10.0'
)

$azureCli290Rows = @(
    "NODE|26`t2029-04-30`tLinux`tNode`tActive`t26.0",
    "NODE|24-lts`t2028-04-30`tLinux`tNode`tActive`t24.0 LTS",
    "NODE|22-lts`t2027-04-30`tLinux`tNode`tNear`t22.0 LTS",
    "DOTNETCORE|11.0`t2028-11-14`tLinux`t.NET`tActive`t11.0",
    "DOTNETCORE|10.0`t2028-11-14`tLinux`t.NET`tActive`t10.0 LTS",
    "DOTNETCORE|9.0`t2026-11-10`tLinux`t.NET`tNear`t9.0",
    "DOTNETCORE|8.0`t2026-11-10`tLinux`t.NET`tNear`t8.0 LTS"
)

$positiveCases = @(
    @{
        Name = 'observed Azure CLI 2.90 TSV output'
        Rows = $azureCli290Rows
    },
    @{
        Name = 'both exact required runtimes'
        Rows = @(
            "NODE|24-lts`t2028-04-30`tLinux`tNode`tActive`t24.0 LTS",
            "DOTNETCORE|10.0`t2028-11-14`tLinux`t.NET`tActive`t10.0 LTS"
        )
    },
    @{
        Name = 'unrelated runtime rows alongside both exact required runtimes'
        Rows = @(
            "PYTHON|3.13`t2029-10-01`tLinux`tPython`tActive`t3.13",
            "NODE|24-lts`t2028-04-30`tLinux`tNode`tActive`t24.0 LTS",
            "JAVA|21-java21`t2029-09-01`tLinux`tJava`tActive`t21",
            "DOTNETCORE|10.0`t2028-11-14`tLinux`t.NET`tActive`t10.0 LTS"
        )
    }
)

foreach ($case in $positiveCases) {
    $arguments = @{
        RuntimeRows = [string[]] $case.Rows
        CommandExitCode = 0
    }
    $actualOutput = @(& $validator @arguments)
    if (($actualOutput -join "`n") -cne ($expectedSuccessOutput -join "`n")) {
        throw "Runtime validator produced unexpected output for $($case.Name)."
    }
}

$negativeCases = @(
    @{
        Name = 'missing Node runtime'
        Rows = @("DOTNETCORE|10.0`t2028-11-14`tLinux`t.NET`tActive`t10.0 LTS")
        ExitCode = 0
    },
    @{
        Name = 'missing .NET runtime'
        Rows = @("NODE|24-lts`t2028-04-30`tLinux`tNode`tActive`t24.0 LTS")
        ExitCode = 0
    },
    @{
        Name = 'malformed output'
        Rows = @(
            'NODE|24-lts 2028-04-30 Linux Node Active 24.0 LTS',
            "DOTNETCORE|10.0`t2028-11-14`tLinux`t.NET`tActive`t10.0 LTS"
        )
        ExitCode = 0
    },
    @{
        Name = 'empty output'
        Rows = @('', '   ')
        ExitCode = 0
    },
    @{
        Name = 'non-zero command exit'
        Rows = $azureCli290Rows
        ExitCode = 2
    },
    @{
        Name = 'similarly named but incorrect runtimes'
        Rows = @(
            "NODE|24-lts-preview`t2028-04-30`tLinux`tNode`tPreview`t24.0",
            "DOTNETCORE|10.0-preview`t2028-11-14`tLinux`t.NET`tPreview`t10.0"
        )
        ExitCode = 0
    }
)

foreach ($case in $negativeCases) {
    $accepted = $false
    $failureMessage = $null
    try {
        & $validator -RuntimeRows ([string[]] $case.Rows) -CommandExitCode $case.ExitCode | Out-Null
        $accepted = $true
    }
    catch {
        $failureMessage = $_.Exception.Message
    }

    if ($accepted) {
        throw "Runtime validator accepted $($case.Name)."
    }
    if ([string]::IsNullOrWhiteSpace($failureMessage)) {
        throw "Runtime validator did not report a failure for $($case.Name)."
    }
    foreach ($catalogueOnlyRuntime in @('NODE|26', 'NODE|22-lts', 'DOTNETCORE|11.0', 'DOTNETCORE|9.0', 'DOTNETCORE|8.0')) {
        if ($failureMessage.Contains($catalogueOnlyRuntime)) {
            throw "Runtime validator dumped an unrelated catalogue runtime for $($case.Name)."
        }
    }
}

Write-Output "Azure App Service native-runtime regression passed $($positiveCases.Count) positive and $($negativeCases.Count) fail-closed cases."
