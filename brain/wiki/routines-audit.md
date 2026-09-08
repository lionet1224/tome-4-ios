# Act routines audit against class play styles (2026-09-08)

Sources: te4.org wiki class pages plus 1.7 forum/Steam guides, read by three research agents, checked against
`data/birth/classes/*.lua` and `data/talents/`. Published page: https://claude.ai/code/artifact/df9ad738-c062-49c0-a380-b56c7e00b716

## Findings
- Almost every class loop is a **priority list** ("first of these that applies"): stun when ready, AoE when 2+, finisher
  when the target is low, else bump. Fixed cycles are rare (Alchemist bomb/staff/staff/staff).
- **Temporal Warden** needs no swap step: Bow Threading talents and Shoot swap to the bow, Blade Threading talents and
  Attack swap to the blades ("adjacent → Warp Blade, else Shoot"). Explicit swaps matter for Archers (bow/sling) and Adventurers.
- Gaps ranked by classes needing them: priority evaluation (all), adjacent/not adjacent (all ranged + TW/SP/Mindslayer),
  keep-sustain-on (all), 2+ enemies (14), life/resource threshold, pets below cap (6), target life/debuff, no enemies in view.
- Pet classes (Summoner, Necromancer, Oozemancer, Doomed, Stone Warden, Alchemist golem, Solipsist thought-form) need
  "summons below cap → summon" and "no enemies in view → refit/resummon".
- The stock game's per-talent auto-use modes (available / no enemies visible / enemies visible / adjacent / out of combat)
  are the same four situations; a "keep on" step is the routine-side equivalent.
- DLC classes (Doombringer, Demonologist, Cultist, Wanderer) are not in this build.

## Proposal (see the page)
1. Priority mode per routine (cycle stays as an option); position pointer goes away.
2. One condition chip per step: adjacent / not adjacent, 2+ enemies, life < X, resource < X, target < X, no enemies in view, pets below cap.
3. Step kinds: keep on (sustain), keep summoned, keep distance N (replaces Step back), swap weapons, turn off.
4. Class templates from birth talents, "reset to class routine".
5. AUTO runs "no enemies in view" steps before exploring.
Build order: priority + keep on → adjacent/2+/no enemies → thresholds/pets → templates → swap/turn off/keep distance.
Open questions for Jordan: default mode for new routines; one or two conditions per step; when AUTO runs the out-of-combat steps.

## Per-class loops (condensed)
- Berserker: Rush → Shattering Blow → Stunning Blow → Death Dance if 2+ → Execution when low → bump; Unstoppable when hurt.
- Bulwark: Block → Rush → Shield Pummel → Assault → Shield Slam → Repulsion if surrounded → bump.
- Arcane Blade: Phase Door/Rush → Flame/Lightning → Fearless Cleave/bump → Dirty Fighting; Manasurge when mana < 30%.
- Brawler: combo generators (Double Strike) → finisher at 5 points (Haymaker/Uppercut/Concussive).
- Rogue/Shadowblade: stealth open → Shadow Dance/Shadowstep → Expose Weakness → burst → re-stealth when nothing in view.
- Marauder: Rush → Dirty Fighting → Dual Strike → Skullcracker → Flurry → bump when stamina is gone.
- Skirmisher: Kneecapper → Bombardment/Swift Shot → Hurricane/Kill Shot → Shoot; adjacent → Tumble/Disengage/Bash and Smash.
- Archer: Headshot → Pin Down → Steady Shot; Scatter/Volley on groups; adjacent → Disengage/Tumble; sling set when ammo is out.
- Archmage: bolt → AoE when 2+ → bolt; adjacent → Phase Door; Shielding when the shield is down.
- Alchemist: Throw Bomb → Channel Staff ×3; golem Refit when hurt/dead; Golem Portal when low.
- Necromancer: summon (souls) → Corpse Explosion → Putrescent Liquefaction → Dire Plague → Invoke Darkness filler; Torture Souls when souls are low.
- Temporal Warden: Warden's Focus → Arrow Echoes → Singularity Arrow → Shoot; adjacent → Warp Blade/Blink Blade; hounds resummon by themselves.
- Paradox Mage: Time Shield → Webs of Fate → Seal Fate → Attenuate → cheap spells; Repulsion Blast when adjacent; Induce Anomaly when paradox is high.
- Sun Paladin: Path of the Sun/Wave of Power → bump/Crusade → Stunning Blow when ready → Sun Ray when energy is full.
- Anorithil: circles → Celestial Surge → Sunburst → Moonlight Ray; Twilight when negative energy is low.
- Mindslayer: Frenzied Focus on groups → Kinetic Surge in → Telekinetic Smash → bump; shields by damage type.
- Solipsist: thought-form → Sleep the pack → Mind Sear → Distortion; keep psi at the threshold; kite.
- Summoner: summons to cap (tank first) → step back → Detonate; resummon what died.
- Wyrmic: breath, breath, breath → Nature's Balance when all cooling → Swallow when the target is low.
- Oozemancer: Call of the Ooze → Slime Spit → Mucus/Acid Splash → mosses; Reabsorb an adjacent ooze when hurt.
- Stone Warden: Stone Vines/Rockswallow pull → Eldritch Slam → Eldritch Blow → Eldritch Fury → Eldritch Stone; Elemental Split when ready.
- Reaver: Virulent Disease → spread → Rend/Acid Strike → Cyst Burst with 2+ diseases; Drain/Life Tap when vim is low.
- Corruptor: curse/hex → Blood Spray → Soul Rot → Blood Grasp → Drain; Blood Boil when adjacent.
- Cursed: Rampage → Harass Prey → Dominate → Slash/Frenzy → bump (bump during Rampage).
- Doomed: Focus Shadows → Feed → Willful Strike/Reproach → Hateful Whisper/Blast; Focus Shadows when shadows are missing.
