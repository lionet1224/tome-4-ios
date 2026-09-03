#!/usr/bin/env bash
# Radial-wheel checks on the Plus simulator: left wheel (hotkeys), right wheel
# (actions), Cast/Cancel while targeting. Frames in $OUT, PASS/FAIL from the
# console markers. Usage: tools/ios/simtest-wheel.sh [UDID]
set -u
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UD="${1:-$(xcrun simctl list devices | grep -E 'Plus.*Booted' | grep -oE '[0-9A-F-]{36}' | head -1)}"
[ -z "$UD" ] && { echo "no booted Plus simulator"; exit 1; }
OUT="$ROOT/runs/simwheel-$(date +%Y%m%d-%H%M%S)"; mkdir -p "$OUT"
LOG="$OUT/console.log"; TAP="python3 $ROOT/tools/ios/simtap.py $UD"
D=$(xcrun simctl get_app_container "$UD" org.te4.tome.dev data)
mkdir -p "$D/Documents/t-engine/4.0/settings"
printf 'audio.enable = false\naudio.music_volume = 0\naudio.effects_volume = 0\n' > "$D/Documents/t-engine/4.0/settings/audio.cfg"
printf 'autopilot = true\nautopilot_birth_only = true\n' > "$D/Documents/t-engine/4.0/settings/autopilot.cfg"
rm -f "$D/Documents/t-engine/4.0/settings/touch.cfg"
shot() { xcrun simctl io "$UD" screenshot "$OUT/$1.png" >/dev/null 2>&1; sips -r 90 "$OUT/$1.png" --out "$OUT/$1.png" >/dev/null 2>&1; }
check() { if grep -qE "$2" "$LOG"; then echo "PASS $1"; else echo "FAIL $1 (no /$2/ in console)"; fi; }
# slow swipe in logical coords: holds still long enough to open a wheel, then slides
slowswipe() { ~/.local/bin/idb ui swipe $(python3 -c "
import json,os;c=json.load(open(os.path.expanduser('~/.tome-simtap.json')))
def pt(lx,ly):
    xl,yl=lx*c['zoom']/c['dpi'],ly*c['zoom']/c['dpi']
    return (c['h']-yl,xl) if c['orient']=='A' else (yl,c['w']-xl)
a=pt($1,$2);b=pt($3,$4);print(int(a[0]),int(a[1]),int(b[0]),int(b[1]))") --duration "$5" --udid "$UD" >/dev/null 2>&1; }

xcrun simctl terminate "$UD" org.te4.tome.dev 2>/dev/null
xcrun simctl launch --console-pty "$UD" org.te4.tome.dev --flush-stdout > "$LOG" 2>&1 &
sleep 85; shot 01-ingame
check "character created" '"birther_state"|AUTOPILOT\] active'
CB=$(grep 'TOUCH\] close box at' "$LOG" | tail -1); X=$(echo "$CB" | awk -F'\t' '{print $2}'); Y=$(echo "$CB" | awk -F'\t' '{print $3}')
[ -n "$X" ] && { $TAP tap $((X+17)) $((Y+17)) >/dev/null; sleep 2; }
check "birth level-up dialog closed" '\[TOUCH\] close box\s+Levelup'
$TAP tap 60 100 >/dev/null; sleep 2; $TAP tap 60 100 >/dev/null; sleep 2
grep -E "Lua Error|error in|stack traceback" "$LOG" | head -5
shot 02-hud
# 1. left wheel: hold in the left third, slide up-right, lift
slowswipe 250 450 380 390 3 & sleep 1.6; shot 03-leftwheel; wait
sleep 2; shot 04-after-left
check "left wheel opened" '\[TOUCH\] wheel open\s+L'
check "left wheel picked a wedge" '\[TOUCH\] wheel pick\s+hotkey'
grep -E 'wheel pick|target placed' "$LOG" | tail -2
# if that talent wants a target: Cancel button, then re-test Cast via a second pick
if grep -q 'wheel pick.*hotkey' "$LOG"; then
	sleep 1; shot 05-targeting
	$TAP tap 1252 565 >/dev/null; sleep 2   # Cancel (right of the two thumb buttons)
	check "Cancel button (if targeting)" '\[TOUCH\] cancel target'
fi
$TAP tap 60 100 >/dev/null; sleep 1
# 2. right wheel: hold in the right third, slide up-left = Rest
slowswipe 1150 450 1020 390 3 & sleep 1.6; shot 06-rightwheel; wait
sleep 2; shot 07-after-right
check "right wheel opened" '\[TOUCH\] wheel open\s+R'
check "right wheel picked an action" '\[TOUCH\] wheel pick\s+key'
# 3. a plain tap in a zone still moves/acts (no wheel)
N=$(grep -c 'wheel open' "$LOG"); $TAP tap 300 450 >/dev/null; sleep 2
[ "$(grep -c 'wheel open' "$LOG")" = "$N" ] && echo "PASS plain tap in a zone does not open a wheel" || echo "FAIL plain tap opened a wheel"
shot 08-end
echo "Lua errors: $(grep -c 'Lua Error' "$LOG")"; grep -A6 'Lua Error' "$LOG" | head -40
echo "frames in $OUT"
