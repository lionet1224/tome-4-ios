#!/usr/bin/env bash
# Reproduce an archived soak run: restore its savefile and resume the autopilot
# from it. Usage: tools/soak-resume.sh runs/<mac|sim>-<stamp> [minutes]
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNDIR="${1:?runs/<mac|sim>-<stamp>}"; MIN="${2:-10}"
SAVE=$(ls "$RUNDIR/save" 2>/dev/null | head -1)
[ -z "$SAVE" ] && { echo "no archived save in $RUNDIR/save (only abnormal runs archive one)"; exit 1; }
case "$(basename "$RUNDIR")" in
	mac-*) DEST="$HOME/Library/Application Support/T-Engine/4.0/tome/save"; PLAT=mac;;
	sim-*) export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
	       DEST="$(xcrun simctl get_app_container booted org.te4.tome.dev data)/Documents/t-engine/4.0/tome/save"; PLAT=sim;;
	*) echo "unknown platform"; exit 1;;
esac
mkdir -p "$DEST"; rm -rf "$DEST/$SAVE"; cp -R "$RUNDIR/save/$SAVE" "$DEST/"
echo "[resume] restored $SAVE -> $DEST; running $PLAT soak for $MIN min from it"
RESUME="$SAVE" bash "$ROOT/tools/soak-$PLAT.sh" "$MIN"
