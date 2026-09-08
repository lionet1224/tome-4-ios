-- iOS port: class routine templates for Act / AUTO.
-- One routine per subclass, written from how the class is actually played (see
-- brain/wiki/routines-audit.md): sustains to keep on first, then the escapes and
-- melee answers for "adjacent", area talents for groups, finishers, the main
-- attacks, and a bump or a shot last. Steps whose talent the player does not know
-- yet are dropped when the routine is generated, so a fresh character gets a
-- short list that grows with "Reset to class routine".
--
-- Step schema: {kind="talent"|"bump"|"distance"|"swap"|"wait", tid, target, if_unusable,
--   cond ("adjacent","not_adjacent","group","life","resource","target_life","no_enemies","pets_low"),
--   pct, off, range}
module(..., package.seeall)

local KINDS = {talent=true, bump=true, distance=true, swap=true, wait=true}
local CONDS = {adjacent=true, not_adjacent=true, group=true, life=true, resource=true, target_life=true, no_enemies=true, pets_low=true}
_M.KINDS, _M.CONDS = KINDS, CONDS

-- step builders ---------------------------------------------------------------
local function t(tid, o)
	o = o or {}
	local st = {kind="talent", tid=tid, target=o.target or "nearest", if_unusable=o.if_unusable or "skip"}
	if o.cond then st.cond = o.cond end
	if o.pct then st.pct = o.pct end
	if o.off then st.off = true end
	return st
end
-- a sustain or self-buff kept up: refused for free while it is on
local function keep(tid, o) o = o or {} o.target = o.target or "self" return t(tid, o) end
local function aoe(tid, o) o = o or {} o.target = o.target or "best_aoe" return t(tid, o) end
local function finisher(tid, pct) return t(tid, {cond="target_life", pct=pct or 25}) end
local function group(tid, o) o = o or {} o.cond = "group" o.target = o.target or "best_aoe" return t(tid, o) end
local function adjacent(tid, o) o = o or {} o.cond = "adjacent" return t(tid, o) end
local function summon(tid) return t(tid, {cond="pets_low", target="self"}) end
local function outside(tid, o) o = o or {} o.cond = "no_enemies" o.target = o.target or "self" return t(tid, o) end
local function bump() return {kind="bump", target="nearest", if_unusable="approach"} end
local function shoot() return t("T_SHOOT", {if_unusable="approach"}) end
local function dist(range, cond) return {kind="distance", range=range or 3, target="nearest", if_unusable="skip", cond=cond} end
local function swap(cond) return {kind="swap", if_unusable="skip", cond=cond} end
local function wait() return {kind="wait", if_unusable="skip"} end

-- templates ---------------------------------------------------------------------
_M.TEMPLATES = {

-- warriors ------------------------------------------------------------------
["Berserker"] = {steps={
	keep("T_BERSERKER_RAGE"),
	t("T_UNSTOPPABLE", {cond="life", pct=30, target="self"}),
	finisher("T_EXECUTION", 25),
	group("T_DEATH_DANCE_ASSAULT", {target="self"}),
	group("T_WARSHOUT_BERSERKER"),
	t("T_STUNNING_BLOW_ASSAULT"),
	t("T_SHATTERING_BLOW"),
	t("T_RUSH", {cond="not_adjacent"}),
	bump(),
}},

["Bulwark"] = {steps={
	keep("T_SHIELD_WALL"),
	t("T_LAST_STAND", {cond="life", pct=30, target="self"}),
	group("T_REPULSION", {target="self"}),
	t("T_BLOCK", {target="self"}),
	t("T_SHIELD_PUMMEL"),
	t("T_ASSAULT"),
	t("T_SHIELD_SLAM"),
	t("T_RUSH", {cond="not_adjacent"}),
	bump(),
}},

["Arcane Blade"] = {steps={
	keep("T_ARCANE_COMBAT"),
	keep("T_ARCANE_FEED"),
	t("T_HEAL", {cond="life", pct=40, target="self"}),
	adjacent("T_DIRTY_FIGHTING"),
	t("T_FLAME", {cond="not_adjacent"}),
	t("T_LIGHTNING", {cond="not_adjacent"}),
	t("T_FEARLESS_CLEAVE"),
	bump(),
}},

["Brawler"] = {steps={
	keep("T_STRIKING_STANCE"),
	finisher("T_HAYMAKER", 30),
	t("T_UPPERCUT"),
	group("T_CONCUSSIVE_PUNCH"),
	t("T_AXE_KICK"),
	t("T_DOUBLE_STRIKE"),
	t("T_RUSH", {cond="not_adjacent"}),
	bump(),
}},

-- rogues --------------------------------------------------------------------
["Rogue"] = {steps={
	outside("T_STEALTH"),
	t("T_SHADOW_DANCE", {target="self"}),
	t("T_EXPOSE_WEAKNESS", {target="self"}),
	group("T_FAN_OF_KNIVES"),
	t("T_THROWING_KNIVES", {cond="not_adjacent"}),
	t("T_DUAL_STRIKE"),
	t("T_FLURRY"),
	t("T_LUNGE"),
	bump(),
}},

["Shadowblade"] = {steps={
	keep("T_SHADOW_COMBAT"),
	keep("T_BLADE_FLURRY"),
	outside("T_STEALTH"),
	t("T_SHADOWSTEP", {cond="not_adjacent"}),
	t("T_EXPOSE_WEAKNESS", {target="self"}),
	t("T_SHADOW_VEIL", {target="self"}),
	t("T_FLURRY"),
	t("T_DUAL_STRIKE"),
	bump(),
}},

["Marauder"] = {steps={
	keep("T_TOTAL_THUGGERY"),
	keep("T_TEMPO"),
	group("T_WINDBLADE", {target="self"}),
	t("T_DIRTY_FIGHTING"),
	t("T_DUAL_STRIKE"),
	t("T_SKULLCRACKER"),
	t("T_FLURRY"),
	t("T_RUSH", {cond="not_adjacent"}),
	bump(),
}},

["Skirmisher"] = {steps={
	keep("T_SKIRMISHER_BOMBARDMENT"),
	keep("T_SKIRMISHER_PACE_YOURSELF"),
	adjacent("T_SKIRMISHER_BASH_AND_SMASH"),
	adjacent("T_DISENGAGE"),
	adjacent("T_TUMBLE", {target="self"}),
	t("T_SKIRMISHER_KNEECAPPER"),
	group("T_SKIRMISHER_HURRICANE_SHOT"),
	t("T_SKIRMISHER_THROAT_SMASHER"),
	t("T_SKIRMISHER_SWIFT_SHOT"),
	shoot(),
}},

["Archer"] = {steps={
	keep("T_AIM"),
	keep("T_CONCEALMENT"),
	adjacent("T_DISENGAGE"),
	group("T_SCATTER_SHOT"),
	t("T_HEADSHOT"),
	t("T_STEADY_SHOT"),
	shoot(),
}},

-- mages ---------------------------------------------------------------------
["Archmage"] = {steps={
	keep("T_ARCANE_POWER"),
	keep("T_DISRUPTION_SHIELD"),
	adjacent("T_PHASE_DOOR", {target="self"}),
	group("T_CHAIN_LIGHTNING"),
	group("T_FIREFLASH"),
	t("T_LIGHTNING"),
	t("T_FLAME"),
	t("T_MANATHRUST"),
	dist(3, "adjacent"),
}},

["Alchemist"] = {mode="cycle", steps={
	outside("T_REFIT_GOLEM", {cond="no_enemies"}),
	outside("T_INVOKE_GOLEM"),
	aoe("T_THROW_BOMB"),
	t("T_CHANNEL_STAFF"),
	t("T_CHANNEL_STAFF"),
	t("T_CHANNEL_STAFF"),
}},

["Necromancer"] = {steps={
	keep("T_BLURRED_MORTALITY"),
	summon("T_CALL_OF_THE_CRYPT"),
	summon("T_CALL_OF_THE_MAUSOLEUM"),
	t("T_TORTURE_SOULS", {cond="resource", pct=30, target="self"}),
	group("T_CORPSE_EXPLOSION"),
	t("T_DIRE_PLAGUE"),
	t("T_IMPENDING_DOOM"),
	t("T_INVOKE_DARKNESS"),
	dist(3, "adjacent"),
}},

["Temporal Warden"] = {steps={
	keep("T_WEBS_OF_FATE"),
	adjacent("T_WARP_BLADE"),
	adjacent("T_BLINK_BLADE"),
	t("T_ARROW_STITCHING"),
	shoot(),
}},

["Paradox Mage"] = {steps={
	keep("T_REALITY_SMEARING"),
	t("T_CHRONO_TIME_SHIELD", {target="self"}),
	adjacent("T_REPULSION_BLAST"),
	t("T_WEBS_OF_FATE", {target="self"}),
	t("T_SEAL_FATE", {target="self"}),
	group("T_ATTENUATE"),
	t("T_TEMPORAL_BOLT"),
	t("T_DUST_TO_DUST"),
	dist(3, "adjacent"),
}},

-- celestial -----------------------------------------------------------------
["Sun Paladin"] = {steps={
	keep("T_WEAPON_OF_LIGHT"),
	keep("T_CHANT_ACOLYTE"),
	t("T_BATHE_IN_LIGHT", {cond="life", pct=40, target="self"}),
	t("T_STUNNING_BLOW_ASSAULT"),
	t("T_CRUSADE"),
	t("T_SUN_BEAM", {cond="not_adjacent"}),
	t("T_PATH_OF_THE_SUN", {cond="not_adjacent"}),
	bump(),
}},

["Anorithil"] = {steps={
	keep("T_HYMN_ACOLYTE"),
	adjacent("T_JUMPGATE", {target="self"}),
	t("T_TWILIGHT", {cond="resource", pct=30, target="self"}),
	t("T_CIRCLE_OF_SHIFTING_SHADOWS", {target="self"}),
	group("T_CELESTIAL_SURGE"),
	group("T_SUNBURST"),
	t("T_MOONLIGHT_RAY"),
	t("T_SEARING_LIGHT"),
	dist(3, "adjacent"),
}},

-- psionic -------------------------------------------------------------------
["Mindslayer"] = {steps={
	keep("T_KINETIC_SHIELD"),
	keep("T_KINETIC_AURA"),
	keep("T_BEYOND_THE_FLESH"),
	group("T_FRENZIED_FOCUS", {target="self"}),
	t("T_TELEKINETIC_SMASH"),
	t("T_KINETIC_SURGE", {cond="not_adjacent"}),
	t("T_IMPALE", {cond="not_adjacent"}),
	bump(),
}},

["Solipsist"] = {steps={
	summon("T_TF_DEFENDER"),
	adjacent("T_SYNAPTIC_STATIC", {target="self"}),
	group("T_SLEEP"),
	t("T_MIND_SEAR"),
	t("T_DISTORTION_BOLT"),
	dist(3, "adjacent"),
}},

-- wilders -------------------------------------------------------------------
["Summoner"] = {steps={
	keep("T_MASTER_SUMMONER"),
	summon("T_TURTLE"),
	summon("T_WAR_HOUND"),
	summon("T_RITCH_FLAMESPITTER"),
	dist(3),
	wait(),
}},

["Wyrmic"] = {steps={
	keep("T_ICY_SKIN"),
	finisher("T_SWALLOW", 20),
	aoe("T_FIRE_BREATH"),
	aoe("T_ICE_BREATH"),
	aoe("T_SAND_BREATH"),
	aoe("T_LIGHTNING_BREATH"),
	bump(),
}},

["Oozemancer"] = {steps={
	keep("T_MITOSIS"),
	keep("T_ANTIMAGIC_SHIELD"),
	keep("T_ACIDIC_SKIN"),
	summon("T_CALL_OF_THE_OOZE"),
	adjacent("T_SLIME_ROOTS", {target="self"}),
	t("T_SLIME_SPIT"),
	t("T_MUCUS", {target="self"}),
	t("T_ACID_SPLASH"),
	dist(3, "adjacent"),
}},

["Stone Warden"] = {steps={
	keep("T_STONE_VINES"),
	keep("T_ELDRITCH_INFUSION"),
	keep("T_SHARDS"),
	summon("T_ELEMENTAL_SPLIT"),
	group("T_ELDRITCH_SLAM", {target="self"}),
	t("T_ELDRITCH_BLOW"),
	t("T_ELDRITCH_FURY"),
	t("T_ROCKSWALLOW", {cond="not_adjacent"}),
	bump(),
}},

-- defilers ------------------------------------------------------------------
["Reaver"] = {steps={
	keep("T_BONE_SHIELD"),
	keep("T_RUIN"),
	t("T_LIFE_TAP", {cond="resource", pct=30, target="self"}),
	t("T_DRAIN", {cond="life", pct=40}),
	t("T_VIRULENT_DISEASE"),
	t("T_CYST_BURST"),
	t("T_REND"),
	t("T_ACID_STRIKE"),
	t("T_BONE_GRAB", {cond="not_adjacent"}),
	bump(),
}},

["Corruptor"] = {steps={
	keep("T_BONE_SHIELD"),
	keep("T_DARK_RITUAL"),
	adjacent("T_BLOOD_BOIL", {target="self"}),
	t("T_DRAIN", {cond="life", pct=40}),
	t("T_CURSE_OF_VULNERABILITY"),
	aoe("T_BLOOD_SPRAY"),
	t("T_SOUL_ROT"),
	t("T_BLOOD_GRASP"),
	dist(3, "adjacent"),
}},

-- afflicted -----------------------------------------------------------------
["Cursed"] = {steps={
	keep("T_GLOOM"),
	keep("T_STALK"),
	keep("T_CLEAVE"),
	t("T_RAMPAGE", {target="self"}),
	t("T_RECKLESS_CHARGE", {cond="not_adjacent"}),
	t("T_HARASS_PREY"),
	t("T_DOMINATE"),
	t("T_SLASH"),
	bump(),
}},

["Doomed"] = {steps={
	keep("T_CALL_SHADOWS"),
	keep("T_DEFLECTION"),
	keep("T_GESTURE_OF_PAIN"),
	t("T_FOCUS_SHADOWS", {cond="pets_low", target="self"}),
	adjacent("T_BLAST"),
	t("T_FEED"),
	t("T_WILLFUL_STRIKE"),
	t("T_REPROACH"),
	t("T_HATEFUL_WHISPER"),
	dist(3, "adjacent"),
}},

-- adventurer: whatever the trees rolled; a generic frame -------------------
["Adventurer"] = {steps={
	keep("T_PRECISE_STRIKES"),
	adjacent("T_DISENGAGE"),
	shoot(),
	bump(),
}},
}

-- API ---------------------------------------------------------------------------

--- The routine for this player's subclass with only the talents it knows; nil when none applies
function _M.default(player)
	if not player or not player.descriptor then return nil end
	local sub = player.descriptor.subclass
	local tpl = sub and _M.TEMPLATES[sub]
	if not tpl then return nil end
	local steps = {}
	for _, st in ipairs(tpl.steps) do
		if st.kind == "talent" then
			if st.tid and player:knowTalent(st.tid) then steps[#steps+1] = table.clone(st) end
		else
			-- bump / distance / swap / wait need nothing
			steps[#steps+1] = table.clone(st)
		end
	end
	-- a list that is nothing but movement or waiting helps nobody
	local useful = false
	for _, st in ipairs(steps) do if st.kind == "talent" or st.kind == "bump" then useful = true break end end
	if not useful then return nil end
	return {name=sub, mode=tpl.mode or "priority", steps=steps, pos=1}
end

--- Replace the active routine with the class routine; false when there is none
function _M.reset(player)
	local r = _M.default(player)
	if not r then return false end
	local rs = player.actRoutines and player:actRoutines() or player.act_routines
	if not rs then return false end
	player.act_active = util.bound(player.act_active or 1, 1, math.max(1, #rs))
	rs[player.act_active] = r
	print("[ACT] routine reset to the class template", r.name, #r.steps, "steps")
	return true
end

--- Does a template exist for this player's class (for the editor's menu entry)
function _M.available(player)
	return player and player.descriptor and _M.TEMPLATES[player.descriptor.subclass] ~= nil
end
