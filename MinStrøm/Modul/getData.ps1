# Parameters
param (
    [Parameter(Mandatory = $true)]
    [string]$apikey,
    [Parameter(Mandatory = $true)]
    [string]$apiSecret
)

# Import support modules
Import-Module "..\PowershellCmdlets\psUtilities.psm1"

$base64Token = New-BearerToken -apiKey $apiKey -apiSecret $apiSecret

# Set date and time for file identification
$DateTime = (Get-Date).ToString("yyyyMMddHHss")

$headers = @{
    "Authorization" = "Bearer $base64Token"
}

# Send the web request and store the response
$response = Invoke-RestMethod -Uri "https://api.minstroem.app/thirdParty/prices/DK1" -Method Get -Headers $headers

# Save the formatted JSON to a file
$response | ConvertTo-Json -Depth 10 | Out-File -FilePath .\Data\$DateTime.json -Encoding UTF8
