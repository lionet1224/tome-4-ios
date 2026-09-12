-- Shoot as a routine step and on AUTO (an Archer): the arrow goes at the enemy in view.
-- sweep-env: AP_CLASS=Archer
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local p, map, tm = game.player, game.level.map, game.uiset.touch_manual
	if not p.actStep then T.log("no Act/AUTO addon") T.log("finished") return end
	T.log("class", tostring(p.descriptor and p.descriptor.subclass), "knows Shoot", tostring(p:knowTalent(p.T_SHOOT)))
	if not p:knowTalent(p.T_SHOOT) then T.log("finished") return end
	p.invulnerable = 1
	for _, e in pairs(game.level.entities) do if e.__is_actor and e ~= p and e.x and p:reactionToward(e) < 0 then map:remove(e.x, e.y, Map.ACTOR) game.level:removeEntity(e) end end
	local function free(x, y) return map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map:checkEntity(x, y, Map.TERRAIN, "block_sight") and not map(x, y, Map.ACTOR) end
	local placed = false
	for r = 0, 12 do for x = math.floor(map.w / 2) - r, math.floor(map.w / 2) + r do for y = math.floor(map.h / 2) - r, math.floor(map.h / 2) + r do
		if not placed and free(x, y) and free(x + 1, y) and free(x + 2, y) and free(x + 3, y) then p:move(x, y, true) placed = true end
	end end if placed then break end end
	map:centerViewAround(p.x, p.y) T.wait(300)
	local npc = game.zone:makeEntity(game.level, "actor", {type="vermin"}, nil, true)
	game.zone:addEntity(game.level, npc, "actor", p.x + 3, p.y) npc.faction = "enemies" npc.ai = "none" npc.never_move = 1 npc.invisible = nil npc.stealth = nil npc.max_life = 5000 npc.life = 5000
	p:playerFOV() tm:setTarget(nil) T.wait(500)
	local r = p:actRoutine()
	local saved = r.steps
	r.steps = {{kind="talent", tid=p.T_SHOOT, target="nearest", if_unusable="approach"}}
	p.act_preview_key = nil
	local pv = p:actPreview()
	T.log("preview", tostring(pv and pv.step and pv.step.tid), tostring(pv and pv.what), "target", tostring(pv and pv.target and pv.target.name))
	local life0, turn0, x0 = npc.life, game.turn, p.x
	p:actStep() T.wait(1200)
	T.log("after Act: enemy life", life0, "->", npc.life, "turn", turn0, "->", game.turn, "aiming", tostring(game.key ~= game.normal_key), "player x", x0, "->", p.x)
	if game.key ~= game.normal_key then T.log("BAD Act left an aim open") T.key("EXIT") T.wait(300) end
	if npc.life >= life0 then T.log("BAD the Shoot step did not hit the enemy") end
	-- and on AUTO for a few seconds
	life0 = npc.life
	p:autoActStart(true) T.wait(4000)
	local stopped = not p.auto_act
	if p.auto_act then p:autoActStop("test") end T.wait(300)
	local t = p:getTalentFromId(p.T_SHOOT)
	local ammo = p:getInven("QUIVER") and p:getInven("QUIVER")[1]
	T.log("after AUTO: enemy life", life0, "->", npc.life, "stopped on its own", tostring(stopped), "usable", tostring(p:preUseTalent(t, true, true)), "shots left", tostring(ammo and ammo.combat and ammo.combat.shots_left), "stamina", math.floor(p.stamina or 0), "/", math.floor(p.max_stamina or 0), "cd", tostring(p:isTalentCoolingDown(t)))
	if npc.life >= life0 then T.log("BAD AUTO did not shoot the enemy") end
	if stopped and (ammo and ammo.combat and (ammo.combat.shots_left or 0) > 0) then T.log("BAD AUTO stopped with shots left") end
	-- an empty pouch: Act waits a turn to reload instead of giving up, then shoots again; AUTO carries on
	local ammo = p:hasAmmo()
	if ammo then
		ammo.combat.shots_left = 0
		p.act_preview_key = nil
		local pv2 = p:actPreview()
		T.log("empty: preview", tostring(pv2 and pv2.what), "steps", tostring(pv2 and pv2.step and pv2.step.tid))
		if not (pv2 and pv2.what == "wait_for") then T.log("BAD the preview does not show a reload wait when out of ammo") end
		local turn1 = game.turn
		p:actStep() T.wait(800)
		T.log("empty: after Act shots left", tostring(ammo.combat.shots_left), "turn", turn1, "->", game.turn)
		if (ammo.combat.shots_left or 0) <= 0 then T.log("BAD Act did not reload when out of ammo") end
		ammo.combat.shots_left = 0
		life0 = npc.life
		p:autoActStart(true) T.wait(4000)
		local stopped2 = not p.auto_act
		if p.auto_act then p:autoActStop("test") end T.wait(300)
		T.log("empty: after AUTO enemy life", life0, "->", npc.life, "stopped on its own", tostring(stopped2), "shots left", tostring(ammo.combat.shots_left))
		if npc.life >= life0 then T.log("BAD AUTO did not reload and shoot from an empty pouch") end
	end
	r.steps = saved
	T.log("finished")
end
