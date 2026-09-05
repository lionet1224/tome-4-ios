---
type: design
title: "Touch UI"
updated: 2026-09-02
tags: [ios, ui, touch, design]
---

# Touch UI — inventory, design, gaps

## 1. What exists today (2026-09-02, commit 22287997)

### Rendering
- Native pixels, `screen_zoom = 2`, `font_scale = 150` (engine/init.lua under `__IOS__`).
- Logical screen on a Plus phone: 1398x645. Dialog clamp (10/40 px) + reverse hit-test
  (topmost element wins). GL scissor / readPixels scaled by zoom.

### Gestures (engine/Mouse.lua on top of SDL touch-as-mouse; ToME map zone in class/Game.lua)
| Gesture | Where | Does |
|---|---|---|
| tap | everywhere | left click (SDL emulation) |
| drag | map | pan the camera; click on release swallowed |
| drag | dialogs | hover-scrub (tooltips follow the finger) |
| hold 450 ms, release | everywhere | right click (Actions menu on map; item/talent menus in dialogs) |
| hold 450 ms, then drag | map | hover-scrub without panning/acting; tooltip stays after lift |
| two-finger tap | everywhere | Escape (EXIT keybind of the current key handler) |
| pinch | map | zoom (secondary; buttons preferred) |
| tap outside a dialog | dialogs | closes it (engine catch-all zone) |
| finger-up after a tap | everywhere | cursor parked off-screen (no hover tooltips) |

### On-screen controls
- Touch row (Minimalist toolbar, bottom-right, finger sized): Rest, Explore, Pick up,
  Level, Char, Z+, Z-. Entries carry `key=` (virtual keybind) or `fct=`.
- Stock toolbar icons: inventory, talents, quest log, lore, main menu, padlock.
- Close box (X) on every dialog frame.
- Hotbar: 12 slots, tap to use (SDL click).
- iOS keyboard shown while a text box has focus.

### Verification
- `tools/ios/simtest.sh` (15 checks) drives all of the above except pinch/two-finger.

## 2. Proposal: make it a first-class layer instead of mouse emulation + patches

Keep SDL's touch-as-mouse for the long tail (every existing click just works), but
put a single **TouchInput** object in front of it that owns gesture state and a
**TouchBar** uiset element that owns the buttons. Concretely:

1. `engine/TouchInput.lua` — the state machine now living in Mouse.lua
   (tap / drag / hold / hold-drag / two-finger / pinch), with a tiny API:
   `TouchInput.mode()` ("tap","pan","hover",...), `TouchInput.onGesture(name, fct)`.
   Map/dialog code asks the mode instead of peeking at `engine.Mouse.touch`.
2. `mod/class/uiset/TouchBar.lua` — a proper bar (bottom edge), not toolbar tiles:
   two groups, *actions* (Rest, Explore, Wait, Stairs, Pick up) and *screens*
   (Level, Char, Inventory, Talents, Log, Menu), plus Z+/Z-, and a hotbar
   page switcher. Buttons declared as data `{label, key|fct, when=function}` so
   context buttons appear only when relevant (Stairs only on stairs; "Confirm" /
   "Cancel" in targeting mode).
3. **List scrolling**: a vertical drag inside any scrollable list scrolls it (convert
   to wheel events); horizontal drag = hover-scrub stays. Do it once in
   engine/ui (List, VariableList, TalentTrees, TextzoneList, Inventory) via a
   shared helper, so every dialog gets it.
4. **Targeting mode** (talents/items that need a target): tap = pick tile/target,
   drag = move the cursor without confirming, two-finger/Back = cancel, a "Confirm"
   button appears in the TouchBar. Verify `Game:targetMouse` already treats a
   click as accept.
5. **Settings**: one "Touch" options page: UI scale (2x / 2.5x / 3x), font scale,
   long-press delay, show/hide d-pad.
6. Optional **virtual d-pad** (8 directions + wait) for precise stepping, hidden by
   default; taps on tiles already cover most movement.

## 3. Gap list (from ToME's keybind table vs touch coverage)

Covered: REST, RUN_AUTO, PICKUP_FLOOR, LEVELUP, SHOW_CHARACTER_SHEET, EXIT,
HOTKEY_1..12 (page 1 taps), SHOW_INVENTORY / USE_TALENTS / SHOW_QUESTS / lore /
main menu (toolbar icons), zoom, map travel + attack (tap), context menus
(hold), tooltips (hover-scrub / dialog drag), ACCEPT (dialog buttons).

Missing or unverified, by priority:
1. **CHANGE_LEVEL** (use stairs) — no touch path yet. Add a context "Stairs" button
   (and/or long-press on your own tile → Actions menu entry).
2. **MOVE_STAY** (wait a turn) — add "Wait" to the bar (also useful to pass turns).
3. **Hotkey pages** (HOTKEY_NEXT/PREV_PAGE, pages 2-7) — page switcher on the bar or
   swipe on the hotbar; today only page 1 is reachable.
4. **List scrolling** in long dialogs (inventory, lore, quests, stores, log) — no
   wheel on touch. Blocking for stores/inventory once packs are big.
5. **Targeting mode** flow — untested on touch; needs the tap/drag/cancel rules above.
6. **Drag-and-drop** (talents → hotbar, inventory reorder) — SDL drag emulation may
   work via `game.mouse` drag, unverified. Fallback: item/talent menus already
   offer "bind to hotkey"-style actions.
7. **SHOW_MESSAGE_LOG / SHOW_MAP / TOGGLE_MINIMAP / LOOK_AROUND / CENTER_ON_PLAYER** —
   screens; add to the "screens" group (Log, Map, Centre).
8. **QUICK_SWITCH_WEAPON, TOGGLE_BUMP_ATTACK, TACTICAL_DISPLAY, TOGGLE_NPC_LIST** —
   toggles; put them in a "More" popup rather than the bar.
9. **Text input** — keyboard wired, not yet verified on device (name box, search).
10. **Two-finger Escape and pinch** — verified only by code review on device use.
11. Party orders / switch (ORDER_PARTY_n, SWITCH_PARTY_n) — later; only with escorts.
12. Modifier clicks (shift-click travel, ctrl-click) — desktop-only conveniences; skip.

## 4. Test plan additions
- simtest: Stairs (stand on stairs → button → level change marker), Wait, hotbar
  page switch, list scroll (inventory with 30 items), targeting (talent with
  target → tap tile → `use_talent` marker), keyboard (name box focus → `[IOS-OSK] show`).

## 5. Frequency-driven design (how keyboard play actually goes)

The loop: auto-explore (z) → interrupted by an enemy → fight with hotkeys 1-0 (most
talents want a target; with "auto accept target" the key fires at the nearest
enemy) and bump-attacks (direction keys) → rest (R) → walk over loot, pick up (g),
maybe read it → back to z. Stairs (>) once per level, level-up (p) every few
levels, inventory (i) when loot is worth equipping. Talents/character/quests/lore/
options/save are rare.

Tiers → touch treatment:
- T1 (dozens/min): hotkey talents, move/attack, explore, rest, confirm target,
  dismiss popups. Must be ONE tap, no mode, thumb-reachable: big hotbar along the
  bottom; two large icon buttons (Explore, Rest) at the right thumb; auto-accept
  target ON so a talent tap fires at the nearest enemy; tap a tile = move/attack/
  travel; a popup closes on any tap.
- T2 (per room/level): pick up (auto-pickup on step, touch-friendly), stairs (tap
  your own tile while on stairs = use them), level-up (glowing contextual button
  when points are unspent), inventory (toolbar icon), use item (hotbar).
- T3 (rare): talents/char/quests/lore/menu behind icons; toggles in a "More" popup.
- Hold = menus, hold-drag = hover, two-finger = Escape stay as the "everything else"
  layer; they are fine being slower.
- Tap your own tile: on stairs → change level; otherwise a small self-menu
  (wait, rest, explore) — replaces the labelled row.

## 6. Decisions (Jordan, 2026-09-02)
- Auto-pickup ON by default. Auto-accept target OFF (targeting stays explicit).
- AoE talents: show the area preview while targeting (as on desktop), then confirm.
  Touch rule: tap a talent → targeting mode with preview at the default target;
  tap/drag on the map moves the preview; Confirm button (or tap the same spot
  again) casts; two-finger / Cancel aborts.
- Tap yourself = wait a turn; on stairs it takes them (2026-09-03). Hold yourself = self menu. Level-up: contextual glowing button
  when points are unspent. Inventory: behind its icon.
- Do NOT dismiss dialogs on any tap; Escape (two-finger, close box, tap-outside) is enough.
- Explore + Rest: right-thumb, hotbar-slot sized (bigger than today's row).
- Design iteration happens in a web mockup first, then in-game.

## 7. Web mockup (2026-09-02)
Interactive mock for feedback before building: https://claude.ai/code/artifact/732175a5-16d9-4328-895e-9a2fc2cae4f9
Source: `tools/ios/design/touch-mockup.html` (republish via the Artifact tool with the same URL).
Shows: 10-slot 96px hotbar with swipe pages, 112px Explore/Rest at the right thumb that turn into
Cast/Cancel while aiming, AoE/bolt preview aiming, hold-tile action menu, self-tile menu, contextual
level-up glow, tabbed level-up screen with drag-scroll (no scrollbar) and per-point undo, inventory
dialog with drag-scroll. Open questions listed at the bottom of the page.

## 8. Radial proposal (Jordan, 2026-09-03)
Jordan's idea: hold in the left third → wheel of hotkeys (with page flip); hold in the right
third → wheel of everything else (explore, rest, inventory, talents, character, journal, menu,
zoom); plain tap = move as today; tap self = wait/stairs. Mock: `tools/ios/design/radial-mockup.html`
(artifact "ToME Radial Layout"). Open questions on the page: trigger (hold vs first movement),
wheel anchored under finger vs corner, zone size, 8 vs 12 wedges, cast/cancel buttons vs tap-again,
cooldown visibility without a hotbar, right-wheel contents.
Decisions 2026-09-03: radial direction accepted; tabbed level-up screen accepted; Cast+Cancel
buttons while aiming; cooldown pips under the vitals; right wheel contents as drawn.
To decide on the phone (build them as settings): wheel trigger (hold vs first movement), wheel
position (under finger vs corner), zone size (thirds vs bottom halves), wedge count (8 vs 12).

## 9. Built (2026-09-03, commit 85601933)
Radial wheels in-game with settings (Options > Touch): trigger hold/drag, position finger/corner,
zone thirds/bottom, wedges 8/12, hold delay. Back and forward page wedges (skip empty pages,
350 ms flip cooldown). Two-tap targeting (first tap places, second fires) + Cast/Cancel buttons.
Cooldown pips under the minimap. Drag-to-scroll in all dialogs. Wedge = icon + number, selected
name shown over the hub. Not yet: tabbed level-up dialog, self-tile hold menu, wait on tap-self.

## 10. Tabbed level-up (2026-09-03)
`mod/dialogs/elements/TouchTalentList.lua` (vertical rows, icon + name + status, big − / + per row,
category headers expand on tap, drag or wheel scroll) + `LevelupDialog:createDisplayTouch()` under
`__IOS__`: the four point buttons are the tabs (Stats / Class / Generic; Category shows its text),
one pane at a time via Dialog:replaceUI, description pane on the right (no_tooltip path), bottom
row keeps Hide-unlearnt / Inscriptions / Prodigies. Undo = the − button (calls onUseTalent(item,false)).
2026-09-03 later: level-up rows grey when unraisable (talent do_shadow; stats: maxed or no points,
iOS-only do_shadow) unless changed this visit (gold name/value, − enabled); + dims when the tab has no
points (can_add). Cooldown pips are now 44px talent icons under the minimap with the turns overlaid
(Minimalist:displayTouchPips). Tooltip while aiming is pushed clear of Cast/Cancel (engine Tooltip.lua).
Jordan reported "options menu doesn't scroll" — drag-scroll on the Game Options TreeList works in the
sim (marker + rows moved); unresolved, needs how he dragged.

## 11. Attack button + unlocks (2026-09-03)
- `Player:touchAttack()`: closest visible hostile (fov.actors_dist); if `touch_attack_talent` (saved on
  the player, "bump" default) is ready, in range and LOS → useTalent with force_target; else bump when
  adjacent, else one A* step. `Player:touchAttackPick()` = listPopup of activated talents (hold the button).
  Drawn/zoned by `Minimalist:displayTouchAttack` bottom-right (Cast/Cancel take the spot while aiming);
  `TouchWheel:zoneOf` excludes the button rect so a hold there is a right-click, not a wheel.
- `TouchWheel.applyUnlocks()` (Game:run, Birther:init): metatable on profile.mod.allow_build → every
  birth option unlocked incl. birth_transmo_chest; the chest makes describeFloor pick up everything
  and transmo items don't count toward encumbrance. Setting `touch.unlock_all` (Options > Touch).

## 12. Flight-proofing + attack v2 + inventory (2026-09-03, late)
- main.c: SDL_AddEventWatch → game:onBackground()/onForeground() (ToME Game:onBackground saves
  synchronously via saveGame + savefile_pipe:forceWait); input-idle → handleIdleTransition(1) at
  IOS_IDLE_FPS=10 after 4 s without input, any input restores.
- Attack: touchPickTarget (enemies fighting us first, then distance, then weakest), pulsing red
  marker on the chosen enemy, second slot (touch_attack_talent2; "Step back" option = adjacent tile
  maximising distance from enemies; "Nothing" hides it). Hold the faint slot to set it.
- Tap yourself = wait (MOVE_STAY) or stairs (CHANGE_LEVEL); the hold menu (MapMenu on_player) already
  has Pickup/Rest/Auto-explore/Inventory/Levelup.
- Inventory: ListColumns item_height 56 + 60px icon column on iOS; EquipDoll scale 1.35 in
  ShowEquipInven. Dialog drag-scroll has momentum (touch_fling in Dialog:toScreen) for pixel scrollers.

## 13. Input-layer rewrite (2026-09-03, evening)
- `engine/TouchInput.lua` owns every gesture. SDL's touch→mouse emulation is OFF on iOS
  (main.c hints SDL_HINT_TOUCH_MOUSE_EVENTS / MOUSE_TOUCH_EVENTS = 0); Mouse.lua's
  receiveTouch/Motion/Gesture just forward to TouchInput.fingerDown/Move/Up/gesture, and
  Game.lua's frame tick calls TouchInput.tick(). TouchInput *emits* mouse events in a known
  order (tap = motion+down+up then park; drag = down at start, motion with "left", up at end;
  hold 450 ms then lift = right click; hold+drag = hover motion; two-finger = escape(); pinch =
  on_pinch). No more suppress_next_up / last_left_down / park hacks.
- Providers set by the uiset: `TouchInput.wheel` (TouchWheel: zoneOf/openAt/move/release/cancel),
  `TouchInput.on_pinch`. Settings single-sourced in TouchInput.DEFAULTS (TouchWheel.setting =
  TouchInput.setting).
- Capability flag: `TouchInput.active()` (iOS, or `touch = {emulate=true}` on desktop) replaces the
  `__IOS__` checks in Dialog (close box, drag-scroll), Tooltip, GameTargeting, Inventory, ToME
  Game.lua (pan, tap-self), LevelupDialog, GameOptions. `__IOS__` stays only for rendering
  (screen_zoom/font) and unlocks.
- Desktop emulation: `TouchInput.mouseAsFinger` / `mouseMotionAsFinger` at the top of
  Mouse:receiveMouse/receiveMouseMotion turn the mouse into finger 1 (right click = two-finger).
  `injecting` guards the events TouchInput itself emits.
- Scripted gestures: `touch.script = "/file.lua"` (physfs path under the home dir) returning
  function(T) with T.tap/hold/swipe/two_finger/key/shot/wait/log, run as a coroutine from tick().
  Harness: `tools/touch/mac-run.sh [script]` (writes settings, launches t-engine.app at
  1398x645, checks markers) with `tools/touch/smoke.lua`.
Rewrite verified 2026-09-03 15:00: tools/ios/simtest.sh 12/12 on the Plus sim (tap, hold, hover-scrub,
pan, close box, right wheel ×3, left wheel, zoom, attack); tools/touch/mac-run.sh 7/7 on the Mac
release build (make -j8 config=release; the Makefile defaults to debug, which is unplayably slow).
Mac stdout always goes to /tmp/te4_log.txt; --flush-stdout now line-buffers it. The birth level-up
dialog must be closed by the script (birth_done runs after it), so no "ready" gate before that.

## 14. Proposal: "Act" button with routines (2026-09-03, Jordan's ask)
Act = one button running the active routine one step per tap. Routine = ordered steps
{kind=talent|bump|approach|step_back|wait|item, target=nearest|attacker|weakest|marked|self|
best_aoe|furthest_in_range, if_unusable=skip|wait}. Multiple named routines per character (saved on
the player), hold Act = switch/edit. Editor = finger rows (like TouchTalentList). Phases: executor +
targeting resolvers + simple editor → multi-routine + AoE spot finder → conditions (life<%, etc.).
Open: one-step-per-tap vs run-through; conditions in v1; per-class starter routines.
Built 2026-09-03 evening: Act = Player:actStep/actDo/actResolveTarget (rules: nearest, attacker,
weakest, strongest, furthest, marked, best_aoe via projectCollect dry-run, manual, self), routines on
player.act_routines (act_active, per-routine pos), hold = actMenu (switch / restart / skip / edit),
editor mod/dialogs/ActRoutines.lua (List rows: tap selects; buttons Add/Remove/Up/Down/Target/
Skip-Wait; New/Rename/Copy/Delete), HUD strip above Act (tap a box = jump), "Mark for Act" in the
creature hold menu. Decisions: one step per tap, no conditions in v1, left wheel stays, no 2nd button.

## 15. Touch inventory / shops / action sheet (2026-09-03 night)
- `mod/dialogs/elements/TouchItemList.lua`: 66px rows (icon, coloured name, stats line, price,
  "likely better / worse / empty slot" hint via score(): weapon damage else price). NOTE font:draw
  returns a texture as wide as requested → measure with font:size(markup-stripped) first.
- `mod/dialogs/TouchInventory.lua` (routed from ActorInventory:showEquipInven when TouchInput.active):
  Tabs (All/Weapons/Armour/Jewelry/Inscriptions/Tools/Other/Chest), EquipStrip of worn slots (tap =
  select worn item → Take off), list + TextzoneList description, fixed-width primary button (Wield /
  Use / Take off / Keep / Drop, or Choose in filter flows) + More (action sheet). Title from the
  caller is "X - Encumbrance a/b" (rendered "~").
- `mod/dialogs/TouchStore.lua` (routed from engine Store:interact): Buy/Sell tabs, prices on rows,
  Buy/Sell button → the store's action callback; implements updateStore/generateList. UNTESTED (no
  shop reachable in the sim run).
- UseItemDialog: touch layout = description + big buttons (first one glows) = the action sheet.

## 16. Dialog sweep (2026-09-04)
`tools/touch/sweep.lua` (run via touch.script on the sim: opens ~22 dialogs, T.shot each; shots land in
Documents/t-engine/4.0/tome/shot-*.png; capture happens in TouchInput.frameEnd so dialogs are drawn).
Generic touch fixes from it: Button default font 30 (unless a font is passed), List/TreeList/ListColumns
rows ≥ 44px, small fixed-size dialogs (≤720x520) scaled 1.5x in Dialog.init, CharacterSheet header
(shorter intro, header height = taller block, buttons anchored right), DeathDialog sized to screen,
detailed talent descriptions always on. Known leftovers: ShowMap draws the minimap at its tiny native
size; LorePopup/ShowChatLog not exercised by the sweep (need real ids / online chat).
- `mod/dialogs/TouchGallery.lua` (Game menu > "Touch UI gallery" on touch): every dialog with faked
  state (spawned NPC for Chat, game:getStore("SWORD_WEAPON"):loadup+interact for a shop, two weapons
  dropped for the pickup dialog, first lore def with string lore for LorePopup(def, w), achiev_defs[1],
  UberTalent). sweep.lua iterates entries(); `touch.script_early=true` starts the script before the
  level exists (birther), T.waitFor(). Death dialog must NOT be faked: its init consumes a life and
  bails (dont_show) leaving a half-built dialog (b8 nil error).

## 17. Safe area + cut-off audit (2026-09-04)
- `src/ios_safearea.m` (UIKit safeAreaInsets) → core.display.safeArea() → TouchInput.safeArea()
  {l,t,r,b} logical (override `touch.safe`). Dialogs clamp+center inside it (Dialog.init/resize),
  HUD places shift (Minimalist:applySafeArea), Act/Cast/Cancel/pips/wheels inset.
  `touch.show_island=true` draws the Dynamic Island pill + home indicator (TouchInput.frameEnd) so
  simulator screenshots show occlusion; the sweep runs with it on.
- Audit fixes: List auto-height capped to 74% of the safe height with a scrollbar (game menu); character
  sheet mono font 13 on touch; wider list panes / columns in UseTalents (62%), GameOptions/VideoOptions
  (58%), KeyBinder (58/21/21). Leftovers: prodigies grid overflows (rare), map dialog minimap tiny.

## 18. AUTO (auto-act) + chat fit (2026-09-04)
- AUTO button left of Act: Player:autoActStart/Stop/Tick (called from Minimalist each frame). The
  engine stops ticking without input events, so the tick calls game:tick() (≤12/frame, 20 ms) until
  game.paused, like the autopilot. Stops on: life < auto_life%, any non-inverted resource < auto_res%,
  any visible enemy with rank > 2 (auto_rare), any dialog other than the Running/Resting popups, key
  handler not normal (aiming), routine "nothing possible", 3 idle steps, any touch outside the button.
  Verified: 2 min unattended, 6 kills, 19 actions.
- Chat dialog (engine/dialogs/Chat.lua): on touch sized to content; long speeches become a scrolling
  TextzoneList so the answers stay visible. Chats have no close box (they ignore Escape).
Auto-act stop reasons name the cause ("<dialog title> opened", "a talent needs aiming", "a menu took
over", "life below 50%", "<resource> below 25%", "<creature> spotted", "you touched the screen",
"nothing left to do here"). The HUD must not stop auto on dialogs (the Running/Resting popups are
dialogs); only autoActTick decides. 150 s unattended run: 42 actions, 9 explores, 7 kills.
Idle mode (2026-09-04): while AUTO runs the screen stays awake (idleTimerDisabled) and dims to 0.35
(restored on stop/background, setting auto_dim); a stop that needs the player vibrates + warning
haptic + posts a local notification "ToME needs you: <reason>" (UNUserNotificationCenter, banner shown
in foreground via delegate). C: src/ios_safearea.m (keep_awake/haptic/notify/brightness),
core.display.keepAwake/haptic/notify/brightness; link UserNotifications + AudioToolbox.

## 19. Touch character sheet (2026-09-04)
CharacterSheet:initTouch (touch only): Tabs General/Attack/Defense/Talents/Equipment, TouchStatList
rows (label | value, section headers), detail pane (tap a row → its TOOLTIP_* text), Level up /
Inventory buttons. Rows come from running the desktop drawDialog(kind) against a recording surface
proxy (drawColorStringBlended returns 7 values; mouseTooltip attaches tips by x,y), sorted by column
then y; "Label : value" split at the first colon; Equipment tab lists worn slots from inven_def.
Leftover: talent category lines are not detected as headers; Tab font patch did not visibly apply.

## 20. Touch character creation (TouchBirther)

Mock: `tools/ios/design/birth-mockup.html` (artifact https://claude.ai/code/artifact/e4ed0764-89b6-4b83-8155-ef971f1a180a). Built as `mod.dialogs.TouchBirther`, a subclass of `mod.dialogs.Birther` that keeps every descriptor rule (allowed/locked/apply/checkNew/atEnd) and replaces only the widgets; `class/Game.lua` picks it when `TouchInput.active()`.

Layout (rail 200 | content | detail 400): `Rail` (five steps, tick/number circles via drawRingWedge, tap to jump back when reachable), `Flow` (sections of cards in one pixel scroller: `scrollbar.pos/max`, no `scroll` field, so the Dialog drag-scroll follows the finger; cards carry name, two-line pitch = first sentence of the descriptor desc, optional icon), detail pane drawn in `innerDisplayBack` (actor sprite, name, pitch, stat chips from `def.stats`/`copy.life_rating`/`experience`), `TextzoneList` description, Back/Next (Next is `c_ok` so the stock `atEnd` gate keeps working; reads Review on step 4 and Begin on step 5 with a gold frame).

Steps: Who (Textbox name: focusing it shows the iOS keyboard; Random = `randomName`; sex cards) → Race (race cards with the lineage sprite, lineage cards; the cosmetic groups were dropped on request, the stock customizer is untouched) → Class (class cards with the first path's `display_entity32`, path cards) → Difficulty (campaign, difficulty, death rows; locked entries stay visible, dimmed, with the unlock text in the pane) → Start (summary rows with edit, More: Tutorial/Random/Premade/Custom tile).

Gotchas: the stock generators re-validate the selection only through the tree widgets, so `generateRaces/Classes` are wrapped to re-find the chosen node; `raceUse/classUse` never touch `c_race/c_class`; `randomBirth` pokes `c_female/c_male.checked`, provided as plain tables; the name box is moved off-screen on other steps (hidden uis still get taps); Escape = Back, Cancel only from step 1, and it is ignored while the soak autopilot runs because the autopilot dismisses the top dialog with EXIT before the birth hook fires (that rebooted the game to the main menu); the autopilot hook now lives in `on_register`. Test: `touch-birth.lua` in the sim Documents (opens a TouchBirther on the live player, taps through all steps); harness `T.tap` now sends down+up in one frame so a slow first draw cannot turn a tap into a long press.

## 21. Six more touch screens (2026-09-04, built by parallel builders, verified in the sim)

Shared kit `engine.ui.TouchKit` (in the engine so the boot module can use it): text cache with bold-aware ellipsis, quad/frame/circle, wrap, pitch, `Rail`, `Flow`. Test runner: `tools/touch/sim-run.sh tools/touch/tests/<name>.lua <outdir> [boot]` (boot mode sets `touch.script_boot` and turns the autopilot off). Tests live in `tools/touch/tests/`.

- **TouchChat** (`mod/dialogs/TouchChat.lua`, routed in `engine/Chat.lua:invoke`): portrait + name left, scrolling speech right, answers as full-width lettered cards; `regen` rebuilds as a TouchChat so later nodes keep the layout.
- **TouchTalents** (`mod/dialogs/TouchTalents.lua`, routed at Game.lua USE_TALENTS, Minimalist and Classic hotkey bars): sections Activable/Sustain/Cooling/Passive, detail pane with Use / Put on wheel / Auto-use; slot picker = 3 wheel pages × 12 slots, assigns `actor.hotkey[i]`.
- **Title screen** (`boot/dialogs/TouchMainMenu.lua`, `TouchLoadGame.lua`, routed in boot `class/Game.lua`; the autopilot start moved to `MainMenu:setupAutopilot`): Continue card with the newest usable save, New character / Load game / Options / More; save cards with thumbnails, facts pane, Load + Delete (confirm).
- **GetQuantity** (`engine/dialogs/GetQuantity.lua` `initTouch`): readout, drag bar (reads TouchInput.t during display because the Dialog swallows drag motion), − / +, 1 / Half / All, Cancel / OK; no keyboard. All callers unchanged.
- **TouchJournal** (`mod/dialogs/TouchJournal.lua`, routed at Game.lua SHOW_QUESTS + game menu Lore/Achievements + QuestPopup): tabs Quests (Active/Done chips) / Lore (per category) / Achievements (Earned/Locked), cards left, detail right.
- **DeathDialog** touch branch (`initTouch`): character card, killer, fact chips, death text, choices as cards with a one-line consequence. `DeathDialog.new(actor, {preview=true})` builds the real choice list with no side effects (gallery entry "Death screen (preview)").

Gallery gained: Journal, Lore tab, Achievements tab, How many? prompt, Death screen (preview). Known leftovers: Tabs font still small (journal tabs), the boot welcome text panel still shows behind the touch menu.

## 22. Round two of touch screens (2026-09-04 night)

Same builder pattern. New/changed: **ShowPickupFloor** touch branch (TouchItemList rows, Take all / Done, hold a row = description); **TouchMap** (`mod/dialogs/TouchMap.lua`, SHOW_MAP): whole level fitted, pan by finger (reads TouchInput.t; hit tests use `display_x + ix`, drawing uses the translated x from innerDisplay — they differ!), tap tile = `player:mouseMove`, Go to the exit, Find me, zoom; **TouchLog** (`mod/dialogs/TouchLog.lua`, SHOW_MESSAGE_LOG): chips per channel, opens at newest, Newest button; **TouchOptions** (`mod/dialogs/TouchOptions.lua`, game menu): rail of sections, rows built from the stock GameOptions generators with stubbed c_desc/c_list, ON/OFF pills, Audio/Video open the stock dialogs; **TouchProdigies** (`mod/dialogs/TouchProdigies.lua`, LevelupDialog + gallery): cards per stat category, requirements met/unmet, Learn/Unchoose with the stock semantics; **QuestPopup/LorePopup** touch branches (status pill / illustration left, Continue). Engine: `TextzoneList` ignores `pingpong` on touch (talent descriptions no longer auto-scroll); `Tab` touch font 32; boot news panel hidden behind the touch title menu; `Game:saveSettings` falls back to a direct `io.open` write when PhysFS refuses (the sim showed hundreds of lost setting writes: default_birth, tactical_mode, audio, touch).

**Zoom and loads (2026-09-04, late):** `Map:loaded()` resets `self.zoom`/`Map.zoom` to 1 and recomputes the viewport tile counts before `makeCMap`, because the C map is always created at 1x and a saved zoom left the Lua side (target cursor, hit tests) at another scale (orange target square drifting after a load + pinch). `Map:recreate()` keeps the current zoom through `applyZoom()` (called after `redisplay()`; calling `_map:setZoom` right after `newMap` drew nothing). Load tests: `tools/touch/sim-load.sh tools/touch/tests/loadzoom.lua <out>` (boot script taps Continue, game phase logs the map). Note: after the in-process reboot that a load triggers, stdout is no longer line-flushed, so late log lines can be missing from the console capture.

## 23. Manual play controls (2026-09-05)

Mock `tools/ios/design/manual-mockup.html`. Built in `mod/class/TouchManual.lua` (owned by Minimalist as `touch_manual`): tap a hostile = `player.touch_target` with a pulsing ring, and the **skill drawer** opens (bottom panel between the left thumb zone and the SKILLS button: who block + one card per hotkey talent, ready first, cooldowns dimmed, horizontal drag scroll, ✕ closes and clears the target); the **SKILLS** button (left of AUTO) toggles the drawer at will; a card casts at the target, else the nearest enemy in view, else starts manual aim. **Tap-to-path is disabled while any enemy is in view** (floor tap clears the target, hint every 5 s); **drag-to-step**: TouchInput `on_map_drag` provider (setting `drag_step`, default on) previews the 8-direction destination tile (dashed gold frame + bar + attack/blocked label) and steps on release through `player:moveDir`, repeats every 220 ms after a 600 ms hold, stops when an enemy appears; a step issued before the turn comes back is retried for 1.5 s (`pending_step`). **More (⋯)** above SKILLS = action sheet (Level up, Inventory, Character, Talents, Journal, Map, Rest, Explore, Zoom, Options, Game menu). **Wheels off by default** (`touch.wheel=false`; option kept). Harness: `T.swipe` moves ≥20 px before yielding (else a slow sim frame turns it into a hold), and `scriptTick` drives `game:tick()` while a script runs (synthetic fingers do not wake the idle throttle, so energy never came back and every step after the first was a silent no-op). Test `tools/touch/tests/manual.lua`.

**Places (2026-09-05):** `mod/dialogs/TouchPlaces.lua`, from More → Places and the map dialog's Places button. Scans remembered/seen tiles: Towns/Dungeons on the wilderness (zone entrances, town list + `town-*`), Exits and stairs elsewhere, Shops (trap-layer `is_store` doors), People (seen non-hostile actors with `can_talk`/`store`/`quest_giver`); cards with icon and distance; tap = `player:mouseMove` (walks into the door or person like a desktop click), or CHANGE_LEVEL when standing on the entrance. Tap-to-walk lockout is skipped on the wilderness (`zone.wilderness`).
