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

## Active Threads (late evening 2026-09-01)
- **World tour on both platforms**: mac AND sim each clear Trollmire → Kor'Pul →
  Norgos' Lair → Scintillating Caves → Rhaloren Camp in ~10 min (plevel 12-13,
  ~400-500 kills, 0 Lua errors). Soak speed ~10× (no move anim, multi-tick/frame).
  Stall classes fixed tonight: stale popup
  cancelling rest, vault door / rock bump-prompts (recurring dialog → first
  button), projectile-in-view spin, sleep effect (pass turns), generic 3s
  self-unstick. Minimap fixed (raw glBindTexture cache desync).
- Harness: SIGKILL by path, telemetry by filename epoch, snapshot scripts.
- Watch next: "Command Staff" dialog recurrence on staff equip; Lua heap growth
  at zone loads; MM-DBG instrumentation still in map.c (remove).

## Earlier (post-C7: AUTOPILOT SOAK LOOP — WORLD TOUR WORKS)
- Mac soak: Trollmire 1-4 → zone_done → worldmap → Ruins of Kor'Pul (wiki order),
  plevel 6, 136 kills, 0 Lua errors. Heap jumps at zone loads, plateaus between.
- Sim: 15-min runs clean; **minimap fixed** (raw glBindTexture calls bypassed the
  tgl cache → made cache-aware), grey band fixed (per-frame clear), rest/vault-door
  loops fixed (stale popup matching; answer Yes to sealed door). MM-DBG
  instrumentation still in map.c (throttled) — remove when convenient.
- Two Claude sessions exist (this one is a fork); the fork owns the repo/soaks.
- Autopilot + telemetry + soak harness landed ([[autopilot-telemetry]]). Mac
  soak reached level 2, 24 kills, talents/equip/chat exercised. Iterating on
  stairs descent; then `tools/soak-sim.sh` on the simulator (bundle rebuilt).
- Run soaks detached (nohup) — background tool tasks get stopped.
- SIM SOAK GREEN: autopilot plays on the simulator (floor 3, plevel 5, 0 Lua
  errors); first telemetry-found iOS bug = ShowPickupFloor overflow.

## Older (post-C6)
- Perf phase next: world gen ~10 min / menu demo sluggish (LuaJIT interp on sim;
  real device should JIT-less-but-faster; consider LuaJIT arm64 device JIT).
- Zoom bug: taps don't register when screen_zoom≠1 despite correct Lua coords.
- Text input: SDL iOS emits no SDL_TEXTINPUT from HID keys with OSK suppressed —
  need native input strategy (part of touch-UI phase).
- idb drives the sim: tap coords = screenshot_px/3 (portrait space).

## Old (post-C5)
- Branch `ios-port` @ C5. ToME's first-run dialog renders in the iPhone 17
  simulator (ES2 fixed-function emu). Rebuild+run: `tools/ios/build-engine.sh`
  then `tools/ios/run-sim.sh`.
- Next: interactive testing (touch input → menu → new character → dungeon);
  expect touch-as-mouse quirks, perf tuning (LuaJIT interp on sim), then the
  touch-UI phase ([[rendering-boundary]] dialog seam).
- Known cut corners: shaderless (effects off), 3D noise textures disabled,
  glGetTexImage clamps unsupported formats, sphere planet untested visually.

## Old threads
- Verify gameplay (new character, a few dungeon levels) on the baseline.
- Commit baseline patches (needs Jordan's go-ahead; fork repo isn't ours — decide
  where the project repo lives).
- Re-point remote to official `git.net-core.org/tome/t-engine4` when it stops 502ing.
- Next phase: LuaJIT 2.1-rolling upgrade (arm64 + iOS interp), then SDL2-iOS
  Xcode scaffold → [[tome-ios]] plan step 2, [[rendering-boundary]] for the GLES2 shim.
