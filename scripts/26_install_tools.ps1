# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: 26_install_tools.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.06.23
# Revision...: 
# Purpose....: Script to install tools via chocolatey package
# Notes......: ...
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ---------------------------------------------------------------------------

# - Default Values -------------------------------------------------------------
$ScriptName     = $MyInvocation.MyCommand.Name
$Hostname       = (Hostname)
# - EOF Variables --------------------------------------------------------------

# - Initialisation -------------------------------------------------------------
Write-Host "INFO: ==============================================================" 
Write-Host "INFO: Start $ScriptName on host $Hostname at" (Get-Date -UFormat "%d %B %Y %T")
# - EOF Initialisation ---------------------------------------------------------

# - Main -----------------------------------------------------------------------
# - Install tools --------------------------------------------------------------
Write-Host '- Installing putty, winscp and other tools -------------------------'
choco install --yes --no-progress --limitoutput winscp putty putty.install
choco install --yes --no-progress --limitoutput totalcommander
#choco install -y wsl

# development
Write-Host '- Installing DEV tools ---------------------------------------------'
choco install --yes --no-progress --limitoutput git github-desktop vscode

# Google chrome
Write-Host '- Installing Google Chrome -----------------------------------------'
choco install --yes --no-progress --limitoutput googlechrome

# LDAP Utilities
Write-Host '- Installing LDAP utilities ----------------------------------------'
choco install --yes --no-progress --limitoutput softerraldapbrowser ldapadmin ldapexplorer

# Oracle stuff
#choco install -y oracle-sql-developer

Write-Host "INFO: Finish $ScriptName" (Get-Date -UFormat "%d %B %Y %T")
Write-Host "INFO: ==============================================================" 
# --- EOF ----------------------------------------------------------------------