# Routines — ToME-iOS brain

Three cadences keep the brain current with minimal human time. Arm via `/schedule`.
(First do the initial comprehension pass: clone → manifest → per-subsystem fan-out →
brain-only test; see ~/.claude memory "brain-kit" for the methodology.)

## 1. Continuous (daily) — capture + comprehend deltas
> In the ToME-iOS vault at `/Users/jmbrown/tome-ios/brain` (export PATH for `gh`/`jq`):
> 1. `bash .sync/github-sync.sh` — repo-level snapshot.
> 2. `bash .sync/change-capture.sh` — capture newly-merged PRs (payload + diff +
>    back-and-forth score) → `.raw/github/prs/` + `wiki/changes/index.csv`.
> 3. Comprehend each captured PR lacking a `wiki/changes/pr-<n>.md`: read
>    `.raw/github/prs/pr-<n>.{json,diff}`, write the record, prepend to
>    `wiki/changelog.md`, append decisions to `wiki/decisions.md`.
> 4. `bash .sync/changed-subsystems.sh` → re-comprehend the listed subsystem pages
>    from `.src`, then `bash .sync/changed-subsystems.sh stamp`.
> 5. Overwrite `wiki/hot.md` (<500 words). Local only; stop on auth failure.

## 2. Weekly (Monday) — standing digest
> Assemble `wiki/digests/<ISO-week>.md` from `wiki/changes/` records merged in the last
> 7 days (TL;DR · merged-by-subsystem · hot/contentious · decisions · risks · velocity).
> Rank hot PRs with `bash ~/TrewUp-analysis/contention.sh cinornu/t-engine4-i18n_korean --since 7d`.

## 3. On-demand — "review session"
> Ask in this vault: "Build me a review brief for ToME-iOS since I last looked." It
> assembles a digest from records newer than the last digest + runs contention for the gap.
