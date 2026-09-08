-- Step conditions: each one against a built situation, and the out-of-combat rule
-- (a "no enemies in view" step runs instead of exploring).
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
		if not placed and free(x, y) and free(x + 1, y) and free(x + 3, y) then p:move(x, y, true) placed = true end
	end end if placed then break end end
	local spawned = {}
	local function mk(dx, dy)
		local a = game.zone:makeEntity(game.level, "actor", {type="vermin"}, nil, true)
		if not a then return nil end
		game.zone:addEntity(game.level, a, "actor", p.x + dx, p.y + dy)
		a.faction = "enemies" a.ai = "none" a.never_move = 1 a.max_life = 1000 a.life = 1000 a.invisible = nil a.stealth = nil
		spawned[#spawned+1] = a
		return a
	end
	local function kill() for _, a in ipairs(spawned) do if not a.dead then map:remove(a.x, a.y, Map.ACTOR) game.level:removeEntity(a) a.dead = true end end spawned = {} p:playerFOV() end
	local function check(name, got, want) T.log(("cond %-12s -> %s (want %s)"):format(name, tostring(got), tostring(want))) if got ~= want then T.log("BAD cond " .. name) end end
	p.invulnerable = 1
	-- nobody in view
	p:playerFOV() T.wait(200)
	check("no_enemies", p:actCondOK({cond="no_enemies"}), true)
	check("adjacent", p:actCondOK({cond="adjacent"}), false)
	check("not_adjacent", p:actCondOK({cond="not_adjacent"}), true)
	check("group", p:actCondOK({cond="group"}), false)
	-- one enemy three tiles away
	local far = mk(3, 0) p:playerFOV() T.wait(200)
	check("no_enemies", p:actCondOK({cond="no_enemies"}), false)
	check("adjacent", p:actCondOK({cond="adjacent"}), false)
	check("not_adjacent", p:actCondOK({cond="not_adjacent"}), true)
	check("group", p:actCondOK({cond="group"}), false)
	-- a second one adjacent
	local near = mk(1, 0) p:playerFOV() T.wait(200)
	check("adjacent", p:actCondOK({cond="adjacent"}), true)
	check("not_adjacent", p:actCondOK({cond="not_adjacent"}), false)
	check("group", p:actCondOK({cond="group"}), true)
	-- life and target life
	p.life = math.floor(p.max_life * 0.3)
	check("life<50", p:actCondOK({cond="life", pct=50}), true)
	check("life<25", p:actCondOK({cond="life", pct=25}), false)
	p.life = p.max_life
	check("life<50 full", p:actCondOK({cond="life"}), false)
	near.life = 100 -- 10 %
	check("target<25", p:actCondOK({cond="target_life", pct=25, target="nearest"}), true)
	near.life = 1000
	check("target<25 full", p:actCondOK({cond="target_life", pct=25, target="nearest"}), false)
	-- resource: stamina at 10 %
	if p.max_stamina and p.max_stamina > 0 then
		local s0 = p.stamina
		p.stamina = p.max_stamina * 0.1
		check("resource<30", p:actCondOK({cond="resource", pct=30}), true)
		p.stamina = p.max_stamina
		check("resource<30 full", p:actCondOK({cond="resource", pct=30}), false)
		p.stamina = s0
	end
	-- pets
	check("pets_low none", p:actCondOK({cond="pets_low"}), true)
	near.summoner = p
	check("pets_low one", p:actCondOK({cond="pets_low"}), false)
	near.summoner = nil
	-- a step with a failing condition is skipped by actStep (the bump behind it runs)
	local r = p:actRoutine()
	r.mode = "priority"
	r.steps = {{kind="wait", cond="life", pct=25}, {kind="bump", target="nearest", if_unusable="approach"}}
	local l0 = near.life
	p:actStep() T.wait(300)
	T.log("failing-cond wait skipped, bump landed", tostring(near.life < l0))
	if not (near.life < l0) then T.log("BAD the step behind a failing condition did not run") end
	-- out of combat: a no_enemies step fires instead of exploring
	kill() T.wait(200)
	local sustain
	for id, lv in pairs(p.talents) do local t = p:getTalentFromId(id) if t and t.mode == "sustained" and not p:isTalentActive(id) and p:preUseTalent(t, true, true) then sustain = id break end end
	if sustain then
		r.steps = {{kind="talent", tid=sustain, cond="no_enemies"}, {kind="bump", target="nearest", if_unusable="approach"}}
		p:actStep() T.wait(400)
		local active = p:isTalentActive(sustain)
		T.log("no enemies: sustain", p:getTalentFromId(sustain).name, "active", tostring(active), "running", tostring(p.running))
		if not active then T.log("BAD the out-of-combat sustain step did not fire") end
		if p.running then T.log("BAD explored instead of running the out-of-combat step") p:runStop() end
		-- next tap: the sustain is on (falls through), so exploring starts
		p:actStep() T.wait(400)
		T.log("second tap: running", tostring(p.running ~= nil))
		if p.running then p:runStop() end
	else
		T.log("note: no inactive sustain known; out-of-combat rule checked with a wait step")
		r.steps = {{kind="wait", cond="no_enemies"}}
		local turn0 = game.turn
		p:actStep() T.wait(300)
		if game.turn == turn0 then T.log("BAD the out-of-combat wait did not spend a turn") end
		if p.running then T.log("BAD explored instead of waiting") p:runStop() end
	end
	T.log("finished")
end
