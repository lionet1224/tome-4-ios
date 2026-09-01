---
type: meta
title: "Decisions Log"
updated: 2026-09-01
tags: [meta, decisions, temporal]
---

# Decisions Log

## 2026-09-01 — ES2 fixed-function emulation (GLES1 unavailable in practice)
**Decision:** The compat layer emulates the fixed-function pipeline over OpenGL ES 2.0
(C matrix stacks + one pos/color/texture shader), replacing the ES 1.1 approach.
**Rationale:** iOS 26 simulators refuse ES1 contexts (SDL silently hands back 2.0 —
verified via GL_VERSION). Emulation keeps engine code untouched and is ALSO the base
needed later for real content shaders. TE4_GLES1 define name kept to avoid churn.

## 2026-09-01 — Maintain DarkGod's LuaJIT physfs patch on modern LuaJIT
**Decision:** tools/LuaJIT carries the physfs loadfile/package patch (lib-only builds).
**Rationale:** The engine's entire load chain (C bootstrap + Lua loader + hooks/addons)
assumes loadfile resolves inside physfs mounts; a Lua-side shim can't cover the C-side
luaL_loadfile calls. Cost: no standalone luajit CLI from that tree; re-apply on updates.

## 2026-09-01 — GLES1-first renderer for the simulator milestone
**Decision:** First iOS boot targets OpenGL ES 1.1 fixed-function (shaderless), not the
GLES2 shim originally sketched.
**Rationale:** Engine GL usage is already ES1-shaped (client arrays + matrix stack, no
glBegin) and carries runtime `shaders_active`/`fbo_active` fallback flags — ES1 keeps the
entire draw path untouched; the compat layer is ~350 lines. GLES2+shaders becomes a later
quality pass (glow/water effects), not a boot blocker.

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
