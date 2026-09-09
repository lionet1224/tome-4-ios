#!/usr/bin/env bash
# Run every scripted touch test in the simulator; print a PASS/FAIL line per test.
# Two simulators run the halves in parallel: the primary (sim-run.sh's default) and the
# one whose UDID is in tools/touch/sim-b.udid (create with: xcrun simctl create "ToME Plus B" <type> <runtime>).
# Both must have the current build installed (build-engine.sh installs only the primary; the sweep installs B).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${1:-$ROOT/runs/sweep-$(date +%Y%m%d-%H%M%S)}"; mkdir -p "$OUT"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
A="${UDID_A:-94E8BD6E-7084-4F64-8116-2AEC560DFCFC}"
B="${UDID_B:-$(cat "$ROOT/tools/touch/sim-b.udid" 2>/dev/null)}"
[ -n "$SWEEP_SINGLE" ] && B=""   # SWEEP_SINGLE=1: leave the second simulator alone
# SWEEP_SHARD=i/n with SWEEP_SINGLE: run only every n-th test starting at i (two shards
# started at different times on different simulators cover the whole list between them)
shard_i=0; shard_n=1
if [ -n "$SWEEP_SHARD" ]; then shard_i="${SWEEP_SHARD%/*}"; shard_n="${SWEEP_SHARD#*/}"; fi
tests=(); k=0
for t in "$ROOT"/tools/touch/tests/*.lua; do n=$(basename "$t" .lua); case "$n" in mainmenu|loadzoom|stepdiag|settings|grab|fps|talentsoak|autofps) continue;; esac
	if (( k % shard_n == shard_i )); then
		# SWEEP_SKIP_PASSED=<results.txt of an earlier sweep>: leave out what already passed there
		# SWEEP_FROM=<name>: start at that test (alphabetical order), skipping the earlier ones
		# (resume an interrupted sweep: pass its own results.txt as SWEEP_SKIP_PASSED and the same output dir)
		if [ -n "${SWEEP_SKIP_PASSED:-}" ] && grep -qx "PASS $n" "$SWEEP_SKIP_PASSED" 2>/dev/null; then :
		elif [ -n "${SWEEP_FROM:-}" ] && [[ "$n" < "$SWEEP_FROM" ]]; then :
		else tests+=("$t"); fi
	fi; k=$((k+1)); done
run_half() { # $1 = udid, $2.. = tests
	local ud="$1"; shift
	for t in "$@"; do
		local n=$(basename "$t" .lua)
		# title-screen tests declare themselves with "script_boot" in their header: run them in boot mode
		local early=""; grep -q "script_boot" "$t" && early="boot"
		# a "portrait" mention in the test's first three lines runs it in portrait (the worn grid, the band...)
		local extra="${TOUCH_EXTRA:-}"; head -3 "$t" | grep -qi "portrait" && extra="$extra, orientation=\"portrait\""
		UDID="$ud" TOUCH_EXTRA="$extra" bash "$ROOT/tools/touch/sim-run.sh" "$t" "$OUT/$n" $early > "$OUT/$n.txt" 2>&1
		if grep -q "SCRIPT\]\s*finished" "$OUT/$n/console.log" && ! grep -q "Lua Error" "$OUT/$n/console.log"; then echo "PASS $n" >> "$OUT/results.txt"
		else { echo "FAIL $n"; grep -m2 -E "Lua Error|script error|script load failed" -A6 "$OUT/$n/console.log" | cut -c1-200; } >> "$OUT/results.txt"; fi
	done
}
if [ -n "$B" ] && xcrun simctl list devices | grep -q "$B"; then
	xcrun simctl boot "$B" 2>/dev/null; xcrun simctl install "$B" "$ROOT/tools/ios/out/ToME.app" >/dev/null 2>&1
	ta=(); tb=(); i=0
	for t in "${tests[@]}"; do if (( i % 2 == 0 )); then ta+=("$t"); else tb+=("$t"); fi; i=$((i+1)); done
	run_half "$A" "${ta[@]}" & pa=$!
	run_half "$B" "${tb[@]}" & pb=$!
	wait $pa; wait $pb
else
	echo "(single simulator: no sim-b.udid)"
	run_half "$A" "${tests[@]}"
fi
# the last verdict per test wins (a resumed sweep re-runs earlier failures)
grep -E '^(PASS|FAIL) ' "$OUT/results.txt" | awk '{last[$2]=$1} END {for (t in last) print last[t], t}' | sort -k2 > "$OUT/summary.txt"
cat "$OUT/summary.txt"
echo "sweep done: $OUT ($(grep -c '^PASS' "$OUT/summary.txt") pass, $(grep -c '^FAIL' "$OUT/summary.txt") fail)"
