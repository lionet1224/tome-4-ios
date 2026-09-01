---
type: meta
title: "Hot Cache"
updated: 2026-09-01
tags: [meta, hot-cache]
---

# Recent Context

## Last Updated
2026-09-01. **Baseline macOS build achieved** — T-Engine4 1.7.2 + ToME boots to
main menu, native arm64, plain Lua 5.1.

## Current state
- Working tree `~/tome-ios`, all port patches **uncommitted** (see [[build-system]]
  for the full patch table). Run: `./t-engine.app/Contents/MacOS/t-engine` from repo root.
- Brain lives in-repo at `brain/`.

## Active Threads (updated: autonomy session)
- **WAITING ON JORDAN: install Xcode from the App Store** (then open once /
  accept license). Watcher fires the moment the SDK appears; then run
  `tools/ios/all.sh` → ToME in the simulator.
- Branch `ios-port` @ C3. GLES1 layer done + verified by syntax; runtime
  validation needs the sim. Risk list in [[build-system]].

## Old threads
- Verify gameplay (new character, a few dungeon levels) on the baseline.
- Commit baseline patches (needs Jordan's go-ahead; fork repo isn't ours — decide
  where the project repo lives).
- Re-point remote to official `git.net-core.org/tome/t-engine4` when it stops 502ing.
- Next phase: LuaJIT 2.1-rolling upgrade (arm64 + iOS interp), then SDL2-iOS
  Xcode scaffold → [[tome-ios]] plan step 2, [[rendering-boundary]] for the GLES2 shim.
