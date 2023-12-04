# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: init_win2016ad_install_ad.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2019.05.13
# Revision...: 
# Purpose....: Script to reset Administrator password
# Notes......: 
# Reference..: 
# License....: Licensed under the Universal Permissive License v 1.0 as 
#              shown at http://oss.oracle.com/licenses/upl.
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ---------------------------------------------------------------------------
Start-Transcript -Path "C:\init_win2016ad_install_ad.log"
$PlainPassword="LAB.42schulung"
$domain="trivadislabs.com"
$DomainMode="Win2012R2"
$ip="10.0.1.4"
$dns1="10.0.1.4"
$dns2="8.8.8.8"
$People="People"
$Groups="Groups"

# set default value for netbiosDomain if empty
$netbiosDomain = $domain.ToUpper() -replace "\.\w*$",""
# define subnet based on ip
$subnet = $ip -replace "\.\w*$", ""

$DefaultPWDFile="C:\Users\Administrator\default_pwd_win2016ad.txt"
Write-Host "Write default password to $DefaultPWDFile"
Set-Content $DefaultPWDFile $PlainPassword

Write-Host '= Start setup init_win2016ad_install_ad ======================================'
Write-Host "Domain              : $domain"
Write-Host "Domain Mode         : $DomainMode"
Write-Host "IP                  : $ip"
Write-Host "DNS 1               : $dns1"
Write-Host "DNS 2               : $dns2"
Write-Host "Default Password    : $PlainPassword"
Write-Host '- Installing RSAT tools ------------------------------------'

Import-Module ServerManager
Add-WindowsFeature RSAT-AD-PowerShell,RSAT-AD-AdminCenter,RSAT-ADDS-Tools

Write-Host '- Relax password complexity --------------------------------'
# Disable password complexity policy
secedit /export /cfg C:\secpol.cfg
(gc C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
secedit /configure /db C:\Windows\security\local.sdb /cfg C:\secpol.cfg /areas SECURITYPOLICY
rm -force C:\secpol.cfg -confirm:$false

# Set administrator password
$computerName = $env:COMPUTERNAME
$adminUser = [ADSI] "WinNT://$computerName/Administrator,User"
$adminUser.SetPassword($PlainPassword)

$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
    
Write-Host '- Creating domain controller -------------------------------'
# Create AD Forest for Windows Server 2012 R2
Install-WindowsFeature AD-domain-services
Import-Module ADDSDeployment
Install-ADDSForest `
    -SafeModeAdministratorPassword $SecurePassword `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode $DomainMode `
    -ForestMode $DomainMode `
    -DomainName $domain `
    -DomainNetbiosName $netbiosDomain `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$true `
    -SysvolPath "C:\Windows\SYSVOL" `
    -Force:$true

Write-Host '- Configure network adapter --------------------------------'
$newDNSServers = $dns1, $dns2
$adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -And ($_.IPAddress).StartsWith($subnet) }
if ($adapters) {
    Write-Host Setting DNS
    $adapters | ForEach-Object {$_.SetDNSServerSearchOrder($newDNSServers)}
}

# --- EOF --------------------------------------------------------------------