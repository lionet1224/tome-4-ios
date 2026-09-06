-- Touch journal in portrait: tabs, full-width list, bottom sheet, reopen keeps the entry.
-- Run with TOUCH_EXTRA=', orientation="portrait", hand="left"' tools/touch/sim-run.sh tools/touch/tests/journal-portrait.lua <outdir>
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local TI = require "engine.TouchInput"
	local p = game.player
	-- fake state: one known lore entry, no popups
	local defs = require("mod.class.interface.PartyLore").lore_defs
	local def
	for _, l in ipairs(defs) do if type(l.lore) == "string" and l.name and l.id then def = l break end end
	if def then pcall(function() game.party:learnLore(def.id, true, true, true) end) end
	T.log("size", game.w, game.h, "portrait", tostring(TI.portrait()), "lore", tostring(def and def.id))

	local d = require("mod.dialogs.TouchJournal").new("quests")
	game:registerDialog(d)
	T.wait(800)
	T.log("dialog", d.iw, d.ih, "portrait layout", tostring(d.portrait), "sheet_y", tostring(d.sheet_y), "hero_h", d.hero_h)

	local function checkBounds(tag)
		local bad = 0
		for _, u in ipairs(d.uis) do
			local ui = u.ui
			if not (ui.w and ui.w > 0 and ui.h and ui.h > 0) then T.log("BAD "..tag..": ui with empty size", tostring(ui.__CLASSNAME), tostring(ui.w), tostring(ui.h)) bad = bad + 1 end
			if u.x < 50000 then
				if u.x < d.ix or u.y < d.iy or u.x + ui.w > d.ix + d.iw + 1 or u.y + ui.h > d.iy + d.ih + 1 then
					T.log("BAD "..tag..": ui outside the dialog", tostring(ui.__CLASSNAME), u.x, u.y, ui.w, ui.h, "dialog", d.ix, d.iy, d.iw, d.ih) bad = bad + 1
				end
			end
		end
		T.log(tag, "bounds checked, problems", bad)
	end
	checkBounds("open")
	local function itemAt(sec, i)
		local it = d.c_flow.sections[sec] and d.c_flow.sections[sec].items[i]
		if not it then return nil end
		return d.c_flow.last_screen_x + it.x + it.w / 2, d.c_flow.last_screen_y + it.y + it.h / 2 - d.c_flow.scrollbar.pos
	end
	-- first quest card (section 1 is the Active/Done chips)
	local x, y = itemAt(2, 1)
	if x then T.tap(x, y) T.wait(400) end
	T.log("quest picked", tostring(d.cur and d.cur.name), "desc item", tostring(d.c_desc.cur_item ~= nil))
	if not d.cur then T.log("BAD quest tap did not select") end
	checkBounds("quest")
	T.shot("journal-portrait")
	-- Done chip
	x, y = itemAt(1, 2)
	if x then T.tap(x, y) T.wait(400) end
	T.log("filter", tostring(d.filters.quests))
	if d.filters.quests ~= "done" then T.log("BAD Done chip did not switch the filter") end
	x, y = itemAt(1, 1)
	if x then T.tap(x, y) T.wait(400) end

	-- Lore tab
	local tabs = d.ui_by_ui[d.c_tabs]
	local tab2 = d.c_tabs.uis[2]
	if tabs and tab2 then T.tap(d.display_x + tabs.x + tab2.x + tab2.ui.w / 2, d.display_y + tabs.y + tab2.ui.h / 2) T.wait(500) end
	if d.kind ~= "lore" then d.c_tabs:select("lore") d:switchTab("lore") T.wait(300) end
	T.log("tab", tostring(d.kind))
	x, y = itemAt(1, 1)
	if x then T.tap(x, y) T.wait(500) end
	T.log("lore picked", tostring(d.cur and d.cur.name))
	checkBounds("lore")
	T.shot("journal-portrait-lore")

	-- rotation hook: a fresh dialog with the same tab and entry
	local nd = d:touch_reopen()
	T.log("reopen: kind", d.kind, "->", tostring(nd and nd.kind), "cur", tostring(d.cur and d.cur.name), "->", tostring(nd and nd.cur and nd.cur.name))
	if not nd or nd.kind ~= d.kind then T.log("BAD touch_reopen lost the tab") end
	if nd and d.cur and not (nd.cur and nd.cur.name == d.cur.name) then T.log("BAD touch_reopen lost the selection") end
	if nd then
		game:replaceDialog(d, nd) d = nd
		T.wait(500)
		checkBounds("reopened")
		T.shot("journal-portrait-reopened")
	end
	T.key("EXIT") T.wait(400)
	T.log("closed", tostring(not game:hasDialog(d)))
	T.log("finished")
end
