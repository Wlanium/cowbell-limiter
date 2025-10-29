#!/bin/bash
#
# Mailcow Message Size Limit Updater
# Sets message size limits across all Mailcow components
#
# Usage: sudo ./set_message_size.sh [OPTIONS] [mailcow_path]
#
# Options:
#   --dry-run    Show what would be changed without making any modifications
#   --help       Show this help message
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Parse arguments
DRY_RUN=false
MAILCOW_PATH=""

show_help() {
   echo "Mailcow Message Size Limit Updater"
   echo ""
   echo "Usage: sudo $0 [OPTIONS] [mailcow_path]"
   echo ""
   echo "Options:"
   echo "  --dry-run    Show what would be changed without making any modifications"
   echo "  --help       Show this help message"
   echo ""
   echo "Examples:"
   echo "  sudo $0                                    # Auto-detect and apply changes"
   echo "  sudo $0 --dry-run                          # Preview changes without applying"
   echo "  sudo $0 /opt/mailcow-dockerized            # Use specific mailcow path"
   echo "  sudo $0 --dry-run /opt/mailcow-dockerized  # Preview with specific path"
   exit 0
}

for arg in "$@"; do
   case $arg in
      --dry-run)
         DRY_RUN=true
         shift
         ;;
      --help)
         show_help
         ;;
      *)
         if [ -z "$MAILCOW_PATH" ]; then
            MAILCOW_PATH="$arg"
         fi
         ;;
   esac
done

echo -e "${GREEN}=== Mailcow Message Size Limit Updater ===${NC}"
if [ "$DRY_RUN" = true ]; then
   echo -e "${MAGENTA}=== DRY RUN MODE - No changes will be made ===${NC}"
fi
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
   echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Function to detect mailcow directory
detect_mailcow_dir() {
   local detected_dir=""

   # Method 1: Check if provided as parameter
   if [ -n "$1" ]; then
      if [ -d "$1" ] && [ -f "$1/mailcow.conf" ]; then
         echo "$1"
         return 0
      else
         echo -e "${YELLOW}Warning: Provided path '$1' is not a valid mailcow directory${NC}" >&2
      fi
   fi

   # Method 2: Check current directory
   if [ -f "./mailcow.conf" ] && [ -f "./docker-compose.yml" ]; then
      echo "$(pwd)"
      return 0
   fi

   # Method 3: Try to detect from running docker container
   if command -v docker &> /dev/null; then
      local container=$(docker ps --format '{{.Names}}' | grep -E 'postfix-mailcow|mailcow.*postfix' | head -1)
      if [ -n "$container" ]; then
         local mount_path=$(docker inspect "$container" --format '{{range .Mounts}}{{if eq .Destination "/opt/postfix/conf"}}{{.Source}}{{end}}{{end}}' 2>/dev/null)
         if [ -n "$mount_path" ]; then
            # Extract base mailcow directory (remove /data/conf/postfix)
            detected_dir="${mount_path%/data/conf/postfix}"
            if [ -f "$detected_dir/mailcow.conf" ]; then
               echo "$detected_dir"
               return 0
            fi
         fi
      fi
   fi

   # Method 4: Search common installation paths
   local common_paths=(
      "/opt/mailcow-dockerized"
      "/opt/mailcow"
      "/srv/mailcow-dockerized"
      "/srv/mailcow"
      "/home/*/docker/mailcow"
      "/home/mailcow"
   )

   for path_pattern in "${common_paths[@]}"; do
      for path in $path_pattern; do
         if [ -d "$path" ] && [ -f "$path/mailcow.conf" ]; then
            echo "$path"
            return 0
         fi
      done
   done

   return 1
}

# Detect mailcow directory
echo -e "${CYAN}Detecting Mailcow installation...${NC}"
MAILCOW_DIR=$(detect_mailcow_dir "$MAILCOW_PATH")

if [ -z "$MAILCOW_DIR" ]; then
   echo -e "${YELLOW}Could not auto-detect Mailcow directory.${NC}"
   echo -e "Please enter the full path to your mailcow installation directory"
   echo -e "(the directory containing mailcow.conf and docker-compose.yml):"
   read -e -p "Path: " MAILCOW_DIR

   if [ ! -d "$MAILCOW_DIR" ] || [ ! -f "$MAILCOW_DIR/mailcow.conf" ]; then
      echo -e "${RED}Error: Invalid mailcow directory: $MAILCOW_DIR${NC}"
      exit 1
   fi
fi

echo -e "${GREEN}✓ Found Mailcow installation: ${MAILCOW_DIR}${NC}\n"

# Verify required directories exist
if [ ! -d "$MAILCOW_DIR/data/conf/postfix" ]; then
   echo -e "${RED}Error: Postfix config directory not found${NC}"
   exit 1
fi

# Define config files
POSTFIX_EXTRA="$MAILCOW_DIR/data/conf/postfix/extra.cf"
POSTFIX_MASTER="$MAILCOW_DIR/data/conf/postfix/master.cf"
RSPAMD_OPTIONS="$MAILCOW_DIR/data/conf/rspamd/local.d/options.inc"
RSPAMD_ANTIVIRUS="$MAILCOW_DIR/data/conf/rspamd/local.d/antivirus.conf"
RSPAMD_EXTERNAL="$MAILCOW_DIR/data/conf/rspamd/local.d/external_services.conf"
CLAMAV_CONF="$MAILCOW_DIR/data/conf/clamav/clamd.conf"

# Function to read current settings
read_current_settings() {
   local new_size_mb=$1
   local new_size_bytes=$2
   local show_changes=${3:-false}

   echo -e "${CYAN}=== Current Configuration ===${NC}\n"

   # Postfix extra.cf
   if [ -f "$POSTFIX_EXTRA" ]; then
      local value=$(grep "^message_size_limit" "$POSTFIX_EXTRA" 2>/dev/null | grep -o "[0-9]*" | head -1)
      if [ -n "$value" ]; then
         local mb=$((value / 1024 / 1024))
         if [ "$show_changes" = true ] && [ "$mb" != "$new_size_mb" ]; then
            echo -e "Postfix (extra.cf):              ${YELLOW}${mb} MB${NC} → ${GREEN}${new_size_mb} MB${NC}"
         else
            echo -e "Postfix (extra.cf):              ${GREEN}${mb} MB${NC} (${value} bytes)"
         fi
      else
         if [ "$show_changes" = true ]; then
            echo -e "Postfix (extra.cf):              ${YELLOW}Not set${NC} → ${GREEN}${new_size_mb} MB${NC}"
         else
            echo -e "Postfix (extra.cf):              ${YELLOW}Not set${NC}"
         fi
      fi
   else
      if [ "$show_changes" = true ]; then
         echo -e "Postfix (extra.cf):              ${RED}File not found${NC} → ${GREEN}Will be created${NC}"
      else
         echo -e "Postfix (extra.cf):              ${RED}File not found${NC}"
      fi
   fi

   # Postfix master.cf (SOGo)
   if [ -f "$POSTFIX_MASTER" ]; then
      local value=$(grep -A 6 "syslog_name=postfix/sogo" "$POSTFIX_MASTER" 2>/dev/null | grep "message_size_limit" | grep -o "[0-9]*" | head -1)
      if [ -n "$value" ]; then
         local mb=$((value / 1024 / 1024))
         if [ "$show_changes" = true ] && [ "$mb" != "$new_size_mb" ]; then
            echo -e "Postfix SOGo (master.cf):        ${YELLOW}${mb} MB${NC} → ${GREEN}${new_size_mb} MB${NC}"
         else
            echo -e "Postfix SOGo (master.cf):        ${GREEN}${mb} MB${NC} (${value} bytes)"
         fi
      else
         if [ "$show_changes" = true ]; then
            echo -e "Postfix SOGo (master.cf):        ${YELLOW}Not set${NC} → ${GREEN}${new_size_mb} MB${NC}"
         else
            echo -e "Postfix SOGo (master.cf):        ${YELLOW}Not set${NC}"
         fi
      fi
   else
      echo -e "Postfix SOGo (master.cf):        ${RED}File not found${NC}"
   fi

   # Rspamd options.inc
   if [ -f "$RSPAMD_OPTIONS" ]; then
      local value=$(grep "^max_message" "$RSPAMD_OPTIONS" 2>/dev/null | grep -o "[0-9]*" | head -1)
      if [ -n "$value" ]; then
         local mb=$((value / 1024 / 1024))
         if [ "$show_changes" = true ] && [ "$mb" != "$new_size_mb" ]; then
            echo -e "Rspamd (options.inc):            ${YELLOW}${mb} MB${NC} → ${GREEN}${new_size_mb} MB${NC}"
         else
            echo -e "Rspamd (options.inc):            ${GREEN}${mb} MB${NC} (${value} bytes)"
         fi
      else
         if [ "$show_changes" = true ]; then
            echo -e "Rspamd (options.inc):            ${YELLOW}Not set${NC} → ${GREEN}${new_size_mb} MB${NC}"
         else
            echo -e "Rspamd (options.inc):            ${YELLOW}Not set${NC}"
         fi
      fi
   else
      echo -e "Rspamd (options.inc):            ${RED}File not found${NC}"
   fi

   # Rspamd antivirus.conf
   if [ -f "$RSPAMD_ANTIVIRUS" ]; then
      local value=$(grep "max_size" "$RSPAMD_ANTIVIRUS" 2>/dev/null | grep -o "[0-9]*" | head -1)
      if [ -n "$value" ]; then
         local mb=$((value / 1024 / 1024))
         if [ "$show_changes" = true ] && [ "$mb" != "$new_size_mb" ]; then
            echo -e "Rspamd (antivirus.conf):         ${YELLOW}${mb} MB${NC} → ${GREEN}${new_size_mb} MB${NC}"
         else
            echo -e "Rspamd (antivirus.conf):         ${GREEN}${mb} MB${NC} (${value} bytes)"
         fi
      else
         if [ "$show_changes" = true ]; then
            echo -e "Rspamd (antivirus.conf):         ${YELLOW}Not set${NC} → ${GREEN}${new_size_mb} MB${NC}"
         else
            echo -e "Rspamd (antivirus.conf):         ${YELLOW}Not set${NC}"
         fi
      fi
   else
      echo -e "Rspamd (antivirus.conf):         ${RED}File not found${NC}"
   fi

   # Rspamd external_services.conf
   if [ -f "$RSPAMD_EXTERNAL" ]; then
      local value=$(grep "max_size" "$RSPAMD_EXTERNAL" 2>/dev/null | grep -o "[0-9]*" | head -1)
      if [ -n "$value" ]; then
         local mb=$((value / 1024 / 1024))
         if [ "$show_changes" = true ] && [ "$mb" != "$new_size_mb" ]; then
            echo -e "Rspamd (external_services.conf): ${YELLOW}${mb} MB${NC} → ${GREEN}${new_size_mb} MB${NC}"
         else
            echo -e "Rspamd (external_services.conf): ${GREEN}${mb} MB${NC} (${value} bytes)"
         fi
      else
         if [ "$show_changes" = true ]; then
            echo -e "Rspamd (external_services.conf): ${YELLOW}Not set${NC} → ${GREEN}${new_size_mb} MB${NC}"
         else
            echo -e "Rspamd (external_services.conf): ${YELLOW}Not set${NC}"
         fi
      fi
   else
      echo -e "Rspamd (external_services.conf): ${RED}File not found${NC}"
   fi

   # ClamAV
   if [ -f "$CLAMAV_CONF" ]; then
      local stream=$(grep "^StreamMaxLength" "$CLAMAV_CONF" 2>/dev/null | awk '{print $2}')
      local maxscan=$(grep "^MaxScanSize" "$CLAMAV_CONF" 2>/dev/null | awk '{print $2}')
      local maxfile=$(grep "^MaxFileSize" "$CLAMAV_CONF" 2>/dev/null | awk '{print $2}')
      local new_maxscan="${new_size_mb}M"
      [ -n "$new_size_mb" ] && new_maxscan="$((new_size_mb * 2))M"

      if [ -n "$stream" ]; then
         if [ "$show_changes" = true ] && [ "$stream" != "${new_size_mb}M" ]; then
            echo -e "ClamAV StreamMaxLength:          ${YELLOW}${stream}${NC} → ${GREEN}${new_size_mb}M${NC}"
         else
            echo -e "ClamAV StreamMaxLength:          ${GREEN}${stream}${NC}"
         fi
      else
         if [ "$show_changes" = true ]; then
            echo -e "ClamAV StreamMaxLength:          ${YELLOW}Not set${NC} → ${GREEN}${new_size_mb}M${NC}"
         else
            echo -e "ClamAV StreamMaxLength:          ${YELLOW}Not set${NC}"
         fi
      fi

      if [ -n "$maxscan" ]; then
         if [ "$show_changes" = true ] && [ "$maxscan" != "$new_maxscan" ]; then
            echo -e "ClamAV MaxScanSize:              ${YELLOW}${maxscan}${NC} → ${GREEN}${new_maxscan}${NC}"
         else
            echo -e "ClamAV MaxScanSize:              ${GREEN}${maxscan}${NC}"
         fi
      else
         if [ "$show_changes" = true ]; then
            echo -e "ClamAV MaxScanSize:              ${YELLOW}Not set${NC} → ${GREEN}${new_maxscan}${NC}"
         else
            echo -e "ClamAV MaxScanSize:              ${YELLOW}Not set${NC}"
         fi
      fi

      if [ -n "$maxfile" ]; then
         if [ "$show_changes" = true ] && [ "$maxfile" != "${new_size_mb}M" ]; then
            echo -e "ClamAV MaxFileSize:              ${YELLOW}${maxfile}${NC} → ${GREEN}${new_size_mb}M${NC}"
         else
            echo -e "ClamAV MaxFileSize:              ${GREEN}${maxfile}${NC}"
         fi
      else
         if [ "$show_changes" = true ]; then
            echo -e "ClamAV MaxFileSize:              ${YELLOW}Not set${NC} → ${GREEN}${new_size_mb}M${NC}"
         else
            echo -e "ClamAV MaxFileSize:              ${YELLOW}Not set${NC}"
         fi
      fi
   else
      echo -e "ClamAV (clamd.conf):             ${RED}File not found${NC}"
   fi

   echo ""
}

# Display current settings
read_current_settings

# Prompt for size in MB
read -p "Enter desired message size limit in MB (e.g., 50, 80, 100): " SIZE_MB

# Validate input
if ! [[ "$SIZE_MB" =~ ^[0-9]+$ ]]; then
   echo -e "${RED}Error: Please enter a valid number${NC}"
   exit 1
fi

if [ "$SIZE_MB" -lt 10 ] || [ "$SIZE_MB" -gt 500 ]; then
   echo -e "${YELLOW}Warning: Size $SIZE_MB MB seems unusual. Recommended: 50-100 MB${NC}"
   read -p "Continue anyway? (y/n): " confirm
   if [ "$confirm" != "y" ]; then
      echo "Aborted."
      exit 0
   fi
fi

# Calculate sizes
SIZE_BYTES=$((SIZE_MB * 1024 * 1024))
CLAMAV_MAXSCAN=$((SIZE_MB * 2))  # Double for ClamAV scanning

echo -e "\n${CYAN}=== Planned Changes ===${NC}\n"
echo "  Mailcow Directory: ${MAILCOW_DIR}"
echo "  New Size: ${SIZE_MB} MB (${SIZE_BYTES} bytes)"
echo "  ClamAV MaxScanSize: ${CLAMAV_MAXSCAN}M"
echo ""

# Show what will change
read_current_settings "$SIZE_MB" "$SIZE_BYTES" true

if [ "$DRY_RUN" = true ]; then
   echo -e "${MAGENTA}=== Dry Run Summary ===${NC}\n"

   echo -e "${CYAN}Files that would be modified:${NC}"
   [ -f "$POSTFIX_EXTRA" ] && echo "  ✓ $POSTFIX_EXTRA" || echo "  + $POSTFIX_EXTRA (would be created)"
   [ -f "$POSTFIX_MASTER" ] && echo "  ✓ $POSTFIX_MASTER"
   [ -f "$RSPAMD_OPTIONS" ] && echo "  ✓ $RSPAMD_OPTIONS"
   [ -f "$RSPAMD_ANTIVIRUS" ] && echo "  ✓ $RSPAMD_ANTIVIRUS"
   [ -f "$RSPAMD_EXTERNAL" ] && echo "  ✓ $RSPAMD_EXTERNAL"
   [ -f "$CLAMAV_CONF" ] && echo "  ✓ $CLAMAV_CONF"
   echo ""

   echo -e "${CYAN}Backups would be created in:${NC}"
   echo "  $MAILCOW_DIR/config_backups/$(date +%Y%m%d_%H%M%S)/"
   echo ""

   echo -e "${CYAN}Containers that would be restarted:${NC}"
   echo "  - postfix-mailcow"
   echo "  - rspamd-mailcow"
   echo "  - clamd-mailcow"
   echo ""

   echo -e "${GREEN}=== Dry Run Complete ===${NC}"
   echo -e "\nNo changes were made. To apply these settings, run:"
   echo -e "${CYAN}  sudo $0 ${MAILCOW_DIR}${NC}"
   echo ""
   exit 0
fi

read -p "Apply these settings? (y/n): " confirm
if [ "$confirm" != "y" ]; then
   echo "Aborted."
   exit 0
fi

# Create backup directory
BACKUP_DIR="$MAILCOW_DIR/config_backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo -e "\n${YELLOW}Creating backups in: $BACKUP_DIR${NC}"

# Backup files
for file in "$POSTFIX_EXTRA" "$POSTFIX_MASTER" "$RSPAMD_OPTIONS" "$RSPAMD_ANTIVIRUS" "$RSPAMD_EXTERNAL" "$CLAMAV_CONF"; do
   if [ -f "$file" ]; then
      cp "$file" "$BACKUP_DIR/$(basename $file).bak"
      echo "  ✓ Backed up: $(basename $file)"
   else
      echo -e "  ${YELLOW}⚠ File not found (will be created if needed): $(basename $file)${NC}"
   fi
done

echo -e "\n${GREEN}Updating configuration files...${NC}"

# 1. Update Postfix extra.cf
if [ -f "$POSTFIX_EXTRA" ]; then
   if grep -q "message_size_limit" "$POSTFIX_EXTRA"; then
      sed -i "s/^message_size_limit = [0-9]*/message_size_limit = ${SIZE_BYTES}/" "$POSTFIX_EXTRA"
      echo "  ✓ Updated: postfix/extra.cf"
   else
      echo "message_size_limit = ${SIZE_BYTES}" >> "$POSTFIX_EXTRA"
      echo "  ✓ Added message_size_limit to: postfix/extra.cf"
   fi

   # Ensure mailbox_size_limit is set
   if ! grep -q "mailbox_size_limit" "$POSTFIX_EXTRA"; then
      echo "mailbox_size_limit = 0" >> "$POSTFIX_EXTRA"
      echo "  ✓ Added mailbox_size_limit to: postfix/extra.cf"
   fi
else
   echo -e "message_size_limit = ${SIZE_BYTES}\nmailbox_size_limit = 0" > "$POSTFIX_EXTRA"
   echo "  ✓ Created: postfix/extra.cf"
fi

# 2. Update Postfix master.cf (SOGo service)
if [ -f "$POSTFIX_MASTER" ]; then
   if grep -q "syslog_name=postfix/sogo" "$POSTFIX_MASTER"; then
      # Check if message_size_limit already exists for SOGo service
      if grep -A 6 "syslog_name=postfix/sogo" "$POSTFIX_MASTER" | grep -q "message_size_limit"; then
         sed -i "/syslog_name=postfix\/sogo/,/^$/s/-o message_size_limit=[0-9]*/-o message_size_limit=${SIZE_BYTES}/" "$POSTFIX_MASTER"
         echo "  ✓ Updated: postfix/master.cf (SOGo service)"
      else
         # Add message_size_limit after syslog_name=postfix/sogo
         sed -i "/syslog_name=postfix\/sogo/a\  -o message_size_limit=${SIZE_BYTES}" "$POSTFIX_MASTER"
         echo "  ✓ Added message_size_limit to: postfix/master.cf (SOGo service)"
      fi
   else
      echo -e "  ${YELLOW}⚠ SOGo service not found in master.cf${NC}"
   fi
else
   echo -e "  ${YELLOW}⚠ master.cf not found${NC}"
fi

# 3. Update Rspamd options.inc
if [ -f "$RSPAMD_OPTIONS" ]; then
   if grep -q "max_message" "$RSPAMD_OPTIONS"; then
      sed -i "s/^max_message = [0-9]*;/max_message = ${SIZE_BYTES};/" "$RSPAMD_OPTIONS"
      echo "  ✓ Updated: rspamd/local.d/options.inc"
   else
      echo "max_message = ${SIZE_BYTES};" >> "$RSPAMD_OPTIONS"
      echo "  ✓ Added max_message to: rspamd/local.d/options.inc"
   fi
else
   echo -e "  ${YELLOW}⚠ rspamd/local.d/options.inc not found${NC}"
fi

# 4. Update Rspamd antivirus.conf
if [ -f "$RSPAMD_ANTIVIRUS" ]; then
   sed -i "s/max_size = [0-9]*;/max_size = ${SIZE_BYTES};/" "$RSPAMD_ANTIVIRUS"
   echo "  ✓ Updated: rspamd/local.d/antivirus.conf"
else
   echo -e "  ${YELLOW}⚠ rspamd/local.d/antivirus.conf not found${NC}"
fi

# 5. Update Rspamd external_services.conf
if [ -f "$RSPAMD_EXTERNAL" ]; then
   sed -i "s/max_size = [0-9]*;/max_size = ${SIZE_BYTES};/" "$RSPAMD_EXTERNAL"
   echo "  ✓ Updated: rspamd/local.d/external_services.conf"
else
   echo -e "  ${YELLOW}⚠ rspamd/local.d/external_services.conf not found${NC}"
fi

# 6. Update ClamAV clamd.conf
if [ -f "$CLAMAV_CONF" ]; then
   sed -i "s/^StreamMaxLength [0-9]*M/StreamMaxLength ${SIZE_MB}M/" "$CLAMAV_CONF"
   sed -i "s/^MaxScanSize [0-9]*M/MaxScanSize ${CLAMAV_MAXSCAN}M/" "$CLAMAV_CONF"
   sed -i "s/^MaxFileSize [0-9]*M/MaxFileSize ${SIZE_MB}M/" "$CLAMAV_CONF"
   echo "  ✓ Updated: clamav/clamd.conf"
else
   echo -e "  ${YELLOW}⚠ clamav/clamd.conf not found${NC}"
fi

# Restart containers
echo -e "\n${GREEN}Restarting Mailcow containers...${NC}"
cd "$MAILCOW_DIR"

# Detect docker-compose command
if command -v docker-compose &> /dev/null; then
   DOCKER_COMPOSE="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null 2>&1; then
   DOCKER_COMPOSE="docker compose"
else
   echo -e "${RED}Error: docker-compose not found${NC}"
   exit 1
fi

echo -e "${CYAN}Using: $DOCKER_COMPOSE${NC}"
$DOCKER_COMPOSE restart postfix-mailcow rspamd-mailcow clamd-mailcow

echo -e "\n${GREEN}=== Verification ===${NC}"

# Wait for containers to be ready
sleep 3

# Detect container names (they might have different prefixes)
POSTFIX_CONTAINER=$(docker ps --format '{{.Names}}' | grep -E 'postfix-mailcow' | grep -v 'tlspol' | head -1)
RSPAMD_CONTAINER=$(docker ps --format '{{.Names}}' | grep -E 'rspamd-mailcow' | head -1)
CLAMD_CONTAINER=$(docker ps --format '{{.Names}}' | grep -E 'clamd-mailcow' | head -1)

if [ -z "$POSTFIX_CONTAINER" ] || [ -z "$RSPAMD_CONTAINER" ] || [ -z "$CLAMD_CONTAINER" ]; then
   echo -e "${YELLOW}Warning: Could not detect all container names. Skipping verification.${NC}"
   echo -e "Please verify manually with: docker ps${NC}"
else
   # Verify Postfix
   echo -ne "Postfix message_size_limit: "
   docker exec "$POSTFIX_CONTAINER" postconf -h message_size_limit 2>/dev/null | head -1 || echo "N/A"

   echo -ne "Postfix SOGo service: "
   docker exec "$POSTFIX_CONTAINER" postconf -P "588/inet/message_size_limit" 2>/dev/null | grep -o "[0-9]*" | head -1 || echo "N/A"

   echo -ne "Rspamd max_message: "
   docker exec "$RSPAMD_CONTAINER" rspamadm configdump options 2>/dev/null | grep max_message | grep -o "[0-9]*" | head -1 || echo "N/A"

   echo -ne "ClamAV StreamMaxLength: "
   docker exec "$CLAMD_CONTAINER" grep "^StreamMaxLength" /etc/clamav/clamd.conf 2>/dev/null | awk '{print $2}' || echo "N/A"

   echo -ne "ClamAV MaxScanSize: "
   docker exec "$CLAMD_CONTAINER" grep "^MaxScanSize" /etc/clamav/clamd.conf 2>/dev/null | awk '{print $2}' || echo "N/A"

   echo -ne "ClamAV MaxFileSize: "
   docker exec "$CLAMD_CONTAINER" grep "^MaxFileSize" /etc/clamav/clamd.conf 2>/dev/null | awk '{print $2}' || echo "N/A"
fi

echo -e "\n${GREEN}✓ Configuration updated successfully!${NC}"
echo -e "Backups saved in: ${BACKUP_DIR}"
echo -e "\nMessage size limit is now: ${GREEN}${SIZE_MB} MB${NC}"
echo -e "\n${CYAN}Note: Attachments are Base64-encoded when sent, which increases size by ~33%${NC}"
echo -e "${CYAN}A ${SIZE_MB}MB limit allows for ~$(($SIZE_MB * 75 / 100))MB of actual attachments.${NC}"
