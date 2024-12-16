#region For
    for (<#Initialize the counter#>$i = 1;  
        <#Conditional expression#> $i -le 10;
        <#Increment the counter#>  $i++ ) {
            Write-Verbose "Counter value: $i" -Verbose
        }
#endregion

#region Foreach( x in y )
foreach ($db in Get-DbaDatabase @instanceParam){
    Write-Host "Database: $($db.name)"
}
#endregion

#region Foreach-object
Get-DbaDatabase @instanceParam -ExcludeSystem |
    Where-Object Owner -NotMatch $env:USERNAME |
    ForEach-Object {
        #take ownership 
        $PSItem |
            Set-DbaDbOwner -TargetLogin "$($env:USERDOMAIN)\$($env:USERNAME)" -WhatIf

        #set recovery to simple   
        $PSItem |
            Set-DbaDbRecoveryModel -RecoveryModel Simple -WhatIf
    }
#endregion

#region while - pre-test
$i = 0
while ($i -le 10) {
    # loop instructions
    $i++
}
#endregion

#region do - post-test
$i = 0
do {
    # loop instructions
    $i++
} while($i++)
#endregion

<# break / return / continue / exit
# break 
    use to jump out of a For, ForEach, While, Do, or Switch

# return
    exits out of a function, script or scriptblock
    Use to go to the next item in a Foreach-Object loop

# Continue
    use to go to the next item in a For, ForEach, While, Do, or Switch statement 
    Behaves like a 'Break' in a Foreach-Object

# exit
    exits the current session    
#>