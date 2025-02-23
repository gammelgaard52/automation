# Convert current time to EPOC
$epochMilliseconds = [datetimeOffset]::New((Get-Date)).ToUnixTimeMilliseconds()

# Define API Endpoints
$endpoints = @{
    "years"  = "https://www.stokercloud.dk/dev/getjsonusagenew.php?mac=gammelgaard_mink&years=12&$epochMilliseconds"
    "months" = "https://www.stokercloud.dk/dev/getjsonusagenew.php?mac=gammelgaard_mink&months=12&$epochMilliseconds"
    "days"   = "https://www.stokercloud.dk/dev/getjsonusagenew.php?mac=gammelgaard_mink&days=24&$epochMilliseconds"
    "hours"  = "https://www.stokercloud.dk/dev/getjsonusagenew.php?mac=gammelgaard_mink&hours=24&$epochMilliseconds"
}

# New endpoint for drift data
$driftApiUrl = "https://www.stokercloud.dk/dev/getjsondriftdata.php?mac=gammelgaard_mink"

# Function to process API response
function Process-ApiData($data, $timeUnit) {
    # Filter out "Pilleforbrug"
    $filteredData = $data | Where-Object { $_.label -ne "Pilleforbrug VVB" }

    # Convert Epoch timestamps and structure data
    $processedData = @{ }
    foreach ($entry in $filteredData) {
        foreach ($record in $entry.data) {
            # Convert Epoch to human-readable time
            $dateTime = [datetimeOffset]::FromUnixTimeMilliseconds($record[0]).ToLocalTime()

            # Extract time unit based on endpoint
            $timeKey = switch ($timeUnit) {
                "years"  { $dateTime.Year }
                "months" { "$($dateTime.Year)-$($dateTime.Month.ToString("00"))" }
                "days"   { "$($dateTime.Year)-$($dateTime.Month.ToString("00"))-$($dateTime.Day.ToString("00"))" }
                "hours"  { "$($dateTime.Year)-$($dateTime.Month.ToString("00"))-$($dateTime.Day.ToString("00")) $($dateTime.Hour):00" }
            }

            # Summarize data by time unit
            if (-not $processedData[$timeKey]) {
                $processedData[$timeKey] = 0
            }
            $processedData[$timeKey] += $record[1]
        }
    }

    # Convert dictionary to sorted array of objects
    return $processedData.GetEnumerator() | Sort-Object Name | ForEach-Object {
        $value = $_.Value

        # Adjust rounding according to the time unit
        $roundedValue = switch ($timeUnit) {
            "years"  { [math]::Round($value, 0) }   # No decimal
            "months" { [math]::Round($value, 0) }   # No decimal
            "days"   { [math]::Round($value, 1) }   # 1 decimal
            "hours"  { [math]::Round($value, 2) }   # 2 decimals
        }

        [PSCustomObject]@{
            TimeUnit  = $_.Key
            KiloGram  = $roundedValue
        }
    }
}

# Function to process Drift Data (new endpoint)
# Function to process Drift Data (new endpoint)
function Process-DriftData($data) {
    return $data  # No need to wrap the data in another object
}

# Initialize results container
$jsonResult = @{ }

# Query each endpoint and process data
foreach ($timeUnit in $endpoints.Keys) {
    $response = Invoke-WebRequest -Uri $endpoints[$timeUnit] -UseBasicParsing
    $data = $response.Content | ConvertFrom-Json
    $jsonResult[$timeUnit] = Process-ApiData $data $timeUnit
}

# Query the new drift data endpoint
$driftResponse = Invoke-WebRequest -Uri $driftApiUrl -UseBasicParsing
$decodedContent = [System.Web.HttpUtility]::HtmlDecode($driftResponse.Content)
$driftData = $decodedContent | ConvertFrom-Json
$jsonResult["driftData"] = Process-DriftData $driftData

# Set date and time for file identification
$DateTime = (Get-Date).ToString("yyyyMMddHHss")

# Define JSON output file path
$outputFile = "$DateTime.json"

# Save structured JSON output
$jsonResult | ConvertTo-Json -Depth 10 | Out-File -FilePath .\Data\$outputFile -Encoding UTF8

# Confirm success
Write-Output "Data successfully saved to $outputFile"
