-- explore (which records running_prev with its popup), save, and make sure the save loads clean
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p = game.player
	T.key("RUN_AUTO") T.wait(4000)
	if p.running then p:runStop("test") end
	T.wait(300)
	T.log("running_prev", tostring(p.running_prev ~= nil), "dialog in it", tostring(p.running_prev and p.running_prev.dialog ~= nil))
	-- outside the script coroutine: saving ticks the game
	local started = false
	game:onTickEnd(function() started = true game:saveGame() end)
	T.waitFor(function() return started end, 10000)
	T.wait(500)
	T.waitFor(function() return not savefile_pipe.saving end, 90000)
	T.wait(1500)
	T.log("saved", game.save_name)
	T.log("finished")
end
