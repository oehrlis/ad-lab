# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: 25_config_ca.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.06.23
# Revision...: 
# Purpose....: Script to configure Certification Autority
# Notes......: ...
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ---------------------------------------------------------------------------

# wait until we can access the AD. this is needed to prevent errors like:
#   Unable to find a default server with Active Directory Web Services running.
while ($true) {
    try {
        Get-ADDomain | Out-Null
        break
    } catch {
        Write-Host 'Wait 15 seconds to get DNS ready...'
        Start-Sleep -Seconds 15
    }
}

# - Variables ---------------------------------------------------------------
$ScriptNameFull = $MyInvocation.MyCommand.Path
$ScriptName     = $MyInvocation.MyCommand.Name
$ScriptPath     = (Split-Path $ScriptNameFull -Parent)
$ConfigScript   = (Split-Path $MyInvocation.MyCommand.Path -Parent) + "\00_init_environment.ps1"
$adDomain       = Get-ADDomain
$domain         = $adDomain.DNSRoot
$domainDn       = $adDomain.DistinguishedName
$company        = (Get-Culture).textinfo.totitlecase($adDomain.Name)
$RootCAFile     = $ConfigPath + $domain + ".cer"

# call Config Script
if ((Test-Path $ConfigScript)) {
    Write-Host "INFO : load default values from $DefaultPWDFile"
    . $ConfigScript
} else {
    Write-Error "ERROR: cloud not load default values"
    exit 1
}
# - EOF Variables -----------------------------------------------------------

# - Configure Domain --------------------------------------------------------
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

if ((Test-Path $DefaultPWDFile)) {
    Write-Host "INFO : Get default password from $DefaultPWDFile"
    $PlainPassword=Get-Content -Path  $DefaultPWDFile -TotalCount 1
    $PlainPassword=$PlainPassword.trim()
} else {
    Write-Error "ERR  : Can not access $DefaultPWDFile"
    $PlainPassword=""
}

Write-Host 'INFO : Install Role ADCS-Cert-Authority...'
Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools

$caCommonName = "$company Enterprise Root CA"

# configure the CA DN using the default DN suffix (which is based on the
# current Windows Domain, trivadislabs.com) to:
#
#   CN=Example Enterprise Root CA,DC=trivadislabs,DC=com
#
# NB to install a EnterpriseRootCa the current user must be on the
#    Enterprise Admins group. 
Write-Host 'INFO : Configure ADCS-Cert-Authority...'
try {
    Install-AdcsCertificationAuthority `
        -CAType EnterpriseRootCa  `
        -CACommonName $caCommonName `
        -CryptoProviderName "RSA#Microsoft Software Key Storage Provider"  `
        -KeyLength 4096 `
        -HashAlgorithmName SHA256 `
        -ValidityPeriod Years `
        -ValidityPeriodUnits 5 `
        -Force
} catch {
    Write-Host 'ERR : Configure ADCS-Cert-Authority...'
    Write-Host $_.Exception.Message
}

Write-Host 'INFO : Export root CA to $RootCAFile ...'
$cmd = 'certutil -ca.cert ' + $RootCAFile
$output = cmd /c $cmd 2>&1
# print command
Write-Host $cmd
# print output off command
Write-Host $output

Write-Host "INFO: Done configuring CA -----------------------------------------" 
Write-Host "INFO: Finish $ScriptName" (Get-Date -UFormat "%d %B %Y %T")
Write-Host "INFO: -------------------------------------------------------------" 
# --- EOF --------------------------------------------------------------------