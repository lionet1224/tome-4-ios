-- boot: tap Continue (newest save); game: log the map state after the load
return function(T)
	local Map = require "engine.Map"
	if game.__mod_info and game.__mod_info.short_name == "boot" then
		T.waitFor(function() local d = game.dialogs[#game.dialogs] return d and d.__touch_menu end, 30000)
		-- the account sheet may sit on top of the title menu: close it
		local function menuUp() local d = game.dialogs[#game.dialogs] return d and d.c_flow and d.c_flow.sections and #d.c_flow.sections > 0 end
		for _ = 1, 3 do
			if menuUp() then break end
			local d = game.dialogs[#game.dialogs]
			T.log("closing", tostring(d and d.__CLASSNAME))
			if d and tostring(d.__CLASSNAME):find("FirstRun") then game:unregisterDialog(d) elseif d then T.key("EXIT") end
			T.waitFor(menuUp, 20000)
		end
		-- the save list is scanned in the background: wait for the first card
		-- the newest save's card: the first card of the first section that holds saves
		local function firstCard()
			local d = game.dialogs[#game.dialogs]
			if not (d and d.c_flow) then return nil end
			for _, sec in ipairs(d.c_flow.sections or {}) do
				for _, it in ipairs(sec.items or {}) do if it.save or it.data and it.data.save or tostring(sec.title or ""):lower():find("continue") or tostring(sec.title or ""):lower():find("saved") then return it end end
			end
		end
		T.waitFor(function() return firstCard() ~= nil end, 30000)
		T.wait(800)
		local d = game.dialogs[#game.dialogs]
		local parts = {}
		for _, sec in ipairs(d.c_flow and d.c_flow.sections or {}) do parts[#parts+1] = ("%s=%d"):format(tostring(sec.title), #(sec.items or {})) end
		T.log("menu sections", table.concat(parts, " | "))
		local it = firstCard()
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
