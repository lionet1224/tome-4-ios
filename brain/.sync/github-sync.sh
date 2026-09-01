#!/usr/bin/env bash
# github-sync.sh — read-only GitHub delta pull for the TrewUp brain.
#
# Pulls repo metadata, file tree, top-level docs, merged PRs and open issues
# SINCE the last sync, and drops timestamped Markdown into .raw/github/ for the
# wiki-ingest step to turn into wiki pages.
#
# Read-only: uses only `gh` GET calls. Never writes to GitHub.
#
# Requires: gh (authenticated — `gh auth status`), jq.
# Usage:    bash .sync/github-sync.sh
#
# UNTESTED until GitHub access lands — verify the first run by eye.

set -euo pipefail

SYNC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT="$(dirname "$SYNC_DIR")"
CFG="$SYNC_DIR/sources.json"
OUT="$VAULT/.raw/github"
STAMP="$(date -u +%Y-%m-%dT%H-%M-%SZ)"

command -v gh >/dev/null || { echo "ERR: gh not installed"; exit 1; }
command -v jq >/dev/null || { echo "ERR: jq not installed"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "ERR: gh not authenticated (run: gh auth login)"; exit 1; }

mkdir -p "$OUT"

repo_count=$(jq '.github.repos | length' "$CFG")
echo "GitHub sync: $repo_count repo(s) at $STAMP"

for i in $(seq 0 $((repo_count - 1))); do
  REPO=$(jq -r ".github.repos[$i].repo" "$CFG")
  BRANCH=$(jq -r ".github.repos[$i].default_branch // \"main\"" "$CFG")
  LAST=$(jq -r ".github.repos[$i].last_sync // empty" "$CFG")
  SINCE="${LAST:-1970-01-01T00:00:00Z}"
  slug="${REPO//\//__}"
  dest="$OUT/${slug}__${STAMP}.md"

  [ "$REPO" = "OWNER/REPO" ] && { echo "  SKIP placeholder repo — edit sources.json"; continue; }
  echo "  → $REPO (branch $BRANCH, since $SINCE)"

  {
    echo "# GitHub sync: $REPO"
    echo "_synced: $STAMP — delta since: ${SINCE}_"
    echo

    echo "## Repository metadata"
    echo '```json'
    gh api "repos/$REPO" --jq '{name,description,visibility,default_branch,language,pushed_at,topics,size}'
    echo '```'
    echo

    echo "## File tree (recursive, default branch)"
    echo '```'
    gh api "repos/$REPO/git/trees/$BRANCH?recursive=1" \
      --jq '.tree[] | select(.type=="blob") | .path' 2>/dev/null | sort || echo "(tree unavailable)"
    echo '```'
    echo

    echo "## Top-level docs"
    # Discover actual top-level doc files rather than assuming README.md — engagement
    # repos use varied conventions (ROADMAP.md, ARCHITECTURE.md, CLAUDE.md, etc.).
    DOC_CAP=15
    docs=$(gh api "repos/$REPO/contents" \
            --jq '.[] | select(.type=="file") | .name' 2>/dev/null \
            | grep -iE '\.(md|mdx|rst|txt)$' || true)
    total=$(printf '%s\n' "$docs" | grep -c . || true)
    echo "_found ${total} top-level doc file(s); including up to ${DOC_CAP}_"
    echo
    n=0
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      n=$((n+1))
      if [ "$n" -gt "$DOC_CAP" ]; then
        echo "_…and $((total - DOC_CAP)) more not included (raise DOC_CAP to capture)_"; echo; break
      fi
      content=$(gh api "repos/$REPO/contents/$f" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null || true)
      [ -n "$content" ] && { echo "### $f"; echo '```markdown'; echo "$content"; echo '```'; echo; }
    done <<< "$docs"

    # ── PR velocity (dev-velocity debugging: which PRs were slow to review & why) ──
    SLOW_N=5         # how many slowest PRs to attach discussion for
    COMMENT_CAP=25   # max comments per PR in the "why" section (truncation logged)
    # One rich pull; metrics + discussion are both computed from this payload.
    PRJSON=$(gh pr list --repo "$REPO" --state merged --limit 100 \
      --search "merged:>=${SINCE%%T*}" \
      --json number,title,author,createdAt,mergedAt,additions,deletions,changedFiles,reviews,comments,labels,url \
      2>/dev/null || echo '[]')

    echo "## PR velocity — merged since $SINCE"
    echo "_Ranked slowest→fastest by time-to-merge. Durations in hours. TTFR = time to first review; chg-req = CHANGES_REQUESTED cycles._"
    echo
    echo "| PR | Title | ±lines | files | reviews | chg-req | TTFR h | TTmerge h | reviewers |"
    echo "|----|-------|--------|-------|---------|---------|--------|-----------|-----------|"
    echo "$PRJSON" | jq -r '
      def hrs($a;$b): if $a==null or $b==null then "—" else (($b-$a)/360|floor)/10 end;
      map(
        (.createdAt|fromdateiso8601) as $c
        | (.mergedAt|fromdateiso8601) as $m
        | ([.reviews[]?.submittedAt | fromdateiso8601] | min) as $fr
        | { n:.number, t:(.title//""),
            size:((.additions//0)+(.deletions//0)), files:(.changedFiles//0),
            nrev:(.reviews|length),
            chg:([.reviews[]?|select(.state=="CHANGES_REQUESTED")]|length),
            ttfr:hrs($c;$fr), ttm:hrs($c;$m), _s:(if $m and $c then $m-$c else 0 end),
            revs:([.reviews[]?.author.login]|unique|join(",")) }
      )
      | sort_by(._s) | reverse
      | .[] | "| #\(.n) | \(.t[0:46]) | \(.size) | \(.files) | \(.nrev) | \(.chg) | \(.ttfr) | \(.ttm) | \(.revs) |"
    ' 2>/dev/null || echo "| (none / unavailable) | | | | | | | | |"
    echo

    echo "### Slowest PRs — discussion (the 'why')"
    echo
    echo "$PRJSON" | jq -r --argjson topn "$SLOW_N" --argjson ccap "$COMMENT_CAP" '
      def hrs($a;$b): if $a==null or $b==null then "—" else (($b-$a)/360|floor)/10 end;
      map( (.createdAt|fromdateiso8601) as $c | (.mergedAt|fromdateiso8601) as $m
           | . + {_s:(if $m and $c then $m-$c else 0 end), _ttm:hrs($c;$m)} )
      | sort_by(._s) | reverse | .[0:$topn] | .[]
      | "#### #\(.number) \(.title//"") — TTmerge \(._ttm)h · \([.reviews[]?|select(.state=="CHANGES_REQUESTED")]|length) change-request cycle(s) · \(.author.login) → \([.reviews[]?.author.login]|unique|join(", "))",
        "",
        "_Review timeline:_",
        ( ([.reviews[]? | "- \(.submittedAt) — @\(.author.login) **\(.state)**" + (if ((.body//"")|length)>0 then ": " + ((.body)|gsub("[\r\n]+";" ")|.[0:240]) else "" end)] | if length>0 then . else ["- (no formal reviews recorded)"] end) | .[] ),
        "",
        "_Comments (\(.comments|length)):_",
        ( [ .comments[0:$ccap][]? | "- \(.createdAt) — @\(.author.login): " + ((.body//"")|gsub("[\r\n]+";" ")|.[0:240]) ] | if length>0 then . else ["- (none)"] end | .[] ),
        (if (.comments|length) > $ccap then "_…\((.comments|length) - $ccap) more comments not included (raise COMMENT_CAP)_" else empty end),
        ""
    ' 2>/dev/null || echo "(no PR discussion available)"
    echo

    echo "## Open issues"
    gh issue list --repo "$REPO" --state open --limit 100 \
      --json number,title,author,labels,url \
      --jq '.[] | "- #\(.number) \(.title) — @\(.author.login) — \(.url)"' 2>/dev/null \
      || echo "(none / unavailable)"
  } > "$dest"

  echo "    wrote $dest"
  # Stamp last_sync for this repo (atomic via temp file)
  tmp=$(mktemp)
  jq ".github.repos[$i].last_sync = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" "$CFG" > "$tmp" && mv "$tmp" "$CFG"
done

echo "Done. Next: ingest .raw/github/ into the wiki (see .sync/ROUTINE.md)."
