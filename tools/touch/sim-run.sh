#!/usr/bin/env bash
# Run one scripted touch test in the iPhone simulator.
#   tools/touch/sim-run.sh tools/touch/tests/birth.lua <outdir> [early]
# Copies the script into the app's Documents, points touch.cfg at it, launches
# the app with the autopilot birth, waits for "[SCRIPT] finished" (or an error),
# then collects the console log and the T.shot() screenshots into <outdir>.
set -u
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$1"; OUT="$2"; EARLY="${3:-}"
UD="${UDID:-94E8BD6E-7084-4F64-8116-2AEC560DFCFC}"
mkdir -p "$OUT"
D=$(xcrun simctl get_app_container "$UD" org.te4.tome.dev data)
NAME="touch-test.lua"
cp "$SCRIPT" "$D/Documents/t-engine/4.0/$NAME"
if [ "$EARLY" = "boot" ]; then printf 'touch = {show_island=true, script="/%s", script_boot=true}\n' "$NAME" > "$D/Documents/t-engine/4.0/settings/touch.cfg"
elif [ -n "$EARLY" ]; then printf 'touch = {show_island=true, script="/%s", script_early=true}\n' "$NAME" > "$D/Documents/t-engine/4.0/settings/touch.cfg"
else printf 'touch = {show_island=true, script="/%s"}\n' "$NAME" > "$D/Documents/t-engine/4.0/settings/touch.cfg"; fi
printf 'audio.enable = false\naudio.music_volume = 0\naudio.effects_volume = 0\n' > "$D/Documents/t-engine/4.0/settings/audio.cfg"
if [ -n "$EARLY" ]; then printf 'autopilot = false\n' > "$D/Documents/t-engine/4.0/settings/autopilot.cfg"
else printf 'autopilot = true\nautopilot_birth_only = true\n' > "$D/Documents/t-engine/4.0/settings/autopilot.cfg"; fi
rm -f "$D"/Documents/t-engine/4.0/tome/shot-*.png "$D"/Documents/t-engine/4.0/boot/shot-*.png "$D"/Documents/t-engine/4.0/shot-*.png 2>/dev/null
rm -f "$D"/Documents/t-engine/4.0/tome/touch-test.log "$D"/Documents/t-engine/4.0/boot/touch-test.log "$D"/Documents/t-engine/4.0/touch-test.log 2>/dev/null
xcrun simctl terminate "$UD" org.te4.tome.dev 2>/dev/null
LOG="$OUT/console.log"
xcrun simctl launch --console-pty "$UD" org.te4.tome.dev --flush-stdout > "$LOG" 2>&1 &
t=0
FL="$D/Documents/t-engine/4.0/tome/touch-test.log $D/Documents/t-engine/4.0/boot/touch-test.log"
until grep -qE "SCRIPT\] finished|SCRIPT\] done|script load failed|script must return|Lua Error" "$LOG" 2>/dev/null || cat $FL 2>/dev/null | grep -qE "SCRIPT\] finished|SCRIPT\] done|script error" || [ "$(grep -c 'script started' "$LOG" 2>/dev/null)" -ge 2 ] || [ $t -ge 200 ]; do sleep 2; t=$((t+2)); done
sleep 4
xcrun simctl terminate "$UD" org.te4.tome.dev 2>/dev/null
for f in "$D"/Documents/t-engine/4.0/tome/shot-*.png "$D"/Documents/t-engine/4.0/boot/shot-*.png "$D"/Documents/t-engine/4.0/shot-*.png; do [ -f "$f" ] && mv "$f" "$OUT/"; done
for f in $FL; do [ -f "$f" ] && cat "$f" >> "$OUT/script.log"; done
echo "=== $SCRIPT -> $OUT"
[ -f "$OUT/script.log" ] && { echo "--- script.log:"; cut -c1-220 "$OUT/script.log"; }
grep -E "SCRIPT\]|Lua Error|script error|script load failed|script must return" -A3 "$LOG" | grep -v "SOUND\|Loading tile\|cached font\|Loading entities" | head -60 | cut -c1-220
ls "$OUT" | grep -v console
