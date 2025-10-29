# Changelog

All notable changes to Cowbell Limiter will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2025-01-29

### Added
- `--version` flag to display version information
- Version number embedded in script and help output

### Changed
- Help output now includes version number in header

## [1.0.0] - 2025-01-29

### Added
- Initial release of Cowbell Limiter
- Auto-detection of Mailcow installation (4 methods)
- Current configuration display before changes
- Dry-run mode (`--dry-run`) to preview changes
- Automatic timestamped backups before modifications
- Updates all 6 Mailcow components:
  - Postfix main configuration
  - Postfix SOGo service (port 588)
  - Rspamd options.inc
  - Rspamd antivirus.conf
  - Rspamd external_services.conf
  - ClamAV clamd.conf (3 parameters)
- Post-update verification of applied settings
- Colored terminal output for better UX
- Help command (`--help`)
- Support for both `docker-compose` and `docker compose`
- Base64 encoding overhead calculation and warnings
- Validation of user input (10-500 MB range)
- Automatic detection of container names (handles different prefixes)

### Features
- Smart value calculation (ClamAV MaxScanSize = 2× message limit)
- Before/After comparison display
- Comprehensive error handling
- File existence checks with warnings
- Interactive confirmation prompts
- Safe file modifications with sed

### Documentation
- Comprehensive README with examples
- Troubleshooting guide
- Installation instructions
- Usage examples
- Background information
- MIT License
- This CHANGELOG

---

## [Unreleased]

### Planned
- Configuration file validation before applying
- Rollback functionality from backups
- Non-interactive mode for automation
- Configuration export/import
- Support for custom ports
- Health check after restart
- Email test after configuration

---

[1.0.0]: https://github.com/YOUR_USERNAME/cowbell-limiter/releases/tag/v1.0.0
