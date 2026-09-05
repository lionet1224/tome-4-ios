-- Touch practice level: run with `tools/touch/sim-run.sh tools/touch/tests/practice.lua <out> boot`
-- (boot mode: autopilot off, script runs on the title screen). Boot phase: tap "Practice the
-- controls"; the game reboots into tome with a practice character. Game phase: drive step 1 by
-- moving, then skip through the rest logging titles.
return function(T)
	if game.__mod_info and game.__mod_info.short_name == "boot" then
		T.waitFor(function() local d = game.dialogs[#game.dialogs] return d and d.__touch_menu end, 30000)
		T.wait(800)
		local d = game.dialogs[#game.dialogs]
		local card
		for _, sec in ipairs(d.c_flow.sections) do for _, it in ipairs(sec.items) do if it.name == "Practice the controls" then card = it end end end
		if not card then T.log("no practice card") T.log("finished") return end
		T.log("boot: tapping practice")
		T.tap(d.c_flow.last_screen_x + card.x + card.w / 2, d.c_flow.last_screen_y + card.y + card.h / 2 - d.c_flow.scrollbar.pos)
		return
	end
	-- tome phase: wait for the practice level and the intro popup, then close it
	T.waitFor(function() return game.zone and game.zone.short_name == "touch-tutorial" and game.player and game.player.x end, 90000)
	T.wait(1500)
	for _ = 1, 3 do if #game.dialogs > 0 then T.key("EXIT") T.wait(600) end end
	T.waitFor(function() return game.touch_coach ~= nil end, 10000)
	local c = game.touch_coach
	T.log("zone", tostring(game.zone and game.zone.short_name), "coach", tostring(c ~= nil), "step", c and c.step or -1, c and c:current().title or "")
	T.shot("practice-1")
	-- step 1: walk onto the mark
	local mx, my
	for _, s in ipairs(game.level.spots) do if s.type == "practice" and s.subtype == "mark" then mx, my = s.x, s.y end end
	T.log("mark at", tostring(mx), tostring(my), "player", game.player.x, game.player.y)
	for _ = 1, 8 do
		if game.player.x == mx and game.player.y == my then break end
		game.player:moveDir(game.player.x < mx and 6 or (game.player.x > mx and 4 or (game.player.y < my and 2 or 8)))
		T.wait(250)
	end
	T.wait(600)
	T.log("after walk: step", c.step, c:current().title)
	T.shot("practice-2")
	-- the rest: skip, logging each title
	local guard = 0
	while c.step < #c.STEPS and guard < 10 do
		T.log("skip step", c.step, c:current().title)
		c:skip() T.wait(400) guard = guard + 1
	end
	T.log("final step", c.step, c:current().title)
	T.shot("practice-3")
	T.log("finished")
end
