#!/bin/bash
# =============================================================
# add_console_option.sh
# Finds boot entry .conf, validates machine-id + version match
# filename, then appends console=tty1 to options line
# =============================================================
set -e

ENTRIES_DIR="/boot/efi/loader/entries"
OPTION_TO_ADD="console=tty1"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC}    $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
fail() { echo -e "${RED}[FAIL]${NC}  $1"; }
info() { echo -e "        $1"; }

# ── root check ───────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
  fail "Run as root: sudo bash $0"
  exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Boot Entry Console Option Patcher"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── check entries dir exists ─────────────────────────────────
if [ ! -d "$ENTRIES_DIR" ]; then
  fail "Entries directory not found: $ENTRIES_DIR"
  exit 1
fi
ok "Found entries dir: $ENTRIES_DIR"

# ── find all .conf files ──────────────────────────────────────
CONF_FILES=$(find "$ENTRIES_DIR" -maxdepth 1 -name "*.conf" | sort)

if [ -z "$CONF_FILES" ]; then
  fail "No .conf files found in $ENTRIES_DIR"
  exit 1
fi

echo ""
echo "── Found .conf files ────────────────────────"
echo "$CONF_FILES" | while read -r f; do info "$(basename "$f")"; done

# ── [1] Disable serial-getty on ttyMSM0 ─────────────────────
echo ""
echo "── [1] Disable serial-getty on ttyMSM0 ──────"
systemctl stop    serial-getty@ttyMSM0.service 2>/dev/null \
  && ok "serial-getty@ttyMSM0 stopped"  || warn "Already stopped or not found"
systemctl disable serial-getty@ttyMSM0.service 2>/dev/null \
  && ok "serial-getty@ttyMSM0 disabled" || warn "Could not disable"
systemctl mask    serial-getty@ttyMSM0.service 2>/dev/null \
  && ok "serial-getty@ttyMSM0 masked"   || warn "Could not mask"

# ── [2] Validate and patch .conf files ───────────────────────
echo ""
echo "── [2] Validating and patching ──────────────"

PATCHED=0
SKIPPED=0

while IFS= read -r CONF_FILE; do
  FILENAME=$(basename "$CONF_FILE" .conf)
  echo ""
  info "Processing: $FILENAME.conf"

  # ── extract fields from filename ──────────────────────────
  FILE_MACHINE_ID=$(echo "$FILENAME" | grep -oE '^[0-9a-f]{32}')
  FILE_VERSION=$(echo "$FILENAME" | sed "s/^${FILE_MACHINE_ID}-//")

  info "Filename machine-id : ${FILE_MACHINE_ID:-NOT FOUND}"
  info "Filename version    : ${FILE_VERSION:-NOT FOUND}"

  # ── extract fields from file content ──────────────────────
  CONTENT_MACHINE_ID=$(grep -E "^machine-id" "$CONF_FILE" | awk '{print $2}')
  CONTENT_VERSION=$(grep -E "^version"    "$CONF_FILE" | awk '{print $2}')
  CONTENT_SORT_KEY=$(grep -E "^sort-key"  "$CONF_FILE" | awk '{print $2}')

  info "Content machine-id  : ${CONTENT_MACHINE_ID:-NOT FOUND}"
  info "Content version     : ${CONTENT_VERSION:-NOT FOUND}"
  info "Content sort-key    : ${CONTENT_SORT_KEY:-NOT FOUND}"

  # ── validate machine-id match ─────────────────────────────
  if [ "$FILE_MACHINE_ID" != "$CONTENT_MACHINE_ID" ]; then
    warn "machine-id MISMATCH — skipping"
    warn "  filename : $FILE_MACHINE_ID"
    warn "  content  : $CONTENT_MACHINE_ID"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi
  ok "machine-id match  [CORRECTLY]"

  # ── validate version match ────────────────────────────────
  if [ "$FILE_VERSION" != "$CONTENT_VERSION" ]; then
    warn "version MISMATCH — skipping"
    warn "  filename : $FILE_VERSION"
    warn "  content  : $CONTENT_VERSION"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi
  ok "version match  [CORRECTLY]"

  # ── check if option already exists ───────────────────────
  if grep -qE "^options.*${OPTION_TO_ADD}" "$CONF_FILE"; then
    warn "$OPTION_TO_ADD already present — skipping"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # ── backup before editing ─────────────────────────────────
  cp "$CONF_FILE" "${CONF_FILE}.bak"
  ok "Backup created: $(basename "${CONF_FILE}.bak")"

  # ── append console=tty1 to options line ───────────────────
  sed -i "s/^\(options .*\)$/\1 ${OPTION_TO_ADD}/" "$CONF_FILE"
  ok "Appended '$OPTION_TO_ADD' to options line"

  # ── verify the change ─────────────────────────────────────
  NEW_OPTIONS=$(grep "^options" "$CONF_FILE")
  info "New options line:"
  info "  $NEW_OPTIONS"

  PATCHED=$((PATCHED + 1))

done <<< "$CONF_FILES"

# ── Summary ──────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ok  "Patched : $PATCHED file(s)"
warn "Skipped : $SKIPPED file(s)"

# ── Reboot prompt ─────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -n "  Reboot now to apply changes? [y/N]: "
read -r CONFIRM

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  ok "Rebooting..."
  sleep 2
  reboot
else
  warn "Reboot skipped."
  info "Run manually when ready: sudo reboot"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
