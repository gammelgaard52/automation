# Parameters
param (
    [Parameter(Mandatory = $true)]
    [string]$apikey,
    [Parameter(Mandatory = $true)]
    [string]$apiSecret
)

# Your API credentials
$apiKey = "FE9D8AA7-E8C7-4C24-9EF3-C7ACF0CA4FC4"
$apiSecret = "6ab5ce6b78d8b3647267b8c04af2822186ddf6a54c2cefa8f98c6e9cee6d74b3"

# Import support modules
Import-Module "..\PowershellCmdlets\psUtilities.psm1"

$base64Token = New-BearerToken -apiKey $apiKey -apiSecret $apiSecret

$headers = @{
    "Authorization" = "Bearer $base64Token"
}

$response = Invoke-RestMethod -Uri "https://api.minstroem.app/thirdParty/prices/DK1" -Method Get -Headers $headers

# Decode the HTML content
$decodedContent = [System.Web.HttpUtility]::HtmlDecode($response.Content)

# Convert the string to a PowerShell object for better formatting (optional)
$decodedObject = $decodedContent | ConvertFrom-Json

# Save the formatted JSON to a file
$decodedObject | ConvertTo-Json -Depth 10 | Out-File -FilePath .\Data\$DateTime.json -Encoding UTF8