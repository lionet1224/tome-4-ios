# .sync — code/infra feeds for the TrewUp brain

This folder turns the vault into a *living* knowledge base by pulling from
GitHub and AWS on a schedule. Everything here is **read-only** against the
source systems.

## Files

| File | What it does |
|------|--------------|
| `sources.json` | Config: which repo(s), which AWS account/profile/regions, and `last_sync` watermarks. **Edit this first.** |
| `github-sync.sh` | Read-only `gh` delta pull → timestamped Markdown in `.raw/github/`. |
| `aws-sync.sh` | Read-only `aws` inventory snapshot → timestamped Markdown in `.raw/aws/`. |
| `ROUTINE.md` | The daily scheduled-agent spec. Staged, not armed (no access yet). |

## Flow

```
sources.json ──▶ github-sync.sh ─┐
                                 ├─▶ .raw/  ──▶ /wiki-ingest ──▶ wiki/resources/{codebase-map, aws-infra-map}
sources.json ──▶ aws-sync.sh  ───┘
```

The sync scripts only *fetch raw data*. The `wiki-ingest` skill (run by you or by
the scheduled routine) is what turns raw data into cross-linked wiki pages.

## Status: SCAFFOLD ONLY (no access yet)

- Placeholders in `sources.json` (`OWNER/REPO`, `PLACEHOLDER_ACCOUNT_ID`).
- Scripts are written but **untested** — verify the first real run by eye.
- Routine is staged in `ROUTINE.md`, not scheduled.

## Confidentiality

- Vault is local Markdown. Keep it that way for the engagement.
- Web-egress skills (autoresearch, defuddle) are **off** — don't invoke them here.
- Use a **read-only** AWS role and a least-privilege GitHub token.
- The AWS script lists Secrets Manager / SSM *names* only, never values.
- If you put this vault under git, confirm `.raw/` handling fits the engagement's
  data-handling agreement before pushing anywhere.
