-- Disengage from the strip the way it is played (portrait): tap the card with no hand-picked
-- target, aim the enemy, Cast, then the escape square opens, Cast again, and you end up further away.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local p, map, tm = game.player, game.level.map, game.uiset.touch_manual
	p.invulnerable = 1
	for _, e in pairs(game.level.entities) do if e.__is_actor and e ~= p and e.x and p:reactionToward(e) < 0 then map:remove(e.x, e.y, Map.ACTOR) game.level:removeEntity(e) end end
	local function free(x, y) return map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map:checkEntity(x, y, Map.TERRAIN, "block_sight") and not map(x, y, Map.ACTOR) end
	local placed = false
	for r = 0, 12 do for x = math.floor(map.w / 2) - r, math.floor(map.w / 2) + r do for y = math.floor(map.h / 2) - r, math.floor(map.h / 2) + r do
		if not placed and free(x, y) and free(x - 1, y) and free(x - 2, y) and free(x - 3, y) and free(x + 1, y) then p:move(x, y, true) placed = true end
	end end if placed then break end end
	map:centerViewAround(p.x, p.y) T.wait(300)
	p:learnTalent(p.T_DISENGAGE, true, 1)
	-- on the hotbar so the strip shows it
	p.hotkey[1] = {"talent", p.T_DISENGAGE} p.changed = true
	local npc = game.zone:makeEntity(game.level, "actor", {type="vermin"}, nil, true)
	game.zone:addEntity(game.level, npc, "actor", p.x + 1, p.y) npc.faction = "enemies" npc.ai = "none" npc.never_move = 1 npc.invisible = nil npc.stealth = nil
	p:playerFOV() tm:setTarget(nil) tm.band_dirty = true T.wait(700)
	local function card() for _, c in pairs(tm.strip_rects or {}) do if c.tid == p.T_DISENGAGE then return c end end end
	local c = card()
	if not c then T.log("no Disengage card on the strip") T.log("finished") return end
	local x0 = p.x
	local function tile(x, y) local sx, sy = map:getTileToScreen(x, y) local tw, th = map.tile_w * (map.zoom or 1), map.tile_h * (map.zoom or 1) return sx + tw / 2, sy + th / 2 end
	local function cast_pill() local lr = tm:layout() return lr.act.x + lr.act.w / 2, lr.act.y + lr.act.h / 2 end
	-- 1. tap the card: the enemy aim opens
	T.tap(c.x + c.w / 2, c.y + c.h / 2) T.wait(600)
	T.log("after card: aiming", tostring(game.key ~= game.normal_key), "cursor", tostring(game.target and game.target.target and game.target.target.x), tostring(game.target and game.target.target and game.target.target.y), "enemy", npc.x, npc.y)
	if game.key == game.normal_key then T.log("BAD the card tap did not open the aim") T.log("finished") return end
	-- 2. tap the enemy, then Cast
	local ex, ey = tile(npc.x, npc.y)
	T.tap(ex, ey) T.wait(400)
	T.log("after enemy tap: cursor", tostring(game.target.target.x), tostring(game.target.target.y), "aiming", tostring(game.key ~= game.normal_key))
	local cx, cy = cast_pill()
	T.tap(cx, cy) T.wait(700)
	T.log("after first Cast: aiming", tostring(game.key ~= game.normal_key), "cursor", tostring(game.target and game.target.target and game.target.target.x), tostring(game.target and game.target.target and game.target.target.y), "player", p.x, p.y)
	if game.key == game.normal_key then
		T.log(p.x == x0 and "BAD the escape aim never opened and nothing happened" or "escape happened without a second aim")
	else
		-- 3. Cast again on the pre-placed escape square
		T.tap(cx, cy) T.wait(800)
		T.log("after second Cast: aiming", tostring(game.key ~= game.normal_key), "player x", x0, "->", p.x)
		if p.x >= x0 then T.log("BAD did not end up further from the enemy") end
	end
	T.shot("disengage-strip")
	if game.key ~= game.normal_key then T.key("EXIT") end
	T.log("finished")
end
