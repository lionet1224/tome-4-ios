-- a tap whose thumb rolls a few mm must stay a tap (tap-to-path), not a random step
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local TI = require "engine.TouchInput"
	local p, map = game.player, game.level.map
	T.log("state: normal key", tostring(game.key == game.normal_key), "dialogs", #game.dialogs, "provider", tostring(TI.on_map_drag ~= nil), "drag_step", tostring(TI.setting("drag_step")), "creating", tostring(game.creating_player))
	local function tileCenter(x, y) local sx, sy = map:getTileToScreen(x, y, true) return sx, sy end
	-- stand near the middle of the level so the view centres and no HUD covers the tiles
	for r = 0, 12 do
		local done = false
		for x = math.floor(map.w / 2) - r, math.floor(map.w / 2) + r do for y = math.floor(map.h / 2) - r, math.floor(map.h / 2) + r do
			if not done and map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR) then p:move(x, y, true) done = true end
		end end
		if done then break end
	end
	map:centerViewAround(p.x, p.y) T.wait(600)
	T.log("standing at", p.x, p.y, "screen", tileCenter(p.x, p.y))
	-- a direction whose next two tiles are free: the tap target is two tiles out, the flick goes the other way (also free)
	local function free(x, y) return map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR) end
	local target
	for _, d in ipairs{{2, 0}, {-2, 0}, {0, 2}, {0, -2}} do
		local ux, uy = d[1] / 2, d[2] / 2
		if free(p.x + ux, p.y + uy) and free(p.x + d[1], p.y + d[2]) and free(p.x - ux, p.y - uy) then target = {x=p.x + d[1], y=p.y + d[2], d=d} break end
	end
	T.log("enemies in view", #p:actEnemies())
	if not target then T.log("no free tile") T.log("finished") return end
	local tx, ty = tileCenter(target.x, target.y)
	local x0, y0 = p.x, p.y
	-- 1. wobbly tap: 30 px roll in 60 ms, in the direction AWAY from the target
	local ux, uy = target.d[1] / 2, target.d[2] / 2
	T.flick(tx, ty, tx - 30 * ux - 8, ty - 30 * uy - 8)
	T.wait(2500)
	local toward = (math.abs(p.x - target.x) + math.abs(p.y - target.y)) < (math.abs(x0 - target.x) + math.abs(y0 - target.y))
	T.log(("wobble tap: player %d,%d -> %d,%d target %d,%d moved_toward=%s"):format(x0, y0, p.x, p.y, target.x, target.y, tostring(toward)))
	if not toward and (p.x ~= x0 or p.y ~= y0) then T.log("BAD wobble tap stepped somewhere else") end
	-- 2. deliberate flick: 90 px in 300 ms from the player's tile, must step one tile that way
	x0, y0 = p.x, p.y
	local px, py = tileCenter(p.x, p.y)
	local fd = {-target.d[1] / 2, -target.d[2] / 2}
	T.swipe(px, py, px + 90 * fd[1], py + 90 * fd[2], 300)
	T.wait(1500)
	T.log(("flick: player %d,%d -> %d,%d expected step %d,%d"):format(x0, y0, p.x, p.y, fd[1], fd[2]))
	if (p.x - x0) ~= fd[1] or (p.y - y0) ~= fd[2] then T.log("BAD flick did not step") end
	T.log("finished")
end
