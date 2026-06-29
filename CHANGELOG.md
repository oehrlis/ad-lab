# Changelog
<!-- markdownlint-disable MD013 -->
<!-- markdownlint-configure-file { "MD024":{"allow_different_nesting": true }} -->
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2026-06-26

### Added

- `CommonFunctions.psm1`: neue Funktion `Wait-ADReady` — wartet auf `Get-ADDomain`
  und LDAP Port 389, konfigurierbare Timeout/Intervall-Parameter, wirft terminierende
  Exception bei Timeout
- `27_config_cmu.ps1`: vollständig implementiert — erstellt `ORA_VFR_11G`/`ORA_VFR_12C`
  Gruppen, setzt `msDS-SupportedEncryptionTypes=AES256` auf Oracle Service Accounts,
  konfiguriert LDAP Bind ACL für oracle User, generiert Kerberos Keytab-Dateien via KtPass
- `config/default_configuration.txt`: neue Konfigurationsparameter `OracleBase`,
  `InstantClientVersion`, `InstantClientBuild`, `InstantClientSuffix`, `CNAMEOud`, `CNAMEDb`
- Dokumentation vollständig überarbeitet: `README.md` (Root), `scripts/README.md`,
  `config/README.md`, `scripts/modules/CommonFunctions/README.md` — aktueller
  Skriptstand, Konfigurationsreferenz, `Wait-ADReady` Dokumentation

### Changed

- `DeployADRole.ps1`: `$ErrorActionPreference = 'Stop'` gesetzt; `Wait-ADReady` am
  Anfang von Step2 aufgerufen
- `11_add_lab_company.ps1`: auf CommonFunctions umgestellt — `Write-Log`, `Set-StrictMode`,
  explizites `Import-Module`, `Wait-ADReady` statt Infinite-Loop, AD-Operationen in
  try-catch; `"Trivadis LAB Users"` durch `"$Company Users"` ersetzt
- `11_add_service_principles.ps1`: auf CommonFunctions umgestellt — `Write-Log`,
  `Set-StrictMode`, `Wait-ADReady`, Idempotenzprüfung für Host-Principals und oracle User
- `12_config_dns.ps1`: auf CommonFunctions umgestellt — `Write-Log`, `Set-StrictMode`,
  `Wait-ADReady`; zuvor auskommentierten DNS A/PTR-Record Code aktiviert; CNAME-Targets
  `oud12`/`db19` durch `$CNAMEOud`/`$CNAMEDb` aus Konfiguration ersetzt
- `28_install_oracle_client.ps1`: Instant Client Version, Build und Suffix als
  Variablen aus Konfiguration; Download und Extract in Schleife; PATH-Prüfung vor
  `SetEnvironmentVariable`; auf CommonFunctions umgestellt
- `40_reset_ad_users.ps1`: `"Trivadis LAB Users"` durch `"$Company Users"` ersetzt
- `00_init_environment.ps1`: Defaults und Config-Hash-Overrides für alle neuen Parameter

### Fixed

- `27_config_cmu.ps1`: Vagrant-Pfad `C:\vagrant_common\config\tnsadmin` durch
  `$env:AD_KEYTAB_DIR` (Fallback `C:\OraLab\config\keytabs`) ersetzt;
  `ktpass -mapuser $FQDN` auf `-mapuser $HostEntry` korrigiert (SAM-Name, nicht FQDN —
  `DsCrackNames 0x2` auf Windows Server 2022)
- `12_config_dns.ps1`, `27_config_cmu.ps1`: Parse-Fehler unter `Set-StrictMode -Version Latest`
  auf PS 5.1.20348+ behoben — `$VAR:` in Strings wurde als Scope-Qualifier geparst;
  Variablen-Referenzen auf `${VAR}:` umgestellt (`$HostEntry`, `$FQDN`, `$NAT_HOSTNAME`,
  `$grp`, `$KeytabFolder`)
- `51_config_ad-lab_part1.ps1`, `52_config_ad-lab_part2.ps1`: `$ErrorActionPreference`
  von `SilentlyContinue` auf `Stop` gesetzt
- `12_config_dns.ps1`: `$NAT_HOSTNAME`/`$NAT_IP` in den Variables-Block verschoben
  (waren erst nach ihrer Verwendung definiert)
- `28_config_misc.ps1`: Typo `-AutoReboo` auf `-AutoReboot` korrigiert; fehlende
  Variable `$ip = $ServerAddress` ergänzt

## [Unreleased] - 2021-03-04

### Added

### Changed

- Update [CONTRIBUTING](CONTRIBUTING.md) guide and add a few security rules
- Update [AUTHOR_GUIDE](AUTHOR_GUIDE.md) change YAML template for the workflow.
- Remove dependency on local templates in *Doc Build* workflow.
- Remove dependency on local templates [AUTHOR_GUIDE](AUTHOR_GUIDE.md).
- reorganize doc build pipeline to one file [doc-pipeline.yml](.github/workflows/doc-pipeline.yml).
- set company name based on domain name

### Fixed

### Removed

- remove all local templates in [templates](./templates). If local templates are
  necessary, they have to be downlowded from
  [oehrlis/pandoc_template](https://github.com/oehrlis/pandoc_template).
- remove [mdlint.yml](.github/workflows/mdlint.yml).
- remove [pandoc_builds.yml](.github/workflows/pandoc_builds.yml).

## [v0.2.1] - 2021-03-01

### Fixed

- Fix Markdown errors

## [0.2.0] - 2021-03-01

### Added

- Add support for boxes in PDF build using *Pandoc filters*.
- Add a pptx template [trivadis.pptx](templates/trivadis.pptx)
- Add a VERSION file for `treeder/bump`

### Changed

- Change `metadata` file and add `header-includes` for PDF boxes.
- Update LaTeX template [trivadis.tex](templates/trivadis.tex).
- Update [AUTHOR_GUIDE](AUTHOR_GUIDE.md).
- Add example for boxes in
  [1x10-General_Information.md](en/1x10-General_Information.md)

### Fixed

- Fix wrong layout for listings, add `--listings` to pandoc build command

### Removed

## [0.1.0] - 2021-02-25

### Added

- This CHANGELOG file to keep changes documented.
- Add draft version of AUTHOR_GUIDE.
- Add draft version of CODE_OF_CONDUCT.
- Add draft version of CONTRIBUTING.
- Add Trivadis LOGO.
- Add local Template for TeX / LaTeX.
- Add local Template for HTML.
- Add draft version of english docs.
- Add draft version of english docs.

### Changed

- exclude markdownlint MD013 in CODE_OF_CONDUCT.
- update [README](templates/README.md)

## [0.0.1] - 2021-02-25

### Added

- initial release of documents and repository

### Changed

### Fixed

### Removed

[unreleased]: https://github.com/olivierlacan/keep-a-changelog/compare/v0.2.1...HEAD
[0.2.1]: https://github.com/olivierlacan/keep-a-changelog/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/olivierlacan/keep-a-changelog/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/olivierlacan/keep-a-changelog/compare/v0.0.1...v0.1.0
[0.0.1]: https://github.com/olivierlacan/keep-a-changelog/releases/tag/v0.0.1
