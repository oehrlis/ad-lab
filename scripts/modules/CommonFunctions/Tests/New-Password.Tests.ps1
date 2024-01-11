# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: New-Password.Tests.ps1
# Author.....: Stefan Oehrli (oes) scripts@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2024.01.11
# Version....: 0.1.0
# Purpose....: Simple Test Script for New-Password CommonFunctions.psm1
# Notes......: make sure to install Pester
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Import the CommonFunctions module
$modulePath = Join-Path (Split-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -Parent) "CommonFunctions.psm1"
Import-Module $modulePath -Force

# Describe the behavior of the New-Password function
Describe 'New-Password Tests' {
    It 'Generates a password of the correct length' {
        $password = New-Password -PasswordLength 12
        $password.Length | Should -Be 12
    }

    It 'Generates a password with required complexity (lowercase, uppercase, digit, special character)' {
        $password = New-Password -PasswordLength 15
        $password -cmatch "[a-z]" | Should -Be $true
        $password -cmatch "[A-Z]" | Should -Be $true
        $password -cmatch "\d" | Should -Be $true
        $password -cmatch "[_+-\.]" | Should -Be $true
    }
}
# --- EOF ----------------------------------------------------------------------