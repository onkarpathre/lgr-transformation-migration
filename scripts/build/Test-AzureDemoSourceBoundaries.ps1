[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$failures = [Collections.Generic.List[string]]::new()

function Add-Failure([string] $Message) { $failures.Add($Message) }
function Read-RepositoryFile([string] $Path) { Get-Content -LiteralPath (Join-Path $repo $Path) -Raw }

$candidateRoots = @('azure-pipelines.yml', 'infra', 'scripts', 'src', 'tools', 'demo-data')
$textFiles = foreach ($candidate in $candidateRoots) {
    $path = Join-Path $repo $candidate
    if (Test-Path -LiteralPath $path -PathType Leaf) { Get-Item -LiteralPath $path }
    elseif (Test-Path -LiteralPath $path -PathType Container) {
        Get-ChildItem -LiteralPath $path -Recurse -File | Where-Object {
            $_.FullName -notmatch '[\\/](bin|obj|node_modules|\.next|runtime)[\\/]'
        }
    }
}

$secretPatterns = @(
    '-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
    '(?i)\b(?:ghp|github_pat|glpat)-[A-Za-z0-9_-]{20,}',
    '(?i)\bAccountKey=[A-Za-z0-9+/]{20,}={0,2}',
    '(?i)\b(?:client_secret|clientSecret)\s*[:=]\s*["''][A-Za-z0-9._~-]{12,}["'']'
)
foreach ($file in $textFiles) {
    if ($file.Extension -in @('.dll', '.exe', '.pdb', '.zip', '.png', '.jpg', '.gif')) { continue }
    $content = Get-Content -LiteralPath $file.FullName -Raw
    foreach ($pattern in $secretPatterns) {
        if ($content -match $pattern) { Add-Failure "Potential secret pattern in $($file.FullName.Substring($repo.Length + 1))." }
    }
}

$azureConfiguration = @(
    'azure-pipelines.yml',
    'src/api/appsettings.AzureDemo.json',
    'infra/bicep/main.bicep',
    'infra/bicep/modules/appservice.bicep',
    'infra/bicep/parameters/azure-demo.bicepparam'
)
foreach ($file in $azureConfiguration) {
    $content = Read-RepositoryFile $file
    if ($content -match '(?i)Authentication__Mode\s*[=:]\s*LocalTest|NEXT_PUBLIC_LGR_TEST_PRINCIPAL|LGR_TEST_PRINCIPAL') {
        Add-Failure "Azure deployment configuration enables local-test identity in $file."
    }
}

$proxy = Read-RepositoryFile 'src/web/app/api/[...path]/route.ts'
foreach ($header in @('x-customer-id', 'x-user-name', 'x-lgr-test-principal', 'x-principal-id', 'x-roles', 'x-project-roles', 'x-permissions')) {
    if ($proxy -notmatch [regex]::Escape($header)) { Add-Failure "Web proxy does not strip $header." }
}
if ($proxy -match 'NEXT_PUBLIC_API_BASE_URL|new URL\(request\.') { Add-Failure 'Web proxy contains an unapproved caller-selected API destination.' }

$startup = Read-RepositoryFile 'src/api/Program.cs'
if ($startup -match 'Database\.(?:Migrate|EnsureCreated)|MigrateAsync|SeedData\.Configure') {
    Add-Failure 'API startup contains a migration, schema-creation or seed invocation.'
}

$applicationFiles = Get-ChildItem (Join-Path $repo 'src') -Recurse -File | Where-Object {
    $_.FullName -notmatch '[\\/](bin|obj|node_modules|\.next)[\\/]'
}
$prohibitedCapabilityPatterns = @(
    'Microsoft\.Azure\.Management',
    'Azure\.ResourceManager',
    'api\.migrate\.azure\.com',
    'AzureMigrate.*HttpClient',
    '(?i)OpenAI|Anthropic|AzureOpenAI'
)
foreach ($file in $applicationFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    foreach ($pattern in $prohibitedCapabilityPatterns) {
        if ($content -match $pattern) { Add-Failure "Prohibited application capability pattern in $($file.FullName.Substring($repo.Length + 1))." }
    }
}

$statusPaths = @(
    git -C $repo diff --name-only
    git -C $repo ls-files --others --exclude-standard
) | Sort-Object -Unique
$binaryOrGenerated = $statusPaths | Where-Object {
    $_ -match '(?i)\.(dll|pdb|exe|zip)$' -or $_ -match '(^|/)artifacts/azure-demo-local/' -or $_ -match '(^|/)(bin|obj|\.next|node_modules)/'
}
if ($binaryOrGenerated) { Add-Failure "Generated/binary paths are present in the intended source inventory: $($binaryOrGenerated -join ', ')." }

if ($failures.Count) {
    $failures | ForEach-Object { Write-Error $_ }
    throw "AzureDemo source-boundary scan failed with $($failures.Count) finding(s)."
}

Write-Output "AzureDemo source-boundary scan passed for $($textFiles.Count) source/configuration files."
