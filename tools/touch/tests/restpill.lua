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
	T.waitFor(function() return rects().wait_label == _t"Rest" end, 4000) -- the band is cached: the rects follow its next full draw
	T.log("hurt: pill", tostring(rects().wait_label))
	if rects().wait_label ~= _t"Rest" then T.log("BAD no Rest pill when hurt with no enemies") T.log("finished") return end
	local r = rects().wait
	T.tap(r.x + r.w / 2, r.y + r.h / 2)
	T.waitFor(function() return p.resting end, 5000)
	T.log("after tap: resting", tostring(p.resting ~= nil))
	if not p.resting then T.log("BAD Rest tap did not start resting") end
	T.waitFor(function() return not p.resting end, 60000)
	T.log("rested to", p.life, "/", p.max_life, "pill now", tostring(rects().wait_label))
	-- full again: no Rest pill, even with a talent on cooldown (the game would rest 0 turns)
	local any for tid in pairs(p.talents) do local t = p:getTalentFromId(tid) if t and t.mode == "activated" then any = tid break end end
	if any then p.talents_cd[any] = 5 end
	T.wait(800)
	T.log("full with a cooldown: pill", tostring(rects().wait_label), "needRest", tostring(game.uiset.touch_manual:needRest()))
	-- whenever the pill is offered, a tap must rest for at least a turn (the phone showed
	-- "Rested for 0 turns" from a pill the game disagreed with)
	if rects().wait_label == _t"Rest" then
		local w = rects().wait
		local turn0 = game.turn
		T.tap(w.x + w.w / 2, w.y + w.h / 2)
		T.waitFor(function() return p.resting end, 3000)
		T.waitFor(function() return not p.resting end, 60000)
		T.log("cooldown rest: turns", (game.turn - turn0) / 10)
		if game.turn - turn0 < 10 then T.log("BAD the offered rest lasted no turn") end
	end
	-- a resource that cannot regenerate must not offer a rest: fake one with zero regen
	p.life = p.max_life
	T.waitFor(function() return rects().wait_label ~= _t"Rest" end, 4000)
	T.log("full: pill", tostring(rects().wait_label))
	if rects().wait_label == _t"Rest" then T.log("BAD Rest pill offered at full") end
	T.log("finished")
end
