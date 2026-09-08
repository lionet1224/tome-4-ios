-- A spot-aimed talent (the Blink rune) opens the aiming cursor even with an enemy selected,
-- and a routine step refuses it unless its target is "aim by hand".
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local Actor = require "mod.class.Actor"
	local p, map = game.player, game.level.map
	local m = game.uiset.touch_manual
	-- inscribe a real Blink rune (the same data the Ogre birth gives) and find its talent
	p:setInscription(nil, "RUNE:_BLINK", {cooldown=16, range=3, dur=3, power=15}, false, false, nil, true, true)
	local tid
	for id in pairs(p.talents) do if tostring(id):find("^T_RUNE:_BLINK") then tid = id break end end
	T.log("talent", tostring(tid))
	if not tid then T.log("BAD test setup: no blink rune talent after inscribing") T.log("finished") return end
	local t = p:getTalentFromId(tid)
	local okt, tg = pcall(t.target, p, t)
	T.log("nolock", tostring(okt and type(tg) == "table" and tg.nolock))
	local function free(x, y) return map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR) end
	local npc
	for _, d in ipairs{{3, 0}, {-3, 0}, {0, 3}, {0, -3}, {2, 2}} do
		if free(p.x + d[1], p.y + d[2]) then
			npc = game.zone:makeEntity(game.level, "actor", {type="vermin"}, nil, true)
			if npc then game.zone:addEntity(game.level, npc, "actor", p.x + d[1], p.y + d[2]) npc.faction = "enemies" npc.ai = "none" npc.never_move = 1 npc.invulnerable = 1 break end
		end
	end
	if not npc then T.log("no npc") T.log("finished") return end
	p:playerFOV() T.wait(300)
	m:setTarget(npc) T.wait(200)
	local x0, y0 = p.x, p.y
	local ok, res = pcall(m.cast, m, tid, npc, true)
	T.wait(500)
	local aiming = game.key == game.targetmode_key
	T.log("manual cast: aiming", tostring(aiming), "moved", tostring(p.x ~= x0 or p.y ~= y0), "res", tostring(res))
	if not aiming then T.log("BAD the blink rune did not open the aim cursor") end
	if p.x ~= x0 or p.y ~= y0 then T.log("BAD the blink rune fired at the selected enemy") end
	if aiming then T.key("EXIT") T.wait(300) end
	p.talents_cd = {}
	local ok2, why = p:actDo({kind="talent", tid=tid, target="nearest", if_unusable="skip"})
	T.log("routine step at nearest:", tostring(ok2), tostring(why))
	if ok2 then T.log("BAD a routine step blinked at the nearest enemy") end
	T.log("finished")
end
