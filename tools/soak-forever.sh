#!/usr/bin/env bash
# Run soak-<platform>.sh back to back until killed. Each iteration re-snapshots
# the harness so fixes committed meanwhile take effect on the next run.
# Usage: tools/soak-forever.sh mac|sim [minutes]   (stop: pkill -f soak-forever)
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLAT="${1:?mac|sim}"; MIN="${2:-30}"
while true; do
	cp "$ROOT/tools/soak-$PLAT.sh" "$ROOT/runs/.soak-$PLAT-snapshot.sh"
	bash "$ROOT/runs/.soak-$PLAT-snapshot.sh" "$MIN"
	echo "[forever] $PLAT run ended $(date +%H:%M:%S); relaunching in 5s"
	sleep 5
done
