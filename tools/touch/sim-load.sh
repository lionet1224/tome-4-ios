#!/usr/bin/env bash
# Load the newest save through the touch title menu and run a boot+game script (tools/touch/tests/loadzoom.lua style).
set -u
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
SCRIPT="$1"; OUT="$2"; UD="${UDID:-94E8BD6E-7084-4F64-8116-2AEC560DFCFC}"
mkdir -p "$OUT"
D=$(xcrun simctl get_app_container "$UD" org.te4.tome.dev data)
cp "$SCRIPT" "$D/Documents/t-engine/4.0/touch-test.lua"
printf 'touch = {show_island=true, script="/touch-test.lua", script_boot=true}\n' > "$D/Documents/t-engine/4.0/settings/touch.cfg"
printf 'autopilot = false\n' > "$D/Documents/t-engine/4.0/settings/autopilot.cfg"
rm -f "$D"/Documents/t-engine/4.0/tome/shot-*.png "$D"/Documents/t-engine/4.0/boot/shot-*.png 2>/dev/null
xcrun simctl terminate "$UD" org.te4.tome.dev 2>/dev/null
xcrun simctl launch --console-pty "$UD" org.te4.tome.dev --flush-stdout > "$OUT/console.log" 2>&1 &
t=0; until grep -qE "SCRIPT\] finished|Lua Error|script error" "$OUT/console.log" 2>/dev/null || [ $t -ge 240 ]; do sleep 3; t=$((t+3)); done; sleep 2
xcrun simctl io "$UD" screenshot "$OUT/after.png" >/dev/null 2>&1; sips -r 90 "$OUT/after.png" --out "$OUT/after.png" >/dev/null 2>&1; sips -Z 900 "$OUT/after.png" --out "$OUT/after-s.png" >/dev/null 2>&1
xcrun simctl terminate "$UD" org.te4.tome.dev 2>/dev/null
for f in "$D"/Documents/t-engine/4.0/tome/shot-*.png "$D"/Documents/t-engine/4.0/boot/shot-*.png; do [ -f "$f" ] && mv "$f" "$OUT/"; done
grep -E "SCRIPT\]|Lua Error|script error|script started|rebooting" "$OUT/console.log" | cut -c1-220 | head -14
ls "$OUT"
