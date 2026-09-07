-- Default routines carry no movement steps: melee bumps and shots close in on their own.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p = game.player
	local rs = p:actRoutines()
	local moves = 0
	for _, r in ipairs(rs) do
		for _, st in ipairs(r.steps or {}) do
			T.log("routine", r.name, "step", st.kind, st.if_unusable or "")
			if st.kind == "approach" or st.kind == "back" then moves = moves + 1 end
		end
	end
	-- a save from before the change: an explicit Approach and the archer's Step back must migrate away
	p.act_routines[1].steps[#p.act_routines[1].steps+1] = {kind="approach", target="nearest", if_unusable="skip"}
	p.act_routines[1].steps[#p.act_routines[1].steps+1] = {kind="back", target="nearest", if_unusable="skip"}
	p.act_no_move_steps = nil
	local after = 0
	for _, st in ipairs(p:actRoutines()[1].steps) do if st.kind == "approach" or st.kind == "back" then after = after + 1 end end
	T.log("movement steps in defaults", moves, "after migration", after)
	if moves > 0 or after > 0 then T.log("BAD movement steps remain") end
	T.log("finished")
end
