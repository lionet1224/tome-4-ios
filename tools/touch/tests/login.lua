-- Touch login sheet on the boot title screen. Needs touch.script_boot=true and autopilot off
-- (run with: tools/touch/sim-run.sh tools/touch/tests/login.lua <out> boot). Never logs in.
return function(T)
	T.waitFor(function() return game and game.__mod_info and game.__mod_info.short_name == "boot" and game.dialogs and game.dialogs[#game.dialogs] and game.dialogs[#game.dialogs].__touch_menu end, 60000)
	T.wait(1200)
	local d = game.dialogs[#game.dialogs]
	if not d or not d.__touch_menu then T.log("no touch main menu on top") T.log("finished") return end
	local x, y
	for _, sec in ipairs(d.c_flow.sections) do
		for _, it in ipairs(sec.items) do
			if it.name == _t"Online profile" then x, y = d.c_flow.last_screen_x + it.x + it.w / 2, d.c_flow.last_screen_y + it.y + it.h / 2 - d.c_flow.scrollbar.pos end
		end
	end
	if not x then T.log("no Online profile card") T.log("finished") return end
	T.tap(x, y) T.wait(1200)
	local ld = game.dialogs[#game.dialogs]
	T.log("top after tap", tostring(ld and ld.title), "touch login", tostring(ld and ld.__touch_login), "logged", tostring(ld and ld.logged))
	T.shot("login-open")
	if ld and ld.__touch_login and ld.c_user then
		local u = ld.ui_by_ui[ld.c_user]
		T.log("sheet at", ld.display_x, ld.display_y, "username box", u and (ld.display_x + u.x) or -1, u and (ld.display_y + u.y) or -1)
		if u then T.tap(ld.display_x + u.x + ld.c_user.w / 2, ld.display_y + u.y + ld.c_user.h / 2) T.wait(1200) end
		T.log("keyboard owner set", tostring(require("engine.TouchInput").osk ~= nil))
		T.shot("login-tapped")
	end
	T.key("EXIT") T.wait(600)
	T.log("closed", tostring(game.dialogs[#game.dialogs] ~= ld))
	T.log("finished")
end
