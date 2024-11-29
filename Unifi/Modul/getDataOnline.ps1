# Parameters
param(
    #[Parameter(Mandatory)]
    [Parameter()]
    [string]$APIkey
)

# Import support modules
Import-Module "..\PowershellCmdlets\psUtilities.psm1"

# Set paths required
$paths = @(
    "Data",
    "Metadata",
    "Data\UI_online"
)

# Ensure each path exists
foreach ($path in $paths) {
    New-FolderIfNotExists -Path $path -Verbose
}

# Set date and time for file identification
$DateTime = (Get-Date).ToString("yyyyMMddHHss")

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Accept", "application/json")
$headers.Add("X-API-KEY", "$APIkey")

# Send the web request and store the response
$response = Invoke-WebRequest 'https://api.ui.com/ea/hosts' -Method 'GET' -Headers $headers -SessionVariable session
#$response = Invoke-WebRequest 'https://api.ui.com/ea/devices?hostIds[]=abd19fc6-de2e-4bb9-a19a-e93d5b6886c6' -Method 'GET' -Headers $headers -SessionVariable session

# Decode the HTML content
$jsonContent = [System.Web.HttpUtility]::HtmlDecode($response.Content)

# Convert the string to a PowerShell object for better formatting (optional)
$jsonObject = $jsonContent | ConvertFrom-Json

# Save the formatted JSON to a file
$jsonObject | ConvertTo-Json -Depth 10 | Out-File -FilePath .\Data\UI_online\$DateTime.json -Encoding UTF8
