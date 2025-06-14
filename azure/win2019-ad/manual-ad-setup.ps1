# Simple AD Setup Script for Manual Execution
# Run this via RDP on the Windows Server

# Install AD Domain Services and DNS
Write-Host "Installing AD Domain Services and DNS..."
Install-WindowsFeature AD-Domain-Services,DNS -IncludeManagementTools

# Convert password to secure string
$secpasswd = ConvertTo-SecureString 'P@ssw0rd1234!' -AsPlainText -Force

# Install AD Forest
Write-Host "Installing AD Forest..."
Install-ADDSForest -DomainName 'example.com' -SafeModeAdministratorPassword $secpasswd -Force -NoRebootOnCompletion -DomainNetbiosName 'CORP' -ForestMode 'WinThreshold' -DomainMode 'WinThreshold' -InstallDns

Write-Host "AD installation complete. Please reboot the server and run part 2."