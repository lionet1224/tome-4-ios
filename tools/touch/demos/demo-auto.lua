-- AUTO: a few enemies, one tap, the routine fights and the pills change. Portrait.
return function(T)
	local L = dofile("/touch-demo-lib.lua")
	L.prelude(T)
	local p, map = game.player, game.level.map
	L.clearHostiles()
	-- no lore notes on the floor: an exploring AUTO stops to read them
	do for _, e in pairs(game.level.entities) do if e.__is_object and e.x and e.lore then map:removeObject(e.x, e.y, e) end end end
	p.max_life = 400 p.life = 400
	-- close enough that the fight starts at once (an exploring AUTO once found a lore note and stopped to read it)
	for _, d in ipairs{{3, 0}, {4, 1}, {3, -2}, {-3, 1}, {-4, -1}, {2, 3}} do if L.free(p.x + d[1], p.y + d[2]) then L.spawn(d[1], d[2], {max_life=40, life=40}) end end
	p.max_life = 600 p.life = 600
	p:playerFOV() map:centerViewAround(p.x, p.y) T.wait(2000)
	local r = game.uiset.touch_auto_rect
	if r then T.tap(r.x + r.w / 2, r.y + r.h / 2) end
	local t0 = core.game.getTime()
	while core.game.getTime() - t0 < 14000 and p.auto_act and #p:actEnemies() > 0 do T.wait(300) end
	T.wait(800)
	if p.auto_act then r = game.uiset.touch_auto_rect if r then T.tap(r.x + r.w / 2, r.y + r.h / 2) end end
	T.wait(1500)
	T.log("finished")
end
