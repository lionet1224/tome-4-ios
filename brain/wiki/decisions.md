---
type: meta
title: "Decisions Log"
updated: 2026-09-01
tags: [meta, decisions, temporal]
---

# Decisions Log

## 2026-09-01 — Native port, not React Native frontend
**Decision:** Port T-Engine4's renderer (GLES2 + fixed-function shim); do NOT build an external
state-consuming frontend (React Native or otherwise).
**Rationale:** Engine has no serializable game state — C loop pushes draw commands via Lua
`display()` callbacks; 155 ToME files create dialogs inline in game logic; an external frontend
still ships the whole C core plus a bridge. Details: [[rendering-boundary]].

## 2026-09-01 — Touch UI at the Lua layer + dialog seam
**Decision:** UI redesign happens in Lua (`engine/ui/*`); optionally swap individual high-traffic
dialogs (inventory, talents, levelup) for native SwiftUI sheets via the `Dialog.lua` choke point.
**Rationale:** Incremental — unported dialogs keep working; Lua iteration is fast and can't
segfault; SwiftUI over RN since iPhone-only and RN needs the same custom bridging anyway.

## 2026-09-01 — Baseline on plain Lua 5.1, LuaJIT upgrade deferred
**Decision:** macOS baseline builds `--lua=default`; upgrade vendored LuaJIT to 2.1-rolling later.
**Rationale:** Vendored LuaJIT predates arm64 (no vm_arm64.dasc). iOS needs modern LuaJIT
(interpreter mode) regardless, so the upgrade is one shared task. See [[build-system]].

## 2026-09-01 — Working off Korean i18n fork temporarily
**Decision:** Track `cinornu/t-engine4-i18n_korean` (engine 1.7.2 + additive translations) until
official `git.net-core.org/tome/t-engine4` recovers from its 502s, then re-point remotes.
**Rationale:** Upstream GitLab down on project day 1; only GitHub mirror pushed since 2016.

## 2026-09-01 — Brain lives in-repo
**Decision:** Knowledge vault at `~/tome-ios/brain/` (inside the working tree), not `~/ToME-iOS-brain`.
**Rationale:** Jordan's call — project and its knowledge base travel together.

ADR-style technical decisions extracted from PRs/commits — direction, not just
mechanics. Maintained by the comprehension pass.

<!-- format:
## YYYY-MM-DD — <title>  (from #N)
**Decision:** ...
**Rationale:** ...
**Affects:** [[subsystem]]
-->
