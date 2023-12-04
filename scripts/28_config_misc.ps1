# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 28_config_misc.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.08.17
# Revision...: 
# Purpose....: Script to display a summary of Active Directory Domain
# Notes......: ...
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# - Default Values -------------------------------------------------------------
$ScriptName     = $MyInvocation.MyCommand.Name
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
    Write-Error "ERROR: could not load default values"
    exit 1
}
# - EOF Initialisation ---------------------------------------------------------

# - Variables ------------------------------------------------------------------
# get the IP Address of the NAT Network
$NAT_IP=(Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object {$_.DefaultIPGateway -ne $null}).IPAddress | select-object -first 1
$NAT_HOSTNAME=hostname
$adDomain       = Get-ADDomain
$domain         = $adDomain.DNSRoot
$StageFolder    =   "C:\stage"
# - EOF Variables --------------------------------------------------------------

# - Main -----------------------------------------------------------------------
Write-Host "INFO: Default Values -----------------------------------------------" 
Write-Host "Domain              : $domain"
Write-Host "IP                  : $ip"
Write-Host "NAT IP              : $NAT_IP"
Write-Host "NAT Hostname        : $NAT_HOSTNAME"

# get DNS Server Records
Get-DnsServerResourceRecord -ZoneName $domain -Name $NAT_HOSTNAME -RRType "A" 

$NAT_RECORD = Get-DnsServerResourceRecord -ZoneName $domain -Name $NAT_HOSTNAME -RRType "A" | where {$_.RecordData.IPv4Address -EQ $NAT_IP}
$IP_RECORD  = Get-DnsServerResourceRecord -ZoneName $domain -Name $NAT_HOSTNAME -RRType "A" | where {$_.RecordData.IPv4Address -EQ $ip}
if($null -eq $NAT_RECORD){
    Write-Host "No NAT DNS record found"
} else {
    if($null -ne $IP_RECORD){
        # remove the DNS Record for the NAT Network
        Write-Host " remove DNS record $NAT_IP for host $NAT_HOSTNAME in zone $domain"
        Remove-DnsServerResourceRecord -ZoneName $domain -RRType "A" -Name $NAT_HOSTNAME -RecordData $NAT_IP -force
    } else {
        Write-Host "NAT DNS record not removed"
    }
}

Get-DnsServerResourceRecord -ZoneName $domain -Name $NAT_HOSTNAME

# Download BGInfo Scripts
New-Item -ItemType Directory -Force -Path "$StageFolder"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wimmatthyssen/Hyper-V-VM-Template/master/Deploy-BgInfo-WS2016-WS2019-WS2022.ps1" `
    -OutFile "$StageFolder\Deploy-BgInfo-WS2016-WS2019-WS2022.ps1"

Start-Process -FilePath "powershell" -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File $StageFolder\Deploy-BgInfo-WS2016-WS2019-WS2022.ps1"

# Windows Update
Write-Host '- Installing Windows Update ----------------------------------------'
Try {
    Install-Module -Name PSWindowsUpdate -Force
    Import-Module -Name PSWindowsUpdate -Force
    Get-WindowsUpdate -AcceptAll -AutoReboo
} Catch {
    Write-Host "Installing Windows Update `n$($Error[0].Exception.Message)"
}

Write-Host "INFO: Finish $ScriptName" (Get-Date -UFormat "%d %B %Y %T")
Write-Host "INFO: ==============================================================" 
# --- EOF ----------------------------------------------------------------------