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
    [switch]$Debug,
    [switch]$Quiet,
    # Path to the configuration file
    [string]$ConfigFile = "00_init_environment.ps1"
)
# - End of Customization -------------------------------------------------------

# - Default Values -------------------------------------------------------------
$Hostname       = [System.Net.Dns]::GetHostName()
$ScriptName     = $MyInvocation.MyCommand.Name
$ScriptBaseName = [System.IO.Path]::GetFileNameWithoutExtension($ScriptName)
$ScriptNameFull = $MyInvocation.MyCommand.Path
$ScriptPath     = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$LogFolder      = Join-Path -Path (Split-Path $ScriptPath -Parent) -ChildPath "logs"
$LogFile        = Join-Path -Path $LogFolder -ChildPath ($ScriptBaseName + "_" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log")
$ConfigFile     = Join-Path -Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -ChildPath $ConfigFile
# - End of Default Values ------------------------------------------------------

# - Initialisation -------------------------------------------------------------

# Display help information if -Help parameter is used
if ($Help) {
    Get-Help ".\$ScriptName" -detailed
    exit 
}

# Load CommonFunctions Module
$ModulePath = Join-Path -Path $ScriptPath -ChildPath "Modules\CommonFunctions"
Import-Module $ModulePath

# Set log levels
if ($Debug) { Set-LoggingLevel -NewLevel DEBUG }    # Set Logging Level DEBUG
if ($Quiet) { Set-LoggingLevel -NewLevel WARNING }  # Set Logging Level QUIET

# start logging
try {
    New-Item -ItemType Directory -Force -Path $LogFolder
    Start-Transcript -path $LogFile
} catch {
    Exit-Script -ErrorMessage "Failed to start logging. Error: $_"
}

Write-Host
Write-Log -Level INFO -Message "=============================================================="
Write-Log -Level INFO -Message "INFO: Start $ScriptName on host $Hostname at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Check and Import Required Module
try {
    if (-not (Get-Module -ListAvailable -Name ADDSDeployment)) {
        Write-Log -Level INFO -Message "The ADDSDeployment module is not installed. Attempting to install it."
        Install-Module -Name ADDSDeployment -Scope CurrentUser -Force
        Write-Log -Level INFO -Message "ADDSDeployment module installed successfully."
    }
    Import-Module ADDSDeployment -ErrorAction Stop
    Write-Log -Level INFO -Message "ADDSDeployment module imported successfully."
} catch {
    Exit-Script -ErrorMessage "Failed to manage the ADDSDeployment module. Error: $_"
}

# call Config Script with Error Handling
try {
    if (Test-Path -Path $ConfigFile) {
        Write-Log -Level INFO -Message "INFO: load default values from $ConfigFile"
        . $ConfigFile
    } else {
        throw "Config file $ConfigFile not found."
    }
} catch {
    Exit-Script -ErrorMessage "Failed to load config file. Error: $_"
}
# - EOF Initialisation ---------------------------------------------------------

Write-Log -Level DEBUG -Message "Default Values -----------------------------------------------"
Write-Log -Level DEBUG -Message "Script Name           : $ScriptName"
Write-Log -Level DEBUG -Message "Script Path           : $ScriptNameFull"
Write-Log -Level DEBUG -Message "Script Folder         : $ScriptPath"
Write-Log -Level DEBUG -Message "Log Folder            : $LogFolder"
Write-Log -Level DEBUG -Message "Log File              : $LogFile"
Write-Log -Level DEBUG -Message "Config Folder         : $ConfigPath"
Write-Log -Level DEBUG -Message "Config File           : $ConfigFile"
Write-Log -Level DEBUG -Message "Password File         : $DefaultPWDFile"
Write-Log -Level DEBUG -Message "Network Domain Name   : $NetworkDomainName"
Write-Log -Level DEBUG -Message "NetBios Name          : $netbiosDomain"
Write-Log -Level DEBUG -Message "AD Domain Mode        : $ADDomainMode"
Write-Log -Level DEBUG -Message "Host IP Address       : $ServerAddress"
Write-Log -Level DEBUG -Message "Subnet                : $Subnet"
Write-Log -Level DEBUG -Message "DNS Server 1          : $DNS1ClientServerAddress"
Write-Log -Level DEBUG -Message "DNS Server 2          : $DNS2ClientServerAddress"
Write-Log -Level DEBUG -Message "Default Password      : $PlainPassword"
Write-Log -Level DEBUG -Message ""

Write-Log -Level INFO -Message "--------------------------------------------------------------"
Write-Log -Level INFO -Message "Install AD Role"

try {
    $computerSystem = Get-WmiObject Win32_ComputerSystem
    if ($computerSystem.PartOfDomain -eq $false) {
        Write-Log -Level INFO -Message "Installing AD-Domain-Services"
        Import-Module ServerManager
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

        Write-Log -Level INFO -Message "Relax password complexity"
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

        Write-Log -Level INFO -Message "Creating domain controller"
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

        Write-Log -Level INFO -Message "Configure network adapter"
        $newDNSServers = $DNS1ClientServerAddress, $DNS2ClientServerAddress
        $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -and ($_.IPAddress).StartsWith($Subnet) }
        foreach ($adapter in $adapters) {
            $adapter.SetDNSServerSearchOrder($newDNSServers)
        }
    }
} catch {
    Exit-Script -ErrorMessage "Failed in AD Role Installation process. Error: $_"
}

Exit-Script
# --- EOF ----------------------------------------------------------------------