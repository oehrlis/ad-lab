# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 40_reset_ad_users.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.06.23
# Revision...: 
# Purpose....: Script to reset the active directory users
# Notes......: ...
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

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
# - EOF Variables --------------------------------------------------------------

# - Initialisation -------------------------------------------------------------

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
Write-Host "INFO: ==============================================================" 
Write-Host "INFO: Start $ScriptName on host $Hostname at" (Get-Date -UFormat "%d %B %Y %T")

# call Config Script
if ((Test-Path $ConfigFile)) {
    Write-Host "INFO: load default values from $ConfigFile"
    . $ConfigFile
} else {
    Write-Error "ERROR: could not load default values"
    exit 1
}
# - EOF Initialisation ---------------------------------------------------------

# - Main -----------------------------------------------------------------------
Import-Module ActiveDirectory

# Update group membership of Trivadis LAB Users
Write-Host "INFO: Add group Trivadis LAB Users to ORA_VFR_11G and ORA_VFR_12C..."
Add-ADPrincipalGroupMembership -Identity "Trivadis LAB Users" -MemberOf ORA_VFR_11G
# ORA_VFR_12C should yet not been used for EUS. Make sure you clarify the SHA512 issues on the DB first.
#Add-ADPrincipalGroupMembership -Identity "Trivadis LAB Users" -MemberOf ORA_VFR_12C

# reset passwords
Write-Host "INFO: Reset all User Passwords..."
Set-ADAccountPassword -Reset -NewPassword $SecurePassword -Identity lynd
Set-ADAccountPassword -Reset -NewPassword $SecurePassword -Identity rider
Set-ADAccountPassword -Reset -NewPassword $SecurePassword -Identity tanner
Set-ADAccountPassword -Reset -NewPassword $SecurePassword -Identity gartner
Set-ADAccountPassword -Reset -NewPassword $SecurePassword -Identity fleming
Set-ADAccountPassword -Reset -NewPassword $SecurePassword -Identity bond
Set-ADAccountPassword -Reset -NewPassword $SecurePassword -Identity walters
Set-ADAccountPassword -Reset -NewPassword $SecurePassword -Identity renton
Set-ADAccountPassword -Reset -NewPassword $SecurePassword -Identity leitner
Set-ADAccountPassword -Reset -NewPassword $SecurePassword -Identity blake
Set-ADAccountPassword -Reset -NewPassword $SecurePassword -Identity ward
Set-ADAccountPassword -Reset -NewPassword $SecurePassword -Identity moneypenny
Set-ADAccountPassword -Reset -NewPassword $SecurePassword -Identity scott
Set-ADAccountPassword -Reset -NewPassword $SecurePassword -Identity smith
Set-ADAccountPassword -Reset -NewPassword $SecurePassword -Identity adams
Set-ADAccountPassword -Reset -NewPassword $SecurePassword -Identity blofeld
Set-ADAccountPassword -Reset -NewPassword $SecurePassword -Identity miller
Set-ADAccountPassword -Reset -NewPassword $SecurePassword -Identity clark
Set-ADAccountPassword -Reset -NewPassword $SecurePassword -Identity king

Write-Host "INFO: Finish $ScriptName" (Get-Date -UFormat "%d %B %Y %T")
Write-Host "INFO: ==============================================================" 
# --- EOF ----------------------------------------------------------------------