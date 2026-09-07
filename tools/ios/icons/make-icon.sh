#!/usr/bin/env bash
# App icon: the lantern-bearing adventurer from the title art (tome3.png), cropped square.
#   tools/ios/icons/make-icon.sh   -> AppIcon<size>.png here (listed in Info.plist CFBundleIconFiles)
set -e
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$HERE/../../../game/engines/default/data/gfx/background/tome3.png"
sips -c 760 760 --cropOffset 180 580 "$SRC" --out "$HERE/AppIcon1024.png" >/dev/null
sips -z 1024 1024 "$HERE/AppIcon1024.png" >/dev/null
for s in 180 167 152 120 87 80 76 60 58 40 29 20; do sips -z $s $s "$HERE/AppIcon1024.png" --out "$HERE/AppIcon$s.png" >/dev/null; done
echo "icons: $(ls "$HERE"/AppIcon*.png | wc -l | tr -d ' ')"
