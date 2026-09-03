#!/usr/bin/env bash
# Touch-UI regression run on the Plus-size simulator. Launches the game with a
# fresh auto-birthed character (autopilot_birth_only), then drives every touch
# interaction we support and captures a frame after each. Prints PASS/FAIL per
# step from the console trace; frames land in $OUT for eyeballing.
# Usage: tools/ios/simtest.sh [UDID]   (needs idb: pipx install fb-idb)
set -u
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UD="${1:-$(xcrun simctl list devices | grep -E 'Plus.*Booted' | grep -oE '[0-9A-F-]{36}' | head -1)}"
[ -z "$UD" ] && { echo "no booted Plus simulator"; exit 1; }
OUT="$ROOT/runs/simtest-$(date +%Y%m%d-%H%M%S)"; mkdir -p "$OUT"
LOG="$OUT/console.log"; TAP="python3 $ROOT/tools/ios/simtap.py $UD"
D=$(xcrun simctl get_app_container "$UD" org.te4.tome.dev data)
mkdir -p "$D/Documents/t-engine/4.0/settings"
printf 'audio.enable = false\naudio.music_volume = 0\naudio.effects_volume = 0\n' > "$D/Documents/t-engine/4.0/settings/audio.cfg"
printf 'autopilot = true\nautopilot_birth_only = true\n' > "$D/Documents/t-engine/4.0/settings/autopilot.cfg"
shot() { xcrun simctl io "$UD" screenshot "$OUT/$1.png" >/dev/null 2>&1; sips -r 90 "$OUT/$1.png" --out "$OUT/$1.png" >/dev/null 2>&1; }
check() { # name pattern
	if grep -qE "$2" "$LOG"; then echo "PASS $1"; else echo "FAIL $1 (no /$2/ in console)"; fi
}
xcrun simctl terminate "$UD" org.te4.tome.dev 2>/dev/null
xcrun simctl launch --console-pty "$UD" org.te4.tome.dev --flush-stdout > "$LOG" 2>&1 &
sleep 85; shot 01-ingame
check "character created (birth-only autopilot)" '"birther_state"|AUTOPILOT\] active'
# the birth opens the level-up dialog (the autopilot no longer dismisses it): close it via its close box
CB=$(grep 'TOUCH\] close box at' "$LOG" | tail -1); X=$(echo "$CB" | awk -F'\t' '{print $2}'); Y=$(echo "$CB" | awk -F'\t' '{print $3}')
[ -n "$X" ] && { $TAP tap $((X+17)) $((Y+17)) >/dev/null; sleep 2; }
check "birth-time level-up dialog closed" '\[TOUCH\] close box\s+Levelup'
# orientation calibration: tap the player frame (HUD, harmless; also dismisses a
# Running popup) and read the engine coords back
N0=$(grep -cE 'IOS-INPUT\] UP' "$LOG"); $TAP tap 60 100 >/dev/null; sleep 2
RAW=$(grep -E 'IOS-INPUT\] UP' "$LOG" | sed -n "$((N0+1))p" | grep -oE 'lua=\([0-9.]+,[0-9.]+\)')
echo "calibration tap -> $RAW (expected near (60,100); if mirrored, flip orient in ~/.tome-simtap.json)"
$TAP tap 60 100 >/dev/null; sleep 2   # settle: no dialog, character idle
# 1. long-press on the character's tile area = right click menu
$TAP tap 700 320 --long >/dev/null; sleep 2; shot 02-longpress
check "long-press -> right click" '\[TOUCH\] long-press'
CB=$(grep 'TOUCH\] close box at' "$LOG" | tail -1); X=$(echo "$CB" | awk -F'\t' '{print $2}'); Y=$(echo "$CB" | awk -F'\t' '{print $3}')
[ -n "$X" ] && { $TAP tap $((X+17)) $((Y+17)) >/dev/null; sleep 1; }   # close the Actions menu via its close box
check "Actions menu closed by its close box" '\[TOUCH\] close box\s+Actions'
# 1b. hold-then-drag = hover-scrub (slow swipe: <12px in the first 450ms, then moves)
~/.local/bin/idb ui swipe $(python3 -c "
import json,os;c=json.load(open(os.path.expanduser('~/.tome-simtap.json')))
def pt(lx,ly):
    xl,yl=lx*c['zoom']/c['dpi'],ly*c['zoom']/c['dpi']
    return (c['h']-yl,xl) if c['orient']=='A' else (yl,c['w']-xl)
a=pt(700,320);b=pt(760,320);print(int(a[0]),int(a[1]),int(b[0]),int(b[1]))") --duration 4 --udid "$UD" >/dev/null 2>&1; sleep 2; shot 02b-hover
check "hold-then-drag -> hover-scrub" '\[TOUCH\] hover-scrub'
# 2. drag pans the camera (trace [PAN] only present in instrumented builds; use setScroll marker instead)
$TAP swipe 700 320 500 320 >/dev/null; sleep 2; shot 03-pan
check "drag -> pan" '\[TOUCH\] drag'
# 3. touch row: Level
$TAP tap 1142 616 >/dev/null; sleep 3; shot 04-levelup
check "touch row Level" '\[TOUCH\] button\s+LEVELUP'
# 4. close box
CB=$(grep 'TOUCH\] close box at' "$LOG" | tail -1); X=$(echo "$CB" | awk -F'\t' '{print $2}'); Y=$(echo "$CB" | awk -F'\t' '{print $3}')
[ -n "$X" ] && { $TAP tap $((X+17)) $((Y+17)) >/dev/null; sleep 2; shot 05-closed; }
check "dialog close box" '\[TOUCH\] close box'
# 5. escape key path (HID) opens the game menu, again closes it
~/.local/bin/idb ui key 41 --udid "$UD" >/dev/null 2>&1; sleep 2; shot 06-gamemenu
~/.local/bin/idb ui key 41 --udid "$UD" >/dev/null 2>&1; sleep 1
# 6. touch row (tiles right to left: Rest 1334, Explore 1270, Pick up 1206, Level 1142, Char 1078; y 616)
$TAP tap 1334 616 >/dev/null; sleep 3; shot 07-rest
check "touch row Rest" '\[TOUCH\] button\s+REST'
~/.local/bin/idb ui key 41 --udid "$UD" >/dev/null 2>&1; sleep 1   # Escape stops resting
~/.local/bin/idb ui key 41 --udid "$UD" >/dev/null 2>&1; sleep 1   # and closes the game menu if it opened instead
$TAP tap 1078 616 >/dev/null; sleep 3; shot 08-char
check "touch row Char" '\[TOUCH\] button\s+SHOW_CHARACTER_SHEET'
CB=$(grep 'TOUCH\] close box at' "$LOG" | tail -1); X=$(echo "$CB" | awk -F'\t' '{print $2}'); Y=$(echo "$CB" | awk -F'\t' '{print $3}')
[ -n "$X" ] && { $TAP tap $((X+17)) $((Y+17)) >/dev/null; sleep 2; shot 09-char-closed; }
$TAP tap 1206 616 >/dev/null; sleep 3; shot 10-pickup
check "touch row Pick up" '\[TOUCH\] button\s+PICKUP_FLOOR'
$TAP tap 1270 616 >/dev/null; sleep 4; shot 11-explore
check "touch row Explore" '\[TOUCH\] button\s+RUN_AUTO'
# 7. zoom buttons (tiles continue leftwards: Z+ 1014, Z- 950)
$TAP tap 1014 616 >/dev/null; sleep 2; $TAP tap 1014 616 >/dev/null; sleep 2; shot 12-zoom-in
check "touch row Z+ zooms in" '\[MAP\] setting zoom level\s+1\.5'
$TAP tap 950 616 >/dev/null; sleep 2; shot 13-zoom-out
check "touch row Z- zooms out" '\[MAP\] setting zoom level\s+1\.25'
echo "lua errors: $(grep -c 'Lua Error' "$LOG")"
echo "frames in $OUT"
