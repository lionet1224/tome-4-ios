-- Touch level map in portrait: map fills the width, bottom sheet holds the buttons; rotation rebuild.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local TI = require "engine.TouchInput"
	local d = require("mod.dialogs.TouchMap").new()
	game:registerDialog(d)
	T.wait(800)
	T.log(("screen %dx%d portrait=%s dialog inner %dx%d map %dx%d sheet_y=%s sheet_h=%s"):format(game.w, game.h, tostring(TI.portrait()), d.iw, d.ih, d.map_w, d.map_h, tostring(d.sheet_y), tostring(d.sheet_h)))
	local function bounds(tag)
		local bad = 0
		for _, u in ipairs(d.uis) do
			local ui = u.ui
			if u.x < 50000 and u.x > -1000 then
				if ui.w <= 0 or ui.h <= 0 or u.x < d.ix or u.y < d.iy or u.x + ui.w > d.ix + d.iw + 1 or u.y + ui.h > d.iy + d.ih + 1 then
					T.log("BAD "..tag..": ui outside the dialog", tostring(ui.text or ui.__CLASSNAME), u.x, u.y, ui.w, ui.h, "inner", d.ix, d.iy, d.iw, d.ih) bad = bad + 1
				end
			end
		end
		T.log(tag, "bounds checked, problems", bad)
	end
	bounds("open")
	if d.portrait and math.abs(d.map_w - d.iw) > 1 then T.log("BAD portrait map not full width") end
	T.shot("map-portrait")
	-- zoom in through the sheet button
	local function btn(b) local u = d.ui_by_ui[b] return d.display_x + u.x + b.w / 2, d.display_y + u.y + b.h / 2 end
	local bs = d.bsize
	T.tap(btn(d.b_zin)) T.wait(300)
	T.log("bsize", bs, "-> after zoom in", d.bsize, "open", tostring(game:hasDialog(d)))
	if d.bsize <= bs then T.log("BAD zoom in did nothing") end
	-- pan across the map area
	local before = d.scroll_x .. "," .. d.scroll_y
	T.swipe(d.map_sx + d.map_w / 2 + 150, d.map_sy + d.map_h / 2, d.map_sx + d.map_w / 2 - 150, d.map_sy + d.map_h / 2, 400) T.wait(500)
	T.log("scroll after pan", d.scroll_x, d.scroll_y, "was", before, "open", tostring(game:hasDialog(d)))
	-- rotation rebuild keeps zoom
	local nd = d:touch_reopen()
	T.log("reopen", tostring(nd ~= nil), "bsize", tostring(nd and nd.bsize), "portrait", tostring(nd and nd.portrait))
	if not nd or nd.bsize ~= d.bsize then T.log("BAD reopen lost the zoom") end
	if nd then nd:unload() end
	T.tap(btn(d.b_close)) T.wait(400)
	T.log("closed", tostring(not game:hasDialog(d)))
	T.log("finished")
end
