function New-IdentityNowTransform {
    <#
.SYNOPSIS
Create an IdentityNow Transform.

.DESCRIPTION
Create an IdentityNow Transform.

.PARAMETER transform
(required - JSON) The configuration for the new IdentityNow Transform.

.EXAMPLE
$attributes = @{value = '$firstName.$lastname'}
$transform = @{type = "static"; id = "FirstName.LastName"; attributes = $attributes}
New-IdentityNowTransform -transform ($transform | convertto-json) 

.LINK
http://darrenjrobinson.com/sailpoint-identitynow

#>

    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$transform
    )

    # IdentityNow Admin User
    $adminUSR = [string]$IdentityNowConfiguration.AdminCredential.UserName.ToLower()
    $adminPWDClear = [System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($IdentityNowConfiguration.AdminCredential.Password))

    # Generate the account hash
    $hashUser = Get-HashString $adminUSR.ToLower() 
    $adminPWD = Get-HashString "$($adminPWDClear)$($hashUser)"  

    $clientSecretv3 = [System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($IdentityNowConfiguration.v3.Password))
    # Basic Auth
    $Bytesv3 = [System.Text.Encoding]::utf8.GetBytes("$($IdentityNowConfiguration.v3.UserName):$($clientSecretv3)")
    $encodedAuthv3 = [Convert]::ToBase64String($Bytesv3)
    $Headersv3 = @{Authorization = "Basic $($encodedAuthv3)" }

    # Get v3 oAuth Token
    # oAuth URI
    $oAuthURI = "https://$($IdentityNowConfiguration.orgName).api.identitynow.com/oauth/token"
    $oAuthTokenBody = @{
        grant_type = "password"
        username = $adminUSR
        password = $adminPWD
    }
    $v3Token = Invoke-RestMethod -Uri $oAuthURI -Method Post -Body $oAuthTokenBody -Headers $Headersv3 

    if ($v3Token.access_token) {
        try {
            $IDNNewTransform = Invoke-RestMethod -Method Post -Uri "https://$($IdentityNowConfiguration.orgName).identitynow.com/api/transform/create" -Headers @{Authorization = "$($v3Token.token_type) $($v3Token.access_token)"; "content-type" = "application/json" } -Body $transform
            return $IDNNewTransform
        }
        catch {
            Write-Error "Creation of new Transform failed. Check Transform Configuration. $($_)" 
        }
    }
    else {
        Write-Error "Authentication Failed. Check your AdminCredential and v3 API ClientID and ClientSecret. $($_)"
        return $v3Token
    } 
}

