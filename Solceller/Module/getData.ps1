#####User details here#####
##Givenergy Portal API Key Goes Below between " "
param(
    [Parameter(Mandatory)]
    [string]$Email,
    [Parameter(Mandatory)]
    [securestring]$Password,
    [Parameter(Mandatory)]
    [string]$Powerstation_Id
)

# Import support modules
Import-Module "..\PowershellCmdlets\psUtilities.psm1"

# Set paths required
$paths = @(
    "Data",
    "Metadata",
    "Data\InverterAllPoint",
    "Data\PowerFlow"
)

# Ensure each path exists
foreach ($path in $paths) {
    New-FolderIfNotExists -Path $path -Verbose
}

# Set date and time for file identification
$DateTime = (Get-Date).ToString("yyyyMMddHHss")

##Login to SEMS API ##
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("sec-ch-ua", "`" Not A;Brand`";v=`"99`", `"Chromium`";v=`"99`", `"Microsoft Edge`";v=`"99`"")
$headers.Add("Accept", "application/json, text/javascript, */*; q=0.01")
$headers.Add("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8")
$headers.Add("X-Requested-With", "XMLHttpRequest")
$headers.Add("sec-ch-ua-mobile", "?0")
$headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.51 Safari/537.36 Edg/99.0.1150.39")
$headers.Add("sec-ch-ua-platform", "`"Windows`"")
$headers.Add("Origin", "https://eu.semsportal.com")
$headers.Add("Sec-Fetch-Site", "same-origin")
$headers.Add("Sec-Fetch-Mode", "cors")
$headers.Add("Sec-Fetch-Dest", "empty")
$headers.Add("Referer", "https://eu.semsportal.com/home/login")
$headers.Add("Accept-Language", "en-GB,en;q=0.9,en-US;q=0.8")

$body = "account=$Email&pwd="+(ConvertFrom-SecureString -SecureString $Password -AsPlainText)+"&code="

$response = Invoke-WebRequest 'https://eu.semsportal.com/Home/Login' -Method 'POST' -Headers $headers -Body $body -SessionVariable session
$response | Select-Object * | ConvertTo-Json  -Depth 10 | Out-File -FilePath .\Metadata\Login$DateTime.json -Encoding ascii
$session | Select-Object * | ConvertTo-Json  -Depth 10 | Out-File -FilePath.\Metadata\Session$DateTime.json -Encoding ascii
Write-Output "Metadata saved to: .\Metadata\" 

$headers2 = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers2.Add("sec-ch-ua", "`" Not A;Brand`";v=`"99`", `"Chromium`";v=`"99`", `"Microsoft Edge`";v=`"99`"")
$headers2.Add("Accept", "*/*")
$headers2.Add("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8")
$headers2.Add("X-Requested-With", "XMLHttpRequest")
$headers2.Add("sec-ch-ua-mobile", "?0")
$headers2.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.51 Safari/537.36 Edg/99.0.1150.39")
$headers2.Add("sec-ch-ua-platform", "`"Windows`"")
$headers2.Add("Origin", "https://eu.semsportal.com")
$headers2.Add("Sec-Fetch-Site", "same-origin")
$headers2.Add("Sec-Fetch-Mode", "cors")
$headers2.Add("Sec-Fetch-Dest", "empty")
$headers2.Add("Referer", "https://eu.semsportal.com/PowerStation/PowerStatusSnMin/$Powerstation_Id")
$headers2.Add("Accept-Language", "en-GB,en;q=0.9,en-US;q=0.8")

$body2 = "str=%7B%22api%22%3A%22%2Fv3%2FPowerStation%2FGetInverterAllPoint%22%2C%22param%22%3A%7B%22powerStationId%22%3A%22$Powerstation_Id%22%7D%7D"

$response2 = Invoke-RestMethod 'https://eu.semsportal.com/GopsApi/Post?s=/v3/PowerStation/GetInverterAllPoint' -Method 'POST' -Headers $headers2 -Body $body2 -WebSession $session
$response2 | ConvertTo-Json -Depth 10 | Out-File -FilePath .\Data\InverterAllPoint\IAP$DateTime.txt -Encoding ASCII

#https://eu.semsportal.com/api/v2/PowerStation/GetPowerflow
$body3 = "str=%7B%22api%22%3A%22%2Fv2%2FPowerStation%2FGetPowerflow%22%2C%22param%22%3A%7B%22powerStationId%22%3A%22$Powerstation_Id%22%7D%7D"

$response3 = Invoke-RestMethod 'https://eu.semsportal.com/GopsApi/Post?s=/v2/PowerStation/GetPowerflow' -Method 'POST' -Headers $headers2 -Body $body3 -WebSession $session
$response3 | ConvertTo-Json -Depth 10 | Out-File -FilePath .\Data\PowerFlow\PF$DateTime.txt -Encoding ASCII

Write-Output "Data Saved to .\Data\<category>"
Write-Output "All done - Closing Powershell in 3...." 
start-sleep -s 3

Exit