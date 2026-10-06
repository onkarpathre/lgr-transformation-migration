$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$script:AzureDemoSubscriptionId = '633398e2-6c00-4bb7-a576-2db0d210ee77'
$script:AzureDemoResourceGroupName = 'Onkar.Pathre'
$script:AzureDemoWebAppName = 'app-mtp-web-dev-uks-001'
$script:AzureDemoApiAppName = 'app-mtp-api-dev-uks-001'
$script:AzureDemoStagingSlotName = 'staging'

function ConvertTo-AzureDemoLowerHex {
    param([Parameter(Mandatory)] [byte[]] $Bytes)
    return ([BitConverter]::ToString($Bytes)).Replace('-', '').ToLowerInvariant()
}

function Get-AzureDemoTextSha256 {
    param([Parameter(Mandatory)] [string] $Text)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ConvertTo-AzureDemoLowerHex ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))) }
    finally { $sha.Dispose() }
}

function Assert-AzureDemoStagingTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $SubscriptionId,
        [Parameter(Mandatory)] [string] $ResourceGroupName,
        [Parameter(Mandatory)] [ValidateSet('Web', 'Api')] [string] $Workload,
        [Parameter(Mandatory)] [string] $AppName,
        [Parameter(Mandatory)] [string] $SlotName,
        [AllowNull()] [object] $Account,
        [AllowNull()] [object] $Resource
    )

    $expectedAppName = if ($Workload -ceq 'Web') { $script:AzureDemoWebAppName } else { $script:AzureDemoApiAppName }
    if ($SubscriptionId -cne $script:AzureDemoSubscriptionId -or
        $ResourceGroupName -cne $script:AzureDemoResourceGroupName -or
        $AppName -cne $expectedAppName -or
        $SlotName -cne $script:AzureDemoStagingSlotName) {
        throw 'Azure demo staging target guard rejected an unexpected subscription, resource group, application or slot.'
    }

    if ($null -eq $Account -or [string] $Account.id -cne $script:AzureDemoSubscriptionId) {
        throw 'Azure demo staging target guard rejected the authenticated subscription.'
    }
    if ($null -eq $Resource) {
        throw 'Azure demo staging target guard requires the current Azure slot resource.'
    }

    $expectedId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$AppName/slots/$SlotName"
    $expectedName = "$AppName/$SlotName"
    if (-not [string]::Equals([string] $Resource.id, $expectedId, [StringComparison]::OrdinalIgnoreCase) -or
        [string] $Resource.name -cne $expectedName -or
        [string] $Resource.resourceGroup -cne $ResourceGroupName -or
        -not [string]::Equals([string] $Resource.type, 'Microsoft.Web/sites/slots', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Azure demo staging target guard rejected the resolved Azure slot identity.'
    }

    $hostName = [string] $Resource.defaultHostName
    if ($hostName -cnotmatch ('^(?i)' + [regex]::Escape("$AppName-$SlotName") + '(?:-[a-z0-9]+)?(?:\.[a-z0-9-]+)?\.azurewebsites\.net$') -or
        $hostName.Contains('*') -or $hostName.Contains(';')) {
        throw 'Azure demo staging target guard rejected the resolved Azure slot hostname.'
    }

    return [pscustomobject]@{
        SubscriptionId = $SubscriptionId
        ResourceGroupName = $ResourceGroupName
        Workload = $Workload
        AppName = $AppName
        SlotName = $SlotName
        ResourceId = $expectedId
        DefaultHostName = $hostName
    }
}

function Invoke-AzureDemoAzCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string[]] $Arguments,
        [Parameter(Mandatory)] [string] $Operation,
        [switch] $AllowFailure
    )

    $stdoutPath = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-{0}.stdout" -f [Guid]::NewGuid().ToString('N'))
    $stderrPath = Join-Path ([IO.Path]::GetTempPath()) ("azdemo-{0}.stderr" -f [Guid]::NewGuid().ToString('N'))
    $priorErrorActionPreference = $ErrorActionPreference
    try {
        try {
            $ErrorActionPreference = 'Continue'
            & az @Arguments 1> $stdoutPath 2> $stderrPath
            $exitCode = $LASTEXITCODE
        }
        finally { $ErrorActionPreference = $priorErrorActionPreference }
        $stdout = if (Test-Path -LiteralPath $stdoutPath) { [IO.File]::ReadAllText($stdoutPath) } else { '' }
        if ($exitCode -ne 0 -and -not $AllowFailure) {
            throw "$Operation failed with Azure CLI exit code $exitCode."
        }
        return [pscustomobject]@{
            ExitCode = $exitCode
            Stdout = $stdout
            StderrPresent = (Test-Path -LiteralPath $stderrPath) -and (Get-Item -LiteralPath $stderrPath).Length -gt 0
        }
    }
    finally {
        Remove-Item -LiteralPath $stdoutPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $stderrPath -Force -ErrorAction SilentlyContinue
    }
}

function ConvertFrom-AzureDemoJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Json,
        [Parameter(Mandatory)] [string] $Operation
    )

    try { return $Json | ConvertFrom-Json -ErrorAction Stop }
    catch { throw "$Operation did not return valid JSON." }
}

function ConvertTo-AzureDemoObjectArray {
    param([AllowNull()] [object] $InputObject)
    if ($null -eq $InputObject) { return @() }
    if ($InputObject -is [Collections.IEnumerable] -and $InputObject -isnot [string]) {
        return @($InputObject | ForEach-Object { $_ })
    }
    return @($InputObject)
}

function Assert-AzureDemoApplicationArtifact {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $ArtifactRoot,
        [Parameter(Mandatory)] [ValidateSet('Web', 'Api')] [string] $Workload,
        [Parameter(Mandatory)] [string] $ExpectedSourceCommit
    )

    $applicationDirectory = Join-Path $ArtifactRoot 'application'
    $manifestPath = Join-Path $applicationDirectory 'application-artifact-manifest.json'
    $artifactName = if ($Workload -ceq 'Web') { 'web.zip' } else { 'api.zip' }
    $artifactPath = Join-Path $applicationDirectory $artifactName
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $artifactPath -PathType Leaf)) {
        throw 'The exact application manifest or selected ZIP is missing from the immutable artifact.'
    }

    $manifest = ConvertFrom-AzureDemoJson -Json ([IO.File]::ReadAllText($manifestPath)) -Operation 'Application artifact manifest validation'
    $properties = (($manifest.PSObject.Properties.Name | Sort-Object) -join '|')
    if ($properties -cne 'artifacts|createdAtUtc|dotnetSdkVersion|nodeVersion|schemaVersion|sourceCommit' -or
        [string] $manifest.schemaVersion -cne '1' -or [string] $manifest.sourceCommit -cne $ExpectedSourceCommit) {
        throw 'Application artifact manifest schema or exact source-commit binding is invalid.'
    }
    $entries = @($manifest.artifacts | Where-Object { [string] $_.name -ceq $artifactName })
    if ($entries.Count -ne 1 -or [string] $entries[0].sha256 -cnotmatch '^[0-9a-f]{64}$') {
        throw 'Application artifact manifest does not select exactly one expected ZIP.'
    }
    $actualHash = (Get-FileHash -LiteralPath $artifactPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -cne [string] $entries[0].sha256) {
        throw 'Selected application ZIP does not match its immutable SHA-256 evidence.'
    }

    return [pscustomobject]@{
        Path = (Resolve-Path -LiteralPath $artifactPath).ProviderPath
        Name = $artifactName
        Sha256 = $actualHash
        SourceCommit = $ExpectedSourceCommit
    }
}

function Get-AzureDemoZipInventory {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string] $Path)

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $Path).ProviderPath)
    try {
        $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        $files = [Collections.Generic.List[object]]::new()
        foreach ($entry in $archive.Entries) {
            $entryPath = $entry.FullName.Replace('\', '/')
            if ([string]::IsNullOrWhiteSpace($entryPath) -or $entryPath.EndsWith('/', [StringComparison]::Ordinal)) { continue }
            if ($entryPath.StartsWith('/', [StringComparison]::Ordinal) -or
                $entryPath -match '(^|/)\.\.?(/|$)' -or
                $entryPath.Contains(':') -or
                -not $seen.Add($entryPath)) {
                throw 'ZIP inventory contains an unsafe or duplicate entry path.'
            }
            $unixMode = ($entry.ExternalAttributes -shr 16) -band 0xF000
            if ($unixMode -eq 0xA000) { throw 'ZIP inventory contains a symbolic link.' }
            $stream = $entry.Open()
            try {
                $sha = [Security.Cryptography.SHA256]::Create()
                try { $hash = ConvertTo-AzureDemoLowerHex ($sha.ComputeHash($stream)) }
                finally { $sha.Dispose() }
            }
            finally { $stream.Dispose() }
            $files.Add([pscustomobject]@{ Path = $entryPath; Length = [long] $entry.Length; Sha256 = $hash })
        }
        if ($files.Count -eq 0) { throw 'ZIP inventory contains no files.' }
        return @($files | Sort-Object Path)
    }
    finally { $archive.Dispose() }
}

function Get-AzureDemoInventoryFingerprint {
    param([Parameter(Mandatory)] [object[]] $Entries)
    $text = [string]::Join("`n", @($Entries | Sort-Object Path | ForEach-Object { '{0}|{1}|{2}' -f $_.Path, $_.Length, $_.Sha256 }))
    return Get-AzureDemoTextSha256 $text
}

function Test-AzureDemoDependencyPath {
    param([Parameter(Mandatory)] [string] $Path)
    return $Path.StartsWith('node_modules/', [StringComparison]::Ordinal) -or
        $Path -in @('node_modules.tar.gz', 'node_modules.tgz', 'node_modules.zip')
}

function Get-AzureDemoZipTextEntry {
    param(
        [Parameter(Mandatory)] [string] $ZipPath,
        [Parameter(Mandatory)] [string] $EntryPath
    )
    $archive = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $ZipPath).ProviderPath)
    try {
        $entry = @($archive.Entries | Where-Object { $_.FullName.Replace('\', '/') -ceq $EntryPath })
        if ($entry.Count -ne 1) { throw "ZIP must contain exactly one $EntryPath entry." }
        $stream = $entry[0].Open()
        try {
            $reader = [IO.StreamReader]::new($stream, [Text.Encoding]::UTF8, $true, 1024, $true)
            try { return $reader.ReadToEnd().Trim() }
            finally { $reader.Dispose() }
        }
        finally { $stream.Dispose() }
    }
    finally { $archive.Dispose() }
}

function Compare-AzureDemoDeployedZip {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [ValidateSet('Web', 'Api')] [string] $Workload,
        [Parameter(Mandatory)] [string] $ExpectedZipPath,
        [Parameter(Mandatory)] [string] $DeployedZipPath,
        [Parameter(Mandatory)] [string] $EvidencePath,
        [Parameter(Mandatory)] [string] $SourceCommit,
        [Parameter(Mandatory)] [string] $ResourceId
    )

    $expected = @(Get-AzureDemoZipInventory -Path $ExpectedZipPath)
    $deployed = @(Get-AzureDemoZipInventory -Path $DeployedZipPath)
    $expectedApplication = @(if ($Workload -ceq 'Web') { $expected | Where-Object { -not (Test-AzureDemoDependencyPath $_.Path) } } else { $expected })
    $deployedApplication = @(if ($Workload -ceq 'Web') { $deployed | Where-Object { -not (Test-AzureDemoDependencyPath $_.Path) } } else { $deployed })
    $expectedDependencies = @(if ($Workload -ceq 'Web') { $expected | Where-Object { Test-AzureDemoDependencyPath $_.Path } })
    $deployedDependencies = @(if ($Workload -ceq 'Web') { $deployed | Where-Object { Test-AzureDemoDependencyPath $_.Path } })

    $expectedByPath = @{}
    foreach ($entry in $expectedApplication) { $expectedByPath[$entry.Path] = $entry }
    $deployedByPath = @{}
    foreach ($entry in $deployedApplication) { $deployedByPath[$entry.Path] = $entry }
    $missing = @($expectedApplication | Where-Object { -not $deployedByPath.ContainsKey($_.Path) } | ForEach-Object Path)
    $changed = @($expectedApplication | Where-Object {
            $deployedByPath.ContainsKey($_.Path) -and
            ($deployedByPath[$_.Path].Length -ne $_.Length -or $deployedByPath[$_.Path].Sha256 -cne $_.Sha256)
        } | ForEach-Object {
            [ordered]@{
                path = $_.Path
                expectedLength = $_.Length
                deployedLength = $deployedByPath[$_.Path].Length
                expectedSha256 = $_.Sha256
                deployedSha256 = $deployedByPath[$_.Path].Sha256
            }
        })
    $unexpected = @($deployedApplication | Where-Object { -not $expectedByPath.ContainsKey($_.Path) } | ForEach-Object Path)

    $requiredFailures = [Collections.Generic.List[string]]::new()
    $expectedBuildId = $null
    $deployedBuildId = $null
    if ($Workload -ceq 'Web') {
        foreach ($requiredPath in @('server.js', '.next/BUILD_ID')) {
            if (-not $expectedByPath.ContainsKey($requiredPath)) { $requiredFailures.Add("expected:$requiredPath") }
            if (-not $deployedByPath.ContainsKey($requiredPath)) { $requiredFailures.Add("deployed:$requiredPath") }
        }
        foreach ($requiredPrefix in @('.next/server/', '.next/server/chunks/', '.next/static/')) {
            if (@($expectedApplication | Where-Object { $_.Path.StartsWith($requiredPrefix, [StringComparison]::Ordinal) }).Count -eq 0) {
                $requiredFailures.Add("expected-prefix:$requiredPrefix")
            }
            if (@($deployedApplication | Where-Object { $_.Path.StartsWith($requiredPrefix, [StringComparison]::Ordinal) }).Count -eq 0) {
                $requiredFailures.Add("deployed-prefix:$requiredPrefix")
            }
        }
        if ($expectedByPath.ContainsKey('.next/BUILD_ID')) { $expectedBuildId = Get-AzureDemoZipTextEntry -ZipPath $ExpectedZipPath -EntryPath '.next/BUILD_ID' }
        if ($deployedByPath.ContainsKey('.next/BUILD_ID')) { $deployedBuildId = Get-AzureDemoZipTextEntry -ZipPath $DeployedZipPath -EntryPath '.next/BUILD_ID' }
        if ([string]::IsNullOrWhiteSpace($expectedBuildId) -or $expectedBuildId -cne $deployedBuildId) { $requiredFailures.Add('build-id-mismatch') }
        if ($expectedDependencies.Count -gt 0 -and $deployedDependencies.Count -eq 0) { $requiredFailures.Add('dependency-payload-missing') }
    }

    $webFileEvidence = $null
    if ($Workload -ceq 'Web') {
        $expectedServerPages = @($expectedApplication | Where-Object {
                $_.Path.StartsWith('.next/server/app/', [StringComparison]::Ordinal) -or
                $_.Path.StartsWith('.next/server/pages/', [StringComparison]::Ordinal)
            })
        $deployedServerPages = @($deployedApplication | Where-Object {
                $_.Path.StartsWith('.next/server/app/', [StringComparison]::Ordinal) -or
                $_.Path.StartsWith('.next/server/pages/', [StringComparison]::Ordinal)
            })
        $expectedServerChunks = @($expectedApplication | Where-Object { $_.Path.StartsWith('.next/server/chunks/', [StringComparison]::Ordinal) })
        $deployedServerChunks = @($deployedApplication | Where-Object { $_.Path.StartsWith('.next/server/chunks/', [StringComparison]::Ordinal) })
        $expectedStatic = @($expectedApplication | Where-Object { $_.Path.StartsWith('.next/static/', [StringComparison]::Ordinal) })
        $deployedStatic = @($deployedApplication | Where-Object { $_.Path.StartsWith('.next/static/', [StringComparison]::Ordinal) })
        $webFileEvidence = [ordered]@{
            serverJs = [ordered]@{
                expectedSha256 = if ($expectedByPath.ContainsKey('server.js')) { $expectedByPath['server.js'].Sha256 } else { $null }
                deployedSha256 = if ($deployedByPath.ContainsKey('server.js')) { $deployedByPath['server.js'].Sha256 } else { $null }
            }
            serverPages = [ordered]@{
                expectedFileCount = $expectedServerPages.Count
                deployedFileCount = $deployedServerPages.Count
                expectedFingerprint = if ($expectedServerPages.Count) { Get-AzureDemoInventoryFingerprint -Entries $expectedServerPages } else { $null }
                deployedFingerprint = if ($deployedServerPages.Count) { Get-AzureDemoInventoryFingerprint -Entries $deployedServerPages } else { $null }
            }
            serverChunks = [ordered]@{
                expectedFileCount = $expectedServerChunks.Count
                deployedFileCount = $deployedServerChunks.Count
                expectedFingerprint = if ($expectedServerChunks.Count) { Get-AzureDemoInventoryFingerprint -Entries $expectedServerChunks } else { $null }
                deployedFingerprint = if ($deployedServerChunks.Count) { Get-AzureDemoInventoryFingerprint -Entries $deployedServerChunks } else { $null }
            }
            staticAssets = [ordered]@{
                expectedFileCount = $expectedStatic.Count
                deployedFileCount = $deployedStatic.Count
                expectedFingerprint = if ($expectedStatic.Count) { Get-AzureDemoInventoryFingerprint -Entries $expectedStatic } else { $null }
                deployedFingerprint = if ($deployedStatic.Count) { Get-AzureDemoInventoryFingerprint -Entries $deployedStatic } else { $null }
            }
        }
    }

    $passed = $missing.Count -eq 0 -and $changed.Count -eq 0 -and $unexpected.Count -eq 0 -and $requiredFailures.Count -eq 0
    $evidence = [ordered]@{
        schemaVersion = '1'
        capturedAtUtc = [DateTimeOffset]::UtcNow.ToString('O')
        status = if ($passed) { 'PASS' } else { 'FAIL' }
        workload = $Workload
        sourceCommit = $SourceCommit
        resourceId = $ResourceId
        expectedZipSha256 = (Get-FileHash -LiteralPath $ExpectedZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
        deployedSnapshotSha256 = (Get-FileHash -LiteralPath $DeployedZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
        applicationVerification = [ordered]@{
            mode = 'exact-path-size-sha256'
            expectedFileCount = $expectedApplication.Count
            deployedFileCount = $deployedApplication.Count
            expectedFingerprint = if ($expectedApplication.Count) { Get-AzureDemoInventoryFingerprint -Entries $expectedApplication } else { $null }
            deployedFingerprint = if ($deployedApplication.Count) { Get-AzureDemoInventoryFingerprint -Entries $deployedApplication } else { $null }
            missing = $missing
            changed = $changed
            unexpected = $unexpected
            requiredFailures = @($requiredFailures)
            webFileEvidence = $webFileEvidence
        }
        buildId = if ($Workload -ceq 'Web') { [ordered]@{ expected = $expectedBuildId; deployed = $deployedBuildId } } else { $null }
        dependencyTransformation = if ($Workload -ceq 'Web') {
            [ordered]@{
                mode = 'platform-transformed-node-modules'
                exactDependencyBytesCompared = $false
                reason = 'App Service NodeProjectOptimizer may compress or expand node_modules; every non-dependency application file remains exact-hash verified.'
                expectedFileCount = $expectedDependencies.Count
                deployedEntryCount = $deployedDependencies.Count
                expectedFingerprint = if ($expectedDependencies.Count) { Get-AzureDemoInventoryFingerprint -Entries $expectedDependencies } else { $null }
                deployedFingerprint = if ($deployedDependencies.Count) { Get-AzureDemoInventoryFingerprint -Entries $deployedDependencies } else { $null }
                deployedPaths = @($deployedDependencies | ForEach-Object Path)
            }
        }
        else { [ordered]@{ mode = 'none'; exactDependencyBytesCompared = $true } }
    }
    $evidenceDirectory = Split-Path -Parent $EvidencePath
    if (-not [string]::IsNullOrWhiteSpace($evidenceDirectory)) { New-Item -ItemType Directory -Path $evidenceDirectory -Force | Out-Null }
    $evidence | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $EvidencePath -Encoding UTF8
    if (-not $passed) { throw "$Workload deployed content does not match the exact immutable ZIP." }
    return [pscustomobject]$evidence
}
