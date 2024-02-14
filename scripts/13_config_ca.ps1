# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 25_config_ca.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.08.17
# Revision...: 
# Purpose....: Script to configure Certification Autority
# Notes......: ...
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
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
$REALM          = $adDomain.DNSRoot.ToUpper()
# - EOF Variables --------------------------------------------------------------

# - Main -----------------------------------------------------------------------
Write-Host "INFO: Default Values -----------------------------------------------" 
Write-Host "      Script Name       : $ScriptName"
Write-Host "      Script fq         : $ScriptNameFull"
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

Write-Host 'INFO: Install Role ADCS-Cert-Authority...'
Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools

$caCommonName = "$company Enterprise Root CA"

# configure the CA DN using the default DN suffix (which is based on the
# current Windows Domain, trivadislabs.com) to:
#
#   CN=Example Enterprise Root CA,DC=trivadislabs,DC=com
#
# NB to install a EnterpriseRootCa the current user must be on the
#    Enterprise Admins group. 
Write-Host 'INFO: Configure ADCS-Cert-Authority...'
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

    # Remove Desktop ShortCut
    $FileName = "$env:Public\Desktop\$ScriptName.lnk"
    if (Test-Path $FileName) { Remove-Item $FileName }
} catch {
    Write-Host 'ERR : Configure ADCS-Cert-Authority...'
    Write-Host $_.Exception.Message

    Write-Host "INFO: Add shortcut for $ScriptName"
    $WScriptShell           = New-Object -ComObject WScript.Shell
    $Shortcut               = $WScriptShell.CreateShortcut("$env:Public\Desktop\$ScriptName.lnk")
    $Shortcut.TargetPath    = "powershell.exe"
    $Shortcut.Arguments     = "-ExecutionPolicy Bypass -File $ScriptNameFull"
    $Shortcut.Save()
}

Write-Host 'INFO: Export root CA to $RootCAFile ...'
$cmd = 'certutil -ca.cert ' + $RootCAFile
$output = cmd /c $cmd 2>&1
# print command
Write-Host $cmd
# print output off command
Write-Host $output

Write-Host "INFO: Done configuring CA ------------------------------------------" 
Write-Host "INFO: Finish $ScriptName" (Get-Date -UFormat "%d %B %Y %T")
Write-Host "INFO: ==============================================================" 
# --- EOF ----------------------------------------------------------------------