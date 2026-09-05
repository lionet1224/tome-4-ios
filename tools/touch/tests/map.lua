-- Touch level map: open, pan, tap a tile to travel, buttons.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local p = game.player
	local d = require("mod.dialogs.TouchMap").new()
	game:registerDialog(d)
	T.wait(800) T.shot("map-open")
	T.log("bsize", d.bsize, "fit", d.fit_size, "scroll", d.scroll_x, d.scroll_y, "exit", d.exit_target and (d.exit_target.x .. "," .. d.exit_target.y) or "none")
	-- pan with a drag across the map pane
	local sx, sy = d.map_sx + d.map_w / 2, d.map_sy + d.map_h / 2
	local before = d.scroll_x .. "," .. d.scroll_y
	T.swipe(sx + 200, sy, sx - 200, sy, 400) T.wait(500)
	T.log("scroll after pan", d.scroll_x, d.scroll_y, "was", before, "still open", tostring(game:hasDialog(d)))
	T.shot("map-panned")
	-- zoom buttons
	local function btn(b) local u = d.ui_by_ui[b] return d.display_x + u.x + b.w / 2, d.display_y + u.y + b.h / 2 end
	T.tap(btn(d.b_zin)) T.wait(300) T.log("bsize after zoom in", d.bsize)
	T.tap(btn(d.b_center)) T.wait(300)
	-- tap a walkable tile a few cells from the player
	local tx, ty
	for dx = 4, 1, -1 do
		for _, dy in ipairs{0, 1, -1} do
			local x, y = p.x + dx, p.y + dy
			if not tx and game.level.map:isBound(x, y) and not game.level.map:checkEntity(x, y, Map.TERRAIN, "block_move") then tx, ty = x, y end
		end
	end
	local ox, oy = p.x, p.y
	if tx then
		local px, py = d.map_sx + (tx - d.scroll_x + 0.5) * d.bsize, d.map_sy + (ty - d.scroll_y + 0.5) * d.bsize
		T.log("state before tap: scroll", d.scroll_x, d.scroll_y, "origin", d.map_sx, d.map_sy, "bsize", d.bsize, "pane", d.map_w, d.map_h)
		T.log("tap tile", tx, ty, "at", math.floor(px), math.floor(py))
		T.tap(px, py) T.wait(2000)
		T.log("dialog closed", tostring(not game:hasDialog(d)), "player", ox, oy, "->", p.x, p.y, (p.x == ox and p.y == oy) and "(no move: engine idle without input)" or "")
	else
		T.log("no walkable tile found nearby")
		T.key("EXIT")
	end
	T.shot("map-after")
	T.log("finished")
end
