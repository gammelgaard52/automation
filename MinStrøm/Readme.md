# Extract telemetry from utility company

This code will extract data from Min Strøm API using PowerShell

## Access to Min Strøm

Request API access directly in their online chat found at <https://minstroem.app/contact>
You will then receive a API key and API secret, that will used as input in [run.ps1](run.ps1)

## API documentation

Documentation can be found at <https://docs.minstroem.app/api-reference/endpoints#parameters>

## Generate access to Eloverblik

Execute this in browser: <https://api.minstroem.app/thirdParty/users/martin/connectAddress> and authenticate with MitID
You are new directed to a new site - accept the terms and conditions
When redirected to Min Strøm, you complete part 1 - Get Access
Now you can use the script
