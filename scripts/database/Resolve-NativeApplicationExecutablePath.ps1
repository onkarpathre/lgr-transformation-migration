function Resolve-NativeApplicationExecutablePath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]] $Candidates
    )

    $validCandidates = @(
        foreach ($candidate in @($Candidates)) {
            if ($candidate -is [System.Management.Automation.ApplicationInfo] -and
                -not [string]::IsNullOrWhiteSpace([string] $candidate.Path)) {
                $candidate
            }
        }
    )

    if ($validCandidates.Count -eq 0) {
        throw 'SQL bootstrap evidence native Git executable resolution was invalid. [GIT_EXECUTABLE_RESOLUTION_INVALID]'
    }

    # Preserve PowerShell/PATH discovery order and convert only the selected
    # ApplicationInfo.Path to the scalar value passed to the call operator.
    [string] $selectedPath = [string] $validCandidates[0].Path
    if ([string]::IsNullOrWhiteSpace($selectedPath) -or
        -not [IO.Path]::IsPathRooted($selectedPath) -or
        -not (Test-Path -LiteralPath $selectedPath -PathType Leaf)) {
        throw 'SQL bootstrap evidence native Git executable resolution was invalid. [GIT_EXECUTABLE_RESOLUTION_INVALID]'
    }

    return [string] $selectedPath
}
