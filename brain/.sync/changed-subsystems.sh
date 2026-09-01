#!/usr/bin/env bash
# changed-subsystems.sh — delta detector for re-comprehension.
#
# Diffs the local clone between the last-comprehended SHA and current HEAD and
# prints which subsystems changed, so the comprehension pass only re-reads those
# subsystem pages instead of the whole repo (the "re-comprehend changed
# subsystems" freshness model).
#
# Usage:
#   bash .sync/changed-subsystems.sh          # list changed subsystems since last comprehension
#   bash .sync/changed-subsystems.sh stamp    # mark current HEAD as comprehended (run AFTER updating pages)

set -euo pipefail
export PATH="/opt/homebrew/bin:$PATH"

SYNC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT="$(dirname "$SYNC_DIR")"
SRC="$VAULT/.src"
STATE="$SYNC_DIR/comprehension.json"

[ -d "$SRC/.git" ] || { echo "ERR: no clone at $SRC"; exit 1; }
git -C "$SRC" fetch --quiet origin 2>/dev/null || true
DEFAULT=$(git -C "$SRC" rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's#origin/##' || echo main)
HEAD=$(git -C "$SRC" rev-parse "origin/$DEFAULT" 2>/dev/null || git -C "$SRC" rev-parse HEAD)
[ -f "$STATE" ] || echo '{"last_sha":null}' > "$STATE"

if [ "${1:-}" = "stamp" ]; then
  tmp=$(mktemp); jq --arg s "$HEAD" '.last_sha=$s | .stamped_at=(now|todate)' "$STATE" > "$tmp" && mv "$tmp" "$STATE"
  echo "stamped comprehension watermark at ${HEAD:0:7}"; exit 0
fi

LAST=$(jq -r '.last_sha // empty' "$STATE")
if [ -z "$LAST" ]; then
  echo "INITIAL: no prior comprehension SHA — all subsystems considered current as of full pass."
  echo "Run 'changed-subsystems.sh stamp' once to set the baseline to HEAD (${HEAD:0:7})."
  exit 0
fi

files=$(git -C "$SRC" diff --name-only "$LAST" "$HEAD" 2>/dev/null || true)
if [ -z "$files" ]; then echo "no code changes since ${LAST:0:7} — nothing to re-comprehend."; exit 0; fi

echo "changed ${LAST:0:7}..${HEAD:0:7} — files:"; echo "$files" | sed 's/^/  /'
echo "subsystems needing re-comprehension:"
subs=$(echo "$files" | sed -nE 's#^src/([a-zA-Z]+)/.*#\1#p' | sort -u)
# loose core files count as core
echo "$files" | grep -qE '^src/(registry|explanations)\.ts$|^bin/' && subs=$(printf '%s\ncore\ndata-flow\n' "$subs")
echo "$subs" | sed '/^$/d' | sort -u | sed 's/^/  - /'
