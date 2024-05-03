# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: Write-Log.Tests.ps1
# Author.....: Stefan Oehrli (oes) scripts@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2024.01.11
# Version....: 0.1.0
# Purpose....: Simple Test Script for Write-Log from CommonFunctions.psm1
# Notes......: make sure to install Pester
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Import the CommonFunctions module
$modulePath = Join-Path (Split-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -Parent) "CommonFunctions.psm1"
Import-Module $modulePath -Force

# Describe the behavior of the Write-Log function
Describe 'Write-Log Tests' {
    It 'Writes an INFO level log message' {
        # Set logging level to INFO (if applicable)
        Set-LoggingLevel -NewLevel INFO

        # Capture the output from Write-Log
        $output = Write-Log -Message "Test INFO message" -Level INFO

        # Assert that the output contains the expected message
        $output | Should -Contain "INFO : Test INFO message"
    }

    It 'Writes a DEBUG level log message' {
        # Set logging level to DEBUG (if applicable)
        Set-LoggingLevel -NewLevel DEBUG

        # Capture the output from Write-Log
        $output = Write-Log -Message "Test DEBUG message" -Level DEBUG

        # Assert that the output contains the expected message
        $output | Should -Contain "DEBUG : Test DEBUG message"
    }

    # Add similar tests for WARNING and ERROR levels...
}

# --- EOF ----------------------------------------------------------------------