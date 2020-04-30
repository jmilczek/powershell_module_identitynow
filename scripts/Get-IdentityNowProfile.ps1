function Get-IdentityNowProfile {
    <#
.SYNOPSIS
Get IdentityNow Identity Profile(s).

.DESCRIPTION
Get IdentityNow Identity Profile(s).

.PARAMETER ID
(optional) The ID of an IdentityNow Identity Profile.

.EXAMPLE
Get-IdentityNowProfile 

.EXAMPLE
Get-IdentityNowProfile -ID 1066 

.LINK
http://darrenjrobinson.com/sailpoint-identitynow

#>

    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$ID
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
            if ($ID) {
                $IDNProfile = Invoke-RestMethod -Method Get -Uri "https://$($IdentityNowConfiguration.orgName).identitynow.com/api/profile/get/$($ID)" -Headers @{Authorization = "$($v3Token.token_type) $($v3Token.access_token)" }                                                                                     
                return $IDNProfile
            }
            else {
                $IDNProfile = Invoke-RestMethod -Method Get -Uri "https://$($IdentityNowConfiguration.orgName).identitynow.com/api/profile/list" -Headers @{Authorization = "$($v3Token.token_type) $($v3Token.access_token)" }
                return $IDNProfile
            }
        }
        catch {
            Write-Error "Profile doesn't exist? $($_)" 
        }
    }
    else {
        Write-Error "Authentication Failed. Check your AdminCredential and v3 API ClientID and ClientSecret. $($_)"
        return $v3Token
    } 
}

