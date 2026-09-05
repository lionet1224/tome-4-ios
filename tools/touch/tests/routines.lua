-- Touch Act routine editor: open, add a step from the picker, change its target, remove it.
-- Run with tools/touch/sim-run.sh tools/touch/tests/routines.lua <outdir>
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local d = require("mod.dialogs.TouchRoutines").new(game.player)
	game:registerDialog(d)
	T.wait(800) T.shot("routines-open")
	local function itemAt(sec, i)
		local it = d.c_flow.sections[sec].items[i]
		return d.c_flow.last_screen_x + it.x + it.w / 2, d.c_flow.last_screen_y + it.y + it.h / 2 - d.c_flow.scrollbar.pos
	end
	local function btn(b) local u = d.ui_by_ui[b] return d.display_x + u.x + b.w / 2, d.display_y + u.y + b.h / 2 end
	local r = d:routine()
	local before = #r.steps
	T.log("routine", r.name, "steps", before, "routines", #game.player.act_routines)

	-- picker
	T.tap(btn(d.b_add)) T.wait(600)
	T.log("mode", d.mode, "sections", #d.c_flow.sections)
	T.shot("routines-picker")
	local sec = #d.c_flow.sections >= 2 and 2 or 1
	T.tap(itemAt(sec, 1)) T.wait(600)
	T.log("after add: mode", d.mode, "steps", #r.steps, "selected", tostring(d.sel_step), "kind", tostring(d:step() and d:step().kind))
	T.shot("routines-added")

	-- select the new step (tap its card) and change its target through the popup
	if d.sel_step then
		T.tap(itemAt(1, d.sel_step)) T.wait(400)
		local st = d:step()
		local was = st and st.target
		T.tap(btn(d.b_target)) T.wait(600)
		local pop = game.dialogs[#game.dialogs]
		if pop and pop ~= d and pop.uis and pop.uis[3] then
			local lu = pop.uis[3]
			local l = lu.ui
			T.tap(pop.display_x + lu.x + 40, pop.display_y + lu.y + (l.fh or 44) * 1.5) T.wait(500)
		else
			T.log("no target popup found")
		end
		T.log("target", tostring(was), "->", tostring(st and st.target))
		-- if-unusable segmented control
		T.tap(btn(d.b_unusable[2])) T.wait(300)
		T.log("if_unusable", tostring(st and st.if_unusable))
		T.shot("routines-step")
		-- drag the step list, then remove the step
		local x, y = itemAt(1, 1)
		T.swipe(x, y + 200, x, y + 60, 300) T.wait(400)
		T.tap(btn(d.b_remove)) T.wait(400)
		T.log("after remove: steps", #r.steps, "was", before)
	end
	T.key("EXIT") T.wait(400)
	T.log("closed", tostring(not game:hasDialog(d)))
	T.log("finished")
end
