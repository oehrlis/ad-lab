# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 11_add_service_principles.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.08.17
# Revision...:
# Purpose....: Script to configure Active Directory
# Notes......: ...
# Reference..:
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# - Customization --------------------------------------------------------------
# - End of Customization -------------------------------------------------------

# - Default Values -------------------------------------------------------------
$ScriptName     = $MyInvocation.MyCommand.Name
$ScriptNameFull = $MyInvocation.MyCommand.Path
$Hostname       = (Hostname)
$ConfigScript   = (Split-Path $MyInvocation.MyCommand.Path -Parent) + "\00_init_environment.ps1"
# - EOF Default Values ---------------------------------------------------------

# - Initialisation -------------------------------------------------------------
Write-Host
Write-Host "INFO: =============================================================="
Write-Host "INFO: Start $ScriptName on host $Hostname at" (Get-Date -UFormat "%d %B %Y %T")

# call Config Script
if ((Test-Path $ConfigScript)) {
    Write-Host "INFO: load default values from $DefaultPWDFile"
    . $ConfigScript
} else {
    Write-Error "ERROR: cloud not load default values"
    exit 1
}

# wait until we can access the AD. this is needed to prevent errors like:
#   Unable to find a default server with Active Directory Web Services running.
while ($true) {
    try {
        Get-ADDomain | Out-Null
        break
    } catch {
        Write-Host 'Wait 15 seconds to get AD Domain ready...'
        Start-Sleep -Seconds 15
    }
}
# - EOF Initialisation ---------------------------------------------------------

# - Variables ------------------------------------------------------------------
$adDomain       = Get-ADDomain
$domain         = $adDomain.DNSRoot
$domainDn       = $adDomain.DistinguishedName
$PeopleDN       = "ou=$People,$domainDn"
$UsersDN        = "cn=Users,$domainDn"
$GroupDN        = "ou=$Groups,$domainDn"
# - EOF Variables --------------------------------------------------------------

# - Main -----------------------------------------------------------------------
Write-Host "INFO: Default Values -----------------------------------------------"
Write-Host "      Script Name           : $ScriptName"
Write-Host "      Script full qualified : $ScriptNameFull"
Write-Host "      Script Path           : $ScriptPath"
Write-Host "      Config Path           : $ConfigPath"
Write-Host "      Config Script         : $ConfigScript"
Write-Host "      Password File         : $DefaultPWDFile"
Write-Host "      User Config CSV File  : $UserCSVFile"
Write-Host "      Network Domain Name   : $domain"
Write-Host "      BaseDN                : $domainDn"
Write-Host "      People DN             : $PeopleDN"
Write-Host "      User DN               : $UsersDN"
Write-Host "      Group DN              : $GroupDN"
Write-Host "INFO: --------------------------------------------------------------"

# - Configure Domain -----------------------------------------------------------
Import-Module ActiveDirectory           # load AD PS module

# create service principle
Write-Host "INFO: Start configuring the service principles ---------------------"
Write-Host "INFO: Create service principles"
Write-Host "INFO: Process hosts from CSV ($HostCSVFile)"
$HostList = Import-Csv -Path $HostCSVFile
foreach ($HostRecord in $HostList)
{
    $Hostname   = $HostRecord.Name
    Write-Host "INFO: Add service principle for $Hostname"
    New-ADUser -SamAccountName $Hostname -Name $Hostname `
        -DisplayName $Hostname -Description "Kerberos Service User for $Hostname" `
        -Path $UsersDN -AccountPassword $SecurePassword -Enabled $true `
        -KerberosEncryptionType "AES128, AES256"
}

# change vagrant privileges
if (Get-ADUser -Filter "sAMAccountName -eq 'vagrant'") {
    Write-Host "INFO: User vagrant does exist. Change privileges."
    Add-ADGroupMember -Identity "Domain Admins"     -Members vagrant
    Add-ADGroupMember -Identity "Enterprise Admins" -Members vagrant
    Add-ADGroupMember -Identity "Schema Admins" -Members vagrant
}

Write-Host "INFO: Finished configuring the service principles ------------------"
Write-Host "INFO: Finish $ScriptName" (Get-Date -UFormat "%d %B %Y %T")
Write-Host "INFO: =============================================================="
# --- EOF ----------------------------------------------------------------------