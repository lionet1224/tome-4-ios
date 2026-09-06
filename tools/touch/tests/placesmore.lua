-- More -> Places -> go on the world map: the trip must not stop for a lingering More popup
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p = game.player
	game:onTickEnd(function() game:changeLevel(1, p.last_wilderness or "wilderness") end)
	T.waitFor(function() return game.zone and game.zone.wilderness and game.level and game.level.map end, 60000)
	T.wait(1500)
	local map = game.level.map
	game.uiset.touch_manual:openMore() T.wait(500)
	local more = game.dialogs[#game.dialogs]
	T.log("More open:", tostring(more and more.title), "dialogs", #game.dialogs)
	-- pick Places the way the popup does: the item's own fct
	local item
	for _, u in ipairs(more.uis or {}) do
		local l = u.ui and u.ui.list
		if type(l) == "table" then for _, it in ipairs(l) do if it.name == _t"Places" then item = it end end end
	end
	if not item then T.log("no Places item in More") T.log("finished") return end
	item.fct() T.wait(800)
	local d = game.dialogs[#game.dialogs]
	T.log("after Places: top", tostring(d and d.__CLASSNAME), "dialogs", #game.dialogs)
	if #game.dialogs ~= 1 then T.log("BAD More still open under Places") end
	local Astar = require "engine.Astar"
	local dest
	for _, sec in ipairs(d.c_flow.sections) do for _, it in ipairs(sec.items) do
		if not dest and it.data and it.data.unseen and Astar.new(map, p):calc(p.x, p.y, it.data.x, it.data.y, false) then dest = it.data end
	end end
	if not dest then T.log("no reachable destination") T.log("finished") return end
	local stops = {}
	local orig = p.runStop
	p.runStop = function(self, msg, ...) stops[#stops+1] = tostring(msg) return orig(self, msg, ...) end
	local ox, oy = p.x, p.y
	d:go(dest)
	T.waitFor(function() return not p.running end, 60000)
	T.log(("trip: %d,%d -> %d,%d dest %d,%d stops: %s dialogs %d"):format(ox, oy, p.x, p.y, dest.x, dest.y, table.concat(stops, " | "), #game.dialogs))
	for _, m in ipairs(stops) do if m:find("dialog") then T.log("BAD run stopped for a dialog") end end
	if core.fov.distance(p.x, p.y, dest.x, dest.y) > 1 then T.log("BAD trip did not arrive") end
	T.log("finished")
end
