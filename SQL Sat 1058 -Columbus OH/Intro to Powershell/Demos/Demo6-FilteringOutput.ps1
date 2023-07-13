Clear-Host

#region Where-Object
    Get-DbaRegisteredServer -Group Demo |
        Test-DbaBuild -Latest |
        Where-Object -FilterScript {$_.Compliant -EQ $false}
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
    Get-DbaRegisteredServer |
        Test-DbaBuild -Latest |
        Where-Object -FilterScript {$_.Compliant -EQ $false} |
        Select SqlInstance, Compliant, Build, BuildTarget        
#endregion
