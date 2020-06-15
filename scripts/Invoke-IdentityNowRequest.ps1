function Invoke-IdentityNowRequest {
    <#
.SYNOPSIS
Submit an IdentityNow API Request.

.DESCRIPTION
Submit an IdentityNow API Request.

.PARAMETER uri
(required) API URI

.PARAMETER method
(required) API Method
e.g Post, Get, Patch, Delete

.PARAMETER headers
(required) Headers for the request
Headersv2 Digest Auth with no Content-Type set 
Headersv2_JSON is Digest Auth with Content-Type set for application/json
Headersv3 is JWT oAuth with no Content-Type set 
Headersv3_JSON is JWT oAuth with Content-Type set for application/json

.PARAMETER body
(optional - JSON) Payload for a webrequest

.PARAMETER json
(optional) Return IdentityNow Request response as JSON.

.EXAMPLE
Invoke-IdentityNowRequest -method Get -headers Headersv2 -uri "https://YOURORG.api.identitynow.com/v2/accounts?sourceId=12345&limit=20&org=YOURORG"

.EXAMPLE
Invoke-IdentityNowRequest -method Get -headers Headersv3 -uri "https://YOURORG.api.identitynow.com/cc/api/integration/listSimIntegrations"

.LINK
http://darrenjrobinson.com/sailpoint-identitynow

#>

    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName='Full URL')]
        [string]$uri,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName='Path')]
        [string]$path,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName='Path')]
        [string][ValidateSet("V1", "V2", "V3","Private", "Beta")]$API,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string][ValidateSet("Get", "Put", "Patch", "Delete", "Post")]$method,
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string][ValidateSet("HeadersV2", "HeadersV3", "Headersv2_JSON", "Headersv3_JSON", "Headersv3_JSON-Patch")]$headers,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$body,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [switch]$json
    )

    switch ($API){
        "Private"{$uri="$((Get-IdentityNowOrg).'v3 / Private Base API URI')/$path"}
        "V1"{$uri="$((Get-IdentityNowOrg).'v1 Base API URI')/$path"}
        "V2"{$uri="$((Get-IdentityNowOrg).'v2 Base API URI')/$path"}
        "V3"{$uri="https://$((Get-IdentityNowOrg).'Organisation Name').api.identitynow.com/v3/$path"}
        "Beta"{$uri="https://$((Get-IdentityNowOrg).'Organisation Name').api.identitynow.com/beta/$path"}
    }
    switch ($headers) {
        HeadersV2 { 
            $requestHeaders = Get-IdentityNowAuth -return V2Header
            Write-Verbose "$requestheaders"
        }
        HeadersV3 { 
            $v3Token=Get-IdentityNowAuth
            $requestHeaders = @{Authorization = "Bearer $($v3Token.access_token)" }
            Write-Verbose "Authorization = Bearer $($v3Token.access_token)"
        }
        Headersv2_JSON { 
            $requestHeaders = Get-IdentityNowAuth -return V2Header
            $requestHeaders.'Content-Type' = "application/json" 
            Write-Verbose "Authorization = 'Basic $($encodedAuth)' ; 'Content-Type' = 'application/json' "
        }
        Headersv3_JSON { 
            $v3Token=Get-IdentityNowAuth
            $requestHeaders = @{Authorization = "Bearer $($v3Token.access_token)"; "Content-Type" = "application/json" }
            Write-Verbose "Authorization = 'Bearer $($v3Token.access_token)' ; 'Content-Type' = 'application/json'"
            Write-verbose ($v3Token | convertTo-json)
        }
        Headersv3_JSON-Patch { 
            $v3Token=Get-IdentityNowAuth
            $requestHeaders = @{Authorization = "Bearer $($v3Token.access_token)"; "Content-Type" = "application/json-patch+json" }
            Write-Verbose "Authorization = 'Bearer $($v3Token.access_token)'; 'Content-Type' = 'application/json-patch+json'"
            Write-verbose ($v3Token | convertTo-json)
        }
        default { 
            $requestHeaders = $headers 
        } 
    }
    
    Write-Verbose $requestHeaders
    
    if ($requestHeaders) {
        try {
            if ($body) {
                if ($json) {
                    $result = (Invoke-WebRequest -Method $method -Uri $uri -Headers $requestHeaders -Body $body).content
                }
                else {
                    $result = Invoke-RestMethod -Method $method -Uri $uri -Headers $requestHeaders -Body $body 
                }
            }
            else {   
                if ($json) {
                    $result = (Invoke-WebRequest -Method $method -Uri $uri -Headers $requestHeaders).content
                }
                else {      
                    $result = Invoke-RestMethod -Method $method -Uri $uri -Headers $requestHeaders        
                }
            }
            return $result
        }
        catch {
            Write-Error "Request Failed. Check your request parameters. $($_)" 
        }
    }
    else {
        Write-Error "No Request Headers computed. Check your request `$headers parameter. $($_)"
        return $v3Token
    } 
}
