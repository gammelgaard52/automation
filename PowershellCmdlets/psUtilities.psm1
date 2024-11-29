function New-FolderIfNotExists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path
    )
    
    # Check if the folder exists
    if (-Not ((Resolve-Path $path).Path)) {
        # Create the folder if it doesn't exist
        New-Item -ItemType Directory -Path $Path | Out-Null
        Write-Verbose "Folder created: $Path"
    } else {
        Write-Verbose "Folder already exists: $Path"
    }
}
