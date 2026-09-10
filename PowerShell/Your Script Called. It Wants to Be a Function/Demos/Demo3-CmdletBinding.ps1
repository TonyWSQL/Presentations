
#region Setup
$svr = Get-DbaRegisteredServer -Group Demo
$Params = @{
    SQLinstance = $svr[0].Name
    Verbose     = $true
}
#endregion

#region Concept: without [CmdletBinding()] - Write-Verbose is silently ignored
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
    Write-Verbose "[$SqlInstance] Connecting..."
    Connect-DbaInstance -SqlInstance $SqlInstance
}
Get-SQLServerInventory @Params  # -Verbose does nothing - [CmdletBinding()] not present yet
Get-Help Get-SQLServerInventory -Parameter *  # no common parameters exist
#endregion

#region Concept: [CmdletBinding()] - one line, all common parameters appear for free
Clear-Host
function Get-SQLServerInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [DbaInstance]$SqlInstance,
        [Parameter(parameterSetName = 'Export')]
        [string]$Path = 'C:\temp',
        [Parameter(parameterSetName = 'Export')]
        [switch]$Export
    )
    Write-Verbose "[$SqlInstance] Connecting..."
    Connect-DbaInstance -SqlInstance $SqlInstance
}
Get-SQLServerInventory @Params  # Write-Verbose fires now
Get-Help Get-SQLServerInventory -Parameter * # see what appeared
#endregion

#region Concept: Write-Debug - more granular progress messages
Clear-Host
function Get-SQLServerInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [DbaInstance]$SqlInstance,
        [Parameter(parameterSetName = 'Export')]
        [string]$Path = 'C:\temp',
        [Parameter(parameterSetName = 'Export')]
        [switch]$Export
    )
    Write-Verbose "[$SqlInstance] Connecting..."
    $server = Connect-DbaInstance -SqlInstance $SqlInstance
    Write-Debug   "[$SqlInstance] Edition: $($server.Edition)"
    $server
}
Get-SQLServerInventory @Params
Get-SQLServerInventory @Params -Debug
#endregion

#region Concept: SupportsShouldProcess - WhatIf and Confirm for free
Clear-Host
function Set-SqlMaxMemory {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [DbaInstance]$SqlInstance ,        
        [int]$MaxMemoryMB = 4096
    )
    if ($PSCmdlet.ShouldProcess($SqlInstance, "Set max memory to $MaxMemoryMB MB")) {
        Set-DbaMaxMemory -SqlInstance $SqlInstance -MaxMB $MaxMemoryMB
    }
}
Set-SqlMaxMemory @Params -WhatIf   # see what would happen - nothing changes
Set-SqlMaxMemory @Params -Confirm  # prompt before acting
#endregion

# -----------------------------------------------------------------------
#region Get-SQLServerInventory v2 - full inventory report
Clear-Host
function Get-SQLServerInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [DbaInstance]$SqlInstance,
        [Parameter(parameterSetName = 'Export')]
        [string]$Path = 'C:\temp',
        [Parameter(parameterSetName = 'Export')]
        [switch]$Export
    )

    Write-Verbose "[$SqlInstance] Connecting..."
    $server = Connect-DbaInstance -SqlInstance $SqlInstance

    Write-Verbose "[$SqlInstance] Getting trace flags..."
    $tfResult = Get-DbaTraceFlag  -SqlInstance $SqlInstance

    Write-Verbose "[$SqlInstance] Getting default paths..."
    $paths = Get-DbaDefaultPath  -SqlInstance $SqlInstance

    [PSCustomObject]@{
        ComputerName  = $server.NetName
        SqlInstance   = $SqlInstance
        Edition       = $server.Edition
        Build         = $server.Version.ToString()
        MaxMemoryMB   = $server.Configuration.MaxServerMemory.ConfigValue
        MaxDOP        = $server.Configuration.MaxDegreeOfParallelism.ConfigValue
        CostThreshold = $server.Configuration.CostThresholdForParallelism.ConfigValue
        TraceFlags    = if ($tfResult) { ($tfResult.TraceFlag -join ', ') } else { 'None' }
        IsHadrEnabled = $server.IsHadrEnabled
        LoginMode     = $server.LoginMode.ToString()
        DataPath      = $paths.Data
        LogPath       = $paths.Log
        BackupPath    = $paths.Backup
    }
}

# verbose shows exactly what's happening on each call
Get-SQLServerInventory @Params -Verbose

#endregion
