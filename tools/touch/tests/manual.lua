-- manual play: target strip, tap-to-path gating, drag-to-step, More, favourites
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local p = game.player
	local map = game.level.map
	local function tileCenter(x, y) local sx, sy = map:getTileToScreen(x, y) local tw, th = map.tile_w * (map.zoom or 1), map.tile_h * (map.zoom or 1) return sx + tw / 2, sy + th / 2 end
	-- a hostile three tiles away on a free tile
	local npc
	for _, d in ipairs{{3, 0}, {-3, 0}, {0, 3}, {0, -3}, {3, 3}, {-3, -3}, {2, 2}, {-2, 2}} do
		local x, y = p.x + d[1], p.y + d[2]
		if map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR) then
			npc = game.zone:makeEntity(game.level, "actor", {type="vermin"}, nil, true)
			if npc then game.zone:addEntity(game.level, npc, "actor", x, y) npc.faction = "enemies" T.log("spawned", npc.name, "at", x, y) break end
		end
	end
	if not npc then T.log("no hostile spawned") T.log("finished") return end
	T.key("MOVE_STAY") T.wait(600)
	T.shot("manual-idle")
	T.log("enemies in view", #p:actEnemies(), "skills button", tostring(game.uiset.touch_skills_rect ~= nil), "more", tostring(game.uiset.touch_more_rect ~= nil), "drawer", tostring(game.uiset.touch_drawer_open))
	-- tap the enemy: target + strip
	local ex, ey = tileCenter(npc.x, npc.y)
	T.tap(ex, ey) T.wait(500)
	local n = 0 for _ in pairs(game.uiset.touch_strip_rects or {}) do n = n + 1 end
	T.log("target", tostring(p.touch_target and p.touch_target.name), "strip cards", n, "drawer", tostring(game.uiset.touch_drawer_open))
	T.shot("manual-target")
	-- cast the first ready card
	local first
	for i = 1, 40 do if game.uiset.touch_strip_rects and game.uiset.touch_strip_rects[i] then first = game.uiset.touch_strip_rects[i] break end end
	if first then
		local turn = game.turn
		T.tap(first.x + first.w / 2, first.y + first.h / 2) T.wait(600)
		T.log("cast card", tostring(first.tid), "turn", turn, "->", game.turn, "key", game.key == game.normal_key and "normal" or "targeting")
		if game.key ~= game.normal_key then T.key("EXIT") T.wait(300) end
	else T.log("no strip card") end
	T.shot("manual-cast")
	-- close the drawer with X: target cleared, drawer closed
	local cr = game.uiset.touch_strip_rect
	if cr then
		T.tap(cr.x + cr.w - 32, cr.y + cr.h / 2) T.wait(400)
		T.log("after X: drawer open", tostring(game.uiset.touch_drawer_open), "target", tostring(p.touch_target and p.touch_target.name))
	end
	-- the Skills button reopens it with no target
	local sk = game.uiset.touch_skills_rect
	if sk then
		T.tap(sk.x + sk.w / 2, sk.y + sk.h / 2) T.wait(500)
		T.log("after Skills: drawer open", tostring(game.uiset.touch_drawer_open), "target", tostring(p.touch_target and p.touch_target.name))
		T.shot("manual-drawer")
		local card
		for i = 1, 40 do if game.uiset.touch_strip_rects and game.uiset.touch_strip_rects[i] then card = game.uiset.touch_strip_rects[i] break end end
		if card then
			local turn = game.turn
			T.tap(card.x + card.w / 2, card.y + card.h / 2) T.wait(600)
			T.log("no-target card", tostring(card.tid), "turn", turn, "->", game.turn, "key", game.key == game.normal_key and "normal (cast at nearest)" or "targeting (manual aim)")
			if game.key ~= game.normal_key then T.key("EXIT") T.wait(300) end
		end
	end
	-- a floor tap far away must not move while an enemy is in view
	local ox, oy = p.x, p.y
	local fx, fy = p.x - 3, p.y
	if not map:isBound(fx, fy) then fx = p.x + 1 fy = p.y + 3 end
	local sx, sy = tileCenter(fx, fy)
	T.tap(sx, sy) T.wait(800)
	T.log("floor tap moved", tostring(p.x ~= ox or p.y ~= oy), "target after", tostring(p.touch_target and p.touch_target.name), "drawer still open", tostring(game.uiset.touch_drawer_open))
	-- drag to step: one tile right (or left when blocked)
	local px, py = tileCenter(p.x, p.y)
	local dir = 1
	if map:checkEntity(p.x + 1, p.y, Map.TERRAIN, "block_move") or map(p.x + 1, p.y, Map.ACTOR) then dir = -1 end
	ox, oy = p.x, p.y
	T.log("energy before drag", tostring(p.energy and p.energy.value))
	T.swipe(px, py, px + dir * 90, py, 350)
	T.wait(1200)
	T.log("drag step", ox, oy, "->", p.x, p.y, "expected dx", dir)
	T.shot("manual-step")
	-- More sheet
	local mr = game.uiset.touch_more_rect
	if mr then T.tap(mr.x + mr.w / 2, mr.y + mr.h / 2) T.wait(500) T.log("more open", tostring(game.dialogs[#game.dialogs] and game.dialogs[#game.dialogs].title)) T.shot("manual-more") T.key("EXIT") T.wait(300) end
	T.log("finished")
end
