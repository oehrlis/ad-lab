# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: 29_sum_up_ad.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2019.05.13
# Revision...: 
# Purpose....: Script to display a summary of Active Directory Domain
# Notes......: ...
# Reference..: 
# License....: Licensed under the Universal Permissive License v 1.0 as 
#              shown at http://oss.oracle.com/licenses/upl.
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ---------------------------------------------------------------------------
# - Variables ---------------------------------------------------------------
$# - Default Values -------------------------------------------------------------
$ScriptName     = $MyInvocation.MyCommand.Name
$ScriptNameFull = $MyInvocation.MyCommand.Path
$ConfigScript   = (Split-Path $MyInvocation.MyCommand.Path -Parent) + "\00_init_environment.ps1"
$Hostname       = (Hostname)
# - EOF Default Values ---------------------------------------------------------
# - Main -----------------------------------------------------------------------
# call Config Script
if ((Test-Path $ConfigScript)) {
    Write-Host "INFO : load default values from $DefaultPWDFile"
    . $ConfigScript
} else {
    Write-Error "ERROR: cloud not load default values"
    exit 1
}
# - EOF Variables --------------------------------------------------------------

# - Main --------------------------------------------------------------------
Write-Host "INFO: Start $ScriptName on host $Hostname at" (Get-Date -UFormat "%d %B %Y %T")
Write-Host "INFO: Default Values ----------------------------------------------" 
Write-Host "      Script Name       : $ScriptName"
Write-Host "      Script fq         : $ScriptNameFull"
Write-Host "      Script Path       : $ScriptPath"
Write-Host "      Config Path       : $ConfigPath"
Write-Host "      Config Script     : $ConfigScript"
Write-Host "      Password File     : $DefaultPWDFile"
Write-Host "      Host              : $NAT_HOSTNAME"
Write-Host "      Domain            : $domain"
Write-Host "      REALM             : $REALM"
Write-Host "      Base DN           : $domainDn"
Write-Host "      AD Domain         : $adDomain"
Write-Host "      Domain Base DN    : $domainDn"
Write-Host "      Company Name      : $company"
Write-Host "      Root CA           : $RootCAFile"

Get-DnsServerResourceRecord -ZoneName $domain -Name $NAT_HOSTNAME

# list OS information.
Write-Host 'INFO: OS Details -----------------------------------------------'
New-Object -TypeName PSObject -Property @{
    Is64BitOperatingSystem = [Environment]::Is64BitOperatingSystem
} | Format-Table -AutoSize
[Environment]::OSVersion | Format-Table -AutoSize

# list all the installed Windows features.
Write-Host 'INFO: Installed Windows Features -------------------------------'
Get-WindowsFeature | Where Installed | Format-Table -AutoSize | Out-String -Width 2000

# see https://gist.github.com/IISResetMe/36ef331484a770e23a81
function Get-MachineSID {
    param(
        [switch]$DomainSID
    )

    # Retrieve the Win32_ComputerSystem class and determine if machine is a Domain Controller  
    $WmiComputerSystem = Get-WmiObject -Class Win32_ComputerSystem
    $IsDomainController = $WmiComputerSystem.DomainRole -ge 4

    if ($IsDomainController -or $DomainSID) {
        # We grab the Domain SID from the DomainDNS object (root object in the default NC)
        $Domain    = $WmiComputerSystem.Domain
        $SIDBytes = ([ADSI]"LDAP://$Domain").objectSid | %{$_}
        New-Object System.Security.Principal.SecurityIdentifier -ArgumentList ([Byte[]]$SIDBytes),0
    } else {
        # Going for the local SID by finding a local account and removing its Relative ID (RID)
        $LocalAccountSID = Get-WmiObject -Query "SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True'" | Select-Object -First 1 -ExpandProperty SID
        $MachineSID      = ($p = $LocalAccountSID -split "-")[0..($p.Length-2)]-join"-"
        New-Object System.Security.Principal.SecurityIdentifier -ArgumentList $MachineSID
    }
}

Write-Host "INFO: This Computer SID is $(Get-MachineSID)"
Write-Host ''
Write-Host "INFO: -------------------------------------------------------------" 
Write-Host 'INFO: Successfully finish setup AD '
Write-Host "INFO: Host      : $NAT_HOSTNAME"
Write-Host "INFO: Domain    : $domain"
Write-Host "INFO: -------------------------------------------------------------" 
Write-Host "INFO: Finish $ScriptName" (Get-Date -UFormat "%d %B %Y %T")
Write-Host "INFO: -------------------------------------------------------------" 
# --- EOF --------------------------------------------------------------------