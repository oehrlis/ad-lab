# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: Exit-Script.Tests.ps1
# Author.....: Stefan Oehrli (oes) scripts@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2024.01.11
# Version....: 0.1.0
# Purpose....: Simple Test Script for Exit-Script from CommonFunctions.psm1
# Notes......: make sure to install Pester
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Import the CommonFunctions module
$modulePath = Join-Path (Split-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -Parent) "CommonFunctions.psm1"
Import-Module $modulePath -Force

# Describe the behavior of the Exit-Script function
Describe 'Exit-Script Tests' {

    Mock Write-Log { }
    Mock Stop-Transcript { }
    Mock exit { }

    It 'Exits the script with an error message and an error exit code' {
        Exit-Script -ErrorMessage "An error occurred" -ExitCode 1

        # Assert that Write-Log was called with an error message
        Assert-MockCalled -CommandName Write-Log -Times 1 -ParameterFilter { $Message -eq "An error occurred" -and $Level -eq 'ERROR' }

        # Assert that exit was called with exit code 1
        Assert-MockCalled -CommandName exit -Times 1 -ParameterFilter { $ExitCode -eq 1 }
    }

    It 'Exits the script with a normal exit message and the default exit code' {
        Exit-Script

        # Assert that Write-Log was called with a normal exit message
        Assert-MockCalled -CommandName Write-Log -Times 1 -ParameterFilter { $Level -eq 'INFO' }

        # Assert that exit was called with exit code 0
        Assert-MockCalled -CommandName exit -Times 1 -ParameterFilter { $ExitCode -eq 0 }
    }
}
# --- EOF ----------------------------------------------------------------------