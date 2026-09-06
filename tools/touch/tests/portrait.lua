return function(T)
	-- Portrait / hand layout probe: logs the screen size, the orientation and
	-- thumb side, the touch HUD rectangles and takes a screenshot. Run it once
	-- with the simulator in landscape and once rotated (Device > Rotate Left in
	-- the Simulator app, or touch.orientation = "portrait" in touch.cfg).
	local TI = require "engine.TouchInput"
	T.wait(60)
	local w, h = game.w, game.h
	T.log(("size %dx%d portrait=%s hand=%s"):format(w, h, tostring(TI.portrait()), TI.hand()))
	local sa = TI.safeArea()
	T.log(("safe l=%d t=%d r=%d b=%d"):format(sa.l, sa.t, sa.r, sa.b))
	local m = game.uiset and game.uiset.touch_manual
	if m then
		local r = m:layout()
		for _, k in ipairs{"act", "auto", "skills", "more", "levelup", "strip"} do
			local q = r[k]
			if q then T.log(("%s x=%d y=%d w=%d h=%d"):format(k, q.x, q.y, q.w, q.h)) end
		end
		-- sanity: everything on screen, dock under the chosen thumb
		local function on(q) return q.x >= 0 and q.y >= 0 and q.x + q.w <= w and q.y + q.h <= h end
		for _, k in ipairs{"act", "auto", "skills", "more", "strip"} do
			if r[k] and not on(r[k]) then T.log("OFFSCREEN "..k) end
		end
		if r.hand == "left" and r.act.x > r.auto.x then T.log("BAD left hand but Act right of AUTO") end
		if r.hand == "right" and r.act.x < r.auto.x then T.log("BAD right hand but Act left of AUTO") end
		if r.portrait then
			-- the band: no Skills button, the strip always there, the map viewport above it
			if r.skills then T.log("BAD portrait has a Skills button") end
			if not r.strip then T.log("BAD portrait has no skill strip") end
			if r.strip and r.strip.w < w - sa.l - sa.r - 30 then T.log("BAD portrait strip not full width") end
			local vh = require("engine.Map").viewport.height
			T.log(("band_y=%s strip_y=%s dock_y=%s viewport_h=%s"):format(tostring(r.band_y), tostring(r.strip and r.strip.y), r.act.y, tostring(vh)))
			if not r.band_y or r.band_y <= game.h - 400 then T.log("BAD band_y too low or missing", tostring(r.band_y)) end
			if r.band_y and vh > r.band_y then T.log("BAD map viewport reaches under the band", vh, r.band_y) end
		end
	end
	for _, k in ipairs{"player", "minimap", "buffs", "gamelog"} do
		local d = game.uiset.places[k]
		if d then T.log(("place %s x=%d y=%d scale=%.2f"):format(k, d.x, d.y, d.scale or 1)) end
	end
	-- let the autopilot finish birth (the first level-up dialog is part of it:
	-- closing it by hand leaves creating_player set and the HUD hidden), then
	-- dismiss whatever popups remain (intro text) so the HUD is visible
	-- (EXIT, not unregister: the level-up and intro dialogs finish birth in
	-- their exit callbacks)
	for _ = 1, 8 do
		if not game.creating_player and not (game.dialogs and #game.dialogs > 0) then break end
		T.key("EXIT") T.wait(1500)
	end
	T.waitFor(function() return not game.creating_player end, 30000)
	T.wait(800)
	T.log("creating="..tostring(game.creating_player).." dialogs="..tostring(#game.dialogs))
	local function where(tag)
		local map, p = game.level and game.level.map, game.player
		if map and p then local sx, sy = map:getTileToScreen(p.x, p.y) T.log(("%s player %d,%d view %s,%s screen %s,%s"):format(tag, p.x, p.y, map.mx, map.my, sx, sy)) end
	end
	where("hud")
	T.shot("hud")
	T.wait(2500)
	where("hud2")
	T.shot("hud2")
	-- landscape: open the drawer so the second screenshot shows it (portrait: the strip is always there)
	if m and m.rects.skills then T.tap(m.rects.skills.x + 20, m.rects.skills.y + 20) T.wait(400) end
	if m and m.rects.portrait and not game.uiset.touch_strip_rects then T.log("BAD portrait strip cards missing without opening anything") end
	T.shot("layout")
	T.log("finished")

end
