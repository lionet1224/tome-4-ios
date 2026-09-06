-- Disengage with a selected enemy: the enemy is the first aim, the escape square is aimed normally
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local p, map = game.player, game.level.map
	local function free(x, y) return map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR) end
	-- stand somewhere with room behind us
	local placed = false
	for r = 0, 12 do for x = math.floor(map.w / 2) - r, math.floor(map.w / 2) + r do for y = math.floor(map.h / 2) - r, math.floor(map.h / 2) + r do
		if not placed and free(x, y) and free(x - 1, y) and free(x - 2, y) and free(x - 3, y) and free(x + 1, y) then p:move(x, y, true) placed = true end
	end end if placed then break end end
	map:centerViewAround(p.x, p.y) T.wait(300)
	p:learnTalent(p.T_DISENGAGE, true, 1)
	local npc = game.zone:makeEntity(game.level, "actor", {type="vermin"}, nil, true)
	if not npc then T.log("no npc") T.log("finished") return end
	game.zone:addEntity(game.level, npc, "actor", p.x + 1, p.y) npc.faction = "enemies"
	p:playerFOV() T.wait(400)
	game.uiset.touch_manual:setTarget(npc) T.wait(200)
	local t = p:getTalentFromId(p.T_DISENGAGE)
	local x0 = p.x
	local ok, why = game.uiset.touch_manual:cast(p.T_DISENGAGE, npc)
	T.wait(600)
	local aiming = game.key ~= game.normal_key
	T.log("cast ok", tostring(ok), tostring(why), "aiming", tostring(aiming), "player x", x0, "->", p.x)
	if aiming then
		-- accept the default escape square (the talent pre-places it away from the enemy)
		T.key("ACCEPT") T.wait(800)
		T.log("after accept: aiming", tostring(game.key ~= game.normal_key), "player x", x0, "->", p.x)
		if p.x >= x0 then T.log("BAD did not disengage away from the enemy") end
	else
		T.log("BAD expected the escape-square aim to open")
	end
	if game.key ~= game.normal_key then T.key("EXIT") end
	T.log("finished")
end
