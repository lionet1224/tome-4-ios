-- portrait: tapping an enemy shows it in the strip header
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local p, map = game.player, game.level.map
	local m = game.uiset.touch_manual
	local npc
	for _, d in ipairs{{2, 0}, {-2, 0}, {0, 2}, {0, -2}, {2, 2}, {-2, -2}} do
		local x, y = p.x + d[1], p.y + d[2]
		if map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR) then
			npc = game.zone:makeEntity(game.level, "actor", {type="vermin"}, nil, true)
			if npc then game.zone:addEntity(game.level, npc, "actor", x, y) npc.faction = "enemies" break end
		end
	end
	if not npc then T.log("no npc") T.log("finished") return end
	p:playerFOV() T.wait(400)
	local sx, sy = map:getTileToScreen(npc.x, npc.y, true)
	T.log("portrait", tostring(require("engine.TouchInput").portrait()), "tap at", sx, sy, "band_y", tostring(m.rects.band_y))
	T.tap(sx, sy) T.wait(600)
	T.log("touch_target", tostring(p.touch_target and p.touch_target.name), "target()", tostring(m:target() and m:target().name), "header rect", tostring(m.strip_who_rect ~= nil))
	if not m:target() then T.log("BAD tapping the enemy did not select it") end
	T.shot("target7")
	T.log("finished")
end
