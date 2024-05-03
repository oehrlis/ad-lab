# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 01_install_ad_role.ps1
# Author.....: Stefan Oehrli (oes) scripts@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2024.01.09
# Version....: 0.1.0
# Purpose....: Script to install Active Directory Role
# Notes......: ...
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

<#
.SYNOPSIS
    Installs and configures the Active Directory Domain Services role on a Windows Server.

.DESCRIPTION
    This script is designed to automate the installation of the Active Directory (AD) role on a Windows server. It includes setting up a new domain controller, configuring DNS settings, and adjusting password policies. It reads configuration settings from an external file and logs actions to a specified log file.

.PARAMETER ConfigFile
    Specifies the path to the configuration file. This file contains various settings required for the installation, such as domain name, network settings, and default passwords. The default value is '00_init_environment.ps1'.

.EXAMPLE
    .\01_install_ad_role.ps1
    Executes the script using the default configuration file '00_init_environment.ps1'.

.EXAMPLE
    .\01_install_ad_role.ps1 -ConfigFile "C:\path\to\your_config.ps1"
    Executes the script with a custom configuration file.

.INPUTS
    None. You cannot pipe objects to this script.

.OUTPUTS
    This script does not generate any output objects. It writes output to the console and to a log file in the specified log folder.

.NOTES
    Author: Stefan Oehrli
    Email: scripts@oradba.ch
    Date: 2024.01.09
    Last Modified: [Last Modified Date]
    Version: 0.1.0
    License: Apache License Version 2.0, January 2004 (http://www.apache.org/licenses/)
    OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland

.LINK
    https://github.com/oehrlis/ad-lab/tree/main - OraDBA AD Lab scripts

#>

# - Begin of Customization -----------------------------------------------------
param (
    [switch]$Help,
    # Path to the configuration file
    [string]$ConfigFile = "00_init_environment.ps1"
)
# - End of Customization -------------------------------------------------------

# - Default Values -------------------------------------------------------------
$Hostname       = [System.Net.Dns]::GetHostName()
$ScriptName     = $MyInvocation.MyCommand.Name
param (
    [string]$LogLevel = 'INFO'
)

$ScriptBaseName = [System.IO.Path]::GetFileNameWithoutExtension($ScriptName)
$ScriptNameFull = $MyInvocation.MyCommand.Path
$ScriptPath     = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$LogFolder      = Join-Path -Path (Split-Path $ScriptPath -Parent) -ChildPath "logs"
$LogFile        = Join-Path -Path $LogFolder -ChildPath ($ScriptBaseName + "_" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log")
$ConfigFile     = Join-Path -Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -ChildPath $ConfigFile
# - End of Default Values ------------------------------------------------------

# - Functions ------------------------------------------------------------------
# - End of Functions -----------------------------------------------------------

# - Initialisation -------------------------------------------------------------

# Display help information if -Help parameter is used
if ($Help) {
    Get-Help .\01_install_ad_role.ps1 -detailed
    exit 
}

try {
    New-Item -ItemType Directory -Force -Path $LogFolder
    Start-Transcript -path $LogFile
  catch {
     Write-Log -Level INFO -Message "ERROR: $_"
      exit 1
  }
    Write-Error "Failed to start logging. Error: $_"
    exit 1
}

Write-Host
Write-Log -Level INFO -Message "INFO: ==============================================================" 
Write-Log -Level INFO -Message "INFO: Start $ScriptName on host $Hostname at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Check and Import Required Module
try {
    if (-not (Get-Module -ListAvailable -Name ADDSDeployment)) {
        Write-Log -Level INFO -Message "INFO: The ADDSDeployment module is not installed. Attempting to install it."
        Install-Module -Name ADDSDeployment -Scope CurrentUser -Force
        Write-Log -Level INFO -Message "INFO: ADDSDeployment module installed successfully."
    }
    Import-Module ADDSDeployment -ErrorAction Stop
    Write-Log -Level INFO -Message "INFO: ADDSDeployment module imported successfully."
  catch {
    Write-Log -Level INFO -Message "ERROR: $_"
      exit 1
  }
    Write-Error "ERR : Failed to manage the ADDSDeployment module. Error: $_"
    exit 1
}

# call Config Script with Error Handling
try {
    if (Test-Path -Path $ConfigFile) {
        Write-Log -Level INFO -Message "INFO: load default values from $ConfigFile"
        . $ConfigFile
    } else {
        throw "Config file $ConfigFile not found."
    }
  catch {
    Write-Log -Level INFO -Message "ERROR: $_"
      exit 1
  }
  Write-Log -Level INFO -Message "ERR: Failed to load config file. Error: $_"
    Stop-Transcript
    exit 1
}
# - EOF Initialisation ---------------------------------------------------------

Log-Info "Default Values -----------------------------------------------"
Log-Info "Script Name           : $ScriptName"
Log-Info "Script Path           : $ScriptNameFull"
Log-Info "Script Folder         : $ScriptPath"
Log-Info "Log Folder            : $LogFolder"
Log-Info "Log File              : $LogFile"
Log-Info "Config Folder         : $ConfigPath"
Log-Info "Config File           : $ConfigFile"
Log-Info "Password File         : $DefaultPWDFile"
Log-Info "Network Domain Name   : $NetworkDomainName"
Log-Info "NetBios Name          : $netbiosDomain"
Log-Info "AD Domain Mode        : $ADDomainMode"
Log-Info "Host IP Address       : $ServerAddress"
Log-Info "Subnet                : $Subnet"
Log-Info "DNS Server 1          : $DNS1ClientServerAddress"
Log-Info "DNS Server 2          : $DNS2ClientServerAddress"
Log-Info "Default Password      : $PlainPassword"
Log-Info ""

Log-Info "--------------------------------------------------------------"
Log-Info "Install AD Role"

try {
    $computerSystem = Get-WmiObject Win32_ComputerSystem
    if ($computerSystem.PartOfDomain -eq $false) {
        Log-Info "Installing AD-Domain-Services"
        Import-Module ServerManager
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

        Log-Info "Relax password complexity"
        # Disable password complexity policy
        $secPolConfigPath = "C:\secpol.cfg"
        secedit /export /cfg $secPolConfigPath
        (Get-Content $secPolConfigPath).replace("PasswordComplexity = 1", "PasswordComplexity = 0").replace("PasswordHistorySize = 24", "PasswordHistorySize = 0") | Set-Content $secPolConfigPath
        secedit /configure /db C:\Windows\security\local.sdb /cfg $secPolConfigPath /areas SECURITYPOLICY
        Remove-Item -Force $secPolConfigPath -Confirm:$false

        # Set administrator password
        $computerName = $env:COMPUTERNAME
        $adminUser = [ADSI]"WinNT://$computerName/Administrator,User"
        $SecurePassword = ConvertTo-SecureString -String $PlainPassword -AsPlainText -Force
        $adminUser.SetPassword($SecurePassword)

        Log-Info "Creating domain controller"
        $ADDSForestParams = @{
            SafeModeAdministratorPassword = $SecurePassword
            CreateDnsDelegation           = $false
            DatabasePath                  = "C:\Windows\NTDS"
            DomainMode                    = $ADDomainMode
            ForestMode                    = $ADDomainMode
            DomainName                    = $NetworkDomainName
            DomainNetbiosName             = $netbiosDomain
            InstallDns                    = $true
            LogPath                       = "C:\Windows\NTDS"
            NoRebootOnCompletion          = $true
            SysvolPath                    = "C:\Windows\SYSVOL"
            Force                         = $true
        }
        Import-Module ADDSDeployment
        Install-ADDSForest @ADDSForestParams

        Log-Info "Configure network adapter"
        $newDNSServers = $DNS1ClientServerAddress, $DNS2ClientServerAddress
        $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -and ($_.IPAddress).StartsWith($Subnet) }
        foreach ($adapter in $adapters) {
            $adapter.SetDNSServerSearchOrder($newDNSServers)
        }
    }
  catch {
      Write-Log -Level INFO -Message "ERROR: $_"
      exit 1
  }
    Log-ErrorAndExit "Failed in AD Role Installation process. Error: $_"
}

Log-Info "Finish $ScriptName $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Log-Info "=============================================================="
Stop-Transcript
# --- EOF ----------------------------------------------------------------------