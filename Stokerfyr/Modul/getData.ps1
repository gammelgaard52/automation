# Send the web request and store the response
$response = Invoke-WebRequest -Uri "https://www.stokercloud.dk/dev/getjsondriftdata.php?mac=dahl"

# Extract the content and decode HTML entities
$decodedContent = [System.Web.HttpUtility]::HtmlDecode($response.Content)

# Convert the decoded content to JSON
$jsonData = $decodedContent | ConvertFrom-Json

# Output the JSON object
$jsonData
