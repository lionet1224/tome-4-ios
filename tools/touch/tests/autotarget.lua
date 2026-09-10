-- The strip's who box shows the nearest enemy when no target was set by hand (a skill goes at it on its own).
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(800)
	local p, tm = game.player, game.uiset.touch_manual
	p.invulnerable = 1
	tm:setTarget(nil)
	T.wait(400)
	T.log("no enemies: who", tostring(tm.strip_who and tm.strip_who.name), "rect", tostring(tm.strip_who_rect ~= nil))
	if tm.strip_who then T.log("BAD who shown with no enemy in view") end
	-- spawn two enemies: the near one must be the automatic pick
	local NPC = require("mod.class.NPC")
	local map = game.level.map
	local function spawn(dx, dy, name)
		local x, y = p.x + dx, p.y + dy
		if map:checkEntity(x, y, engine.Map.TERRAIN, "block_move") or map(x, y, engine.Map.ACTOR) then return end
		local e = game.zone:makeEntity(game.level, "actor", {name="giant white mouse"}, nil, true)
		if not e then return end
		e.name = name e.faction = "enemies" e.ai = "none"
		game.zone:addEntity(game.level, e, "actor", x, y)
		return e
	end
	local far = spawn(4, 0, "far mouse")
	local near = spawn(2, 0, "near mouse")
	p:playerFOV() T.wait(600)
	T.log("who", tostring(tm.strip_who and tm.strip_who.name), "expected", tostring(near and near.name))
	if not (near and tm.strip_who == near) then T.log("BAD the who box does not show the nearest enemy") end
	if tm.strip_clear_rect then T.log("BAD a clear x is drawn for an automatic pick") end
	-- a strip tap with no hand-picked target aims by hand (Act alone picks on its own)
	local card
	for _, c in pairs(tm.strip_rects or {}) do
		local t = c.tid and p:getTalentFromId(c.tid)
		if t and t.mode ~= "sustained" and t.target and not card then card = c end
	end
	if card then
		T.tap(card.x + card.w / 2, card.y + card.h / 2) T.wait(600)
		T.log("strip tap", tostring(card.tid), "key", game.key == game.normal_key and "normal" or "targeting")
		if game.key == game.normal_key then T.log("BAD a strip tap with no hand-picked target cast on its own") end
		if game.key ~= game.normal_key then T.key("EXIT") T.wait(400) end
	else T.log("no targeted card on the strip to tap") end
	-- a hand-picked target wins over the nearest one
	if far then tm:setTarget(far) T.wait(400)
		T.log("manual who", tostring(tm.strip_who and tm.strip_who.name))
		if tm.strip_who ~= far then T.log("BAD the manual target does not replace the automatic pick") end
		tm:setTarget(nil)
	end
	-- the near one dies: the box moves to the next enemy
	if near then near:die(p) T.wait(600)
		T.log("after death who", tostring(tm.strip_who and tm.strip_who.name))
		if tm.strip_who ~= far then T.log("BAD the who box did not move on after the nearest enemy died") end
	end
	T.shot("autotarget")
	T.log("finished")
end
