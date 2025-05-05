#region Untyped
Clear-Host
$dateString = '04/15/2023 10:45'
$dateString
$dateString.GetType()
$env:COMPUTERNAME
$instanceString = 'INLAP-WKS11068\SQL2019de'
$instanceString
#endregion
Import-Module dbatools
#region Typed
Clear-Host
[datetime]$dateDT = '04/15/2023 10:45'
$dateDT
$dateDT.GetType()

$dateDT2 = [datetime]'04/15/2023 10:45'
$dateDT2
$dateDT2.GetType()

$datedt.AddDays(1)
$dateDT.DayOfWeek

[DbaInstance]$instanceDBA = 'INLAP-WKS11068\SQL2019DE'
$instanceDBA
$instanceDBA.GetType()
#endregion

#region Custom Objects
Clear-Host
$customObj =
[PSCustomObject][ordered]@{
	Name  = 'This is the object Name'
	Value = 123
	Date  = Get-Date
}
$customObj
$customObj.GetType()
$customObj.Name
$customObj.date

# these values are read & write
$customObj.Name = 'Updated Name'
$customObj

# adding new properties
$customObj.NewProperty = 'Trying to add a new property'

#region
Add-Member -InputObject $customObj -Name 'NewProperty' -MemberType NoteProperty -Value 'Added a new property'
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
$hashTable = @{
	Name  = 'This is a hashtable'
	Value = 123
	Date  = Get-Date
}
$hashTable.GetType()
$hashTable.Date
#endregion

#region Ordered Hashtable/Dictionary
Clear-Host
$orderedHashtable = [ordered]@{
	Name  = 'This is an ordered hashtable'
	Value = 123
	Date  = Get-Date
}
$orderedHashtable.GetType()
$orderedHashtable.Date
#endregion

#region Mixing it up
Clear-Host
$hashTable.CustomObj = $customObj

$hashTable
$customObj.Date = Get-Date

$hashTable
#endregion