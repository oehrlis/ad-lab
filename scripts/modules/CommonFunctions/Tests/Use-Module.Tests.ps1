# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: Use-Module.Tests.ps1
# Author.....: Stefan Oehrli (oes) scripts@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2024.01.11
# Version....: 0.1.0
# Purpose....: Simple Test Script for Use-Module from CommonFunctions.psm1
# Notes......: make sure to install Pester
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Import the CommonFunctions module
$modulePath = Join-Path (Split-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -Parent) "CommonFunctions.psm1"
Import-Module $modulePath -Force

Describe "Use-Module Tests for PowerShellGet" {
    It "Installs and imports the module if it's not already present" {
        $testModuleName = "PowerShellGet"
        $testModuleVersion = "2.0.0" # Specify a version that you expect to be available
    
        # Check if the module is already installed
        $module = Get-Module -ListAvailable -Name $testModuleName -MinimumVersion $testModuleVersion
        
        if (-not $module) {
            # The module is not installed, let's test the installation
            Use-Module -ModuleName $testModuleName -ModuleVersion $testModuleVersion

            # Verify that the module is now installed
            $installedModule = Get-Module -ListAvailable -Name $testModuleName -MinimumVersion $testModuleVersion
            $installedModule | Should -Not -Be $null
        } else {
            # The module is already installed, just verify the import functionality
            Use-Module -ModuleName $testModuleName -ModuleVersion $testModuleVersion

            # Verify that the module is imported
            $importedModule = Get-Module -Name $testModuleName
            $importedModule | Should -Not -Be $null
        }
    }
}

# --- EOF ----------------------------------------------------------------------