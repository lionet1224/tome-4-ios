-- Touch options screen: sections on the left, rows on the right, toggles in place.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local d = require("mod.dialogs.TouchOptions").new()
	game:registerDialog(d)
	T.wait(800) T.shot("options-open")
	T.log("sections", #d.sections, "first", tostring(d.kind), "rows", #d.c_rows.items)
	local function navAt(i) local it = d.c_nav.sections[1].items[i] return d.c_nav.last_screen_x + it.x + it.w / 2, d.c_nav.last_screen_y + it.y + it.h / 2 - d.c_nav.scrollbar.pos end
	local function rowAt(i) local it = d.c_rows.items[i] return d.c_rows.last_screen_x + it.x + it.w / 2, d.c_rows.last_screen_y + it.y + it.h / 2 - d.c_rows.scrollbar.pos end
	-- the Touch section (first when touch is active; find it by kind to be safe)
	local ti
	for i, s in ipairs(d.sections) do if s.kind == "touch" then ti = i end end
	if ti then T.tap(navAt(ti)) T.wait(400) end
	T.shot("options-touch")
	T.log("kind", tostring(d.kind), "rows", #d.c_rows.items)
	-- first row of the section is a toggle (Touch wheels on/off): tap, read, tap back
	local TouchWheel = require "mod.class.TouchWheel"
	local before = tostring(TouchWheel.setting("wheel"))
	T.tap(rowAt(1)) T.wait(400)
	local after = tostring(TouchWheel.setting("wheel"))
	T.log("wheel setting", before, "->", after, "value shown", d.c_rows.valueOf(d.c_rows.items[1]))
	T.tap(rowAt(1)) T.wait(400)
	T.log("restored", tostring(TouchWheel.setting("wheel")))
	-- another section, and a drag-scroll of its rows
	local gi
	for i, s in ipairs(d.sections) do if s.kind == "ui" then gi = i end end
	if gi then T.tap(navAt(gi)) T.wait(500) end
	T.shot("options-ui")
	local x, y = rowAt(1)
	T.swipe(x, y + 300, x, y, 400) T.wait(600)
	T.log("ui rows", #d.c_rows.items, "scroll", tostring(d.c_rows.scrollbar.pos))
	T.shot("options-ui-scrolled")
	T.key("EXIT") T.wait(300)
	T.log("closed", tostring(not game:hasDialog(d)))
	T.log("finished")
end
