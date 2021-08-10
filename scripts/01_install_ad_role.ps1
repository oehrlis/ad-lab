# ------------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 01_install_ad_role.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.06.19
# Revision...: 
# Purpose....: Script to install Active Directory Role
# Notes......: ...
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ------------------------------------------------------------------------------

# - Customization --------------------------------------------------------------
# - End of Customization -------------------------------------------------------

# - Default Values -------------------------------------------------------------
$ScriptName     = $MyInvocation.MyCommand.Name
$ScriptNameFull = $MyInvocation.MyCommand.Path
$ConfigScript   = (Split-Path $MyInvocation.MyCommand.Path -Parent) + "\00_init_environment.ps1"
$Hostname       = (Hostname)
# call Config Script
if ((Test-Path $ConfigScript)) {
    Write-Host "INFO : load default values from $DefaultPWDFile"
    . $ConfigScript
} else {
    Write-Error "ERROR: could not load default values"
    exit 1
}
# - EOF Variables --------------------------------------------------------------

# - Main -----------------------------------------------------------------------
Write-Host "INFO: -------------------------------------------------------------" 
Write-Host "INFO: Start $ScriptName on host $Hostname at" (Get-Date -UFormat "%d %B %Y %T")
Write-Host "INFO: Default Values ----------------------------------------------" 
Write-Host "      Script Name           : $ScriptName"
Write-Host "      Script full qualified : $ScriptNameFull"
Write-Host "      Script Path           : $ScriptPath"
Write-Host "      Config Path           : $ConfigPath"
Write-Host "      Config Script         : $ConfigScript"
Write-Host "      Password File         : $DefaultPWDFile"
Write-Host "      Network Domain Name   : $NetworkDomainName"
Write-Host "      NetBios Name          : $netbiosDomain"
Write-Host "      AD Domain Mode        : $ADDomainMode"
Write-Host "      Host IP Address       : $ServerAddress"
Write-Host "      Subnet                : $Subnet"
Write-Host "      DNS Server 1          : $DNS1Address"
Write-Host "      DNS Server 2          : $DNS2Address"
Write-Host "      Default Password      : $PlainPassword"
Write-Host "INFO: -------------------------------------------------------------" 

Write-Host "INFO: Install AD Role" 
# initiate AD setup if system is not yet part of a domain
if ((gwmi win32_computersystem).partofdomain -eq $false) {
    Write-Host "INFO: Installing RSAT tools"

    Import-Module ServerManager
    Add-WindowsFeature RSAT-AD-PowerShell,RSAT-AD-AdminCenter,RSAT-ADDS-Tools

    Write-Host "INFO: Relax password complexity"
    # Disable password complexity policy
    secedit /export /cfg C:\secpol.cfg
    (Get-Content C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
    (Get-Content C:\secpol.cfg).replace("PasswordHistorySize = 24", "PasswordHistorySize = 0") | Out-File C:\secpol.cfg
    secedit /configure /db C:\Windows\security\local.sdb /cfg C:\secpol.cfg /areas SECURITYPOLICY
    rm -force C:\secpol.cfg -confirm:$false

    # Set administrator password
    $computerName   = $env:COMPUTERNAME
    $adminUser      = [ADSI] "WinNT://$computerName/Administrator,User"
    $SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
    $adminUser.SetPassword($PlainPassword)

    Write-Host "INFO: Creating domain controller"
    # Create AD Forest for Windows Server 2012 R2
    Install-WindowsFeature AD-domain-services
    Import-Module ADDSDeployment
    Install-ADDSForest `
        -SafeModeAdministratorPassword $SecurePassword `
        -CreateDnsDelegation:$false `
        -DatabasePath "C:\Windows\NTDS" `
        -DomainMode $ADDomainMode `
        -ForestMode $ADDomainMode `
        -DomainName $NetworkDomainName `
        -DomainNetbiosName $netbiosDomain `
        -InstallDns:$true `
        -LogPath "C:\Windows\NTDS" `
        -NoRebootOnCompletion:$true `
        -SysvolPath "C:\Windows\SYSVOL" `
        -Force:$true
        
    Write-Host "INFO: Configure network adapter"
    $newDNSServers = $DNS1Address, $DNS2Address
    $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -And ($_.IPAddress).StartsWith($subnet) }
    if ($adapters) {
        Write-Host "INFO: Setting DNS"
        $adapters | ForEach-Object {$_.SetDNSServerSearchOrder($newDNSServers)}
    }
}
Write-Host "INFO: Finish $ScriptName" (Get-Date -UFormat "%d %B %Y %T")
Write-Host "INFO: -------------------------------------------------------------" 
# --- EOF --------------------------------------------------------------------