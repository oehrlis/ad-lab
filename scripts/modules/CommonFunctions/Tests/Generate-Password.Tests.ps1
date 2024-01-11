# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: TestCommonFunctions.ps1
# Author.....: Stefan Oehrli (oes) scripts@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2024.01.11
# Version....: 0.1.0
# Purpose....: Simple Test Script for Generate-Password from CommonFunctions.psm1
# Notes......: make sure to install Pester
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Import the CommonFunctions module
Import-Module (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "CommonFunctions.psm1") -Force

# Describe the behavior of the Generate-Password function
Describe 'Generate-Password Tests' {
    It 'Generates a password of the correct length' {
        $password = Generate-Password -PasswordLength 12
        $password.Length | Should -Be 12
    }

    It 'Generates a password with required complexity (lowercase, uppercase, digit, special character)' {
        $password = Generate-Password -PasswordLength 15
        $password -cmatch "[a-z]" | Should -Be $true
        $password -cmatch "[A-Z]" | Should -Be $true
        $password -cmatch "\d" | Should -Be $true
        $password -cmatch "[_+-\.]" | Should -Be $true
    }
}
# --- EOF ----------------------------------------------------------------------