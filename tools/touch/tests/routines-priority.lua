-- Priority mode: every tap runs the first step that applies and works; a cooling talent is
-- retried as soon as it is ready, a step whose condition fails is skipped, and out-of-combat
-- steps never run with enemies in view.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local p, map = game.player, game.level.map
	for _, e in pairs(game.level.entities) do
		if e.__is_actor and e ~= p and e.x and p:reactionToward(e) < 0 then map:remove(e.x, e.y, Map.ACTOR) game.level:removeEntity(e) end
	end
	local function free(x, y) return map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR) end
	local placed = false
	for r = 0, 14 do for x = math.floor(map.w / 2) - r, math.floor(map.w / 2) + r do for y = math.floor(map.h / 2) - r, math.floor(map.h / 2) + r do
		if not placed and free(x, y) and free(x + 1, y) and free(x + 2, y) then p:move(x, y, true) placed = true end
	end end if placed then break end end
	local function mk(dx, dy)
		local a = game.zone:makeEntity(game.level, "actor", {type="vermin"}, nil, true)
		if not a then return nil end
		game.zone:addEntity(game.level, a, "actor", p.x + dx, p.y + dy)
		a.faction = "enemies" a.ai = "none" a.never_move = 1 a.max_life = 100000 a.life = 100000 a.invisible = nil a.stealth = nil
		return a
	end
	local enemy = mk(1, 0)
	if not enemy then T.log("no enemy") T.log("finished") return end
	p.invulnerable = 1 p:playerFOV() T.wait(300)
	-- a known activated talent with a cooldown that works on an adjacent enemy (a melee technique)
	local tid
	for id, lv in pairs(p.talents) do
		local t = p:getTalentFromId(id)
		if t and t.mode == "activated" and t.cooldown and (t.type[1]:find("^technique/") or t.type[1]:find("^cunning/")) and not t.no_energy and p:preUseTalent(t, true, true) then
			local ok, tg = pcall(p.getTalentTarget, p, t)
			if ok and tg and (tg.type == "hit" or tg.type == "bolt") and (p:getTalentRange(t) or 1) >= 1 then tid = id break end
		end
	end
	if not tid then T.log("note: no melee technique known, using any activated talent") for id, lv in pairs(p.talents) do local t = p:getTalentFromId(id) if t and t.mode == "activated" and t.cooldown then tid = id break end end end
	local t = p:getTalentFromId(tid)
	T.log("talent", t.name, "cooldown", tostring(util.getval(t.cooldown, p, t)))
	local r = p:actRoutine()
	r.mode = "priority"
	r.steps = {
		{kind="talent", tid=tid, target="nearest", if_unusable="skip"},
		{kind="wait", cond="no_enemies"},        -- must never run while the enemy stands here
		{kind="bump", target="nearest", if_unusable="approach", cond="group"}, -- one enemy: skipped
		{kind="bump", target="nearest", if_unusable="approach"},
	}
	T.log("mode", r.mode, "steps", #r.steps)
	local fired, bumps, waits = {}, 0, 0
	local turn0 = game.turn
	for tap = 1, 6 do
		local cd0 = p.talents_cd[tid] or 0
		local life0 = enemy.life
		p:actStep() T.wait(250)
		local cd1 = p.talents_cd[tid] or 0
		local used = cd1 > cd0
		fired[#fired+1] = used and "T" or (enemy.life < life0 and "b" or (game.turn == turn0 and "-" or "?"))
		if used then else if enemy.life < life0 then bumps = bumps + 1 end end
		turn0 = game.turn
		-- let the cooldown tick: one player turn per tap already passes
		T.log(("tap %d: talent cd %d -> %d, enemy life %d -> %d, turn %d"):format(tap, cd0, cd1, life0, enemy.life, game.turn))
	end
	T.log("sequence", table.concat(fired, " "))
	if fired[1] ~= "T" then T.log("BAD the talent did not fire on the first tap") end
	if bumps == 0 then T.log("BAD no bump while the talent cooled") end
	local again = false
	for i = 2, #fired do if fired[i] == "T" then again = true end end
	if not again then T.log(("note: the talent did not come off cooldown within 6 taps (cooldown %s)"):format(tostring(util.getval(t.cooldown, p, t)))) end
	if p.act_nothing then T.log("BAD the routine found nothing to do") end
	-- the group step must have been skipped: only one enemy in view
	T.log("enemies in view", #p:actEnemies(), "cond group", tostring(p:actCondOK({cond="group"})))
	if p:actCondOK({cond="group"}) then T.log("BAD group condition true with one enemy") end
	-- the no_enemies wait never ran while fighting: its wait would not touch the enemy but would spend a turn
	-- without a bump or talent; every tap above spent its turn on one of those
	for i, f in ipairs(fired) do if f == "-" then T.log("BAD tap " .. i .. " spent no turn") end end
	-- cycle mode still walks the list
	r.mode = "cycle" r.pos = 1
	p.talents_cd[tid] = nil
	local order = {}
	for tap = 1, 3 do local cd0 = p.talents_cd[tid] or 0 local l0 = enemy.life p:actStep() T.wait(250) order[#order+1] = ((p.talents_cd[tid] or 0) > cd0) and "T" or (enemy.life < l0 and "b" or "-") end
	T.log("cycle sequence", table.concat(order, " "))
	if order[1] ~= "T" or order[2] ~= "b" then T.log("BAD cycle mode order", table.concat(order, " ")) end
	T.log("finished")
end
