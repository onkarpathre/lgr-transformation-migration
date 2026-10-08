[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$validator = Join-Path $PSScriptRoot 'Assert-AzureAppServiceNativeRuntimes.ps1'
$expectedSuccessOutput = @(
    'Validated required native App Service runtime: NODE|24-lts',
    'Validated required native App Service runtime: DOTNETCORE|10.0'
)

$azureCli290Json = @'
[
  {
    "config": "dotnet|11",
    "end_of_life": "2028-11-14",
    "os": "Linux",
    "runtime": ".NET",
    "support": "Active",
    "version": "11.0 (STS)"
  },
  {
    "config": "DOTNETCORE|10.0",
    "end_of_life": "2028-11-14",
    "os": "Linux",
    "runtime": ".NET",
    "support": "Active",
    "version": "10.0 (LTS)"
  },
  {
    "config": "NODE|24-lts",
    "end_of_life": "2028-04-30",
    "os": "Linux",
    "runtime": "Node",
    "support": "Active",
    "version": "24.0 LTS"
  }
]
'@

$positiveCases = @(
    @{
        Name = 'observed Azure CLI 2.90 JSON catalogue with lowercase dotnet family'
        Json = $azureCli290Json
    },
    @{
        Name = 'both exact required runtimes'
        Json = '[{"config":"NODE|24-lts","os":"Linux"},{"config":"DOTNETCORE|10.0","os":"Linux"}]'
    },
    @{
        Name = 'reordered properties and additional metadata'
        Json = @'
[
  {"support":"Active","os":"Linux","metadata":{"channel":"lts"},"config":"NODE|24-lts","version":"24.0 LTS"},
  {"version":"10.0 (LTS)","extra":["ignored"],"config":"DOTNETCORE|10.0","runtime":".NET","os":"Linux"},
  {"os":"Linux","config":"PYTHON|3.13","unrelated":true}
]
'@
    }
)

foreach ($case in $positiveCases) {
    $arguments = @{
        RuntimeJson = [string] $case.Json
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
        Json = '[{"config":"DOTNETCORE|10.0","os":"Linux"}]'
        ExitCode = 0
    },
    @{
        Name = 'missing .NET runtime'
        Json = '[{"config":"NODE|24-lts","os":"Linux"}]'
        ExitCode = 0
    },
    @{
        Name = 'required runtimes on the wrong OS'
        Json = '[{"config":"NODE|24-lts","os":"Windows"},{"config":"DOTNETCORE|10.0","os":"Windows"}]'
        ExitCode = 0
    },
    @{
        Name = 'newer-version-only catalogue'
        Json = '[{"config":"NODE|26","os":"Linux"},{"config":"dotnet|11","os":"Linux"}]'
        ExitCode = 0
    },
    @{
        Name = 'non-zero command exit with valid stdout'
        Json = $azureCli290Json
        ExitCode = 2
    },
    @{
        Name = 'empty output'
        Json = '   '
        ExitCode = 0
    },
    @{
        Name = 'malformed JSON'
        Json = '[{"config":"NODE|24-lts"'
        ExitCode = 0
    },
    @{
        Name = 'empty top-level array'
        Json = '[]'
        ExitCode = 0
    },
    @{
        Name = 'incorrect top-level object shape'
        Json = '{"config":"NODE|24-lts","os":"Linux"}'
        ExitCode = 0
    },
    @{
        Name = 'top-level array containing a non-object'
        Json = '[{"config":"NODE|24-lts","os":"Linux"},42]'
        ExitCode = 0
    },
    @{
        Name = 'invalid config type'
        Json = '[{"config":24,"os":"Linux"},{"config":"DOTNETCORE|10.0","os":"Linux"}]'
        ExitCode = 0
    },
    @{
        Name = 'invalid os type'
        Json = '[{"config":"NODE|24-lts","os":["Linux"]},{"config":"DOTNETCORE|10.0","os":"Linux"}]'
        ExitCode = 0
    },
    @{
        Name = 'missing required field'
        Json = '[{"config":"NODE|24-lts"},{"config":"DOTNETCORE|10.0","os":"Linux"}]'
        ExitCode = 0
    },
    @{
        Name = 'diagnostic text prepended to otherwise valid JSON'
        Json = "WARNING: diagnostic text must remain on stderr.`n$azureCli290Json"
        ExitCode = 0
    },
    @{
        Name = 'similarly named but incorrect runtimes'
        Json = '[{"config":"NODE|24-lts-preview","os":"Linux"},{"config":"DOTNETCORE|10.0-preview","os":"Linux"}]'
        ExitCode = 0
    }
)

foreach ($case in $negativeCases) {
    $accepted = $false
    $failureMessage = $null
    try {
        & $validator -RuntimeJson ([string] $case.Json) -CommandExitCode $case.ExitCode | Out-Null
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
    foreach ($catalogueOnlyRuntime in @('NODE|26', 'dotnet|11')) {
        if ($failureMessage.Contains($catalogueOnlyRuntime)) {
            throw "Runtime validator dumped an unrelated catalogue runtime for $($case.Name)."
        }
    }
}

Write-Output "Azure App Service native-runtime regression passed $($positiveCases.Count) positive and $($negativeCases.Count) fail-closed cases."
