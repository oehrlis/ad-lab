# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: CommonFunctions.psm1
# Author.....: Stefan Oehrli (oes) scripts@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2024.01.11
# Version....: 0.1.0
# Purpose....: CommonFunctions is a PowerShell module that contains a set of
#              utilities and helper functions such as logging, configuration
#              management, and more, used across various scripts.
# Notes......: ...
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Define logging levels
enum LogLevel {
    DEBUG
    INFO
    WARNING
    ERROR
}

<#
.SYNOPSIS
    A collection of common functions for PowerShell scripting.

.DESCRIPTION
    CommonFunctions is a PowerShell module that contains a set of utilities and helper functions such as logging, configuration management, and more, used across various scripts.

.EXAMPLE
    Get-Help CommonFunctions -Detailed

.NOTES
    Author:         Stefan Oehrli
    Email:          scripts@oradba.ch
    Date:           2024.01.11
    Last Modified:  2024.01.11
    Version:        0.1.0
    License:        Apache License Version 2.0, January 2004 (http://www.apache.org/licenses/)

.LINK
    https://github.com/oehrlis/ad-lab/tree/main - OraDBA AD Lab scripts
#>

# Define the script-scoped variable for LoggingLevel
$script:LoggingLevel = [LogLevel]::INFO

# - Functions ------------------------------------------------------------------

<#
.SYNOPSIS
    Generates a random password with specified criteria.

.DESCRIPTION
    The New-Password function creates a random password of a specified length. 
    The generated password includes at least one lowercase letter, one uppercase letter, 
    one digit, and one special character (from a set of specified special characters).
    This ensures that the password meets common complexity requirements.

.PARAMETER PasswordLength
    Specifies the length of the password to be generated. The default length is 15 characters.

.EXAMPLE
    New-Password -PasswordLength 12
    Generates a 12-character long password with mixed characters including letters, digits, and special characters.

.EXAMPLE
    New-Password
    Generates a 15-character long password (default length) with mixed characters.

.NOTES
    This function uses the Get-Random cmdlet to select characters randomly from the allowed set. 
    The function will continue to generate passwords until it finds one that meets the specified complexity requirements.

#>
Function New-Password {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateRange(8, 128)]
        [int]$PasswordLength = 15
    )

    # Define character sets
    $lowercase = 'abcdefghijklmnopqrstuvwxyz'
    $uppercase = $lowercase.ToUpper()
    $digits = '0123456789'
    $specialChars = '_+-.'
    $charSet = $lowercase + $uppercase + $digits + $specialChars

    do {
        $passwordChars = Get-Random -InputObject $charSet.ToCharArray() -Count $PasswordLength
        $password = -join $passwordChars
    }
    until ($password -cmatch "(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).+$")

    return $password
}

<#
.SYNOPSIS
    Writes a log message to the console with specified verbosity and optional timestamp.

.DESCRIPTION
    The Write-Log function outputs a message to the console based on the specified log level.
    It compares the message's log level with the script's current logging level and outputs the 
    message if the level is appropriate. Supports various log levels such as DEBUG, INFO, WARNING, and ERROR.
    The function can optionally include a timestamp with each log message.

.PARAMETER Message
    The log message to be written to the console.

.PARAMETER Level
    The log level of the message. This determines if the message will be displayed based 
    on the script's current logging level. Possible values are DEBUG, INFO, WARNING, and ERROR.
    Default is INFO if not specified.

.PARAMETER IncludeTimestamp
    Specifies whether to include a timestamp with the log message. Default is $true.

.EXAMPLE
    Write-Log -Message "This is an informational message."
    Writes an information message to the console with a timestamp, using the default INFO log level.

.EXAMPLE
    Write-Log -Message "This is a debug message." -Level DEBUG
    Writes a debug message to the console with a timestamp.

.EXAMPLE
    Write-Log -Message "This is an informational message." -IncludeTimestamp $false
    Writes an information message to the console without a timestamp, using the default INFO log level.

.NOTES
    This function is part of the CommonFunctions module. The actual logging behavior depends on 
    the script's logging level, managed by the `$script:LoggingLevel` variable within the module.

#>#>
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [LogLevel]$Level = [LogLevel]::INFO,

        [Parameter(Mandatory=$false)]
        [bool]$IncludeTimestamp = $true
    )

    # Generate timestamp if required
    $timestamp = if ($IncludeTimestamp) { Get-Date -Format 'yyyy-MM-dd HH:mm:ss' } else { "" }

    # Check if the log level is sufficient to log the message
    if ($Level -ge $script:LoggingLevel) {
        $formattedMessage = if ($IncludeTimestamp) { "${timestamp}: $Message" } else { $Message }

        switch ($Level) {
            'DEBUG'   { Write-Host "DEBUG  : $formattedMessage" -ForegroundColor Gray }
            'INFO'    { Write-Host "INFO   : $formattedMessage" -ForegroundColor Green }
            'WARNING' { Write-Host "WARNING: $formattedMessage" -ForegroundColor Yellow }
            'ERROR'   { Write-Host "ERROR  : $formattedMessage" -ForegroundColor Red }
        }
    }
}

<#
.SYNOPSIS
    Exits the script with an optional error message and custom exit code.

.DESCRIPTION
    The Exit-Script function is used to exit a PowerShell script with optional error handling. It provides the ability to specify an error message, custom exit code, script name, and whether to include a timestamp in the log.

.PARAMETER ErrorMessage
    Specifies the error message to log if an error occurs. If provided, the function will log this message as an error and exit with an exit code of 1.

.PARAMETER ExitCode
    Specifies a custom exit code to use when exiting the script. The default exit code is 0.

.PARAMETER ScriptName
    Specifies the name of the script. By default, it is obtained from the name of the script file.

.PARAMETER IncludeTimestamp
    Indicates whether to include a timestamp in the log message. By default, a timestamp is included.

.EXAMPLE
    Exit-Script
    Exits the script with a normal exit message and the default exit code (0).

.EXAMPLE
    Exit-Script -ErrorMessage "An error occurred"
    Exits the script with an error message and an exit code of 1.

.EXAMPLE
    Exit-Script -ExitCode 42 -ScriptName "MyScript.ps1" -IncludeTimestamp:$false
    Exits the script with a custom exit code (42) and a custom script name without a timestamp in the log.

.INPUTS
    None. You cannot pipe objects to this function.

.OUTPUTS
    None. The function exits the script with the specified exit code.

#>

function Exit-Script {
    param (
        [Parameter(Mandatory=$false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory=$false)]
        [int]$ExitCode = 0,

        [Parameter(Mandatory=$false)]
        [string]$ScriptName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name),

        [Parameter(Mandatory=$false)]
        [bool]$IncludeTimestamp = $true
    )

    if ($ErrorMessage) {
        # Log the error message and exit with the specified error code
        Write-Log -Message "$ErrorMessage" -Level ERROR -IncludeTimestamp:$IncludeTimestamp
        $ExitCode = 1  # Override the exit code for errors
    } else {
        # Log a normal exit message
        $exitMessage = if ($IncludeTimestamp) { "Finish $ScriptName" } else { "Finish" }
        Write-Log -Message $exitMessage -Level INFO -IncludeTimestamp:$IncludeTimestamp
    }

    Stop-Transcript
    exit $ExitCode
}

<#
.SYNOPSIS
    Ensures that a PowerShell module is installed and imported with a specified minimum version.

.DESCRIPTION
    The Use-Module function checks if a specified PowerShell module is available and imports it with a minimum version requirement. If the module is not available, it attempts to install it from the PowerShell Gallery.

.PARAMETER ModuleName
    Specifies the name of the module to ensure is installed and imported.

.PARAMETER ModuleVersion
    Specifies the minimum version of the module required for installation and import.

.EXAMPLE
    Use-Module -ModuleName "MyModule" -ModuleVersion "1.0"
    Ensures that the "MyModule" module with a minimum version of "1.0" is installed and imported.

.INPUTS
    None. You cannot pipe objects to this function.

.OUTPUTS
    None. The function checks and ensures the module's availability.

#>

function Use-Module {
    param (
        [string]$ModuleName,
        [string]$ModuleVersion
    )

    # Check if the module is available
    $module = Get-Module -ListAvailable -Name $ModuleName | Where-Object { $_.Version -ge $ModuleVersion }
    
    if (-not $module) {
        try {
            # Attempt to install the module from the PowerShell Gallery
            Write-Log -Message  "Installing module: $ModuleName" -Level INFO
            Install-Module -Name $ModuleName -MinimumVersion $ModuleVersion -Scope CurrentUser -Force
        } catch {
            Exit-Script -ErrorMessage "Error installing module $ModuleName : $_"
        }
    }

    # Import the module
    try {
        Import-Module -Name $ModuleName -MinimumVersion $ModuleVersion
    } catch {
        Exit-Script -ErrorMessage "Error importing module $ModuleName : $_"
    }
}

<#
.SYNOPSIS
    Sets the logging level for the module.

.DESCRIPTION
    The Set-LoggingLevel function is used to change the logging level for the entire module. The logging level
    determines which log messages are displayed when using the module's logging functions such as Write-Log.
    Logging levels include DEBUG, INFO, WARNING, and ERROR, with DEBUG being the most verbose and ERROR being the
    most minimal.

.PARAMETER NewLevel
    Specifies the new logging level to be set. Valid values are DEBUG, INFO, WARNING, and ERROR.

.EXAMPLE
    Set-LoggingLevel -NewLevel INFO
    Sets the logging level to INFO, displaying information and more severe log messages.

.EXAMPLE
    Set-LoggingLevel -NewLevel DEBUG
    Sets the logging level to DEBUG, displaying all available log messages, including debug information.

.NOTES
    Changing the logging level affects the behavior of all logging functions within the module. It allows users to
    control the verbosity of log messages based on their needs.

#>
function Set-LoggingLevel {
    param (
        [LogLevel]$NewLevel
    )

    $script:LoggingLevel = $NewLevel
}

<#
.SYNOPSIS
    Retrieves the current logging level from the CommonFunctions module.

.DESCRIPTION
    The Get-LoggingLevel function is used to obtain the current logging level that is set in the CommonFunctions module. 
    This function is useful for checking which types of log messages (e.g., DEBUG, INFO, WARNING, ERROR) are currently 
    being recorded or displayed according to the module's settings.

.SYNTAX
    Get-LoggingLevel

.PARAMETER
    This function does not require any parameters.

.EXAMPLE
    PS C:\> Get-LoggingLevel
    INFO
    This example retrieves the current logging level, which in this case is 'INFO'.

.NOTES
    This function is part of the CommonFunctions PowerShell module and is intended to be used alongside other logging functions,
    such as Write-Log and Set-LoggingLevel, to manage and inspect logging behaviors in scripts.

.LINK
    Set-LoggingLevel
    Write-Log

#>
function Get-LoggingLevel {
    return $script:LoggingLevel
}

# Export the functions
Export-ModuleMember -Function Write-Log, New-Password, Exit-Script, Use-Module, Set-LoggingLevel, Get-LoggingLevel
# --- EOF ----------------------------------------------------------------------