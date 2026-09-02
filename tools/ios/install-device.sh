#!/usr/bin/env bash
# Build the device engine, wrap+sign it with Xcode, install and launch on the
# connected iPhone. Re-run this to refresh a free-account install (7-day expiry).
# Usage: tools/ios/install-device.sh [--no-engine]   (skip the engine rebuild)
set -euo pipefail
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
XC="$ROOT/tools/ios/xcode"
[ "${1:-}" = "--no-engine" ] || PLATFORM=dev bash "$ROOT/tools/ios/build-engine.sh"
DEV=$(xcrun devicectl list devices 2>/dev/null | awk '/connected/{print $(NF-2)}' | head -1)
[ -z "$DEV" ] && { echo "no connected iPhone (plug it in, unlock, trust this Mac)"; exit 1; }
XDEST=$(cd "$XC" && xcodebuild -project ToME.xcodeproj -scheme ToME -showdestinations 2>/dev/null | grep 'platform:iOS, arch' | grep -oE 'id:[0-9A-F-]+' | cut -d: -f2 | head -1)
echo "[install] device $DEV (xcode dest $XDEST)"
(cd "$XC" && xcodebuild -project ToME.xcodeproj -scheme ToME -configuration Release -destination "id=$XDEST" -allowProvisioningUpdates -derivedDataPath "$XC/DerivedData" build | grep -E 'error:|BUILD (SUCCEEDED|FAILED)|embedded engine')
APP=$(find "$XC/DerivedData" -name 'ToME.app' -path '*Release-iphoneos*' -maxdepth 6 | head -1)
[ -z "$APP" ] && { echo "no built app found"; exit 1; }
xcrun devicectl device install app --device "$DEV" "$APP"
xcrun devicectl device process launch --device "$DEV" org.te4.tome.dev || true
echo "[install] done: Tales of Maj'Eyal is on the phone"
