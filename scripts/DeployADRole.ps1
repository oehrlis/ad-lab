# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: DeployADRole.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2023.12.04
# Revision...: 
# Purpose....: Script to deploy the AD role an Windows Server
# Notes......: ...
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http:\\www.apache.org\licenses\
# ------------------------------------------------------------------------------
# Missing stuff
# - check if AD already deployed
# - documentation
# - error handling

<#
.SYNOPSIS
    Automates a series of steps for deploying AD roles with optional automatic reboot handling.

.DESCRIPTION
    DeployADRole.ps1 is designed to automate the deployment of AD roles, supporting both manual and automatic reboot processes. The script offers flexibility through various parameters that control its operation, including automatic reboots, status checks, and configuration through an external file.

.PARAMETER Reboot
    Specifies that the script should automatically handle system reboots between steps. If used without the -Force parameter, it prompts for user confirmation before proceeding.

.PARAMETER Force
    Forces the script to proceed without interactive prompts. When used with -Reboot, it bypasses the confirmation dialog and directly proceeds with the reboots.

.PARAMETER ListStatus
    Displays the current status of the script without performing any actions. Useful for checking the progress or state of the script.

.PARAMETER CleanStatus
    Clears any saved script status, effectively resetting the script's progress. Useful for starting the script execution from the beginning.

.PARAMETER Help
    Displays help information about the script's usage and parameters. Equivalent to running Get-Help for this script.

.PARAMETER ConfigFile
    Specifies the path to a configuration file containing key-value pairs for script settings. Allows for external configuration of the script.

.EXAMPLE
    .\DeployADRole.ps1 -Reboot
    Runs the script with automatic reboots, prompting the user for confirmation before proceeding.

.EXAMPLE
    .\DeployADRole.ps1 -Reboot -Force
    Runs the script with automatic reboots without any user confirmation.

.EXAMPLE
    .\DeployADRole.ps1 -ListStatus
    Displays the current status of the script execution.

.NOTES
    Ensure the script has the necessary permissions to execute and manage system reboots. Test the script in a controlled environment before deploying in a production setting.

.LINK
    https://github.com/oehrlis/ad-lab/tree/main

#>

# - Parameters -----------------------------------------------------------------
param (
    [switch]$Reboot,
    [switch]$Force,
    [switch]$ListStatus,
    [switch]$CleanStatus,
    [switch]$Help,
    [string]$ConfigFile
)
# - EOF Parameters -------------------------------------------------------------

# - Default Values -------------------------------------------------------------
# String containing a list of file names, separated by commas
$defaultScriptsStep1String  = "01_install_ad_role.ps1, 22_install_chocolatey.ps1"
$defaultScriptsStep2String  = "11_add_lab_company.ps1, 11_add_service_principles.ps1, 12_config_dns.ps1, 26_install_tools.ps1, 28_config_misc.ps1, 28_install_oracle_client.ps1"
$defaultScriptsStep3String  = "13_config_ca.ps1, 19_sum_up_ad.ps1"
$defaultLogFolder           = "C:\Windows\Temp"
$defaultMarkerPath          = "C:\Windows\Temp\scriptProgress.marker"
# - EOF Default Values ---------------------------------------------------------
# - Variables ------------------------------------------------------------------
# Define default values
$MyScriptName               = $MyInvocation.MyCommand.Name
$MyScriptNameFull           = $MyInvocation.MyCommand.Path
# Get the current script path
$MyScriptPath               = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Get the base name of the current script (without the extension)
$MyScriptBaseName           = [System.IO.Path]::GetFileNameWithoutExtension($MyScriptName)

# Create the marker file name by appending ".marker" to the script base name
$markerFileName             = "$MyScriptBaseName.marker"
# Combine the script path with the marker file name to create the full marker path
$markerPath                 = Join-Path -Path $MyScriptPath -ChildPath $markerFileName
# Create a log file name by appending ".log" to the script base name
$logFileName                = "$MyScriptBaseName.log"
$taskName                   = "$MyScriptBaseName.Task"
# - EOF Variables --------------------------------------------------------------

# - Functions ------------------------------------------------------------------
# Function to list current status
function ListStatus {
    Write-HostWithTimestamp "INFO: Run List Status"
    # check marker file
    if (Test-Path -Path $markerPath) {
        $progress = Get-Content -Path $markerPath
        Write-HostWithTimestamp "INFO: Marker Path: $markerPath"
        Write-HostWithTimestamp "INFO: Current Status: Step is at '$progress'"
    } else {
        Write-HostWithTimestamp "INFO: No progress marker found. Script has not been started or is at Step1."
    }

    # Check if the scheduled task exists
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Write-HostWithTimestamp "INFO: Scheduled task '$taskName' does exists."
    } else {
        Write-HostWithTimestamp "INFO: Scheduled task '$taskName' does not exists."
    }
}

# Function to clean the current status i.e. remove the marker file and the scheduler task
function CleanStatus {
    Write-HostWithTimestamp "INFO: Run Clean Status"
    Remove-StartupTask
    if (Test-Path $markerPath) {
        Remove-Item $markerPath # Clean up the marker file
    } 
}

# Function to add the script to Task Scheduler for automated reboots
function Set-StartupTask {
    $executeCommand = "Powershell.exe"
    $arguments = "-File `"$PSCommandPath`" -Reboot -Force"
    
    # Create the scheduled task action
    $action  = New-ScheduledTaskAction -Execute $executeCommand -Argument $arguments
    $trigger = New-ScheduledTaskTrigger -AtStartup -RandomDelay (New-TimeSpan -Minutes 1)
    # Check if the scheduled task exists
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Write-HostWithTimestamp "INFO: Scheduled task '$taskName' allready exists."
    } else {
        # Register the scheduled task to run as SYSTEM, which allows it to run whether the user is logged in or not, and with highest privileges
        Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Description "Run $MyScriptBaseName at startup" -User "SYSTEM" -RunLevel Highest
        Write-HostWithTimestamp "INFO: Scheduled task '$taskName' created."
    }
}

# Function to remove the script from Task Scheduler
function Remove-StartupTask {
    # Check if the scheduled task exists
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        # Unregister (delete) the task
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-HostWithTimestamp "INFO: Scheduled task '$taskName' has been removed."
    } else {
        Write-HostWithTimestamp "INFO: No scheduled task '$taskName' found to be removed."
    }
}

function Step1 {
    # Your code for Step 1
    Write-HostWithTimestamp "INFO: Start Step 1"

    # Split the string into an array of file names
    $ScriptsStep1Array = $ScriptsStep1String -split ',\s*'

    # Loop through each file name
    foreach ($ScriptName in $ScriptsStep1Array) {
        # Your code to process each file name
        Write-HostWithTimestamp "INFO: Processing file: $ScriptName"
        # Full path to the other script
        $ScriptPath = Join-Path -Path $MyScriptPath -ChildPath $ScriptName

        try {
            # Execute the script configuration script
            Write-HostWithTimestamp "INFO: Executing script $ScriptPath"
            & $ScriptPath -ErrorAction Stop
        } catch {
            # Error handling for script execution
            Write-HostWithTimestamp "ERR : An error occurred while executing $ScriptPath - $_"
            Remove-StartupTask  # Remove startup task on error
            break  # to stop processing further scripts
        }
    }
    "Step1 completed" | Out-File -FilePath $markerPath
    if ($Reboot) {
        Write-HostWithTimestamp "INFO: Finish Step 1, automatically reboot system"
        Restart-Computer -Force
    } else {
        Write-HostWithTimestamp "INFO: Finish Step 1, please manually reboot system"
    }
}

function Step2 {
    # Your code for Step 2
    Write-HostWithTimestamp "INFO: Start Step 2"
    # Split the string into an array of file names
    $ScriptsStep2Array = $ScriptsStep2String -split ',\s*'

    # Loop through each file name
    foreach ($ScriptName in $ScriptsStep2Array) {
        # Your code to process each file name
        Write-HostWithTimestamp "INFO: Processing file: $ScriptName"
        # Full path to the other script
        $ScriptPath = Join-Path -Path $MyScriptPath -ChildPath $ScriptName

        try {
            # Execute the script configuration script
            Write-HostWithTimestamp "INFO: Executing script $ScriptPath"
            & $ScriptPath -ErrorAction Stop
        } catch {
            # Error handling for script execution
            Write-HostWithTimestamp "ERR : An error occurred while executing $ScriptPath - $_"
            Remove-StartupTask  # Remove startup task on error
            break  # to stop processing further scripts
        }
    }
    "Step2 completed" | Out-File -FilePath $markerPath
    if ($Reboot) {
        Write-HostWithTimestamp "INFO: Finish Step 2, automatically reboot system"
        Restart-Computer -Force
    } else {
        Write-HostWithTimestamp "INFO: Finish Step 2, please manually reboot system"
    }
}

function Step3 {
    # Your code for Step 3
    Write-HostWithTimestamp "INFO: Start Step 3"
    # Split the string into an array of file names
    $ScriptsStep3Array = $ScriptsStep3String -split ',\s*'

    # Loop through each file name
    foreach ($ScriptName in $ScriptsStep3Array) {
        # Your code to process each file name
        Write-HostWithTimestamp "INFO: Processing file: $ScriptName"
        # Full path to the other script
        $ScriptPath = Join-Path -Path $MyScriptPath -ChildPath $ScriptName

        try {
            # Execute the script configuration script
            Write-HostWithTimestamp "INFO: Executing script $ScriptPath"
            & $ScriptPath -ErrorAction Stop
        } catch {
            # Error handling for script execution
            Write-HostWithTimestamp "ERR : An error occurred while executing $ScriptPath - $_"
            Remove-StartupTask  # Remove startup task on error
            break  # to stop processing further scripts
        }
    }
    CleanStatus # Clean up Status
    if ($Reboot) {
        Write-HostWithTimestamp "INFO: Finish Step 3, automatically reboot system"
        Restart-Computer -Force
    } else {
        Write-HostWithTimestamp "INFO: Finish Step 3, please manually reboot system"
    }
}

function Get-ConfigValueOrDefault {
    param (
        [string]$Key,
        [string]$DefaultValue
    )

    if ($config.ContainsKey($Key)) {
        return $config[$Key]
    } else {
        return $DefaultValue
    }
}

function ExitWithStatus {
    # Stop logging at the end of the script
    Write-HostWithTimestamp "INFO: = Finish $MyScriptBaseName ==========================================="
    Stop-Transcript
    exit
}

function Write-HostWithTimestamp {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host "${timestamp}: $Message"
}
# - End of Functions -----------------------------------------------------------

# - Main -----------------------------------------------------------------------
# Read configuration from file if provided
$config = @{}
if ($ConfigFile -and (Test-Path -Path $ConfigFile)) {
    Get-Content -Path $ConfigFile | ForEach-Object {
        $key, $value = $_ -split '=', 2
        $config[$key] = $value
    }
}

# Load the values from the configuration file
# Set the values
$ScriptsStep1String = Get-ConfigValueOrDefault -Key "ScriptsStep1String" -DefaultValue $defaultScriptsStep1String
$ScriptsStep2String = Get-ConfigValueOrDefault -Key "ScriptsStep2String" -DefaultValue $defaultScriptsStep2String
$ScriptsStep3String = Get-ConfigValueOrDefault -Key "ScriptsStep3String" -DefaultValue $defaultScriptsStep3String

# Determine the log folder based on priority
$LogFolder = $null
if ($config.LogFolder -and (Test-Path -Path $config.LogFolder -PathType Container)) {
    # Priority 1: Log folder from config file
    $LogFolder = $config.LogFolder
} elseif (Test-Path -Path $MyScriptPath -PathType Container) {
    # Priority 2: Current script folder
    $LogFolder = $MyScriptPath
} else {
    # Priority 3: Default Windows folder
    $LogFolder = $defaultLogFolder
}

# Combine the log folder path with the new log file name
$logFile = Join-Path -Path $LogFolder -ChildPath $logFileName

# Start logging
Start-Transcript -Path $logFile -Append

Write-HostWithTimestamp "INFO: = Start $MyScriptBaseName ============================================"

# List current status and exit if -ListStatus is specified
if ($ListStatus) {
    ListStatus
    ExitWithStatus
}

# Clean current status and exit if -CleanStatus is specified
if ($CleanStatus) {
    CleanStatus
    ExitWithStatus
}

# Display help information if -Help parameter is used
if ($Help) {
    Get-Help .\DeployADRole.ps1 -Full
    ExitWithStatus
}

# Set up the script to run at startup if in automated mode
if ($Reboot -and -not $Force) {
    $confirmation = $Host.UI.PromptForChoice("Confirmation", "Do you want to proceed with automatic reboots?", @("&Yes", "&No"), 1)
    if ($confirmation -ne 0) {
        Write-HostWithTimestamp "INFO: Operation aborted by the user."
        ExitWithStatus
    }
    Set-StartupTask
} elseif ($Reboot -and $Force) {
    Write-HostWithTimestamp "INFO: Started with forced reboot"
    Set-StartupTask
} else {
    Write-HostWithTimestamp "INFO: Started with manual reboot. Please reboot after each step..."
}

# Check if the marker file exists and run the appropriate step
if (Test-Path $markerPath) {
    $progress = Get-Content $markerPath
    switch ($progress) {
        "Step1 completed" { Step2 }
        "Step2 completed" { Step3 }
    }
} else {
    Step1
}

ExitWithStatus
# --- EOF ----------------------------------------------------------------------