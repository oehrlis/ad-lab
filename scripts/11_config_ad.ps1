# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: 23_config_ad.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2019.05.13
# Revision...: 
# Purpose....: Script to configure Active Directory
# Notes......: ...
# Reference..: 
# License....: Licensed under the Universal Permissive License v 1.0 as 
#              shown at http://oss.oracle.com/licenses/upl.
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ---------------------------------------------------------------------------

# processing commandline parameter
param (
    [string]$People = "People",
    [string]$Groups = "Groups",
    [string]$company = "Trivadis LAB"
)

# - Variables ---------------------------------------------------------------
$ScriptNameFull = $MyInvocation.MyCommand.Path
$ScriptName = $MyInvocation.MyCommand.Name
$ScriptPath = (Split-Path $ScriptNameFull -Parent)
$ConfigPath = (Split-Path $ScriptPath -Parent) + "\config"
# set file name for default password
$DefaultPWDFile = $ConfigPath + "\default_pwd_windows.txt"
$UserCSV = $ConfigPath + "\users_ad.csv"
# - EOF Variables -----------------------------------------------------------

# - Main --------------------------------------------------------------------
Write-Host '= Start Config AD Role =========================================='
Write-Host "- Default Values ------------------------------------------------"
Write-Host "Script Name       : $ScriptName"
Write-Host "Script fq         : $ScriptNameFull"
Write-Host "Script Path       : $ScriptPath"
Write-Host "Config Path       : $ConfigPath"
Write-Host "People OU         : $People"
Write-Host "Group OU          : $Groups"
Write-Host "Company Name      : $company"
Write-Host "Password File     : $DefaultPWDFile"
Write-Host "User Config File  : $UserCSV"

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

if ((Test-Path $DefaultPWDFile)) {
    Write-Host "Get default password from $DefaultPWDFile"
    $PlainPassword=Get-Content -Path  $DefaultPWDFile -TotalCount 1
    $PlainPassword=$PlainPassword.trim()
} else {
    Write-Error "Can not access $DefaultPWDFile"
    $PlainPassword=""
}

# - Variables ---------------------------------------------------------------
$adDomain   = Get-ADDomain
$domain     = $adDomain.DNSRoot
$domainDn   = $adDomain.DistinguishedName
$PeopleDN   = "ou=$People,$domainDn"
$UsersDN    = "cn=Users,$domainDn"
$GroupDN    = "ou=$Groups,$domainDn"
#$company    = (Get-Culture).textinfo.totitlecase($adDomain.Name)
$SecurePassword = ConvertTo-SecureString -AsPlainText $PlainPassword -Force
# - EOF Variables -----------------------------------------------------------

# - Configure Domain --------------------------------------------------------
Write-Host '- Configure active directory -------------------------------'
Write-Host "Company             : $company"
Write-Host "Domain              : $domain"
Write-Host "Base DN             : $domainDn"
Write-Host "Users DN            : $UsersDN"
Write-Host "People DN           : $PeopleDN"
Write-Host "Group DN            : $GroupDN"
Write-Host "Default Password    : $PlainPassword"

# load AD PS module
Import-Module ActiveDirectory

# # add People OU...
Write-Host 'Add organizational units for departments...'
NEW-ADOrganizationalUnit -name $People -path $domainDn
NEW-ADOrganizationalUnit -name "Senior Management" -path $PeopleDN
NEW-ADOrganizationalUnit -name "Human Resources" -path $PeopleDN
NEW-ADOrganizationalUnit -name "Information Technology" -path $PeopleDN 
NEW-ADOrganizationalUnit -name "Accounting" -path $PeopleDN
NEW-ADOrganizationalUnit -name "Research" -path $PeopleDN
NEW-ADOrganizationalUnit -name "Sales" -path $PeopleDN
NEW-ADOrganizationalUnit -name "Operations" -path $PeopleDN

#...and import users
Write-Host 'Import users from CSV ...'
Import-CSV -delimiter "," $UserCSV | foreach {
    $Path = "ou=" + $_.Department + "," + $PeopleDN
    $UserPrincipalName = $_.SamAccountName + "@" + $domain
    $eMail = $_.GivenName + "." + $_.Surname + "@" + $domain
    New-ADUser  -SamAccountName $_.SamAccountName  `
                -GivenName $_.GivenName `
                -Surname $_.Surname `
                -Name $_.Name `
                -UserPrincipalName $UserPrincipalName `
                -DisplayName $_.Name `
                -EmailAddress $eMail `
                -Title $_.Title `
                -Company "$company" `
                -Department $_.Department `
                -Path $Path `
                -AccountPassword $SecurePassword -Enabled $true
}

# Update OU and set managedBy
Write-Host 'Add managed by to organizational units...'
Set-ADOrganizationalUnit -Identity "ou=Senior Management,$PeopleDN" -ManagedBy king
Set-ADOrganizationalUnit -Identity "ou=Human Resources,$PeopleDN" -ManagedBy rider
Set-ADOrganizationalUnit -Identity "ou=Information Technology,$PeopleDN" -ManagedBy fleming
Set-ADOrganizationalUnit -Identity "ou=Accounting,$PeopleDN" -ManagedBy clark
Set-ADOrganizationalUnit -Identity "ou=Research,$PeopleDN" -ManagedBy blofeld
Set-ADOrganizationalUnit -Identity "ou=Sales,$PeopleDN" -ManagedBy moneypenny
Set-ADOrganizationalUnit -Identity "ou=Operations,$PeopleDN" -ManagedBy leitner

# create company groups
Write-Host 'Create $company groups...'
NEW-ADOrganizationalUnit -name $Groups -path $domainDn
New-ADGroup -Name "$company Users" -SamAccountName "$company Users" -GroupCategory Security -GroupScope Global -DisplayName "$company Users" -Path $GroupDN
Add-ADGroupMember -Identity "$company Users" -Members lynd,rider,tanner,gartner,fleming,bond,walters,renton,leitner,blake,dent,ward,moneypenny,scott,smith,adams,prefect,blofeld,miller,clark,king

New-ADGroup -Name "$company DB Admins" -SamAccountName "$company DB Admins" -GroupCategory Security -GroupScope Global -DisplayName "$company DB Admins" -Path $GroupDN
Add-ADGroupMember -Identity "$company DB Admins" -Members gartner,fleming

New-ADGroup -Name "$company Developers" -SamAccountName "$company Developers" -GroupCategory Security -GroupScope Global -DisplayName "$company Developers" -Path $GroupDN
Add-ADGroupMember -Identity "$company Developers" -Members scott,smith,adams,prefect,blofeld

New-ADGroup -Name "$company System Admins" -SamAccountName "$company System Admins" -GroupCategory Security -GroupScope Global -DisplayName "$company System Admins" -Path $GroupDN
Add-ADGroupMember -Identity "$company System Admins" -Members tanner,fleming

New-ADGroup -Name "$company APP Admins" -SamAccountName "$company APP Admins" -GroupCategory Security -GroupScope Global -DisplayName "$company APP Admins" -Path $GroupDN

New-ADGroup -Name "$company HR" -SamAccountName "$company HR" -GroupCategory Security -GroupScope Global -DisplayName "$company Management" -Path $GroupDN
Add-ADGroupMember -Identity "$company HR" -Members rider,lynd

New-ADGroup -Name "$company Management" -SamAccountName "$company Management" -GroupCategory Security -GroupScope Global -DisplayName "$company Management" -Path $GroupDN
Add-ADGroupMember -Identity "$company Management" -Members king,rider,fleming,clark,blofeld,moneypenny,leitner

# create service principle
Write-Host 'Create service principles...'
New-ADUser -SamAccountName "oracle" -Name "oracle" -UserPrincipalName "oracle@$domain" -DisplayName "oracle" -Path $UsersDN -AccountPassword $SecurePassword -Enabled $true 
New-ADUser -SamAccountName "cmudb" -Name "cmudb" -DisplayName "cmudb" -Description "Oracle CMU Service User" -Path $UsersDN -AccountPassword $SecurePassword -Enabled $true -PasswordNeverExpires $true
New-ADUser -SamAccountName "db12" -Name "db12.$domain" -DisplayName "db12.$domain" -UserPrincipalName "oracle\db12.$domain@$domain" -Description "Kerberos Service User for db12" -Path $UsersDN -AccountPassword $SecurePassword -Enabled $true -KerberosEncryptionType "AES128, AES256"
New-ADUser -SamAccountName "db18" -Name "db18.$domain" -DisplayName "db18.$domain" -UserPrincipalName "oracle\db18.$domain@$domain" -Description "Kerberos Service User for db18" -Path $UsersDN -AccountPassword $SecurePassword -Enabled $true -KerberosEncryptionType "AES128, AES256"
New-ADUser -SamAccountName "db19" -Name "db19.$domain" -DisplayName "db19.$domain" -UserPrincipalName "oracle\db19.$domain@$domain" -Description "Kerberos Service User for db19" -Path $UsersDN -AccountPassword $SecurePassword -Enabled $true -KerberosEncryptionType "AES128, AES256"
New-ADUser -SamAccountName "oem1" -Name "oem1.$domain" -DisplayName "oem1.$domain" -UserPrincipalName "oracle\oem1.$domain@$domain" -Description "Kerberos Service User for oem1" -Path $UsersDN -AccountPassword $SecurePassword -Enabled $true -KerberosEncryptionType "AES128, AES256"
New-ADUser -SamAccountName "oem2" -Name "oem2.$domain" -DisplayName "oem2.$domain" -UserPrincipalName "oracle\oem2.$domain@$domain" -Description "Kerberos Service User for oem2" -Path $UsersDN -AccountPassword $SecurePassword -Enabled $true -KerberosEncryptionType "AES128, AES256"

# change vagrant privileges
Add-ADGroupMember -Identity "Domain Admins" -Members vagrant
Add-ADGroupMember -Identity "Enterprise Admins" -Members vagrant

Write-Host 'Done configuring AD...'
Write-Host '= Finish part 3 ============================================'
# --- EOF --------------------------------------------------------------------