-- Touch title screen + load game. Runs on the boot module: needs
--   touch = {show_island=true, script="/touch-mainmenu.lua", script_boot=true}
-- and autopilot = false (otherwise the autopilot starts a new game at once).
return function(T)
	T.waitFor(function() return game and game.__mod_info and game.__mod_info.short_name == "boot" and game.dialogs and game.dialogs[#game.dialogs] and game.dialogs[#game.dialogs].__touch_menu end, 60000)
	T.wait(1200)
	local d = game.dialogs[#game.dialogs]
	if not d or not d.__touch_menu then T.log("no touch main menu on top", tostring(d and (d.title or d.__CLASSNAME))) T.log("finished") return end
	T.shot("menu-open")
	T.log("continue save", tostring(d.last_save and d.last_save.name))
	local function card(dlg, name)
		for _, sec in ipairs(dlg.c_flow.sections) do
			for _, it in ipairs(sec.items) do
				if it.name == name then return dlg.c_flow.last_screen_x + it.x + it.w / 2, dlg.c_flow.last_screen_y + it.y + it.h / 2 - dlg.c_flow.scrollbar.pos end
			end
		end
	end
	local x, y = card(d, _t"Load game")
	if not x then T.log("no Load game card") T.log("finished") return end
	T.tap(x, y) T.wait(2500)
	local ld = game.dialogs[#game.dialogs]
	T.log("top after tap", tostring(ld and ld.title), "touch load", tostring(ld and ld.__touch_load))
	T.shot("load-open")
	if ld and ld.__touch_load then
		T.log("saves", #ld.saves)
		local sec = ld.c_flow.sections[1]
		local it = sec and sec.items[1]
		if it and it.data then
			T.tap(ld.c_flow.last_screen_x + it.x + it.w / 2, ld.c_flow.last_screen_y + it.y + it.h / 2 - ld.c_flow.scrollbar.pos) T.wait(800)
			T.log("selected", tostring(ld.save_sel and ld.save_sel.name))
		end
		T.shot("load-detail")
	end
	T.log("finished")
end
