-- AUTO: a few enemies, one tap, the routine fights and the pills change. Portrait.
return function(T)
	local L = dofile("/touch-demo-lib.lua")
	L.prelude(T)
	local p, map = game.player, game.level.map
	L.clearHostiles()
	p.max_life = 400 p.life = 400
	for _, d in ipairs{{5, 1}, {6, -1}, {6, 2}, {-5, 0}} do if L.free(p.x + d[1], p.y + d[2]) then L.spawn(d[1], d[2], {max_life=45, life=45}) end end
	p:playerFOV() map:centerViewAround(p.x, p.y) T.wait(2000)
	local r = game.uiset.touch_auto_rect
	if r then T.tap(r.x + r.w / 2, r.y + r.h / 2) end
	T.wait(16000)
	if p.auto_act then r = game.uiset.touch_auto_rect if r then T.tap(r.x + r.w / 2, r.y + r.h / 2) end end
	T.wait(1500)
	T.log("finished")
end
