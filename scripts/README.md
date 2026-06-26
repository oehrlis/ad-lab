# AD Setup Scripts

PowerShell scripts for automated Active Directory lab setup. All scripts use
the `CommonFunctions` module for logging (`Write-Log`) and AD readiness checks
(`Wait-ADReady`). Configuration is loaded from `00_init_environment.ps1` which
reads `../config/default_configuration.txt`.

## Orchestration

| Script | Purpose |
|--------|---------|
| [DeployADRole.ps1](DeployADRole.ps1) | Main orchestration script — runs Step 1-3 across reboots, manages a startup task for automatic continuation |
| [51_config_ad-lab_part1.ps1](51_config_ad-lab_part1.ps1) | Legacy wrapper: runs Step 1 scripts manually |
| [52_config_ad-lab_part2.ps1](52_config_ad-lab_part2.ps1) | Legacy wrapper: runs Step 2+3 scripts manually |

## Configuration

| Script | Purpose |
|--------|---------|
| [00_init_environment.ps1](00_init_environment.ps1) | Dot-sourced by all scripts — loads `default_configuration.txt`, sets domain, password, company, Oracle, and CNAME variables; imports `CommonFunctions` |

## Step 1 - AD Role Installation

| Script | Purpose |
|--------|---------|
| [01_install_ad_role.ps1](01_install_ad_role.ps1) | Installs the AD Domain Services role and promotes the server to domain controller |
| [22_install_chocolatey.ps1](22_install_chocolatey.ps1) | Installs the Chocolatey package manager |

## Step 2 - AD and Tools Configuration

| Script | Purpose |
|--------|---------|
| [11_add_lab_company.ps1](11_add_lab_company.ps1) | Creates lab OUs (People, Groups, departments), imports users from `users_ad.csv`, creates company groups (`$Company Users`, DB Admins, Developers, etc.) |
| [11_add_service_principles.ps1](11_add_service_principles.ps1) | Creates Kerberos service principal accounts from `hosts.csv`; creates and privileges the `oracle` service user |
| [12_config_dns.ps1](12_config_dns.ps1) | Configures DNS: reverse lookup zone, A/PTR records from `hosts.csv`, CNAME aliases for `ad`, `oud` (`$CNAMEOud`), `db` (`$CNAMEDb`) |
| [26_install_tools.ps1](26_install_tools.ps1) | Installs tools via Chocolatey (e.g. git, sysinternals) |
| [28_config_misc.ps1](28_config_misc.ps1) | Removes NAT DNS record, deploys BGInfo, runs Windows Update |
| [28_install_oracle_client.ps1](28_install_oracle_client.ps1) | Downloads and installs Oracle Instant Client; version controlled via `InstantClientVersion`/`InstantClientBuild` in config |

## Step 3 - CA and Summary

| Script | Purpose |
|--------|---------|
| [13_config_ca.ps1](13_config_ca.ps1) | Configures the Certificate Authority |
| [19_sum_up_ad.ps1](19_sum_up_ad.ps1) | Displays an AD domain summary |

## Oracle CMU and Kerberos (run after Step 2)

| Script | Purpose |
|--------|---------|
| [27_config_cmu.ps1](27_config_cmu.ps1) | Creates `ORA_VFR_11G`/`ORA_VFR_12C` groups; sets `msDS-SupportedEncryptionTypes=AES256` on Oracle service accounts; grants `oracle` LDAP bind ACL; generates Kerberos keytab files via `ktpass` for DB hosts |

## Day-2 Operations

| Script | Purpose |
|--------|---------|
| [40_reset_ad_users.ps1](40_reset_ad_users.ps1) | Resets all lab user passwords to the current default password; adds `$Company Users` to `ORA_VFR_11G` |

## Module

| Path | Purpose |
|------|---------|
| [modules/CommonFunctions/](modules/CommonFunctions/) | Shared module: `Write-Log`, `Wait-ADReady`, `New-Password`, `Exit-Script`, `Use-Module`, `Set-LoggingLevel`, `Get-LoggingLevel` |

## Script Standards

All scripts in this repository follow these conventions:

- `Set-StrictMode -Version Latest`
- `$ErrorActionPreference = 'Stop'` (or inherited from caller)
- Explicit `Import-Module CommonFunctions` at the top
- All AD operations wrapped in `try-catch` with `Write-Log -Level ERROR`
- `Wait-ADReady` replaces infinite `while ($true)` AD polling loops
- No `Write-Host` — all output via `Write-Log`
- Configuration values from `00_init_environment.ps1` / `default_configuration.txt`
- Idempotent: re-runnable without errors when objects already exist

## Template

[99_template.ps1](99_template.ps1) provides a starting point for new scripts
following the repository conventions.
