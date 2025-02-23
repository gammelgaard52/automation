# Parameters
param (
    [Parameter(Mandatory = $true,
    HelpMessage = "API Key obtained through Min Strøm")]
    [string]$apiKey,
    [Parameter(Mandatory = $true,
    HelpMessage = "API Secret obtained through Min Strøm")]
    [string]$apiSecret,
    [Parameter(Mandatory = $false,
    HelpMessage = "Region of where to get utility data. Denmark is divided into 2 regions, west=DK1 and east=DK2.")]
    [string]$region = "DK1",
    [Parameter(Mandatory = $true,
    HelpMessage = "Full address of target meter data")]
    [string]$fullAddress,
    [Parameter(Mandatory = $true,
    HelpMessage = 'Set the User ID - used when first initiated the connection to Eloverblik ("Get access")')]
    [string]$userId
)

# Import support modules
Import-Module "..\PowershellCmdlets\psUtilities.psm1"

$base64Token = New-BearerToken -apiKey $apiKey -apiSecret $apiSecret
#$base64Token | Out-File .\Metadata\token.txt

# Set date and time for file identification
$DateTime = (Get-Date).ToString("yyyyMMddHHss")

# Set header with bearer token
$headers = @{
    "Authorization" = "Bearer $base64Token"
}

# Get SPOT prices
$spotPrices = Invoke-RestMethod -Uri "https://api.minstroem.app/thirdParty/prices/DK1" -Method Get -Headers $headers

# Get address id
$addressId = Get-AddressId -userId $userId

# Create an empty array to store all price responses
$pricePerAddress = @()

# Append the response to the array as a proper object
$pricePerAddress += @{
    "address" = $addressId.fullAddress
    "prices" = Get-AddressPriceById $addressId.id
    "note" = "Two things to account for. A - Add your own cost from your Utility provider. B - Remember to account for timezone, since this is recorded in Coordinated Universal Time (UTC). Add +1 for Danish local time and +2 in Summer Time"
}

# Amount of requests used per day
#Invoke-RestMethod -Uri "https://api.minstroem.app/thirdParty/currentRequestCount" -Method Get -Headers $headers
# Husk at introducere en limit på 50 kald per dag. Måske noget med den gemmer noget data i metadata og laver noget lookup deri og incrementor for hvert interface der er spurgt efter data.

# Get a date that is ISO8601 format
#$isoDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
#Write-Host $isoDate

# Get coordinates from address
#$coords = Get-AddressCoordinate -fullAddress $fullAddress

# Lookup tariff by coordinate
#Invoke-RestMethod -Uri "https://api.minstroem.app/thirdParty/prices/charges/location?latitude=$($coords.latitude)&longitude=$($coords.longitude)&date=$($isoDate)" -Method Get -Headers $headers
#Invoke-RestMethod -Uri "https://api.minstroem.app/thirdParty/prices/charges/location?latitude=56.864496&longitude=9.507283&date=2025-02-15" -Method Get -Headers $headers

# Full price incl tariff by coordinate
#$pricePerCoordinate = Invoke-RestMethod -Uri "https://api.minstroem.app/thirdParty/prices/location?latitude=$($coords.latitude)&longitude=$($coords.longitude)" -Method Get -Headers $headers

# Combine all data into a single object
$combinedData = @{
    "spotPricesRegion$($region)" = $spotPrices
    #"addressTable" = $addressTable
    "fullPriceInclTariffPerAddress" = $pricePerAddress
    #"fullPriceInclTariffPerCoordinate" = $pricePerCoordinate
}

# Convert the combined data to JSON and save to a file
$combinedData | ConvertTo-Json -Depth 10 | Out-File -FilePath .\Data\$DateTime.json -Encoding UTF8