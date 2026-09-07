-- no enemies: a Rest pill shows when there is something to recover, and rests on tap
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local p, map = game.player, game.level.map
	for _, e in pairs(game.level.entities) do
		if e.__is_actor and e ~= p and e.x and p:reactionToward(e) < 0 then map:remove(e.x, e.y, Map.ACTOR) game.level:removeEntity(e) end
	end
	p:playerFOV() T.wait(500)
	local function rects() return game.uiset.touch_ctx_rects or {} end
	T.log("full: wait pill", tostring(rects().wait ~= nil), tostring(rects().wait_label), "enemies", #p:actEnemies(), "needRest", tostring(game.uiset.touch_manual:needRest()))
	if rects().wait and rects().wait_label == _t"Rest" then T.log("note: Rest shown at full (a cooldown or resource not full)") end
	p.life = math.floor(p.max_life * 0.6) T.wait(500)
	T.log("hurt: pill", tostring(rects().wait_label))
	if rects().wait_label ~= _t"Rest" then T.log("BAD no Rest pill when hurt with no enemies") T.log("finished") return end
	local r = rects().wait
	T.tap(r.x + r.w / 2, r.y + r.h / 2)
	T.waitFor(function() return p.resting end, 5000)
	T.log("after tap: resting", tostring(p.resting ~= nil))
	if not p.resting then T.log("BAD Rest tap did not start resting") end
	T.waitFor(function() return not p.resting end, 60000)
	T.log("rested to", p.life, "/", p.max_life, "pill now", tostring(rects().wait_label))
	T.log("finished")
end
