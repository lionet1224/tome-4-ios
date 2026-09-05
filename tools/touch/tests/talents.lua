-- Touch talent browser: open, pick a talent, put it on the wheel.
-- Run via settings touch.script (copy to the sim Documents dir as /touch-talents.lua).
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local d = require("mod.dialogs.TouchTalents").new(game.player)
	game:registerDialog(d)
	T.wait(800) T.shot("talents-open")
	local function itemAt(sec, i)
		local it = d.c_flow.sections[sec].items[i]
		return d.c_flow.last_screen_x + it.x + it.w / 2, d.c_flow.last_screen_y + it.y + it.h / 2 - d.c_flow.scrollbar.pos
	end
	local function btn(b) local u = d.ui_by_ui[b] return d.display_x + u.x + b.w / 2, d.display_y + u.y + b.h / 2 end
	T.log("sections", #d.c_flow.sections, d.c_flow.sections[1] and d.c_flow.sections[1].title or "none")
	-- first card of the first group (activable talents come first)
	T.tap(itemAt(1, 1)) T.wait(500)
	T.log("selected", tostring(d.cur and d.cur.talent), "mode", tostring(d.cur and d.cur.t.mode))
	T.shot("talents-detail")
	T.tap(btn(d.b_wheel)) T.wait(600)
	T.log("mode", d.mode, "sections", #d.c_flow.sections)
	T.shot("talents-slots")
	-- page 1, slot 2
	T.tap(itemAt(1, 2)) T.wait(600)
	local hk = game.player.hotkey[2]
	T.log("hotkey 2", hk and (hk[1] .. " " .. tostring(hk[2])) or "nil", "mode", d.mode)
	T.shot("talents-assigned")
	-- drag-scroll the list
	local x, y = itemAt(1, 1)
	T.swipe(x, y + 250, x, y, 400) T.wait(600)
	T.log("flow scroll", tostring(d.c_flow.scrollbar.pos))
	T.shot("talents-scrolled")
	T.key("EXIT") T.wait(300)
	T.log("closed", tostring(not game:hasDialog(d)))
	T.log("finished")
end
