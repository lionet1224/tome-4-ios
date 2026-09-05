return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local d = require("engine.dialogs.GetText").new("Type a name", "Name", 2, 25, function(t) print("[SCRIPT] got", t) end, function() end)
	game:registerDialog(d) T.wait(800)
	T.shot("kb-open")
	local box = d.c_box
	local u = d.ui_by_ui[box]
	T.log("box", tostring(box ~= nil), "focused", tostring(box and box.focused), "at", u and (d.display_x + u.x) or -1, u and (d.display_y + u.y) or -1)
	if u then T.tap(d.display_x + u.x + box.w / 2, d.display_y + u.y + box.h / 2) end
	T.wait(1500)
	T.log("after tap focused", tostring(box and box.focused))
	T.shot("kb-tapped")
	T.log("finished")
end
