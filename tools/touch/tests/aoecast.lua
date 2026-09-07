-- Area talents through both cast paths against a clump of durable targets:
-- a ball (Fireflash), a range-0 circle (Chill of the Tomb) and a range-0 cone (Acid Breath).
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local p, map = game.player, game.level.map
	local m = game.uiset.touch_manual
	for _, e in pairs(game.level.entities) do
		if e.__is_actor and e ~= p and e.x and p:reactionToward(e) < 0 then map:remove(e.x, e.y, Map.ACTOR) game.level:removeEntity(e) end
	end
	local function free(x, y) return map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR) end
	local placed = false
	for r = 0, 14 do for x = math.floor(map.w / 2) - r, math.floor(map.w / 2) + r do for y = math.floor(map.h / 2) - r, math.floor(map.h / 2) + r do
		if not placed and free(x, y) and free(x + 3, y) and free(x + 3, y + 1) and free(x + 3, y - 1) and free(x + 2, y) and free(x + 1, y) and free(x + 1, y + 1) and free(x + 1, y - 1) then p:move(x, y, true) placed = true end
	end end if placed then break end end
	local x0, y0 = p.x, p.y
	local targets = {}
	for _, d in ipairs{{3, 0}, {3, 1}, {3, -1}, {1, 0}, {1, 1}, {1, -1}} do
		local a = game.zone:makeEntity(game.level, "actor", {type="vermin"}, nil, true)
		if a then
			game.zone:addEntity(game.level, a, "actor", x0 + d[1], y0 + d[2])
			a.faction = "enemies" a.ai = "none" a.never_move = 1 a.max_life = 1000000 a.life = 1000000 a.__hits = 0
			local o = a.takeHit a.takeHit = function(self, ...) self.__hits = self.__hits + 1 return o(self, ...) end
			targets[#targets+1] = a
		end
	end
	local npc = targets[1]
	p.invulnerable = 1 p:playerFOV() T.wait(300)
	m:setTarget(npc)
	local function reset() for _, a in ipairs(targets) do a.__hits = 0 end end
	local function touched() local n = 0 for _, a in ipairs(targets) do if a.__hits > 0 then n = n + 1 end end return n end
	local function settle() for _ = 1, 4 do if game.key ~= game.normal_key or game.target and game.target.active then pcall(T.key, "ACCEPT") T.wait(200) end end end
	-- projectiles (Fireflash...) only land when game time passes: let a few turns go by
	local function passTurns(n) for _ = 1, n or 3 do p.energy.value = 0 game.paused = false T.wait(120) end end
	local function refill() p.life = p.max_life for _, r in ipairs(p.resources_def or {}) do if r.short_name and p["max_"..r.short_name] and not r.invert_values then p[r.short_name] = p["max_"..r.short_name] end end end
	local bad = {}
	for _, tid in ipairs{"T_FIREFLASH", "T_CHILL_OF_THE_TOMB", "T_ACID_BREATH", "T_FAN_OF_KNIVES"} do
		p:learnTalent(tid, true, 3)
		local t = p:getTalentFromId(tid)
		refill() reset()
		local orig = p.getTarget
		p.getTarget = function(a, typ) local x, y, e = orig(a, typ) T.log("getTarget", tid, "->", tostring(x), tostring(y), e and e.name or "nil", "force", tostring(p.__talent_force_target)) return x, y, e end
		local ok, res, why = pcall(m.cast, m, tid, npc, true)
		T.wait(200) settle() passTurns(4)
		local mt = touched()
		p.getTarget = orig
		for _, a in ipairs(targets) do a.dead = false end
		p.talents_cd = {} refill() reset()
		local ok2, res2, why2 = pcall(p.actDo, p, {kind="talent", tid=tid, target="nearest", if_unusable="approach"})
		T.wait(200) settle() passTurns(4)
		local at = touched()
		T.log(("%s: manual %s %s touched %d | auto %s %s touched %d"):format(tid, tostring(ok and res), tostring(why or ""), mt, tostring(ok2 and res2), tostring(why2 or ""), at))
		if mt < 2 or at < 2 then bad[#bad+1] = tid end
		if t.mode == "sustained" and p:isTalentActive(tid) then pcall(p.forceUseTalent, p, tid, {ignore_energy=true}) end
		pcall(p.unlearnTalentFull, p, tid)
	end
	for _, b in ipairs(bad) do T.log("BAD", b, "covered fewer than 2 targets in a path") end
	T.log("finished")
end
