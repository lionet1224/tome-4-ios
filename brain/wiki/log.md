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
