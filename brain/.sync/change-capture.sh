#!/usr/bin/env bash
# change-capture.sh — temporal capture of merged PRs (the brain's "what changed" backbone).
#
# For each merged PR not yet captured, saves the full PR payload + diff into
# .raw/github/prs/, computes a transparent "back-and-forth" score, derives which
# subsystems it touched, and appends a row to wiki/changes/index.csv. Idempotent:
# a captured-PR watermark (.sync/captured.json) means re-runs only pick up new PRs.
#
# The DETERMINISTIC half of the temporal layer. The LLM half (writing per-PR
# records, changelog, decisions, digest) reads .raw/github/prs/ — see ROUTINE.md.
#
# back_and_forth_score = 2*change_request_rounds + inline_comments
#                        + commits_after_first_review + 0.5*conversation_comments
#
# Read-only on GitHub. Requires: gh (auth), jq.
# Usage: bash .sync/change-capture.sh [OWNER/REPO]

set -euo pipefail
export PATH="/opt/homebrew/bin:$PATH"

SYNC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT="$(dirname "$SYNC_DIR")"
CFG="$SYNC_DIR/sources.json"
REPO="${1:-$(jq -r '.github.repos[0].repo' "$CFG")}"
OUT="$VAULT/.raw/github/prs"
CHG="$VAULT/wiki/changes"
CSV="$CHG/index.csv"
WM="$SYNC_DIR/captured.json"

command -v gh >/dev/null || { echo "ERR: gh not installed"; exit 1; }
command -v jq >/dev/null || { echo "ERR: jq not installed"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "ERR: gh not authenticated"; exit 1; }
[ "$REPO" = "OWNER/REPO" ] && { echo "ERR: edit sources.json — repo is still the placeholder"; exit 1; }

mkdir -p "$OUT" "$CHG"
[ -f "$WM" ]  || echo '{"prs":{},"last_capture_at":null}' > "$WM"
[ -f "$CSV" ] || echo "number,merged_at,author,subsystems,reviews,change_req_rounds,conversation_comments,inline_comments,commits_after_first_review,back_and_forth_score,title,url" > "$CSV"

echo "change-capture: $REPO"
nums=$(gh pr list --repo "$REPO" --state merged --limit 100 --json number --jq '.[].number')
new=0
for n in $nums; do
  [ -n "$(jq -r --arg n "$n" '.prs[$n] // empty' "$WM")" ] && continue
  echo "  capturing #$n"
  pj=$(gh pr view "$n" --repo "$REPO" --json number,title,author,body,createdAt,mergedAt,mergeCommit,additions,deletions,changedFiles,reviews,comments,commits,files,labels,url)
  inline=$(gh api "repos/$REPO/pulls/$n/comments" --jq 'length' 2>/dev/null || echo 0)

  printf '%s' "$pj" > "$OUT/pr-$n.json"
  gh pr diff "$n" --repo "$REPO" > "$OUT/pr-$n.diff" 2>/dev/null || true

  metrics=$(printf '%s' "$pj" | jq -c --argjson inline "$inline" '
    ([.reviews[]?.submittedAt|fromdateiso8601]|min) as $fr
    | { reviews:(.reviews|length),
        change_req:([.reviews[]?|select(.state=="CHANGES_REQUESTED")]|length),
        conv:(.comments|length),
        inline:$inline,
        commits_after:( if $fr then ([.commits[]?|select((.committedDate|fromdateiso8601) > $fr)]|length) else 0 end),
        subsystems:([.files[]?.path | select(startswith("src/")) | split("/")[1]] | unique | join(";")) }
    | .score = (2*.change_req + .inline + .commits_after + (0.5*.conv))
  ')
  printf '%s' "$pj" | jq -r --argjson m "$metrics" '
    [ .number, .mergedAt, (.author.login//""), $m.subsystems, $m.reviews, $m.change_req,
      $m.conv, $m.inline, $m.commits_after, $m.score, .title, .url ] | @csv' >> "$CSV"

  sha=$(printf '%s' "$pj" | jq -r '.mergeCommit.oid // ""')
  tmp=$(mktemp); jq --arg n "$n" --arg sha "$sha" '.prs[$n]=$sha' "$WM" > "$tmp" && mv "$tmp" "$WM"
  new=$((new+1))
done
tmp=$(mktemp); jq --arg t "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '.last_capture_at=$t' "$WM" > "$tmp" && mv "$tmp" "$WM"
echo "done: $new new PR(s) captured → $OUT ; index → $CSV"
