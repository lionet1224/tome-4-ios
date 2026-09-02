#!/usr/bin/env bash
# Run soak-<platform>.sh back to back until killed. Each iteration re-snapshots
# the harness so fixes committed meanwhile take effect on the next run.
# Usage: tools/soak-forever.sh mac|sim [minutes]   (stop: pkill -f soak-forever)
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLAT="${1:?mac|sim}"; MIN="${2:-30}"
while true; do
	cp "$ROOT/tools/soak-$PLAT.sh" "$ROOT/runs/.soak-$PLAT-snapshot.sh"
	T0=$(date +%s)
	bash "$ROOT/runs/.soak-$PLAT-snapshot.sh" "$MIN"
	DUR=$(( $(date +%s) - T0 ))
	FREE_MB=$(df -m "$ROOT" | awk 'NR==2{print $4}')
	if [ "$FREE_MB" -lt 1000 ]; then echo "[forever] only ${FREE_MB}MB free: stopping"; break; fi
	if [ "$DUR" -lt 90 ]; then echo "[forever] $PLAT run died after ${DUR}s; backing off 120s"; sleep 120; else sleep 5; fi
	echo "[forever] $PLAT run ended $(date +%H:%M:%S); relaunching"
	# retention: PNGs only for the 6 newest runs, console logs capped at 20MB
	ls -dt "$ROOT"/runs/*/ | tail -n +7 | while read -r d; do rm -f "$d"/shots/*.png "$d"/periodic-*.png; done
	for c in "$ROOT"/runs/*/console.log; do [ "$(stat -f %z "$c")" -gt 20000000 ] && tail -c 20000000 "$c" > "$c.tmp" && mv "$c.tmp" "$c"; done
done
