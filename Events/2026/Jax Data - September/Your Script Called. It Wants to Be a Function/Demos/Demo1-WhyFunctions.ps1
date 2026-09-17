
#region The Problem - copy/paste your way to pain
Clear-Host
# Check max memory on a server - works great for one server
Get-DbaMaxMemory -SqlInstance 'INLAP-WKS11068\SQL2022DE'

# Now check a second server... here comes copy/paste
Get-DbaMaxMemory -SqlInstance 'INLAP-WKS11068\SQL2019DE'

# What if the logic changes? You update it in 2 places. Then 5. Then 20.
    
#endregion

#region Step up: pull instances from registered servers
Clear-Host
Get-DbaRegisteredServer -Group Demo |
ForEach-Object { Get-DbaMaxMemory -SqlInstance $_.Name }

# no hardcoded list - but every caller still has to know this pattern
# and we can't reuse it without copy-pasting the whole block
#endregion

#region The payoff - where we'll be by the end of this talk
Clear-Host
<#
        Get-DbaRegisteredServer -Group Demo |
            Get-SQLServerInventory -path "c:\temp' |
    #>

# one line: all your registered servers, a full health report, in Excel.
# Let's build Get-SQLServerInventory from scratch.
#endregion

#region Functions are first-class citizens in PowerShell
Clear-Host
function Get-SQLServerInventory {
    # we'll fill this in as the talk progresses
}

# PowerShell treats it exactly like any cmdlet
Get-Command Get-SQLServerInventory | Select-Object Name, CommandType, Module
Get-Help Get-SQLServerInventory -ShowWindow
#endregion
