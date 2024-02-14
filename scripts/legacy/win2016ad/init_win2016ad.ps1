# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: init_win2016ad.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2019.05.13
# Revision...: 
# Purpose....: Script to install Active Directory Role
# Notes......: ...
# Reference..: 
# License....: Licensed under the Universal Permissive License v 1.0 as 
#              shown at http://oss.oracle.com/licenses/upl.
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ---------------------------------------------------------------------------
# Global Variables
$PlainPassword="LAB.42schulung"
# Set the Administrator Password and activate the Domain Admin Account
net user Administrator $PlainPassword /logonpasswordchg:no /active:yes

Start-Transcript -Path "C:\stage1.txt"
$PlainPassword="LAB.42schulung"
$domain="trivadislabs.com"
$DomainMode="Win2012R2"
$ip="10.0.1.4"
$dns1="8.8.8.8"
$dns2="4.4.4.4"
$People="People"
$Groups="Groups"

# set default value for netbiosDomain if empty
$netbiosDomain = $domain.ToUpper() -replace "\.\w*$",""
# define subnet based on ip
$subnet = $ip -replace "\.\w*$", ""

# Set the Administrator Password and activate the Domain Admin Account
net user Administrator $PlainPassword /logonpasswordchg:no /active:yes

$DefaultPWDFile="C:\Users\Administrator\default_pwd_win2016ad.txt"
Write-Host "Write default password to $DefaultPWDFile"
Set-Content $DefaultPWDFile $PlainPassword

Write-Host '= Start setup part 01 ======================================'
Write-Host "Domain              : $domain"
Write-Host "Domain Mode         : $DomainMode"
Write-Host "IP                  : $ip"
Write-Host "DNS 1               : $dns1"
Write-Host "DNS 2               : $dns2"
Write-Host "Default Password    : $PlainPassword"
Write-Host '- Installing RSAT tools ------------------------------------'

Import-Module ServerManager
Add-WindowsFeature RSAT-AD-PowerShell,RSAT-AD-AdminCenter,RSAT-ADDS-Tools

Write-Host '- Relax password complexity --------------------------------'
# Disable password complexity policy
secedit /export /cfg C:\secpol.cfg
(gc C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
secedit /configure /db C:\Windows\security\local.sdb /cfg C:\secpol.cfg /areas SECURITYPOLICY
rm -force C:\secpol.cfg -confirm:$false

# Set administrator password
$computerName = $env:COMPUTERNAME
$adminUser = [ADSI] "WinNT://$computerName/Administrator,User"
$adminUser.SetPassword($PlainPassword)

$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
    
Write-Host '- Creating domain controller -------------------------------'
# Create AD Forest for Windows Server 2012 R2
Install-WindowsFeature AD-domain-services
Import-Module ADDSDeployment
Install-ADDSForest `
    -SafeModeAdministratorPassword $SecurePassword `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode $DomainMode `
    -ForestMode $DomainMode `
    -DomainName $domain `
    -DomainNetbiosName $netbiosDomain `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$true `
    -SysvolPath "C:\Windows\SYSVOL" `
    -Force:$true

Write-Host '- Configure network adapter --------------------------------'
$newDNSServers = $dns1, $dns2
$adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -And ($_.IPAddress).StartsWith($subnet) }
if ($adapters) {
    Write-Host Setting DNS
    $adapters | ForEach-Object {$_.SetDNSServerSearchOrder($newDNSServers)}
}

Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))




############


$People="People"
$Groups="Groups"

Get-ADDomain
$DefaultPWDFile="C:\Users\Administrator\default_pwd_win2016ad.txt"
# get default password from file
$DefaultPWDFile="C:\vagrant\config\default_pwd_win2016ad.txt"
if ((Test-Path $DefaultPWDFile)) {
    Write-Host "Get default password from $DefaultPWDFile"
    $PlainPassword=Get-Content -Path  $DefaultPWDFile -TotalCount 1
    $PlainPassword=$PlainPassword.trim()
} else {
    Write-Error "Can not access $DefaultPWDFile"
    $PlainPassword=""
}


$adDomain   = Get-ADDomain
$domain     = $adDomain.DNSRoot
$domainDn   = $adDomain.DistinguishedName
$PeopleDN   = "ou=$People,$domainDn"
$UsersDN    = "cn=Users,$domainDn"
$GroupDN    = "ou=$Groups,$domainDn"
$company    = (Get-Culture).textinfo.totitlecase($adDomain.Name)
$SecurePassword = ConvertTo-SecureString -AsPlainText $PlainPassword -Force

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
Import-CSV -delimiter "," C:\Users\Administrator\users_ad.csv | foreach {
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
Write-Host '= Finish part 10 ==========================================='



$adDomain   = Get-ADDomain
$domain     = $adDomain.DNSRoot
$REALM      = $adDomain.DNSRoot.ToUpper()
$domainDn   = $adDomain.DistinguishedName
$hostfile   = "C:\Users\Administrator\hosts.csv"
# - Configure Domain --------------------------------------------------------
# - Main --------------------------------------------------------------------
Write-Host '= Start setup part 11 ======================================'
Write-Host '- Configure active directory -------------------------------'
Write-Host "Domain              : $domain"
Write-Host "REALM               : $REALM"
Write-Host "Base DN             : $domainDn"
Write-Host "Host File           : $hostfile"

Write-Host 'Create reverse lookup zone...'
# create reverse lookup zone
Add-DnsServerPrimaryZone -NetworkID "10.0.1.0/24" -ReplicationScope "Forest"

# temporary remove AD server record
Remove-DnsServerResourceRecord -ZoneName $domain -RRType "A" -Name "win2016ad" -Force

#...and import hosts
Write-Host 'Process hosts from CSV ...'

$HostList = Import-Csv -Path C:\Users\Administrator\hosts.csv   
foreach ($HostRecord in $HostList)
{
    $IP         = $HostRecord.IP
    $IPv4Name   = $IP.Split(".")[3]
    $Hostname   = $HostRecord.Name
    $FQDN       = $Hostname + '.'+ $domain
    $Keytabfile = 'C:\oracle\network\' + $FQDN + '.keytab'
    $Zone       = "1.0.10.in-addr.arpa"

    Write-Host "Add DNS Resource Record A for Host $Hostname with IP $IP ..."
    Add-DnsServerResourceRecordA -Name $Hostname -ZoneName $domain -AllowUpdateAny -IPv4Address $IP -TimeToLive 01:00:00
    Write-Host "Add DNS PTR resource record for Host $Hostname for $FQDN"
    Add-DnsServerResourceRecordPtr -Name $IPv4Name -ZoneName $Zone -AllowUpdateAny -TimeToLive 01:00:00 -AgeRecord -PtrDomainName $FQDN
    if ( $Hostname -Match "db") {
        Write-Host "Generate keytab file for host $Hostname ..."
        $cmd = 'ktpass -princ oracle/' + $FQDN + '@' + $REALM + ' -mapuser ' + $FQDN + ' -pass ' + $PlainPassword + ' -crypto ALL -ptype KRB5_NT_PRINCIPAL -out ' + $Keytabfile
        $output = cmd /c $cmd 2>&1
        # print command
        Write-Host $cmd
        # print output off command
        Write-Host $output
    } else {
        Write-Host "Skip keytab file generation for host $Hostname ..."
    }
}



# add CNAME records for ad, db and oud
Add-DnsServerResourceRecordCName -Name "ad" -HostNameAlias "win2016ad.$domain" -ZoneName $domain
Add-DnsServerResourceRecordCName -Name "oud" -HostNameAlias "ol7oud12.$domain" -ZoneName $domain
Add-DnsServerResourceRecordCName -Name "db" -HostNameAlias "ol7db19.$domain" -ZoneName $domain

# get the IP Address of the NAT Network
$NAT_IP=(Get-WmiObject -Class Win32_NetworkAdapterConfiguration | where {$_.DefaultIPGateway -ne $null}).IPAddress | select-object -first 1
$NAT_HOSTNAME=hostname

# get DNS Server Records
Get-DnsServerResourceRecord -ZoneName $domain -Name $NAT_HOSTNAME

$adDomain   = Get-ADDomain
$domain     = $adDomain.DNSRoot
$domainDn   = $adDomain.DistinguishedName
$company    = (Get-Culture).textinfo.totitlecase($adDomain.Name)
$RootCAFile = "C:\oracle\network\RootCA_" + $domain + ".cer"

Write-Host '= Start setup part 12 ======================================'
Write-Host '- Configure Cert-Authority ---------------------------------'
Write-Host "Domain              : $domain"
Write-Host "Base DN             : $domainDn"
Write-Host "Company             : $company"

Write-Host 'Install Role ADCS-Cert-Authority...'
Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools

$caCommonName = "$company Enterprise Root CA"




Write-Host 'Configure ADCS-Cert-Authority...'

Install-AdcsCertificationAuthority `
    -CAType EnterpriseRootCa  `
    -CACommonName $caCommonName `
    -CryptoProviderName "RSA#Microsoft Software Key Storage Provider"  `
    -KeyLength 4096 `
    -HashAlgorithmName SHA256 `
    -ValidityPeriod Years `
    -ValidityPeriodUnits 5 `
    -Force

Write-Host 'Export root CA to $RootCAFile ...'
$cmd = 'certutil -ca.cert ' + $RootCAFile
$output = cmd /c $cmd 2>&1
# print command
Write-Host $cmd
# print output off command
Write-Host $output



Write-Host '- Installing putty, winscp and other tools -----------------'
choco install --yes --no-progress --limitoutput winscp putty putty.install mobaxterm
choco install --yes --no-progress --limitoutput totalcommander
#choco install -y wsl

# development
Write-Host '- Installing DEV tools -------------------------------------'
choco install --yes --no-progress --limitoutput git github-desktop vscode

# Google chrome
Write-Host '- Installing Google Chrome ----------------------------------'
choco install --yes --no-progress --limitoutput googlechrome

# LDAP Utilities
Write-Host '- Installing LDAP utilities --------------------------------'
choco install --yes --no-progress --limitoutput softerraldapbrowser ldapadmin ldapexplorer 

# Oracle stuff
#choco install -y oracle-sql-developer
choco install --yes --no-progress --limitoutput oracle-sql-developer  --params "'/Username:cpureport@trivadis.com /Password:tr1vad1$'"
choco install --yes --no-progress --limitoutput strawberryperl




choco install --yes --no-progress --limitoutput apache-directory-studio






# # - Configure Domain --------------------------------------------------------
# # - Main --------------------------------------------------------------------
# Write-Host '= Start setup part 11 ======================================'
# Write-Host '- Configure active directory -------------------------------'
# Write-Host "Domain              : $domain"
# Write-Host "REALM               : $REALM"
# Write-Host "Base DN             : $domainDn"
# Write-Host "Host File           : $hostfile"

# Write-Host 'Create reverse lookup zone...'
# # create reverse lookup zone
# Add-DnsServerPrimaryZone -NetworkID "10.0.1.0/24" -ReplicationScope "Forest"

# # temporary remove AD server record
# Remove-DnsServerResourceRecord -ZoneName $domain -RRType "A" -Name "win2016ad" -Force

# #...and import hosts
# Write-Host 'Process hosts from CSV ...'
# $HostList = Import-Csv -Path $hostfile   
# foreach ($HostRecord in $HostList)
# {
#     $IP         = $HostRecord.IP
#     $IPv4Name   = $IP.Split(".")[3]
#     $Hostname   = $HostRecord.Name
#     $FQDN       = $Hostname + '.'+ $domain
#     $Keytabfile = 'C:\oracle\network\' + $FQDN + '.keytab'
#     $Zone       = "1.0.10.in-addr.arpa"

#     Write-Host "Add DNS Resource Record A for Host $Hostname with IP $IP ..."
#     Add-DnsServerResourceRecordA -Name $Hostname -ZoneName $domain -AllowUpdateAny -IPv4Address $IP -TimeToLive 01:00:00
#     Write-Host "Add DNS PTR resource record for Host $Hostname for $FQDN"
#     Add-DnsServerResourceRecordPtr -Name $IPv4Name -ZoneName $Zone -AllowUpdateAny -TimeToLive 01:00:00 -AgeRecord -PtrDomainName $FQDN
#     if ( $Hostname -Match "db") {
#         Write-Host "Generate keytab file for host $Hostname ..."
#         $cmd = 'ktpass -princ oracle/' + $FQDN + '@' + $REALM + ' -mapuser ' + $FQDN + ' -pass ' + $PlainPassword + ' -crypto ALL -ptype KRB5_NT_PRINCIPAL -out ' + $Keytabfile
#         $output = cmd /c $cmd 2>&1
#         # print command
#         Write-Host $cmd
#         # print output off command
#         Write-Host $output
#     } else {
#         Write-Host "Skip keytab file generation for host $Hostname ..."
#     }
# }





# # - EOF Variables -----------------------------------------------------------
# If (!$SkipToPhaseTwo)
# {
#     # Start the logging in the C:\DomainJoin directory
#     Start-Transcript -Path "C:\stage1.txt"


#     # - Main --------------------------------------------------------------------
#     Write-Host '= Start setup stage 1 ======================================'
#     Write-Host "Domain              : $domain"
#     Write-Host "Domain Mode         : $DomainMode"
#     Write-Host "IP                  : $ip"
#     Write-Host "DNS 1               : $dns1"
#     Write-Host "DNS 2               : $dns2"
#     Write-Host "Default Password    : $PlainPassword"
#     Write-Host '- Installing RSAT tools ------------------------------------'

#     Import-Module ServerManager
#     Add-WindowsFeature RSAT-AD-PowerShell,RSAT-AD-AdminCenter,RSAT-ADDS-Tools

#     Write-Host '- Relax password complexity --------------------------------'
#     # Disable password complexity policy
#     secedit /export /cfg C:\secpol.cfg
#     (gc C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
#     secedit /configure /db C:\Windows\security\local.sdb /cfg C:\secpol.cfg /areas SECURITYPOLICY
#     rm -force C:\secpol.cfg -confirm:$false

#     # Set administrator password
#     $computerName = $env:COMPUTERNAME
#     $adminUser = [ADSI] "WinNT://$computerName/Administrator,User"
#     $adminUser.SetPassword($PlainPassword)

#     $SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
    
#     Write-Host '- Creating domain controller -------------------------------'
#     # Create AD Forest for Windows Server 2012 R2
#     Install-WindowsFeature AD-domain-services
#     Import-Module ADDSDeployment
#     Install-ADDSForest `
#         -SafeModeAdministratorPassword $SecurePassword `
#         -CreateDnsDelegation:$false `
#         -DatabasePath "C:\Windows\NTDS" `
#         -DomainMode $DomainMode `
#         -ForestMode $DomainMode `
#         -DomainName $domain `
#         -DomainNetbiosName $netbiosDomain `
#         -InstallDns:$true `
#         -LogPath "C:\Windows\NTDS" `
#         -NoRebootOnCompletion:$true `
#         -SysvolPath "C:\Windows\SYSVOL" `
#         -Force:$true

#     Write-Host '- Configure network adapter --------------------------------'
#     $newDNSServers = $dns1, $dns2
#     $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -And ($_.IPAddress).StartsWith($subnet) }
#     if ($adapters) {
#         Write-Host Setting DNS
#         $adapters | ForEach-Object {$_.SetDNSServerSearchOrder($newDNSServers)}
#     }

#     Write-Host '- Install chocolatey ---------------------------------------'
#     Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

#     #This code schedules the currently running script to restart and forward to a given checkpoint:
#     schtasks.exe /create /tn "HeadlessRestartTask" /ru SYSTEM /sc ONSTART /tr "powershell.exe -file $($MyInvocation.MyCommand.Definition) -SkipToPhaseTwo"
#     Write-Host "`"$scriptlocation`" is scheduled to run once after reboot."
#     Restart-Computer -Force
#     Write-Host '= Finish part 01 ==========================================='
# }
# # Start the logging in the C:\DomainJoin directory
# Start-Transcript -Path "C:\stage2.txt"
# Write-Output "The system has restarted, continuing..."
# #self-delete the scheduled task
# "schtasks.exe /delete /f /tn HeadlessRestartTask"

# Write-Host '= Start setup stage 2 ======================================'
# # wait until we can access the AD. this is needed to prevent errors like:
# #   Unable to find a default server with Active Directory Web Services running.
# while ($true) {
#     try {
#         Get-ADDomain | Out-Null
#         break
#     } catch {
#         Write-Host 'Wait 15 seconds to get AD Domain ready...'
#         Start-Sleep -Seconds 15
#     }
# }

# $adDomain   = Get-ADDomain
# $domain     = $adDomain.DNSRoot
# $domainDn   = $adDomain.DistinguishedName
# $PeopleDN   = "ou=$People,$domainDn"
# $UsersDN    = "cn=Users,$domainDn"
# $GroupDN    = "ou=$Groups,$domainDn"
# $company    = (Get-Culture).textinfo.totitlecase($adDomain.Name)
# $SecurePassword = ConvertTo-SecureString -AsPlainText $PlainPassword -Force
# # - Configure Domain --------------------------------------------------------
# Write-Host '- Configure active directory -------------------------------'
# Write-Host "Company             : $company"
# Write-Host "Domain              : $domain"
# Write-Host "Base DN             : $domainDn"
# Write-Host "Users DN            : $UsersDN"
# Write-Host "People DN           : $PeopleDN"
# Write-Host "Group DN            : $GroupDN"
# Write-Host "Default Password    : $PlainPassword"

# # load AD PS module
# Import-Module ActiveDirectory

# # add People OU...
# Write-Host 'Add organizational units for departments...'
# NEW-ADOrganizationalUnit -name $People -path $domainDn
# NEW-ADOrganizationalUnit -name "Senior Management" -path $PeopleDN
# NEW-ADOrganizationalUnit -name "Human Resources" -path $PeopleDN
# NEW-ADOrganizationalUnit -name "Information Technology" -path $PeopleDN 
# NEW-ADOrganizationalUnit -name "Accounting" -path $PeopleDN
# NEW-ADOrganizationalUnit -name "Research" -path $PeopleDN
# NEW-ADOrganizationalUnit -name "Sales" -path $PeopleDN
# NEW-ADOrganizationalUnit -name "Operations" -path $PeopleDN

# # --- EOF --------------------------------------------------------------------