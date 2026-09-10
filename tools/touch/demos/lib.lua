-- shared bits for the demo scripts (portrait); the capture harness films from "script started" to "finished"
local L = {}
function L.prelude(T) T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(800) T.log("demo start") end
function L.clearHostiles()
	local Map = require "engine.Map"
	local p, map = game.player, game.level.map
	for _, e in pairs(game.level.entities) do
		if e.__is_actor and e ~= p and e.x and p:reactionToward(e) < 0 then map:remove(e.x, e.y, Map.ACTOR) game.level:removeEntity(e) end
	end
end
function L.free(x, y)
	local Map = require "engine.Map"
	local map = game.level.map
	return map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR)
end
function L.tile(x, y)
	local map = game.level.map
	local sx, sy = map:getTileToScreen(x, y, true)
	return sx, sy
end
function L.spawn(dx, dy, opts)
	local p = game.player
	local a = game.zone:makeEntity(game.level, "actor", {type="vermin"}, nil, true)
	if not a then return nil end
	game.zone:addEntity(game.level, a, "actor", p.x + dx, p.y + dy)
	a.faction = "enemies" a.invisible = nil a.stealth = nil
	for k, v in pairs(opts or {}) do a[k] = v end
	return a
end
return L
