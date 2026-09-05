return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p, map = game.player, game.level.map
	local Map = require "engine.Map"
	local function blocked(x, y) return not map:isBound(x, y) or map:checkEntity(x, y, Map.TERRAIN, "block_move") end
	local function freeDir() if not blocked(p.x + 1, p.y) then return 6, 1, 0 elseif not blocked(p.x - 1, p.y) then return 4, -1, 0 elseif not blocked(p.x, p.y + 1) then return 2, 0, 1 else return 8, 0, -1 end end
	T.log("start", p.x, p.y, "energy", p.energy.value, "turn", game.turn, "paused", tostring(game.paused))
	-- 1. swipe first, with full energy
	local dir, dx, dy = freeDir()
	local sx, sy = map:getTileToScreen(p.x, p.y)
	local cx, cy = sx + map.tile_w / 2, sy + map.tile_h / 2
	local ox, oy = p.x, p.y
	T.swipe(cx, cy, cx + dx * 90, cy + dy * 90, 60) T.wait(800)
	T.log("swipe", dir, ox, oy, "->", p.x, p.y, "energy", p.energy.value, "turn", game.turn)
	-- 2. direct move next
	dir, dx, dy = freeDir() ox, oy = p.x, p.y
	p:moveDir(dir) T.wait(800)
	T.log("direct", dir, ox, oy, "->", p.x, p.y, "energy", p.energy.value, "turn", game.turn)
	-- 3. swipe again
	dir, dx, dy = freeDir() ox, oy = p.x, p.y
	sx, sy = map:getTileToScreen(p.x, p.y) cx, cy = sx + map.tile_w / 2, sy + map.tile_h / 2
	T.swipe(cx, cy, cx + dx * 90, cy + dy * 90, 60) T.wait(800)
	T.log("swipe2", dir, ox, oy, "->", p.x, p.y, "energy", p.energy.value, "turn", game.turn)
	T.log("finished")
end
