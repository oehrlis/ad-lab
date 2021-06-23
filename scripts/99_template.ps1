# ------------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 01_install_ad_role.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2019.05.19
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
$ConfigScript   = (Split-Path $MyInvocation.MyCommand.Path -Parent) + "\00_config.ps1"
$Hostname       = (Hostname)
# - EOF Default Values ---------------------------------------------------------
# - Main -----------------------------------------------------------------------
# call Config Script
if ((Test-Path $ConfigScript)) {
    Write-Host "INFO : load default values from $DefaultPWDFile"
    . $ConfigScript
} else {
    Write-Error "ERROR: cloud not load default values"
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


Write-Host "INFO: Finish $ScriptName" (Get-Date -UFormat "%d %B %Y %T")
Write-Host "INFO: -------------------------------------------------------------" 
# --- EOF --------------------------------------------------------------------