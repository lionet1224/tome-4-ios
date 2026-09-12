-- Disengage as a routine step (the talent aims twice): Act moves you away from the adjacent enemy
-- and leaves no aim open; Disengage out of a straight line is skipped, not stuck.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local p, map, tm = game.player, game.level.map, game.uiset.touch_manual
	if not p.actStep then T.log("no Act/AUTO addon") T.log("finished") return end
	p.invulnerable = 1
	for _, e in pairs(game.level.entities) do if e.__is_actor and e ~= p and e.x and p:reactionToward(e) < 0 then map:remove(e.x, e.y, Map.ACTOR) game.level:removeEntity(e) end end
	local function free(x, y) return map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map:checkEntity(x, y, Map.TERRAIN, "block_sight") and not map(x, y, Map.ACTOR) end
	local placed = false
	for r = 0, 12 do for x = math.floor(map.w / 2) - r, math.floor(map.w / 2) + r do for y = math.floor(map.h / 2) - r, math.floor(map.h / 2) + r do
		if not placed and free(x, y) and free(x - 1, y) and free(x - 2, y) and free(x - 3, y) and free(x + 1, y) then p:move(x, y, true) placed = true end
	end end if placed then break end end
	map:centerViewAround(p.x, p.y) T.wait(300)
	p:learnTalent(p.T_DISENGAGE, true, 1)
	local npc = game.zone:makeEntity(game.level, "actor", {type="vermin"}, nil, true)
	game.zone:addEntity(game.level, npc, "actor", p.x + 1, p.y) npc.faction = "enemies" npc.ai = "none" npc.never_move = 1 npc.invisible = nil npc.stealth = nil npc.max_life = 1000 npc.life = 1000
	p:playerFOV() tm:setTarget(nil) T.wait(500)
	local r = p:actRoutine()
	local saved = r.steps
	r.steps = {{kind="talent", tid=p.T_DISENGAGE, target="nearest", if_unusable="skip"}}
	local pv = (function() p.act_preview_key = nil return p:actPreview() end)()
	T.log("preview", tostring(pv and pv.step and pv.step.tid), tostring(pv and pv.what))
	local x0 = p.x
	p:actStep() T.wait(900)
	T.log("after Act: aiming", tostring(game.key ~= game.normal_key), "player x", x0, "->", p.x, "cooling", tostring(p:isTalentCoolingDown(p:getTalentFromId(p.T_DISENGAGE))))
	if game.key ~= game.normal_key then T.log("BAD Act left an aim open") T.key("EXIT") T.wait(300) end
	if p.x >= x0 then T.log("BAD Act's Disengage did not move away from the enemy") end
	r.steps = saved
	T.log("finished")
end
