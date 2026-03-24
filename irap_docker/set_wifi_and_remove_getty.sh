#!/bin/bash
# wifi_optimize.sh — maximize WiFi RX performance
# Usage: sudo bash wifi_optimize.sh [interface]
# Default interface: wlan0

IFACE=${1:-wlan0}
IW=/sbin/iw

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC}    $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
fail() { echo -e "${RED}[FAIL]${NC}  $1"; }
info() { echo -e "        $1"; }

# ─── root check ────────────────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
  fail "Run as root: sudo bash $0"
  exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  WiFi Optimizer — interface: $IFACE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ─── fix PATH so /sbin tools work without full path ───────────────────────────
export PATH=$PATH:/sbin:/usr/sbin

# ─── install missing tools ────────────────────────────────────────────────────
echo "── [0] Checking required tools ─────────────"
for pkg in iw wireless-tools ethtool; do
  if ! dpkg -s "$pkg" &>/dev/null; then
    info "Installing $pkg..."
    apt-get install -y "$pkg" -qq && ok "$pkg installed" || warn "Could not install $pkg"
  else
    ok "$pkg already installed"
  fi
done

# re-check iw path after install
IW=$(command -v iw || echo /sbin/iw)

# ─── check interface exists ────────────────────────────────────────────────────
echo ""
echo "── Checking interface ───────────────────────"
if ! ip link show "$IFACE" &>/dev/null; then
  fail "Interface $IFACE not found"
  info "Available interfaces:"
  ip link show | grep -E "^[0-9]" | awk '{print "  "$2}' | tr -d ':'
  exit 1
fi
ok "Interface $IFACE found"

# ─── detect phy ────────────────────────────────────────────────────────────────
PHY=$(cat /sys/class/net/$IFACE/phy80211/name 2>/dev/null || echo "phy0")
info "PHY: $PHY"

# ─── detect chip via sysfs (works without lsusb/lspci on ARM) ────────────────
CHIP=""
MODALIAS=$(cat /sys/class/net/$IFACE/device/modalias 2>/dev/null)
if [ -n "$MODALIAS" ]; then
  CHIP="$MODALIAS"
  ok "Chip modalias: $CHIP"
else
  CHIP=$(lsusb 2>/dev/null | grep -i -E "ralink|realtek|mediatek|atheros|broadcom|qualcomm" | head -1)
  [ -z "$CHIP" ] && CHIP=$(lspci 2>/dev/null | grep -i "wireless\|wifi\|wlan" | head -1)
  [ -n "$CHIP" ] && ok "Chip: $CHIP" || warn "Could not detect chip (non-fatal)"
fi

# ─── detect driver ────────────────────────────────────────────────────────────
DRIVER=$(ethtool -i "$IFACE" 2>/dev/null | awk '/driver:/{print $2}')
[ -z "$DRIVER" ] && DRIVER=$(readlink /sys/class/net/$IFACE/device/driver 2>/dev/null | xargs basename 2>/dev/null)
info "Driver: ${DRIVER:-unknown}"

echo ""
echo "── [1] Disable power saving ─────────────────"
if iwconfig "$IFACE" power off 2>/dev/null; then
  ok "Power saving disabled (iwconfig)"
elif $IW dev "$IFACE" set power_save off 2>/dev/null; then
  ok "Power saving disabled (iw)"
else
  warn "Could not disable power saving — may not be supported by this driver"
fi

echo ""
echo "── [2] Set regulatory domain ────────────────"
$IW reg set US 2>/dev/null && ok "Regulatory domain set to US (30 dBm max)" || warn "Could not set reg domain"

echo ""
echo "── [3] Set max TX power ─────────────────────"
if $IW phy "$PHY" set txpower fixed 3000 2>/dev/null; then
  ok "TX power set to 30 dBm"
elif $IW dev "$IFACE" set txpower fixed 3000 2>/dev/null; then
  ok "TX power set to 30 dBm (via dev)"
elif $IW phy "$PHY" set txpower auto 2>/dev/null; then
  ok "TX power set to auto (driver max)"
else
  warn "TX power unchanged — driver may manage this internally"
fi

echo ""
echo "── [4] Bring interface up ───────────────────"
ip link set "$IFACE" up && ok "Interface is up" || fail "Could not bring interface up"

echo ""
echo "── [5] Current connection status ───────────"
LINK=$($IW dev "$IFACE" link 2>/dev/null)
if echo "$LINK" | grep -q "Connected"; then
  ok "Connected"
  echo "$LINK" | grep -E "SSID|signal|tx bitrate|rx bitrate" | while read -r line; do info "$line"; done
else
  warn "Not connected (NO-CARRIER) — connect via nmtui then re-run"
fi

echo ""
echo "── [6] Driver-level RX tuning ───────────────"
info "Driver: ${DRIVER:-unknown}"
SYSFS_MOD="/sys/module/${DRIVER}/parameters"

if echo "$DRIVER" | grep -qi "rtw\|rtl\|88\|8192\|8812\|8821"; then
  ok "Realtek driver detected"
  if [ -d "$SYSFS_MOD" ]; then
    info "Available module params:"
    ls "$SYSFS_MOD" | while read -r p; do info "  $p = $(cat $SYSFS_MOD/$p 2>/dev/null)"; done
  else
    info "Writing modprobe config..."
    echo "options ${DRIVER} rtw_lps_mode=0 rtw_power_mgnt=0 rtw_ips_mode=0" \
      > /etc/modprobe.d/wifi-rx.conf
    ok "Written /etc/modprobe.d/wifi-rx.conf (takes effect on reboot)"
  fi
elif echo "$DRIVER" | grep -qi "ath\|qca\|ath10k\|ath9k"; then
  ok "Atheros/QCA driver detected"
  $IW phy "$PHY" set antenna 3 3 2>/dev/null \
    && ok "Both antenna chains enabled (mask 3)" \
    || warn "Antenna control not supported"
elif echo "$DRIVER" | grep -qi "brcm\|brcmfmac"; then
  ok "Broadcom driver detected"
  iwconfig "$IFACE" roam off 2>/dev/null && ok "Roam disabled" || true
else
  warn "Unknown driver — no chip-specific tuning applied"
  info "Run: ethtool -i $IFACE   to identify driver"
fi

echo ""
echo "── [7] Disable serial-getty on ttyMSM0 ──────"
systemctl stop    serial-getty@ttyMSM0.service 2>/dev/null \
  && ok "serial-getty@ttyMSM0 stopped"   || warn "Already stopped or not found"
systemctl disable serial-getty@ttyMSM0.service 2>/dev/null \
  && ok "serial-getty@ttyMSM0 disabled"  || warn "Could not disable"
systemctl mask    serial-getty@ttyMSM0.service 2>/dev/null \
  && ok "serial-getty@ttyMSM0 masked"    || warn "Could not mask"

echo ""
echo "── [8] Kernel network buffer tweaks ─────────"
sysctl -w net.core.rmem_max=26214400       &>/dev/null && ok "rmem_max           = 26214400"
sysctl -w net.core.wmem_max=26214400       &>/dev/null && ok "wmem_max           = 26214400"
sysctl -w net.core.netdev_max_backlog=5000 &>/dev/null && ok "netdev_max_backlog = 5000"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Done."
echo ""
echo "  If wlan0 still shows NO-CARRIER:"
echo "    sudo nmtui                   # connect to AP"
echo "    sudo nmcli dev wifi list     # list networks"
echo ""
echo "  Monitor live signal after connecting:"
echo "    watch -n 0.5 \"$IW dev $IFACE link\""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
