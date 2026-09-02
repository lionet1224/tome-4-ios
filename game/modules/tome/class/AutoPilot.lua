-- iOS port: automated soak-testing player + telemetry.
--
-- Enabled by config.settings.autopilot (settings/autopilot.cfg) or the
-- TE4_AUTOPILOT env var.
--
-- Policy: fight visible hostiles (using real talents), spend levelup
-- points, keep sustains up, rest when hurt, auto-explore, visit stores,
-- descend stairs, and tour the worldmap following the wiki's recommended
-- zone progression. God mode (default): killing blows are logged as
-- would_have_died telemetry and healed, so damage code paths still run
-- but runs go deep; TE4_AUTOPILOT_MORTAL=1 restores permadeath.
--
-- Telemetry: JSONL in /autopilot/telemetry-<ts>.jsonl (physfs write dir =
-- user save dir), consumed by tools/soak*.sh + tools/telemetry-summary.py.
-- Everything is pcall-guarded: the autopilot must never be the crash.

local Astar = require "engine.Astar"

local _M = {}

-- te4.org/wiki/Recommended_Zone_Order_Progression (Age of Ascendancy, west)
_M.PROGRESSION = {
	"trollmire", "kor-pul", "norgos-lair", "scintillating-caves",
	"rhaloren-camp", "heart-gloom", "deep-bellow", "arena",
	"old-forest", "maze", "sandworm-lair", "daikara",
	"halfling-ruins", "unknown-tunnels", "dreadfell", "reknor",
}

_M.state = {
	started = false, log = nil,
	last_turn = -1, last_progress_time = nil,
	stuck_count = 0, last_zone = nil,
	kills = 0, would_have_died = 0,
	last_heartbeat = 0, done = false,
	stairs_cache = nil, stairs_level = nil,
	visited_zones = {}, visited_stores = {},
	chat_answers = 0, acts = 0, equips = 0,
	level_key = nil, level_acts = 0, explore_noprog = 0, explored = false, last_act_turn = -1,
	arrival = nil, bad_stairs = {}, stairs_tries = 0, stairs_wait = 0,
	zone_done = {}, levels_seen = {},
}

-- env vars don't reach module Lua (sandboxed os); the soak harness writes
-- settings/autopilot.cfg instead
function _M.enabled()
	return config.settings.autopilot and true or false
end

-- os.exit does nothing on iOS; ask the engine to shut down instead
function _M.quit(code)
	_M.state.done = true
	pcall(os.exit, code or 0)
	pcall(function() core.game.exit_engine() end)
end

function _M.godmode()
	return not config.settings.autopilot_mortal
end

-- ---------------------------------------------------------------- telemetry

local function json_escape(s)
	return tostring(s):gsub('[%c"\\]', function(c) return string.format("\\u%04x", c:byte()) end)
end

function _M.event(kind, data)
	local st = _M.state
	if not st.log then
		local okd, errd = pcall(fs.mkdir, "/autopilot")
		local ok, f = pcall(fs.open, "/autopilot/telemetry-"..os.time()..".jsonl", "w")
		if not ok or not f then
			if not st.log_warned then
				st.log_warned = true
				print("[AUTOPILOT] TELEMETRY OPEN FAILED", tostring(okd), tostring(errd), tostring(ok), tostring(f))
			end
			return
		end
		print("[AUTOPILOT] telemetry open")
		st.log = f
	end
	local parts = {'"ev":"'..json_escape(kind)..'"', '"t":'..os.time(), '"turn":'..tostring(game.turn or -1)}
	if game.zone then parts[#parts+1] = '"zone":"'..json_escape(game.zone.short_name or "?")..'"' end
	if game.level and game.level.level then parts[#parts+1] = '"lvl":'..tostring(game.level.level) end
	for k, v in pairs(data or {}) do
		if type(v) == "number" or type(v) == "boolean" then
			parts[#parts+1] = '"'..json_escape(k)..'":'..tostring(v)
		else
			parts[#parts+1] = '"'..json_escape(k)..'":"'..json_escape(v)..'"'
		end
	end
	pcall(function()
		st.log:write("{"..table.concat(parts, ",").."}\n")
		st.log:flush()
	end)
end

-- ---------------------------------------------------------------- lifecycle

function _M.setup()
	local st = _M.state
	if st.started then return end
	st.started = true
	st.last_progress_time = os.time()

	local sha = config.settings.autopilot_build or "dev"
	print("[AUTOPILOT] active, god="..tostring(_M.godmode()))

	-- soak speed: no per-tile movement animation or smooth map scrolling
	-- (walking was ~8 frames per step; fighting had no such cost)
	pcall(function()
		config.settings.tome.smooth_move = 0
		config.settings.tome.twitch_move = false
		require("engine.Map").smooth_scroll = 0
	end)
	_M.event("session_start", {build=sha, platform=(__IOS__ and "ios" or "desktop"), god=_M.godmode()})

	local Player = require "mod.class.Player"
	local oldact = Player.act
	Player.act = function(self, ...)
		local r = oldact(self, ...)
		if _M.enabled() and not _M.state.done then
			local okp, err = pcall(_M.onPlayerAct, _M, self)
			if not okp then _M.event("autopilot_error", {err=tostring(err)}) end
		end
		return r
	end

	-- count engine ticks to see whether the game loop is alive at all
	local Game = require "mod.class.Game"
	local oldtick = Game.tick
	Game.tick = function(self, ...)
		_M.state.ticks = (_M.state.ticks or 0) + 1
		return oldtick(self, ...)
	end

	local Actor = require "mod.class.Actor"
	local olddie = Actor.die
	Actor.die = function(self, src, ...)
		if src == game.player and self ~= game.player then
			_M.state.kills = _M.state.kills + 1
			_M.event("kill", {victim=self.name or "?"})
		end
		if self == game.player and _M.godmode() then
			_M.state.would_have_died = _M.state.would_have_died + 1
			_M.event("would_have_died", {source=(src and src.name) or "?", count=_M.state.would_have_died})
			self.life = self.max_life
			self.dead = false
			return
		end
		return olddie(self, src, ...)
	end
end

-- dialogs that actually block play: everything except auto-explore's own
-- "Running..." progress popup, which is expected while a run is in flight
function _M.blockingDialogs()
	local n = 0
	for _, d in ipairs(game.dialogs) do
		local t = d.title and tostring(d.title) or ""
		if not (t:find("Running") or t:find("Resting")) then n = n + 1 end
	end
	return n
end

-- one action per open dialog: answer chats, spend-then-close levelups,
-- drive stores (buy one, sell one, leave), accept quantity prompts,
-- close everything else
function _M.handleDialog(d)
	local cls = d.__CLASSNAME or "?"
	-- auto-explore/run progress popup: dismissing it *stops the run*, so
	-- leave it while a run is live; once the run is over it just lingers
	if d.title and (tostring(d.title):find("Running") or tostring(d.title):find("Resting")) then
		-- keep the popup that belongs to the *current* activity; a leftover
		-- one (e.g. "Running..." while resting) makes the engine abort the
		-- rest every turn with "dialog is displayed"
		local p = game.player
		local t = tostring(d.title)
		local live = p and ((t:find("Running") and p.running) or (t:find("Resting") and p.resting))
		if live then return end
		_M.event("dialog_dismiss", {dialog=cls, title=t.." (stale)"})
		pcall(function() d.key:triggerVirtual("EXIT") end)
		return
	end
	-- sealed vault door popup: tell auto-explore to stop targeting the door
	if d.title and tostring(d.title):find("sealed door") then
		local p = game.player
		if p and game.level then
			local map = game.level.map
			for dx = -1, 1 do for dy = -1, 1 do
				local g = map(p.x + dx, p.y + dy, map.TERRAIN)
				-- vault doors carry door_player_check/door_player_stop; that is the
				-- pair auto-explore consults together with autoexplore_ignore
				if g and (g.door_player_check or g.door_player_stop or g.door_opened or g.is_door) then
					map.attrs(p.x + dx, p.y + dy, "autoexplore_ignore", true)
				end
			end end
		end
		-- fall through: the prompt is a yes/no, answered Yes below (opens the vault)
	end
	-- "Danger..." (descending to a level above our rank) and similar yes/no
	-- prompts where the bot wants to proceed: press the Yes button
	local title = d.title and tostring(d.title) or ""
	if title:find("Danger") or title:find("sealed door") then
		-- prefer a Yes/Open/Ok button; otherwise the first button is the
		-- positive one in the engine's prompt helpers
		local first
		for _, ui in ipairs(d.uis or {}) do
			local u = ui.ui
			if u and u.fct and u.text then
				local t = tostring(u.text)
				if t:find("Yes") or t:find("Open") or t:find("Ok") then
					_M.event("dialog_yes", {dialog=cls, title=title, button=t})
					pcall(function() u.fct() end)
					return
				end
				first = first or u
			end
		end
		if first then
			_M.event("dialog_yes", {dialog=cls, title=title, button=tostring(first.text)})
			pcall(function() first.fct() end)
			return
		end
	end
	if cls:find("GetQuantity") then
		_M.event("quantity_accept", {})
		if not pcall(function() d:okclick() end) then pcall(function() d.key:triggerVirtual("EXIT") end) end
		return
	end
	if cls:find("ShowStore") then
		local step = d.__ap_step or 0
		d.__ap_step = step + 1
		if step == 0 and d.store_list and #d.store_list > 0 and d.action then
			local it = d.store_list[rng.range(1, #d.store_list)]
			if it and it.object then
				_M.event("store_buy", {name=it.object.name or "?"})
				pcall(function() d.action("buy", it.object, it.item) end)
				return
			end
		elseif step == 1 and d.inven_list and #d.inven_list > 0 and d.action then
			local it = d.inven_list[rng.range(1, #d.inven_list)]
			if it and it.object then
				_M.event("store_sell", {name=it.object.name or "?"})
				pcall(function() d.action("sell", it.object, it.item) end)
				return
			end
		end
		_M.event("dialog_dismiss", {dialog=cls})
		pcall(function() d.key:triggerVirtual("EXIT") end)
		return
	end
	if cls:find("Chat") and d.list and #d.list > 0 and d.use then
		_M.state.chat_answers = _M.state.chat_answers + 1
		local pick = rng.range(1, #d.list)
		_M.event("chat_answer", {dialog=cls, pick=pick, of=#d.list})
		local ok = pcall(function() d:use(d.list[pick]) end)
		if ok then return end
	end
	-- (levelup points are spent on the next player turn, NOT here: touching
	-- the counters while LevelupDialog is open triggers its accept-changes
	-- confirm, whose cancel-on-EXIT loops forever)
	_M.event("dialog_dismiss", {dialog=cls, title=tostring(d.title or "")})
	pcall(function() d.key:triggerVirtual("EXIT") end)
end

function _M.frame()
	local st = _M.state
	if not st.started then _M.setup() end
	if st.done then return end
	local now = os.time()

	-- periodic in-game screenshot (engine glReadPixels -> PNG in
	-- <module>/screenshots/) so visual glitches like the minimap-rat get
	-- caught by review, on mac and sim alike
	if game.level and now - (st.last_shot or 0) >= 60 then
		st.last_shot = now
		local ok = pcall(function() game:saveScreenshot() end)
		_M.event("screenshot", {ok=ok and true or false})
	end

	if now - st.last_heartbeat >= 5 then
		st.last_heartbeat = now
		local p = game.player
		if p and not p.dead then
			_M.event("heartbeat", {life=math.floor(p.life or 0), max_life=math.floor(p.max_life or 0),
				plevel=p.level or 0, kills=st.kills, chats=st.chat_answers, acts=st.acts,
				mem_kb=math.floor(collectgarbage("count"))})
		end
		if game.turn ~= st.last_turn then
			st.last_turn = game.turn
			st.last_progress_time = now
		elseif now - st.last_progress_time > 90 then
			_M.event("stalled", {seconds=now - st.last_progress_time})
			_M.quit(3)
		end
	end

	-- only treat death as final once we have actually played a turn
	-- (during module load game.player can be a dead placeholder)
	if st.ingame and game.player and game.player.dead then
		_M.event("death", {kills=st.kills})
		_M.quit(0)
	end

	-- UI overflow detector: any dialog poking outside the screen is a bug
	-- of the birther-Play-button class; log geometry for every new dialog
	for _, d in ipairs(game.dialogs) do
		if not d.__ap_geom_checked then
			d.__ap_geom_checked = true
			local dw, dh, dx, dy = d.w or 0, d.h or 0, d.display_x or 0, d.display_y or 0
			if dx < 0 or dy < 0 or dx + dw > game.w or dy + dh > game.h then
				_M.event("ui_overflow", {dialog=d.__CLASSNAME or "?",
					x=math.floor(dx), y=math.floor(dy), w=math.floor(dw), h=math.floor(dh),
					sw=game.w, sh=game.h})
			end
		end
	end

	if #game.dialogs > 0 then
		local d = game.dialogs[#game.dialogs]
		if d and d.key then pcall(_M.handleDialog, d) end
		if not d.__ap_seen then d.__ap_seen = true; _M.event("dialog_seen", {dialog=d.__CLASSNAME or "?", title=tostring(d.title or "")}) end
	end

	local zname = game.zone and game.zone.short_name
	if zname and zname ~= st.last_zone then
		st.last_zone = zname
		st.stairs_cache = nil
		st.visited_zones[zname] = true
		_M.event("zone_change", {})
	end

	-- the real driver: when the game is paused awaiting player input and no
	-- dialog is up, run the player's act() — the engine's own method handles
	-- rest/run continuation, and the wrapped act calls our policy when idle
	local p = game.player
	if now - (st.last_guard_log or 0) >= 10 then
		st.last_guard_log = now
		_M.event("guard", {paused=game.paused and true or false, has_p=p and true or false,
			dead=(p and p.dead) and true or false, has_x=(p and p.x) and true or false,
			dialogs=#game.dialogs, has_zone=game.zone and true or false,
			has_level=game.level and true or false, acts=st.acts,
			creating=game.creating_player and true or false,
			energy=(p and p.energy and math.floor(p.energy.value)) or -1,
			ticks=st.ticks or 0, in_level=(p and game.level and game.level:hasEntity(p)) and true or false})
	end
	if game.paused and p and not p.dead and p.x and _M.blockingDialogs() == 0
	   and game.zone and game.level then
		local okp, err = pcall(function() p:act() end)
		if not okp then _M.event("autopilot_error", {err=tostring(err)}) end
	end

	-- headless drive: with no human input the C loop stops requesting
	-- ticks (its idle optimization waits for SDL events). Tick from the
	-- display callback instead - the engine itself notes this is valid.
	-- run several game ticks per frame (time-bounded) so resting, fighting
	-- and walking all advance at the same brisk pace instead of one turn per
	-- rendered frame
	if game.tick then
		local t0 = os.clock()
		local n = 0
		repeat
			local ok = pcall(function() game:tick() end)
			n = n + 1
		until not ok or n >= 12 or (os.clock() - t0) > 0.02
	end
end

-- ---------------------------------------------------------------- levelup

local STAT_IDS = {"str", "dex", "con", "mag", "wil", "cun"}

function _M:spendPoints(p)
	local spent = 0
	-- stats
	while (p.unused_stats or 0) > 0 and spent < 30 do
		local sid = STAT_IDS[rng.range(1, #STAT_IDS)]
		local ok = pcall(function() p:incStat(sid, 1) end)
		p.unused_stats = p.unused_stats - 1
		spent = spent + 1
		if ok then _M.event("spend_stat", {stat=sid}) end
	end
	-- talents: random learnable from known categories
	local tries = 0
	while ((p.unused_talents or 0) > 0 or (p.unused_generics or 0) > 0) and tries < 60 do
		tries = tries + 1
		local cands = {}
		for tt, known in pairs(p.talents_types or {}) do
			if known then
				local ttdef = p.talents_types_def[tt]
				if ttdef and ttdef.talents then
					for _, t in ipairs(ttdef.talents) do
						local pool = t.generic and "unused_generics" or "unused_talents"
						if (p[pool] or 0) > 0
						   and (p:getTalentLevelRaw(t.id) or 0) < (t.points or 5)
						   and p:canLearnTalent(t) then
							cands[#cands+1] = {t=t, pool=pool}
						end
					end
				end
			end
		end
		if #cands == 0 then break end
		local c = cands[rng.range(1, #cands)]
		local ok = pcall(function() p:learnTalent(c.t.id, true) end)
		if ok then
			p[c.pool] = p[c.pool] - 1
			_M.event("learn_talent", {talent=c.t.id, pool=c.pool})
		else
			break
		end
	end
	-- zero whatever we can't spend (category points, prodigies, leftovers)
	-- so the levelup dialog's "unspent points" confirm never loops us
	p.unused_stats = 0
	p.unused_talents = 0
	p.unused_generics = 0
	p.unused_talents_types = 0
	p.unused_prodigies = math.min(p.unused_prodigies or 0, 0)
end

-- ---------------------------------------------------------------- policy

-- pick the earliest wiki-progression zone we haven't done; fall back to
-- nearest unvisited entrance
function _M:findZoneEntrance(p)
	local map = game.level.map
	local entrances = {}
	for x = 0, map.w - 1 do for y = 0, map.h - 1 do
		local g = map(x, y, map.TERRAIN)
		if g and g.change_zone and not self.state.visited_zones[g.change_zone] then
			entrances[#entrances+1] = {x=x, y=y, zone=g.change_zone,
				dist=core.fov.distance(p.x, p.y, x, y)}
		end
	end end
	if #entrances == 0 then return nil end
	for _, want in ipairs(_M.PROGRESSION) do
		for _, e in ipairs(entrances) do
			if e.zone:find(want, 1, true) then return e end
		end
	end
	table.sort(entrances, function(a, b) return a.dist < b.dist end)
	return entrances[1]
end

local function findStairs()
	local st = _M.state
	local lvl = game.level
	if not lvl then return nil end
	local leaving = game.zone and st.zone_done[game.zone.short_name]
	local key = (game.zone and game.zone.short_name or "?")..":"..tostring(lvl.level or 0)
	if st.stairs_cache and st.stairs_level == key then return st.stairs_cache end
	local map = lvl.map
	local best, fallback = nil, nil
	for x = 0, map.w - 1 do for y = 0, map.h - 1 do
		local g = map(x, y, map.TERRAIN)
		if g and g.change_level and not st.bad_stairs[x..":"..y] then
			local cl = g.change_level or 0
			if not g.change_zone and cl > 0 then
				-- in-zone stairs going deeper: what we want
				if not best or cl > best.cl then best = {x=x, y=y, cl=cl} end
			elseif g.change_zone and not fallback then
				-- zone exit (worldmap etc.): only if this zone has nothing deeper
				fallback = {x=x, y=y, cl=cl}
			elseif cl < 0 and leaving and not fallback then
				-- zone exhausted: retrace up toward the exit
				fallback = {x=x, y=y, cl=cl}
			end
		end
	end end
	if leaving then best = fallback or best else best = best or fallback end
	st.stairs_cache = best
	st.stairs_level = key
	return best
end

local function findStore(p)
	local map = game.level.map
	for x = 0, map.w - 1 do for y = 0, map.h - 1 do
		local g = map(x, y, map.TERRAIN)
		if g and g.store then
			local key = (game.zone.short_name or "?")..":"..x..":"..y
			if not _M.state.visited_stores[key] then
				return {x=x, y=y, key=key}
			end
		end
	end end
	return nil
end

local function stepToward(p, tx, ty)
	local a = Astar.new(game.level.map, p)
	local path = a:calc(p.x, p.y, tx, ty)
	if path and path[1] then
		p:move(path[1].x, path[1].y)
		return true
	end
	return false
end

-- try a real activated talent on the target; falls back to a melee bump
local function tryCombatTalent(p, target)
	if rng.percent(50) then return false end -- half the time, plain attacks
	local cands = {}
	for tid, lvl in pairs(p.talents or {}) do
		local t = p:getTalentFromId(tid)
		if t and t.mode == "activated" and not p:isTalentCoolingDown(t) and not t.no_npc_use then
			cands[#cands+1] = tid
		end
	end
	if #cands == 0 then return false end
	local tid = cands[rng.range(1, #cands)]
	local ok, used = pcall(function() return p:useTalent(tid, nil, nil, nil, target) end)
	if ok and used then
		_M.event("use_talent", {talent=tid})
		return true
	end
	return false
end

local function keepSustainsUp(p)
	for tid, lvl in pairs(p.talents or {}) do
		local t = p:getTalentFromId(tid)
		if t and t.mode == "sustained" and not p:isTalentActive(tid) and not p:isTalentCoolingDown(t) then
			local ok, used = pcall(function() return p:useTalent(tid) end)
			if ok and used then
				_M.event("sustain_on", {talent=tid})
				return true
			end
		end
	end
	return false
end

function _M:onPlayerAct(p)
	if not game.level or not game.zone then return end
	if p.dead then return end
	if p.resting or p.running then return end
	if _M.blockingDialogs() > 0 then return end

	-- spend any levelup points that arrived outside the dialog
	if (p.unused_stats or 0) > 0 or (p.unused_talents or 0) > 0 or (p.unused_generics or 0) > 0 then
		self:spendPoints(p)
	end

	if game.zone.wilderness then
		local ent = self:findZoneEntrance(p)
		if not ent then
			_M.event("world_tour_complete", {kills=self.state.kills})
			_M.quit(0)
			return
		end
		if p.x == ent.x and p.y == ent.y then
			_M.event("enter_zone", {zone=ent.zone or "?"})
			game.key:triggerVirtual("CHANGE_LEVEL")
		elseif not stepToward(p, ent.x, ent.y) then
			p:useEnergy()
			self.state.stuck_count = self.state.stuck_count + 1
		end
		return
	end

	self.state.acts = self.state.acts + 1
	self.state.ingame = true

	-- pick up whatever we are standing on, item by item (playerPickup opens
	-- the ShowPickupFloor chooser when several items lie here, which on a
	-- 402pt screen also overflows - ui_overflow caught that on the sim)
	if game.level.map:getObject(p.x, p.y, 1) then
		local n = 0
		local ok = pcall(function()
			while game.level.map:getObject(p.x, p.y, 1) and n < 20 do
				if not p:pickupFloor(1, true) then break end
				n = n + 1
			end
		end)
		if ok and n > 0 then _M.event("pickup", {items=n}) return end
		-- couldn't pick (full pack, etc.): fall through so we don't loop
	end

	-- periodic equip churn: wear something wearable from the pack
	-- (exercises wear/takeoff + stat recomputation, a classic bug nest)
	if self.state.acts % 40 == 0 then
		local inven = p:getInven(p.INVEN_INVEN)
		if inven then
			local wearables = {}
			for i, o in ipairs(inven) do
				if o:wornInven() then wearables[#wearables+1] = {o=o, idx=i} end
			end
			if #wearables > 0 then
				local pick = wearables[rng.range(1, #wearables)]
				-- same order as the game's doWear: remove, wear, restore on failure
				pcall(function() p:removeObject(inven, pick.idx, true) end)
				local ok, worn = pcall(function() return p:wearObject(pick.o, true, false) end)
				if ok and worn then
					self.state.equips = self.state.equips + 1
					_M.event("equip", {name=pick.o.name or "?"})
				else
					pcall(function() p:addObject(inven, pick.o) end)
				end
				return
			end
		end
	end
	-- TODO: item activation (wands/charms) needs targeting-mode escape
	-- handling before it can be automated safely

	local hostiles = p:spotHostiles(true)
	if #hostiles > 0 then
		local best, bd
		for _, h in ipairs(hostiles) do
			local d = core.fov.distance(p.x, p.y, h.x, h.y)
			if not bd or d < bd then best, bd = h, d end
		end
		if tryCombatTalent(p, best.actor) then return end
		if bd <= 1 then
			p:attackTarget(best.actor)
		elseif not stepToward(p, best.x, best.y) then
			p:useEnergy()
			self.state.stuck_count = self.state.stuck_count + 1
		end
		return
	end

	if keepSustainsUp(p) then return end

	if p.life < p.max_life * 0.7 then
		p:restInit()
		return
	end

	-- per-level bookkeeping
	local lkey = (game.zone.short_name or "?")..":"..tostring(game.level.level or 0)
	if lkey ~= self.state.level_key then
		local zdone = self.state.zone_done[game.zone.short_name]
		local seen_before = self.state.levels_seen[lkey]
		self.state.levels_seen[lkey] = true
		self.state.level_key, self.state.level_acts, self.state.explore_noprog = lkey, 0, 0
		self.state.explored = (zdone and seen_before) and true or false
		self.state.arrival = {x=p.x, y=p.y}
		self.state.bad_stairs, self.state.stairs_tries, self.state.stairs_wait, self.state.stairs_cache = {}, 0, 0, nil
	end
	self.state.level_acts = self.state.level_acts + 1

	if not self.state.explored then
		-- auto-explore's terminal move is "go stand on an exit": if we are on
		-- a level-change tile with nothing pulling us elsewhere, we're done
		local here = game.level.map(p.x, p.y, game.level.map.TERRAIN)
		local arr = self.state.arrival
		local on_arrival = arr and arr.x == p.x and arr.y == p.y
		if here and here.change_level and not on_arrival
		   and ((here.change_level or 0) > 0 or here.change_zone) and self.state.level_acts > 5 then
			self.state.explored = true
			_M.event("level_explored", {acts=self.state.level_acts, reason="at_exit"})
		end
	end
	if not self.state.explored then
		local started = p:autoExplore()
		if started and game.turn ~= self.state.last_act_turn then
			self.state.last_act_turn = game.turn
			self.state.explore_noprog = 0
			return
		end
		-- explore returned nothing, or keeps "starting" without the clock moving
		self.state.explore_noprog = self.state.explore_noprog + 1
		if not started or self.state.explore_noprog >= 3 or self.state.level_acts > 400 then
			self.state.explored = true
			_M.event("level_explored", {acts=self.state.level_acts, reason=(not started) and "done" or "noprog"})
		else
			p:useEnergy()
			return
		end
	end

	-- explored: browse an unvisited store, then take the stairs
	local store = findStore(p)
	if store then
		if core.fov.distance(p.x, p.y, store.x, store.y) <= 1 then
			-- bumping the store tile opens it (block_move hook)
			self.state.visited_stores[store.key] = true
			_M.event("store_visit", {})
			p:move(store.x, store.y)
		elseif not stepToward(p, store.x, store.y) then
			self.state.visited_stores[store.key] = true -- unreachable; skip
		end
		return
	end

	local stairs = findStairs()
	if not stairs and game.zone and not self.state.zone_done[game.zone.short_name] then
		-- explored, nothing deeper, no exit here: this zone is finished
		self.state.zone_done[game.zone.short_name] = true
		self.state.stairs_cache = nil
		_M.event("zone_done", {})
		stairs = findStairs()
	end
	if stairs then
		if p.x == stairs.x and p.y == stairs.y then
			if self.state.stairs_wait > 0 then
				self.state.stairs_wait = self.state.stairs_wait - 1
				p:useEnergy()
				return
			end
			self.state.stairs_tries = self.state.stairs_tries + 1
			if self.state.stairs_tries > 3 then
				_M.event("stairs_dead", {x=stairs.x, y=stairs.y})
				self.state.bad_stairs[stairs.x..":"..stairs.y] = true
				self.state.stairs_cache, self.state.stairs_tries = nil, 0
				p:useEnergy()
				return
			end
			_M.event("take_stairs", {try=self.state.stairs_tries})
			self.state.stairs_wait = 5
			game.key:triggerVirtual("CHANGE_LEVEL")
		elseif not stepToward(p, stairs.x, stairs.y) then
			p:useEnergy()
			self.state.stuck_count = self.state.stuck_count + 1
		end
		return
	end

	p:useEnergy()
	self.state.stuck_count = self.state.stuck_count + 1
	if self.state.stuck_count > 200 then
		_M.event("stuck", {count=self.state.stuck_count})
		_M.quit(3)
	end
end

return _M
