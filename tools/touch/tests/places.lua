return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p, map = game.player, game.level.map
	-- know the whole level so the exits show up
	for x = 0, map.w - 1 do for y = 0, map.h - 1 do map.remembers(x, y, true) end end
	local d = require("mod.dialogs.TouchPlaces").new()
	game:registerDialog(d) T.wait(800)
	T.shot("places-open")
	local secs = d.c_flow.sections
	local parts = {}
	for i, sec in ipairs(secs) do parts[#parts+1] = ("%s=%d"):format(tostring(sec.title), #sec.items) end
	T.log("sections", #secs, table.concat(parts, " | "))
	local it = secs[1] and secs[1].items[1]
	if not it then T.log("no cards") T.log("finished") return end
	local ox, oy = p.x, p.y
	T.log("first card", tostring(it.name), tostring(it.sub))
	T.tap(d.c_flow.last_screen_x + it.x + it.w / 2, d.c_flow.last_screen_y + it.y + it.h / 2 - d.c_flow.scrollbar.pos)
	T.wait(1500)
	T.log("after tap: dialog open", tostring(game:hasDialog(d)), "player", ox, oy, "->", p.x, p.y, "running", tostring(p.running ~= nil))
	T.log("finished")
end
