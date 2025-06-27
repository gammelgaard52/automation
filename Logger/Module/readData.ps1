# Parameters
param (
    [ValidateSet("Now", "Hour", "DailySummary")]
    [string]$Mode = "Now"
)

$global:LogPath = "Data\data.jsonl"

$global:FriendlyLabels = @{
    activePowerPOC      = "Transferred to grid"
    activePowerInverter = "Inverter output (grid + house)"
    activePowerUsage    = "Current usage in house"
    activePowerSolar    = "Solar cell generation"
    batterySOC          = "Battery charge"
}

function Load-InverterData {
    $entries = @()
    Get-Content -Path $global:LogPath | ForEach-Object {
        try {
            $json = $_ | ConvertFrom-Json
            if ($json.messageType -eq "deviceData") {
                $timestamp = Get-Date $json.timestamp
                $entries += [PSCustomObject]@{
                    Timestamp           = $timestamp
                    activePowerPOC      = [double]$json.activePowerPOC
                    activePowerInverter = [double]$json.activePowerInverter
                    activePowerUsage    = [double]$json.activePowerUsage
                    activePowerSolar    = [double]$json.activePowerSolar
                    batterySOC          = [double]$json.batterySOC
                }
            }
        } catch {
            Write-Warning "Failed to parse line: $_"
        }
    }
    return $entries
}

function Get-AverageRecord {
    param (
        [datetime]$timestamp,
        [pscustomobject[]]$records,
        [string]$label
    )

    return [PSCustomObject]@{
        Timestamp = "$($label): $($timestamp.ToString('yyyy-MM-dd HH:mm'))"
        activePowerPOC      = ($records | Measure-Object -Property activePowerPOC -Average).Average
        activePowerInverter = ($records | Measure-Object -Property activePowerInverter -Average).Average
        activePowerUsage    = ($records | Measure-Object -Property activePowerUsage -Average).Average
        activePowerSolar    = ($records | Measure-Object -Property activePowerSolar -Average).Average
        batterySOC          = ($records | Measure-Object -Property batterySOC -Average).Average
    }
}

function Show-FriendlyOutput {
    param (
        [pscustomobject[]]$records
    )

    $records |
        Select-Object @(
            @{ Name = 'Timestamp'; Expression = { $_.Timestamp } },
            @{ Name = "$($global:FriendlyLabels.activePowerPOC) (W)"; Expression = { "{0:N1}" -f $_.activePowerPOC } },
            @{ Name = "$($global:FriendlyLabels.activePowerInverter) (W)"; Expression = { "{0:N1}" -f $_.activePowerInverter } },
            @{ Name = "$($global:FriendlyLabels.activePowerUsage) (W)"; Expression = { "{0:N1}" -f $_.activePowerUsage } },
            @{ Name = "$($global:FriendlyLabels.activePowerSolar) (W)"; Expression = { "{0:N1}" -f $_.activePowerSolar } },
            @{ Name = "$($global:FriendlyLabels.batterySOC) (%)"; Expression = { "{0:N0}" -f $_.batterySOC } }
        ) | Format-Table -AutoSize
}

function Show-Now {
    $data = Load-InverterData
    $latest = $data | Sort-Object Timestamp -Descending | Select-Object -First 1

    $latest.Timestamp = "Latest reading: $($latest.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))"
    Show-FriendlyOutput -records @($latest)
}


function Show-HourAverage {
    $cutoff = (Get-Date).AddHours(-1)
    $data = Load-InverterData | Where-Object { $_.Timestamp -ge $cutoff }

    if ($data.Count -eq 0) {
        Write-Host "No data found in the last hour."
        return
    }

    $average = Get-AverageRecord -timestamp (Get-Date) -records $data -label "Average (last hour)"
    Show-FriendlyOutput -records @($average)
}


function Show-DailySummary {
    $data = Load-InverterData
    $dailyGroups = $data | Group-Object { $_.Timestamp.Date }

    $summaries = @()
    foreach ($group in $dailyGroups) {
        $summary = Get-AverageRecord -timestamp (Get-Date $group.Name) -records $group.Group -label "Average (daily)"
        $summaries += $summary
    }

    Show-FriendlyOutput -records $summaries
}


function Show-Help {
    Write-Host "Usage: .\readData.ps1 -Mode [Now | Hour | DailySummary]"
    Write-Host "  Now            - Show the latest real-time reading"
    Write-Host "  Hour           - Show average over the last hour"
    Write-Host "  DailySummary  - Show daily average grouped by day"
}


# Main
switch ($Mode) {
    "Now"            { Show-Now }
    "Hour"           { Show-HourAverage }
    "DailySummary"  { Show-DailySummary }
    default          { Show-Help }
}
