-- Screenshot sweep of every dialog in the touch gallery (engine.TouchInput script).
-- Run with touch = {script="/touch-sweep.lua", script_early=true} so the birther is caught too.
return function(T)
	if not (game.level and game.player and game.player.x) then
		T.wait(2500)
		T.shot("birther")
		T.waitFor(function() return game.level and game.player and game.player.x end, 180000)
	end
	T.wait(1500)
	T.key("EXIT") T.wait(6000)          -- birth level-up; the birth then finishes
	T.shot("welcome") T.key("EXIT") T.wait(600)
	T.shot("hud")
	for _, e in ipairs(require("mod.dialogs.TouchGallery").entries()) do
		local id = e.name:lower():gsub("[^%w]+", "-")
		local ok, err = pcall(e.fct)
		if not ok then T.log("open failed", e.name, err)
		else
			T.wait(900)
			T.shot(id)
			T.key("EXIT") T.wait(300) T.key("EXIT") T.wait(300)
		end
	end
	T.log("finished")
end
