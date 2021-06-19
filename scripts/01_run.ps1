# ------------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 00_config.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2019.06.19
# Revision...: 
# Purpose....: Configure and variable script used to define the default values
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
$ScriptNameFull             = $MyInvocation.MyCommand.Path
$ScriptName                 = $MyInvocation.MyCommand.Name
$ScriptPath                 = (Split-Path $ScriptNameFull -Parent)
$ConfigPath                 = (Split-Path $ScriptPath -Parent) + "\config"
$ConfigScript               = $ScriptPath + "\00_config.ps1"
Write-Host "Script Name             : $ScriptName"
Write-Host "Script fq               : $ScriptNameFull"
# call Config Script
. $ConfigScript

# - EOF Default Values --------------------------------------------------------

# - Main --------------------------------------------------------------------
Write-Host '= Start something =============================================================='
Write-Host "- List Default Values ----------------------------------------------------------"
Write-Host "Script Name             : $ScriptName"
Write-Host "Script fq               : $ScriptNameFull"
Write-Host "Script Path             : $ScriptPath"
Write-Host "Config Path             : $ConfigPath"
Write-Host "Password File           : $DefaultPWDFile"
Write-Host "Network Domain Name     : $NetworkDomainName"
Write-Host "AD Domain Mode          : $ADDomainMode"
Write-Host "Host IP Address         : $ServerAddress"
Write-Host "DNS Server 2            : $DNS1ClientServerAddress"
Write-Host "DNS Server 2            : $DNS2ClientServerAddress"
Write-Host "Default Password        : $PlainPassword"
Write-Host "- EOF Default Values -----------------------------------------------------------"
# --- EOF ----------------------------------------------------------------------
