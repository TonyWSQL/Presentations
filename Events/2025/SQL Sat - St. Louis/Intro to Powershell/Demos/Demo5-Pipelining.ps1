Clear-Host
#region 
    # Build a hash table to splat the instance parameter for the following commands
    $backupFile = 'C:\Users\anthony.wilhelm\OneDrive - Moser Consulting, Inc\Repos\Presentations\databases\Chicago.bak'

    $InstanceParam = @{
        SqlInstance = "$($env:COMPUTERNAME)\SQL2019DE"
        Verbose = $true
    }
    Get-DbaBackupInformation @InstanceParam -Path $backupFile |
        Restore-DbaDatabase @InstanceParam -WithReplace -WhatIf
#endregion

#region
    # Copying a hashtable 
    $BackupInfoParam = $InstanceParam.Clone()
    $BackupInfoParam.path = $backupFile
    $RestoreParam = $InstanceParam.Clone()
    $RestoreParam.WithReplace = $true

    Get-DbaBackupInformation @BackupInfoParam |
        Restore-DbaDatabase @RestoreParam

#endregion