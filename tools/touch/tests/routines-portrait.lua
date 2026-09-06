-- Touch Act routine editor in portrait: everything fits, chips on top, bottom sheet, picker, reopen.
-- Run with TOUCH_EXTRA=', orientation="portrait", hand="left"' tools/touch/sim-run.sh tools/touch/tests/routines-portrait.lua <outdir>
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local TI = require "engine.TouchInput"
	T.log("size", game.w, game.h, "portrait", tostring(TI.portrait()))
	local d = require("mod.dialogs.TouchRoutines").new(game.player)
	game:registerDialog(d)
	T.wait(800)
	T.log("dialog", d.iw, d.ih, "portrait layout", tostring(d.portrait), "top_h", tostring(d.top_h), "sheet_y", tostring(d.sheet_y))

	-- every placed ui inside the dialog, none with a zero/negative width
	local function checkBounds(tag)
		local bad = 0
		for _, u in ipairs(d.uis) do
			local ui = u.ui
			if not (ui.w and ui.w > 0 and ui.h and ui.h > 0) then T.log("BAD "..tag..": ui with empty size", tostring(ui.text or ui.__CLASSNAME), tostring(ui.w), tostring(ui.h)) bad = bad + 1 end
			if u.x > -1000 then -- parked uis sit at -9999
				if u.x < d.ix or u.y < d.iy or u.x + ui.w > d.ix + d.iw + 1 or u.y + ui.h > d.iy + d.ih + 1 then
					T.log("BAD "..tag..": ui outside the dialog", tostring(ui.text or ui.__CLASSNAME), u.x, u.y, ui.w, ui.h, "dialog", d.iw, d.ih) bad = bad + 1
				end
			end
		end
		T.log(tag, "bounds checked, problems", bad)
	end
	checkBounds("open")
	local function itemAt(flow, sec, i)
		local it = flow.sections[sec].items[i]
		return flow.last_screen_x + it.x + it.w / 2, flow.last_screen_y + it.y + it.h / 2 - flow.scrollbar.pos
	end
	local function btn(b) local u = d.ui_by_ui[b] return d.display_x + u.x + b.w / 2, d.display_y + u.y + b.h / 2 end
	T.shot("routines-portrait")

	-- chips: the second one is a real routine only when two exist (the last chip is "New routine")
	local chips = d.c_rail.sections[1] and #d.c_rail.sections[1].items or 0
	T.log("chips", chips, "routines", #game.player.act_routines, "edit_idx", d.edit_idx)
	if #game.player.act_routines >= 2 then
		local was = d.edit_idx
		T.tap(itemAt(d.c_rail, 1, 2)) T.wait(500)
		T.log("second chip: edit_idx", was, "->", d.edit_idx)
		if d.edit_idx == was then T.log("BAD second chip did not switch routine") end
	end

	-- tap a step card: the sheet shows its description
	local r = d:routine()
	T.log("routine", r.name, "steps", #r.steps)
	if #r.steps > 0 then
		T.tap(itemAt(d.c_flow, 1, 1)) T.wait(500)
		T.log("after step tap: sel_step", tostring(d.sel_step), "step", tostring(d:step() and d:step().kind), "desc item", tostring(d.c_desc.cur_item ~= nil))
		if not d:step() then T.log("BAD step tap did not select a step") end
		checkBounds("step selected")
		T.shot("routines-step")
	end

	-- picker replaces the steps, Cancel brings them back
	T.tap(btn(d.b_add)) T.wait(600)
	T.log("picker: mode", d.mode, "sections", #d.c_flow.sections)
	if d.mode ~= "picker" then T.log("BAD Add step did not open the picker") end
	checkBounds("picker")
	T.shot("routines-picker")
	T.tap(btn(d.b_cancel)) T.wait(500)
	T.log("after cancel: mode", d.mode)
	if d.mode ~= "steps" then T.log("BAD Cancel did not close the picker") end

	-- rotation hook: a fresh dialog with the same routine and step
	local nd = d:touch_reopen()
	T.log("reopen: edit_idx", d.edit_idx, "->", tostring(nd and nd.edit_idx), "sel_step", tostring(d.sel_step), "->", tostring(nd and nd.sel_step), "mode", tostring(nd and nd.mode))
	if not nd or nd.edit_idx ~= d.edit_idx or nd.sel_step ~= d.sel_step then T.log("BAD touch_reopen lost the editing state") end
	if nd then
		game:replaceDialog(d, nd) d = nd
		T.wait(500)
		checkBounds("reopened")
		T.shot("routines-reopened")
	end
	T.key("EXIT") T.wait(400)
	T.log("closed", tostring(not game:hasDialog(d)))
	T.log("finished")
end
