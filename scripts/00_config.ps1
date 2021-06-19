# ------------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 00_config.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2019.06.19
# Revision...: 
# Purpose....: Configure and variable script used to define the default values
# Notes......: ...
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ------------------------------------------------------------------------------

# - Customization --------------------------------------------------------------
$NetworkDomainName          = "trivadislabs.com"
$ADDomainMode               = "Win2012R2"
$ServerAddress              = ""
$DNS1ClientServerAddress    = ""
$DNS2ClientServerAddress    = ""
$PlainPassword              = ""
# - End of Customization -------------------------------------------------------

# - Default Values -------------------------------------------------------------
$ConfigScriptNameFull       = $MyInvocation.MyCommand.Path
$ScriptPath                 = (Split-Path $ConfigScriptNameFull -Parent)
$ConfigPath                 = (Split-Path $ScriptPath -Parent) + "\config"
$DefaultPWDFile             = $ConfigPath + "\default_pwd_windows.txt"

# get the $ServerAddress if not defined
if (!$ServerAddress) { 
    $ServerAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet*").IPAddress | Select-Object -first 1
}

# get the $DNS1ClientServerAddress if not defined
if (!$DNS1ClientServerAddress) { 
    $DNS1ClientServerAddress = (Get-DnsClientServerAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet*").ServerAddresses | Select-Object -first 1
}

# get the $DNS2ClientServerAddress if not defined
if (!$DNS2ClientServerAddress) { 
    $DNS2ClientServerAddress = (Get-DnsClientServerAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet*").ServerAddresses | Select-Object -last 1
}

# generate random password if variable is empty
if (!$PlainPassword) { 
    # get default password from file
    if ((Test-Path $DefaultPWDFile)) {
        Write-Host "INFO: Get default password from $DefaultPWDFile"
        $PlainPassword=Get-Content -Path  $DefaultPWDFile -TotalCount 1
        $PlainPassword=$PlainPassword.trim()
        # generate a password if password from file is empty
        if (!$PlainPassword) {
            Write-Host "INFO: Default password from $DefaultPWDFile seems empty, generate new password"
            $PlainPassword = (1..$(Get-Random -Minimum 10 -Maximum 12) | % {$asci | get-random}) -join "" 
        }
    } else {
        # generate a new password
        Write-Error "INFO: Generate new password"
        $PlainPassword = (1..$(Get-Random -Minimum 10 -Maximum 12) | % {$asci | get-random}) -join "" 
    }  
} else {
    Write-Host "INFO: Using password provided via config file"
}
# - EOF Default Values --------------------------------------------------------

# - Main --------------------------------------------------------------------
Write-Host '= Set the default configuration values ========================================='
Write-Host "- List Default Values ----------------------------------------------------------"
Write-Host "Script Name             : $ScriptName"
Write-Host "Script fq               : $ScriptNameFull"
Write-Host "Script Path             : $ScriptPath"
Write-Host "Config Path             : $ConfigPath"
Write-Host "Password File           : $DefaultPWDFile"
Write-Host "Network Domain Name     : $NetworkDomainName"
Write-Host "AD Domain Mode          : $ADDomainMode"
Write-Host "Host IP Address         : $ServerAddress"
Write-Host "DNS Server 2            : $DNS1ClientServerAddress"
Write-Host "DNS Server 2            : $DNS2ClientServerAddress"
Write-Host "Default Password        : $PlainPassword"
Write-Host "- EOF Default Values -----------------------------------------------------------"
# --- EOF ----------------------------------------------------------------------
