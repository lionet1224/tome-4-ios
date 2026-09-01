#!/usr/bin/env bash
# Install and launch ToME.app in the iOS simulator. Builds nothing itself;
# run build-deps.sh then build-engine.sh first (or just: tools/ios/all.sh).
set -euo pipefail

# use a freshly installed Xcode even before xcode-select is switched to it
if ! xcrun --sdk iphonesimulator --show-sdk-path >/dev/null 2>&1 && [ -d /Applications/Xcode.app ]; then
	export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP="$ROOT/tools/ios/out/ToME.app"
BUNDLE_ID=org.te4.tome.dev

[ -x "$APP/t-engine" ] || { echo "ERROR: $APP not built yet"; exit 1; }

# pick a booted device, else boot the newest available iPhone
DEV="$(xcrun simctl list devices booted | grep -oE '[0-9A-F-]{36}' | head -1 || true)"
if [ -z "$DEV" ]; then
	DEV="$(xcrun simctl list devices available | grep -E 'iPhone' | grep -oE '[0-9A-F-]{36}' | tail -1)"
	[ -n "$DEV" ] || { echo "ERROR: no available iPhone simulator devices"; exit 1; }
	echo "Booting simulator $DEV ..."
	xcrun simctl boot "$DEV"
fi
open -a Simulator

xcrun simctl install "$DEV" "$APP"
echo "Launching (engine log follows; also /tmp/te4_log.txt inside sim container)..."
xcrun simctl launch --console-pty "$DEV" "$BUNDLE_ID"
