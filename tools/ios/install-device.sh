#!/usr/bin/env bash
# Build the device engine, wrap+sign it with Xcode, install and launch on the
# connected iPhone. Re-run this to refresh a free-account install (7-day expiry).
# Usage: tools/ios/install-device.sh [--no-engine]   (skip the engine rebuild)
set -euo pipefail
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
XC="$ROOT/tools/ios/xcode"
# Signing needs your Apple team id (Xcode > Settings > Accounts, or developer.apple.com > Membership):
# put it in tools/ios/team.txt (ignored by git) or export APPLE_TEAM. The project itself carries none.
TEAM="${APPLE_TEAM:-}"
[ -z "$TEAM" ] && [ -f "$ROOT/tools/ios/team.txt" ] && TEAM=$(tr -d '[:space:]' < "$ROOT/tools/ios/team.txt")
[ -z "$TEAM" ] && { echo "no Apple team id: write it to tools/ios/team.txt or export APPLE_TEAM (10 characters, from Xcode > Settings > Accounts)"; exit 1; }
[ "${1:-}" = "--no-engine" ] || PLATFORM=dev bash "$ROOT/tools/ios/build-engine.sh"
DEV=$(xcrun devicectl list devices 2>/dev/null | grep -E "connected|available" | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' | head -1)
[ -z "$DEV" ] && { echo "no connected iPhone (plug it in, unlock, trust this Mac)"; exit 1; }
XDEST=$(cd "$XC" && xcodebuild -project ToME.xcodeproj -scheme ToME -showdestinations 2>/dev/null | grep 'platform:iOS, arch' | grep -oE 'id:[0-9A-F-]+' | cut -d: -f2 | head -1)
echo "[install] device $DEV (xcode dest $XDEST)"
rm -rf "$XC/DerivedData/Build/Products/Release-iphoneos/ToME.app"  # force embed + codesign to rerun
(cd "$XC" && xcodebuild -project ToME.xcodeproj -scheme ToME -configuration Release -destination "id=$XDEST" -allowProvisioningUpdates DEVELOPMENT_TEAM="$TEAM" -derivedDataPath "$XC/DerivedData" build | grep -E 'error:|BUILD (SUCCEEDED|FAILED)|embedded engine')
APP=$(find "$XC/DerivedData" -name 'ToME.app' -path '*Release-iphoneos*' -maxdepth 6 | head -1)
[ -z "$APP" ] && { echo "no built app found"; exit 1; }
# the embed phase swaps the engine binary in after Xcode signed the bundle, so sign
# again ourselves with the entitlements from the profile Xcode embedded
if ! codesign --verify --deep --strict "$APP" >/dev/null 2>&1; then
	ID=$(security find-identity -v -p codesigning | grep -oE '"Apple Development: [^"]+"' | head -1 | tr -d '"')
	[ -z "$ID" ] && { echo "no Apple Development signing identity in the keychain"; exit 1; }
	ENT=$(mktemp /tmp/te4-ent.XXXXXX.plist)
	security cms -D -i "$APP/embedded.mobileprovision" | plutil -extract Entitlements xml1 -o "$ENT" - || { echo "cannot read the embedded profile"; exit 1; }
	codesign --force --sign "$ID" --entitlements "$ENT" --timestamp=none "$APP" || { echo "re-signing failed"; exit 1; }
	rm -f "$ENT"
	echo "[install] re-signed with $ID"
fi
codesign --verify --deep --strict "$APP" || { echo "app signature does not verify - aborting"; exit 1; }
xcrun devicectl device install app --device "$DEV" "$APP"
xcrun devicectl device process launch --device "$DEV" org.te4.tome.dev || true
echo "[install] done: Tales of Maj'Eyal is on the phone"
