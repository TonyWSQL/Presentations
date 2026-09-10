# Requires ImportExcel module

# ---------------- CONFIG ----------------
$csvPath   = "\\deaconess.com\shares\Departments\IS\Data Management\Database Management\SQL Server Info\Database Inventory Script\ServerList.csv"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$excelPath = "\\deaconess.com\shares\Departments\IS\Data Management\Database Management\SQL Server Info\Database Inventory Script\SQL_Inventory_Licensing_$timestamp.xlsx"

if (!(Test-Path $csvPath)) {
    Write-Error "Server list CSV not found"
    return
}

$servers = Import-Csv $csvPath | Select-Object -ExpandProperty ServerName | Sort-Object

# ---------------- LICENSE COST ----------------
$licenseCostPerCore = @{
    "Enterprise Edition" = 7128
    "Standard Edition"   = 1856
    "Developer Edition"  = 0
}

$serverSummary = @()
$perServerData = @()

foreach ($server in $servers) {

    Write-Host "Querying $server..." -ForegroundColor Cyan

    try {

        # -------- SERVER QUERY --------
        $serverQuery = @"
SET NOCOUNT ON;

DECLARE @RawVer NVARCHAR(100);
DECLARE @WinVer NVARCHAR(100);

CREATE TABLE #ver (
    IndexID INT,
    Name SYSNAME,
    Internal_Value INT,
    Character_Value NVARCHAR(256)
);

INSERT INTO #ver EXEC xp_msver 'WindowsVersion';
SELECT @RawVer = Character_Value FROM #ver;
DROP TABLE #ver;

SET @WinVer = CASE
    WHEN @RawVer LIKE '10.0.26100%' THEN 'Windows Server 2025'
    WHEN @RawVer LIKE '10.0.20348%' THEN 'Windows Server 2022'
    WHEN @RawVer LIKE '10.0.17763%' THEN 'Windows Server 2019'
    WHEN @RawVer LIKE '10.0.14393%' THEN 'Windows Server 2016'
    WHEN @RawVer LIKE '6.3%' THEN 'Windows Server 2012 R2'
    WHEN @RawVer LIKE '6.2%' THEN 'Windows Server 2012'
    ELSE ISNULL(@RawVer,'Unknown')
END;

DECLARE @offline_cpu_count INT =
(
    SELECT COUNT(*) FROM sys.dm_os_schedulers WHERE status = 'VISIBLE OFFLINE'
);

SELECT
    @@SERVERNAME AS ServerName,
    CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(50)) AS SQLVersion,
    CAST(SERVERPROPERTY('ProductLevel') AS NVARCHAR(50)) AS ServicePackLevel,
    ISNULL(CAST(SERVERPROPERTY('ProductUpdateReference') AS NVARCHAR(50)),'N/A') AS UpdateKBNumber,
    CAST(SERVERPROPERTY('Edition') AS NVARCHAR(100)) AS Edition,
    @WinVer AS OSVersion,
    osi.cpu_count AS LogicalCPUs,
    osi.cpu_count / NULLIF(osi.hyperthread_ratio,0) AS PhysicalCores,
    @offline_cpu_count AS OfflineCPUCount,
    CAST(osm.total_physical_memory_kb/1024.0/1024.0 AS DECIMAL(10,2)) AS ServerMemoryGB
FROM sys.dm_os_sys_info osi
CROSS JOIN sys.dm_os_sys_memory osm;
"@

        $summaryResult = Invoke-Sqlcmd -ServerInstance $server -Query $serverQuery -TrustServerCertificate -ErrorAction Stop
        if (!$summaryResult) { continue }

        # -------- SQL MAX MEMORY --------
        $maxMemoryQuery = @"
SELECT CAST(value_in_use AS INT)/1024 AS SQLServerMemoryAllocationGB
FROM sys.configurations
WHERE name = 'max server memory (MB)';
"@

        $maxMemoryResult = Invoke-Sqlcmd -ServerInstance $server -Query $maxMemoryQuery -TrustServerCertificate -ErrorAction Stop

        $summaryResult | Add-Member SQLServerMemoryAllocationGB ($maxMemoryResult.SQLServerMemoryAllocationGB) -Force

        # -------- LICENSE COST --------
        $edition = $summaryResult.Edition
        $match = $licenseCostPerCore.Keys | Where-Object { $edition -like "*$_*" }

        $cost = if ($match) {
            [int]($summaryResult.LogicalCPUs * $licenseCostPerCore[$match])
        } else { 0 }

        $summaryResult | Add-Member EstimatedLicenseCost $cost -Force
        $serverSummary += $summaryResult

        # -------- DATABASE QUERY --------
        $dbQuery = @"
SELECT 
    db.name AS DatabaseName,
    create_date AS DatabaseCreationDate,
    SUSER_SNAME(owner_sid) AS DatabaseOwner,
    recovery_model_desc AS RecoveryModel,
    compatibility_level AS CompatibilityLevel,
    CAST(SUM(mf.size) * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS DatabaseSizeGB,
    CASE WHEN ag.name IS NOT NULL THEN 'Yes' ELSE 'No' END AS IsInAvailabilityGroup
FROM sys.databases db
LEFT JOIN sys.master_files mf ON db.database_id = mf.database_id
LEFT JOIN sys.availability_databases_cluster adc ON db.name = adc.database_name
LEFT JOIN sys.availability_groups ag ON adc.group_id = ag.group_id
WHERE db.state_desc = 'ONLINE'
GROUP BY db.name, create_date, owner_sid, recovery_model_desc, compatibility_level, ag.name
ORDER BY db.name;
"@

        $dbResults = Invoke-Sqlcmd -ServerInstance $server -Query $dbQuery -TrustServerCertificate -ErrorAction Stop

        foreach ($db in $dbResults) {
            $db | Add-Member ServerName $summaryResult.ServerName -Force
        }

        $perServerData += $dbResults

    } catch {
        Write-Warning "Failed $server : $_"
    }
}

# -------- TOTAL DB SIZE --------
$serverDbSize = $perServerData | Group-Object ServerName | ForEach-Object {
    [PSCustomObject]@{
        ServerName = $_.Name
        TotalDBSizeGB = ($_.Group | Measure-Object DatabaseSizeGB -Sum).Sum
    }
}

# ---------------- SUMMARY ----------------
$summaryForExcel = foreach ($row in $serverSummary) {
    $ws = $row.ServerName.Replace("\","-")

    [PSCustomObject]@{
        ServerName = $row.ServerName
        SQLVersion = $row.SQLVersion
        Edition    = $row.Edition
        OSVersion  = $row.OSVersion
        LogicalCPUs = $row.LogicalCPUs
        ServerMemoryGB = $row.ServerMemoryGB
        SQLServerMemoryAllocationGB = $row.SQLServerMemoryAllocationGB
        TotalDBSizeGB = ($serverDbSize | Where-Object ServerName -eq $row.ServerName).TotalDBSizeGB
        EstimatedLicenseCost = $row.EstimatedLicenseCost
    }
}

$summaryForExcel | Export-Excel -Path $excelPath -WorksheetName "Server_Summary" -AutoSize -BoldTopRow -FreezeTopRow -TableStyle None

# ---------------- SERVER TABS ----------------
foreach ($server in $servers) {

    $sheet = $server.Replace("\","-")
    $data = $perServerData | Where-Object ServerName -eq $server

    if ($data) {
        $data |
        Sort-Object DatabaseName |
        Select-Object ServerName, DatabaseName, DatabaseSizeGB, DatabaseCreationDate,
                      DatabaseOwner, RecoveryModel, CompatibilityLevel, IsInAvailabilityGroup |
        Export-Excel -Path $excelPath -WorksheetName $sheet -AutoSize -BoldTopRow -TableStyle None
    }
}

# ---------------- ADD HYPERLINKS SAFELY ----------------
$excel = Open-ExcelPackage $excelPath

# Summary links
$summarySheet = $excel.Workbook.Worksheets["Server_Summary"]

for ($i = 2; $i -le $summarySheet.Dimension.End.Row; $i++) {
    $serverName = $summarySheet.Cells["A$i"].Value
    $sheetName = $serverName.Replace("\","-")

    $summarySheet.Cells["A$i"].Formula = "HYPERLINK(""#'$sheetName'!A1"",""$serverName"")"
}

# Back links
foreach ($sheet in $excel.Workbook.Worksheets) {
    if ($sheet.Name -ne "Server_Summary") {
        $sheet.InsertRow(1,1)
        $sheet.Cells["A1"].Formula = "HYPERLINK(""#'Server_Summary'!A1"",""← Back to Summary"")"
    }
}

Close-ExcelPackage $excel

Write-Host "SQL Inventory Complete ✔ (Bulletproof Mode)" -ForegroundColor Green
Write-Host $excelPath