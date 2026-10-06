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
    param([AllowNull()] [object] $Exception)

    if ($null -eq $Exception) { return 'request-failure' }
    if ($Exception -isnot [Exception]) { return 'unexpected-error-object' }

    $current = $Exception
    while ($null -ne $current) {
        $currentType = $current.GetType().FullName
        if ($currentType -match 'Timeout|TaskCanceled') { return 'timeout' }
        if ($currentType -match 'AuthenticationException') { return 'tls' }
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

    $exceptionType = $Exception.GetType().FullName
    if ($exceptionType -match 'HttpRequestException|WebException') { return 'transport' }
    return 'request-failure'
}

function Get-AzureDemoSmokeSafeTypeName {
    [CmdletBinding()]
    param([AllowNull()] [object] $InputObject)

    if ($null -eq $InputObject) { return 'none' }
    return $InputObject.GetType().FullName
}

function Get-AzureDemoSmokeSafeErrorIdentifier {
    [CmdletBinding()]
    param(
        [AllowNull()] [object] $ErrorObject,
        [string] $Fallback = 'unavailable'
    )

    $errorRecord = if ($ErrorObject -is [System.Management.Automation.ErrorRecord]) {
        [System.Management.Automation.ErrorRecord] $ErrorObject
    }
    elseif ($ErrorObject -is [Exception]) {
        $property = $ErrorObject.PSObject.Properties['ErrorRecord']
        if ($null -ne $property -and $property.Value -is [System.Management.Automation.ErrorRecord]) {
            [System.Management.Automation.ErrorRecord] $property.Value
        }
        else { $null }
    }
    else { $null }

    if ($null -ne $errorRecord) {
        $candidate = [string] $errorRecord.FullyQualifiedErrorId
        if ($candidate -cmatch '^[A-Za-z][A-Za-z0-9_.-]{0,127}(?:,[A-Za-z][A-Za-z0-9_.-]{0,127})?$') {
            return $candidate
        }

        # Evidence validators use bounded, code-owned identifiers. Convert only
        # that exact prefix; never surface an arbitrary exception message.
        $message = if ($errorRecord.Exception -is [Exception]) { [string] $errorRecord.Exception.Message } else { '' }
        if ($message -cmatch '^Smoke evidence rejected: ([A-Z][A-Z0-9_]{0,63})(?:[ .(]|$)') {
            return "Evidence.$($Matches[1])"
        }
    }

    return $Fallback
}

function Get-AzureDemoSmokeSafeInvocationLocation {
    [CmdletBinding()]
    param([AllowNull()] [object] $ErrorObject)

    $errorRecord = if ($ErrorObject -is [System.Management.Automation.ErrorRecord]) {
        [System.Management.Automation.ErrorRecord] $ErrorObject
    }
    elseif ($ErrorObject -is [Exception]) {
        $property = $ErrorObject.PSObject.Properties['ErrorRecord']
        if ($null -ne $property -and $property.Value -is [System.Management.Automation.ErrorRecord]) {
            [System.Management.Automation.ErrorRecord] $property.Value
        }
        else { $null }
    }
    else { $null }

    if ($null -eq $errorRecord -or $null -eq $errorRecord.InvocationInfo) {
        return [pscustomobject]@{ script = $null; line = $null }
    }

    $scriptPath = [string] $errorRecord.InvocationInfo.ScriptName
    $line = [int] $errorRecord.InvocationInfo.ScriptLineNumber
    if ([string]::IsNullOrWhiteSpace($scriptPath) -or $line -le 0) {
        return [pscustomobject]@{ script = $null; line = $null }
    }

    try {
        $repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
        $resolvedScript = [IO.Path]::GetFullPath($scriptPath)
        $rootPrefix = $repositoryRoot.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
        if (-not $resolvedScript.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            return [pscustomobject]@{ script = $null; line = $null }
        }

        return [pscustomobject]@{ script = [IO.Path]::GetFileName($resolvedScript); line = $line }
    }
    catch {
        return [pscustomobject]@{ script = $null; line = $null }
    }
}

function Get-AzureDemoSmokeErrorObjectClassification {
    [CmdletBinding()]
    param(
        [AllowNull()] [object] $InputObject,
        [Parameter(Mandatory)] [ValidateSet('error-variable', 'catch')] [string] $Origin
    )

    if ($null -eq $InputObject) {
        return [pscustomobject][ordered]@{
            Origin = $Origin
            Kind = 'null'
            TypeName = 'none'
            ErrorRecord = $null
            Exception = $null
            FullyQualifiedErrorId = $null
        }
    }

    if ($InputObject -is [System.Management.Automation.ErrorRecord]) {
        $errorRecord = [System.Management.Automation.ErrorRecord] $InputObject
        $exception = if ($errorRecord.Exception -is [Exception]) { $errorRecord.Exception } else { $null }
        return [pscustomobject][ordered]@{
            Origin = $Origin
            Kind = 'error-record'
            TypeName = Get-AzureDemoSmokeSafeTypeName -InputObject $InputObject
            ErrorRecord = $errorRecord
            Exception = $exception
            FullyQualifiedErrorId = $errorRecord.FullyQualifiedErrorId
        }
    }

    if ($InputObject -is [Exception]) {
        $exception = [Exception] $InputObject
        $errorRecordProperty = $exception.PSObject.Properties['ErrorRecord']
        $embeddedErrorRecord = if ($null -ne $errorRecordProperty -and
            $errorRecordProperty.Value -is [System.Management.Automation.ErrorRecord]) {
            [System.Management.Automation.ErrorRecord] $errorRecordProperty.Value
        }
        else {
            $null
        }

        return [pscustomobject][ordered]@{
            Origin = $Origin
            Kind = 'exception'
            TypeName = Get-AzureDemoSmokeSafeTypeName -InputObject $InputObject
            ErrorRecord = $embeddedErrorRecord
            Exception = $exception
            FullyQualifiedErrorId = if ($null -eq $embeddedErrorRecord) { $null } else { $embeddedErrorRecord.FullyQualifiedErrorId }
        }
    }

    return [pscustomobject][ordered]@{
        Origin = $Origin
        Kind = 'unexpected'
        TypeName = Get-AzureDemoSmokeSafeTypeName -InputObject $InputObject
        ErrorRecord = $null
        Exception = $null
        FullyQualifiedErrorId = $null
    }
}

function Get-AzureDemoSmokeExceptionResponse {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [Exception] $Exception)

    $current = $Exception
    while ($null -ne $current) {
        $responseProperty = $current.PSObject.Properties['Response']
        if ($null -ne $responseProperty -and $null -ne $responseProperty.Value) {
            return $responseProperty.Value
        }

        $current = $current.InnerException
    }

    return $null
}

function Get-AzureDemoSmokeHttpResponseInfo {
    [CmdletBinding()]
    param([AllowNull()] [object] $Response)

    $invalid = [pscustomobject][ordered]@{
        HasHttpShape = $false
        HasBasicWebResponseShape = $false
        StatusCode = $null
        Headers = $null
        Content = ''
        RawContentLength = 0L
    }
    if ($null -eq $Response) { return $invalid }

    $statusProperty = $Response.PSObject.Properties['StatusCode']
    $headersProperty = $Response.PSObject.Properties['Headers']
    if ($null -eq $statusProperty -or $null -eq $statusProperty.Value -or
        $null -eq $headersProperty -or $null -eq $headersProperty.Value) {
        return $invalid
    }

    try { $statusCode = [int] $statusProperty.Value } catch { return $invalid }
    if ($statusCode -lt 100 -or $statusCode -gt 599) { return $invalid }

    $contentProperty = $Response.PSObject.Properties['Content']
    $rawContentLengthProperty = $Response.PSObject.Properties['RawContentLength']
    $hasBasicWebResponseShape = $null -ne $contentProperty -and $null -ne $rawContentLengthProperty
    $rawContentLength = 0L
    if ($hasBasicWebResponseShape) {
        try { $rawContentLength = [long] $rawContentLengthProperty.Value } catch { $hasBasicWebResponseShape = $false }
    }

    return [pscustomobject][ordered]@{
        HasHttpShape = $true
        HasBasicWebResponseShape = $hasBasicWebResponseShape
        StatusCode = $statusCode
        Headers = $headersProperty.Value
        Content = if ($null -eq $contentProperty) { '' } else { [string] $contentProperty.Value }
        RawContentLength = $rawContentLength
    }
}

function Get-AzureDemoSmokeHeaderValue {
    [CmdletBinding()]
    param(
        [AllowNull()] [object] $Response,
        [Parameter(Mandatory)] [string] $Name
    )

    if ($null -eq $Response) { return $null }
    $headersProperty = $Response.PSObject.Properties['Headers']
    if ($null -eq $headersProperty -or $null -eq $headersProperty.Value) { return $null }
    $headers = $headersProperty.Value
    $value = $null
    if ($headers -is [Collections.Specialized.NameValueCollection]) {
        $value = $headers.Get($Name)
    }
    elseif ($headers -is [Collections.IDictionary]) {
        foreach ($key in $headers.Keys) {
            if ([string]::Equals([string] $key, $Name, [StringComparison]::OrdinalIgnoreCase)) {
                $value = $headers[$key]
                break
            }
        }
    }
    else {
        $tryGetValues = $headers.PSObject.Methods['TryGetValues']
        if ($null -ne $tryGetValues) {
            $values = $null
            if ($headers.TryGetValues($Name, [ref] $values)) { $value = $values }
        }
        if ($null -eq $value) {
            $property = $headers.PSObject.Properties[$Name]
            if ($null -ne $property) { $value = $property.Value }
        }
    }

    if ($null -eq $value) { return $null }
    if ($value -is [string]) { return $value }
    if ($value -is [Collections.IEnumerable]) {
        $items = @($value | ForEach-Object { [string] $_ })
        if ($items.Count -eq 0) { return $null }
        return [string]::Join(', ', $items)
    }
    return [string] $value
}

function Resolve-AzureDemoSmokeHttpResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $CheckId,
        [Parameter(Mandatory)] [uri] $Uri,
        [AllowNull()] [object] $PipelineOutput,
        [AllowNull()] [object] $CapturedErrors,
        [AllowNull()] [object] $TerminatingError
    )

    $pipelineItems = [Collections.Generic.List[object]]::new()
    if ($null -ne $PipelineOutput) {
        if ($PipelineOutput -is [Collections.IList]) {
            foreach ($item in $PipelineOutput) { $pipelineItems.Add($item) }
        }
        else {
            $pipelineItems.Add($PipelineOutput)
        }
    }

    $errorClassifications = [Collections.Generic.List[object]]::new()
    if ($null -ne $CapturedErrors) {
        if ($CapturedErrors -is [Collections.IList]) {
            foreach ($capturedError in $CapturedErrors) {
                $errorClassifications.Add((Get-AzureDemoSmokeErrorObjectClassification -InputObject $capturedError -Origin 'error-variable'))
            }
        }
        else {
            $errorClassifications.Add((Get-AzureDemoSmokeErrorObjectClassification -InputObject $CapturedErrors -Origin 'error-variable'))
        }
    }
    if ($null -ne $TerminatingError) {
        $errorClassifications.Add((Get-AzureDemoSmokeErrorObjectClassification -InputObject $TerminatingError -Origin 'catch'))
    }

    $response = if ($pipelineItems.Count -eq 1) { $pipelineItems[0] } else { $null }
    $responseInfo = Get-AzureDemoSmokeHttpResponseInfo -Response $response
    $hasUnexpectedErrorObject = @($errorClassifications | Where-Object { $_.Kind -eq 'unexpected' }).Count -gt 0
    $hasNullErrorObject = @($errorClassifications | Where-Object { $_.Kind -eq 'null' }).Count -gt 0
    $expectedRedirectErrorId = 'MaximumRedirectExceeded,Microsoft.PowerShell.Commands.InvokeWebRequestCommand'
    $hasOnlyExpectedRedirectErrors = $errorClassifications.Count -gt 0
    foreach ($classification in $errorClassifications) {
        if ($null -eq $classification.ErrorRecord -or
            $classification.FullyQualifiedErrorId -cne $expectedRedirectErrorId) {
            $hasOnlyExpectedRedirectErrors = $false
            break
        }
    }

    $requestFailure = if ($null -ne $TerminatingError) {
        Get-AzureDemoSmokeErrorObjectClassification -InputObject $TerminatingError -Origin 'catch'
    }
    elseif ($errorClassifications.Count -gt 0) {
        $errorClassifications[$errorClassifications.Count - 1]
    }
    else {
        $null
    }
    $requestException = if ($null -eq $requestFailure -or $requestFailure.Exception -isnot [Exception]) {
        $null
    }
    else {
        [Exception] $requestFailure.Exception
    }
    $safeErrorObject = if ($null -ne $requestFailure -and $null -ne $requestFailure.ErrorRecord) {
        $requestFailure.ErrorRecord
    }
    elseif ($null -ne $requestException) {
        $requestException
    }
    else {
        $null
    }
    $safeLocation = Get-AzureDemoSmokeSafeInvocationLocation -ErrorObject $safeErrorObject
    $safeErrorIdentifier = Get-AzureDemoSmokeSafeErrorIdentifier -ErrorObject $safeErrorObject
    $errorObjectTypes = if ($errorClassifications.Count -eq 0) {
        'none'
    }
    else {
        (($errorClassifications | ForEach-Object { '{0}:{1}:{2}' -f $_.Origin, $_.Kind, $_.TypeName }) -join ';')
    }
    $resultType = if ($pipelineItems.Count -eq 1) {
        Get-AzureDemoSmokeSafeTypeName -InputObject $pipelineItems[0]
    }
    elseif ($pipelineItems.Count -gt 1) {
        "multiple-output:$($pipelineItems.Count)"
    }
    else {
        'none'
    }

    if ($responseInfo.HasBasicWebResponseShape -and
        ($errorClassifications.Count -eq 0 -or
            ($hasOnlyExpectedRedirectErrors -and $responseInfo.StatusCode -ge 300 -and $responseInfo.StatusCode -lt 400))) {
        return [pscustomobject]@{
            TransportSucceeded = $true
            StatusCode = $responseInfo.StatusCode
            Headers = $responseInfo.Headers
            Content = $responseInfo.Content
            RawContentLength = $responseInfo.RawContentLength
            Diagnostic = [pscustomobject][ordered]@{
                checkId = $CheckId
                executionPhase = 'http-request'
                scheme = $Uri.Scheme
                hostname = $Uri.DnsSafeHost
                path = $Uri.AbsolutePath
                httpStatus = $responseInfo.StatusCode
                runtimeVersion = $PSVersionTable.PSVersion.ToString()
                resultType = $resultType
                errorVariableType = Get-AzureDemoSmokeSafeTypeName -InputObject $CapturedErrors
                errorObjects = $errorObjectTypes
                exceptionType = if ($null -eq $requestException) { 'none' } else { Get-AzureDemoSmokeSafeTypeName -InputObject $requestException }
                errorIdentifier = $safeErrorIdentifier
                exceptionCategory = if ($hasOnlyExpectedRedirectErrors) { 'redirect-response' } else { 'none' }
                script = $safeLocation.script
                line = $safeLocation.line
            }
        }
    }

    $exceptionResponse = if ($null -eq $requestException) { $null } else { Get-AzureDemoSmokeExceptionResponse -Exception $requestException }
    $exceptionResponseInfo = Get-AzureDemoSmokeHttpResponseInfo -Response $exceptionResponse
    if ($pipelineItems.Count -eq 0 -and $hasOnlyExpectedRedirectErrors -and
        $exceptionResponseInfo.HasHttpShape -and
        $exceptionResponseInfo.StatusCode -ge 300 -and $exceptionResponseInfo.StatusCode -lt 400) {
        $redirectHeaders = [ordered]@{}
        $redirectHeaders.Location = Get-AzureDemoSmokeHeaderValue -Response $exceptionResponse -Name 'Location'
        return [pscustomobject]@{
            TransportSucceeded = $true
            StatusCode = $exceptionResponseInfo.StatusCode
            Headers = $redirectHeaders
            Content = ''
            RawContentLength = 0L
            Diagnostic = [pscustomobject][ordered]@{
                checkId = $CheckId
                executionPhase = 'http-request'
                scheme = $Uri.Scheme
                hostname = $Uri.DnsSafeHost
                path = $Uri.AbsolutePath
                httpStatus = $exceptionResponseInfo.StatusCode
                runtimeVersion = $PSVersionTable.PSVersion.ToString()
                resultType = Get-AzureDemoSmokeSafeTypeName -InputObject $exceptionResponse
                errorVariableType = Get-AzureDemoSmokeSafeTypeName -InputObject $CapturedErrors
                errorObjects = $errorObjectTypes
                exceptionType = Get-AzureDemoSmokeSafeTypeName -InputObject $requestException
                errorIdentifier = $safeErrorIdentifier
                exceptionCategory = 'redirect-response'
                script = $safeLocation.script
                line = $safeLocation.line
            }
        }
    }

    $failureStatusCode = if ($exceptionResponseInfo.HasHttpShape) { $exceptionResponseInfo.StatusCode } else { $null }
    $failureCategory = if ($hasUnexpectedErrorObject) {
        'unexpected-error-object'
    }
    elseif ($hasNullErrorObject) {
        'null-error-object'
    }
    elseif ($pipelineItems.Count -gt 0) {
        if ($errorClassifications.Count -gt 0) { 'request-failure' } else { 'unexpected-output' }
    }
    elseif ($null -ne $requestException) {
        Get-AzureDemoSmokeExceptionCategory -Exception $requestException
    }
    elseif ($errorClassifications.Count -gt 0) {
        'request-failure'
    }
    else {
        'missing-result'
    }

    return [pscustomobject]@{
        TransportSucceeded = $false
        StatusCode = $failureStatusCode
        Headers = @{}
        Content = ''
        RawContentLength = 0L
        Diagnostic = [pscustomobject][ordered]@{
            checkId = $CheckId
            executionPhase = 'http-request'
            scheme = $Uri.Scheme
            hostname = $Uri.DnsSafeHost
            path = $Uri.AbsolutePath
            httpStatus = $failureStatusCode
            runtimeVersion = $PSVersionTable.PSVersion.ToString()
            resultType = if ($null -ne $exceptionResponse) { Get-AzureDemoSmokeSafeTypeName -InputObject $exceptionResponse } else { $resultType }
            errorVariableType = Get-AzureDemoSmokeSafeTypeName -InputObject $CapturedErrors
            errorObjects = $errorObjectTypes
            exceptionType = if ($null -eq $requestException) { 'none' } else { Get-AzureDemoSmokeSafeTypeName -InputObject $requestException }
            errorIdentifier = $safeErrorIdentifier
            exceptionCategory = $failureCategory
            script = $safeLocation.script
            line = $safeLocation.line
        }
    }
}

function Invoke-AzureDemoSmokeHttpRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $CheckId,
        [Parameter(Mandatory)] [uri] $Uri,
        [string] $Method = 'GET',
        [hashtable] $Headers = @{}
    )

    $pipelineOutput = @()
    $requestErrors = @()
    $terminatingError = $null
    try {
        # PowerShell 7 writes a redirect response to the success pipeline and then
        # emits MaximumRedirectExceeded when MaximumRedirection is zero. Do not
        # promote that expected error before the response can be captured.
        $pipelineOutput = @(Invoke-WebRequest -Uri $Uri -Method $Method -Headers $Headers -MaximumRedirection 0 -SkipHttpErrorCheck -TimeoutSec 30 -ErrorAction SilentlyContinue -ErrorVariable requestErrors)
    }
    catch {
        $terminatingError = $_
    }

    return Resolve-AzureDemoSmokeHttpResult -CheckId $CheckId -Uri $Uri `
        -PipelineOutput $pipelineOutput -CapturedErrors $requestErrors -TerminatingError $terminatingError
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
