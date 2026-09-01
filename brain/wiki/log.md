---
type: meta
title: "Log"
updated: 2026-09-01
tags: [meta, log]
---

# Log

- 2026-09-01 — Brain bootstrapped for ToME-iOS (repo cinornu/t-engine4-i18n_korean). PARA mode. Sync wired.
- 2026-09-01 — Project scoped across three sessions: iOS port of ToME chosen over streaming; RN frontend rejected ([[decisions]]); rendering boundary measured ([[rendering-boundary]]).
- 2026-09-01 — Working tree at `~/tome-ios` (1.0 GB full checkout, engine 1.7.2). premake4 built from source for arm64, installed at `tools/premake4/`. Homebrew deps in.
- 2026-09-01 — Baseline macOS build underway: tSDL.h/premake/te4core/zutil.h/core_lua.c patched for modern clang+Homebrew ([[build-system]]); all vendored static libs compile; engine core in progress.
- 2026-09-01 — **Baseline RUNS.** Two runtime fixes: detached screen surface (SDL_GetWindowSurface × GL context conflict, main.c) + minimal .app bundle at repo root (boot.lua path math). Boot menu loads on arm64/plain Lua 5.1. All patches uncommitted in working tree.
- 2026-09-01 — Autonomy session: C0-C3 committed on branch `ios-port`. LuaJIT 2.1.ROLLING integrated (jit2ext). GLES1 compat layer written + whole core syntax-verified against GLES headers. iOS sim pipeline staged in tools/ios/. BLOCKED on Xcode install (user action); background watcher armed to resume.
- 2026-09-01 — **ToME RENDERS in the iOS simulator** (C5). Pivots en route: modern sims only give ES 2.0 → compat layer became fixed-function-over-ES2 emulation (matrix stacks + pipeline shader in C); stock LuaJIT loadfile is stdio but the whole engine needs physfs-aware loading → ported DarkGod's LuaJIT patch to tools/LuaJIT (lib-only builds now); te4 table.sort field-key extension re-implemented as Lua wrapper in boot.lua; 'bind FBO 0' remapped to SDL's screen FBO (iOS has none); UILaunchScreen for native res; OSK suppressed. First-run online-features dialog renders fully.
- 2026-09-01 — **CHARACTER CREATED & GAME PLAYABLE IN SIMULATOR** (C7). Full touch-driven flow via idb. Fixed en route: Entity.resolve pairs()-order dependence (world-gen crash; generics now resolve last), Birther screen-height clamp + default name, OSK-less text input limitation documented. Known open: clicks dead under screen_zoom≠1; interp-mode world gen ~10min (perf phase pending). Save persists in sim Documents.
