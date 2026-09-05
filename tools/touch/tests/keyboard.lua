return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local d = require("engine.dialogs.GetText").new("Type a name", "Name", 2, 25, function(t) print("[SCRIPT] got", t) end, function() end)
	game:registerDialog(d) T.wait(800)
	local box = d.c_box
	local u = d.ui_by_ui[box]
	T.tap(d.display_x + u.x + box.w / 2, d.display_y + u.y + box.h / 2) T.wait(1200)
	local TI = require "engine.TouchInput"
	T.log("after tap: keyboard owner set", tostring(TI.osk ~= nil))
	-- a popup over the dialog must hide the keyboard
	require("engine.ui.Dialog"):simplePopup("Login failed", "Bad password.") T.wait(1200)
	T.log("after popup: keyboard owner set", tostring(TI.osk ~= nil))
	T.key("EXIT") T.wait(600)
	T.log("finished")
end
