-- a bump step with the target 3 tiles away closes in instead of skipping
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local p, map = game.player, game.level.map
	for _, e in pairs(game.level.entities) do
		if e.__is_actor and e ~= p and e.x and p:reactionToward(e) < 0 then map:remove(e.x, e.y, Map.ACTOR) game.level:removeEntity(e) end
	end
	local function free(x, y) return map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR) end
	local npc
	for _, d in ipairs{{3, 0}, {-3, 0}, {0, 3}, {0, -3}} do
		if free(p.x + d[1], p.y + d[2]) and free(p.x + d[1] / 3, p.y + d[2] / 3) and free(p.x + 2 * d[1] / 3, p.y + 2 * d[2] / 3) then
			npc = game.zone:makeEntity(game.level, "actor", {type="vermin"}, nil, true)
			if npc then game.zone:addEntity(game.level, npc, "actor", p.x + d[1], p.y + d[2]) npc.faction = "enemies" npc.ai = "none" npc.never_move = 1 npc.invulnerable = 1 break end
		end
	end
	if not npc then T.log("no npc") T.log("finished") return end
	p:playerFOV() T.wait(400)
	local r = p:actRoutine()
	T.log("routine", r.name, "steps", #r.steps, "bump if_unusable", tostring(r.steps[1] and r.steps[1].if_unusable))
	local d0 = core.fov.distance(p.x, p.y, npc.x, npc.y)
	p:actStep() T.wait(600)
	local d1 = core.fov.distance(p.x, p.y, npc.x, npc.y)
	T.log("Act: distance", d0, "->", d1, "last ok", tostring(p.act_last_ok))
	if d1 >= d0 then T.log("BAD bump step did not close in") end
	p:actStep() T.wait(600)
	local d2 = core.fov.distance(p.x, p.y, npc.x, npc.y)
	T.log("Act again: distance", d1, "->", d2)
	if d2 >= d1 and d1 > 1 then T.log("BAD second Act did not close in") end
	T.log("finished")
end
