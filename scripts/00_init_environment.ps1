# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 00_init_environment.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.06.23
# Revision...: 
# Purpose....: Initialize and configure the default values
# Notes......: ...
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# - Customization --------------------------------------------------------------
$NetworkDomainName          = "trivadislabs.com"    # Domain Name used to setup the DC and DNS
$netbiosDomain              = ""                    # NetBios Name defaults to uppercase domain name 
$Subnet                     = ""                    # SubNet generated from IP address if omitted
$ADDomainMode               = "Default"             # AD Domain Mode e.g Win2008, Win2008R2, Win2012, Win2012R2, WinThreshold, Default
$ServerAddress              = ""                    # IP address of the DC if ommited 
$DNS1ClientServerAddress    = "8.8.8.8"             # IP Address of the first DNS server
$DNS2ClientServerAddress    = "4.4.4.4"             # IP Address of the second DNS server
$PlainPassword              = ""                    # default Password use to setup. If empty it will be taken from default_pwd_windows.txt or generated
$PasswordLength             = 15                    # password length if password is generated
$ScriptDebug                = ""                    # set to any value to enable debug messages 
$People                     = "People"              # OU Name used for user entries
$Groups                     = "Groups"              # OU Name used for group entries
$Company                    = "Trivadis LAB"        # Company name
$OracleBase                 = "C:\u00\app\oracle"   # Oracle Base Folder              
# - End of Customization -------------------------------------------------------

# - Default Values -------------------------------------------------------------
Write-Log -Level INFO -Message "INFO: Set the default configuration values ------------------------" 
$ConfigScriptName       = $MyInvocation.MyCommand.Name
$ConfigScriptNameFull   = $MyInvocation.MyCommand.Path
$ScriptPath             = (Split-Path $ConfigScriptNameFull -Parent)
$ConfigPath             = Join-Path -Path (Split-Path $ScriptPath -Parent) -ChildPath "config"
$DefaultPWDFile         = Join-Path -Path $ConfigPath -ChildPath "default_pwd_windows.txt"
$DefaultConfigFile      = Join-Path -Path $ConfigPath -ChildPath "default_configuration.txt"
$UserCSVFile            = Join-Path -Path $ConfigPath -ChildPath "users_ad.csv"
$HostCSVFile            = Join-Path -Path $ConfigPath -ChildPath "hosts.csv"
$RootCAFile             = Join-Path -Path $ConfigPath -ChildPath "rootCA.cer"
# - End of Default Values ------------------------------------------------------

# Load CommonFunctions Module
$ModulePath = Join-Path -Path $ScriptPath -ChildPath "Modules\CommonFunctions"
Import-Module $ModulePath

# call Config Script
if ((Test-Path $DefaultConfigFile)) {
    Write-Log -Level INFO -Message "Load default config values from $DefaultConfigFile"
    $DefaultConfigHash = Get-Content -raw -Path $DefaultConfigFile | ConvertFrom-StringData
} else {
    Write-Log -Level WARNING -Message "Could not load default values"
}

# set default values from Config Hash
Write-Log -Level INFO -Message "Set default config values from config hash"
if ($DefaultConfigHash.NetworkDomainName) {
    $NetworkDomainName = $DefaultConfigHash.NetworkDomainName
}

if ($DefaultConfigHash.netbiosDomain) {
    $netbiosDomain = $DefaultConfigHash.netbiosDomain
} else {
    # Get the default NetBios Name from the domain name
    if (!$netbiosDomain) { 
        $netbiosDomain  = $NetworkDomainName.ToUpper() -replace "\.\w*$",""
    }
}

if ($DefaultConfigHash.ADDomainMode) {
    $ADDomainMode = $DefaultConfigHash.ADDomainMode
}

if ($DefaultConfigHash.ServerAddress) {
    $ServerAddress = $DefaultConfigHash.ServerAddress
} else {
    # get the $ServerAddress if not defined
    if (!$ServerAddress) { 
        $ServerAddress = (Get-NetIPAddress `
            -AddressFamily IPv4 `
            -InterfaceAlias "Ethernet*").IPAddress | Select-Object -first 1
    }
}

if ($DefaultConfigHash.ServerAddress) {
    $ServerAddress = $DefaultConfigHash.ServerAddress
} else {
    # get the $ServerAddress if not defined
    if (!$ServerAddress) { 
        $ServerAddress = (Get-NetIPAddress `
            -AddressFamily IPv4 `
            -InterfaceAlias "Ethernet*").IPAddress | Select-Object -first 1
    }
}

if ($DefaultConfigHash.DNS1ClientServerAddress) {
    $DNS1ClientServerAddress = $DefaultConfigHash.DNS1ClientServerAddress
} else {
    # get the $DNS1ClientServerAddress if not defined
    if (!$DNS1ClientServerAddress) { 
        $DNS1ClientServerAddress = (Get-DnsClientServerAddress `
            -AddressFamily IPv4 `
            -InterfaceAlias "Ethernet*").ServerAddresses | Select-Object -first 1
    }
}

if ($DefaultConfigHash.DNS2ClientServerAddress) {
    $DNS2ClientServerAddress = $DefaultConfigHash.DNS2ClientServerAddress
} else {
    # get the $DNS2ClientServerAddress if not defined
    if (!$DNS2ClientServerAddress) { 
        $DNS2ClientServerAddress = (Get-DnsClientServerAddress `
            -AddressFamily IPv4 `
            -InterfaceAlias "Ethernet*").ServerAddresses | Select-Object -last 1
    }
}

if ($DefaultConfigHash.PasswordLength) {
    $PasswordLength = $DefaultConfigHash.PasswordLength
}

if ($DefaultConfigHash.People) {
    $People = $DefaultConfigHash.People
}

if ($DefaultConfigHash.Groups) {
    $Groups = $DefaultConfigHash.Groups
}

if ($DefaultConfigHash.Company) {
    $Company = $DefaultConfigHash.Company
}

if ($DefaultConfigHash.Company) {
    $Company = $DefaultConfigHash.Company
} else {
    # Get the default NetBios Name from the domain name
    if (!$Company) { 
        $CompanyName    = $NetworkDomainName.ToTitleCase() -replace "\.\w*$",""
        $Company        = "$CompanyName LAB"
    }
}

if ($DefaultConfigHash.PlainPassword) {
    $PlainPassword = $DefaultConfigHash.PlainPassword
}

# get the default subnet from the IP Address
if (!$Subnet) { 
    $Subnet  = $ServerAddress -replace "\.\w*$", ""
}

# generate random password if variable is empty
if (!$PlainPassword) { 
    # get default password from file
    if ((Test-Path $DefaultPWDFile)) {
        Write-Log -Level INFO -Message "Get default password from $DefaultPWDFile"
        $PlainPassword=Get-Content -Path  $DefaultPWDFile -TotalCount 1
        # generate a password if password from file is empty
        if (!$PlainPassword) {
            Write-Log -Level INFO -Message "Default password from $DefaultPWDFile seems empty, generate new password"
            $PlainPassword = New-Password
        } else {
            $PlainPassword=$PlainPassword.trim()
        }
    } else {
        # generate a new password
        Write-Log -Level INFO -Message "Generate new password"
        $PlainPassword = New-Password
    } 
} else {
    Write-Log -Level INFO -Message "Using password provided via config file"
}
# Create secure Password string
$SecurePassword = ConvertTo-SecureString -AsPlainText $PlainPassword -Force

# update password file
Write-Log -Level INFO -Message "INFO: Write default password to $DefaultPWDFile"
Set-Content $DefaultPWDFile $PlainPassword
# - EOF Default Values ---------------------------------------------------------

# - Main --------------------------------------------------------------------
if ($ScriptDebug) { 
    Write-Log -Level INFO -Message "Default Values ----------------------------------------------"
    Write-Log -Level INFO -Message "    Script Name           : $ScriptName"
    Write-Log -Level INFO -Message "    Script full qualified : $ScriptNameFull"
    Write-Log -Level INFO -Message "    Script Path           : $ScriptPath"
    Write-Log -Level INFO -Message "    Config Path           : $ConfigPath"
    Write-Log -Level INFO -Message "    Password File         : $DefaultPWDFile"
    Write-Log -Level INFO -Message "    Network Domain Name   : $NetworkDomainName"
    Write-Log -Level INFO -Message "    NetBios Name          : $netbiosDomain"
    Write-Log -Level INFO -Message "    AD Domain Mode        : $ADDomainMode"
    Write-Log -Level INFO -Message "    Host IP Address       : $ServerAddress"
    Write-Log -Level INFO -Message "    Subnet                : $Subnet"
    Write-Log -Level INFO -Message "    DNS Server 1          : $DNS1ClientServerAddress"
    Write-Log -Level INFO -Message "    DNS Server 2          : $DNS2ClientServerAddress"
    Write-Log -Level INFO -Message "    Default Password      : $PlainPassword"
    Write-Log -Level INFO -Message "    OU User Name          : $People"
    Write-Log -Level INFO -Message "    OU Group Name         : $Groups"
    Write-Log -Level INFO -Message "    Company Name          : $Company"
    Write-Log -Level INFO -Message "    User CSV File         : $UserCSVFile"
    Write-Log -Level INFO -Message "    Host CSV File         : $HostCSVFile"
    Write-Log -Level INFO -Message "    Oracle Base Folder    : $OracleBase"
    Write-Log -Level INFO -Message "-------------------------------------------------------------"
}
# --- EOF ----------------------------------------------------------------------
