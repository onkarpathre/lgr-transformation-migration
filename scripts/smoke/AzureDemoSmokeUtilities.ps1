Set-StrictMode -Version 3.0

function Test-AzureDemoDefaultHostName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $HostName,
        [Parameter(Mandatory)] [string] $AppName,
        [Parameter(Mandatory)] [ValidateSet('production', 'staging')] [string] $SlotName
    )

    if ([string]::IsNullOrWhiteSpace($HostName) -or $HostName.Length -gt 253 -or
        $HostName -cne $HostName.ToLowerInvariant() -or
        $HostName -match '[:/@?#\\]' -or
        $HostName -notmatch '^[a-z0-9.-]+$') {
        return $false
    }

    $prefix = if ($SlotName -eq 'production') { $AppName } else { "$AppName-$SlotName" }
    $legacyHost = "$prefix.azurewebsites.net"
    if ([string]::Equals($HostName, $legacyHost, [StringComparison]::Ordinal)) {
        return $true
    }

    # App Service may add a generated uniqueness token and regional stamp to the
    # default hostname. The token is accepted only after the Azure resource ID,
    # app and slot have been independently matched by the resolver.
    $generatedPattern = '^{0}-[a-z0-9]{{8,64}}\.[a-z0-9](?:[a-z0-9-]{{0,61}}[a-z0-9])?-\d{{2}}\.azurewebsites\.net$' -f [regex]::Escape($prefix)
    return $HostName -cmatch $generatedPattern
}

function Assert-AzureDemoSmokeUriTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [uri] $Uri,
        [Parameter(Mandatory)] [string] $VerifiedHost,
        [Parameter(Mandatory)] [ValidateSet('http', 'https')] [string] $ExpectedScheme,
        [switch] $RequireRootPath
    )

    $expectedPort = if ($ExpectedScheme -eq 'https') { 443 } else { 80 }
    if (-not $Uri.IsAbsoluteUri -or
        -not [string]::Equals($Uri.Scheme, $ExpectedScheme, [StringComparison]::Ordinal) -or
        -not [string]::Equals($Uri.DnsSafeHost, $VerifiedHost, [StringComparison]::Ordinal) -or
        -not [string]::IsNullOrEmpty($Uri.UserInfo) -or
        -not $Uri.IsDefaultPort -or
        $Uri.Port -ne $expectedPort -or
        -not [string]::IsNullOrEmpty($Uri.Query) -or
        -not [string]::IsNullOrEmpty($Uri.Fragment) -or
        ($RequireRootPath -and $Uri.AbsolutePath -ne '/')) {
        throw 'Smoke target URI did not match the exact verified resource hostname, scheme, port and path contract.'
    }
}

function Get-AzureDemoSmokeExceptionCategory {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [System.Management.Automation.ErrorRecord] $ErrorRecord)

    $exception = $ErrorRecord.Exception
    $exceptionType = $exception.GetType().FullName
    if ($exceptionType -match 'Timeout|TaskCanceled') { return 'timeout' }
    if ($exceptionType -match 'AuthenticationException') { return 'tls' }

    $current = $exception
    while ($null -ne $current) {
        if ($current -is [Net.Sockets.SocketException]) {
            switch ($current.SocketErrorCode) {
                ([Net.Sockets.SocketError]::HostNotFound) { return 'name-resolution' }
                ([Net.Sockets.SocketError]::NoData) { return 'name-resolution' }
                ([Net.Sockets.SocketError]::ConnectionRefused) { return 'connection-refused' }
                ([Net.Sockets.SocketError]::NetworkUnreachable) { return 'network-unreachable' }
                default { return 'transport' }
            }
        }
        $current = $current.InnerException
    }

    if ($exceptionType -match 'HttpRequestException|WebException') { return 'transport' }
    return 'request-failure'
}

function Get-AzureDemoSmokeHeaderValue {
    [CmdletBinding()]
    param(
        [AllowNull()] [object] $Response,
        [Parameter(Mandatory)] [string] $Name
    )

    if ($null -eq $Response -or $null -eq $Response.Headers) { return $null }
    if ($Response.Headers -is [Collections.IDictionary]) { return [string] $Response.Headers[$Name] }

    $property = $Response.Headers.PSObject.Properties[$Name]
    if ($null -ne $property) { return [string] $property.Value }
    return $null
}

function Invoke-AzureDemoSmokeHttpRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $CheckId,
        [Parameter(Mandatory)] [uri] $Uri,
        [string] $Method = 'GET',
        [hashtable] $Headers = @{}
    )

    try {
        $response = Invoke-WebRequest -Uri $Uri -Method $Method -Headers $Headers -MaximumRedirection 0 -SkipHttpErrorCheck -TimeoutSec 30 -ErrorAction Stop
        $statusCode = [int] $response.StatusCode
        return [pscustomobject]@{
            TransportSucceeded = $true
            StatusCode = $statusCode
            Headers = $response.Headers
            Content = [string] $response.Content
            RawContentLength = [long] $response.RawContentLength
            Diagnostic = [pscustomobject][ordered]@{
                checkId = $CheckId
                scheme = $Uri.Scheme
                hostname = $Uri.DnsSafeHost
                path = $Uri.AbsolutePath
                httpStatus = $statusCode
                exceptionCategory = 'none'
            }
        }
    }
    catch {
        $responseProperty = $_.Exception.PSObject.Properties['Response']
        $exceptionResponse = if ($null -eq $responseProperty) { $null } else { $responseProperty.Value }
        $statusCode = $null
        $statusProperty = if ($null -eq $exceptionResponse) { $null } else { $exceptionResponse.PSObject.Properties['StatusCode'] }
        if ($null -ne $statusProperty -and $null -ne $statusProperty.Value) {
            $statusCode = [int] $statusProperty.Value
        }

        # PowerShell 7 versions may surface MaximumRedirection 0 as an exception
        # while retaining the original 3xx response. Preserve that response as
        # an HTTP result; a catch without a response remains a transport failure.
        if ($null -ne $statusCode -and $statusCode -in 301, 302, 303, 307, 308) {
            $redirectHeaders = [ordered]@{}
            $redirectHeaders.Location = Get-AzureDemoSmokeHeaderValue -Response $exceptionResponse -Name 'Location'
            return [pscustomobject]@{
                TransportSucceeded = $true
                StatusCode = $statusCode
                Headers = $redirectHeaders
                Content = ''
                RawContentLength = 0L
                Diagnostic = [pscustomobject][ordered]@{
                    checkId = $CheckId
                    scheme = $Uri.Scheme
                    hostname = $Uri.DnsSafeHost
                    path = $Uri.AbsolutePath
                    httpStatus = $statusCode
                    exceptionCategory = 'redirect-response'
                }
            }
        }

        return [pscustomobject]@{
            TransportSucceeded = $false
            StatusCode = $statusCode
            Headers = @{}
            Content = ''
            RawContentLength = 0L
            Diagnostic = [pscustomobject][ordered]@{
                checkId = $CheckId
                scheme = $Uri.Scheme
                hostname = $Uri.DnsSafeHost
                path = $Uri.AbsolutePath
                httpStatus = $statusCode
                exceptionCategory = Get-AzureDemoSmokeExceptionCategory -ErrorRecord $_
            }
        }
    }
}

function Test-AzureDemoHttpsRedirectResponse {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [uri] $RequestUri,
        [Parameter(Mandatory)] [object] $RequestResult
    )

    if (-not $RequestResult.TransportSucceeded -or $RequestResult.StatusCode -notin 301, 302, 307, 308) { return $false }
    $locationValue = Get-AzureDemoSmokeHeaderValue -Response $RequestResult -Name 'Location'
    $location = $null
    if ([string]::IsNullOrWhiteSpace($locationValue) -or -not [uri]::TryCreate($locationValue, [UriKind]::Absolute, [ref] $location)) { return $false }

    return $location.Scheme -eq 'https' -and
        [string]::Equals($location.DnsSafeHost, $RequestUri.DnsSafeHost, [StringComparison]::Ordinal) -and
        [string]::IsNullOrEmpty($location.UserInfo) -and
        $location.IsDefaultPort -and
        $location.Port -eq 443 -and
        $location.AbsolutePath -eq $RequestUri.AbsolutePath -and
        [string]::IsNullOrEmpty($location.Query) -and
        [string]::IsNullOrEmpty($location.Fragment)
}
