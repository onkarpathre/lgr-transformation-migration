$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-AzureDemoArtifactPathComparison {
    if ([IO.Path]::DirectorySeparatorChar -eq '\') {
        return [StringComparison]::OrdinalIgnoreCase
    }
    return [StringComparison]::Ordinal
}

function Assert-AzureDemoNoReparsePoints {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $RootPath,
        [Parameter(Mandatory)] [string] $CandidatePath
    )

    $comparison = Get-AzureDemoArtifactPathComparison
    $root = [IO.Path]::GetFullPath($RootPath).TrimEnd([char[]] @('\', '/'))
    $candidate = [IO.Path]::GetFullPath($CandidatePath).TrimEnd([char[]] @('\', '/'))
    $current = $candidate
    while ($true) {
        $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw 'Immutable artifact paths must not contain symbolic links or reparse points.'
        }
        if ($current.Equals($root, $comparison)) { break }
        $parent = [IO.Path]::GetDirectoryName($current)
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent.Equals($current, $comparison)) {
            throw 'Immutable artifact path ancestry could not be validated.'
        }
        $current = $parent.TrimEnd([char[]] @('\', '/'))
    }
}

function Resolve-AzureDemoArtifactPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $ArtifactRoot,
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [ValidateSet('Leaf', 'Container')] [string] $PathType
    )

    if (-not [IO.Path]::IsPathRooted($ArtifactRoot) -or -not [IO.Path]::IsPathRooted($Path)) {
        throw 'Immutable artifact root and payload paths must be explicit absolute paths.'
    }

    $comparison = Get-AzureDemoArtifactPathComparison
    $root = [IO.Path]::GetFullPath($ArtifactRoot).TrimEnd([char[]] @('\', '/'))
    $candidate = [IO.Path]::GetFullPath($Path).TrimEnd([char[]] @('\', '/'))
    $rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
    if ($candidate.Equals($root, $comparison) -or -not $candidate.StartsWith($rootPrefix, $comparison)) {
        throw 'Immutable artifact payload path escapes the approved artifact root.'
    }
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        throw 'The approved immutable artifact root does not exist.'
    }
    if (-not (Test-Path -LiteralPath $candidate -PathType $PathType)) {
        throw 'A required immutable artifact path is missing or has the wrong type.'
    }

    Assert-AzureDemoNoReparsePoints -RootPath $root -CandidatePath $candidate
    $resolvedRoot = (Resolve-Path -LiteralPath $root).ProviderPath.TrimEnd([char[]] @('\', '/'))
    $resolvedCandidate = (Resolve-Path -LiteralPath $candidate).ProviderPath.TrimEnd([char[]] @('\', '/'))
    $resolvedPrefix = $resolvedRoot + [IO.Path]::DirectorySeparatorChar
    if ($resolvedCandidate.Equals($resolvedRoot, $comparison) -or
        -not $resolvedCandidate.StartsWith($resolvedPrefix, $comparison)) {
        throw 'Resolved immutable artifact payload path escapes the approved artifact root.'
    }
    return $resolvedCandidate
}

function ConvertTo-AzureDemoArtifactRelativePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $ArtifactRoot,
        [Parameter(Mandatory)] [string] $FullPath
    )

    $comparison = Get-AzureDemoArtifactPathComparison
    $root = [IO.Path]::GetFullPath($ArtifactRoot).TrimEnd([char[]] @('\', '/'))
    $path = [IO.Path]::GetFullPath($FullPath)
    $prefix = $root + [IO.Path]::DirectorySeparatorChar
    if (-not $path.StartsWith($prefix, $comparison)) {
        throw 'Artifact file is outside the immutable package root.'
    }
    return $path.Substring($prefix.Length).Replace('\', '/')
}

function Assert-AzureDemoArtifactRelativePath {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string] $Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or
        $Path.Contains('\') -or
        [IO.Path]::IsPathRooted($Path) -or
        $Path -match '(^|/)\.\.?(/|$)' -or
        $Path -match '(^|/)(?:\.git|obj)(/|$)' -or
        $Path -match '(?i)(?:^|/)(?:project\.assets\.json|packages\.lock\.json)$' -or
        $Path -match '(?i)\.(?:cs|csproj|sln|slnx|user|pfx|publishsettings)$') {
        throw 'Deployment artifact manifest contains an unsafe or prohibited payload path.'
    }
}

function New-AzureDemoDeploymentArtifactManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $ArtifactRoot,
        [Parameter(Mandatory)] [string] $SourceCommit
    )

    if ($SourceCommit -cnotmatch '^[0-9a-f]{40}$') {
        throw 'Deployment artifact manifest requires a full lowercase source commit.'
    }
    if (-not [IO.Path]::IsPathRooted($ArtifactRoot) -or
        -not (Test-Path -LiteralPath $ArtifactRoot -PathType Container)) {
        throw 'Deployment artifact manifest requires an existing absolute artifact root.'
    }

    $root = (Resolve-Path -LiteralPath $ArtifactRoot).ProviderPath.TrimEnd([char[]] @('\', '/'))
    $manifestPath = Join-Path $root 'deployment-artifact-manifest.json'
    if (Test-Path -LiteralPath $manifestPath) {
        Remove-Item -LiteralPath $manifestPath -Force
    }
    Assert-AzureDemoNoReparsePoints -RootPath $root -CandidatePath $root

    $items = @(Get-ChildItem -LiteralPath $root -Recurse -Force)
    $links = @($items | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 })
    if ($links.Count -ne 0) {
        throw 'Immutable deployment package contains a symbolic link or reparse point.'
    }
    $files = @($items | Where-Object { -not $_.PSIsContainer } | Sort-Object {
            ConvertTo-AzureDemoArtifactRelativePath -ArtifactRoot $root -FullPath $_.FullName
        })
    if ($files.Count -eq 0) {
        throw 'Immutable deployment package contains no payload files.'
    }

    $artifacts = @($files | ForEach-Object {
            $relativePath = ConvertTo-AzureDemoArtifactRelativePath -ArtifactRoot $root -FullPath $_.FullName
            Assert-AzureDemoArtifactRelativePath -Path $relativePath
            [ordered]@{
                path = $relativePath
                sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            }
        })
    $manifest = [ordered]@{
        schemaVersion = '1'
        sourceCommit = $SourceCommit
        createdAtUtc = [DateTimeOffset]::UtcNow.ToString('O')
        artifacts = $artifacts
    }
    $manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    return $manifestPath
}

function Assert-AzureDemoDeploymentArtifact {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $ArtifactRoot,
        [Parameter(Mandatory)] [string] $ManifestPath,
        [Parameter(Mandatory)] [string] $ExpectedSourceCommit
    )

    if ($ExpectedSourceCommit -cnotmatch '^[0-9a-f]{40}$') {
        throw 'Deployment artifact validation requires a full lowercase expected source commit.'
    }
    $resolvedManifest = Resolve-AzureDemoArtifactPath -ArtifactRoot $ArtifactRoot -Path $ManifestPath -PathType Leaf
    $root = (Resolve-Path -LiteralPath $ArtifactRoot).ProviderPath.TrimEnd([char[]] @('\', '/'))
    $expectedManifest = Join-Path $root 'deployment-artifact-manifest.json'
    $comparison = Get-AzureDemoArtifactPathComparison
    if (-not $resolvedManifest.Equals($expectedManifest, $comparison)) {
        throw 'Deployment artifact manifest must be the exact root manifest.'
    }

    try {
        $manifest = Get-Content -LiteralPath $resolvedManifest -Raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw 'Deployment artifact manifest is not valid JSON.'
    }
    $manifestProperties = @(($manifest.PSObject.Properties.Name | Sort-Object) -join '|')
    if ($manifestProperties.Count -ne 1 -or $manifestProperties[0] -cne 'artifacts|createdAtUtc|schemaVersion|sourceCommit' -or
        $manifest.schemaVersion -cne '1' -or $manifest.sourceCommit -cne $ExpectedSourceCommit) {
        throw 'Deployment artifact manifest schema or exact source-commit binding is invalid.'
    }

    $items = @(Get-ChildItem -LiteralPath $root -Recurse -Force)
    $links = @($items | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 })
    if ($links.Count -ne 0) {
        throw 'Immutable deployment package contains a symbolic link or reparse point.'
    }
    $actualFiles = @($items | Where-Object {
            -not $_.PSIsContainer -and -not $_.FullName.Equals($resolvedManifest, $comparison)
        })
    $artifacts = @($manifest.artifacts)
    if ($artifacts.Count -eq 0 -or $artifacts.Count -ne $actualFiles.Count) {
        throw 'Deployment artifact manifest does not cover the exact immutable payload file set.'
    }

    $pathComparer = if ([IO.Path]::DirectorySeparatorChar -eq '\') {
        [StringComparer]::OrdinalIgnoreCase
    }
    else {
        [StringComparer]::Ordinal
    }
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ($pathComparer)
    foreach ($artifact in $artifacts) {
        $properties = @(($artifact.PSObject.Properties.Name | Sort-Object) -join '|')
        $relativePath = [string] $artifact.path
        if ($properties.Count -ne 1 -or $properties[0] -cne 'path|sha256') {
            throw 'Deployment artifact entry schema is invalid.'
        }
        Assert-AzureDemoArtifactRelativePath -Path $relativePath
        if (-not $seen.Add($relativePath)) {
            throw 'Deployment artifact manifest contains a duplicate payload path.'
        }
        if ([string] $artifact.sha256 -cnotmatch '^[0-9a-f]{64}$') {
            throw 'Deployment artifact manifest contains an invalid SHA-256 value.'
        }
        $candidate = Join-Path $root ($relativePath.Replace('/', [IO.Path]::DirectorySeparatorChar))
        $resolvedCandidate = Resolve-AzureDemoArtifactPath -ArtifactRoot $root -Path $candidate -PathType Leaf
        $actualRelativePath = ConvertTo-AzureDemoArtifactRelativePath -ArtifactRoot $root -FullPath $resolvedCandidate
        if (-not $actualRelativePath.Equals($relativePath, $comparison)) {
            throw 'Deployment artifact manifest path does not match the exact payload path.'
        }
        $actualHash = (Get-FileHash -LiteralPath $resolvedCandidate -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actualHash -cne [string] $artifact.sha256) {
            throw 'Deployment artifact payload SHA-256 validation failed.'
        }
    }

    foreach ($file in $actualFiles) {
        $relativePath = ConvertTo-AzureDemoArtifactRelativePath -ArtifactRoot $root -FullPath $file.FullName
        if (-not $seen.Contains($relativePath)) {
            throw 'Deployment artifact contains an unmanifested payload file.'
        }
    }

    return [pscustomobject]@{
        ArtifactRoot = $root
        ManifestPath = $resolvedManifest
        SourceCommit = [string] $manifest.sourceCommit
        ArtifactCount = $artifacts.Count
    }
}
