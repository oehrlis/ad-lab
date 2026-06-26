# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 28_install_oracle_client.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.08.17
# Version....: 0.2.0
# Purpose....: Script to install the Oracle Instant Client
# Notes......: Version, build number and suffix are read from
#              default_configuration.txt via 00_init_environment.ps1.
#              Change InstantClientVersion, InstantClientBuild, and
#              InstantClientSuffix there to install a different release.
# Reference..:
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

Set-StrictMode -Version Latest

# - Default Values -------------------------------------------------------------
$ScriptName   = $MyInvocation.MyCommand.Name
$Hostname     = (Hostname)
$ScriptPath   = Split-Path $MyInvocation.MyCommand.Path -Parent
$ConfigScript = Join-Path -Path $ScriptPath -ChildPath "00_init_environment.ps1"
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
# - EOF Initialisation ---------------------------------------------------------

# - Variables ------------------------------------------------------------------
$StageFolder      = "C:\stage"
$vParts           = $InstantClientVersion.Split(".")
$InstantClientDir = "instantclient_$($vParts[0])_$($vParts[1])"
$IcBaseUrl        = "https://download.oracle.com/otn_software/nt/instantclient/$InstantClientBuild"
$IcFileSuffix     = "windows.x64-$InstantClientVersion$InstantClientSuffix"
$IcPackages       = @("basic", "sqlplus", "tools", "odbc", "sdk", "jdbc")
# - EOF Variables --------------------------------------------------------------

# - Main -----------------------------------------------------------------------
Write-Log -Level INFO -Message "Default Values -----------------------------------------------"
Write-Log -Level INFO -Message "    Script Name         : $ScriptName"
Write-Log -Level INFO -Message "    Oracle Base         : $OracleBase"
Write-Log -Level INFO -Message "    IC Version          : $InstantClientVersion"
Write-Log -Level INFO -Message "    IC Build            : $InstantClientBuild"
Write-Log -Level INFO -Message "    IC Suffix           : $InstantClientSuffix"
Write-Log -Level INFO -Message "    IC Directory        : $InstantClientDir"
Write-Log -Level INFO -Message "    Stage Folder        : $StageFolder"
Write-Log -Level INFO -Message "--------------------------------------------------------------"

Write-Log -Level INFO -Message "Download Oracle Instant Client $InstantClientVersion"
try {
    New-Item -ItemType Directory -Force -Path $StageFolder | Out-Null
    foreach ($pkg in $IcPackages) {
        $fileName = "instantclient-$pkg-$IcFileSuffix.zip"
        $outFile  = Join-Path -Path $StageFolder -ChildPath $fileName
        $uri      = "$IcBaseUrl/$fileName"
        Write-Log -Level INFO -Message "Download $fileName"
        Invoke-WebRequest -Uri $uri -OutFile $outFile
    }
} catch {
    Write-Log -Level ERROR -Message "Failed to download Instant Client package: $_"
    exit 1
}

Write-Log -Level INFO -Message "Install Oracle Instant Client $InstantClientVersion to $OracleBase"
try {
    New-Item -ItemType Directory -Force -Path "$OracleBase\product"       | Out-Null
    New-Item -ItemType Directory -Force -Path "$OracleBase\network\admin" | Out-Null
    foreach ($pkg in $IcPackages) {
        $fileName = "instantclient-$pkg-$IcFileSuffix.zip"
        $zipPath  = Join-Path -Path $StageFolder -ChildPath $fileName
        Write-Log -Level INFO -Message "Extract $fileName"
        Expand-Archive -LiteralPath $zipPath -DestinationPath "$OracleBase\product" -Force
    }
} catch {
    Write-Log -Level ERROR -Message "Failed to install Instant Client: $_"
    exit 1
}

Write-Log -Level INFO -Message "Configure Oracle Instant Client environment"
try {
    $tnsAdmin = "$OracleBase\network\admin"
    New-Item -ItemType Directory -Force -Path $tnsAdmin | Out-Null
    $sqlnetOra  = Join-Path -Path $tnsAdmin -ChildPath "sqlnet.ora"
    $tnsnamesOra = Join-Path -Path $tnsAdmin -ChildPath "tnsnames.ora"
    if (-not (Test-Path $sqlnetOra))   { New-Item -Name "sqlnet.ora"   -Path $tnsAdmin -ItemType File | Out-Null }
    if (-not (Test-Path $tnsnamesOra)) { New-Item -Name "tnsnames.ora" -Path $tnsAdmin -ItemType File | Out-Null }

    $icPath    = "$OracleBase\product\$InstantClientDir"
    $machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    if ($machinePath -notlike "*$icPath*") {
        [System.Environment]::SetEnvironmentVariable('Path', "$machinePath;$icPath", 'Machine')
        Write-Log -Level INFO -Message "Added $icPath to system PATH"
    } else {
        Write-Log -Level INFO -Message "PATH already contains $icPath. Skip."
    }
    [System.Environment]::SetEnvironmentVariable('TNS_ADMIN', $tnsAdmin, [System.EnvironmentVariableTarget]::Machine)
    Write-Log -Level INFO -Message "TNS_ADMIN set to $tnsAdmin"
} catch {
    Write-Log -Level ERROR -Message "Failed to configure Instant Client environment: $_"
    exit 1
}

Write-Log -Level INFO -Message "Done installing Oracle Instant Client $InstantClientVersion"
Write-Log -Level INFO -Message "Finish $ScriptName $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log -Level INFO -Message "=============================================================="
# --- EOF ----------------------------------------------------------------------
