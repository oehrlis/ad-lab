# ------------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 12_config_dns.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.08.17
# Revision...: 
# Purpose....: Script to configure DNS server
# Notes......: ...
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ------------------------------------------------------------------------------

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
    Write-Host "INFO : load default values from $DefaultPWDFile"
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
$REALM          = $adDomain.DNSRoot.ToUpper()
# - EOF Variables --------------------------------------------------------------

# - Main -----------------------------------------------------------------------
Write-Host "INFO: Default Values -----------------------------------------------" 
Write-Host "      Script Name       : $ScriptName"
Write-Host "      Script fq         : $ScriptNameFull"
Write-Host "      Script Path       : $ScriptPath"
Write-Host "      Config Path       : $ConfigPath"
Write-Host "      Config Script     : $ConfigScript"
Write-Host "      Password File     : $DefaultPWDFile"
Write-Host "      Host File         : $HostCSVFile"
Write-Host "      Host              : $NAT_HOSTNAME"
Write-Host "      Domain            : $domain"
Write-Host "      REALM             : $REALM"
Write-Host "      Base DN           : $domainDn"

Write-Host 'INFO : Create reverse lookup zone...'
# create reverse lookup zone
Add-DnsServerPrimaryZone -NetworkID "10.0.0.0/24" -ReplicationScope "Forest"
Add-DnsServerPrimaryZone -Name "west02.contoso.com" -ZoneFile "west02.contoso.com.dns"
# temporary remove AD server record
#Remove-DnsServerResourceRecord -ZoneName $domain -RRType "A" -Name $NAT_HOSTNAME -Force

#...and import hosts
Write-Host 'INFO : Process hosts from CSV ...'
$HostList = Import-Csv -Path $HostCSVFile   
foreach ($HostRecord in $HostList)
{
    $IP         = $HostRecord.IP
    $IPv4Name   = $IP.Split(".")[3]
    $Hostname   = $HostRecord.Name
    $FQDN       = $Hostname + '.'+ $domain
    $Keytabfile = 'C:\vagrant_common\config\tnsadmin\' + $FQDN + '.keytab'
    $Zone       = "0.0.10.in-addr.arpa"

    # Write-Host "Add DNS Resource Record A for Host $Hostname with IP $IP ..."
    # Try {
    #     Add-DnsServerResourceRecordA -Name $Hostname -ZoneName $domain -AllowUpdateAny -IPv4Address $IP -TimeToLive 01:00:00
    # } Catch {
    #     Write-Host "Error while adding Resource Record A for Host:`n$($Error[0].Exception.Message)"
    # }
    Write-Host "Add DNS PTR resource record for Host $Hostname for $FQDN"
    # Add-DnsServerResourceRecordPtr -Name $IPv4Name -ZoneName $Zone -AllowUpdateAny -TimeToLive 01:00:00 -AgeRecord -PtrDomainName $FQDN
    # if ( $Hostname -Match "db") {
    #     Write-Host "Generate keytab file for host $Hostname ..."
    #     $cmd = 'ktpass -princ oracle/' + $FQDN + '@' + $REALM + ' -mapuser ' + $FQDN + ' -pass ' + $PlainPassword + ' -crypto ALL -ptype KRB5_NT_PRINCIPAL -out ' + $Keytabfile
    #     $output = cmd /c $cmd 2>&1
    #     # print command
    #     Write-Host $cmd
    #     # print output off command
    #     Write-Host $output
    # } else {
    #     Write-Host "Skip keytab file generation for host $Hostname ..."
    # }
}

# add CNAME records for ad, db and oud
Add-DnsServerResourceRecordCName -Name "ad"  -HostNameAlias "win2016ad.$domain" -ZoneName $domain
Add-DnsServerResourceRecordCName -Name "oud" -HostNameAlias "ol7oud12.$domain"  -ZoneName $domain
Add-DnsServerResourceRecordCName -Name "db"  -HostNameAlias "ol7db19.$domain"   -ZoneName $domain

# get the IP Address of the NAT Network
$NAT_IP=(Get-WmiObject -Class Win32_NetworkAdapterConfiguration | where {$_.DefaultIPGateway -ne $null}).IPAddress | select-object -first 1
$NAT_HOSTNAME=hostname

# get DNS Server Records
Get-DnsServerResourceRecord -ZoneName $domain -Name $NAT_HOSTNAME

Write-Host "INFO: Done configuring DNS -----------------------------------------" 
Write-Host "INFO: Finish $ScriptName" (Get-Date -UFormat "%d %B %Y %T")
Write-Host "INFO: ==============================================================" 
# --- EOF ----------------------------------------------------------------------