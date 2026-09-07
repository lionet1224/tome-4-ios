-- AUTO while a stop condition holds: a dialog asks; Continue overrides it until the fight is over
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local p, map = game.player, game.level.map
	local function free(x, y) return map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR) end
	local npc
	for _, d in ipairs{{3, 0}, {-3, 0}, {0, 3}, {0, -3}, {2, 2}, {-2, -2}} do
		if free(p.x + d[1], p.y + d[2]) then
			npc = game.zone:makeEntity(game.level, "actor", {type="vermin"}, nil, true)
			if npc then game.zone:addEntity(game.level, npc, "actor", p.x + d[1], p.y + d[2]) npc.faction = "enemies" npc.ai = "none" npc.invulnerable = 1 npc.never_move = 1 break end
		end
	end
	if not npc then T.log("no npc") T.log("finished") return end
	p:playerFOV() T.wait(400)
	if #p:actEnemies() == 0 then
		-- not in view (dark, wall): put it right next to us
		for _, d in ipairs{{1, 0}, {-1, 0}, {0, 1}, {0, -1}} do
			if free(p.x + d[1], p.y + d[2]) then npc:move(p.x + d[1], p.y + d[2], true) break end
		end
		p:playerFOV() T.wait(400)
	end
	p.life = math.floor(p.max_life * 0.4)
	T.log("enemies in view", #p:actEnemies(), "blocker:", tostring(p:autoActBlocker()))
	p:autoActStart() T.wait(600)
	local d = game.dialogs[#game.dialogs]
	T.log("dialog:", tostring(d and d.title), "auto_act", tostring(p.auto_act))
	if not (d and tostring(d.title) == _t"Auto") then T.log("BAD no confirmation dialog") T.log("finished") return end
	T.shot("auto-confirm")
	-- Continue (the popup's own button; ACCEPT is not bound on it)
	local pressed = false
	for _, u in ipairs(d.uis or {}) do if u.ui and u.ui.text == _t"Continue" and u.ui.fct then u.ui.fct() pressed = true break end end
	T.log("pressed Continue", tostring(pressed)) T.wait(800)
	T.log("after Continue: auto_act", tostring(p.auto_act), "override", tostring(p.auto_override), "dialogs", #game.dialogs)
	if not p.auto_act then T.log("BAD AUTO did not start after Continue") end
	if p.auto_override ~= "life" then T.log("BAD override not set") end
	T.wait(1500)
	T.log("1.5 s later: auto_act", tostring(p.auto_act), "override", tostring(p.auto_override))
	if not p.auto_act then T.log("BAD AUTO stopped despite the override") end
	-- the fight ends: the override lapses
	if not npc.dead and npc.x then map:remove(npc.x, npc.y, Map.ACTOR) game.level:removeEntity(npc) end p:playerFOV() T.wait(1500)
	T.log("no enemies: override", tostring(p.auto_override), "auto_act", tostring(p.auto_act))
	if p.auto_override then T.log("BAD override survived the end of the fight") end
	p:autoActStop("test")
	T.log("finished")
end
