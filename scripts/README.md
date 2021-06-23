# AD Setup Scripts

This directory contains a couple of setup script to configure a
*MS Active Directory* LAB environment. The following list does provide a short
overview of the different scripts.

- [00_init_environment.ps1](00_init_environment.ps1) script to Initialize and
  configure the default values.
- [01_install_ad_role.ps1](01_install_ad_role.ps1) PowerShell script to install
  *MS Active Directory* server role
- [11_config_ad.ps1](11_config_ad.ps1) PowerShell script to configure Active Directory
- [12_config_dns.ps1](12_config_dns.ps1) PowerShell script to configure DNS server
- [13_config_ca.ps1](13_config_ca.ps1) Script to configure Certification Autority
- [19_sum_up_ad.ps1](19_sum_up_ad.ps1) PowerShell script to display a summary of
  Active Directory Domain and install Windows updates
- [22_install_chocolatey.ps1](22_install_chocolatey.ps1) PowerShell script to
  install Chocolatey package manager
- [26_install_tools.ps1](26_install_tools.ps1) PowerShell script to install
  tools via chocolatey package
- [27_config_cmu.ps1](27_config_cmu.ps1) PowerShell script to configure CMU on
  *MS Active Directory*
- [28_config_misc.ps1](28_config_misc.ps1) PowerShell script to configure NAT
  zone records for AD domain
- [28_install_oracle_client.ps1](40_install_oracle_client.ps1) PowerShell
  script to install the Oracle Client
- [99_template.ps1](99_template.ps1) PowerShell template for other scripts
- [40_reset_ad_users.ps1](reset_ad_users.ps1) PowerShell script to reset all
  domain user password

Although the script [27_config_cmu.ps1](27_config_cmu.ps1) and
[28_install_oracle_client.ps1](28_install_oracle_client.ps1) are just skeletons.
They do not yet install any thing.
