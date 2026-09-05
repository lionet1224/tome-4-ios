return function(T)
	if game.__mod_info and game.__mod_info.short_name == "boot" then
		T.waitFor(function() local d = game.dialogs[#game.dialogs] return d and d.__touch_menu end, 30000) T.wait(800)
		local d = game.dialogs[#game.dialogs]
		local card for _, sec in ipairs(d.c_flow.sections) do for _, it in ipairs(sec.items) do if tostring(it.name):find("Practice") then card = it end end end
		if not card then T.log("no practice card") T.log("finished") return end
		T.tap(d.c_flow.last_screen_x + card.x + card.w / 2, d.c_flow.last_screen_y + card.y + card.h / 2)
		return
	end
	T.waitFor(function() return game.zone and game.zone.short_name == "touch-tutorial" and game.player and game.player.x end, 60000)
	T.wait(3000) T.key("EXIT") T.wait(800)
	local Map = require "engine.Map"
	local ex, ey
	for i = 0, game.level.map.w - 1 do for j = 0, game.level.map.h - 1 do local g = game.level.map(i, j, Map.TERRAIN) if g and g.practice_id == "exit" then ex, ey = i, j end end end
	T.log("exit at", ex, ey, "player", game.player.x, game.player.y)
	-- stand next to the exit, with the coach skipped to the last step
	while game.touch_coach and game.touch_coach.step < 7 do game.touch_coach:skip() end
	T.log("coach step", tostring(game.touch_coach and game.touch_coach.step))
	game.player.x, game.player.y = ex - 1, ey
	game.level.map:remove(ex - 1, ey, Map.ACTOR) game.level.map(ex - 1, ey, Map.ACTOR, game.player)
	game.level.map:centerViewAround(ex, ey) game.level.map.changed = true
	T.wait(600)
	T.log("placed at", game.player.x, game.player.y)
	local sx, sy = game.level.map:getTileToScreen(ex, ey, true)
	T.log("tapping the exit tile at", math.floor(sx), math.floor(sy))
	T.tap(sx, sy) T.wait(2500)
	T.log("after tapping exit: zone", tostring(game.zone and game.zone.short_name), "level", tostring(game.level and game.level.level), "player", game.player.x, game.player.y, "top", tostring(game.dialogs[#game.dialogs] and (game.dialogs[#game.dialogs].title or game.dialogs[#game.dialogs].__CLASSNAME)))
	if game.player.x == ex and game.player.y == ey then
		sx, sy = game.level.map:getTileToScreen(ex, ey, true)
		T.tap(sx, sy) T.wait(2500)
		T.log("after self tap: zone", tostring(game.zone and game.zone.short_name), "player", game.player.x, game.player.y, "top", tostring(game.dialogs[#game.dialogs] and (game.dialogs[#game.dialogs].title or game.dialogs[#game.dialogs].__CLASSNAME)))
	end
	T.log("finished")
end
