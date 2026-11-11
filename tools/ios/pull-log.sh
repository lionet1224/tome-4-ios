#!/usr/bin/env bash
# Pull the on-device game log (Documents/te4_log.txt) off the phone.
#   tools/ios/pull-log.sh [dest]   (default: runs/device-log-<time>.txt)
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEST="${1:-$ROOT/runs/device-log-$(date +%Y%m%d-%H%M%S).txt}"
UD=$(xcrun devicectl list devices 2>/dev/null | grep -i iphone | awk '{for(i=1;i<=NF;i++) if ($i ~ /^([0-9A-F]{8}-[0-9A-F]{16}|[0-9A-F-]{36})$/) print $i}' | head -1)
[ -z "$UD" ] && { echo "no iPhone visible"; exit 1; }
xcrun devicectl device copy from --device "$UD" --domain-type appDataContainer --domain-identifier com.lionet.tome --source Documents/te4_log.txt --destination "$DEST" >/dev/null 2>&1 && { echo "$DEST"; wc -l "$DEST"; } || { echo "copy failed (phone unlocked and plugged in?)"; exit 1; }
# the crash report, if the last run died (written by src/ios_crash.c; survives relaunches until the next crash)
CRASH="${DEST%.txt}.crash.txt"
if xcrun devicectl device copy from --device "$UD" --domain-type appDataContainer --domain-identifier com.lionet.tome --source Documents/te4_crash.txt --destination "$CRASH" >/dev/null 2>&1 && [ -s "$CRASH" ]; then
	echo "crash report: $CRASH"
else
	rm -f "$CRASH" 2>/dev/null
fi
