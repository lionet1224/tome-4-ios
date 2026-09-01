#!/usr/bin/env bash
# One-shot: deps -> engine -> simulator. Run this once Xcode is installed.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$HERE/build-deps.sh"
bash "$HERE/build-engine.sh"
bash "$HERE/run-sim.sh"
