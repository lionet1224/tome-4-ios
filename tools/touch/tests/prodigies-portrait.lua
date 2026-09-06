-- Touch prodigies screen in portrait: full-width cards, bottom sheet, Learn inside, reopen. Never learns anything.
-- Run with TOUCH_EXTRA=', orientation="portrait", hand="left"' tools/touch/sim-run.sh tools/touch/tests/prodigies-portrait.lua <outdir>
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local TI = require "engine.TouchInput"
	T.log("size", game.w, game.h, "portrait", tostring(TI.portrait()))
	game.player.unused_prodigies = 1
	local pending = {}
	local d = require("mod.dialogs.TouchProdigies").new(game.player, pending)
	game:registerDialog(d)
	T.wait(800)
	T.log("dialog", d.iw, d.ih, "portrait layout", tostring(d.portrait), "sheet_y", tostring(d.sheet_y), "sheet_h", tostring(d.sheet_h), "flow h", d.c_flow.h)

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
	local function itemAt(sec, i)
		local it = d.c_flow.sections[sec].items[i]
		return d.c_flow.last_screen_x + it.x + it.w / 2, d.c_flow.last_screen_y + it.y + it.h / 2 - d.c_flow.scrollbar.pos
	end
	checkBounds("open")
	local n = 0
	for _, s in ipairs(d.c_flow.sections) do n = n + #s.items end
	T.log("sections", #d.c_flow.sections, "cards", n, "flow max", tostring(d.c_flow.scrollbar.max))
	T.shot("prodigies-portrait")

	T.tap(itemAt(1, 1)) T.wait(500)
	T.log("selected", tostring(d.cur and d.cur.talent), "kind", tostring(d.cur and d.cur.kind), "status", tostring(d.cur and d.cur.status), "desc item", tostring(d.c_desc.cur_item ~= nil))
	if not d.cur then T.log("BAD card tap did not select a prodigy") end
	checkBounds("selected")
	local u = d.ui_by_ui[d.b_learn]
	if u.x > -1000 and u.y < d.iy + d.sheet_y then T.log("BAD Learn button is not in the bottom sheet", u.y, d.sheet_y) end
	T.shot("prodigies-portrait-detail")

	local x, y = itemAt(1, 1)
	T.swipe(x, y + 300, x, y, 400) T.wait(800)
	T.log("flow scroll", tostring(d.c_flow.scrollbar.pos))

	-- rotation hook: the old dialog unloads first (as the game hook does), the fresh one keeps the selection
	local tid = d.cur and d.cur.talent
	d:unload()
	local nd = d:touch_reopen()
	T.log("reopen: talent", tostring(tid), "->", tostring(nd and nd.cur and nd.cur.talent), "portrait", tostring(nd and nd.portrait), "in dialog", tostring(game.player.is_in_uber_dialog == nd))
	if not nd or (tid and (not nd.cur or nd.cur.talent ~= tid)) then T.log("BAD touch_reopen lost the selection") end
	if nd then
		game:replaceDialog(d, nd) d = nd
		T.wait(500)
		checkBounds("reopened")
		T.shot("prodigies-portrait-reopened")
	end
	local chosen = 0
	for _, v in pairs(pending) do if v then chosen = chosen + 1 end end
	T.log("chosen", chosen, "points", tostring(game.player.unused_prodigies))
	T.key("EXIT") T.wait(300)
	T.log("closed", tostring(not game:hasDialog(d)))
	T.log("finished")
end
