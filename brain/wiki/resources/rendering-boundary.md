---
type: resource
title: "Rendering Boundary"
created: 2026-09-01
tags: [resource, architecture, rendering, ios]
---

# Rendering Boundary (the port surface)

Measured 2026-09-01 on engine 1.7.2 source. This page answers: *where can we swap
the renderer, and what contract must we honor?*

## Three layers

1. **C core** (`src/`) — SDL2 + desktop OpenGL + Lua VM + physfs. Only layer that
   touches GL.
2. **Lua engine layer** (`game/engines/default/engine/`) — Map display, `Dialog.lua`,
   `ui/` widget toolkit, particles wrappers. Ships with engine, calls C core.
3. **ToME module** (`game/modules/tome/`) — 2,169 Lua files / ~442k lines. Pure
   Lua + data. Never draws directly.

## The contract

- 16 `core.*` Lua modules registered in C: display, map, particles, shader, game,
  key, mouse, fov, noise, sound, profile, serial, wait, zlib, discord, webview.
- ~106 Lua-facing functions on the render path (display/map/particles regs).
- Plus GL-flavored Lua helpers: `glTranslate`/`glScale`/`glMatrix`/`glScissor`,
  `surface:glTexture()` (57 uses in engine Lua) — implement as matrix ops.

## GL usage in C (why porting is tractable)

- ~350 GL call sites in six files: `core_lua.c` (157), `map.c` (73), `shaders.c`
  (30), `noise.c` (22), `main.c` (21), `particles.c` (16).
- **No `glBegin` immediate mode.** Client-side vertex arrays
  (`glVertexPointer`/`glTexCoordPointer`/`glColorPointer`, ~70 sites) + matrix
  stack (`glMatrixMode`, `glOrtho`). GLES1-shaped.
- GLEW vendored/static; content GLSL shaders exist (need ES precision/#version
  tweaks).

## Frame model — who initiates

Immediate-mode push: C main loop fires Lua `display()`/`tick()` callbacks
(`src/main.c:663`, `:628`); Lua walks live objects and issues draw calls. **There
is no serializable game-state snapshot** — map scroll/visibility state lives
C-side in `core.map`. A custom renderer = custom *backend* for the engine's
command stream, not a frontend over data.

## Why not React Native / external frontend (2026-09-01)

- 155 ToME files instantiate dialogs *inline in game logic* (e.g.
  `class/Game.lua:1149` pops yes/no mid-flow). UI is game logic, not a shell.
- Bridging every flow to JS = reimplementing hundreds of interactions; breaks on
  every patch/addon; still ships the whole C core anyway.

## Chosen strategy

- **World rendering:** GLES2 + fixed-function shim (matrix-stack emulation + one
  default shader consuming the vertex arrays). Alternative kept in pocket:
  MetalANGLE.
- **Touch UI:** Lua layer (`engine/ui/*`) is the fast-iteration zone; the
  **dialog seam** (`Dialog.lua` choke point) allows swapping whole screens for
  native SwiftUI sheets incrementally — unported dialogs keep working.

See [[tome-ios]] for plan of record, [[build-system]] for toolchain.
