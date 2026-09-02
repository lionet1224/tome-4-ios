#!/usr/bin/env bash
# Soak-test ToME in the iOS simulator with the in-game autopilot.
# Usage: tools/soak-sim.sh [minutes] (default 15). Requires a built ToME.app.
set -uo pipefail
if ! xcrun --sdk iphonesimulator --show-sdk-path >/dev/null 2>&1 && [ -d /Applications/Xcode.app ]; then
	export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MINUTES="${1:-15}"
STAMP="$(date +%Y%m%d-%H%M%S)"
RUN="$ROOT/runs/sim-$STAMP"
BUNDLE_ID=org.te4.tome.dev
mkdir -p "$RUN"; touch "$RUN/.start"

# newest telemetry file that BEGAN after this run started (filename epoch), so a
# still-running older instance can't be mistaken for ours
tele_for_run() { # dir
	local start; start=$(stat -f %m "$RUN/.start")
	ls "$1"/telemetry-*.jsonl 2>/dev/null | while read -r f; do
		local e; e=$(basename "$f" .jsonl); e=${e#telemetry-}
		[ "$e" -ge "$start" ] 2>/dev/null && echo "$f"
	done | sort | tail -1
}

DEV="$(xcrun simctl list devices booted | grep -oE '[0-9A-F-]{36}' | head -1 || true)"
[ -n "$DEV" ] || { echo "no booted simulator"; exit 1; }

SHA="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
DPRE="$(xcrun simctl get_app_container "$DEV" $BUNDLE_ID data 2>/dev/null)"
if [ -n "$DPRE" ]; then
	mkdir -p "$DPRE/Documents/t-engine/4.0/settings"
	printf 'autopilot = true\nautopilot_build = "%s"\n' "$SHA" > "$DPRE/Documents/t-engine/4.0/settings/autopilot.cfg"
	trap 'rm -f "$DPRE/Documents/t-engine/4.0/settings/autopilot.cfg"' EXIT
fi

echo "[soak-sim] $MINUTES min run, build $SHA -> $RUN"
xcrun simctl terminate "$DEV" $BUNDLE_ID 2>/dev/null
# install the current bundle (data container + settings persist across installs)
xcrun simctl install "$DEV" "$ROOT/tools/ios/out/ToME.app" || { echo "install failed"; exit 1; }
xcrun simctl launch --console-pty "$DEV" $BUNDLE_ID --flush-stdout > "$RUN/console.log" 2>&1 &
LPID=$!

D0="$(xcrun simctl get_app_container "$DEV" $BUNDLE_ID data 2>/dev/null)"
SECS=$((MINUTES * 60))
HUNG=""
sleep 20  # let the app come up before judging liveness
for i in $(seq 1 "$SECS"); do
	pgrep -f 'ToME.app/t-engine' >/dev/null 2>&1 || { echo "[soak-sim] app exited"; break; }
	if [ $((i % 60)) -eq 0 ]; then
		xcrun simctl io "$DEV" screenshot "$RUN/periodic-$i.png" >/dev/null 2>&1
	fi
	if [ $((i % 30)) -eq 0 ] && [ -n "$D0" ]; then
		TELE="$(tele_for_run "$D0/Documents/t-engine/4.0/tome/autopilot")"
		if [ -n "$TELE" ]; then
			AGE=$(( $(date +%s) - $(stat -f %m "$TELE") ))
			if [ "$AGE" -gt 120 ]; then echo "[soak-sim] HUNG: telemetry stale ${AGE}s"; HUNG=1; break; fi
			if grep -q '"session_end"' "$TELE"; then echo "[soak-sim] autopilot ended the run"; break; fi
		fi
	fi
	sleep 1
done
find "$HOME/Library/Logs/DiagnosticReports" -name 't-engine-*.ips' -newer "$RUN/.start" -exec cp {} "$RUN/" \; 2>/dev/null
[ -n "${HUNG:-}" ] && echo "[soak-sim] run ended HUNG"
xcrun simctl io "$DEV" screenshot "$RUN/final.png" >/dev/null 2>&1
xcrun simctl terminate "$DEV" $BUNDLE_ID 2>/dev/null
sleep 2

D="$(xcrun simctl get_app_container "$DEV" $BUNDLE_ID data 2>/dev/null)"
if [ -n "$D" ]; then
	TELE="$(tele_for_run "$D/Documents/t-engine/4.0/tome/autopilot")"
	[ -n "${TELE:-}" ] && cp "$TELE" "$RUN/telemetry.jsonl" || echo "[soak-sim] no telemetry from this run"
	ls "$D/Documents/t-engine/4.0/tome/error-logs/"*/*.txt 2>/dev/null | tail -3 | while read -r f; do cp "$f" "$RUN/"; done
fi
mkdir -p "$RUN/shots"; [ -n "$D" ] && find "$D/Documents/t-engine/4.0/tome/screenshots" -name '*.png' -newer "$RUN/.start" -exec mv {} "$RUN/shots/" \; 2>/dev/null

python3 "$ROOT/tools/telemetry-summary.py" "$RUN/telemetry.jsonl" "$RUN/console.log" 2>/dev/null || true
echo "[soak-sim] artifacts in $RUN"
