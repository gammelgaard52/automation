<#
.SYNOPSIS
  Logs real-time inverter telemetry from a WebSocket-enabled logger device (e.g., AEG/Goodwee).

.DESCRIPTION
  This script connects to a WebSocket endpoint provided by a local logger device (typically connected via RS485 to an inverter),
  receives real-time device data, and writes structured JSON objects to a .jsonl log file.

.PARAMETER WsUri
  The full WebSocket URI of the logger (e.g., ws://10.0.0.2/ws).

.EXAMPLE
  .\getData.ps1 -WsUri "ws://10.0.0.2/ws"
#>
param (
    [Parameter(Mandatory = $true, HelpMessage = "WebSocket URI of the logger device (e.g. ws://10.0.0.2/ws)")]
    [string]$WsUri
)

function Initialize-WebSocketClient {
    <#
    .SYNOPSIS
        Initializes and connects a WebSocket client to the logger.
    .OUTPUTS
        [System.Net.WebSockets.ClientWebSocket]
    #>
    Add-Type -AssemblyName System.Net.WebSockets.Client
    Add-Type -AssemblyName System.Runtime

    $uri = [Uri]$WsUri
    $client = [System.Net.WebSockets.ClientWebSocket]::new()
    $null = $client.ConnectAsync($uri, [System.Threading.CancellationToken]::None).Result
    return $client
}

function Read-NextMessage {
    <#
    .SYNOPSIS
        Reads the next WebSocket message as a UTF-8 string.
    .PARAMETER client
        An active ClientWebSocket object.
    .OUTPUTS
        [string]
    #>
    param (
        [System.Net.WebSockets.ClientWebSocket]$client
    )

    $buffer = New-Object 'System.Byte[]' 4096
    $segment = [System.ArraySegment[byte]]::new($buffer, 0, $buffer.Length)
    $result = $client.ReceiveAsync($segment, [System.Threading.CancellationToken]::None).Result
    $text = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $result.Count)
    return $text.Trim()
}

function Handle-DeviceData {
    <#
    .SYNOPSIS
        Parses and stores inverter data messages to JSONL log.
    .PARAMETER jsonText
        The raw message as a string.
    #>
    param (
        [string]$jsonText
    )

    try {
        $json = $jsonText | ConvertFrom-Json
        if ($json.messageType -eq "deviceData") {
            $json | Add-Member -NotePropertyName "timestamp" -NotePropertyValue (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            Write-Host "[$($json.timestamp)] activePowerPOC: $($json.activePowerPOC) batterySOC: $($json.batterySOC)"
            $json | ConvertTo-Json -Depth 5 -Compress | Out-File -FilePath .\Data\data.jsonl -Append -Encoding UTF8
        }
    } catch {
        Write-Warning "Failed to parse or process JSON: $_"
    }
}

function Start-Logger {
    <#
    .SYNOPSIS
        Starts the WebSocket logger loop and writes to file.
    #>
    $client = Initialize-WebSocketClient

    while ($true) {
        $text = Read-NextMessage -client $client
        if ($text) {
            Handle-DeviceData -jsonText $text
        }
        Start-Sleep -Milliseconds 200
    }
}

# ▶️ Entry Point
Start-Logger
