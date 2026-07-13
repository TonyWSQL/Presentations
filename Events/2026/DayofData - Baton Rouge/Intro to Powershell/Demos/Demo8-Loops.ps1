Clear-Host

#region Conditionals
IF ($true) {
    Write-Host "This is true"
}
ELSE {
    Write-Host "This is false"
}
#end region

# Switch/case statement
switch ($env:USERNAME) {
    "awilhelm" { Write-Host "Welcome back Tony!" }
    "jdoe" { Write-Host "Welcome back John!" }
    default { Write-Host "Welcome back $($env:USERNAME)!" }
}
#end region

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
while (<#conditional expression#>) {
    # loop instructions
}
#endregion

#region do - post-test
do {
    # loop instructions
}while(<#conditional expression#>)
#endregion

<# break / return/ continue / exit
# exit
    exits the current session

# break 
    use to jump out of a For, ForEach, While, Do, or Switch

# return
    exits out of a function, script or scriptblock
    Use to go to the next item in a Foreach-Object loop

# Continue
    use to go to the next item in a For, ForEach, While, Do, or Switch statement 
    Behaves like a 'Break' in a Foreach-Object
#>