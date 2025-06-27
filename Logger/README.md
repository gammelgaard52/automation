# Inverter Logger (<company_name>)

This PowerShell-based toolset lets you collect and analyze real-time inverter data from WebSocket-enabled inverter Loggers such as **company_name**.

## 🧩 Modules

- `Modules/getData.ps1`  
  Connects to a WebSocket endpoint and logs device data to a `.jsonl` file.

- `Modules/readData.ps1`  
  Reads and analyzes the `.jsonl` file with output options like latest, hourly average, and daily summaries.

## 🚀 Example Usage

### Log data from your inverter Logger device (WebSocket required)

```powershell
.\Modules\getData.ps1 `
  -WsUri "ws://10.0.0.2/ws"
```

> ℹ️ Replace the WebSocket IP and file path with your local configuration.

### Read data from JSON log

```powershell
.\Modules\readData.ps1 -Mode Now
.\Modules\readData.ps1 -Mode Hour
.\Modules\readData.ps1 -Mode DailySummary
```

## 🧪 Output Modes

| Mode           | Description                            |
|----------------|----------------------------------------|
| `Now`          | Show the latest real-time data entry   |
| `Hour`         | Calculate average from the past hour   |
| `DailySummary` | Show daily averages grouped by date    |

## 📝 Notes

- Data is saved in JSON Lines format (`.jsonl`)
- Only `deviceData` messages are recorded
- You can schedule `getData.ps1` with Task Scheduler for continuous collection
- Data must be collected using a separate WebSocket logger (not included here).
- The `readData.ps1` expects data entries in JSONL format, each line like:

```json
{"messageType":"deviceData","deviceType":"Inverter","activePowerPOC":363,"activePowerInverter":1063,"activePowerSolar":1132,"activePowerBattery":-19,"activePowerGenerator":0,"activePowerUsage":700,"batterySOC":96,"timestamp":"2025-06-27 20:09:50"}
```

## 🙏 Credits

**company_name**

---

Created for analyzing inverter logger telemetry from Goodwee / AEG inverters connected via RS485 to a WebSocket gateway (e.g. custom ESP or vendor logger).
