Clear-Host 

#region these require internet connectivity (for the PSGallery) 
    Install-Module -Name dbatools -Scope CurrentUser 
    <# scope options
        AllUsers - This will install the module for all users, requires an elevated command prompt
            Default for Powershell < 6.0
        CurrentUser - This will install the module for only the current user
            Default for Powershell 6.0+, unless it's an elevated session
    #>

    Uninstall-Module -Name dbatools 
    Update-Module -Name dbatools  

    Find-Module -Name dbatools -
#endregion

#region These can be ran locally
    
    # from Microsoft.PowerShell.Core module    
        # List all the modules loaded in memory
        Get-Module
        
        # lists the version(s) of the named module in memory
        Get-Module -Name dbatools 

        # Lists the installed versions of the name modules
        Get-Module -Name dbatools -ListAvailable 
    
    # Similar to Get-Module, but from the PowerShellGet module
    Get-InstalledModule -Name dbatools -AllVersions    

    # List all the commands in a given module
    Get-Command -Module dbatools | where name -Match build

    # Load the module into memory
    Import-Module -Name dbatools 
    
    # Removes a module from memory
    Remove-Module -Name dbatools
    
    # getting help on an command
    Get-Help -Name Get-DbaRegisteredServer -ShowWindow
    Get-Help -Name Install-Module -ShowWindow

   
#endregion
