Clear-Host
$instanceParam = @{
    SqlInstance = "$($env:COMPUTERNAME)\SQL2019DE"
    Verbose = $true
    }

#region Format-List
    Get-DbaDatabase @instanceParam -ExcludeSystem |
        Format-List SqlInstance, Name

#endregion

#region Format-Table
    Get-DbaDatabase @instanceParam -ExcludeSystem |
        Get-DbaDbFile |
        Select-Object SqlInstance, database, LogicalName, TypeDescription, *size*, growth* |
        Sort-Object TypeDescription |
        Format-Table -AutoSize
#endregion

#region Out-Gridview
    Get-DbaDatabase @instanceParam |        
        Out-GridView -Title "Select a database" -PassThru |
        Get-DbaDbFile |
        Select-Object SqlInstance, database, LogicalName, TypeDescription, *size*, growth* |
        Sort-Object TypeDescription |
        Out-GridView
#endregion

#region Write-Host
    Write-Host "This will output your code to the terminal window"
#endregion

#region Write-Verbose
    Write-Verbose "This will output your code to the window as a verbose" -Verbose
#endregion

#region Write-Warning
    Write-Warning "This will output your code to the window as a warning"
#endregion

#region Write-Error
    Write-Error "oops an error has occured"     
#endregion