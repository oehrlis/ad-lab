# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: 27_config_cmu.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.06.23
# Revision...: 
# Purpose....: Script to configure CMU on Active Directory
# Notes......: ...
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ---------------------------------------------------------------------------

# - Main --------------------------------------------------------------------
Write-Host '= Start setup part 7 ========================================'

# - Variables ---------------------------------------------------------------
$adDomain   = Get-ADDomain
# - EOF Variables -----------------------------------------------------------

# - Configure Domain --------------------------------------------------------
Write-Host '- Configure AD password filter -----------------------------'
Write-Host " not yet implemented"

Write-Host '= Finish part 7 ============================================='
# --- EOF --------------------------------------------------------------------