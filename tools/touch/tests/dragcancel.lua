-- A drag-to-step that comes back to its start point is a cancel, not a tap-to-move.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(800)
	local TI = require("engine.TouchInput")
	local p, map = game.player, game.level.map
	p.invulnerable = 1
	local function center(x, y) local sx, sy = map:getTileToScreen(x, y) local tw, th = map.tile_w * (map.zoom or 1), map.tile_h * (map.zoom or 1) return sx + tw / 2, sy + th / 2 end
	map:centerViewAround(p.x, p.y) T.wait(400)
	-- start the drag in the middle of the map view (a step drag can start anywhere off the HUD)
	local sx, sy = map.display_x + map.viewport.width / 2, map.display_y + map.viewport.height * 0.4
	local ox, oy = p.x, p.y
	-- out past the deadzone, then back to the start, then release
	-- out within one frame, back within the next: quick enough that the hold-still walk (600 ms) never starts
	-- (a simulator frame is ~130 ms, so every T.wait here costs a whole frame)
	TI.fingerDown(1, sx, sy) T.wait(30)
	for i = 1, 5 do TI.fingerMove(1, sx + 16 * i, sy) end
	T.wait(300)
	for i = 4, 0, -1 do TI.fingerMove(1, sx + 16 * i, sy) end
	TI.fingerUp(1, sx, sy) T.wait(900)
	T.log("after cancelled drag", ox, oy, "->", p.x, p.y, "running", tostring(p.running ~= nil and p.running ~= false))
	if p.x ~= ox or p.y ~= oy then T.log("BAD a cancelled drag moved the player") end
	-- a real drag still steps once
	local dirx = 1
	local function free(dx) return map:isBound(p.x + dx, p.y) and not map:checkEntity(p.x + dx, p.y, engine.Map.TERRAIN, "block_move") and not map(p.x + dx, p.y, engine.Map.ACTOR) end
	if not free(1) and free(-1) then dirx = -1 end
	if free(dirx) then
		ox, oy = p.x, p.y
		TI.fingerDown(1, sx, sy) T.wait(30)
		for i = 1, 5 do TI.fingerMove(1, sx + 16 * i * dirx, sy) end
		T.wait(300)
		TI.fingerUp(1, sx + 80 * dirx, sy) T.wait(900)
		T.log("after drag", dirx > 0 and "right" or "left", ox, oy, "->", p.x, p.y)
		if p.x ~= ox + dirx then T.log("BAD a drag did not step once") end
	else T.log("both sides blocked; step check skipped") end
	-- holding still in a direction never walks: nothing until the release, then one step
	dirx = free(1) and 1 or (free(-1) and -1) or nil
	if not dirx then T.log("both sides blocked; hold check skipped") end
	if dirx then
		ox, oy = p.x, p.y
		TI.fingerDown(1, sx, sy) T.wait(30)
		for i = 1, 5 do TI.fingerMove(1, sx + 16 * i * dirx, sy) end
		T.wait(1800)
		T.log("held 1.8 s", ox, oy, "->", p.x, p.y)
		if p.x ~= ox or p.y ~= oy then T.log("BAD holding still moved the player") end
		TI.fingerUp(1, sx + 80 * dirx, sy) T.wait(900)
		T.log("after release", ox, oy, "->", p.x, p.y)
		if p.x ~= ox + dirx then T.log("BAD the release did not step once") end
	end
	if p.running then p:runStop() end
	T.log("finished")
end
