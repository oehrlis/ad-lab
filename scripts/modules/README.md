# Module Folder: CommonFunctions

This folder contains a PowerShell module named *CommonFunctions*. This module
includes a set of utilities and helper functions that can be used across various
PowerShell scripts.

## Module Contents

- **CommonFunctions.psd1:** This file is the module manifest for *CommonFunctions*.
  It contains metadata and module-specific information.
- **CommonFunctions.psm1:** This file is the main module file for *CommonFunctions*.
  It contains the actual PowerShell functions and logic that can be used in your
  scripts.
- **README.md:** This file provides documentation and information about the
  *CommonFunctions* module, its purpose, functions, and usage.

## Module Information

- **Author:** Stefan Oehrli (oes)
- **Email:** <scripts@oradba.ch>
- **Version:** 0.1.0
- **License:** Apache License Version 2.0 (January 2004)

## How to Use the Module

To use the "CommonFunctions" module in your PowerShell scripts, follow these steps:

1. Determine the path of the current script. You can use the following code to
   get the script's path:

    ```powershell
    $ScriptPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
    ```

2. Construct the path to the module by appending the module folder name to the
   script's path:

    ```powershell
    $ModulePath = Join-Path -Path $ScriptPath -ChildPath "Modules\CommonFunctions"
    ```

3. Import the module using the `Import-Module` cmdlet:

    ```powershell
    Import-Module $ModulePath
    ```

4. You can now use the functions provided by the module in your scripts. For
   example:

    ```powershell
    # Example: Write a message with a timestamp using a function from the module
    Write-Log -Message "This is a debug message." -Level INFO
    ```

## Functions Provided by the Module

- `New-Password`:       Generates a random password with specified criteria.
- `Write-Log`:          Writes log messages to the console with specified verbosity
                        and
                        optional timestamp.
- `Exit-Script`:        Exits the script with optional error message and custom
                        exit code.
- `Use-Module`:         Ensures that a PowerShell module is installed and imported
                        with a specified minimum version.
- `Set-LoggingLevel`:   Sets the logging level for the module.
- `Get-LoggingLevel`:   Retrieves the current logging level from the
                        CommonFunctions module.

Refer to the module's documentation and comments in the source code for more
details on each function and how to use them.

## Module Repository

For more information and updates, you can visit the [OraDBA AD Lab GitHub repository](https://github.com/oehrlis/ad-lab/tree/main).
