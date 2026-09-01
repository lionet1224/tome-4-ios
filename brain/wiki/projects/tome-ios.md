---
type: project
title: "ToME-iOS"
status: active
created: 2026-09-01
tags: [project, ios, port, game]
---

# ToME-iOS

Port Tales of Maj'Eyal (T-Engine4, GPL-3) to iPhone for personal sideloaded use —
**not** App Store distribution. Jordan's project; UI redesign for touch is part of
the goal, not a chore.

## Plan of record

1. **Baseline macOS build** (in progress) — build T-Engine4 1.7.2 from source on
   the arm64 Mac, run ToME natively. Validates toolchain before iOS work.
2. **iOS scaffold** — SDL2 iOS Xcode project, engine C core compiled for arm64
   iOS, LuaJIT in interpreter mode (no W^X on iOS), physfs data loading.
3. **Renderer** — GLES2 + small fixed-function shim (matrix stack emulation +
   default shader for client vertex arrays). See [[rendering-boundary]].
4. **Touch UI** — Lua-layer work (engine/ui widgets) + optional native SwiftUI
   sheets via the dialog seam. NOT React Native (see [[decisions|Decisions]]).
5. **Sideload** — free Apple ID (7-day resign) or AltStore/SideStore refresh.

## Tracking
- Repo: `cinornu/t-engine4-i18n_korean` (**temporary** — official upstream
  `git.net-core.org/tome/t-engine4` was 502 on 2026-09-01; re-point remote when
  it recovers. Fork = engine 1.7.2 + additive Korean i18n.)
- Working tree: `~/tome-ios` (brain lives in-repo at `brain/`)
- Living maps: [[codebase-map]], [[build-system]], [[rendering-boundary]]

## Key constraints
- GPL-3: personal sideloading fine; no App Store intent.
- Vendored LuaJIT has **no arm64 target** → baseline uses plain Lua 5.1
  (`--lua=default`); LuaJIT 2.1-rolling upgrade is a tracked task (needed for iOS).
- CEF webview + Discord + Steam integrations: stub/skip on iOS.

## Sync
- `bash .sync/github-sync.sh` → `.raw/github/` → `/wiki-ingest` → [[codebase-map]]
