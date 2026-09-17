#Requires -modules  @{ ModuleName="dbatools";  ModuleVersion="2.7.0" }
#Requires -modules  @{ ModuleName="ImportExcel";  ModuleVersion="7.8.0" }

<#
.SYNOPSIS
    Collects server and database-level inventory facts from one or more SQL Server instances.

.DESCRIPTION
    Get-SQLServerInventory connects to each supplied SQL instance via dbatools and gathers
    server-level configuration (version, edition, memory, trace flags, default paths, etc.)
    along with per-database details (recovery model, compatibility level, owner, file sizes).
    Results are returned as a single object with Servers and Databases collections, and can
    optionally be exported to a timestamped Excel workbook.

.PARAMETER SqlInstance
    One or more SQL instances to inventory. Accepts pipeline input so you can feed it a list
    of servers.

.PARAMETER Path
    Optional folder to export an Excel workbook to. The folder must already exist. When
    supplied, a workbook named SQL_Inventory_yyyyMMdd_HHmmss.xlsx is created with separate
    worksheets for the server and database summaries, and the resulting path is added to the
    output as ExcelPath.

.PARAMETER Export
    Switch belonging to the same parameter set as -Path. Exporting is actually triggered by
    supplying -Path (which defaults to C:\temp); this switch does not need to be specified
    separately.

.EXAMPLE
    PS> Get-SQLServerInventory -SqlInstance 'SQL01'

    Returns an object with Servers and Databases properties describing SQL01.

.EXAMPLE
    PS> 'SQL01', 'SQL02' | Get-SQLServerInventory -Path 'C:\Temp'

    Inventories both instances and exports the results to an Excel workbook in C:\Temp.

.OUTPUTS
    PSCustomObject with Servers (V-RodDBASQL.ServerInventory[]) and
    Databases (V-RodDBASQL.DatabaseInventory[]) properties, plus ExcelPath when -Path is used.
#>
function Get-SQLServerInventory {    
    [CmdletBinding()]
    param (
        # One or more SQL instances to inventory; accepts pipeline input so you can feed it a list of servers
        [Parameter(Mandatory, ValueFromPipeline)]
        [DbaInstance[]]$SqlInstance,

        # Optional folder to export an Excel workbook to; must already exist
        [Parameter(parameterSetName = 'Export')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [string]$Path = 'C:\temp',

        [Parameter(parameterSetName = 'Export')]
        [switch]$Export
    )
    begin {
        # Accumulators for every instance processed across the whole pipeline run
        $serverInventory = @()
        $databaseInventory = @()

        # Common splat used on every dbatools call below
        $sqlParams = @{
            ErrorAction = 'Stop'
            Verbose     = $VerbosePreference
        }

        # Build a unique, timestamped workbook path once, up front, if exporting was requested
        if ($PSBoundParameters.ContainsKey('Path') -or $PSCmdlet.ParameterSetName -eq 'Export') {
            $exportPath = join-path -Path $Path -ChildPath ("SQL_Inventory_{0}.xlsx" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
        }

        # Give each output object type a sensible default set of columns so ft/fl without -Property
        # doesn't dump every property on screen
        Update-TypeData -TypeName 'V-RodDBASQL.ServerInventory' -DefaultDisplayPropertySet 'ServerName', 'InstanceName', 'SQLVersion', 'Edition' -Force
        Update-TypeData -TypeName 'V-RodDBASQL.DatabaseInventory' -DefaultDisplayPropertySet 'SqlInstance', 'Name', 'Status', 'RecoveryModel', 'Owner' -Force
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
        $tfResult = Get-DbaTraceFlag -SqlInstance $SqlInstance

        # Get the default paths for the server
        Write-Verbose "[$SqlInstance] Getting default paths..."
        $paths = Get-DbaDefaultPath -SqlInstance $SqlInstance
    
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
        # Tag the object with a custom type name so the Update-TypeData display set above applies to it
        $serverInventory[-1].PSObject.TypeNames.Insert(0, 'V-RodDBASQL.ServerInventory')

        foreach ($db in (Get-DbaDatabase @sqlParams)) {

            # File sizes come back as separate rows per file, split by data (Rows) vs log
            $dbFiles = Get-DbaDbFile  -Database $db.Name @SqlParams

            $databaseInventory += [PSCustomObject]@{
                SqlInstance        = $db.SqlInstance
                CreateDate         = $db.CreateDate
                Name               = $db.Name
                Status             = $db.Status
                RecoveryModel      = $db.RecoveryModel
                CompatibilityLevel = $db.CompatibilityLevel
                Collation          = $db.Collation
                Owner              = $db.Owner
                IsSystemObject     = $db.IsSystemObject
                DataSizeMB         = [dbaSize]($dbFiles | Where-Object TypeDescription -eq 'Rows' | Measure-Object -Property Size -Sum).Sum
                LogSizeMB          = [dbaSize]($dbFiles | Where-Object TypeDescription -eq 'Log' | Measure-Object -Property Size -Sum).Sum
            }
            # Same custom-type tagging as above, but for the database-level object shape
            $databaseInventory[-1].PSObject.TypeNames.Insert(0, 'V-RodDBASQL.DatabaseInventory')
        }
    }

    end {
        # Bundle both collections into a single return object so callers can grab either side
        # (Servers / Databases) without the two object shapes colliding in one pipeline stream
        $output = [PSCustomObject]@{
            Servers   = $serverInventory
            Databases = $databaseInventory
        }

        if ($PSBoundParameters.ContainsKey('Path') -or $PSCmdlet.ParameterSetName -eq 'Export') {
            # Surface the workbook path on the output so the caller doesn't have to remember it
            $output | Add-Member -MemberType NoteProperty -Name 'ExcelPath' -Value $exportPath -Force

            $excelParams = @{
                Path         = $exportPath
                AutoSize     = $true
                FreezeTopRow = $true
                BoldTopRow   = $true
                AutoFilter   = $true
            }

            # Export-Excel appends a new worksheet to the same workbook on each call
            $serverInventory | Export-Excel @excelParams -WorksheetName 'Server Summary'
            $databaseInventory | Export-Excel @excelParams -WorksheetName 'Database Summary'
        }

        $output
    }
}

# Stop here when dot-sourcing/running this file just to load the function definition above
return

# --- Example usage below ---

get-help Get-SQLServerInventory -ShowWindow

$servers = @()
$servers += ("{0}\{1}" -f $env:COMPUTERNAME, 'SQL2019DE')
$servers += ("{0}\{1}" -f $env:COMPUTERNAME, 'SQL2022DE')

$servers = Get-DbaRegisteredServer -Group Demo 

$inventory = $servers |
Get-SQLServerInventory -path "C:\Temp"

$inventory.Servers   | Format-Table -a
$inventory.Databases | Format-Table -a

# Open the generated workbook
. $inventory.ExcelPath
