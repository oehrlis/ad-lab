# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 01_install_ad_role.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.08.16
# Revision...: 
# Purpose....: Script to install Active Directory Role
# Notes......: ...
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# - Default Values -------------------------------------------------------------
$ScriptName     = $MyInvocation.MyCommand.Name
$ScriptNameFull = $MyInvocation.MyCommand.Path
$Hostname       = (Hostname)
$ConfigScript   = (Split-Path $MyInvocation.MyCommand.Path -Parent) + "\00_init_environment.ps1"
# - EOF Default Values ---------------------------------------------------------

# - Initialisation -------------------------------------------------------------
Write-Host
Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): INFO: ==============================================================" 
Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): INFO: Start $ScriptName on host $Hostname at" (Get-Date -UFormat "%d %B %Y %T")

# call Config Script
if ((Test-Path $ConfigScript)) {
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): INFO: load default values from $ConfigScript"
    . $ConfigScript
} else {
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): ERR : could not load config script $ConfigScript"
    exit 1
}

# - EOF Initialisation ---------------------------------------------------------

# - Main -----------------------------------------------------------------------
Write-HostWithTimestamp "INFO: Default Values -----------------------------------------------" 
Write-HostWithTimestamp "      Script Name           : $ScriptName"
Write-HostWithTimestamp "      Script full qualified : $ScriptNameFull"
Write-HostWithTimestamp "      Script Path           : $ScriptPath"
Write-HostWithTimestamp "      Config Path           : $ConfigPath"
Write-HostWithTimestamp "      Config Script         : $ConfigScript"
Write-HostWithTimestamp "      Password File         : $DefaultPWDFile"
Write-HostWithTimestamp "      Network Domain Name   : $NetworkDomainName"
Write-HostWithTimestamp "      NetBios Name          : $netbiosDomain"
Write-HostWithTimestamp "      AD Domain Mode        : $ADDomainMode"
Write-HostWithTimestamp "      Host IP Address       : $ServerAddress"
Write-HostWithTimestamp "      Subnet                : $Subnet"
Write-HostWithTimestamp "      DNS Server 1          : $DNS1ClientServerAddress"
Write-HostWithTimestamp "      DNS Server 2          : $DNS2ClientServerAddress"
Write-HostWithTimestamp "      Default Password      : $PlainPassword"
Write-HostWithTimestamp "INFO: --------------------------------------------------------------" 

Write-HostWithTimestamp "INFO: Install AD Role" 
# initiate AD setup if system is not yet part of a domain
if ((gwmi win32_computersystem).partofdomain -eq $false) {
    Write-HostWithTimestamp "INFO: Installing AD-Domain-Services"

    Import-Module ServerManager
    Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools

    Write-HostWithTimestamp "INFO: Relax password complexity"
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

    Write-HostWithTimestamp "INFO: Creating domain controller"
    try {
        # Define parameter for ADDSForest
        $ADDSForestParams = @{
            SafeModeAdministratorPassword   =   $SecurePassword
            CreateDnsDelegation             =   $false
            DatabasePath                    =   "C:\Windows\NTDS"
            DomainMode                      =   $ADDomainMode
            ForestMode                      =   $ADDomainMode
            DomainName                      =   $NetworkDomainName
            DomainNetbiosName               =   $netbiosDomain
            InstallDns                      =   $true
            LogPath                         =   "C:\Windows\NTDS"
            NoRebootOnCompletion            =   $true
            SysvolPath                      =   "C:\Windows\SYSVOL"
            Force                           =   $true
        }
        # import required module to deploy the forest
        Import-Module ADDSDeployment
        Install-ADDSForest @ADDSForestParams
    } catch {
        Write-HostWithTimestamp 'ERR : Creating domain controller.'
        Write-HostWithTimestamp $_.Exception.Message
    }

    Write-HostWithTimestamp "INFO: Configure network adapter"
    $newDNSServers = $DNS1ClientServerAddress, $DNS2ClientServerAddress
    $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -And ($_.IPAddress).StartsWith($subnet) }
    if ($adapters) {
        Write-HostWithTimestamp "INFO: Setting DNS"
        $adapters | ForEach-Object {$_.SetDNSServerSearchOrder($newDNSServers)}
    }
}
Write-HostWithTimestamp "INFO: Finish $ScriptName" (Get-Date -UFormat "%d %B %Y %T")
Write-HostWithTimestamp "INFO: ==============================================================" 
# --- EOF ----------------------------------------------------------------------