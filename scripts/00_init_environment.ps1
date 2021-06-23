# ------------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 00_init_environment.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.06.19
# Revision...: 
# Purpose....: Initialize and configure the default values
# Notes......: ...
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ------------------------------------------------------------------------------

# - Customization --------------------------------------------------------------
$NetworkDomainName  = "trivadislabs.com"    # Domain Name used to setup the DC and DNS
$netbiosDomain      = ""                    # NetBios Name defaults to uppercase domain name 
$Subnet             = ""                    # SubNet generated from IP address if omitted
$ADDomainMode       = "Default"             # AD Domain Mode e.g Win2008, Win2008R2, Win2012, Win2012R2, WinThreshold, Default
$ServerAddress      = ""                    # IP address of the DC if ommited 
$DNS1Address        = ""                    # IP Address of the first DNS server
$DNS2Address        = ""                    # IP Address of the second DNS server
$PlainPassword      = ""                    # default Password use to setup. If empty it will be taken from default_pwd_windows.txt or generated
$PasswordLength     = 15                    # password length if password is generated
$ScriptDebug        = ""                    # set to any value to enable debug messages 
$People             = "People"              # OU Name used for user entries
$Groups             = "Groups"              # OU Name used for group entries
$Company            = "Trivadis LAB"        # Company name
# - End of Customization -------------------------------------------------------

# - Default Values -------------------------------------------------------------
Write-Host "INFO: Set the default configuration values ------------------------" 
$ConfigScriptNameFull   = $MyInvocation.MyCommand.Path
$ScriptPath             = (Split-Path $ConfigScriptNameFull -Parent)
$ConfigPath             = (Split-Path $ScriptPath -Parent) + "\config"
$DefaultPWDFile         = $ConfigPath + "\default_pwd_windows.txt"
$UserCSVFile            = $ConfigPath + "\users_ad.csv"
$HostCSVFile            = $ConfigPath + "\hosts.csv"
# Get the default NetBios Name from the domain name
if (!$netbiosDomain) { 
    $netbiosDomain  = $domain.ToUpper() -replace "\.\w*$",""
}

# get the $ServerAddress if not defined
if (!$ServerAddress) { 
    $ServerAddress = (Get-NetIPAddress `
        -AddressFamily IPv4 `
        -InterfaceAlias "Ethernet*").IPAddress | Select-Object -first 1
}

# get the default subnet from the IP Address
if (!$Subnet) { 
    $Subnet  = $ServerAddress -replace "\.\w*$", ""
}

# get the $DNS1ClientServerAddress if not defined
if (!$DNS1ClientServerAddress) { 
    $DNS1ClientServerAddress = (Get-DnsClientServerAddress `
        -AddressFamily IPv4 `
        -InterfaceAlias "Ethernet*").ServerAddresses | Select-Object -first 1
}

# get the $DNS2ClientServerAddress if not defined
if (!$DNS2ClientServerAddress) { 
    $DNS2ClientServerAddress = (Get-DnsClientServerAddress `
        -AddressFamily IPv4 `
        -InterfaceAlias "Ethernet*").ServerAddresses | Select-Object -last 1
}

# generate random password if variable is empty
if (!$PlainPassword) { 
    # get default password from file
    if ((Test-Path $DefaultPWDFile)) {
        Write-Host "INFO: Get default password from $DefaultPWDFile"
        $PlainPassword=Get-Content -Path  $DefaultPWDFile -TotalCount 1
        # generate a password if password from file is empty
        if (!$PlainPassword) {
            Write-Host "INFO: Default password from $DefaultPWDFile seems empty, generate new password"
            $PlainPassword = (-join ((48..57) + (97..122) | Get-Random -Count $PasswordLength | % {[char]$_}))
        } else {
            $PlainPassword=$PlainPassword.trim()
        }
    } else {
        # generate a new password
        Write-Error "INFO: Generate new password"
        $PlainPassword = (-join ((48..57) + (97..122) | Get-Random -Count $PasswordLength | % {[char]$_}))
    } 
} else {
    Write-Host "INFO: Using password provided via config file"
}

# update password file
Write-Host "INFO : Write default password to $DefaultPWDFile"
Set-Content $DefaultPWDFile $PlainPassword
# - EOF Default Values ---------------------------------------------------------

# - Main --------------------------------------------------------------------
if ($ScriptDebug) { 
    Write-Host "INFO: Default Values ----------------------------------------------"
    Write-Host "    Script Name           : $ScriptName"
    Write-Host "    Script full qualified : $ScriptNameFull"
    Write-Host "    Script Path           : $ScriptPath"
    Write-Host "    Config Path           : $ConfigPath"
    Write-Host "    Password File         : $DefaultPWDFile"
    Write-Host "    Network Domain Name   : $NetworkDomainName"
    Write-Host "    NetBios Name          : $netbiosDomain"
    Write-Host "    AD Domain Mode        : $ADDomainMode"
    Write-Host "    Host IP Address       : $ServerAddress"
    Write-Host "    Subnet                : $Subnet"
    Write-Host "    DNS Server 1          : $DNS1Address"
    Write-Host "    DNS Server 2          : $DNS2Address"
    Write-Host "    Default Password      : $PlainPassword"
    Write-Host "    OU User Name          : $People"
    Write-Host "    OU Group Name         : $Groups"
    Write-Host "    Company Name          : $Company"
    Write-Host "    User CSV File         : $UserCSVFile"
    Write-Host "    Host CSV File         : $HostCSVFile"
    
    Write-Host "INFO: -------------------------------------------------------------"
}
# --- EOF ----------------------------------------------------------------------
