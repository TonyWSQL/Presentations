Clear-Host

#TODO must start the SQL Engine service(s) on laptop prior to running this demo

# get the latest build reference list from dbatools 
## Must be connected to the internet 
Update-DbaBuildReference 

Find-DbaInstance -ComputerName $env:COMPUTERNAME 

Get-DbaService -ComputerName $env:COMPUTERNAME -Type Engine 

#region Where-Object
    Get-DbaRegisteredServer -Group Demo |
        Test-DbaBuild -Latest |
        Where -FilterScript {$_.NameLevel -EQ 2022}
        #Where-Object {$_.Compliant -EQ $false}
        #Where-Object -Property Compliant -EQ $false
        #Where-Object Compliant -EQ $false
        #Where Compliant -eq $false
        #? Compliant -eq $false

    Get-DbaRegisteredServer -Group demo |
        Test-DbaBuild -Latest |
        Where-Object {$_.SupportedUntil -GE (Get-Date)}

    <# other logical operands        
        -EQ Equal to
        -NE Not Equal to
        -GT Greater than
        -GE Greater than or Equal to
        -LT Less than
        -LE Less than or Equal to
        -Like wildcard pattern (-notlike)        
        -Match regex pattern (-notmatch)       

        Prefixing the operator with a 'c' will make it case sensitive
        ex: -cmatch & -ceq
    #>
#endregion

#region Select-Object
    Get-DbaRegisteredServer -Group Demo |
        Test-DbaBuild -Latest |
        #Where-Object -FilterScript {$_.NameLevel -EQ 2022} |
        Select-Object SqlInstance, Compliant, *level      
#endregion
