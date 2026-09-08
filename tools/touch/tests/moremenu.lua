-- Title screen "More": the desktop Main Menu dialog must sit on screen in portrait.
-- Boot script (script_boot=true, autopilot off), portrait orientation.
return function(T)
	T.waitFor(function() return game and game.__mod_info and game.__mod_info.short_name == "boot" and game.dialogs and game.dialogs[#game.dialogs] and game.dialogs[#game.dialogs].__touch_menu end, 60000)
	T.wait(1000)
	local menu = game.dialogs[#game.dialogs]
	if not menu or not menu.__touch_menu then T.log("no touch main menu on top") T.log("finished") return end
	local more
	for _, e in ipairs(menu.list or {}) do if e.name == _t"More" then more = e end end
	if not more then T.log("BAD no More entry") T.log("finished") return end
	more.fct() T.wait(800)
	local d = game.dialogs[#game.dialogs]
	T.log("top", tostring(d and d.title), ("at %d,%d %dx%d screen %dx%d"):format(d.display_x or -1, d.display_y or -1, d.w or -1, d.h or -1, game.w, game.h))
	T.shot("more-menu")
	if d == menu then T.log("BAD More opened nothing") T.log("finished") return end
	if d.display_x < 0 or d.display_y < 0 or d.display_x + d.w > game.w or d.display_y + d.h > game.h then T.log("BAD the More menu is off screen") end
	T.key("EXIT") T.wait(600)
	local top = game.dialogs[#game.dialogs]
	T.log("after EXIT: top", tostring(top and (top.__touch_menu and "touch menu" or top.title)), "dialogs", #game.dialogs)
	if not (top and top.__touch_menu) then T.log("BAD the More menu did not close on EXIT") end
	T.log("finished")
end
