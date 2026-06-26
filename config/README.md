# AD Lab Configuration

This directory contains lab configuration files loaded by the setup scripts.

## Files

| File | Purpose |
|------|---------|
| [default_configuration.txt](default_configuration.txt) | Key-value pairs overriding script defaults |
| [default_pwd_windows.txt](default_pwd_windows.txt) | Default AD password (auto-generated if empty) |
| [hosts.csv](hosts.csv) | IP/hostname list for DNS records and Kerberos SPNs |
| [users_ad.csv](users_ad.csv) | User list imported into Active Directory |

## default_configuration.txt — Parameter Reference

All parameters are optional. If omitted, the defaults from
`00_init_environment.ps1` are used.

### Domain

| Parameter | Default | Description |
|-----------|---------|-------------|
| `NetworkDomainName` | `trivadislabs.com` | AD domain DNS name |
| `ADDomainMode` | `default` | AD functional level (e.g. `Win2019`) |
| `ServerAddress` | *(auto-detected)* | IP address of the DC; derived from first `Ethernet*` interface if empty |
| `DNS1ClientServerAddress` | `8.8.8.8` | Primary DNS forwarder |
| `DNS2ClientServerAddress` | `4.4.4.4` | Secondary DNS forwarder |

### Passwords

| Parameter | Default | Description |
|-----------|---------|-------------|
| `PlainPassword` | *(generated)* | Default password for all lab accounts; auto-generated and written to `default_pwd_windows.txt` if empty |
| `PasswordLength` | `15` | Length of auto-generated passwords |

### Active Directory Structure

| Parameter | Default | Description |
|-----------|---------|-------------|
| `Company` | `Trivadis LAB` | Company name; used as prefix for AD group names (e.g. `Trivadis LAB Users`) |
| `People` | `People` | OU name for user accounts |
| `Groups` | `Groups` | OU name for group accounts |

### Oracle

| Parameter | Default | Description |
|-----------|---------|-------------|
| `OracleBase` | `C:\u00\app\oracle` | Oracle base directory for Instant Client installation |
| `InstantClientVersion` | `19.11.0.0.0` | Oracle Instant Client version string (used in download filename) |
| `InstantClientBuild` | `1911000` | Oracle Instant Client build number (URL path segment on oracle.com) |
| `InstantClientSuffix` | `dbru` | Oracle Instant Client filename suffix after version string |

To install a different Instant Client release, update all three Oracle
parameters. Example for 21c:

```ini
InstantClientVersion    = 21.13.0.0.0
InstantClientBuild      = 2113000
InstantClientSuffix     = dbru
```

### DNS CNAME Aliases

| Parameter | Default | Description |
|-----------|---------|-------------|
| `CNAMEOud` | `oud12` | Target hostname for the `oud` CNAME DNS alias |
| `CNAMEDb` | `db19` | Target hostname for the `db` CNAME DNS alias |

The DNS script creates the following aliases:

| Alias | Points to |
|-------|-----------|
| `ad.<domain>` | AD server hostname |
| `oud.<domain>` | `$CNAMEOud.<domain>` |
| `db.<domain>` | `$CNAMEDb.<domain>` |

## hosts.csv

CSV file with `IP,Name` columns. Used by:

- `11_add_service_principles.ps1` — creates Kerberos service principal accounts
- `12_config_dns.ps1` — creates A and PTR DNS records
- `27_config_cmu.ps1` — sets AES256 encryption on service principals; generates
  keytab files for hosts matching `db*`

Example:

```csv
IP,Name
10.0.1.19,db19
10.0.1.10,oud12
```

## users_ad.csv

CSV file imported by `11_add_lab_company.ps1`. Required columns:
`SamAccountName`, `GivenName`, `Surname`, `Name`, `Title`, `Department`.
