
#region Setup
$svr = Get-DbaRegisteredServer -Group Demo
#endregion

#region Concept: Pipeline support - functions can accept input from the pipeline, and can emit output to the pipeline
Clear-Host
function Get-SQLServerInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [DbaInstance]$SqlInstance
    )
    # no process block - body runs as the end block
    # only the LAST piped value is ever in $SqlInstance
    Write-Verbose "Checking: $SqlInstance" -Verbose
    #[PSCustomObject]@{ SqlInstance = $SqlInstance }
}
$svr | Get-SQLServerInventory
# only the last registered server appears in the output
#endregion

#region  Concept: Code Blocks
Clear-Host 
function Get-SQLServerInventory {
    [CmdletBinding()]
    param(
    )
    begin {
        Write-Verbose "Starting inventory"            
    }
    process {
        # process{} runs once per instance piped in
        Write-Verbose "Checking: "        
    }
    End {
        Write-Verbose "Inventory complete"        
    }
}

Get-SQLServerInventory -Verbose

#endregion

#region Concept: ValueFromPipeline - strings pipe in, process block runs per item
Clear-Host
function Get-SQLServerInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [DbaInstance]$SqlInstance,
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [string]$Path
    )    
    begin {
        Write-Verbose "Starting inventory"     
        
        # Initialize a list to hold the results across the whole pipeline run
        $serverInventory = @()
    }
    process {
        Write-Verbose "Checking: $SqlInstance"
        $serverInventory += [PSCustomObject]@{
            SqlInstance = $SqlInstance
            Edition     = (Connect-DbaInstance -SqlInstance $SqlInstance).Edition
        }    
    }
    End {
        Write-Verbose "Inventory complete - $($serverInventory.Count) instance(s)"
        $serverInventory               
    }
}
$svr[0].Name | Get-SQLServerInventory -Verbose  # single
$svr    | Get-SQLServerInventory -Verbose  # all registered servers
#endregion

#region Concept: Begin / Process / End - full pipeline lifecycle
Clear-Host
function Get-SQLServerInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias('Name')]
        [DbaInstance]$SqlInstance
    )
    begin {
        # runs once before the first item arrives - good for setup
        Write-Verbose "Starting health checks"
        
        # Initialize a list to hold the results across the whole pipeline run
        $serverInventory = @()
    }
    process {
        # runs once per pipeline item
        Write-Verbose "Checking: $SqlInstance"
        $serverInventory += [PSCustomObject]@{ SqlInstance = $SqlInstance }
    }
    end {
        # runs once after the last item - good for summary output
        Write-Verbose "Complete - $($serverInventory.Count) instance(s) checked"
        $serverInventory
    }
}
Get-DbaRegisteredServer -Group Demo | Get-SQLServerInventory -Verbose
#endregion

# -----------------------------------------------------------------------
#region Get-SQLServerInventory v4 - full pipeline support, inventory for all servers
Clear-Host
function Get-SQLServerInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [DbaInstance]$SqlInstance
    )
    begin {
        Write-Verbose "Starting inventory"
        $serverInventory = @()
    }
    process {
        Write-Verbose "[$SqlInstance] Connecting..."
        $server = Connect-DbaInstance -SqlInstance $SqlInstance

        Write-Verbose "[$SqlInstance] Getting trace flags..."
        $tfResult = Get-DbaTraceFlag    -SqlInstance $SqlInstance

        Write-Verbose "[$SqlInstance] Getting default paths..."
        $paths = Get-DbaDefaultPath  -SqlInstance $SqlInstance

        $serverInventory += [PSCustomObject]@{
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
    end {
        Write-Verbose "Inventory complete - $($serverInventory.Count) instance(s)"
        $serverInventory
    }
}

# check a single server
Get-SQLServerInventory -SqlInstance $svr[0].Name -Verbose

# all registered servers - this is what we've been building toward
Get-DbaRegisteredServer -Group Demo | Get-SQLServerInventory -Verbose

# inventory report across all registered servers
Get-DbaRegisteredServer -Group Demo | Get-SQLServerInventory | Format-Table -AutoSize
#endregion
