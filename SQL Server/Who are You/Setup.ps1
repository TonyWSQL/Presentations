Import-Module microsoft.powershell.localaccounts -UseWindowsPowerShell
Import-Module dbatools
$EventName = 'SQL Sat OR & SW WA'
$domain = $env:computername

# create local groups   
New-LocalGroup -name 'DBUsers' -Description ('Database users for {0}' -f $EventName)

#region create local users
$users = @()
$users += [PSCustomObject][ordered]@{
    Name = 'MichaelM'
    FullName = 'Michael McManus'}
$users += [PSCustomObject][ordered]@{
    Name = 'DeanK'
    FullName = 'Dean Keaton'}
$users += [PSCustomObject][ordered]@{
    Name = 'FredF'
    FullName = 'Fred Fenster'}
$users += [PSCustomObject][ordered]@{
    Name = 'ToddH'
    FullName = 'Todd Hockney'}
$users += [PSCustomObject][ordered]@{
    Name = 'KaiserS'
    #FullName = 'Roger "Verbal" Kint'
    FullName = 'Keyser Söze'
}

$params = @{
    Name = ''
    Password = ''
    FullName = ''
}

$users |       
    ForEach-Object {
        $params.Name = $PSItem.Name
        $params.Password = ConvertTo-SecureString ("{0}!202408" -f $PSItem.Name) -AsPlainText
        $params.FullName = $PSItem.FullName       

        New-LocalUser @params 
        Add-LocalGroupMember -Group 'DBUsers' -Member $params.Name

        # create the SQL Logins/Users
        New-DbaLogin -SqlInstance ("{0}\SQL2019DE" -F $domain) -Login ("{0}\{1}" -f $domain, $params.Name) -Force
    }

Get-LocalUser -Name 'KaiserS' |    
    Rename-LocalUser -NewName 'RogerK'

Set-LocalUser -Name 'RogerK' -FullName 'Roger "Verbal" Kint'

#endregion



return
#region Cleanup
    # remove Local users
    Get-LocalGroupMember -Group 'DBUsers' |
        ForEach-Object {
            $name = $PSItem.name.split("\")[1]
            Remove-LocalUser -Name $name -Verbose
        }    
    # remove the local group
    Remove-LocalGroup 'DBUsers'
#endregion