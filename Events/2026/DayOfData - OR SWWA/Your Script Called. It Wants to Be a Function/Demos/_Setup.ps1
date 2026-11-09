#Requires -RunAsAdministrator
#Requires -modules  @{ ModuleName="dbatools";  ModuleVersion="2.7.0" }
#Requires -modules  @{ ModuleName="ImportExcel";  ModuleVersion="7.8.0" }

# dot source this file to get the demo functions in your session
Start-DbaService -ComputerName $env:COMPUTERNAME -Type Engine |
    Format-Table -a
