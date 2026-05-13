#region This will start SSMS
    Start-Process -FilePath "C:\Program Files (x86)\Microsoft SQL Server Management Studio 20\Common7\IDE\Ssms.exe" 
    Get-Process -Name SSMS 
#endregion    
Clear-Host

# Set defaults just for this session
Set-DbatoolsInsecureConnection -SessionOnly

#region Common Parameters
    # WhatIf 
    Stop-Process -Name SSMS -WhatIf 

    # Confirm
    Stop-Process -Name SSMS -Confirm

    # verbose
    Stop-Process -Name SSMS -Verbose

#endregion

#region 
    # Splatting - using a hashtable to pass parameters
    $InstanceParam = @{
        SqlInstance = "$($env:COMPUTERNAME)\SQL2019DE"
        Verbose = $true
    }
    $InstanceParam
    
    Test-DbaMaxMemory @InstanceParam   
    Set-DbaMaxMemory @InstanceParam -Confirm
    
    Test-DbaMaxDop @InstanceParam

    # adding a new name/value pair to the hash table
    $InstanceParam.Latest = $true
    Test-DbaBuild  @InstanceParam 

    Test-DbaMaxDop @InstanceParam 
    #region 
    Test-DbaMaxMemory @InstanceParam
        Test-DbaMaxMemory -SqlInstance $InstanceParam.SqlInstance
        $InstanceParam.Remove('Latest')    
        Test-DbaMaxDop @InstanceParam 
    #endregion

    #region 
        #Add values to the the hash table to re-attach database 

        $DefaultPath = Get-DbaDefaultPath @InstanceParam
        $DefaultPath

        $InstanceParam.Database = 'StackOverflow2010'
        $InstanceParam.FileStructure = New-Object System.Collections.Specialized.StringCollection
        $InstanceParam.FileStructure.add((Join-Path $DefaultPath.Data "StackOverflow2010.mdf" -Resolve))
        $InstanceParam.FileStructure.add((Join-Path $DefaultPath.log "StackOverflow2010_log.ldf" -Resolve))

        $InstanceParam
        Attach-DbaDatabase @InstanceParam -WhatIf
    #endregion

#endregion

