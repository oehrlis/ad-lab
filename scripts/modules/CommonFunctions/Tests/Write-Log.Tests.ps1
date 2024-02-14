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
    It 'Writes an INFO level log message to the console' {
        # Capture the console output
        $output = Start-OutputCapture
        Write-Log -Message "Test INFO message" -Level INFO
        Stop-OutputCapture | Should -Contain "INFO   : Test INFO message"
    }

    It 'Writes a DEBUG level log message to the console' {
        # Capture the console output
        $output = Start-OutputCapture
        Write-Log -Message "Test DEBUG message" -Level DEBUG
        Stop-OutputCapture | Should -Contain "DEBUG  : Test DEBUG message"
    }

    It 'Writes a WARNING level log message to the console' {
        # Capture the console output
        $output = Start-OutputCapture
        Write-Log -Message "Test WARNING message" -Level WARNING
        Stop-OutputCapture | Should -Contain "WARNING: Test WARNING message"
    }

    It 'Writes an ERROR level log message to the console' {
        # Capture the console output
        $output = Start-OutputCapture
        Write-Log -Message "Test ERROR message" -Level ERROR
        Stop-OutputCapture | Should -Contain "ERROR  : Test ERROR message"
    }
}

# Helper functions to capture console output
function Start-OutputCapture {
    $script:outputCapture = [System.IO.MemoryStream]::new()
    $script:streamWriter = [System.IO.StreamWriter]::new($script:outputCapture)
    [System.Console]::SetOut($script:streamWriter)
}

function Stop-OutputCapture {
    $script:streamWriter.Flush()
    $script:outputCapture.Seek(0, [System.IO.SeekOrigin]::Begin)
    $reader = [System.IO.StreamReader]::new($script:outputCapture)
    $content = $reader.ReadToEnd()
    $reader.Dispose()

    [System.Console]::SetOut([System.Console]::Out)
    $script:streamWriter.Dispose()
    $script:outputCapture.Dispose()

    return $content
}
# --- EOF ----------------------------------------------------------------------