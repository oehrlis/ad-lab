# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 12_config_dns.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.08.17
# Version....: 0.2.0
# Purpose....: Script to configure DNS server
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
$adDomain     = Get-ADDomain
$domain       = $adDomain.DNSRoot
$domainDn     = $adDomain.DistinguishedName
$REALM        = $adDomain.DNSRoot.ToUpper()
$NAT_IP       = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object {$_.DefaultIPGateway -ne $null}).IPAddress | Select-Object -First 1
$NAT_HOSTNAME = hostname
# - EOF Variables --------------------------------------------------------------

# - Main -----------------------------------------------------------------------
Write-Log -Level INFO -Message "Default Values -----------------------------------------------"
Write-Log -Level INFO -Message "    Script Name   : $ScriptName"
Write-Log -Level INFO -Message "    Script fq     : $ScriptNameFull"
Write-Log -Level INFO -Message "    Script Path   : $ScriptPath"
Write-Log -Level INFO -Message "    Config Path   : $ConfigPath"
Write-Log -Level INFO -Message "    Config Script : $ConfigScript"
Write-Log -Level INFO -Message "    Password File : $DefaultPWDFile"
Write-Log -Level INFO -Message "    Host File     : $HostCSVFile"
Write-Log -Level INFO -Message "    Host          : $NAT_HOSTNAME"
Write-Log -Level INFO -Message "    Subnet        : $Subnet"
Write-Log -Level INFO -Message "    Domain        : $domain"
Write-Log -Level INFO -Message "    REALM         : $REALM"
Write-Log -Level INFO -Message "    Base DN       : $domainDn"

Import-Module DnsServer

$CharArray    = $Subnet.Split(".")
[array]::Reverse($CharArray)
$revers_subnet = $CharArray -join '.'

Write-Log -Level INFO -Message "Create reverse lookup zone for network $Subnet.0/24"
try {
    Add-DnsServerPrimaryZone -NetworkID "$Subnet.0/24" -ZoneFile "$revers_subnet.in-addr.arpa.dns"
} catch {
    Write-Log -Level WARNING -Message "Could not create reverse lookup zone: $($_.Exception.Message)"
}

Write-Log -Level INFO -Message "Process hosts from CSV ($HostCSVFile)"
try {
    $HostList = Import-Csv -Path $HostCSVFile
    foreach ($HostRecord in $HostList) {
        $HostEntry = $HostRecord.Name
        $IP        = $HostRecord.IP
        $IPv4Name  = $IP.Split(".")[3]
        $FQDN      = $HostEntry + '.' + $domain
        $Zone      = (Get-DnsServerZone | Where-Object { $_.IsReverseLookupZone -eq $true -and $_.IsAutoCreated -eq $false } | Select-Object -ExpandProperty ZoneName)

        Write-Log -Level INFO -Message "Add DNS A record for $HostEntry ($IP)"
        try {
            Add-DnsServerResourceRecordA -Name $HostEntry -ZoneName $domain -AllowUpdateAny -IPv4Address $IP -TimeToLive 01:00:00
        } catch {
            Write-Log -Level WARNING -Message "Could not add A record for ${HostEntry}: $($_.Exception.Message)"
        }

        if ($Zone) {
            Write-Log -Level INFO -Message "Add DNS PTR record for $FQDN"
            try {
                Add-DnsServerResourceRecordPtr -Name $IPv4Name -ZoneName $Zone -AllowUpdateAny -TimeToLive 01:00:00 -AgeRecord -PtrDomainName $FQDN
            } catch {
                Write-Log -Level WARNING -Message "Could not add PTR record for ${FQDN}: $($_.Exception.Message)"
            }
        }
    }
} catch {
    Write-Log -Level ERROR -Message "Failed to process hosts CSV: $_"
}

Write-Log -Level INFO -Message "Add CNAME records for ad ($NAT_HOSTNAME), oud ($CNAMEOud), db ($CNAMEDb)"
try {
    Add-DnsServerResourceRecordCName -Name "ad"  -HostNameAlias "$NAT_HOSTNAME.$domain" -ZoneName $domain
    Add-DnsServerResourceRecordCName -Name "oud" -HostNameAlias "$CNAMEOud.$domain"     -ZoneName $domain
    Add-DnsServerResourceRecordCName -Name "db"  -HostNameAlias "$CNAMEDb.$domain"      -ZoneName $domain
} catch {
    Write-Log -Level WARNING -Message "Could not add CNAME record: $($_.Exception.Message)"
}

try {
    Resolve-DnsName -Name www.trivadislabs.com -Server 8.8.8.8 | Out-Null
} catch {
    Write-Log -Level WARNING -Message "Could not resolve www.trivadislabs.com: $($_.Exception.Message)"
}

if ($domain -eq "trivadislabs.com") {
    try {
        Add-DnsServerResourceRecordA -Name "www" -ZoneName $domain -AllowUpdateAny -IPv4Address "140.238.172.60" -TimeToLive 01:00:00
    } catch {
        Write-Log -Level WARNING -Message "Could not add www A record: $($_.Exception.Message)"
    }
}

try {
    Get-DnsServerResourceRecord -ZoneName $domain -Name $NAT_HOSTNAME | Out-Null
} catch {
    Write-Log -Level WARNING -Message "Could not query DNS records for ${NAT_HOSTNAME}: $($_.Exception.Message)"
}

Write-Log -Level INFO -Message "Done configuring DNS"
Write-Log -Level INFO -Message "Finish $ScriptName $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log -Level INFO -Message "=============================================================="
# --- EOF ----------------------------------------------------------------------
