# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: 22_install_chocolatey.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.06.23
# Revision...: 
# Purpose....: Script to install Chocolatey package manager
# Notes......: ...
# Reference..: https://chocolatey.org/
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ---------------------------------------------------------------------------

# - Main --------------------------------------------------------------------
Write-Host '= Start setup part 2 ======================================='

# install chocolatey
Write-Host '- Install chocolatey ---------------------------------------'

Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
Write-Host '= Finish part 2 ============================================'
# --- EOF --------------------------------------------------------------------