# ad-lab

Initially forked from https://github.com/oehrlis/ad-lab.

In a classic "yoink and twist" I've repurposed Trivaldis great Active Directory LAB Setup for Vault LDAP Demos.

I mostly use it in conjunction with this terraform code: https://github.com/GuyBarros/terraform-hcp-vault-dynamic-credentials-workshop

## to install and Configure AD:

cd c:\stage\ad-lab\scripts

- config default password
- check settings / domain in 00_init_environment.ps1
- run 01_install_ad_role.ps1
- reboot
- run scripts 12-15
