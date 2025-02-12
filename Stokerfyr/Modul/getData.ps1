# Parameters
param(
    [Parameter(Mandatory)]
    [string]$User
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
$response = Invoke-WebRequest -Uri "https://www.stokercloud.dk/dev/getjsondriftdata.php?mac=$User"

# Decode the HTML content
$decodedContent = [System.Web.HttpUtility]::HtmlDecode($response.Content)

# Convert the string to a PowerShell object for better formatting (optional)
$decodedObject = $decodedContent | ConvertFrom-Json

# Save the formatted JSON to a file
$decodedObject | ConvertTo-Json -Depth 10 | Out-File -FilePath .\Data\$DateTime.json -Encoding UTF8
