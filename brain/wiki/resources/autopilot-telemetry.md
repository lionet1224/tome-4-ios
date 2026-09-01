---
type: resource
title: "Autopilot & Telemetry"
created: 2026-09-01
tags: [resource, testing, autopilot, telemetry, soak]
---

# Autopilot & Telemetry (the test loop)

Goal: test faster than a human can tap. An in-game Lua player soaks the game
headlessly on macOS (fast: no install, JIT Lua, ~3 min/iteration) and on the
iOS simulator (slow, but exercises GL/input/physfs/OpenAL). Same code both.

## Pieces
- `game/modules/tome/class/AutoPilot.lua` — policy + telemetry. Hooked from
  tome `Game:display` (every frame → `AutoPilot.frame()`), wraps `Player.act`,
  `Actor.die` (kills + god-mode cheat-death), `Game.tick` (tick counter).
- Auto-start: boot `MainMenu` triggers New Game; tome `Birther` picks first
  race/subrace/class/subclass + `atEnd("created")`; name defaults "Adventurer".
- Harness: `tools/soak-mac.sh N` / `tools/soak-sim.sh N` → `runs/<ts>/`
  (console.log, telemetry.jsonl, error-logs, crash .ips, sim screenshots) +
  `tools/telemetry-summary.py`. Run soaks **detached** (`nohup … & disown`) —
  Claude Code background tasks get stopped and take children with them.
- Enable via **settings file** `settings/autopilot.cfg` (`autopilot = true`,
  `autopilot_build = "sha"`, optional `autopilot_mortal = true`). Env vars do
  NOT reach module Lua (sandboxed `os`). Harness writes/removes the cfg.
- Telemetry lands in **`4.0/tome/autopilot/telemetry-<ts>.jsonl`** (physfs
  write dir is per-module, not 4.0 root). Mac: `~/Library/Application Support/
  T-Engine/4.0/tome/autopilot/`; sim: app container `Documents/t-engine/4.0/tome/`.

## Policy (v2)
fight (50% real talents via `useTalent(tid,nil,nil,nil,target)`, else bump) →
spend levelup points (`incStat`, `learnTalent(id,true)`, then zero leftovers) →
sustains up → rest <70% → pickup at feet → equip-churn every 40 acts (remove→
wear→restore-on-fail, same order as `doWear`) → `autoExplore()` until it
returns false / no clock progress ×3 / 800 acts → unvisited store (bump tile;
dialog: buy one, sell one, leave) → in-zone downstairs (`change_level>0`, no
`change_zone`) → `CHANGE_LEVEL` virtual key → worldmap: nearest entrance in
wiki progression order (`_M.PROGRESSION`). Dialogs: Chat → random answer;
GetQuantity → okclick; everything else EXIT — except "Running…" while a run is
live (dismissing it *stops the run*; dismiss only when stale).

## Traps found by the soak loop (all fixed in C7+)
1. `table.sort` shim in bootstrap/boot.lua never loads on desktop → moved to
   `game/loader/init.lua`.
2. **Headless idle**: C main loop stops calling Lua `tick()` when no SDL input
   events arrive (`tickPaused`); `frame()` now calls `game:tick()` itself
   (engine comment says this is legit).
3. Turn-based semantics: `game.paused` is NOT the awaiting-input state you'd
   expect; drive via `p:act()` from frame + tick drive.
4. `LevelupDialog` EXIT with changed counters → "accept changes?" 3-way
   confirm whose cancel loops forever → never touch points inside the dialog.
5. `creating_player` clears only in the intro ShowText's `on_exit` — ok as long
   as dialogs are EXITed (ShowText EXIT runs the callback).
6. `game.player` is a dead placeholder during load → death check only after
   first real act (`state.ingame`).
7. Stale "Running…" popup lingers after a run ends → dialogs>0 → deadlock.

## Telemetry events
session_start, heartbeat(life, plevel, kills, acts, mem_kb), guard (debug),
kill, would_have_died, use_talent, sustain_on, spend_stat, learn_talent,
equip, pickup, store_visit/buy/sell, chat_answer, dialog_dismiss(title),
ui_overflow(dialog geometry vs screen), zone_change, level_explored,
take_stairs, enter_zone, world_tour_complete, stalled, stuck, death,
autopilot_error. Summary tool prints turns/sec, heap trend, zones, deaths.

## Known gaps / next
- Item *activation* (wands/charms) not automated: can enter targeting mode
  (not a dialog) — needs an escape strategy.
- Sim soak not yet run green; then per-platform diffs are the interesting bugs.
- Mac perf: turns/sec metric is game-turn/10 units; compare mac vs sim.
