-- The Act button shows what a tap does right now: a melee step out of reach is skipped for the
-- gap closer further down the list, and the preview says so before the tap.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(800)
	local p, map = game.player, game.level.map
	p.invulnerable = 1
	local NPC = require("mod.class.NPC")
	local function spawn(dx, dy, name)
		local x, y = p.x + dx, p.y + dy
		if not map:isBound(x, y) or map:checkEntity(x, y, engine.Map.TERRAIN, "block_move") or map(x, y, engine.Map.ACTOR) then return end
		local e = game.zone:makeEntity(game.level, "actor", {name="giant white mouse"}, nil, true)
		if not e then return end
		e.name = name e.faction = "enemies" e.ai = "none" e.max_life = 500 e.life = 500
		game.zone:addEntity(game.level, e, "actor", x, y)
		return e
	end
	-- nobody around: the soak start can have rabbits in view
	for _, a in pairs(game.level.entities) do if a.__is_actor and a ~= p and p:reactionToward(a) < 0 and p:canSee(a) then a:die(p) end end
	p:playerFOV() T.wait(400)
	local function preview() p.act_preview_key = nil local pv = p:actPreview() return pv, pv and pv.step and (pv.step.tid or pv.step.kind) or "nil", pv and tostring(pv.what) or "nil" end
	-- nobody in view: explore
	local pv, st, what = preview()
	T.log("alone:", st, what)
	if what ~= "explore" then T.log("BAD with nobody in view the preview is not explore") end
	if not p:knowTalent("T_RUSH") then p:learnTalent("T_RUSH", true) end
	-- a straight, open line of four tiles in some direction, then a mouse at its end
	local DX, DY
	for _, d in ipairs{{1, 0}, {-1, 0}, {0, 1}, {0, -1}, {1, 1}, {-1, -1}, {1, -1}, {-1, 1}} do
		local open = true
		for i = 1, 4 do
			local x, y = p.x + d[1] * i, p.y + d[2] * i
			if not map:isBound(x, y) or map:checkEntity(x, y, engine.Map.TERRAIN, "block_move") or map:checkEntity(x, y, engine.Map.TERRAIN, "block_sight") or map(x, y, engine.Map.ACTOR) then open = false break end
		end
		if open then DX, DY = d[1], d[2] break end
	end
	if not DX then T.log("no open line of four tiles anywhere") T.log("finished") return end
	local far = spawn(4 * DX, 4 * DY, "far mouse")
	if not far then T.log("no room for the far mouse") T.log("finished") return end
	p:playerFOV() T.wait(500)
	local r = p:actRoutine()
	-- a melee opener first, the gap closer later, a bump last: the shape that hid Rush behind Stunning Blow
	local saved = r.steps
	r.steps = {
		{kind="talent", tid="T_STUNNING_BLOW_ASSAULT", target="nearest", if_unusable="skip"},
		{kind="talent", tid="T_RUSH", target="nearest", if_unusable="skip", cond="not_adjacent"},
		{kind="bump", target="nearest", if_unusable="approach"},
	}
	T.log("routine", r.name, "steps", #r.steps, "enemies", #p:actEnemies(), "rush known", tostring(p:knowTalent("T_RUSH")))
	pv, st, what = preview()
	T.log("four tiles off:", st, what, "target", tostring(pv and pv.target and pv.target.name))
	if st ~= "T_RUSH" then T.log("BAD expected Rush (the gap closer) in the preview, got "..st) end
	-- the tap does what the preview said
	local ox, oy = p.x, p.y
	p:actStep() T.wait(700)
	T.log("after tap: rush cooling", tostring(p:isTalentCoolingDown(p:getTalentFromId("T_RUSH"))), "dist", core.fov.distance(p.x, p.y, far.x, far.y))
	if not p:isTalentCoolingDown(p:getTalentFromId("T_RUSH")) then T.log("BAD the tap did not cast Rush") end
	-- adjacent now: a melee step leads
	p:playerFOV() T.wait(300)
	pv, st, what = preview()
	T.log("adjacent:", st, what)
	if st == "T_RUSH" then T.log("BAD Rush shown while adjacent") end
	-- a routine of only a bump with approach: out of reach, the preview says Close in
	far:die(p) T.wait(300)
	p:move(ox, oy, true) p:playerFOV() T.wait(300)
	local far2 = spawn(4 * DX, 4 * DY, "far mouse 2") or spawn(3 * DX, 3 * DY, "far mouse 2")
	if far2 then
		p:playerFOV() T.wait(300)
		r.steps = {{kind="bump", target="nearest", if_unusable="approach"}}
		pv, st, what = preview()
		T.log("bump only, out of reach:", st, what)
		if what ~= "step_in" then T.log("BAD expected step_in for a bump out of reach") end
		r.steps = {{kind="talent", tid="T_STUNNING_BLOW_ASSAULT", target="nearest", if_unusable="skip"}}
		pv, st, what = preview()
		T.log("melee only, out of reach:", st, what)
		if pv and pv.step then T.log("BAD expected nothing applicable") end
	end
	r.steps = saved
	T.shot("actpreview")
	T.log("finished")
end
