-- AUTO rests without the "Resting..." popup
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p = game.player
	p.life = math.floor(p.max_life * 0.7)
	local seen_popup, rested = false, false
	p:autoActStart()
	local t0 = core.game.getTime()
	while core.game.getTime() - t0 < 15000 do
		T.wait(200)
		if p.resting then rested = true end
		for _, d in ipairs(game.dialogs) do if tostring(d.title):find("Resting") then seen_popup = true end end
		if rested and not p.resting then break end
	end
	T.log("auto_act", tostring(p.auto_act), "rested", tostring(rested), "popup seen", tostring(seen_popup), "life", p.life, "/", p.max_life)
	if not rested then T.log("note: AUTO did not rest in 15 s (enemies?)") end
	if seen_popup then T.log("BAD resting popup shown during AUTO") end
	p:autoActStop("test")
	T.log("finished")
end
