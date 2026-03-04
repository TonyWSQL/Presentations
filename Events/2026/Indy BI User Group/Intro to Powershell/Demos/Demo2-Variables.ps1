#region Untyped
    Clear-Host
    $dateString = '02/24/2026 11:12:04 AM'
    $dateString
    $dateString.GetType()

    $instanceString = "$($env:COMPUTERNAME)\SQL2019DE"
    $instanceString
#endregion

Import-Module dbatools  
#region Typed
    Clear-Host
    ([datetime]$dateDT = '02/24/2026 11:12:04 AM')    
    #$dateDT
    $dateDT.GetType()

    $dateDT2 = [datetime]'02/24/2026 11:12:04 AM'
    $dateDT2
    $dateDT2.GetType()
    
    $dateDT2.AddDays(1)
    $dateDT.DayOfWeek

    [DbaInstance]$instanceDBA = "$($env:COMPUTERNAME)\SQL2019DE"
    $instanceDBA
    $instanceDBA.GetType()
#endregion

#region Custom Objects
    Clear-Host
    $customObj = 
        [PSCustomObject][ordered]@{
            Name = 'This is the object Name'
            Value = 123
            Date = Get-Date
        }
    $customObj
    $customObj.GetType()    
    $customObj.Name
    $customObj.date 
        
    # these values are read & write
    $customObj.Name = "Updated Name"
    $customObj

    # adding new properties
    $customObj.NewProperty = "Trying to add a new property"

    #region 
        Add-Member -InputObject $customObj -Name 'NewProperty' -MemberType NoteProperty -Value "Added a new property"
        $customObj
    #endregion    

#endregion

#region Arrays
    Clear-Host
    $databaseName = @('master', 'model') #declaring the array with 2 items
    $databaseName += 'msdb'
    $databaseName
    $databaseName[0]
    $databaseName.GetType()
#endregion

#region Hashtables
    Clear-Host
    $hashTable = [ordered]@{

        Name = 'This is a hashtable'
        Value = 123
        Date = Get-Date
    }
    $hashTable.GetType()
    $hashTable.Date    
#endregion

#region Mixing it up
    Clear-Host
    $hashTable.CustomObj = $customObj

    $hashTable.CustomObj.NewProperty
    $customObj.Date = Get-Date
    
    $hashTable
#endregion 