# https://ubntwiki.com/products/software/unifi-controller/api

# Parameters
param(
    [Parameter(Mandatory)]
    [string]$Username,
    [Parameter(Mandatory)]
    [string]$Password,
    [Parameter(Mandatory)]
    [string]$udmIP
)

# Import support modules
Import-Module "..\PowershellCmdlets\psUtilities.psm1"

# Set paths required
$paths = @(
    "Data",
    "Metadata",
    "Data\udm_local"
)

# Ensure each path exists
foreach ($path in $paths) {
    New-FolderIfNotExists -Path $path -Verbose
}

# Set date and time for file identification
$DateTime = (Get-Date).ToString("yyyyMMddHHss")

# Define the session variable
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

# Step 1: Initial Request to Get the Cookie or Token
$response = Invoke-WebRequest -Uri ("https://"+$udmIP+":443/api/auth/login") -Method POST `
    -Body @{username="$Username"; password="$Password"} `
    -WebSession $session `
    -SkipCertificateCheck

# Step 2: Perform the subsequent request using the same session
## With prefix (controller endpoints)
$api1 = "api/self"
$api1method = "GET"
$response = Invoke-WebRequest -Uri "https://$udmIP/proxy/network/$api1" -Method $api1method -WebSession $session -SkipCertificateCheck

## Without prefix (site endpoints)
$api2 = "stat/sta" # "stat/sta" lister all klienter på netværket og her kan ses om der er pakke tab eller retries, ovs.
$api2method = "GET"
$response = Invoke-WebRequest -Uri "https://$udmIP/proxy/network/api/s/default/$api2" -Method $api2method -WebSession $session -SkipCertificateCheck

# Decode the HTML content
$jsonContent = [System.Web.HttpUtility]::HtmlDecode($response.Content)

# Convert the string to a PowerShell object for better formatting (optional)
$jsonObject = $jsonContent | ConvertFrom-Json

# Save the formatted JSON to a file
$jsonObject | ConvertTo-Json -Depth 10 | Out-File -FilePath .\Data\udm_local\$DateTime.json -Encoding UTF8