# CommonFunctions PowerShell Module

## Overview

**CommonFunctions** is a PowerShell module that contains a set of utilities and
helper functions designed to streamline script development. These functions cover
areas such as logging, configuration management, and generating secure passwords.
You can use this module across various PowerShell scripts to enhance their
functionality and maintain consistency.

## Features

The module provides the following functions:

- **New-Password:** Generates a random password with specified criteria,
  ensuring it meets common complexity requirements.
- **Write-Log:** Logs messages to the console with different verbosity levels
  (DEBUG, INFO, WARNING, ERROR) and optional timestamps.
- **Exit-Script:** Exits the script with optional error handling, allowing you
  to specify an error message, custom exit code, and script name.
- **Use-Module:** Ensures that a specified PowerShell module is installed
  and imported with a minimum version. It can automatically install the module
  if it's not available.

## Getting Started

To start using the CommonFunctions module, follow these steps:

1. Download or clone the repository to your local machine.
2. Place the `CommonFunctions.psm1` file in your PowerShell module directory.
   You can check the module path using `$env:PSModulePath`.
3. Import the module in your PowerShell script using the `Import-Module` command.
4. You can then use the functions provided by the module in your scripts.

## Functions

### New-Password

This function generates a random password with specified criteria, ensuring it
meets common complexity requirements.

```powershell
New-Password [-PasswordLength <int>]
```

- `PasswordLength` (Optional): Specifies the length of the password to be
  generated. The default length is 15 characters.

### Write-Log

This function logs messages to the console with different verbosity levels and
optional timestamps.

```powershell
Write-Log -Message <string> [-Level <LogLevel>] [-IncludeTimestamp <bool>]
```

- `Message` (Required): The log message to be written to the console.
- `Level` (Optional): The log level of the message. Possible values are DEBUG,
  INFO, WARNING, and ERROR. Default is INFO if not specified.
- `IncludeTimestamp` (Optional): Specifies whether to include a timestamp with
  the log message. Default is true.

### Exit-Script

This function exits the script with optional error handling, allowing you to$
specify an error message, custom exit code, and script name.

```powershell
Exit-Script [-ErrorMessage <string>] [-ExitCode <int>] [-ScriptName <string>]
[-IncludeTimestamp <bool>]
```

- `ErrorMessage` (Optional): Specifies the error message to log if an error
  occurs. If provided, the function will log this message as an error and exit
  with an exit code of 1.
- `ExitCode` (Optional): Specifies a custom exit code to use when exiting the
  script. The default exit code is 0.
- `ScriptName` (Optional): Specifies the name of the script. By default, it is
  obtained from the name of the script file.
- `IncludeTimestamp` (Optional): Indicates whether to include a timestamp in
  the log message. Default is true.

### Use-Module

This function ensures that a specified PowerShell module is installed and
imported with a minimum version.

```powershell
Use-Module -ModuleName <string> -ModuleVersion <string>
```

- `ModuleName` (Required): Specifies the name of the module to ensure is installed
  and imported.
- `ModuleVersion` (Required): Specifies the minimum version of the module required
  for installation and import.

### Set-LoggingLevel

This function sets the logging level for the module.

```powershell
Set-LoggingLevel -NewLevel <LogLevel>
```

- `NewLevel` (Required): Specifies the new logging level to be set. Valid values
  are DEBUG, INFO, WARNING, and ERROR.

### Get-LoggingLevel

This function gets the logging level for the module.

```powershell
Get-LoggingLevel
```

## Examples

Here are some examples of how to use the functions provided by the CommonFunctions
module:

```powershell
# Generate a random password with default length (15 characters)
$randomPassword = New-Password

# Log an informational message with a timestamp
Write-Log -Message "This is an informational message."

# Exit the script with a custom error message and exit code
Exit-Script -ErrorMessage "An error occurred" -ExitCode 1

# Sets the logging level to DEBUG, displaying all available log messages,
# including debug information.
Set-LoggingLevel -NewLevel DEBUG
```

For more detailed usage instructions, you can use the `Get-Help` command followed
by the function name. For example:

```powershell
Get-Help New-Password -Detailed
```

## License

This module is distributed under the [Apache License Version 2.0](http://www.apache.org/licenses/).

## Contact

- Author: Stefan Oehrli
- Email: <scripts@oradba.ch>

For more information and updates, you can visit the [GitHub repository](https://github.com/oehrlis/ad-lab/tree/main).

Enjoy using the CommonFunctions PowerShell module!
