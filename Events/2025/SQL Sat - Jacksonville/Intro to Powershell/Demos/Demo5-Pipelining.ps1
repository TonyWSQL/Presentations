Clear-Host
#region 
    # Build a hash table to splat the instance parameter for the following commands
    $InstanceParam = @{
        SqlInstance = 'INLAP-WKS11068\SQL2019DE'
        Verbose = $true
    }    
    Get-DbaBackupInformation @InstanceParam -Path "C:\Users\anthony.wilhelm\OneDrive - Moser Consulting, Inc\Repos\Presentations\databases\Chicago.bak" |
        Restore-DbaDatabase @InstanceParam -WithReplace -WhatIf
#endregion

#region
    # Copying a hashtable 
    $BackupInfoParam = $InstanceParam.Clone()
    $BackupInfoParam.path = "C:\Users\anthony.wilhelm\Downloads\chicago.bak"
    $RestoreParam = $InstanceParam.Clone()
    $RestoreParam.Withreplace = $true

    Get-DbaBackupInformation @BackupInfoParam |
        Restore-DbaDatabase @RestoreParam

#endregion