# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 51_config_ad-lab_part1.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.08.17
# Revision...: 
# Purpose....: Script to config the AD-LAB part I based on the GitHub repository
# Notes......: ...
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http:\\www.apache.org\licenses\
# ------------------------------------------------------------------------------

# - Default Values -------------------------------------------------------------
$ScriptName     = $MyInvocation.MyCommand.Name
$ScriptBaseName = $MyInvocation.MyCommand.Name.Split(".")[0]
$ScriptNameFull = $MyInvocation.MyCommand.Path
$ScriptFolder   = (Split-Path $MyInvocation.MyCommand.Path -Parent)
$LogFolder      = (Split-Path $MyInvocation.MyCommand.Path -Parent|Split-Path -Parent) + "\logs"
$LogFile        = $LogFolder + "\" + $ScriptBaseName + ".log"
$StageFolder    = (Split-Path $MyInvocation.MyCommand.Path -Parent|Split-Path -Parent|Split-Path -Parent)
# - EOF Default Values ---------------------------------------------------------

# - Main -----------------------------------------------------------------------
Write-Host '= Start AD-Lab config part I ======================================='
New-Item -ItemType Directory -Force -Path $LogFolder
$ErrorActionPreference="SilentlyContinue"
Start-Transcript -path "$LogFile" 

Write-Host "INFO: Config Values ------------------------------------------------" 
Write-Host "Stage Folder        : $StageFolder"
Write-Host "Script Folder       : $ScriptFolder"
Write-Host "Log Folder          : $LogFolder"
Write-Host "Log File            : $LogFile"

# Download AD Scripts
Write-Host '- call 01_install_ad_role script -----------------------------------'
& "$ScriptFolder\01_install_ad_role.ps1" 
Write-Host '- call 22_install_chocolatey script --------------------------------'
& "$ScriptFolder\22_install_chocolatey.ps1"

# Remove Desktop ShortCut
$FileName = "$env:Public\Desktop\Config AD Part I.lnk"
if (Test-Path $FileName) { Remove-Item $FileName }

Stop-Transcript
Write-Host '= Finish AD-Lab config part I ======================================'
# --- EOF ----------------------------------------------------------------------