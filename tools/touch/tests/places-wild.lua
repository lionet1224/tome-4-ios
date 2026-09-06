-- world map: Places lists every zone entrance from the start and travels to an unseen one
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p = game.player
	-- outside the script coroutine: changeLevel ticks the game
	game:onTickEnd(function() game:changeLevel(1, p.last_wilderness or "wilderness") end)
	T.waitFor(function() return game.zone and game.zone.wilderness and game.level and game.level.map end, 60000)
	T.wait(1500)
	local map = game.level.map
	local d = require("mod.dialogs.TouchPlaces").new()
	game:registerDialog(d) T.wait(800)
	T.shot("places-wild")
	local secs = d.c_flow.sections
	local parts, unseen, total = {}, 0, 0
	for i, sec in ipairs(secs) do
		parts[#parts+1] = ("%s=%d"):format(tostring(sec.title), #sec.items)
		for _, it in ipairs(sec.items) do total = total + 1 if it.sub and it.sub:find("not yet visited") then unseen = unseen + 1 end end
	end
	T.log("sections", #secs, table.concat(parts, " | "), "entries", total, "unseen", unseen)
	if total < 5 then T.log("BAD expected the world map's entrances listed from the start") end
	-- travel to the nearest unseen entrance that has a real overland route
	local Astar = require "engine.Astar"
	local cands = {}
	for _, sec in ipairs(secs) do for _, it in ipairs(sec.items) do if it.data and it.data.unseen then cands[#cands+1] = it end end end
	table.sort(cands, function(a, b) return a.data.d < b.data.d end)
	local far
	for _, it in ipairs(cands) do
		if Astar.new(map, p):calc(p.x, p.y, it.data.x, it.data.y, false) then far = it break end
	end
	if not far then T.log("no reachable unseen entrance") T.log("finished") return end
	local ox, oy = p.x, p.y
	T.log("destination card", tostring(far.name), tostring(far.sub))
	local Map = require "engine.Map"
	local orig = p.runStop
	p.runStop = function(self, msg, ...)
		local r = self.running
		local path, cnt = r and r.path, r and r.cnt
		local nx = path and cnt and path[cnt]
		if nx then
			local g = map(nx.x, nx.y, Map.TERRAIN)
			local a = map(nx.x, nx.y, Map.ACTOR)
			T.log(("runStop: %s at %d,%d; next %d,%d (cnt %d of %d) terrain=%s block=%s actor=%s"):format(tostring(msg), self.x, self.y, nx.x, nx.y, cnt, #path, g and tostring(g.name) or "nil", tostring(map:checkAllEntities(nx.x, nx.y, "block_move", self)), a and tostring(a.name) or "none"))
		else T.log("runStop:", tostring(msg), "at", self.x, self.y, "no path") end
		return orig(self, msg, ...)
	end
	d:go(far.data)
	if p.running and p.running.path then
		local parts = {}
		for i = 1, math.min(8, #p.running.path) do parts[#parts+1] = p.running.path[i].x..","..p.running.path[i].y end
		T.log("path", #p.running.path, "tiles:", table.concat(parts, " "), "touch_dest", tostring(p.running.touch_dest))
	else T.log("no run after go; running=", tostring(p.running)) end
	local dest = far.data
	T.waitFor(function() return not p.running end, 60000)
	T.log(("trip ended: player %d,%d dest %d,%d dist %d running=%s"):format(p.x, p.y, dest.x, dest.y, core.fov.distance(p.x, p.y, dest.x, dest.y), tostring(p.running ~= nil)))
	if core.fov.distance(p.x, p.y, dest.x, dest.y) > 1 then T.log("BAD trip did not arrive") end
	T.log("after go: dialog open", tostring(game:hasDialog(d)), "player", ox, oy, "->", p.x, p.y, "running", tostring(p.running ~= nil))
	if p.x == ox and p.y == oy then T.log("BAD did not start travelling") end
	T.log("finished")
end
