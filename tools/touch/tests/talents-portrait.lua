-- Touch talent browser in portrait: full-width cards, bottom sheet, buttons inside, reopen.
-- Run with TOUCH_EXTRA=', orientation="portrait", hand="left"' tools/touch/sim-run.sh tools/touch/tests/talents-portrait.lua <outdir>
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local TI = require "engine.TouchInput"
	T.log("size", game.w, game.h, "portrait", tostring(TI.portrait()))
	local d = require("mod.dialogs.TouchTalents").new(game.player)
	game:registerDialog(d)
	T.wait(800)
	T.log("dialog", d.iw, d.ih, "portrait layout", tostring(d.portrait), "sheet_y", tostring(d.sheet_y), "sheet_h", tostring(d.sheet_h), "flow h", d.c_flow.h)

	-- every placed ui inside the dialog, none with an empty size (parked ones sit at -9999 / 100000)
	local function checkBounds(tag)
		local bad = 0
		for _, u in ipairs(d.uis) do
			local ui = u.ui
			if not (ui.w and ui.w > 0 and ui.h and ui.h > 0) then T.log("BAD "..tag..": ui with empty size", tostring(ui.text or ui.__CLASSNAME), tostring(ui.w), tostring(ui.h)) bad = bad + 1 end
			if u.x > -1000 and u.x < 50000 then
				if u.x < d.ix or u.y < d.iy or u.x + ui.w > d.ix + d.iw + 8 or u.y + ui.h > d.iy + d.ih + 8 then
					T.log("BAD "..tag..": ui outside the dialog", tostring(ui.text or ui.__CLASSNAME), u.x, u.y, ui.w, ui.h, "dialog", d.ix, d.iy, d.iw, d.ih) bad = bad + 1
				end
			end
		end
		T.log(tag, "bounds checked, problems", bad)
	end
	local function itemAt(sec, i)
		local it = d.c_flow.sections[sec].items[i]
		return d.c_flow.last_screen_x + it.x + it.w / 2, d.c_flow.last_screen_y + it.y + it.h / 2 - d.c_flow.scrollbar.pos
	end
	local function btn(b) local u = d.ui_by_ui[b] return d.display_x + u.x + b.w / 2, d.display_y + u.y + b.h / 2 end
	checkBounds("open")
	T.log("sections", #d.c_flow.sections, d.c_flow.sections[1] and d.c_flow.sections[1].title or "none")
	T.shot("talents-portrait")

	-- first card of the first group: the sheet shows it, the buttons come out of parking
	T.tap(itemAt(1, 1)) T.wait(500)
	T.log("selected", tostring(d.cur and d.cur.talent), "mode", tostring(d.cur and d.cur.t.mode), "desc item", tostring(d.c_desc.cur_item ~= nil))
	if not d.cur then T.log("BAD card tap did not select a talent") end
	checkBounds("selected")
	T.shot("talents-portrait-detail")
	-- the sheet buttons sit below the cards, inside the sheet
	if d.sheet_y and d.cur and d.cur.t.mode ~= "passive" then -- the sheet exists in portrait only
		local u = d.ui_by_ui[d.b_use]
		if u.y < d.iy + d.sheet_y then T.log("BAD Use button is not in the bottom sheet", u.y, d.sheet_y) end
		local a, w = d.ui_by_ui[d.b_auto], d.ui_by_ui[d.b_wheel]
		if a.x < w.x + d.b_wheel.w then T.log("BAD Put on bar / Auto-use overlap", w.x, d.b_wheel.w, a.x) end
	end

	-- drag-scroll the cards (the flow is the only thing above the sheet)
	local x, y = itemAt(1, 1)
	T.swipe(x, y + 250, x, y, 400) T.wait(600)
	T.log("flow scroll", tostring(d.c_flow.scrollbar.pos))

	-- rotation hook: a fresh dialog showing the same talent
	local nd = d:touch_reopen()
	T.log("reopen: talent", tostring(d.cur and d.cur.talent), "->", tostring(nd and nd.cur and nd.cur.talent), "portrait", tostring(nd and nd.portrait))
	if not nd or (d.cur and (not nd.cur or nd.cur.talent ~= d.cur.talent)) then T.log("BAD touch_reopen lost the selection") end
	if nd then
		game:replaceDialog(d, nd) d = nd
		T.wait(500)
		checkBounds("reopened")
		T.shot("talents-portrait-reopened")
	end
	T.key("EXIT") T.wait(300)
	T.log("closed", tostring(not game:hasDialog(d)))
	T.log("finished")
end
