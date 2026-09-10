-- Raid: the level 50 Archmage save (tools/touch/demos/hero-archmage.lua) fighting through Vor Pride on AUTO. Portrait.
-- First pass reboots into the save; the script runs again inside the loaded game and films from there.
return function(T)
	local L = dofile("/touch-demo-lib.lua")
	if not (game.player and game.player.name == "Archmage") then
		T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(800)
		T.log("loading the Archmage save")
		game:onTickEnd(function() util.showMainMenu(false, nil, nil, "tome", "archmage", false) end)
		T.wait(60000)
		return
	end
	T.wait(2500)
	for _ = 1, 4 do if #game.dialogs > 0 then T.key("EXIT") T.wait(500) end end
	local p = game.player
	-- filming only: a fat life pool and no stop rules, so AUTO plays the whole fight out on camera
	p.max_life = 2400 p.life = 2400 p:resetToFull()
	p.autoActBlocker = function() return nil end
	p:playerFOV() game.level.map:centerViewAround(p.x, p.y) T.wait(1000)
	T.log("demo start")
	T.wait(1500)
	-- start AUTO directly with the "continue anyway" override: a boss in view would otherwise raise the confirm popup
	local why, kind = p:autoActBlocker()
	T.log("blocker", tostring(why), tostring(kind))
	if kind then p.auto_override = kind end
	p:autoActStart(true) T.wait(300)
	T.log("auto_act", tostring(p.auto_act))
	local t0 = core.game.getTime()
	while core.game.getTime() - t0 < 30000 and p.auto_act do T.wait(300) end
	T.wait(800)
	if p.auto_act then r = game.uiset.touch_auto_rect if r then T.tap(r.x + r.w / 2, r.y + r.h / 2) end end
	T.wait(1500)
	T.log("finished")
end
