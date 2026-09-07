-- tap-to-walk lands on the tapped tile (both orientations, at 1x and zoomed)
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local TI = require "engine.TouchInput"
	local p, map = game.player, game.level.map
	-- no hostiles: floor taps must not be blocked
	for _, e in pairs(game.level.entities) do
		if e.__is_actor and e ~= p and e.x and p:reactionToward(e) < 0 then map:remove(e.x, e.y, Map.ACTOR) game.level:removeEntity(e) end
	end
	-- stand near the middle so the view is not clamped
	local function free(x, y) return map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR) end
	for r = 0, 12 do local done = false
		for x = math.floor(map.w / 2) - r, math.floor(map.w / 2) + r do for y = math.floor(map.h / 2) - r, math.floor(map.h / 2) + r do
			if not done and free(x, y) then p:move(x, y, true) done = true end
		end end
		if done then break end
	end
	p:playerFOV()
	for x = 0, map.w - 1 do for y = 0, map.h - 1 do map.remembers(x, y, true) map.has_seens(x, y, true) end end
	local function trial(tag)
		map:centerViewAround(p.x, p.y) T.wait(500)
		local target
		for _, d in ipairs{{3, 2}, {-3, 2}, {3, -2}, {-3, -2}, {4, 0}, {0, 4}, {-4, 0}, {0, -4}} do
			local x, y = p.x + d[1], p.y + d[2]
			if free(x, y) then target = {x=x, y=y} break end
		end
		if not target then T.log(tag, "no free target") return end
		local sx, sy = map:getTileToScreen(target.x, target.y, true)
		local bx, by = map:getMouseTile(sx, sy)
		T.log(("%s: portrait=%s zoom=%s view %d,%d tile %d,%d -> screen %d,%d -> back %d,%d"):format(tag, tostring(TI.portrait()), tostring(map.zoom), map.mx, map.my, target.x, target.y, sx, sy, bx, by))
		if bx ~= target.x or by ~= target.y then T.log("BAD "..tag..": screen->tile round trip is off") end
		local ox, oy = p.x, p.y
		local stops = {}
		if not p.__stop_hooked then local orig = p.runStop p.runStop = function(self, msg, ...) stops[#stops+1] = tostring(msg) return orig(self, msg, ...) end p.__stop_hooked = true end
		p.__stops = stops
		T.tap(sx, sy)
		T.waitFor(function() return not p.running and (p.x ~= ox or p.y ~= oy) end, 15000)
		T.waitFor(function() return not p.running end, 15000)
		T.log(("%s: walked %d,%d -> %d,%d (tapped %d,%d) stops: %s"):format(tag, ox, oy, p.x, p.y, target.x, target.y, table.concat(p.__stops or {}, " | ")))
		if p.x ~= target.x or p.y ~= target.y then T.log("BAD "..tag..": did not arrive at the tapped tile") end
	end
	trial("1x")
	-- zoom in (the pinch path) and try again
	if TI.on_pinch then pcall(TI.on_pinch, 0.6) T.wait(800) end
	trial("zoomed")
	T.log("finished")
end
