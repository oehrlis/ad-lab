# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 52_config_ad-lab_part2.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.08.17
# Revision...: 
# Purpose....: Script to config the AD-LAB part II based on the GitHub repository
# Notes......: ...
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
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
Write-Host '= Start AD-Lab config part II ======================================'
New-Item -ItemType Directory -Force -Path $LogFolder
$ErrorActionPreference="SilentlyContinue"
Start-Transcript -path "$LogFile" 

Write-Host "INFO: Config Values ------------------------------------------------" 
Write-Host "Stage Folder        : $StageFolder"
Write-Host "Script Folder       : $ScriptFolder"
Write-Host "Log Folder          : $LogFolder"
Write-Host "Log File            : $LogFile"

# Download AD Scripts
Write-Host '- call 11_add_lab_company script -----------------------------------'
& "$ScriptFolder\11_add_lab_company.ps1" 
Write-Host '- call 11_add_service_principles script ----------------------------'
& "$ScriptFolder\11_add_service_principles.ps1"  
Write-Host '- call 12_config_dns script ----------------------------------------'
& "$ScriptFolder\12_config_dns.ps1"
Write-Host '- call 26_install_tools script -------------------------------------'
& "$ScriptFolder\26_install_tools.ps1" 
Write-Host '- call 28_config_misc script ---------------------------------------'
& "$ScriptFolder\28_config_misc.ps1"
Write-Host '- call 28_install_oracle_client script -----------------------------'
& "$ScriptFolder\28_install_oracle_client.ps1"
Write-Host '- call 13_config_ca script -----------------------------------------'
& "$ScriptFolder\13_config_ca.ps1"
Write-Host '- call 19_sum_up_ad script -----------------------------------------'
& "$ScriptFolder\19_sum_up_ad.ps1"

# Remove Desktop ShortCut
$FileName = "$env:Public\Desktop\Config AD Part II.lnk"
if (Test-Path $FileName) { Remove-Item $FileName }

Stop-Transcript
Write-Host '= Finish AD-Lab config part II ====================================='
# --- EOF ----------------------------------------------------------------------