#!/usr/bin/env bash
# Film a demo script on a simulator: frames from "script started" to "finished", assembled into docs/gifs/<name>.gif
#   tools/touch/demos/democap.sh <udid> <name> [extra touch settings]
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
UD="$1"; NAME="$2"; EXTRA="${3:-}"
OUT="${DEMO_OUT:-$ROOT/runs/demos}/$NAME"; rm -rf "$OUT"; mkdir -p "$OUT/frames"
D=$(xcrun simctl get_app_container "$UD" org.te4.tome.dev data)
cp "$ROOT/tools/touch/demos/lib.lua" "$D/Documents/t-engine/4.0/touch-demo-lib.lua"
UDID="$UD" TOUCH_EXTRA=", orientation=\"portrait\"$EXTRA" SIM_TIMEOUT=500 bash "$ROOT/tools/touch/sim-run.sh" "$ROOT/tools/touch/demos/demo-$NAME.lua" "$OUT" > "$OUT/run.txt" 2>&1 &
pid=$!
until grep -q "script started" "$OUT/console.log" 2>/dev/null || ! kill -0 $pid 2>/dev/null; do sleep 1; done
i=0
while kill -0 $pid 2>/dev/null && ! grep -q "SCRIPT\]\s*finished" "$OUT/console.log" 2>/dev/null; do
	xcrun simctl io "$UD" screenshot --type=jpeg "$OUT/frames/f$(printf %05d $i).jpg" >/dev/null 2>&1
	i=$((i+1))
done
wait $pid 2>/dev/null
echo "$NAME: $i frames"
"$ROOT/tools/touch/demos/assemble.py" "$OUT/frames" "$ROOT/docs/gifs/$NAME.gif" && rm -rf "$OUT/frames"
