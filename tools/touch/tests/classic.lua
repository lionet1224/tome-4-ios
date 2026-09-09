-- Classic controls (touch.classic=true, portrait): no Act, no AUTO, no routine strip; the
-- pills sit in the thumb corner; Cast / Cancel still appear while aiming; AUTO cannot start.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local p, map = game.player, game.level.map
	local m = game.uiset.touch_manual
	local r = m:layout()
	T.log("classic", tostring(r.classic), "attack rect", tostring(game.uiset.touch_attack_rect ~= nil), "auto rect", tostring(game.uiset.touch_auto_rect ~= nil))
	if not r.classic then T.log("BAD layout is not classic") T.log("finished") return end
	T.wait(800)
	if game.uiset.touch_attack_rect or game.uiset.touch_auto_rect then T.log("BAD Act / AUTO rects still present") end
	if game.mouse.areas_name and (game.mouse.areas_name.touch_attack or game.mouse.areas_name.touch_auto) then T.log("BAD Act / AUTO zones still registered") end
	-- (the band stays HUD in portrait: a tap there must never walk, Act or no Act)
	-- pills in the thumb corner
	if r.hand == "left" and r.ctx_lo.x ~= r.act.x then T.log("BAD pills not in the thumb corner", r.ctx_lo.x, r.act.x) end
	-- AUTO cannot start
	p:autoActStart(true) T.wait(300)
	T.log("auto after start", tostring(p.auto_act))
	if p.auto_act then T.log("BAD AUTO started in classic mode") p:autoActStop("test") end
	-- an enemy: the Wait pill still shows and the Pan pill is there
	local function free(x, y) return map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR) end
	for _, d in ipairs{{2, 0}, {-2, 0}, {0, 2}, {0, -2}} do
		if free(p.x + d[1], p.y + d[2]) then local a = game.zone:makeEntity(game.level, "actor", {type="vermin"}, nil, true) if a then game.zone:addEntity(game.level, a, "actor", p.x + d[1], p.y + d[2]) a.faction = "enemies" a.ai = "none" a.never_move = 1 a.invisible = nil a.stealth = nil break end end
	end
	p:playerFOV() T.waitFor(function() return game.uiset.touch_ctx_rects and game.uiset.touch_ctx_rects.wait end, 4000)
	local c = game.uiset.touch_ctx_rects or {}
	T.log("wait pill", tostring(c.wait ~= nil), "pan pill", tostring(c.pan ~= nil))
	if not c.wait then T.log("BAD no Wait pill with an enemy in view") end
	T.shot("classic")
	-- aiming: Cast / Cancel at the dock spots
	local tid for id in pairs(p.talents) do local t = p:getTalentFromId(id) if t and t.mode == "activated" and t.range and not id:find("^T_INFUSION") and not id:find("^T_RUNE") then tid = id break end end
	if tid then
		p:useTalent(tid) T.wait(400)
		T.log("aiming", tostring(game.key == game.targetmode_key), "cast zone", tostring(game.mouse.areas_name and game.mouse.areas_name.touch_cast ~= nil))
		if game.key == game.targetmode_key then
			if not (game.mouse.areas_name and game.mouse.areas_name.touch_cast) then T.log("BAD no Cast button while aiming") end
			T.key("EXIT") T.wait(300)
		end
	end
	T.log("finished")
end
