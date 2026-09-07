-- AUTO with no enemies and life under half rests and carries on instead of refusing
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p = game.player
	p.life = math.floor(p.max_life * 0.4)
	local l0 = p.life
	p:autoActStart()
	local rested = false
	local t0 = core.game.getTime()
	while core.game.getTime() - t0 < 12000 do T.wait(200) if p.resting then rested = true end if rested and not p.resting then break end end
	T.log("enemies", #p:actEnemies(), "rested", tostring(rested), "auto still on", tostring(p.auto_act), "life", l0, "->", p.life)
	if not rested and #p:actEnemies() == 0 then T.log("BAD AUTO did not rest at 40% with no enemies") end
	if not p.auto_act and #p:actEnemies() == 0 then T.log("BAD AUTO stopped instead of resting") end
	p:autoActStop("test")
	T.log("finished")
end
