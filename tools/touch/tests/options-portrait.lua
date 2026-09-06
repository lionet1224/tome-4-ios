-- Touch options in portrait: section chips on top, rows full width, toggle, reopen keeps the section.
-- Run with TOUCH_EXTRA=', orientation="portrait", hand="left"' tools/touch/sim-run.sh tools/touch/tests/options-portrait.lua <outdir>
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local TI = require "engine.TouchInput"
	T.log("size", game.w, game.h, "portrait", tostring(TI.portrait()))
	local d = require("mod.dialogs.TouchOptions").new()
	game:registerDialog(d)
	T.wait(800)
	T.log("dialog", d.iw, d.ih, "portrait layout", tostring(d.portrait), "nav_h", tostring(d.nav_h), "sections", #d.sections, "first", tostring(d.kind), "rows", #d.c_rows.items)

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
	local function navAt(i) local it = d.c_nav.sections[1].items[i] return d.c_nav.last_screen_x + it.x + it.w / 2, d.c_nav.last_screen_y + it.y + it.h / 2 - d.c_nav.scrollbar.pos end
	local function rowAt(i) local it = d.c_rows.items[i] return d.c_rows.last_screen_x + it.x + it.w / 2, d.c_rows.last_screen_y + it.y + it.h / 2 - d.c_rows.scrollbar.pos end
	-- the chips must all sit inside the nav strip
	local last = d.c_nav.sections[1].items[#d.c_nav.sections[1].items]
	T.log("chips", #d.c_nav.sections[1].items, "last chip bottom", last and (last.y + last.h) or -1, "strip", d.c_nav.h, "scroll max", d.c_nav.scrollbar.max)
	T.shot("options-portrait")
	-- the Interface section, then back to Touch
	local gi, ti
	for i, s in ipairs(d.sections) do if s.kind == "ui" then gi = i end if s.kind == "touch" then ti = i end end
	if gi then T.tap(navAt(gi)) T.wait(500) end
	T.log("kind after chip", tostring(d.kind), "rows", #d.c_rows.items)
	if gi and d.kind ~= "ui" then T.log("BAD section chip did not switch") end
	T.shot("options-portrait-ui")
	if ti then T.tap(navAt(ti)) T.wait(400) end
	T.log("kind", tostring(d.kind), "rows", #d.c_rows.items)
	-- first row of the Touch section is a toggle: tap, read, tap back
	if ti and d.c_rows.items[1] then
		local TouchWheel = require "mod.class.TouchWheel"
		local before = tostring(TouchWheel.setting("wheel"))
		T.tap(rowAt(1)) T.wait(400)
		local after = tostring(TouchWheel.setting("wheel"))
		T.log("wheel setting", before, "->", after, "value shown", d.c_rows.valueOf(d.c_rows.items[1]))
		if before == after then T.log("BAD row tap did not toggle") end
		T.tap(rowAt(1)) T.wait(400)
		T.log("restored", tostring(TouchWheel.setting("wheel")))
	end
	-- drag-scroll the rows
	if d.c_rows.items[1] then
		local x, y = rowAt(1)
		T.swipe(x, y + 300, x, y, 400) T.wait(600)
		T.log("scroll", tostring(d.c_rows.scrollbar.pos), "max", tostring(d.c_rows.scrollbar.max))
	end
	checkBounds("scrolled")

	-- rotation hook: a fresh dialog on the same section
	local nd = d:touch_reopen()
	T.log("reopen: kind", tostring(d.kind), "->", tostring(nd and nd.kind), "rows", #d.c_rows.items, "->", tostring(nd and #nd.c_rows.items))
	if not nd or nd.kind ~= d.kind then T.log("BAD touch_reopen lost the section") end
	if nd then
		game:replaceDialog(d, nd) d = nd
		T.wait(500)
		checkBounds("reopened")
		T.shot("options-portrait-reopened")
	end
	T.key("EXIT") T.wait(300)
	T.log("closed", tostring(not game:hasDialog(d)))
	T.log("finished")
end
