# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: init_win2016ad_config_ad.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2019.05.13
# Revision...: 
# Purpose....: Script to reset Administrator password
# Notes......: Set-ExecutionPolicy Bypass -Scope Process -Force;
# Reference..: 
# License....: Licensed under the Universal Permissive License v 1.0 as 
#              shown at http://oss.oracle.com/licenses/upl.
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ---------------------------------------------------------------------------
Start-Transcript -Path "C:\init_win2016ad_config_ad.log"
$People = "People"
$Groups = "Groups"

# - Main --------------------------------------------------------------------
# get default password from file
$DefaultPWDFile="C:\Users\Administrator\default_pwd_win2016ad.txt"
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
$company    = (Get-Culture).textinfo.totitlecase($adDomain.Name)
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
Import-CSV -delimiter "," \\tsclient\shared\o-sec-eus\init_win2016ad_users_ad.csv | foreach {
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

New-ADGroup -Name "$company Management" -SamAccountName "$company Management" -GroupCategory Security -GroupScope Global -DisplayName "$company Management" -Path $GroupDN
Add-ADGroupMember -Identity "$company Management" -Members king,rider,fleming,clark,blofeld,moneypenny,leitner

# create service principle
Write-Host 'Create service principles...'
New-ADUser -SamAccountName "oracle" -Name "oracle" -UserPrincipalName "oracle@$domain" -DisplayName "oracle" -Path $UsersDN -AccountPassword $SecurePassword -Enabled $true
New-ADUser -SamAccountName "ol7db19" -Name "ol7db19.$domain" -DisplayName "ol7db19.$domain" -UserPrincipalName "oracle\ol7db19.$domain@$domain" -Path $UsersDN -AccountPassword $SecurePassword -Enabled $true

Write-Host 'Done configuring AD...'
# --- EOF --------------------------------------------------------------------