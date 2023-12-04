# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: init_win2016ad_install_chocolatey.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2019.05.13
# Revision...: 
# Purpose....: Script to install chocolatey
# Notes......: Set-ExecutionPolicy Bypass -Scope Process -Force;
# Reference..: 
# License....: Licensed under the Universal Permissive License v 1.0 as 
#              shown at http://oss.oracle.com/licenses/upl.
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ---------------------------------------------------------------------------
Write-Host '- Installing putty, winscp and other tools -----------------'
choco install --yes --no-progress --limitoutput winscp putty putty.install mobaxterm
choco install --yes --no-progress --limitoutput totalcommander
#choco install -y wsl

# development
Write-Host '- Installing DEV tools -------------------------------------'
choco install --yes --no-progress --limitoutput git github-desktop vscode

# Google chrome
Write-Host '- Installing Google Chrome ----------------------------------'
choco install --yes --no-progress --limitoutput googlechrome

# LDAP Utilities
Write-Host '- Installing LDAP utilities --------------------------------'
choco install --yes --no-progress --limitoutput softerraldapbrowser ldapadmin ldapexplorer 

# Oracle stuff
#choco install -y oracle-sql-developer
choco install --yes --no-progress --limitoutput oracle-sql-developer  --params "'/Username:cpureport@trivadis.com /Password:tr1vad1$'"
choco install --yes --no-progress --limitoutput strawberryperl
choco uninstall --yes --no-progress --limitoutput apache-directory-studio 

# --- EOF --------------------------------------------------------------------