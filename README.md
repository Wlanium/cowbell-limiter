# 🔔 Cowbell Limiter

> *"I got a fever, and the only prescription is... adjustable message size limits!"*

**Cowbell Limiter** is a production-ready bash script that automatically configures message size limits across all Mailcow Dockerized components. No more manual editing of 6+ configuration files!

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Mailcow](https://img.shields.io/badge/mailcow-dockerized-blue.svg)](https://mailcow.email/)

## 🎯 Features

- **🔍 Auto-Detection**: Automatically finds your Mailcow installation using 4 different methods
- **📊 Current Status Display**: Shows all current settings before making changes
- **👀 Dry-Run Mode**: Preview changes without modifying anything (`--dry-run`)
- **💾 Automatic Backups**: Creates timestamped backups before any modifications
- **🎨 Colored Output**: Clear, professional terminal output with progress indicators
- **✅ Post-Verification**: Validates settings after applying changes
- **🔄 Smart Updates**: Updates all 6 components consistently:
  - Postfix (main configuration + SOGo service)
  - Rspamd (3 configuration files)
  - ClamAV (3 size parameters)

## 🚨 The Problem

Mailcow's legacy version had a simple `mailcow_msg_size` command. The Dockerized version requires manual editing of **6 different configuration files** across multiple components. Miss one, and emails fail silently or get rejected.

Common issues when doing this manually:
- Forgetting the SOGo service in Postfix `master.cf`
- Inconsistent values across components
- Missing `mailbox_size_limit` setting
- ClamAV's `StreamMaxLength` not updated
- No backups before changes

**Cowbell Limiter solves all of this** with a single command.

## 📦 Installation

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/cowbell-limiter.git
cd cowbell-limiter

# Make executable
chmod +x set_message_size.sh
```

## 🚀 Usage

### Basic Usage (Auto-detect Mailcow)
```bash
sudo ./set_message_size.sh
```

### Preview Changes (Dry Run)
```bash
sudo ./set_message_size.sh --dry-run
```

### Specify Mailcow Path
```bash
sudo ./set_message_size.sh /opt/mailcow-dockerized
```

### Combined: Dry Run with Path
```bash
sudo ./set_message_size.sh --dry-run /opt/mailcow-dockerized
```

### Get Help
```bash
sudo ./set_message_size.sh --help
```

## 📸 Example Output

### Standard Run
```
=== Mailcow Message Size Limit Updater ===

Detecting Mailcow installation...
✓ Found Mailcow installation: /home/username/docker/mailcow

=== Current Configuration ===

Postfix (extra.cf):              50 MB (52428800 bytes)
Postfix SOGo (master.cf):        50 MB (52428800 bytes)
Rspamd (options.inc):            50 MB (52428800 bytes)
Rspamd (antivirus.conf):         50 MB (52428800 bytes)
Rspamd (external_services.conf): 50 MB (52428800 bytes)
ClamAV StreamMaxLength:          50M
ClamAV MaxScanSize:              100M
ClamAV MaxFileSize:              50M

Enter desired message size limit in MB (e.g., 50, 80, 100): 80

=== Planned Changes ===

  Mailcow Directory: /home/username/docker/mailcow
  New Size: 80 MB (83886080 bytes)
  ClamAV MaxScanSize: 160M

Postfix (extra.cf):              50 MB → 80 MB
Postfix SOGo (master.cf):        50 MB → 80 MB
Rspamd (options.inc):            50 MB → 80 MB
Rspamd (antivirus.conf):         50 MB → 80 MB
Rspamd (external_services.conf): 50 MB → 80 MB
ClamAV StreamMaxLength:          50M → 80M
ClamAV MaxScanSize:              100M → 160M
ClamAV MaxFileSize:              50M → 80M

Apply these settings? (y/n): y

Creating backups in: /home/username/docker/mailcow/config_backups/20250129_143022/
  ✓ Backed up: extra.cf
  ✓ Backed up: master.cf
  ✓ Backed up: options.inc
  ✓ Backed up: antivirus.conf
  ✓ Backed up: external_services.conf
  ✓ Backed up: clamd.conf

Updating configuration files...
  ✓ Updated: postfix/extra.cf
  ✓ Updated: postfix/master.cf (SOGo service)
  ✓ Updated: rspamd/local.d/options.inc
  ✓ Updated: rspamd/local.d/antivirus.conf
  ✓ Updated: rspamd/local.d/external_services.conf
  ✓ Updated: clamav/clamd.conf

Restarting Mailcow containers...
Using: docker-compose
mailcow-dockerized_postfix-mailcow_1 ... done
mailcow-dockerized_rspamd-mailcow_1  ... done
mailcow-dockerized_clamd-mailcow_1   ... done

=== Verification ===
Postfix message_size_limit: 83886080
Postfix SOGo service: 83886080
Rspamd max_message: 83886080
ClamAV StreamMaxLength: 80M
ClamAV MaxScanSize: 160M
ClamAV MaxFileSize: 80M

✓ Configuration updated successfully!
Backups saved in: /home/username/docker/mailcow/config_backups/20250129_143022/

Message size limit is now: 80 MB

Note: Attachments are Base64-encoded when sent, which increases size by ~33%
A 80MB limit allows for ~60MB of actual attachments.
```

### Dry Run Output
```
=== Mailcow Message Size Limit Updater ===
=== DRY RUN MODE - No changes will be made ===

[... shows current config and planned changes ...]

=== Dry Run Summary ===

Files that would be modified:
  ✓ /home/username/docker/mailcow/data/conf/postfix/extra.cf
  ✓ /home/username/docker/mailcow/data/conf/postfix/master.cf
  ✓ /home/username/docker/mailcow/data/conf/rspamd/local.d/options.inc
  ✓ /home/username/docker/mailcow/data/conf/rspamd/local.d/antivirus.conf
  ✓ /home/username/docker/mailcow/data/conf/rspamd/local.d/external_services.conf
  ✓ /home/username/docker/mailcow/data/conf/clamav/clamd.conf

Backups would be created in:
  /home/username/docker/mailcow/config_backups/20250129_143530/

Containers that would be restarted:
  - postfix-mailcow
  - rspamd-mailcow
  - clamd-mailcow

=== Dry Run Complete ===

No changes were made. To apply these settings, run:
  sudo ./set_message_size.sh /home/username/docker/mailcow
```

## 🔧 What Gets Updated

The script updates message size limits in these files:

| Component | File | Parameter |
|-----------|------|-----------|
| Postfix | `data/conf/postfix/extra.cf` | `message_size_limit`, `mailbox_size_limit` |
| Postfix (SOGo) | `data/conf/postfix/master.cf` | `message_size_limit` (port 588) |
| Rspamd | `data/conf/rspamd/local.d/options.inc` | `max_message` |
| Rspamd | `data/conf/rspamd/local.d/antivirus.conf` | `max_size` |
| Rspamd | `data/conf/rspamd/local.d/external_services.conf` | `max_size` |
| ClamAV | `data/conf/clamav/clamd.conf` | `StreamMaxLength`, `MaxScanSize`, `MaxFileSize` |

**Note:** ClamAV's `MaxScanSize` is automatically set to 2× the message limit for scanning overhead.

## 💡 Important Notes

### Base64 Encoding
Email attachments are Base64-encoded during transmission, which increases their size by approximately **33%**.

**Example:**
- **80 MB limit** = ~60 MB of actual attachments
- **100 MB limit** = ~75 MB of actual attachments
- **50 MB limit** = ~37 MB of actual attachments

### Recommended Limits
- **Small organizations**: 50-80 MB
- **Medium/Large**: 80-100 MB
- **Avoid**: > 150 MB (performance impact)

## 🔍 Auto-Detection Methods

The script tries 4 methods to find your Mailcow installation:

1. **Command-line parameter**: If you provide a path
2. **Current directory**: If you're in the Mailcow directory
3. **Docker inspection**: Reads volume mounts from running containers
4. **Common paths**: Searches standard installation locations:
   - `/opt/mailcow-dockerized`
   - `/opt/mailcow`
   - `/srv/mailcow-dockerized`
   - `/srv/mailcow`
   - `/home/*/docker/mailcow`

If all methods fail, you'll be prompted to enter the path manually.

## 🐛 Troubleshooting

### "Error: This script must be run as root"
The script needs root privileges to modify configuration files and restart containers.
```bash
sudo ./set_message_size.sh
```

### "Error: Mailcow directory not found"
Specify the path explicitly:
```bash
sudo ./set_message_size.sh /path/to/your/mailcow-dockerized
```

### "docker-compose not found"
The script supports both `docker-compose` (standalone) and `docker compose` (plugin). Ensure Docker is installed.

### Still Getting "Message Too Large" Errors?

1. **Check if changes were applied**: Use `--dry-run` to verify current settings
2. **Restart Outlook/Mail Client**: They cache server capabilities
3. **Check receiving server**: The recipient's mail server might have limits too
4. **Verify container restart**: Check `docker ps` to ensure containers restarted successfully

## 📚 Background

This script was created to solve a recurring issue with Mailcow Dockerized: the lack of a simple command to adjust message size limits (which existed in the legacy version as `mailcow_msg_size`).

The Docker version requires editing multiple configuration files across different components, which is:
- Time-consuming
- Error-prone
- Poorly documented
- Easy to miss critical settings (like SOGo service limits)

This has led to numerous GitHub issues ([#1914](https://github.com/mailcow/mailcow-dockerized/issues/1914), [#578](https://github.com/mailcow/mailcow-dockerized/issues/578), [#4726](https://github.com/mailcow/mailcow-dockerized/issues/4726), [#3653](https://github.com/mailcow/mailcow-dockerized/issues/3653)) and community forum posts.

**Cowbell Limiter** automates this entire process with safety checks, backups, and verification.

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests
- Improve documentation

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- The [Mailcow](https://mailcow.email/) team for creating an excellent mail server suite
- Everyone who reported issues about message size configuration
- The original `mc_msg_size` script from legacy Mailcow

## ⚠️ Disclaimer

This script modifies your Mailcow configuration. Always:
- Test in a non-production environment first
- Use `--dry-run` to preview changes
- Verify backups are created
- Keep your Mailcow instance updated

**Use at your own risk.** The authors are not responsible for any issues arising from the use of this script.

---

**Need more cowbell?** 🔔 [Open an issue](https://github.com/Wlanium/cowbell-limiter/issues) or submit a PR!
