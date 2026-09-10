-- Movement: tap to walk, drag to step with the preview, the Pan pill. Portrait.
return function(T)
	local L = dofile("/touch-demo-lib.lua")
	L.prelude(T)
	local p, map = game.player, game.level.map
	L.clearHostiles() p:playerFOV() map:centerViewAround(p.x, p.y) T.wait(1500)
	-- tap a tile a few steps away: the character walks there
	local tx, ty
	for d = 5, 3, -1 do for _, dir in ipairs{{d, 0}, {-d, 0}, {0, d}, {0, -d}, {d, d}, {-d, -d}} do
		if not tx and L.free(p.x + dir[1], p.y + dir[2]) and p:hasLOS(p.x + dir[1], p.y + dir[2]) then tx, ty = p.x + dir[1], p.y + dir[2] end
	end end
	if tx then local sx, sy = L.tile(tx, ty) T.tap(sx, sy) T.wait(4500) end
	-- drag to step: the destination lights up under the finger, release to step
	map:centerViewAround(p.x, p.y) T.wait(800)
	local sx, sy = L.tile(p.x, p.y)
	local tw = map.tile_w * (map.zoom or 1)
	local dx = L.free(p.x + 1, p.y) and 1 or -1
	T.swipe(sx, sy, sx + dx * tw, sy, 1400, 300) T.wait(1500)
	T.swipe(sx + dx * tw, sy, sx + 2 * dx * tw, sy, 1400, 300) T.wait(1500)
	-- Pan: tap the pill, drag the map around, tap again
	local c = game.uiset.touch_ctx_rects or {}
	if c.pan then
		T.tap(c.pan.x + c.pan.w / 2, c.pan.y + c.pan.h / 2) T.wait(900)
		local cx, cy = game.w / 2, (game.uiset.touch_band_y or game.h) / 2
		T.swipe(cx, cy, cx - tw * 4, cy - tw * 2, 1200) T.wait(900)
		T.swipe(cx - tw * 4, cy - tw * 2, cx, cy, 1200) T.wait(900)
		c = game.uiset.touch_ctx_rects or {}
		if c.pan then T.tap(c.pan.x + c.pan.w / 2, c.pan.y + c.pan.h / 2) end
		T.wait(1200)
	end
	T.log("finished")
end
