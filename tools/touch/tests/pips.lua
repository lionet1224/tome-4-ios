return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p = game.player
	T.shot("pips-none")
	-- put two hotkey talents on cooldown and look at the strip under the minimap
	local n = 0
	for i = 1, 12 do local hk = p.hotkey[i] if hk and hk[1] == "talent" and n < 2 then p.talents_cd[hk[2]] = 5 + n n = n + 1 end end
	p.changed = true T.wait(600)
	T.shot("pips-two")
	T.log("cooling", n)
	T.log("finished")
end
