#!/usr/bin/env bash
# Soak-test ToME on macOS with the in-game autopilot.
# Usage: tools/soak-mac.sh [minutes] (default 10)
# Archives console log + telemetry into runs/<timestamp>/ and prints a summary.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MINUTES="${1:-10}"
STAMP="$(date +%Y%m%d-%H%M%S)"
RUN="$ROOT/runs/mac-$STAMP"
HOME_TE="$HOME/Library/Application Support/T-Engine/4.0"
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

SHA="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
# module Lua can't see env vars; enable via settings file
mkdir -p "$HOME_TE/settings"
printf 'autopilot = true\nautopilot_build = "%s"\n' "$SHA" > "$HOME_TE/settings/autopilot.cfg"
[ -n "${RESUME:-}" ] && printf 'autopilot_resume = "%s"\n' "$RESUME" >> "$HOME_TE/settings/autopilot.cfg" && echo "[soak] resuming save $RESUME"
trap 'rm -f "$HOME_TE/settings/autopilot.cfg"' EXIT
export TE4_BUILD_SHA="$SHA"
# AddressSanitizer build (premake --asan): report to $RUN/asan.<pid>, abort on first error
# libmalloc debug (no dyld interposition needed, unlike ASan which trips SDL's
# dynapi guard): scribble freed/allocated memory, guard pages around blocks
export MallocScribble=1 MallocPreScribble=1 MallocGuardEdges=1 MallocCheckHeapStart=1000 MallocCheckHeapEach=5000
export ASAN_OPTIONS="abort_on_error=1:halt_on_error=1:detect_leaks=0:log_path=$RUN/asan:print_stats=0"

echo "[soak] $MINUTES min run, build $SHA -> $RUN"
pkill -9 -f "MacOS/t-engine" 2>/dev/null; sleep 1  # SIGKILL: the engine ignores TERM. mac binary only (launched by relative path); the sim app is ToME.app/t-engine

( cd "$ROOT" && ./t-engine.app/Contents/MacOS/t-engine --flush-stdout ) &
PID=$!

SECS=$((MINUTES * 60))
HUNG=""
for i in $(seq 1 "$SECS"); do
	kill -0 "$PID" 2>/dev/null || break
	if [ $((i % 30)) -eq 0 ]; then
		TELE="$(tele_for_run "$HOME_TE/tome/autopilot")"
		if [ -n "$TELE" ]; then
			AGE=$(( $(date +%s) - $(stat -f %m "$TELE") ))
			if [ "$AGE" -gt 120 ]; then echo "[soak] HUNG: telemetry stale ${AGE}s"; HUNG=1; break; fi
		elif [ "$i" -ge 180 ]; then echo "[soak] HUNG: no telemetry ${i}s after launch"; HUNG=1; break
			if grep -q '"session_end"' "$TELE"; then echo "[soak] autopilot ended the run"; pkill -9 -f "MacOS/t-engine"; break; fi
		fi
	fi
	sleep 1
done
if kill -0 "$PID" 2>/dev/null; then
	echo "[soak] time up, stopping"
	pkill -f "MacOS/t-engine" 2>/dev/null   # the engine itself, not just the subshell
	kill "$PID" 2>/dev/null
	sleep 2
	pkill -9 -f "MacOS/t-engine" 2>/dev/null
	kill -9 "$PID" 2>/dev/null
	EXIT="timeout"
else
	wait "$PID"; EXIT="exited($?)"
fi

cp /tmp/te4_log.txt "$RUN/console.log" 2>/dev/null
# newest telemetry file from this run
TELE="$(tele_for_run "$HOME_TE/tome/autopilot")"
[ -n "${TELE:-}" ] && cp "$TELE" "$RUN/telemetry.jsonl" || echo "[soak] no telemetry from this run"
ls "$HOME_TE"/tome/error-logs/*/*.txt 2>/dev/null | tail -3 | while read -r f; do cp "$f" "$RUN/"; done

# the run's savefile: archived when the run ended abnormally (repro with
# tools/soak-resume.sh), always removed from the engine dir (disk)
SAVE=$(grep -oE '"save":"[^"]*"' "$RUN/telemetry.jsonl" 2>/dev/null | tail -1 | cut -d'"' -f4 | tr 'A-Z' 'a-z' | sed 's/[^a-z0-9_.]/_/g')
if [ -n "$SAVE" ] && [ -d "$HOME_TE/tome/save/$SAVE" ]; then
	case "$EXIT" in timeout|"exited(0)") ;; *) mkdir -p "$RUN/save"; cp -R "$HOME_TE/tome/save/$SAVE" "$RUN/save/" && echo "[soak] save archived: $SAVE";; esac
	rm -rf "$HOME_TE/tome/save/$SAVE" "$HOME_TE/tome/save/$SAVE.quickbirth"
fi
# in-game screenshots taken by the autopilot every 60s
mkdir -p "$RUN/shots"; find "$HOME_TE/tome/screenshots" -name '*.png' -newer "$RUN/.start" -exec mv {} "$RUN/shots/" \; 2>/dev/null
# harvest crash reports from the run window
sleep 4  # the .ips lands a few seconds after the crash
find "$HOME/Library/Logs/DiagnosticReports" -name 't-engine-*.ips' -newer "$RUN/.start" -exec cp {} "$RUN/" \; 2>/dev/null
[ -n "${HUNG:-}" ] && EXIT="HUNG(telemetry stale)"
echo "[soak] finished: $EXIT"
python3 "$ROOT/tools/telemetry-summary.py" "$RUN/telemetry.jsonl" "$RUN/console.log" 2>/dev/null || true
echo "[soak] artifacts in $RUN"
