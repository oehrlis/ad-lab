# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: 28_install_oracle_client.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.06.23
# Revision...: 
# Purpose....: Script to install the Oracle Client
# Notes......: ...
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ---------------------------------------------------------------------------


# - Customization --------------------------------------------------------------
# - End of Customization -------------------------------------------------------

# - Default Values -------------------------------------------------------------
$ScriptName     = $MyInvocation.MyCommand.Name
$ScriptNameFull = $MyInvocation.MyCommand.Path
$ConfigScript   = (Split-Path $MyInvocation.MyCommand.Path -Parent) + "\00_init_environment.ps1"
$Hostname       = (Hostname)
# call Config Script
if ((Test-Path $ConfigScript)) {
    Write-Host "INFO : load default values from $DefaultPWDFile"
    . $ConfigScript
} else {
    Write-Error "ERROR: cloud not load default values"
    exit 1
}
# - EOF Variables --------------------------------------------------------------

# - Main -----------------------------------------------------------------------
Write-Host "INFO: -------------------------------------------------------------" 
Write-Host "INFO: Start $ScriptName on host $Hostname at" (Get-Date -UFormat "%d %B %Y %T")
Write-Host "INFO: Default Values ----------------------------------------------" 
Write-Host "INFO: Download Oracle Instant Client 19c --------------------------"
New-Item -ItemType Directory -Force -Path "c:\stage"
Invoke-WebRequest -Uri "https://download.oracle.com/otn_software/nt/instantclient/1911000/instantclient-basic-windows.x64-19.11.0.0.0dbru.zip" `
    -OutFile "c:\stage\instantclient-basic-windows.x64-19.11.0.0.0dbru.zip"
Invoke-WebRequest -Uri "https://download.oracle.com/otn_software/nt/instantclient/1911000/instantclient-sqlplus-windows.x64-19.11.0.0.0dbru.zip" `
    -OutFile "c:\stage\instantclient-sqlplus-windows.x64-19.11.0.0.0dbru.zip"
Invoke-WebRequest -Uri "https://download.oracle.com/otn_software/nt/instantclient/1911000/instantclient-tools-windows.x64-19.11.0.0.0dbru.zip" `
    -OutFile "c:\stage\instantclient-tools-windows.x64-19.11.0.0.0dbru.zip"
Invoke-WebRequest -Uri "https://download.oracle.com/otn_software/nt/instantclient/1911000/instantclient-odbc-windows.x64-19.11.0.0.0dbru.zip" `
    -OutFile "c:\stage\instantclient-odbc-windows.x64-19.11.0.0.0dbru.zip"
Invoke-WebRequest -Uri "https://download.oracle.com/otn_software/nt/instantclient/1911000/instantclient-sdk-windows.x64-19.11.0.0.0dbru.zip" `
    -OutFile "c:\stage\instantclient-sdk-windows.x64-19.11.0.0.0dbru.zip"
Invoke-WebRequest -Uri "https://download.oracle.com/otn_software/nt/instantclient/1911000/instantclient-jdbc-windows.x64-19.11.0.0.0dbru.zip" `
    -OutFile "c:\stage\instantclient-jdbc-windows.x64-19.11.0.0.0dbru.zip"

Write-Host "INFO: Install Oracle Instant Client 19c ---------------------------"
New-Item -ItemType Directory -Force -Path "$OracleBase\product"
New-Item -ItemType Directory -Force -Path "$OracleBase\network\admin"

Expand-Archive -LiteralPath "c:\stage\instantclient-basic-windows.x64-19.11.0.0.0dbru.zip" `
    -DestinationPath "$OracleBase\product"
Expand-Archive -LiteralPath "c:\stage\instantclient-sqlplus-windows.x64-19.11.0.0.0dbru.zip" `
    -DestinationPath "$OracleBase\product"
Expand-Archive -LiteralPath "c:\stage\instantclient-tools-windows.x64-19.11.0.0.0dbru.zip" `
    -DestinationPath "$OracleBase\product"
Expand-Archive -LiteralPath "c:\stage\instantclient-odbc-windows.x64-19.11.0.0.0dbru.zip" `
    -DestinationPath "$OracleBase\product"
Expand-Archive -LiteralPath "c:\stage\instantclient-sdk-windows.x64-19.11.0.0.0dbru.zip" `
    -DestinationPath "$OracleBase\product"
Expand-Archive -LiteralPath "c:\stage\instantclient-jdbc-windows.x64-19.11.0.0.0dbru.zip" `
    -DestinationPath "$OracleBase\product"

Write-Host "INFO: Configure Oracle Instant Client 19c --------------------------"
New-Item -ItemType Directory -Force -Path "$OracleBase\network\admin"
cd "$OracleBase\network\admin"
New-Item -Name "sqlnet.ora" -ItemType File
New-Item -Name "tnsnames.ora" -ItemType File

[System.Environment]::SetEnvironmentVariable('Path',([System.Environment]::GetEnvironmentVariables('Machine')).Path+";$OracleBase\product\instantclient_19_11",'Machine')
[System.Environment]::SetEnvironmentVariable('TNS_ADMIN', "$OracleBase\network\admin",[System.EnvironmentVariableTarget]::Machine)

Write-Host "INFO: Done installing Oracle Instant Client 19c --------------------" 
Write-Host "INFO: Finish $ScriptName" (Get-Date -UFormat "%d %B %Y %T")
Write-Host "INFO: -------------------------------------------------------------" 
# --- EOF --------------------------------------------------------------------