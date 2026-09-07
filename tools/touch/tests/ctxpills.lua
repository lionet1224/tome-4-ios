-- context pills beside AUTO: Descend on the stairs, Wait while enemies are in view; both stack
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local p, map = game.player, game.level.map
	local m = game.uiset.touch_manual
	local function ctx() return game.uiset.touch_ctx_rects or {} end
	local function inside(q) return q.x >= 0 and q.y >= 0 and q.x + q.w <= game.w and q.y + q.h <= game.h end
	local function overlap(a, b) return a and b and a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h end
	local function free(x, y) return map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR) end
	-- no hostiles
	for _, e in pairs(game.level.entities) do
		if e.__is_actor and e ~= p and e.x and p:reactionToward(e) < 0 then map:remove(e.x, e.y, Map.ACTOR) game.level:removeEntity(e) end
	end
	p:playerFOV() T.wait(500)
	-- we may have spawned on the entrance stairs: step onto a plain tile first
	do
		local function plain(x, y) local g = map(x, y, Map.TERRAIN) return map:isBound(x, y) and g and not g.block_move and not g.change_level and not g.change_zone and not map(x, y, Map.ACTOR) end
		local moved = false
		for r = 1, 4 do for dx = -r, r do for dy = -r, r do
			if not moved and plain(p.x + dx, p.y + dy) then p:move(p.x + dx, p.y + dy, true) moved = true end
		end end if moved then break end end
		m:layout() T.wait(400)
		local g = map(p.x, p.y, Map.TERRAIN)
		T.log("after step-off: at", p.x, p.y, "tile", tostring(g and g.name), "change_level", tostring(g and g.change_level), "change_zone", tostring(g and g.change_zone), "rects", tostring(game.uiset.touch_ctx_rects and game.uiset.touch_ctx_rects.exit_label))
	end
	T.log("idle: exit", tostring(ctx().exit ~= nil), "wait", tostring(ctx().wait ~= nil), "enemies", #p:actEnemies())
	do
		local g0 = map(p.x, p.y, Map.TERRAIN)
		local on_exit = g0 and (g0.change_level or g0.change_zone)
		if not on_exit and (game.uiset.touch_ctx_rects.exit or game.uiset.touch_ctx_rects.wait) then T.log("BAD pills shown with nothing to do") end
		if on_exit and not game.uiset.touch_ctx_rects.exit then T.log("BAD standing on an exit without the pill") end
	end
	-- onto the nearest down stairs
	local best, bd
	for x = 0, map.w - 1 do for y = 0, map.h - 1 do
		local g = map(x, y, Map.TERRAIN)
		if g and g.change_level and g.change_level > 0 and not g.change_zone then
			local d = core.fov.distance(p.x, p.y, x, y)
			if not bd or d < bd then best, bd = {x=x, y=y}, d end
		end
	end end
	if not best then T.log("no stairs down") T.log("finished") return end
	p:move(best.x, best.y, true) p:playerFOV() map:centerViewAround(p.x, p.y) T.wait(600)
	local ex = ctx().exit
	T.log("on stairs: exit pill", tostring(ex ~= nil), "label", tostring(ctx().exit_label), ex and ("%d,%d %dx%d"):format(ex.x, ex.y, ex.w, ex.h) or "")
	if not ex then T.log("BAD no exit pill on the stairs") T.log("finished") return end
	if ctx().exit_label ~= _t"Descend" then T.log("BAD label is not Descend") end
	if not inside(ex) then T.log("BAD exit pill off screen") end
	local r = m.rects
	for _, k in ipairs{"act", "auto", "skills", "more"} do if overlap(ex, r[k]) then T.log("BAD exit pill overlaps "..k) end end
	if m:stripShown() and overlap(ex, r.strip) then T.log("BAD exit pill overlaps the strip") end
	if m:levelUpPending() and overlap(ex, r.levelup) then T.log("BAD exit pill overlaps Level up") end
	-- a hostile in view: the Wait pill joins, stacked above/below without overlap
	local npc
	for _, d in ipairs{{2, 0}, {-2, 0}, {0, 2}, {0, -2}, {1, 1}, {-1, -1}} do
		if free(p.x + d[1], p.y + d[2]) then
			npc = game.zone:makeEntity(game.level, "actor", {type="vermin"}, nil, true)
			if npc then game.zone:addEntity(game.level, npc, "actor", p.x + d[1], p.y + d[2]) npc.faction = "enemies" npc.ai = "none" npc.invulnerable = 1 npc.never_move = 1 npc.invisible = nil npc.stealth = nil break end
		end
	end
	if npc then
		p:playerFOV() T.wait(600)
		local wt = ctx().wait
		ex = ctx().exit
		T.log("with enemy: exit", tostring(ex ~= nil), "wait", tostring(wt ~= nil), wt and ("%d,%d"):format(wt.x, wt.y) or "", "enemies", #p:actEnemies())
		if not wt then T.log("BAD no Wait pill with an enemy in view") end
		if not ex then T.log("BAD exit pill gone with an enemy in view") end
		if wt and ex and overlap(wt, ex) then T.log("BAD the two pills overlap") end
		if wt and not inside(wt) then T.log("BAD Wait pill off screen") end
		T.shot("ctxpills")
		if wt then
			local turn = game.turn
			T.tap(wt.x + wt.w / 2, wt.y + wt.h / 2) T.wait(800)
			T.log("Wait tap: turn", turn, "->", game.turn)
			if game.turn == turn then T.log("BAD Wait did not pass a turn") end
		end
	else
		T.log("could not spawn a hostile; skipping the Wait checks")
		T.shot("ctxpills")
	end
	-- Descend
	local lvl0, zone0 = game.level.level, game.zone.short_name
	ex = ctx().exit
	if ex then
		T.tap(ex.x + ex.w / 2, ex.y + ex.h / 2)
		T.waitFor(function() return game.level.level ~= lvl0 or game.zone.short_name ~= zone0 end, 30000)
		T.log("Descend tap: level", zone0, lvl0, "->", game.zone.short_name, game.level.level)
		if game.level.level == lvl0 and game.zone.short_name == zone0 then T.log("BAD Descend did not change level") end
	end
	T.log("finished")
end
