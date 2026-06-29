# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 27_config_cmu.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2024.06.26
# Version....: 0.1.0
# Purpose....: Script to configure Active Directory for Oracle CMU (Central
#              Management of User Accounts) and Kerberos authentication.
#              Creates ORA_VFR groups, sets AES256 encryption on Oracle service
#              accounts, grants the oracle LDAP bind account read access to
#              password attributes, and generates Kerberos keytab files for
#              DB service principals.
# Notes......: Requires RSAT-AD-Tools and the DNS server role on the DC.
#              Keytab output path: C:\vagrant_common\config\tnsadmin\
# Reference..: Oracle CMU documentation, Oracle Kerberos configuration guide
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
$adDomain        = Get-ADDomain
$domain          = $adDomain.DNSRoot
$domainDn        = $adDomain.DistinguishedName
$REALM           = $adDomain.DNSRoot.ToUpper()
$GroupDN         = "ou=$Groups,$domainDn"
$UsersDN         = "cn=Users,$domainDn"
$KeytabFolder    = "C:\vagrant_common\config\tnsadmin"

# AES256 only for Oracle service accounts (msDS-SupportedEncryptionTypes = 16)
$AES256EncType   = 16

# Oracle VFR groups required for EUS/CMU authentication
$OraVfrGroups    = @("ORA_VFR_11G", "ORA_VFR_12C")
# - EOF Variables --------------------------------------------------------------

# - Main -----------------------------------------------------------------------
Write-Log -Level INFO -Message "Default Values -----------------------------------------------"
Write-Log -Level INFO -Message "    Script Name   : $ScriptName"
Write-Log -Level INFO -Message "    Script fq     : $ScriptNameFull"
Write-Log -Level INFO -Message "    Script Path   : $ScriptPath"
Write-Log -Level INFO -Message "    Config Path   : $ConfigPath"
Write-Log -Level INFO -Message "    Host File     : $HostCSVFile"
Write-Log -Level INFO -Message "    Domain        : $domain"
Write-Log -Level INFO -Message "    REALM         : $REALM"
Write-Log -Level INFO -Message "    Base DN       : $domainDn"
Write-Log -Level INFO -Message "    Groups DN     : $GroupDN"
Write-Log -Level INFO -Message "    Users DN      : $UsersDN"
Write-Log -Level INFO -Message "    Keytab Folder : $KeytabFolder"
Write-Log -Level INFO -Message "--------------------------------------------------------------"

Import-Module ActiveDirectory

# - Step 1: ORA_VFR Groups -----------------------------------------------------
Write-Log -Level INFO -Message "Step 1: Create Oracle VFR groups (ORA_VFR_11G, ORA_VFR_12C)"
foreach ($grp in $OraVfrGroups) {
    try {
        if (-not (Get-ADGroup -Filter "Name -eq '$grp'" -ErrorAction SilentlyContinue)) {
            Write-Log -Level INFO -Message "Create group $grp in $GroupDN"
            New-ADGroup -Name $grp -SamAccountName $grp `
                -GroupCategory Security -GroupScope Global `
                -DisplayName $grp -Path $GroupDN `
                -Description "Oracle EUS/CMU verification group"
        } else {
            Write-Log -Level INFO -Message "Group $grp already exists. Skip."
        }
    } catch {
        Write-Log -Level ERROR -Message "Failed to create group ${grp}: $_"
    }
}

# - Step 2: AES256 encryption on Oracle service accounts ----------------------
Write-Log -Level INFO -Message "Step 2: Set AES256-only encryption on Oracle service accounts"

# oracle user account
try {
    if (Get-ADUser -Filter "sAMAccountName -eq 'oracle'" -ErrorAction SilentlyContinue) {
        Write-Log -Level INFO -Message "Set msDS-SupportedEncryptionTypes=AES256 on oracle"
        Set-ADUser -Identity oracle -Replace @{'msDS-SupportedEncryptionTypes' = $AES256EncType}
    } else {
        Write-Log -Level WARNING -Message "User oracle not found. Skip encryption type setting."
    }
} catch {
    Write-Log -Level ERROR -Message "Failed to set encryption type on oracle: $_"
}

# host service principal accounts from CSV
try {
    $HostList = Import-Csv -Path $HostCSVFile
    foreach ($HostRecord in $HostList) {
        $HostEntry = $HostRecord.Name
        if (Get-ADUser -Filter "sAMAccountName -eq '$HostEntry'" -ErrorAction SilentlyContinue) {
            Write-Log -Level INFO -Message "Set msDS-SupportedEncryptionTypes=AES256 on $HostEntry"
            Set-ADUser -Identity $HostEntry -Replace @{'msDS-SupportedEncryptionTypes' = $AES256EncType}
        } else {
            Write-Log -Level INFO -Message "Service principal $HostEntry not found. Skip."
        }
    }
} catch {
    Write-Log -Level ERROR -Message "Failed to set encryption types on host principals: $_"
}

# - Step 3: ACL for Oracle LDAP Bind Account -----------------------------------
# Grant oracle read access on userPassword / unicodePwd so it can perform
# LDAP bind verification as required by Oracle CMU password verifier.
Write-Log -Level INFO -Message "Step 3: Grant oracle LDAP bind read ACL on domain"
try {
    $oracleUser = Get-ADUser -Identity oracle
    $oracleSid  = New-Object System.Security.Principal.SecurityIdentifier $oracleUser.SID

    $adRoot = [ADSI]"LDAP://$domainDn"
    $acl    = $adRoot.ObjectSecurity

    # Extended right: User-Force-Change-Password is not needed; we need
    # Read-Property on the confidential attributes via DS-Replication-Get-Changes
    # and generic read on the naming context for LDAP browsing.
    $readRight  = [System.DirectoryServices.ActiveDirectoryRights]::ReadProperty -bor `
                  [System.DirectoryServices.ActiveDirectoryRights]::GenericRead
    $accessType = [System.Security.AccessControl.AccessControlType]::Allow
    $inheritance = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::All

    $ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
        $oracleSid, $readRight, $accessType, $inheritance
    )
    $acl.AddAccessRule($ace)
    $adRoot.CommitChanges()
    Write-Log -Level INFO -Message "ACL for oracle LDAP bind account set on $domainDn"
} catch {
    Write-Log -Level ERROR -Message "Failed to set LDAP bind ACL for oracle: $_"
}

# - Step 4: KtPass for Kerberos SPNs -------------------------------------------
Write-Log -Level INFO -Message "Step 4: Generate Kerberos keytab files for DB service principals"
try {
    New-Item -ItemType Directory -Force -Path $KeytabFolder | Out-Null
} catch {
    Write-Log -Level WARNING -Message "Could not create keytab folder ${KeytabFolder}: $($_.Exception.Message)"
}

try {
    $HostList = Import-Csv -Path $HostCSVFile
    foreach ($HostRecord in $HostList) {
        $HostEntry   = $HostRecord.Name
        $FQDN        = $HostEntry + '.' + $domain
        $Keytabfile  = Join-Path -Path $KeytabFolder -ChildPath ($FQDN + '.keytab')

        if ($HostEntry -match "db") {
            Write-Log -Level INFO -Message "Generate keytab for $FQDN"
            try {
                $ktpassCmd = "ktpass -princ oracle/$FQDN@$REALM -mapuser $FQDN -pass $PlainPassword -crypto AES256-SHA1 -ptype KRB5_NT_PRINCIPAL -out `"$Keytabfile`""
                Write-Log -Level INFO -Message "Running: $ktpassCmd"
                $output = cmd /c $ktpassCmd 2>&1
                Write-Log -Level INFO -Message "ktpass output: $output"
            } catch {
                Write-Log -Level ERROR -Message "ktpass failed for ${FQDN}: $_"
            }
        } else {
            Write-Log -Level INFO -Message "Skip keytab for $HostEntry (not a DB host)"
        }
    }
} catch {
    Write-Log -Level ERROR -Message "Failed to process keytab generation: $_"
}

Write-Log -Level INFO -Message "Done configuring CMU/Kerberos"
Write-Log -Level INFO -Message "Finish $ScriptName $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log -Level INFO -Message "=============================================================="
# --- EOF ----------------------------------------------------------------------
