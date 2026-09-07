return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local _, _, _, _, rw, rh = core.display.size()
	T.log("size", game.w, game.h, "real", tostring(rw), tostring(rh))
	game.touch_bg_debug = true
	T.key("SHOW_INVENTORY") T.wait(1200)
	T.log("static", tostring(game.touch_bg_valid), "tex", tostring(game.touch_bg_tex ~= nil))
	T.shot("grab-debug")
	T.key("EXIT") T.wait(300)
	T.log("finished")
end
