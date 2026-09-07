-- the text prompt on touch: wide, keyboard up, OK/Cancel inside, ACCEPT delivers the text
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local TI = require "engine.TouchInput"
	local got, cancelled = nil, false
	local d = require("engine.dialogs.GetText").new("Name?", "name", 2, 25, function(t) got = t end, function() cancelled = true end)
	game:registerDialog(d) T.wait(800)
	T.log(("dialog %dx%d at %d,%d screen %dx%d touch=%s"):format(d.w, d.h, d.display_x, d.display_y, game.w, game.h, tostring(d.touch)))
	if d.w < game.w * (TI.portrait() and 0.8 or 0.5) then T.log("BAD prompt too narrow for touch") end
	for _, b in ipairs{d.b_ok, d.b_cancel} do
		local e = b and d.ui_by_ui[b]
		if not e then T.log("BAD button entry missing") else
			if e.x < d.ix or e.y < d.iy or e.x + b.w > d.ix + d.iw + 3 or e.y + b.h > d.iy + d.ih + 3 then T.log("BAD button outside the dialog", tostring(b.text), e.x, e.y, b.w, b.h) end
		end
	end
	T.log("keyboard owner set", tostring(TI.osk ~= nil and TI.osk.box == d.c_box))
	d.c_box:setText("abc") T.wait(200)
	T.key("ACCEPT") T.wait(500)
	T.log("callback got", tostring(got), "cancelled", tostring(cancelled), "dialog gone", tostring(game.dialogs[#game.dialogs] ~= d))
	if got ~= "abc" then T.log("BAD ACCEPT did not deliver the text") end
	if TI.osk then T.log("BAD keyboard still owned after the prompt closed") end
	T.log("finished")
end
