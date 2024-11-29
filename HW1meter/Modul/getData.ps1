# Parameters
param(
    [Parameter(Mandatory)]
    [string]$Ipaddress
)

# Import support modules
Import-Module "..\PowershellCmdlets\psUtilities.psm1"

# Set paths required
$paths = @(
    "Data",
    "Metadata"
)

# Ensure each path exists
foreach ($path in $paths) {
    New-FolderIfNotExists -Path $path -Verbose
}

# Set date and time for file identification
$DateTime = (Get-Date).ToString("yyyyMMddHHss")

# Send the web request and store the response
$response = Invoke-WebRequest -Uri "http://$Ipaddress/api/v1/data"

# Decode the HTML content
$jsonContent = [System.Web.HttpUtility]::HtmlDecode($response.Content)

# Convert the string to a PowerShell object for better formatting (optional)
$jsonObject = $jsonContent | ConvertFrom-Json

# Save the formatted JSON to a file
$jsonObject | ConvertTo-Json -Depth 10 | Out-File -FilePath .\Data\$DateTime.json -Encoding UTF8
