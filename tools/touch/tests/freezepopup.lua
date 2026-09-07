-- A small popup (the sealed-door message) freezes the game beneath it just like a big sheet.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local TI = require "engine.TouchInput"
	local Dialog = require "engine.ui.Dialog"
	local f0 = TI.frames T.wait(1000) local base = TI.frames - f0
	local d = Dialog:simplePopup("Sealed door", "This door is sealed by a powerful ward. You cannot pass.")
	T.wait(500)
	local frozen = game.touch_bg_valid
	local f1 = TI.frames T.wait(1000) local under = TI.frames - f1
	T.log("popup", d.w, "x", d.h, "frozen", tostring(frozen), "fps free", base, "fps under popup", under)
	T.key("EXIT") T.wait(300)
	T.log("after close frozen", tostring(game.touch_bg_valid))
	-- the run popup must stay live
	local r = Dialog:simplePopup("Running...", "...")
	T.wait(300) T.log("running popup frozen", tostring(game.touch_bg_valid))
	local live = not game.touch_bg_valid
	T.key("EXIT") T.wait(300)
	if not frozen or not live or game.touch_bg_valid then T.log("BAD freeze rule") end
	T.log("finished")
end
