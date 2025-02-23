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

# Set explicitly which Functions to export
Export-ModuleMember -Function New-FolderIfNotExists, New-BearerToken, Get-AddressCoordinate, Get-AddressPriceById, Get-AddressId