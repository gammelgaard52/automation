function New-FolderIfNotExists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path
    )
    
    # Check if the folder exists
    if (-Not ((Resolve-Path $path).Path)) {
        # Create the folder if it doesn't exist
        New-Item -ItemType Directory -Path $Path | Out-Null
        Write-Verbose "Folder created: $Path"
    } else {
        Write-Verbose "Folder already exists: $Path"
    }
}

function New-BearerToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$apikey,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$apiSecret
    )
    
    # Convert to byte arrays
    $keyBytes = [System.Text.Encoding]::UTF8.GetBytes($apiSecret)
    $dataBytes = [System.Text.Encoding]::UTF8.GetBytes($apiKey)

    # Create HMAC-SHA256 hash
    $hmacsha256 = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha256.Key = $keyBytes
    $hashBytes = $hmacsha256.ComputeHash($dataBytes)

    # Convert hash to hexadecimal string
    $hashHex = -join ($hashBytes | ForEach-Object { $_.ToString("x2") })

    # Concatenate API key with hashed value
    $concatenated = "$apiKey`:$hashHex"

    # Base64 encode the concatenated string
    $base64Token = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($concatenated))

    # Return the Bearer token
    return "$base64Token"
}

function Get-AddressCoordinate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$fullAddress
    )

    # Encode the address for a URL request
    $encodedAddress = [System.Web.HttpUtility]::UrlEncode($fullAddress)

    # Call the OpenStreetMap Nominatim API to get latitude & longitude
    $geoResponse = Invoke-RestMethod -Uri "https://nominatim.openstreetmap.org/search?q=$encodedAddress&format=json" -Method Get

    # Extract latitude and longitude from the response
    if ($geoResponse.Count -gt 0) {
        $latitude = [double]$geoResponse[0].lat
        $longitude = [double]$geoResponse[0].lon
        Write-Host "Latitude: $latitude, Longitude: $longitude"
    } else {
        Write-Host "Could not retrieve coordinates."
        return $null  # Return null if no coordinates found
    }

    # Output data as an object
    return [PSCustomObject]@{
        Latitude = $latitude
        Longitude = $longitude
    }

}

function Get-AddressPriceById {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$addressId
    )

    $AddressPrice = Invoke-RestMethod -Uri "https://api.minstroem.app/thirdParty/prices/addresses/$($2.id)" -Method Get -Headers $headers
    
    return $AddressPrice
}

function Get-AddressId {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$userId
    )
    
    $addressTable = Invoke-RestMethod -Uri "https://api.minstroem.app/thirdParty/users/$($userId)/connectedAddresses" -Method Get -Headers $headers
    $addressId = Invoke-RestMethod -Uri "https://api.minstroem.app/thirdParty/prices/addresses/suggestions/$($addressTable[0].fullAddress)" -Method Get -Headers $headers

    if ($2[0].suggestion=$addressTable[0].fullAddress) {
        $matchRating = 1
        $reason = "Exact address match - proceeding"
    }
    else {
        $matchRating = 0
        $reason = "Proceeding with less confidence, since it's not an exact address match"
    }

    # Output data as an object
    return [PSCustomObject]@{
        id = $addressId.id
        fullAddress = $addressTable[0].fullAddress
        matchRating = @{
            rating = $matchRating
            reason = $reason
        }
    }
}


# =========================
# PlexusGrid PowerShell API
# =========================

# Decode any JWT and show expiry & time remaining
function Get-JwtExpiryInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Jwt
    )
    $p = $Jwt.Split('.')[1].Replace('-', '+').Replace('_', '/')
    switch ($p.Length % 4) { 2 { $p += '==' } 3 { $p += '=' } }
    $json = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($p))
    $payload = $json | ConvertFrom-Json
    if (-not $payload.exp) {
        Write-Warning "Token has no 'exp' field"
        return $payload
    }
    $exp = [int64]$payload.exp
    if ($exp -gt 9999999999) { $exp = [math]::Floor($exp/1000) } # ms→s safeguard
    $expiryUtc = [DateTimeOffset]::FromUnixTimeSeconds($exp)
    $expiryLocal = $expiryUtc.ToLocalTime()
    $remaining = $expiryLocal - (Get-Date)
    [pscustomobject]@{
        #ExpiryUtc     = $expiryUtc.UtcDateTime
        ExpiryLocal   = $expiryLocal.DateTime
        #TimeRemaining = ("{0:%d}d {0:%h}h {0:%m}m {0:%s}s" -f $remaining)
        #Payload       = $payload
    }
}

# Create a new authenticated WebSession (logs in via Next.js Server Action)
function New-PlexusSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Username,
        [Parameter(Mandatory)][string]$Password,
        [string]$BaseUrl = 'https://plexusgrid.com',
        # From your HAR (stays stable until the app changes its server action id)
        [string]$NextAction = '60d9fd163325a477ea92adc22b20c54a59346ac66b',
        # From your HAR; server expects this auxiliary field
        [string]$ActionZero = '["$undefined","$K1"]',
        # If you discover the app requires it, you can pass the long router-state header here
        [string]$NextRouterStateTree
    )
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

    $headers = @{
        'Accept'      = 'text/x-component'
        'Origin'      = $BaseUrl
        'Referer'     = "$BaseUrl/login"
        'Next-Action' = $NextAction
    }
    if ($NextRouterStateTree) { $headers['Next-Router-State-Tree'] = $NextRouterStateTree }

    # Multipart form via -Form (lets PowerShell build boundary correctly)
    $form = [ordered]@{
        '1_username' = $Username
        '1_password' = $Password
        '0'          = $ActionZero     # keep $ signs literal
    }

    Write-Verbose "POST $BaseUrl/login"
    $resp = Invoke-WebRequest "$BaseUrl/login" -Method POST -WebSession $session -Headers $headers -Form $form -SkipHttpErrorCheck

    # Basic sanity check: do we have a 'session' cookie?
    $cookie = $session.Cookies.GetCookies($BaseUrl) | Where-Object Name -eq 'session'
    if (-not $cookie) {
        throw "Login did not produce a 'session' cookie. Check credentials/headers (try adding Next-Router-State-Tree from DevTools)."
    }

    # Return both session and cookie info
    [pscustomobject]@{
        Session  = $session
        Cookie   = $cookie
        Response = $resp
    }
}

# Persist session cookie to disk
function Save-PlexusCookie {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$WebSession,
        [string]$BaseUrl = 'https://plexusgrid.com',
        [string]$Path = "$env:TEMP\plexusgrid_cookie.json"
    )
    $cookie = $WebSession.Cookies.GetCookies($BaseUrl) | Where-Object Name -eq 'session'
    if (-not $cookie) { throw "No 'session' cookie present to save." }
    $cookie | ConvertTo-Json | Set-Content -Path $Path -Encoding UTF8
    Get-Item $Path
}

# Load cookie from disk into a new WebSession
function Import-PlexusSession {
    [CmdletBinding()]
    param(
        [string]$Path = "$env:TEMP\plexusgrid_cookie.json",
        [string]$BaseUrl = 'https://plexusgrid.com'
    )
    if (-not (Test-Path $Path)) { throw "Cookie file not found: $Path" }
    $obj = Get-Content $Path -Raw | ConvertFrom-Json
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $uri = [Uri]$BaseUrl
    $session.Cookies.Add([System.Net.Cookie]::new($obj.Name, $obj.Value, '/', $uri.Host))
    $session
}

# Quick auth test (myDataspaces)
function Test-PlexusAuth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$WebSession,
        [string]$BaseUrl = 'https://plexusgrid.com'
    )
    $resp = Invoke-WebRequest "$BaseUrl/api/data/myDataspaces" -Method GET -WebSession $WebSession -Headers @{Accept='application/json'} -SkipHttpErrorCheck
    [pscustomobject]@{
        StatusCode = $resp.StatusCode
        Body       = $resp.Content
    }
}

# Get config JSON
function Get-PlexusConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$WebSession,
        [string]$BaseUrl = 'https://plexusgrid.com'
    )
    Invoke-RestMethod "$BaseUrl/api/config" -Method GET -WebSession $WebSession -Headers @{Accept='application/json'}
}

# Get realtime JSON
function Get-PlexusRealtime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$WebSession,
        [string]$BaseUrl = 'https://plexusgrid.com'
    )
    Invoke-RestMethod "$BaseUrl/api/data/realtime" -Method GET -WebSession $WebSession -Headers @{Accept='application/json'}
}

# Shape a compact summary object from realtime JSON
function Select-PlexusRealtimeSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Realtime
    )
    [pscustomobject]@{
        Timestamp                 = $Realtime.timestamp
        BatterySOC                = $Realtime.batteryStateOfCharge
        BatteryPower              = $Realtime.batteryActivePower
        GridPower                 = $Realtime.gridPower
        SolarPowerProduction      = $Realtime.solarPowerProduction
        PowerConsumption          = $Realtime.powerConsumption
        GeneratorPowerProduction  = $Realtime.generatorPowerProduction
    }
}

# Simple execution wrapper, that combines auth check, config, realtime, and summary
function Invoke-PlexusRealtime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $WebSession,
        [string]$BaseUrl = 'https://plexusgrid.com',

        # If auth check fails (non-200), throw instead of quietly returning $null
        [switch]$ThrowOnAuthFailure,

        # Return a richer object with Auth, Config, Realtime, and Summary
        [switch]$PassThruAll
    )

    # 1) Auth check (no output)
    $auth = Test-PlexusAuth -WebSession $WebSession -BaseUrl $BaseUrl
    if ($auth.StatusCode -ne 200) {
        $msg = "Auth check failed: $($auth.StatusCode) $($auth.Body)"
        if ($ThrowOnAuthFailure) { throw $msg } else { Write-Verbose $msg; return $null }
    }

    # 2) Fetch config (no output)
    $cfg = Get-PlexusConfig -WebSession $WebSession -BaseUrl $BaseUrl
    if (-not $cfg.dataspace -or -not $cfg.device -or -not $cfg.measurement) {
        throw "No config available (dataspace/device/measurement missing)."
    }

    # 3) Fetch realtime (no output)
    $rt = Get-PlexusRealtime -WebSession $WebSession -BaseUrl $BaseUrl

    # 4) Shape summary (final output by default)
    $summary = Select-PlexusRealtimeSummary -Realtime $rt

    if ($PassThruAll) {
        [pscustomobject]@{
            Auth    = $auth
            Config  = $cfg
            Realtime= $rt
            Summary = $summary
        }
    } else {
        $summary
    }
}

# Set explicitly which Functions to export
Export-ModuleMember -Function New-FolderIfNotExists, New-BearerToken, Get-AddressCoordinate, Get-AddressPriceById, Get-AddressId, Get-JwtExpiryInfo, New-PlexusSession, Save-PlexusCookie, Import-PlexusSession, Test-PlexusAuth, Get-PlexusConfig, Get-PlexusRealtime, Select-PlexusRealtimeSummary, Invoke-PlexusRealtime