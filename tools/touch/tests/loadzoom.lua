-- boot: tap Continue (newest save); game: log the map state after the load
return function(T)
	local Map = require "engine.Map"
	if game.__mod_info and game.__mod_info.short_name == "boot" then
		T.waitFor(function() local d = game.dialogs[#game.dialogs] return d and d.__touch_menu end, 30000)
		T.wait(800)
		local d = game.dialogs[#game.dialogs]
		local it = d.c_flow and d.c_flow.sections[1] and d.c_flow.sections[1].items[1]
		if not it then T.log("no continue card") T.log("finished") return end
		T.log("boot: tapping continue", tostring(it.name))
		T.tap(d.c_flow.last_screen_x + it.x + it.w / 2, d.c_flow.last_screen_y + it.y + it.h / 2)
		return
	end
	T.wait(3000) T.key("EXIT") T.wait(800)
	local map = game.level.map
	T.log("loaded: zoom", tostring(Map.zoom), tostring(map.zoom), "viewport", map.viewport.width, map.viewport.height, map.viewport.mwidth, map.viewport.mheight, "tile", map.tile_w, "scroll", map.mx, map.my, "player", game.player.x, game.player.y)
	T.shot("after-load")
	T.log("finished")
end
