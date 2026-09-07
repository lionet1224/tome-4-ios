-- tapping the stairs from afar walks there and takes them
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local p, map = game.player, game.level.map
	local Astar = require "engine.Astar"
	-- the nearest reachable down stairs; reveal the level so the tap is a normal path
	for x = 0, map.w - 1 do for y = 0, map.h - 1 do map.remembers(x, y, true) map.has_seens(x, y, true) end end
	local best, bd
	for x = 0, map.w - 1 do for y = 0, map.h - 1 do
		local g = map(x, y, Map.TERRAIN)
		if g and g.change_level and g.change_level > 0 and not (x == p.x and y == p.y) then
			local d = core.fov.distance(p.x, p.y, x, y)
			if (not bd or d < bd) and Astar.new(map, p):calc(p.x, p.y, x, y, false) then best, bd = {x=x, y=y}, d end
		end
	end end
	if not best then T.log("no stairs down reachable") T.log("finished") return end
	-- stand a few tiles from the stairs so the walk is short
	local function free(x, y) return map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR) and not map:checkEntity(x, y, Map.TERRAIN, "change_level") end
	local spot
	for r = 3, 6 do for dx = -r, r do for dy = -r, r do
		local x, y = best.x + dx, best.y + dy
		if not spot and free(x, y) and Astar.new(map, p):calc(x, y, best.x, best.y, false) then spot = {x=x, y=y} end
	end end if spot then break end end
	if spot then p:move(spot.x, spot.y, true) end
	-- no hostiles: the tap must not be blocked and the walk must not stop
	local removed = 0
	for _, e in pairs(game.level.entities) do
		if e.__is_actor and e ~= p and e.x and p:reactionToward(e) < 0 then map:remove(e.x, e.y, Map.ACTOR) game.level:removeEntity(e) removed = removed + 1 end
	end
	p:playerFOV() T.wait(400)
	T.log("hostiles removed", removed, "enemies in view", #p:actEnemies())
	local lvl0, zone0 = game.level.level, game.zone.short_name
	map:centerViewAround(p.x, p.y) T.wait(300)
	local sx, sy = map:getTileToScreen(best.x, best.y, true)
	T.log("stairs at", best.x, best.y, "dist", bd, "screen", sx, sy)
	if sx < 0 or sy < 0 or sx > game.w or sy > game.h then
		-- off screen: scroll the view there first
		map:centerViewAround(best.x, best.y) T.wait(300) sx, sy = map:getTileToScreen(best.x, best.y, true)
	end
	local stops = {}
	local orig = p.runStop
	p.runStop = function(self, msg, ...) stops[#stops+1] = tostring(msg) return orig(self, msg, ...) end
	T.tap(sx, sy)
	T.waitFor(function() return game.level.level ~= lvl0 or game.zone.short_name ~= zone0 end, 40000)
	T.log("level", zone0, lvl0, "->", game.zone.short_name, game.level.level, "player", p.x, p.y, "touch_enter", tostring(p.touch_enter))
	T.log("run stops:", table.concat(stops, " | "))
	if game.level.level == lvl0 and game.zone.short_name == zone0 then T.log("BAD did not take the tapped stairs") end
	T.log("finished")
end
