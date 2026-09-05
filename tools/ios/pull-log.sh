#!/usr/bin/env bash
# Pull the on-device game log (Documents/te4_log.txt) off the phone.
#   tools/ios/pull-log.sh [dest]   (default: runs/device-log-<time>.txt)
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEST="${1:-$ROOT/runs/device-log-$(date +%Y%m%d-%H%M%S).txt}"
UD=$(xcrun devicectl list devices 2>/dev/null | grep -i iphone | awk '{for(i=1;i<=NF;i++) if ($i ~ /^[0-9A-F-]{36}$/) print $i}' | head -1)
[ -z "$UD" ] && { echo "no iPhone visible"; exit 1; }
xcrun devicectl device copy from --device "$UD" --domain-type appDataContainer --domain-identifier org.te4.tome.dev --source Documents/te4_log.txt --destination "$DEST" >/dev/null 2>&1 && { echo "$DEST"; wc -l "$DEST"; } || { echo "copy failed (phone unlocked and plugged in?)"; exit 1; }
