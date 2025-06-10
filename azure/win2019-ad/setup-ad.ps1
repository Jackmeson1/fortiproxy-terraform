param(
    [string]$DomainName,
    [string]$SafePassword,
    [string]$UserPassword
)

$secpasswd = ConvertTo-SecureString $SafePassword -AsPlainText -Force
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName $DomainName -SafeModeAdministratorPassword $secpasswd -Force

# Wait for AD DS to finish configuring
Start-Sleep -Seconds 60

Import-Module ActiveDirectory
New-ADUser -Name "test1" -AccountPassword (ConvertTo-SecureString $UserPassword -AsPlainText -Force) -Enabled $true
New-ADUser -Name "test2" -AccountPassword (ConvertTo-SecureString $UserPassword -AsPlainText -Force) -Enabled $true
