# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 11_add_service_principles.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.08.17
# Version....: 0.2.0
# Purpose....: Script to configure Active Directory service principals
# Notes......: ...
# Reference..:
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

Set-StrictMode -Version Latest

# - Default Values -------------------------------------------------------------
$ScriptName     = $MyInvocation.MyCommand.Name
$ScriptNameFull = $MyInvocation.MyCommand.Path
$Hostname       = (Hostname)
$ScriptPath     = Split-Path $MyInvocation.MyCommand.Path -Parent
$ConfigScript   = Join-Path -Path $ScriptPath -ChildPath "00_init_environment.ps1"
# - EOF Default Values ---------------------------------------------------------

# Load CommonFunctions Module
$ModulePath = Join-Path -Path $ScriptPath -ChildPath "Modules\CommonFunctions"
Import-Module $ModulePath

# - Initialisation -------------------------------------------------------------
Write-Log -Level INFO -Message "=============================================================="
Write-Log -Level INFO -Message "Start $ScriptName on host $Hostname at $(Get-Date -UFormat '%d %B %Y %T')"

# call Config Script
if (Test-Path $ConfigScript) {
    Write-Log -Level INFO -Message "Load default values from $ConfigScript"
    . $ConfigScript
} else {
    Write-Log -Level ERROR -Message "Could not load default values from $ConfigScript"
    exit 1
}

Wait-ADReady -TimeoutSeconds 300 -IntervalSeconds 15
# - EOF Initialisation ---------------------------------------------------------

# - Variables ------------------------------------------------------------------
$adDomain   = Get-ADDomain
$domain     = $adDomain.DNSRoot
$domainDn   = $adDomain.DistinguishedName
$PeopleDN   = "ou=$People,$domainDn"
$UsersDN    = "cn=Users,$domainDn"
$GroupDN    = "ou=$Groups,$domainDn"
# - EOF Variables --------------------------------------------------------------

# - Main -----------------------------------------------------------------------
Write-Log -Level INFO -Message "Default Values -----------------------------------------------"
Write-Log -Level INFO -Message "    Script Name           : $ScriptName"
Write-Log -Level INFO -Message "    Script full qualified : $ScriptNameFull"
Write-Log -Level INFO -Message "    Script Path           : $ScriptPath"
Write-Log -Level INFO -Message "    Config Path           : $ConfigPath"
Write-Log -Level INFO -Message "    Config Script         : $ConfigScript"
Write-Log -Level INFO -Message "    Password File         : $DefaultPWDFile"
Write-Log -Level INFO -Message "    User Config CSV File  : $UserCSVFile"
Write-Log -Level INFO -Message "    Network Domain Name   : $domain"
Write-Log -Level INFO -Message "    BaseDN                : $domainDn"
Write-Log -Level INFO -Message "    People DN             : $PeopleDN"
Write-Log -Level INFO -Message "    User DN               : $UsersDN"
Write-Log -Level INFO -Message "    Group DN              : $GroupDN"
Write-Log -Level INFO -Message "--------------------------------------------------------------"

# - Configure Domain -----------------------------------------------------------
Import-Module ActiveDirectory

Write-Log -Level INFO -Message "Start configuring the service principals"

try {
    Write-Log -Level INFO -Message "Create host service principals from CSV ($HostCSVFile)"
    $HostList = Import-Csv -Path $HostCSVFile
    foreach ($HostRecord in $HostList) {
        $HostEntry = $HostRecord.Name
        Write-Log -Level INFO -Message "Add service principal for $HostEntry"
        if (-not (Get-ADUser -Filter "sAMAccountName -eq '$HostEntry'" -ErrorAction SilentlyContinue)) {
            New-ADUser -SamAccountName $HostEntry -Name $HostEntry `
                -DisplayName $HostEntry -Description "Kerberos Service User for $HostEntry" `
                -Path $UsersDN -AccountPassword $SecurePassword -Enabled $true `
                -KerberosEncryptionType "AES128, AES256"
        } else {
            Write-Log -Level INFO -Message "Service principal $HostEntry already exists. Skip."
        }
    }
} catch {
    Write-Log -Level ERROR -Message "Failed to create host service principals: $_"
    exit 1
}

try {
    if (-not (Get-ADUser -Filter "sAMAccountName -eq 'oracle'" -ErrorAction SilentlyContinue)) {
        Write-Log -Level INFO -Message "User oracle does not exist. Add new one."
        New-ADUser -SamAccountName "oracle" -Name "oracle" -DisplayName "oracle" `
            -Description "Oracle Service User" -Path $UsersDN `
            -AccountPassword $SecurePassword -Enabled $true `
            -PasswordNeverExpires $true
    } else {
        Write-Log -Level INFO -Message "User oracle already exists. Skip creation."
    }
} catch {
    Write-Log -Level ERROR -Message "Failed to create oracle user: $_"
    exit 1
}

try {
    Write-Log -Level INFO -Message "Change privileges for user oracle"
    Add-ADGroupMember -Identity "Domain Admins"     -Members oracle
    Add-ADGroupMember -Identity "Enterprise Admins" -Members oracle
    Add-ADGroupMember -Identity "Schema Admins"     -Members oracle
} catch {
    Write-Log -Level ERROR -Message "Failed to set oracle group memberships: $_"
}

try {
    if (Get-ADUser -Filter "sAMAccountName -eq 'vagrant'" -ErrorAction SilentlyContinue) {
        Write-Log -Level INFO -Message "User vagrant exists. Change privileges."
        Add-ADGroupMember -Identity "Domain Admins"     -Members vagrant
        Add-ADGroupMember -Identity "Enterprise Admins" -Members vagrant
        Add-ADGroupMember -Identity "Schema Admins"     -Members vagrant
    }
} catch {
    Write-Log -Level ERROR -Message "Failed to set vagrant group memberships: $_"
}

Write-Log -Level INFO -Message "Finished configuring the service principals"
Write-Log -Level INFO -Message "Finish $ScriptName $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log -Level INFO -Message "=============================================================="
# --- EOF ----------------------------------------------------------------------
