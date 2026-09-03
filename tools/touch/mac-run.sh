#!/usr/bin/env bash
# Run the touch layer on the Mac build with mouse-as-finger emulation and a
# scripted gesture file, then check the console markers. ~90 s.
# Usage: tools/touch/mac-run.sh [script.lua]   (default tools/touch/smoke.lua)
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${1:-$ROOT/tools/touch/smoke.lua}"
HOME_TE="$HOME/Library/Application Support/T-Engine/4.0"
mkdir -p "$HOME_TE/settings"
cp "$SCRIPT" "$HOME_TE/touch-script.lua"
printf 'touch = {emulate=true, script="/touch-script.lua"}\n' > "$HOME_TE/settings/touch.cfg"
printf 'autopilot = true\nautopilot_birth_only = true\n' > "$HOME_TE/settings/autopilot.cfg"
printf 'audio.enable = false\n' > "$HOME_TE/settings/audio.cfg"
printf "window = {size='1398x645 Windowed'}\n" > "$HOME_TE/settings/window.cfg"
OUT="$ROOT/runs/touchmac-$(date +%Y%m%d-%H%M%S)"; mkdir -p "$OUT"; LOG="$OUT/console.log"
( cd "$ROOT" && ./t-engine.app/Contents/MacOS/t-engine --flush-stdout > "$LOG" 2>&1 ) &
PID=$!
for i in $(seq 1 150); do sleep 2; grep -q "\[SCRIPT\] done\|\[TOUCH\] script error\|script load failed" "$LOG" && break; done
kill $PID 2>/dev/null; sleep 1; kill -9 $PID 2>/dev/null
rm -f "$HOME_TE/settings/touch.cfg"
check() { if grep -qE "$2" "$LOG"; then echo "PASS $1"; else echo "FAIL $1 (no /$2/)"; fi; }
check "script ran" '\[SCRIPT\] finished'
check "tap -> click" '\[TOUCH\] tap'
check "hold -> right click" '\[TOUCH\] long-press -> right click'
check "drag -> pan" '\[TOUCH\] drag -> pan'
check "wheel opened" '\[TOUCH\] wheel open'
check "two-finger -> Escape" '\[TOUCH\] two-finger tap -> EXIT'
check "drag in dialog -> scroll" '\[TOUCH\] drag -> scroll'
echo "Lua errors: $(grep -c 'Lua Error' "$LOG")"; grep -A8 'Lua Error' "$LOG" | head -30
echo "log: $LOG"
