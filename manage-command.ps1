# This gets all installed versions and uninstalls them except the newest
Get-InstalledModule -Name "Microsoft.WinGet.Client" -AllVersions | Sort-Object Version -Descending | Select-Object -Skip 1 | Uninstall-Module

# This uninstalls a specific version of PSFzf, in this case version 2.7.9
Uninstall-Module -Name "PSFzf" -RequiredVersion 2.7.9

# Only modules active in the current session.
Get-Module	
# All modules found in module paths on the system.
Get-Module -ListAvailable	
# Only modules installed via Install-Module.
Get-InstalledModule	