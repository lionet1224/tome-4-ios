#!/bin/bash
# Xcode "Embed ToME engine" phase: swap the placeholder binary for the real
# engine and copy the game data, then Xcode signs the whole bundle.
set -euo pipefail
SRC="$SRCROOT/../out-dev/ToME.app"
[ -f "$SRC/t-engine" ] || { echo "error: $SRC/t-engine missing - run: PLATFORM=dev tools/ios/build-engine.sh"; exit 1; }
APP="$TARGET_BUILD_DIR/$WRAPPER_NAME"
cp -f "$SRC/t-engine" "$APP/$EXECUTABLE_NAME"
rsync -a --delete "$SRC/bootstrap" "$APP/"
rsync -a --delete "$SRC/game" "$APP/"
cp -f "$SRCROOT/../icons"/AppIcon*.png "$APP/"   # app icon files (CFBundleIconFiles)
echo "embedded engine + data into $APP"
