---
type: resource
title: "Build System"
created: 2026-09-01
tags: [resource, build, toolchain, macos]
---

# Build System

T-Engine4 builds with **premake4** (not premake5-compatible) generating gmake
files. Root `premake4.lua` (solution + platform configs) + `build/te4core.lua`
(all projects) + `build/options.lua` (flags; `--lua` defaults to `jit2`).

## Toolchain we stood up (2026-09-01)

- **premake4 built from source** (github premake/premake-4.x) for arm64 —
  generated `scripts.c` isn't committed, so we stub `builtin_scripts` and always
  pass `--scripts`. Installed in-repo: `tools/premake4/premake4` + `tools/premake4/src`.
- Deps via Homebrew: sdl2, sdl2_image, sdl2_ttf, libpng, libogg, libvorbis.
  OpenAL/OpenGL/Cocoa = system frameworks (both deprecated; still ship).
- **Generate:** `tools/premake4/premake4 --scripts=tools/premake4/src --lua=default gmake`
  (top Makefile lands in **repo root**, project .makes in `build/`)
- **Build:** `make -j8 config=release` from repo root.

## Why `--lua=default` (plain Lua 5.1) for now

Vendored LuaJIT (`src/luajit2`) has no arm64 target (vm_*.dasc: arm/x86/ppc/mips
only; zero `LJ_TARGET_ARM64` refs) → premake errors out on Apple Silicon.
**Tracked task:** upgrade to LuaJIT 2.1-rolling (has arm64 + iOS interp mode) —
needed for iOS regardless. Watch for te4-local LuaJIT patches when swapping.

## Patches applied for modern macOS (all in working tree)

| File | Change |
|---|---|
| `src/tSDL.h` | Apple branch: framework-style `<SDL2_ttf/…>` → Homebrew-style `<SDL2/SDL_ttf.h>` etc. |
| `premake4.lua` | Dropped hardcoded MacOSX10.7 sysroot; Homebrew include/libdirs; `-Wno-implicit-function-declaration -Wno-deprecated-declarations -Wno-deprecated-non-prototype -Wno-incompatible-function-pointer-types -Wno-incompatible-pointer-types -Wno-int-conversion` (new-clang hard errors, legacy vendored code) |
| `build/te4core.lua` | macosx: framework links (SDL2/png/ogg/vorbis) → Homebrew `-l` links; removed dead `../mac/base_app` postbuild (dir not in repo) |
| `src/zlib/zutil.h` | `defined(TARGET_OS_MAC)` classic-MacOS branch misfires on modern Darwin (fdopen→NULL macro breaks SDK stdio); condition now `defined(MACOS)` only — same fix upstream zlib made |

## Runtime fixes (beyond compile)

- **`SDL_GetWindowSurface` vs GL context (`src/main.c` `do_resize`):** modern SDL2
  binds the window to the software renderer on that call, so the subsequent
  `SDL_GL_CreateContext` returned NULL (unchecked) → segfault in `glewInit`→
  `glGetString`. Engine only reads `screen->w/h/format`, so we keep a detached
  `SDL_CreateRGBSurface` mirror instead (`update_screen_surface()`), + NULL-check
  the context. Fix carries to iOS as-is.
- **Must run from an `.app` bundle**: mac `getself.m` returns NSBundle
  resourcePath and `bootstrap/boot.lua` strips 3 path components to find `game/`
  next to the bundle. Bare binary → data path "/" → boot.lua:39 nil error.
  We keep a minimal bundle at repo root: `t-engine.app/Contents/{MacOS/t-engine,
  Info.plist,Resources/}`; `game/` sits beside it.
- Engine log goes to **`/tmp/te4_log.txt`** on mac (`main.c` ~1490), fully
  buffered → empty file on crash. Crash reports: `~/Library/Logs/DiagnosticReports/`.

## Baseline status: ✅ RUNS (2026-09-01)

`cd ~/tome-ios && ./t-engine.app/Contents/MacOS/t-engine` → boot menu loads
(GL context up, max texture 16384, tiles/fonts/music loading, Lua 5.1 VM).

## Gotchas log

- premake4 prints "Generating build/*.make" but writes the **top-level Makefile to
  cwd** — run make from repo root, not build/.
- Old zlib/expat/physfs are all vendored 2010-era; expect more
  hard-error-in-new-clang classes as files compile.

See [[tome-ios]], [[rendering-boundary]].
