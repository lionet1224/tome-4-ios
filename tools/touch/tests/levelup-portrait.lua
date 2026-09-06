-- Level-up dialog in portrait: buttons in two rows, list full width, description sheet, tab switch, reopen.
-- Run with TOUCH_EXTRA=', orientation="portrait", hand="left"' tools/touch/sim-run.sh tools/touch/tests/levelup-portrait.lua <outdir>
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local TI = require "engine.TouchInput"
	T.log("size", game.w, game.h, "portrait", tostring(TI.portrait()))
	local p = game.player
	p.unused_stats = 3 p.unused_talents = 2 p.unused_generics = 2 p.unused_talents_types = 1
	local finished = false
	p:playerLevelup(function() finished = true end, false)
	T.wait(1200)
	local d = game.dialogs[#game.dialogs]
	T.log("dialog", tostring(d and d.__CLASSNAME), d and d.iw, d and d.ih, "portrait layout", tostring(d and d.portrait), "top_h", tostring(d and d.top_h))
	if not d or not d.c_pane then T.log("BAD level-up dialog did not open") T.log("finished") return end
	local function checkBounds(tag)
		local bad = 0
		for _, u in ipairs(d.uis) do
			local ui = u.ui
			if not (ui.w and ui.w > 0 and ui.h and ui.h > 0) then T.log("BAD "..tag..": ui with empty size", tostring(ui.text or ui.__CLASSNAME), tostring(ui.w), tostring(ui.h)) bad = bad + 1 end
			if ui ~= d.t_messages and u.x > -1000 and u.x < 50000 then
				if u.x < d.ix or u.y < d.iy or u.x + ui.w > d.ix + d.iw + 1 or u.y + ui.h > d.iy + d.ih + 1 then
					T.log("BAD "..tag..": ui outside the dialog", tostring(ui.text or ui.__CLASSNAME), u.x, u.y, ui.w, ui.h, "dialog", d.ix, d.iy, d.iw, d.ih) bad = bad + 1
				end
			end
		end
		T.log(tag, "bounds checked, problems", bad)
	end
	checkBounds("open")
	if d.portrait and d.c_pane.w < d.iw - 1 then T.log("BAD portrait list not full width", d.c_pane.w, d.iw) end
	local function btn(b) local u = d.ui_by_ui[b] return d.display_x + u.x + b.w / 2, d.display_y + u.y + b.h / 2 end
	T.log("pane", d:paneKind(), "desc rect", tostring(d.ui_by_ui[d.c_desc] and d.ui_by_ui[d.c_desc].y), d.c_desc.w, d.c_desc.h)
	T.shot("levelup-portrait")
	-- Class points tab
	T.tap(btn(d.b_class)) T.wait(600)
	T.log("after class tap: pane", d:paneKind(), "desc has item", tostring(d.c_desc.cur_item ~= nil or (d.c_desc.list and #d.c_desc.list > 0)))
	if d:paneKind() ~= "class" then T.log("BAD class tab did not switch") end
	checkBounds("class")
	T.shot("levelup-class")
	-- the list rows must stay reachable: the first row's centre is inside the list, tap it
	local e = d.ui_by_ui[d.c_pane]
	if e then T.tap(d.display_x + e.x + d.c_pane.w / 2, d.display_y + e.y + 40) T.wait(500) T.log("tapped a row, pane still", d:paneKind()) end
	-- rotation hook (same order as Game:checkResolutionChange: unload, then reopen):
	-- nothing spent yet, so the dialog rebuilds on the same tab
	d:unload()
	local nd = d:touch_reopen()
	T.log("reopen", tostring(nd ~= nil), "pane", tostring(nd and nd:paneKind()))
	if not nd then T.log("BAD touch_reopen returned nil with nothing spent") end
	if nd and nd:paneKind() ~= "class" then T.log("BAD reopen lost the tab") end
	if nd then game:replaceDialog(d, nd) d = nd T.wait(500) checkBounds("reopened") T.shot("levelup-reopened") end
	-- with a stat point spent the reopen must refuse (Cancel would lose the undo)
	local st = d.c_stat and d.c_stat.tree and d.c_stat.tree[1]
	if d.actor.unused_stats > 0 then
		d.actor.unused_stats = d.actor.unused_stats - 1 -- stand-in for a spent point
		local nd2 = d:touch_reopen()
		T.log("reopen with pending change", tostring(nd2 ~= nil))
		if nd2 then T.log("BAD touch_reopen rebuilt a dialog with pending changes") nd2:unload() end
		d.actor.unused_stats = d.actor.unused_stats + 1
	end
	T.key("EXIT") T.wait(800)
	-- no changes: closes straight away
	T.log("closed", tostring(not game:hasDialog(d)), "on_finish", tostring(finished))
	T.log("finished")
end
