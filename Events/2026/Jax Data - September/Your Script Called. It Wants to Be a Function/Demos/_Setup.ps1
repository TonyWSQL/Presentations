#Requires -modules  @{ ModuleName="dbatools";  ModuleVersion="2.7.0" }
#Requires -modules  @{ ModuleName="ImportExcel";  ModuleVersion="7.8.0" }

Get-DbaService -ComputerName localhost -Type Engine |
    where-object { $_.State -ne 'Running' } |
    Start-DbaService -Verbose 

