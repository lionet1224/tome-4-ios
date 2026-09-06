-- a tap on your own tile (rest a turn) or on the floor must not leave a tooltip on screen
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p, map = game.player, game.level.map
	map:centerViewAround(p.x, p.y) T.wait(300)
	local sx, sy = map:getTileToScreen(p.x, p.y, true)
	local turn = game.turn
	T.tap(sx, sy) T.wait(800)
	T.log("tap self: tooltip_x", tostring(game.tooltip_x), "turn", turn, "->", game.turn)
	if game.tooltip_x then T.log("BAD tooltip left after tapping yourself") end
	local fx, fy = map:getTileToScreen(p.x + 2, p.y, true)
	T.tap(fx, fy) T.wait(800)
	T.log("tap floor: tooltip_x", tostring(game.tooltip_x))
	if game.tooltip_x then T.log("BAD tooltip left after tapping the floor") end
	T.log("finished")
end
