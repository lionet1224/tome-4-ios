-- Every activatable talent, cast once by hand (TouchManual:cast) and once by the routine (Player:actDo).
-- Records per talent: ok / refused (reason) / error. Lua errors also land in the console log next to the
-- "[SOAK] talent" marker for attribution.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local Actor = require "mod.class.Actor"
	local p, map = game.player, game.level.map
	local m = game.uiset.touch_manual
	local zone0 = game.zone.short_name
	-- a safe arena: no hostiles, an invulnerable target that never moves, god mode for us
	for _, e in pairs(game.level.entities) do
		if e.__is_actor and e ~= p and e.x and p:reactionToward(e) < 0 then map:remove(e.x, e.y, Map.ACTOR) game.level:removeEntity(e) end
	end
	local function free(x, y) return map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR) end
	local placed = false
	for r = 0, 14 do for x = math.floor(map.w / 2) - r, math.floor(map.w / 2) + r do for y = math.floor(map.h / 2) - r, math.floor(map.h / 2) + r do
		if not placed and free(x, y) and free(x + 3, y) and free(x + 3, y + 1) and free(x + 3, y - 1) and free(x + 2, y) and free(x + 1, y) and free(x + 1, y + 1) and free(x + 1, y - 1) and free(x - 1, y) then p:move(x, y, true) placed = true end
	end end if placed then break end end
	local x0, y0 = p.x, p.y
	-- three durable targets in a clump 3 tiles away: the middle one is the aim,
	-- the two beside it tell us whether an area talent really covered an area
	local function mkTarget(x, y)
		local a = game.zone:makeEntity(game.level, "actor", {type="vermin"}, nil, true)
		if not a then return nil end
		game.zone:addEntity(game.level, a, "actor", x, y)
		a.faction = "enemies" a.ai = "none" a.never_move = 1
		a.max_life = 1000000 a.life = 1000000 a.__hits = 0
		a.__home = {x=x, y=y}
		local origHit = a.takeHit
		a.takeHit = function(self, ...) self.__hits = (self.__hits or 0) + 1 return origHit(self, ...) end
		local origOn = a.onTakeHit
		a.onTakeHit = function(self, ...) self.__hits = (self.__hits or 0) + 1 return origOn(self, ...) end
		local origEff = a.setEffect
		a.setEffect = function(self, ...) self.__hits = (self.__hits or 0) + 1 return origEff(self, ...) end
		return a
	end
	-- two clumps: adjacent (self-centred areas) and three tiles out (aimed areas)
	local targets = {}
	for _, d in ipairs{{3, 0}, {3, 1}, {3, -1}, {1, 0}, {1, 1}, {1, -1}} do local a = mkTarget(x0 + d[1], y0 + d[2]) if a then targets[#targets+1] = a end end
	local npc = targets[1]
	if not npc then T.log("no npc") T.log("finished") return end
	local nx0, ny0 = npc.x, npc.y
	p.invulnerable = 1 p.no_breath = 1
	p:playerFOV() T.wait(300)
	m:setTarget(npc)
	local function resetHits() for _, a in ipairs(targets) do a.__hits = 0 a.life = a.max_life end end
	local function touched() local n = 0 for _, a in ipairs(targets) do if (a.__hits or 0) > 0 then n = n + 1 end end return n end
	local function isArea(t)
		local ok, tg = pcall(p.getTalentTarget, p, t)
		if not ok or type(tg) ~= "table" then return false end
		if tg.type == "self" then return false end
		return (tg.radius and tg.radius >= 1) or tg.type == "cone" or tg.type == "beam" or tg.type == "wall" or tg.type == "ball" or tg.type == "widebeam"
	end

	local stats = {manual_ok=0, manual_refused=0, manual_error=0, auto_ok=0, auto_refused=0, auto_error=0, zone=0}
	local function refill()
		p.life = p.max_life
		for _, res in ipairs(p.resources_def or {}) do
			local sn = res.short_name
			if res.invert_values then if p["min_"..sn] then p[sn] = p["min_"..sn] end
			elseif p["max_"..sn] then p[sn] = p["max_"..sn] end
		end
		p.talents_cd = {}
		p.energy.value = game.energy_to_act
	end
	local function settle()
		-- confirm an aim, close popups, come back home
		for _ = 1, 4 do
			-- a talent's action can error when the aim is confirmed: keep the soak alive and note it
			if game.key ~= game.normal_key then local ok, e = pcall(T.key, "ACCEPT") if not ok then T.log("ACTION ERROR on confirm:", tostring(e):sub(1, 160)) stats.confirm_error = (stats.confirm_error or 0) + 1 end T.wait(120) end
			if game.key ~= game.normal_key then pcall(T.key, "EXIT") T.wait(120) end
			if #game.dialogs > 0 then pcall(T.key, "EXIT") T.wait(120) else break end
		end
		if game.zone.short_name ~= zone0 then return false end
		if p.x ~= x0 or p.y ~= y0 then if free(x0, y0) then p:move(x0, y0, true) end end
		for i, a in ipairs(targets) do
			if a.dead or not a.x then
				local nt = mkTarget(a.__home.x, a.__home.y)
				if nt then targets[i] = nt if i == 1 then npc = nt m:setTarget(npc) end end
			elseif (a.x ~= a.__home.x or a.y ~= a.__home.y) and free(a.__home.x, a.__home.y) then a:move(a.__home.x, a.__home.y, true) end
		end
		-- talents that hand control to another body (Ambuscade, possession): take it back
		if game.player ~= p then pcall(game.party.select, game.party, p) T.wait(150) end
		if game.player ~= p then T.log("CONTROL LOST after a talent; stopping") return false end
		-- extra party members some talents summon would otherwise pile up
		for _, a in ipairs(game.party.m_list or {}) do if a ~= p and a.summoner == p and a.x then pcall(a.die, a) end end
		-- effects wear off / stun etc. would block the next cast
		pcall(p.removeAllEffects, p) p.energy.value = game.energy_to_act
		pcall(p.playerFOV, p)
		return true
	end

	-- the talents: every activated or sustained one that is not NPC-only
	local list = {}
	for tid, t in pairs(Actor.talents_def) do
		if (t.mode == "activated" or t.mode == "sustained") and not (t.type and t.type[1]:find("^other/npcs")) then list[#list+1] = t end
	end
	table.sort(list, function(a, b) return a.id < b.id end)
	local limit = tonumber(config.settings.touch.soak_limit or 0)
	local from = tonumber(config.settings.touch.soak_from or 1)
	-- plane-shifting talents (Fearscape...) must not carry the arena away: refuse level changes
	local blockedLevel = 0
	game.changeLevel = function(self, ...) blockedLevel = blockedLevel + 1 T.log("blocked changeLevel") end
	if limit > 0 and #list > limit then local l2 = {} for i = 1, limit do l2[i] = list[i] end list = l2 end
	T.log("talents to exercise:", #list)

	-- (stats declared below; settle references it)
	local bad = {}
	-- object-granted copies (T_INFUSION:_HEALING_4...) need their item: not player talents
	for i, t in ipairs(list) do if i >= from and not t.id:find(":", 1, true) then
		local tid = t.id
		print("[SOAK] talent", i, tid, t.name)
		local learned = pcall(function() p:learnTalent(tid, true, 1) end)
		refill() resetHits()
		local area = isArea(t)
		-- manual: the strip's path
		local ok, res, why = pcall(m.cast, m, tid, npc, true)
		T.wait(150)
		-- the aim may have opened: settle confirms it, so count only afterwards
		if not settle() then T.log("ZONE CHANGED by", tid) stats.zone = stats.zone + 1 T.log("finished") return end
		T.wait(100)
		local mtouch = touched()
		local mres
		if not ok then mres = "ERROR "..tostring(res):sub(1, 80) stats.manual_error = stats.manual_error + 1 bad[#bad+1] = tid.." manual: "..mres
		elseif res then mres = "ok" stats.manual_ok = stats.manual_ok + 1
		else mres = "refused: "..tostring(why) stats.manual_refused = stats.manual_refused + 1 end
		refill() resetHits()
		-- auto: the routine's path (area talents through the best-area rule)
		local ok2, res2, why2 = pcall(p.actDo, p, {kind="talent", tid=tid, target=area and "best_aoe" or "nearest", if_unusable="approach"})
		T.wait(150)
		if not settle() then T.log("ZONE CHANGED by", tid) stats.zone = stats.zone + 1 T.log("finished") return end
		T.wait(100)
		local atouch = touched()
		local ares
		if not ok2 then ares = "ERROR "..tostring(res2):sub(1, 80) stats.auto_error = stats.auto_error + 1 bad[#bad+1] = tid.." auto: "..ares
		elseif res2 then ares = "ok" stats.auto_ok = stats.auto_ok + 1
		else ares = "refused: "..tostring(why2) stats.auto_refused = stats.auto_refused + 1 end
		if i % 25 == 0 then T.log(("progress %d/%d"):format(i, #list)) end
		if mres:find("^ERROR") or ares:find("^ERROR") then T.log("TALENT", tid, "manual", mres, "| auto", ares) end
		if area then
			stats.area = (stats.area or 0) + 1
			local mok, aok = mres == "ok", ares == "ok"
			local anomaly = t.type and t.type[1]:find("anomal")
			if (mok and mtouch < 2) or (aok and atouch < 2) then
				if anomaly then stats.area_anomaly = (stats.area_anomaly or 0) + 1 -- not player-cast: informational
				else
					stats.area_bad = (stats.area_bad or 0) + 1
					T.log(("AOE %s: manual %s touched %d | auto %s touched %d"):format(tid, mres, mtouch, ares, atouch))
					bad[#bad+1] = tid.." area covered "..mtouch.."/"..atouch.." targets"
				end
			end
		end
		-- sustains: turn them off again so they do not stack up
		if t.mode == "sustained" and p:isTalentActive(tid) then pcall(p.forceUseTalent, p, tid, {ignore_energy=true}) end
		pcall(p.unlearnTalentFull, p, tid)
	end end
	if blockedLevel > 0 then T.log("blocked level changes:", blockedLevel) end
	T.log(("SUMMARY manual ok %d refused %d error %d | auto ok %d refused %d error %d | area talents %d, %d covered fewer than 2 targets | %d action errors on confirm"):format(stats.manual_ok, stats.manual_refused, stats.manual_error, stats.auto_ok, stats.auto_refused, stats.auto_error, stats.area or 0, stats.area_bad or 0, stats.confirm_error or 0))
	for _, b in ipairs(bad) do T.log("BAD", b) end
	T.log("finished")
end
