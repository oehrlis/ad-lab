# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: CommonFunctions.psd1
# Author.....: Stefan Oehrli (oes) scripts@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2024.01.11
# Version....: 0.1.0
# Purpose....: Manifest for the 'CommonFunctions' module containing common
#              functions used across various scripts.
# Notes......: ...
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

@{
    RootModule          = 'CommonFunctions.psm1'
    ModuleVersion       = '0.1.0'
    Author              = 'Stefan Oehrli '
    CompanyName         = 'OraDBA'
    PowerShellVersion   = '5.1'
    FunctionsToExport   = @('New-Password', 'Write-Log', 'Exit-Script', 'Use-Module', 'Set-LoggingLevel', 'Get-LoggingLevel')
    VariablesToExport   = '*'
    AliasesToExport     = @()
    CmdletsToExport     = @()
    PrivateData         = @{}
}
# --- EOF ----------------------------------------------------------------------