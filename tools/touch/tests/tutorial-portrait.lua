-- Controls reference in portrait: illustration on top, words under it, pages, swipe, reopen.
-- Run with TOUCH_EXTRA=', orientation="portrait", hand="left"' tools/touch/sim-run.sh tools/touch/tests/tutorial-portrait.lua <outdir>
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local TI = require "engine.TouchInput"
	T.log("size", game.w, game.h, "portrait", tostring(TI.portrait()))
	config.settings.touch = config.settings.touch or {}
	config.settings.touch.tutorial_seen = nil
	local TT = require "mod.dialogs.TouchTutorial"
	local d = TT.new()
	game:registerDialog(d) T.wait(800)
	T.log("dialog", d.iw, d.ih, "portrait layout", tostring(d.portrait), "ill", d.ill_w, d.ill_h, "text", d.text_x, d.text_y, d.text_w)
	local function checkBounds(tag)
		local bad = 0
		for _, u in ipairs(d.uis) do
			local ui = u.ui
			if not (ui.w and ui.w > 0 and ui.h and ui.h > 0) then T.log("BAD "..tag..": ui with empty size", tostring(ui.text or ui.__CLASSNAME), tostring(ui.w), tostring(ui.h)) bad = bad + 1 end
			if u.x > -1000 and u.x < 50000 then
				if u.x < d.ix or u.y < d.iy or u.x + ui.w > d.ix + d.iw + 1 or u.y + ui.h > d.iy + d.ih + 1 then
					T.log("BAD "..tag..": ui outside the dialog", tostring(ui.text or ui.__CLASSNAME), u.x, u.y, ui.w, ui.h, "dialog", d.ix, d.iy, d.iw, d.ih) bad = bad + 1
				end
			end
		end
		T.log(tag, "bounds checked, problems", bad)
	end
	checkBounds("open")
	if d.portrait and (d.ill_w < d.iw - 1 or d.text_w < d.iw - 1) then T.log("BAD portrait panes not full width", d.ill_w, d.text_w, d.iw) end
	local function btn(b) local u = d.ui_by_ui[b] return d.display_x + u.x + b.w / 2, d.display_y + u.y + b.h / 2 end
	local n = #TT.PAGES
	T.shot("tutorial-portrait-1")
	T.tap(btn(d.b_next)) T.wait(400)
	T.log("after Next: page", d.page)
	if d.page ~= 2 then T.log("BAD Next did not turn the page") end
	T.shot("tutorial-portrait-2")
	-- every page gets a shot (the illustrations are hand drawn), then back to page 2
	for i = 3, 5 do T.tap(btn(d.b_next)) T.wait(300) T.shot("tutorial-portrait-" .. i) end
	for i = 3, 5 do T.tap(btn(d.b_back)) T.wait(200) end
	T.log("back on page", d.page)
	-- a horizontal swipe on the illustration (top pane in portrait) turns pages
	local ix, iy = d.display_x + d.ix + d.ill_w / 2, d.display_y + d.iy + d.ill_h / 2
	T.swipe(ix - 60, iy, ix + 80, iy, 120) T.wait(600)
	T.log("after swipe right: page", d.page)
	if d.page ~= 1 then T.log("BAD swipe right did not go back") end
	T.swipe(ix + 60, iy, ix - 80, iy, 120) T.wait(600)
	T.log("after swipe left: page", d.page)
	-- rotation hook: same page
	local nd = d:touch_reopen()
	T.log("reopen", tostring(nd ~= nil), "page", tostring(nd and nd.page))
	if not nd or nd.page ~= d.page then T.log("BAD touch_reopen lost the page") end
	if nd then game:replaceDialog(d, nd) d = nd T.wait(400) checkBounds("reopened") T.shot("tutorial-portrait-reopened") end
	-- to the last page and Done
	for i = d.page, n - 1 do T.tap(btn(d.b_next)) T.wait(300) end
	T.log("page", d.page, "of", n, "next says", tostring(d.b_next.text))
	T.shot("tutorial-portrait-last")
	T.tap(btn(d.b_next)) T.wait(600)
	T.log("after Done: open", tostring(game:hasDialog(d)), "seen", tostring(config.settings.touch.tutorial_seen))
	T.log("finished")
end
