cls
#region Setup
($svr = Get-DbaRegisteredServer -Group Demo)
#endregion

#region Concept: untyped param
Clear-Host
function Get-SQLServerInventory {
    param($SqlInstance, $path)
    Get-DbaMaxMemory -SqlInstance $SqlInstance
}
Get-SQLServerInventory -SqlInstance $svr[0].Name
#endregion

#region Concept: typed param - [DbaInstance] understands server names, instance names, and SMO objects
Clear-Host
function Get-SQLServerInventory {
    param(
        [DbaInstance]$SqlInstance,
        [string]$path
    )
    Get-DbaMaxMemory -SqlInstance $SqlInstance
}
Get-SQLServerInventory -SqlInstance 99  # wrong type - fails at the boundary
Get-SQLServerInventory -SqlInstance $svr[0].Name
#endregion

#region Concept mandatory parameters
Clear-Host
function Get-SQLServerInventory {
    param(
        [Parameter(Mandatory)]
        [DbaInstance]$SqlInstance,
        [string]$path = 'C:\temp'
    )
    Get-DbaMaxMemory -SqlInstance $SqlInstance
}
Get-SQLServerInventory -SqlInstance $svr[0].Name
Get-SQLServerInventory # fails because the mandatory parameter was not supplied

#endregion

#region Concept: Parameter sets and default parameter values
Clear-Host

function Get-SQLServerInventory {
    param(
        [Parameter(Mandatory)]
        [DbaInstance]$SqlInstance,
        [Parameter(parameterSetName = 'Export')]
        [string]$Path = 'C:\temp',
        [Parameter(parameterSetName = 'Export')]
        [switch]$Export
    )

    # Build a unique, timestamped workbook path once, up front, if exporting was requested
    if ($PSBoundParameters.ContainsKey('Path') -or $PSCmdlet.ParameterSetName -eq 'Export') {
        $exportPath = join-path -Path $Path -ChildPath ("SQL_Inventory_{0}.xlsx" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
    }
    
    "Parameter set: $($PSCmdlet.ParameterSetName)"
    "Write export for {0} to $exportPath" -f $sqlInstance.InstanceName
}

Get-SQLServerInventory -SqlInstance $svr[0].Name
Get-SQLServerInventory -SqlInstance $svr[0].Name -export
Get-SQLServerInventory -SqlInstance $svr[0].Name -path 'C:\temp_export'
#endregion

#region Concept: Connect-DbaInstance - the SMO server object
Clear-Host
# most dbatools commands connect under the hood - this gives you direct access
$server = Connect-DbaInstance -SqlInstance $svr[0].Name
$server

# the object has everything you need about the instance
$server.NetName
$server.Edition
$server.Version
$server.IsHadrEnabled
$server.LoginMode
$server.Configuration.MaxServerMemory.ConfigValue
$server.Configuration.MaxDegreeOfParallelism.ConfigValue
$server.Configuration.CostThresholdForParallelism.ConfigValue
#endregion

# -----------------------------------------------------------------------
#region Get-SQLServerInventory v1 - param block, returns structured identity data
Clear-Host
function Get-SQLServerInventory {
    param(
        [Parameter(Mandatory)]
        [DbaInstance]$SqlInstance,
        [Parameter(parameterSetName = 'Export')]
        [string]$Path = 'C:\temp',
        [Parameter(parameterSetName = 'Export')]
        [switch]$Export
    )

    $server = Connect-DbaInstance -SqlInstance $SqlInstance

    [PSCustomObject]@{
        ComputerName = $server.NetName
        SqlInstance  = $SqlInstance
        Edition      = $server.Edition
        Build        = $server.Version.ToString()
    }
}

Get-SQLServerInventory -SqlInstance $svr[1].Name
Get-SQLServerInventory -SqlInstance $svr[1].Name | Format-Table -AutoSize
#endregion
