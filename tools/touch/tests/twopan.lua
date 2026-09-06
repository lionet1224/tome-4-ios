-- two-finger drag pans the map; it is neither a step nor the two-finger Escape
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local TI = require "engine.TouchInput"
	local p, map = game.player, game.level.map
	map:centerViewAround(p.x, p.y) T.wait(300)
	local mx0, my0, px, py, nd = map.mx, map.my, p.x, p.y, #game.dialogs
	local cx, cy = game.w / 2, game.h / 2 - 100
	TI.fingerDown(1, cx - 60, cy) TI.fingerDown(2, cx + 60, cy) T.wait(80)
	for i = 1, 10 do TI.fingerMove(1, cx - 60 - i * 20, cy) TI.fingerMove(2, cx + 60 - i * 20, cy) T.wait(40) end
	TI.fingerUp(2, cx + 60 - 200, cy) TI.fingerUp(1, cx - 60 - 200, cy) T.wait(500)
	T.log(("pan: view %d,%d -> %d,%d player %d,%d -> %d,%d dialogs %d -> %d"):format(mx0, my0, map.mx, map.my, px, py, p.x, p.y, nd, #game.dialogs))
	if map.mx == mx0 then T.log("BAD two-finger drag did not pan") end
	if p.x ~= px or p.y ~= py then T.log("BAD two-finger drag moved the player") end
	if #game.dialogs ~= nd then T.log("BAD two-finger drag opened/closed a dialog (Escape fired)") end
	-- a still two-finger tap is still Escape (opens the game menu when nothing is up)
	TI.fingerDown(1, cx - 60, cy) TI.fingerDown(2, cx + 60, cy) T.wait(80) TI.fingerUp(2, cx + 60, cy) TI.fingerUp(1, cx - 60, cy) T.wait(600)
	T.log("two-finger tap: dialogs", nd, "->", #game.dialogs)
	if #game.dialogs > nd then T.key("EXIT") T.wait(300) end
	T.log("finished")
end
