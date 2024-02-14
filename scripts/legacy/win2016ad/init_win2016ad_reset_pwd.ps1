# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: init_win2016ad_reset_pwd.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2019.05.13
# Revision...: 
# Purpose....: Script to reset Administrator password
# Notes......: Set-ExecutionPolicy Bypass -Scope Process -Force;
# Reference..: 
# License....: Licensed under the Universal Permissive License v 1.0 as 
#              shown at http://oss.oracle.com/licenses/upl.
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ---------------------------------------------------------------------------
Set-ExecutionPolicy Bypass -Scope Process -Force;
# Global Variables
$PlainPassword="LAB.42schulung"
# Set the Administrator Password and activate the Domain Admin Account
net user Administrator $PlainPassword /logonpasswordchg:no /active:yes
# --- EOF --------------------------------------------------------------------