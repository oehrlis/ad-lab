# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 11_add_lab_company.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.08.17
# Revision...: 
# Purpose....: Script to add LAB company to Active Directory
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
Write-Host "      Company               : $Company"
Write-Host "      People DN             : $PeopleDN"
Write-Host "      User DN               : $UsersDN"
Write-Host "      Group DN              : $GroupDN"
Write-Host "INFO: --------------------------------------------------------------" 

# - Configure Domain --------------------------------------------------------
Import-Module ActiveDirectory           # load AD PS module

# add People OU...
Write-Host "INFO: Adding LAB company organisation ------------------------------" 
Write-Host "INFO: Add organizational units for departments" 
NEW-ADOrganizationalUnit -name $People -path $domainDn
NEW-ADOrganizationalUnit -name "Senior Management" -path $PeopleDN
NEW-ADOrganizationalUnit -name "Human Resources" -path $PeopleDN
NEW-ADOrganizationalUnit -name "Information Technology" -path $PeopleDN 
NEW-ADOrganizationalUnit -name "Accounting" -path $PeopleDN
NEW-ADOrganizationalUnit -name "Research" -path $PeopleDN
NEW-ADOrganizationalUnit -name "Sales" -path $PeopleDN
NEW-ADOrganizationalUnit -name "Operations" -path $PeopleDN

#...and import users
Write-Host "INFO: Import users from CSV" 
Import-CSV -delimiter "," $UserCSVFile | foreach {
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
                -Company "$Company" `
                -Department $_.Department `
                -Path $Path `
                -AccountPassword $SecurePassword -Enabled $true
}

# Update OU and set managedBy
Write-Host "INFO: Add managed by to organizational units" 
Set-ADOrganizationalUnit -Identity "ou=Senior Management,$PeopleDN" -ManagedBy king
Set-ADOrganizationalUnit -Identity "ou=Human Resources,$PeopleDN"   -ManagedBy rider
Set-ADOrganizationalUnit -Identity "ou=Information Technology,$PeopleDN" -ManagedBy fleming
Set-ADOrganizationalUnit -Identity "ou=Accounting,$PeopleDN"        -ManagedBy clark
Set-ADOrganizationalUnit -Identity "ou=Research,$PeopleDN"          -ManagedBy blofeld
Set-ADOrganizationalUnit -Identity "ou=Sales,$PeopleDN"             -ManagedBy moneypenny
Set-ADOrganizationalUnit -Identity "ou=Operations,$PeopleDN"        -ManagedBy leitner

# create company groups
Write-Host "INFO: Create $Company groups" 
NEW-ADOrganizationalUnit -name $Groups -path $domainDn
New-ADGroup -Name "$Company Users" -SamAccountName "$Company Users" `
    -GroupCategory Security -GroupScope Global `
    -DisplayName "$Company Users" -Path $GroupDN

Add-ADGroupMember -Identity "$Company Users" `
    -Members lynd,rider,tanner,gartner,fleming,bond,walters,renton,leitner,blake

Add-ADGroupMember -Identity "$Company Users" `
    -Members dent,ward,moneypenny,scott,smith,adams,prefect,blofeld,miller,clark,king

New-ADGroup -Name "$Company DB Admins" -SamAccountName "$Company DB Admins" `
    -GroupCategory Security -GroupScope Global `
    -DisplayName "$Company DB Admins" -Path $GroupDN

Add-ADGroupMember -Identity "$Company DB Admins" -Members gartner,fleming

New-ADGroup -Name "$Company Developers" -SamAccountName "$Company Developers" `
    -GroupCategory Security -GroupScope Global `
    -DisplayName "$Company Developers" -Path $GroupDN

Add-ADGroupMember -Identity "$Company Developers" `
    -Members scott,smith,adams,prefect,blofeld

New-ADGroup -Name "$Company System Admins" -SamAccountName "$Company System Admins" `
    -GroupCategory Security -GroupScope Global `
    -DisplayName "$Company System Admins" -Path $GroupDN

Add-ADGroupMember -Identity "$Company System Admins" -Members tanner,fleming

New-ADGroup -Name "$Company APP Admins" -SamAccountName "$Company APP Admins" `
    -GroupCategory Security -GroupScope Global `
    -DisplayName "$Company APP Admins" -Path $GroupDN

New-ADGroup -Name "$Company HR" -SamAccountName "$Company HR" `
    -GroupCategory Security -GroupScope Global `
    -DisplayName "$Company Management" -Path $GroupDN

Add-ADGroupMember -Identity "$Company HR" -Members rider,lynd

New-ADGroup -Name "$Company Management" -SamAccountName "$Company Management" `
    -GroupCategory Security -GroupScope Global `
    -DisplayName "$Company Management" -Path $GroupDN

Add-ADGroupMember -Identity "$Company Management" -Members clark,blofeld,moneypenny
Add-ADGroupMember -Identity "$Company Management" -Members king,rider,fleming,leitner
Add-ADPrincipalGroupMembership -Identity "Trivadis LAB Users" -MemberOf "Remote Desktop Users" 

Write-Host "INFO: Done adding LAB company organisation -------------------------" 
Write-Host "INFO: Finish $ScriptName $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "INFO: ==============================================================" 
# --- EOF ----------------------------------------------------------------------