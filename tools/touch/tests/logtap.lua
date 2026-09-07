-- portrait: a tap on a map tile that lies under the floating message log walks to THAT tile
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local p, map = game.player, game.level.map
	for _, e in pairs(game.level.entities) do
		if e.__is_actor and e ~= p and e.x and p:reactionToward(e) < 0 then map:remove(e.x, e.y, Map.ACTOR) game.level:removeEntity(e) end
	end
	for x = 0, map.w - 1 do for y = 0, map.h - 1 do map.remembers(x, y, true) end end
	local function free(x, y) return map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR) end
	-- stand where 8 rows below is free, near the middle
	local placed
	for r = 0, 14 do for x = math.floor(map.w / 2) - r, math.floor(map.w / 2) + r do for y = math.floor(map.h / 2) - r, math.floor(map.h / 2) + r do
		if not placed and free(x, y) and free(x, y + 8) then p:move(x, y, true) placed = true end
	end end if placed then break end end
	p:playerFOV() map:centerViewAround(p.x, p.y) T.wait(500)
	local lg = game.uiset.places.gamelog
	local tx, ty = p.x, p.y + 8
	local sx, sy = map:getTileToScreen(tx, ty, true)
	local bx, by = map:getMouseTile(sx, sy)
	T.log(("log place y=%s..%s; tile %d,%d at screen %d,%d -> back %d,%d view %d,%d"):format(tostring(lg and lg.y), tostring(lg and lg.y + (lg.h or 0)), tx, ty, sx, sy, bx, by, map.mx, map.my))
	local ox, oy = p.x, p.y
	T.tap(sx, sy)
	T.waitFor(function() return not p.running and (p.x ~= ox or p.y ~= oy) end, 15000)
	T.waitFor(function() return not p.running end, 15000)
	T.log(("walked %d,%d -> %d,%d (tapped %d,%d)"):format(ox, oy, p.x, p.y, tx, ty))
	if p.x ~= tx or p.y ~= ty then T.log("BAD tap under the log did not walk to the tapped tile") end
	T.log("finished")
end
