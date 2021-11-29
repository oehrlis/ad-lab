# ------------------------------------------------------------------------------
# Trivadis - Part of Accenture, Platform Factory - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
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
# Modified...:
# see git revision history for more information on changes/updates
# ------------------------------------------------------------------------------

# - Variables ------------------------------------------------------------------
$StageFolder            = "C:\stage"
$LogFolder              = "$StageFolder\logs"
# - EOF Variables --------------------------------------------------------------

# - Main -----------------------------------------------------------------------
Write-Host '= Start AD-Lab config part II ======================================'
New-Item -ItemType Directory -Force -Path $LogFolder
$ErrorActionPreference="SilentlyContinue"
Start-Transcript -path "$LogFolder\52_config_ad-lab_part2.log" 

Write-Host "INFO: Config Values ------------------------------------------------" 
Write-Host "Stage folder        : $StageFolder"
Write-Host "Log folder          : $LogFolder"

# Download AD Scripts
Write-Host '- call 11_add_lab_company script -----------------------------------'
& "$StageFolder\ad-lab\scripts\11_add_lab_company.ps1" 
Write-Host '- call 11_add_service_principles script ----------------------------'
& "$StageFolder\ad-lab\scripts\11_add_service_principles.ps1"  
Write-Host '- call 12_config_dns script ----------------------------------------'
& "$StageFolder\ad-lab\scripts\12_config_dns.ps1"
Write-Host '- call 26_install_tools script -------------------------------------'
& "$StageFolder\ad-lab\scripts\26_install_tools.ps1" 
Write-Host '- call 28_config_misc script ---------------------------------------'
& "$StageFolder\ad-lab\scripts\28_config_misc.ps1"
Write-Host '- call 28_install_oracle_client script -----------------------------'
& "$StageFolder\ad-lab\scripts\28_install_oracle_client.ps1"
Write-Host '- call 13_config_ca script -----------------------------------------'
& "$StageFolder\ad-lab\scripts\13_config_ca.ps1"
Write-Host '- call 19_sum_up_ad script -----------------------------------------'
& "$StageFolder\ad-lab\scripts\19_sum_up_ad.ps1"

# Remove Desktop ShortCut
$FileName = "$env:Public\Desktop\Config AD Part II.lnk"
if (Test-Path $FileName) { Remove-Item $FileName }

Stop-Transcript
Write-Host '= Finish AD-Lab config part II ====================================='
# --- EOF ----------------------------------------------------------------------