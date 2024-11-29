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
    # Resolve the relative path to an absolute path
    $absolutePath = (Resolve-Path $path).Path
    New-FolderIfNotExists -Path $absolutePath -Verbose
}

# Set date and time for file identification
$DateTime = (Get-Date).ToString("yyyyMMddHHss")

# Send the web request and store the response
$response = Invoke-WebRequest -Uri "https://www.stokercloud.dk/dev/getjsondriftdata.php?mac=$User"

# Extract the content and decode HTML entities
$decodedContent = [System.Web.HttpUtility]::HtmlDecode($response.Content)

# Convert the decoded content to JSON
$decodedContent | ConvertFrom-Json | Out-File -FilePath .\Data\$DateTime.json
