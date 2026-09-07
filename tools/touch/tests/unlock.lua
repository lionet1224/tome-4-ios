-- The "option unlocked" notice fits the phone: name in gold, scrollable text, OK.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local d = require("mod.dialogs.UnlockDialog").new("adventurer")
	game:registerDialog(d) T.wait(600)
	T.log(("dialog %dx%d at %d,%d screen %dx%d name=%s touch=%s"):format(d.w, d.h, d.display_x, d.display_y, game.w, game.h, tostring(d.name), tostring(d.touch)))
	if not d.touch then T.log("BAD not the touch layout") end
	if d.display_x < 0 or d.display_y < 0 or d.display_x + d.w > game.w or d.display_y + d.h > game.h then T.log("BAD dialog does not fit the screen") end
	local ok = d.ui_by_ui[d.b_ok]
	T.log("OK button", tostring(ok ~= nil), ok and ok.x, ok and ok.y, d.b_ok and d.b_ok.w)
	if not ok then T.log("BAD no OK button") end
	if ok and ok.x + d.b_ok.w > d.ix + d.iw + 3 then T.log("BAD OK button overflows") end
	if not d.c_text.cur_item then T.log("BAD no text shown") end
	T.shot("unlock")
	d.b_ok.fct()
	T.wait(300)
	T.log("closed", tostring(not game:hasDialog(d)))
	if game:hasDialog(d) then T.log("BAD OK did not close it") end
	T.log("finished")
end
