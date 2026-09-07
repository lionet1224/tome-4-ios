-- The Pan pill: visible whenever AUTO is off, toggles a mode where one-finger drags
-- scroll the camera; tapping it again or stepping ends the mode.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p, map = game.player, game.level.map
	local m = game.uiset.touch_manual
	local function ctx() return game.uiset.touch_ctx_rects or {} end
	T.wait(300)
	local pan = ctx().pan
	T.log("pan pill", pan and ("%d,%d %dx%d"):format(pan.x, pan.y, pan.w, pan.h) or "nil", "auto", tostring(p.auto_act))
	if not pan then T.log("BAD no Pan pill with AUTO off") T.log("finished") return end
	local r = m.rects
	local function overlap(a, b) return a and b and a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h end
	for _, k in ipairs{"act", "auto", "more", "levelup", "ctx_lo", "ctx_hi"} do if overlap(pan, r[k]) then T.log("BAD Pan pill overlaps "..k) end end
	if pan.x < 0 or pan.x + pan.w > game.w or pan.y + pan.h > game.h then T.log("BAD Pan pill off screen") end
	-- AUTO hides it
	p.invulnerable = 1
	p:autoActStart(true) T.wait(500)
	T.log("during AUTO: pill", tostring(ctx().pan ~= nil), "auto", tostring(p.auto_act))
	if p.auto_act and ctx().pan then T.log("BAD Pan pill shown during AUTO") end
	p:autoActStop("test") T.wait(1200)
	T.log("after AUTO: key normal", tostring(game.key == game.normal_key), "dialogs", #game.dialogs, "shown", tostring(m.ctx_pan_shown ~= nil and m.ctx_pan_shown ~= false), "running", tostring(p.running), "resting", tostring(p.resting), "rect", tostring(m.rects.ctx_pan ~= nil))
	if not ctx().pan then T.log("BAD Pan pill did not come back after AUTO") end
	-- tap: pan mode on
	T.tap(pan.x + pan.w / 2, pan.y + pan.h / 2) T.wait(400)
	T.log("after tap: pan_mode", tostring(m.pan_mode), "label", tostring(ctx().pan_mode))
	if not m.pan_mode then T.log("BAD tap did not enter pan mode") T.log("finished") return end
	-- a drag on the map scrolls the camera and does not move the player
	local mx0, my0, px0, py0 = map.mx, map.my, p.x, p.y
	local cx, cy = game.w / 2, (m.rects.band_y or game.h) / 2
	T.swipe(cx, cy, cx - map.tile_w * 3, cy - map.tile_h * 2, 400) T.wait(600)
	T.log(("drag: view %d,%d -> %d,%d  player %d,%d -> %d,%d"):format(mx0, my0, map.mx, map.my, px0, py0, p.x, p.y))
	if map.mx == mx0 and map.my == my0 then T.log("BAD the drag did not pan the view") end
	if p.x ~= px0 or p.y ~= py0 then T.log("BAD the drag moved the player") end
	if not m.pan_mode then T.log("BAD pan mode ended on a drag") end
	T.shot("panpill-panned")
	-- tap again: off
	pan = ctx().pan
	T.tap(pan.x + pan.w / 2, pan.y + pan.h / 2) T.wait(400)
	T.log("after second tap: pan_mode", tostring(m.pan_mode))
	if m.pan_mode then T.log("BAD second tap did not leave pan mode") end
	-- on, then a step ends it
	T.tap(pan.x + pan.w / 2, pan.y + pan.h / 2) T.wait(400)
	local moved = false
	for _, d in ipairs{{1, 0}, {-1, 0}, {0, 1}, {0, -1}} do
		local x, y = p.x + d[1], p.y + d[2]
		if map:isBound(x, y) and not map:checkEntity(x, y, require("engine.Map").TERRAIN, "block_move") then p:move(x, y, true) moved = true break end
	end
	T.wait(500)
	T.log("after a step: moved", tostring(moved), "pan_mode", tostring(m.pan_mode))
	if moved and m.pan_mode then T.log("BAD pan mode survived a step") end
	T.log("finished")
end
