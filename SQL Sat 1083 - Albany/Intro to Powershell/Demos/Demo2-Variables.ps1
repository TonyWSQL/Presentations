#region Untyped
    Clear-Host
    $dateString = '04/15/2023 10:45'
    $dateString
    $dateString.GetType()

    $instanceString = 'INLAP-WKS11068\SQL2022'
    $instanceString
#endregion
Import-Module dbatools  
#region Typed
    Clear-Host
    [datetime]$dateDT = '08/03/2023 10:45'
    $dateDT
    $dateDT.GetType()

    $dateDT2 = [datetime]'08/03/2024 10:45'
    $dateDT2
    $dateDT2.GetType()
    
    $datedt.AddDays(1)
    $dateDT.DayOfWeek

    [DbaInstance]$instanceDBA = 'INLAP-WKS11068\SQL2022DE'
    $instanceDBA
    $instancedba.GetType()
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
    $databaseName[-1]
    $databaseName.GetType()
#endregion

#region Hashtables
    Clear-Host
    $hashTable = @{
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

    $hashTable
    $customObj.Date = Get-Date
    
    $hashTable
#endregion 