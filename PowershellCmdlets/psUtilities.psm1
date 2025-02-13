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

# Set explicitly which Functions to export
Export-ModuleMember -Function New-FolderIfNotExists, New-BearerToken