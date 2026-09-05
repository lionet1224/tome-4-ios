#!/usr/bin/env bash
# Run every scripted touch test in the simulator, one after another; print a PASS/FAIL line per test.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${1:-$ROOT/runs/sweep-$(date +%Y%m%d-%H%M%S)}"; mkdir -p "$OUT"
for t in "$ROOT"/tools/touch/tests/*.lua; do
	n=$(basename "$t" .lua)
	case "$n" in mainmenu|loadzoom|stepdiag|settings) continue;; esac
	bash "$ROOT/tools/touch/sim-run.sh" "$t" "$OUT/$n" > "$OUT/$n.txt" 2>&1
	if grep -q "SCRIPT\]\s*finished" "$OUT/$n/console.log" && ! grep -q "Lua Error" "$OUT/$n/console.log"; then echo "PASS $n"
	else echo "FAIL $n"; grep -m2 -E "Lua Error|script error|script load failed" -A6 "$OUT/$n/console.log" | cut -c1-200; fi
done
echo "sweep done: $OUT"
