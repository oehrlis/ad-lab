# AD Lab
<!-- markdownlint-configure-file { "MD013": { "tables": false } } -->
Active Directory lab environment for Oracle CMU (Central Management of User
Accounts) and Kerberos authentication testing on OCI Windows Server (x86).

## Overview

The scripts in this repository automate the full setup of a Windows Server
Active Directory domain controller, including:

- AD domain installation and DNS configuration
- Lab company structure (OUs, users, groups)
- Oracle CMU configuration (ORA_VFR groups, AES256 encryption, LDAP ACL)
- Kerberos service principal and keytab generation
- Oracle Instant Client installation
- CA configuration and Windows updates

## Prerequisites

- Windows Server 2019/2022 (OCI or on-prem)
- PowerShell 5.1 or later
- Internet access for Chocolatey, tools, and Oracle Instant Client downloads
- Stage folder `C:\stage\ad-lab` with this repository checked out

## Quick Start

The recommended deployment method uses `DeployADRole.ps1`, which orchestrates
the full multi-step setup including automatic reboots.

```powershell
cd C:\stage\ad-lab\scripts

# 1. Review and adjust configuration
notepad ..\config\default_configuration.txt

# 2. Run with automatic reboots (recommended)
.\DeployADRole.ps1 -Reboot -Force

# 3. Check current progress at any time
.\DeployADRole.ps1 -ListStatus

# 4. Reset progress marker if needed
.\DeployADRole.ps1 -CleanStatus
```

`DeployADRole.ps1` runs three steps across reboots:

| Step   | Scripts                                                                                                                                                      | Purpose                  |
|--------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------|
| Step 1 | `01_install_ad_role.ps1`, `22_install_chocolatey.ps1`                                                                                                        | Install AD role + reboot |
| Step 2 | `11_add_lab_company.ps1`, `11_add_service_principles.ps1`, `12_config_dns.ps1`, `26_install_tools.ps1`, `28_config_misc.ps1`, `28_install_oracle_client.ps1` | Configure AD + tools     |
| Step 3 | `13_config_ca.ps1`, `19_sum_up_ad.ps1`                                                                                                                       | CA + summary + updates   |

Run `27_config_cmu.ps1` separately after Step 2 to complete Oracle CMU and
Kerberos configuration:

```powershell
.\27_config_cmu.ps1
```

## Configuration

All configuration is managed via two files:

| File                               | Purpose                                    |
|------------------------------------|--------------------------------------------|
| `config/default_configuration.txt` | Key-value pairs overriding script defaults |
| `config/default_pwd_windows.txt`   | Default password (generated if empty)      |
| `config/hosts.csv`                 | IP/hostname list for DNS and Kerberos SPNs |
| `config/users_ad.csv`              | User list for AD import                    |

Key parameters in `default_configuration.txt`:

```ini
NetworkDomainName       = trivadislabs.com
Company                 = Trivadis LAB
OracleBase              = C:\u00\app\oracle
InstantClientVersion    = 19.11.0.0.0
InstantClientBuild      = 1911000
CNAMEOud                = oud12
CNAMEDb                 = db19
```

See [config/README.md](config/README.md) for the full parameter reference.

## Repository Structure

```text
ad-lab/
├── config/                         # Configuration files
│   ├── default_configuration.txt   # Main configuration
│   ├── default_pwd_windows.txt     # Default password
│   ├── hosts.csv                   # Host/IP list for DNS and Kerberos
│   └── users_ad.csv                # User list for AD import
└── scripts/                        # Setup scripts
    ├── modules/
    │   └── CommonFunctions/        # Shared PowerShell module
    ├── DeployADRole.ps1            # Main orchestration script
    ├── 00_init_environment.ps1     # Configuration loader (dot-sourced)
    ├── 01_install_ad_role.ps1      # AD role installation
    ├── 11_add_lab_company.ps1      # OUs, users, groups
    ├── 11_add_service_principles.ps1 # Service principals + Kerberos accounts
    ├── 12_config_dns.ps1           # DNS zones, A/PTR/CNAME records
    ├── 13_config_ca.ps1            # Certificate Authority
    ├── 19_sum_up_ad.ps1            # AD summary + Windows updates
    ├── 22_install_chocolatey.ps1   # Chocolatey package manager
    ├── 26_install_tools.ps1        # Tools via Chocolatey
    ├── 27_config_cmu.ps1           # Oracle CMU + Kerberos keytabs
    ├── 28_config_misc.ps1          # NAT DNS record cleanup + BGInfo
    ├── 28_install_oracle_client.ps1 # Oracle Instant Client
    └── 40_reset_ad_users.ps1       # Reset all user passwords
```

## Day-2 Operations

Reset all user passwords and refresh ORA_VFR group membership:

```powershell
.\40_reset_ad_users.ps1
```

## License

This project is licensed under the Apache License 2.0 - see
[LICENSE](LICENSE) for details.
