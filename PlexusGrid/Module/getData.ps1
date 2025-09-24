param (
    [Parameter(Mandatory = $true, HelpMessage = "Insert username for PlexusGrid account")]
    [string]$Username,
    [Parameter(Mandatory = $true, HelpMessage = "Insert password for PlexusGrid account")]
    [string]$Password
)

# Import support modules
Import-Module ".\PowershellCmdlets\psUtilities.psm1"

# 1) Login and get a session
$auth = New-PlexusSession -Username $Username -Password $Password -Verbose
$session = $auth.Session

# 2) Get live data
Invoke-PlexusRealtime -WebSession $session
<#
# 3) (Optional) see cookie expiry
$jwt = ($session.Cookies.GetCookies('https://plexusgrid.com') | ? Name -eq 'session').Value
Get-JwtExpiryInfo -Jwt $jwt

# 4) Persist cookie to reuse later
Save-PlexusCookie -WebSession $session -Path "$env:TEMP\plexusgrid_cookie.json"

# ...later / new shell...
$session2 = Import-PlexusSession -Path "$env:TEMP\plexusgrid_cookie.json"
Test-PlexusAuth -WebSession $session2
$rt2 = Get-PlexusRealtime -WebSession $session2
Select-PlexusRealtimeSummary -Realtime $rt2
#>

