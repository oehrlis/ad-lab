# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 99_template.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2019.08.17
# Revision...: 
# Purpose....: Template script
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
Write-Host "INFO: ==============================================================" 
Write-Host "INFO: Start $ScriptName on host $Hostname at" (Get-Date -UFormat "%d %B %Y %T")

# call Config Script
if ((Test-Path $ConfigScript)) {
    Write-Host "INFO: load default values from $DefaultPWDFile"
    . $ConfigScript
} else {
    Write-Error "ERROR: could not load default values"
    exit 1
}
# - EOF Initialisation ---------------------------------------------------------

# - Main -----------------------------------------------------------------------
Write-Host "INFO: Default Values -----------------------------------------------" 
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
Write-Host "INFO: -------------------------------------------------------------" 

Write-Host "INFO: Finish $ScriptName" (Get-Date -UFormat "%d %B %Y %T")
Write-Host "INFO: ==============================================================" 
# --- EOF ----------------------------------------------------------------------