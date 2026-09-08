-- AUTO stops when you are losing breath under water instead of exploring on until you drown.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p = game.player
	p.invulnerable = 1
	-- pretend we are under water: losing air, half of it gone
	p.air_regen = -12
	p.air = math.floor(p.max_air * 0.5)
	p:autoActStart(true) T.wait(600)
	local stopped_at = nil
	local t0 = core.game.getTime()
	while p.auto_act and core.game.getTime() - t0 < 6000 do T.wait(200) end
	T.log("auto_act", tostring(p.auto_act), "air", p.air, "/", p.max_air, "after", core.game.getTime() - t0, "ms")
	if p.auto_act then T.log("BAD AUTO kept going while losing breath") p:autoActStop("test") end
	local why = p:autoActBlocker()
	T.log("blocker now", tostring(why))
	if why ~= _t"losing breath" then T.log("BAD the blocker is not the air rule") end
	-- back on land: no air rule
	p.air_regen = 12 p.air = p.max_air
	local why2 = p:autoActBlocker()
	T.log("blocker with air", tostring(why2))
	if why2 == _t"losing breath" then T.log("BAD air rule holds with full air") end
	T.log("finished")
end
