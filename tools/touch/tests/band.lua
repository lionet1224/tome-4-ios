-- portrait band: at the bottom edge of the level the player stays above the HUD band
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local p, map = game.player, game.level.map
	local m = game.uiset.touch_manual
	local r = m:layout()
	T.log(("portrait=%s band_y=%s viewport %dx%d map_h_stop=%s"):format(tostring(r.portrait), tostring(r.band_y), Map.viewport.width, Map.viewport.height, tostring(game.uiset.map_h_stop)))
	-- the bottom-most free tile
	local found
	for y = map.h - 1, 0, -1 do
		for x = 0, map.w - 1 do
			if not found and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR) then found = {x=x, y=y} end
		end
		if found then break end
	end
	if not found then T.log("no free tile") T.log("finished") return end
	p:move(found.x, found.y, true)
	map:centerViewAround(p.x, p.y) T.wait(800)
	local sx, sy = map:getTileToScreen(p.x, p.y, true)
	T.log(("player %d,%d of %dx%d screen %s,%s"):format(p.x, p.y, map.w, map.h, tostring(sx), tostring(sy)))
	if r.portrait and r.band_y and sy and sy >= r.band_y then T.log("BAD player hidden under the band", sy, r.band_y) end
	if r.portrait and r.band_y and Map.viewport.height > r.band_y then T.log("BAD viewport under the band") end
	T.shot("band-bottom")
	T.log("finished")
end
