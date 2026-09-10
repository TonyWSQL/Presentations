
#region Setup
$svr = Get-DbaRegisteredServer -Group Demo
#endregion

#region Concept: no error handling - one bad server crashes the pipeline
Clear-Host
function Get-SQLServerInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias('Name')]
        [DbaInstance]$SqlInstance
    )
    process {
        $server = Connect-DbaInstance -SqlInstance $SqlInstance -EnableException
        [PSCustomObject]@{ SqlInstance = $SqlInstance; Edition = $server.Edition }
    }
}
@($svr[0].Name, 'DOESNOTEXIST', $svr[1].Name) | Get-SQLServerInventory
# everything after DOESNOTEXIST never runs
#endregion

#region Concept: Try / Catch - bad server becomes an Error row, others still run
Clear-Host
function Get-SQLServerInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias('Name')]
        [DbaInstance]$SqlInstance
    )
    process {
        try {
            # -EnableException tells dbatools to throw instead of writing a warning
            # without it try/catch won't fire - dbatools errors are non-terminating by default
            $server = Connect-DbaInstance -SqlInstance $SqlInstance -EnableException
            [PSCustomObject]@{ SqlInstance = $SqlInstance; Edition = $server.Edition; Status = 'OK' }
        }
        catch {
            Write-Warning "[$SqlInstance] $($_.Exception.Message)"
            [PSCustomObject]@{ SqlInstance = $SqlInstance; Edition = $null; Status = 'Error' }
        }
    }
}
@($svr[0].Name, 'DOESNOTEXIST', $svr[1].Name) | Get-SQLServerInventory
# DOESNOTEXIST gets an Error row - the other two produce results
#endregion

#region Concept: -ErrorAction Stop - required for try/catch on built-in cmdlets
Clear-Host
# dbatools uses -EnableException; built-in cmdlets need -ErrorAction Stop
try {
    Get-ChildItem 'Z:\DoesNotExist' -ErrorAction Stop
}
catch {
    Write-Warning "Caught it: $($_.Exception.Message)"
}

# $Error is PowerShell's automatic error log for the session
$Error[0].Exception.Message
$Error[0].InvocationInfo.Line
#endregion

# -----------------------------------------------------------------------
#region Get-SQLServerInventory v5 - full health report with error handling
Clear-Host
function Get-SQLServerInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias('Name')]
        [ValidateNotNullOrEmpty()]
        [DbaInstance]$SqlInstance
    )
    begin {
        Write-Verbose "Starting health checks"

        # Common splat used on every dbatools call below
        $sqlParams = @{
            ErrorAction = 'Stop'
            Verbose     = $VerbosePreference
        }
        
        # Initialize a list to hold the results across the whole pipeline run
        $serverInventory = @()
    }
    process {
        # process{} runs once per instance piped in, so re-target the shared splat each time
        $sqlParams.SqlInstance = $SqlInstance

        # A missing/unreachable server should skip just this instance, not kill the whole pipeline run
        try {
            # Get the generic server object first so we can grab the computer name for the Get-DbaComputerSystem call below
            $server = Connect-DbaInstance @sqlParams
        }
        catch {
            Write-Error -Message "Could not connect to '$SqlInstance': $($_.Exception.Message)" -TargetObject $SqlInstance
            return
        }

        # Get the maximum memory setting for the server
        $maxMemory = Get-DbaMaxMemory @sqlParams

        # Get the trace flags for the server
        Write-Verbose "[$SqlInstance] Getting trace flags..."
        $tfResult = Get-DbaTraceFlag    -SqlInstance $SqlInstance

        # Get the default paths for the server
        Write-Verbose "[$SqlInstance] Getting default paths..."
        $paths = Get-DbaDefaultPath  -SqlInstance $SqlInstance
    
        # Get the version information for the server
        $version = Get-DbaBuild -Build $server.ServerVersion

        # Get the computer system object for the server
        $computer = Get-DbaComputerSystem -ComputerName $server.ComputerNamePhysicalNetBIOS 

        # One row of server-level facts per instance
        $serverInventory += [PSCustomObject]@{
            ServerName                  = $server.ComputerNamePhysicalNetBIOS
            InstanceName                = $server.InstanceName
            SQLVersion                  = $server.ServerVersion
            ServicePackLevel            = ("{0} - {1}" -f $version.SPLevel, $version.CULevel)
            UpdateKBLevel               = $version.KBLevel
            Edition                     = $server.Edition
            OSVersion                   = $server.HostDistribution
            TraceFlags                  = if ($tfResult) { ($tfResult.TraceFlag -join ', ') } else { 'None' }
            NumberOfCores               = $server.Processors
            NumberOfProcessors          = $computer.NumberProcessors
            MaxDegreeOfParallelism      = $server.Configuration.MaxDegreeOfParallelism.ConfigValue
            CostThresholdForParallelism = $server.Configuration.CostThresholdForParallelism.ConfigValue
            ServerMemory                = $server.PhysicalMemory
            MaxMemorySetting            = $maxMemory.MaxValue
            IsHadrEnabled               = $server.IsHadrEnabled
            LoginMode                   = $server.LoginMode
            DataPath                    = $paths.Data
            LogPath                     = $paths.Log
            BackupPath                  = $paths.Backup
        }
    }
    end {
        Write-Verbose "Complete - $($serverInventory.Count) instance(s) checked"
        $serverInventory
    }
}

# verify error handling - bad server gets a row, doesn't crash the report
@($svr[0].Name, 'DOESNOTEXIST', $svr[1].Name) | 
Get-SQLServerInventory -Verbose
#endregion

# -----------------------------------------------------------------------
#region The payoff - generate both reports from the same function
Clear-Host
$report = Get-DbaRegisteredServer -Group Demo | Get-SQLServerInventory

# view in the console
$report | Format-Table -AutoSize

# copy as plain text - paste straight into an email
$report | Format-Table -AutoSize
