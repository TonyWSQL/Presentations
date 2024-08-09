#region This will start SSMS
    Start-Process -FilePath "C:\Program Files (x86)\Microsoft SQL Server Management Studio 20\Common7\IDE\Ssms.exe"
    Get-Process -Name smss
#endregion    
Clear-Host

#region Common Parameters
    # whatif 
    Stop-Process -Name ssms -WhatIf 

    # Confirm
    Stop-Process -Name smss -Confirmn

    # verbose
    Stop-Process -Name ssms -Verbose

#endregion

#region Set defaults just for this session
Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true
Set-DbatoolsConfig -FullName sql.connection.encrypt -Value $false
Set-DbatoolsInsecureConnection
#endregion

#region 
    # Splatting - using a hashtable to pass parameters
    $InstanceParam = @{
        SqlInstance = 'INLAP-WKS11068\SQL2019DE'
        Verbose = $true
    }
    $InstanceParam
    
    Test-DbaMaxMemory @InstanceParam   
    Test-DbaMaxDop @InstanceParam

    # adding a new name/value pair to the hash table
    $InstanceParam.Latest = $true
    Test-DbaBuild  @InstanceParam 

    Test-DbaMaxDop @InstanceParam 
    #region 
        Test-DbaMaxMemory -SqlInstance $InstanceParam.SqlInstance
        $InstanceParam.Remove('Latest')    
        Test-DbaMaxDop @InstanceParam 
    #endregion

    #region 
        #Add vaules to the the hash table to re-attach database 

        $DefaultPath = Get-DbaDefaultPath @InstanceParam
        #Set-DbaDefaultPath -SqlInstance mmm -Type Backup -Path
        $DefaultPath

        $InstanceParam.Database = 'StackOverflow2010'
        $InstanceParam.FileStructure = New-Object System.Collections.Specialized.StringCollection
        $InstanceParam.FileStructure.add((Join-Path $DefaultPath.Data "StackOverflow2010.mdf" -Resolve))
        $InstanceParam.FileStructure.add((Join-Path $DefaultPath.log "StackOverflow2010_log.ldf" -Resolve))

        $InstanceParam
        Attach-DbaDatabase @InstanceParam -WhatIf 
    #endregion

#endregion

