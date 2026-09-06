-- live rotation: open the inventory, switch orientation from Lua, check the dialog rebuild
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local TI = require "engine.TouchInput"
	T.log(("before: %dx%d portrait=%s"):format(game.w, game.h, tostring(TI.portrait())))
	T.key("SHOW_INVENTORY") T.wait(800)
	local d = game.dialogs[#game.dialogs]
	T.log("dialog", tostring(d and d.__CLASSNAME), "w", d and d.w, "h", d and d.h)
	T.shot("rotate-before")
	-- ask iOS for the other orientation, the way the Options row does, and wait for the resize
	local w0 = game.w
	local want = TI.portrait() and "landscape" or "portrait"
	local ok, live = pcall(core.display.setOrientation, want)
	T.log("setOrientation", want, tostring(ok), tostring(live))
	T.waitFor(function() return game.w ~= w0 end, 20000)
	T.wait(2500)
	local d2 = game.dialogs[#game.dialogs]
	T.log(("after: %dx%d portrait=%s dialog=%s same=%s w=%s h=%s"):format(game.w, game.h, tostring(TI.portrait()), tostring(d2 and d2.__CLASSNAME), tostring(d2 == d), tostring(d2 and d2.w), tostring(d2 and d2.h)))
	if game.w == w0 then T.log("BAD no rotation arrived") end
	if d2 == d then T.log("BAD dialog was not rebuilt") end
	if d2 and d2.w and d2.w > game.w then T.log("BAD dialog wider than the screen") end
	T.shot("rotate-after")
	T.log("finished")
end
