-- AUTO rests without the "Resting..." popup
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p = game.player
	p.life = math.floor(p.max_life * 0.7)
	local seen_popup, rested = false, false
	p:autoActStart()
	local t0 = core.game.getTime()
	local rest_t0, rest_turn0
	while core.game.getTime() - t0 < 15000 do
		T.wait(200)
		if p.resting then rested = true rest_t0 = rest_t0 or core.game.getTime() rest_turn0 = rest_turn0 or game.turn end
		for _, d in ipairs(game.dialogs) do if tostring(d.title):find("Resting") then seen_popup = true end end
		if rested and not p.resting then break end
	end
	T.log("auto_act", tostring(p.auto_act), "rested", tostring(rested), "popup seen", tostring(seen_popup), "life", p.life, "/", p.max_life)
	-- pace of the rest (the script harness also ticks the world in the simulator, so this is a floor)
	if rest_t0 then T.log(("rest pace: %.1f turns/s"):format((game.turn - rest_turn0) / 10 / math.max(0.2, (core.game.getTime() - rest_t0) / 1000))) end
	if not rested then T.log("note: AUTO did not rest in 15 s (enemies?)") end
	if seen_popup then T.log("BAD resting popup shown during AUTO") end
	p:autoActStop("test")
	T.log("finished")
end
