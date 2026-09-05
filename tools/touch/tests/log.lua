-- Touch message log reader: chips, drag scrolling, jump to newest.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	for i = 1, 40 do game.log("Touch log test line %d", i) end
	local d = require("mod.dialogs.TouchLog").new(_t"Message log", 0.6, game.uiset.logdisplay, profile.chat)
	game:registerDialog(d)
	T.wait(800) T.shot("log-open")
	local sb = d.c_text.scrollbar
	T.log("opened at newest", tostring(sb and sb.pos), "of", tostring(sb and sb.max))
	-- drag up (finger moves down the screen = older lines)
	local u = d.ui_by_ui[d.c_text]
	local cx = d.display_x + u.x + d.c_text.w / 2
	local cy = d.display_y + u.y + d.c_text.h / 2
	T.swipe(cx, cy - 150, cx, cy + 150, 400) T.wait(900) T.shot("log-scrolled")
	T.log("after drag", tostring(sb and sb.pos))
	-- jump to newest
	local b = d.ui_by_ui[d.b_newest]
	T.tap(d.display_x + b.x + d.b_newest.w / 2, d.display_y + b.y + d.b_newest.h / 2) T.wait(400)
	T.log("after newest", tostring(sb and sb.pos), "max", tostring(sb and sb.max))
	-- a chat chip if any, then back to the game log
	if #d.c_chips.items > 1 then
		local c = d.ui_by_ui[d.c_chips]
		local it = d.c_chips.items[2]
		T.tap(d.display_x + c.x + it.x + it.w / 2, d.display_y + c.y + 25) T.wait(500) T.shot("log-chat")
		T.log("chip", tostring(d.cur))
		local it1 = d.c_chips.items[1]
		T.tap(d.display_x + c.x + it1.x + it1.w / 2, d.display_y + c.y + 25) T.wait(300)
	end
	T.key("EXIT") T.wait(300)
	T.log("closed", tostring(not game:hasDialog(d)))
	T.log("finished")
end
