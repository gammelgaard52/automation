# Extract inverter data from Goodwee and AEG

This code will extract data from Goodwee and AEG inverters using PowerShell

## Example execution

Use the email and password from [Sems portal](https://semsportal.com/Home/Login), as well as the Powerstation id, listen in the URL after successful login to Sems portal
`https://semsportal.com/PowerStation/PowerStatusSnMin/xxxxaed6-xxxx-xxxx-xxxx-fa248349xxxx`

.\Solceller\Module\getData.ps1 `
-Email "YourEmailUsedToLogin" `
-Password (ConvertTo-SecureString "YourPasswordUsedToLogin" -AsPlainText -Force) `
-Powerstation_Id "PowerstationIdFromUrl"

or use the run.ps1 and fill with your parameters file

Credits to original creator of script
`https://terravolt.co.uk/api-integrations/goodwe-api-integrations/`
