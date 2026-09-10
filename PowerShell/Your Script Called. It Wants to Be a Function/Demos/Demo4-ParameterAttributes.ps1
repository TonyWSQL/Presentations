
#region Setup
$svr = Get-DbaRegisteredServer -Group Demo
#endregion

#region Concept: ValidateSet - tab completion + rejection at the boundary
Clear-Host
function Set-SqlRecoveryModel {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [DbaInstance]$SqlInstance,
        [Parameter(Mandatory)]
        [string]$Database,
        [Parameter(Mandatory)]
        [ValidateSet('Simple', 'Full', 'BulkLogged')]
        [string]$RecoveryModel
    )
    if ($PSCmdlet.ShouldProcess($SqlInstance, "Set recovery model for $Database to $RecoveryModel")) {
        Set-DbaDbRecoveryModel -SqlInstance $SqlInstance -Database $Database -RecoveryModel $RecoveryModel
    }
    
}
# tab-complete on -RecoveryModel, invalid value rejected before the body runs
Set-SqlRecoveryModel -SqlInstance $svr[0].Name -Database 'StackOverflow2010' -WhatIf -RecoveryModel 'Fast' 
Set-SqlRecoveryModel -SqlInstance $svr[0].Name -Database 'StackOverflow2010' -WhatIf -RecoveryModel  
Set-SqlRecoveryModel -SqlInstance $svr[0].Name -Database 'StackOverflow2010' -WhatIf -RecoveryModel 'full' 
#endregion

#region Concept: ValidateRange - numeric bounds like a CHECK constraint
Clear-Host
function Set-SqlMaxMemory {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [DbaInstance]$SqlInstance,
        [Parameter(Mandatory)]
        [ValidateRange(512, 131072)]
        [int]$MaxMemoryMB
    )
    if ($PSCmdlet.ShouldProcess($SqlInstance, "Set max memory to $MaxMemoryMB MB")) {
        Set-DbaMaxMemory -SqlInstance $SqlInstance -MaxMB $MaxMemoryMB
    }
}
Set-SqlMaxMemory -SqlInstance $svr[0].Name -MaxMemoryMB 64   -WhatIf # below minimum - rejected
Set-SqlMaxMemory -SqlInstance $svr[0].Name -MaxMemoryMB 4096 -WhatIf # valid
#endregion

#region Concept: ValidateScript - custom logic when a fixed list won't do
Clear-Host
function Get-SQLServerInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [DbaInstance]$SqlInstance,
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [Parameter(parameterSetName = 'Export')]
        [string]$Path = 'C:\temp',
        [Parameter(parameterSetName = 'Export')]
        [switch]$Export
    )
}
# empty string - ValidateNotNullOrEmpty rejects it before SQL Server is ever contacted
Get-SQLServerInventory -SqlInstance ''

Get-SQLServerInventory @Params -path 'C:\temp_folder'
Get-SQLServerInventory @Params -path 'C:\temp'
#endregion

# -----------------------------------------------------------------------
#region Concept: Get-SQLServerInventory v3 - validated parameters
Clear-Host
function Get-SQLServerInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [DbaInstance]$SqlInstance,
        [Parameter(parameterSetName = 'Export')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [string]$Path = 'C:\temp',
        [Parameter(parameterSetName = 'Export')]
        [switch]$Export
    )

    Write-Verbose "[$SqlInstance] Connecting..."
    $server = Connect-DbaInstance -SqlInstance $SqlInstance

    Write-Verbose "[$SqlInstance] Getting trace flags..."
    $tfResult = Get-DbaTraceFlag    -SqlInstance $SqlInstance

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

# valid - full inventory for this instance
Get-SQLServerInventory -SqlInstance $svr[0].Name -Verbose
Get-SQLServerInventory -SqlInstance $svr[1].Name

# already useful as a standalone inventory tool
@($svr[0].Name, $svr[1].Name) |
ForEach-Object { 
    Get-SQLServerInventory -SqlInstance $_ } |
Format-Table -AutoSize
#endregion
