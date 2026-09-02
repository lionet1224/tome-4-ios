#!/usr/bin/env bash
# One-screen health of the live mac + sim soaks: is the clock moving, where is
# the bot, any stall/error events, and the last archived run outcomes.
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MACD="$HOME/Library/Application Support/T-Engine/4.0/tome/autopilot"
SIMD="$(xcrun simctl get_app_container booted org.te4.tome.dev data 2>/dev/null)/Documents/t-engine/4.0/tome/autopilot"
stat_one() { # name dir
	local f; f=$(ls -t "$2"/telemetry-*.jsonl 2>/dev/null | head -1)
	[ -z "$f" ] && { echo "$1: no telemetry"; return; }
	local age=$(( $(date +%s) - $(stat -f %m "$f") ))
	local hb; hb=$(grep '"heartbeat"' "$f" | tail -1)
	local hb2; hb2=$(grep '"heartbeat"' "$f" | tail -25 | head -1)
	local t1 t2; t1=$(echo "$hb" | grep -oE '"turn":[0-9]+' | cut -d: -f2); t2=$(echo "$hb2" | grep -oE '"turn":[0-9]+' | cut -d: -f2)
	local zone lvl pl kills; zone=$(echo "$hb" | grep -oE '"zone":"[^"]*"' | cut -d'"' -f4); lvl=$(echo "$hb" | grep -oE '"lvl":[0-9]+' | cut -d: -f2)
	pl=$(echo "$hb" | grep -oE '"plevel":[0-9]+' | cut -d: -f2); kills=$(echo "$hb" | grep -oE '"kills":[0-9]+' | cut -d: -f2)
	local moving="MOVING"; [ "${t1:-0}" -le "${t2:-0}" ] && moving="STALLED(turn ${t1:-?} for ~2min)"
	[ "$age" -gt 120 ] && moving="DEAD(telemetry ${age}s old)"
	echo "$1: $moving | $zone L$lvl plevel $pl kills $kills | run age $(( ( $(date +%s) - $(basename "$f" .jsonl | sed s/telemetry-//) ) / 60 ))min"
	echo "   errors: lua=$(grep -c '"lua_error"' "$f") stalls=$(grep -cE '"(stall_dialog|stalemate)"' "$f") unstick=$(grep -c '"unstick"' "$f") overflow=$(grep -c '"ui_overflow"' "$f")"
	grep -E '"(stall_dialog|stalemate|godmode_kill|lua_error)"' "$f" | tail -2 | cut -c1-160 | sed 's/^/   /'
}
stat_one mac "$MACD"
stat_one sim "$SIMD"
echo "last runs:"; for r in $(ls -dt "$ROOT"/runs/*-2*/ | sed -n '1,4p'); do echo -n "   $(basename $r): "; [ -f "$r/telemetry.jsonl" ] && python3 "$ROOT/tools/telemetry-summary.py" "$r/telemetry.jsonl" 2>/dev/null | grep -iE 'zones|heartbeat' | head -1 | cut -c1-110 || echo "(live)"; done
echo "loops: $(pgrep -fl soak-forever | grep -c 'bash tools/soak-forever.sh') running"
