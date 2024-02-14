# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: Set-LoggingLevel.Tests.ps1
# Author.....: Stefan Oehrli (oes) scripts@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2024.01.11
# Version....: 0.1.0
# Purpose....: Simple Test Script for Set-LoggingLevel from CommonFunctions.psm1
# Notes......: make sure to install Pester
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Import the CommonFunctions module
$modulePath = Join-Path (Split-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -Parent) "CommonFunctions.psm1"
Import-Module $modulePath -Force

# Describe the behavior of the Set-LoggingLevel function
Describe 'Set-LoggingLevel Tests' {
    # Assuming LogLevel is an enum with values DEBUG, INFO, WARNING, ERROR
    # You might need to adjust these values based on the actual implementation

    It 'Sets the logging level to DEBUG' {
        Set-LoggingLevel -NewLevel DEBUG
        (Get-LoggingLevel) | Should -Be 'DEBUG'
    }

    It 'Sets the logging level to INFO' {
        Set-LoggingLevel -NewLevel INFO
        (Get-LoggingLevel) | Should -Be 'INFO'
    }

    It 'Sets the logging level to WARNING' {
        Set-LoggingLevel -NewLevel WARNING
        (Get-LoggingLevel) | Should -Be 'WARNING'
    }

    It 'Sets the logging level to ERROR' {
        Set-LoggingLevel -NewLevel ERROR
        (Get-LoggingLevel) | Should -Be 'ERROR'
    }
}
# --- EOF ----------------------------------------------------------------------