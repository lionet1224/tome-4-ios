-- The context pills: Descend on the stairs, Wait with an enemy in view, Rest when hurt. Portrait.
return function(T)
	local L = dofile("/touch-demo-lib.lua")
	local Map = require "engine.Map"
	L.prelude(T)
	local p, map = game.player, game.level.map
	L.clearHostiles()
	-- stand on the stairs down
	local best, bd
	for x = 1, map.w do for y = 1, map.h do
		local g = map(x, y, Map.TERRAIN)
		if g and g.change_level and g.change_level > 0 and not g.change_zone then local d = core.fov.distance(p.x, p.y, x, y) if not bd or d < bd then best, bd = {x=x, y=y}, d end end
	end end
	if best then p:move(best.x, best.y, true) end
	p:playerFOV() map:centerViewAround(p.x, p.y) T.wait(3500)
	-- an enemy walks into view: Wait joins
	local a = L.spawn(3, 0, {ai="none", never_move=1, invulnerable=1}) or L.spawn(-3, 0, {ai="none", never_move=1, invulnerable=1}) or L.spawn(0, 3, {ai="none", never_move=1, invulnerable=1})
	p:playerFOV() T.wait(3500)
	local c = game.uiset.touch_ctx_rects or {}
	if c.wait then T.tap(c.wait.x + c.wait.w / 2, c.wait.y + c.wait.h / 2) T.wait(1500) end
	-- alone and hurt: Rest
	if a then map:remove(a.x, a.y, Map.ACTOR) game.level:removeEntity(a) end
	p.life = math.floor(p.max_life * 0.4) p:playerFOV() T.wait(3000)
	c = game.uiset.touch_ctx_rects or {}
	if c.wait and c.wait_label == _t"Rest" then T.tap(c.wait.x + c.wait.w / 2, c.wait.y + c.wait.h / 2) end
	T.waitFor(function() return p.resting end, 3000)
	T.waitFor(function() return not p.resting end, 30000)
	T.wait(1500)
	T.log("finished")
end
