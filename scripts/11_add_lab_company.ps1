# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 11_add_lab_company.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2024.05.06
# Version....: 0.3.0
# Purpose....: Script to add LAB company to Active Directory
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
$adDomain   = Get-ADDomain
$domain     = $adDomain.DNSRoot
$domainDn   = $adDomain.DistinguishedName
$PeopleDN   = "ou=$People,$domainDn"
$UsersDN    = "cn=Users,$domainDn"
$GroupDN    = "ou=$Groups,$domainDn"
# - EOF Variables --------------------------------------------------------------

# - Main -----------------------------------------------------------------------
Write-Log -Level INFO -Message "Default Values -----------------------------------------------"
Write-Log -Level INFO -Message "    Script Name           : $ScriptName"
Write-Log -Level INFO -Message "    Script full qualified : $ScriptNameFull"
Write-Log -Level INFO -Message "    Script Path           : $ScriptPath"
Write-Log -Level INFO -Message "    Config Path           : $ConfigPath"
Write-Log -Level INFO -Message "    Config Script         : $ConfigScript"
Write-Log -Level INFO -Message "    Password File         : $DefaultPWDFile"
Write-Log -Level INFO -Message "    User Config CSV File  : $UserCSVFile"
Write-Log -Level INFO -Message "    Network Domain Name   : $domain"
Write-Log -Level INFO -Message "    BaseDN                : $domainDn"
Write-Log -Level INFO -Message "    Company               : $Company"
Write-Log -Level INFO -Message "    People DN             : $PeopleDN"
Write-Log -Level INFO -Message "    User DN               : $UsersDN"
Write-Log -Level INFO -Message "    Group DN              : $GroupDN"
Write-Log -Level INFO -Message "--------------------------------------------------------------"

# - Configure Domain -----------------------------------------------------------
Import-Module ActiveDirectory

if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$People'" -SearchBase $domainDn -ErrorAction SilentlyContinue)) {
    Write-Log -Level INFO -Message "Adding LAB company organisation"

    try {
        Write-Log -Level INFO -Message "Add organizational units for departments"
        New-ADOrganizationalUnit -Name $People              -Path $domainDn
        New-ADOrganizationalUnit -Name "Senior Management"  -Path $PeopleDN
        New-ADOrganizationalUnit -Name "Human Resources"    -Path $PeopleDN
        New-ADOrganizationalUnit -Name "Information Technology" -Path $PeopleDN
        New-ADOrganizationalUnit -Name "Accounting"         -Path $PeopleDN
        New-ADOrganizationalUnit -Name "Research"           -Path $PeopleDN
        New-ADOrganizationalUnit -Name "Sales"              -Path $PeopleDN
        New-ADOrganizationalUnit -Name "Operations"         -Path $PeopleDN
    } catch {
        Write-Log -Level ERROR -Message "Failed to create OUs: $_"
        exit 1
    }

    try {
        Write-Log -Level INFO -Message "Import users from CSV ($UserCSVFile)"
        Import-CSV -Delimiter "," $UserCSVFile | ForEach-Object {
            $Path              = "ou=" + $_.Department + "," + $PeopleDN
            $UserPrincipalName = $_.SamAccountName + "@" + $domain
            $eMail             = $_.GivenName + "." + $_.Surname + "@" + $domain
            New-ADUser -SamAccountName $_.SamAccountName `
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
    } catch {
        Write-Log -Level ERROR -Message "Failed to import users from CSV: $_"
        exit 1
    }

    try {
        Write-Log -Level INFO -Message "Add managed by to organizational units"
        Set-ADOrganizationalUnit -Identity "ou=Senior Management,$PeopleDN"      -ManagedBy king
        Set-ADOrganizationalUnit -Identity "ou=Human Resources,$PeopleDN"        -ManagedBy rider
        Set-ADOrganizationalUnit -Identity "ou=Information Technology,$PeopleDN" -ManagedBy fleming
        Set-ADOrganizationalUnit -Identity "ou=Accounting,$PeopleDN"             -ManagedBy clark
        Set-ADOrganizationalUnit -Identity "ou=Research,$PeopleDN"               -ManagedBy blofeld
        Set-ADOrganizationalUnit -Identity "ou=Sales,$PeopleDN"                  -ManagedBy moneypenny
        Set-ADOrganizationalUnit -Identity "ou=Operations,$PeopleDN"             -ManagedBy leitner
    } catch {
        Write-Log -Level ERROR -Message "Failed to set OU ManagedBy: $_"
    }

    try {
        Write-Log -Level INFO -Message "Create $Company groups"
        New-ADOrganizationalUnit -Name $Groups -Path $domainDn

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

        Add-ADPrincipalGroupMembership -Identity "$Company Users" -MemberOf "Remote Desktop Users"
    } catch {
        Write-Log -Level ERROR -Message "Failed to create groups: $_"
        exit 1
    }

    Write-Log -Level INFO -Message "Done adding LAB company organisation"
} else {
    Write-Log -Level INFO -Message "OU '$People' already exists in '$domainDn'. Skip."
}

Write-Log -Level INFO -Message "Finish $ScriptName $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log -Level INFO -Message "=============================================================="
# --- EOF ----------------------------------------------------------------------
