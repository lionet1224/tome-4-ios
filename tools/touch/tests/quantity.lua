-- Touch quantity prompt: steppers, chips, drag bar, OK
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local d = require("engine.dialogs.GetQuantity").new("How many?", "Drop", 3, 20, function(q) print("[SCRIPT] qty", q) end)
	game:registerDialog(d)
	T.wait(800) T.shot("qty-open")
	local function btn(b) local u = d.ui_by_ui[b] return d.display_x + u.x + b.w / 2, d.display_y + u.y + b.h / 2 end
	T.tap(btn(d.b_plus)) T.tap(btn(d.b_plus)) T.wait(300)
	T.log("after ++", tostring(d.c_bar.number))
	T.tap(btn(d.b_half)) T.wait(300)
	T.log("after half", tostring(d.c_bar.number))
	local bx, by = d.c_bar.last_screen_x, d.c_bar.last_screen_y + d.c_bar.h / 2
	T.swipe(bx + 20, by, bx + d.c_bar.w - 20, by, 500) T.wait(400)
	T.log("after drag", tostring(d.c_bar.number))
	T.shot("qty-set")
	T.tap(btn(d.b_ok)) T.wait(400)
	T.log("dialog closed", tostring(not game:hasDialog(d)))
	T.log("finished")
end
