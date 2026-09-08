-- Act routine editor, second draft (portrait): mode toggle, the When chip and its
-- threshold, keep on / turn off for sustains, Keep distance with its range, everything on screen.
-- Run with TOUCH_EXTRA=', orientation="portrait"' tools/touch/sim-run.sh tools/touch/tests/routines-editor.lua <outdir>
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p = game.player
	local d = require("mod.dialogs.TouchRoutines").new(p)
	game:registerDialog(d)
	T.wait(800)
	local function btn(b) local u = d.ui_by_ui[b] return d.display_x + u.x + b.w / 2, d.display_y + u.y + b.h / 2 end
	local function checkBounds(tag)
		local bad = 0
		for _, u in ipairs(d.uis) do
			local ui = u.ui
			if not (ui.w and ui.w > 0 and ui.h and ui.h > 0) then T.log("BAD "..tag..": ui with empty size", tostring(ui.text or ui.__CLASSNAME)) bad = bad + 1 end
			if u.x > -1000 and (u.x < d.ix or u.y < d.iy or u.x + ui.w > d.ix + d.iw + 1 or u.y + ui.h > d.iy + d.ih + 1) then
				T.log("BAD "..tag..": ui outside the dialog", tostring(ui.text or ui.__CLASSNAME), u.x, u.y, ui.w, ui.h, "dialog", d.iw, d.ih) bad = bad + 1
			end
		end
		-- placed buttons must not overlap each other
		local placed = {}
		for _, u in ipairs(d.uis) do if u.x > -1000 and u.ui.__CLASSNAME == "engine.ui.Button" then placed[#placed+1] = u end end
		for i = 1, #placed do for j = i + 1, #placed do
			local a, b = placed[i], placed[j]
			if a.x < b.x + b.ui.w and b.x < a.x + a.ui.w and a.y < b.y + b.ui.h and b.y < a.y + a.ui.h then
				T.log("BAD "..tag..": buttons overlap", tostring(a.ui.text), tostring(b.ui.text)) bad = bad + 1
			end
		end end
		T.log(tag, "bounds checked, problems", bad)
	end
	local r = d:routine()
	T.log("routine", r.name, "mode", tostring(r.mode), "steps", #r.steps, "portrait", tostring(d.portrait))
	checkBounds("open")
	T.shot("editor-open")

	-- add a known talent through the picker entries (an activated one first, a sustain if any)
	local acts, tal = d:pickerEntries()
	local activated, sustain
	for _, e in ipairs(tal) do if e.t.mode == "sustained" and not sustain then sustain = e elseif e.t.mode == "activated" and not activated then activated = e end end
	if not activated then T.log("BAD no activated talent to add") T.log("finished") return end
	d:appendStep(activated.step) T.wait(300)
	local st = d:step()
	T.log("added", p:actStepName(st), "sel", tostring(d.sel_step), "cond", tostring(st.cond))
	checkBounds("step selected")

	-- the When chip walks the conditions; the summary says "when ..."
	local seen = {}
	local list = mod.class.Player.ACT_CONDS or {"adjacent", "not_adjacent", "group", "life", "resource", "target_life", "no_enemies", "pets_low"}
	for i = 1, #list do
		T.tap(btn(d.b_when)) T.wait(200)
		seen[#seen+1] = tostring(st.cond)
		if st.cond ~= list[i] then T.log("BAD When chip: expected", list[i], "got", tostring(st.cond)) end
		if not d:stepSub(st):find(_t"when") then T.log("BAD summary lacks 'when' for", tostring(st.cond)) end
	end
	T.log("conditions walked:", table.concat(seen, " > "))
	T.tap(btn(d.b_when)) T.wait(200)
	if st.cond ~= nil then T.log("BAD When chip did not wrap back to always, got", tostring(st.cond)) end

	-- life condition: the threshold chip cycles 50 -> 75 -> 25
	while st.cond ~= "life" do T.tap(btn(d.b_when)) T.wait(150) end
	T.log("life cond pct", tostring(st.pct), "summary", d:stepSub(st))
	if st.pct ~= 50 then T.log("BAD life threshold default is not 50, got", tostring(st.pct)) end
	local pu = d.ui_by_ui[d.b_pct]
	if pu.x < -1000 then T.log("BAD threshold chip not shown for the life condition") end
	T.tap(btn(d.b_pct)) T.wait(200)
	T.log("after pct tap", tostring(st.pct))
	if st.pct ~= 75 then T.log("BAD threshold did not cycle to 75, got", tostring(st.pct)) end
	T.tap(btn(d.b_pct)) T.wait(200)
	if st.pct ~= 25 then T.log("BAD threshold did not cycle to 25, got", tostring(st.pct)) end
	if not d:stepSub(st):find("25") then T.log("BAD summary does not show the threshold:", d:stepSub(st)) end
	checkBounds("life cond")
	T.shot("editor-when")

	-- a sustain step reads keep on, the chip turns it into turn off
	if sustain then
		d:appendStep(sustain.step) T.wait(300)
		local ss = d:step()
		T.log("sustain step", p:actStepName(ss), "summary", d:stepSub(ss))
		if not d:stepSub(ss):find(_t"keep on") then T.log("BAD sustain summary lacks 'keep on'") end
		local ou = d.ui_by_ui[d.b_onoff]
		if ou.x < -1000 then T.log("BAD keep on chip not shown for a sustain") end
		T.tap(btn(d.b_onoff)) T.wait(200)
		if not ss.off then T.log("BAD chip did not set off") end
		if not d:stepSub(ss):find(_t"turn off") then T.log("BAD summary lacks 'turn off'") end
		T.tap(btn(d.b_onoff)) T.wait(200)
		if ss.off then T.log("BAD chip did not clear off") end
	else
		T.log("note: no sustained talent known, keep on / turn off not exercised")
	end

	-- mode toggle: priority <-> cycle
	local was = r.mode or "priority"
	T.tap(btn(d.b_mode)) T.wait(200)
	T.log("mode", was, "->", tostring(r.mode), "button", d.b_mode.text)
	if r.mode ~= "cycle" then T.log("BAD mode did not switch to cycle") end
	T.tap(btn(d.b_mode)) T.wait(200)
	if r.mode ~= "priority" then T.log("BAD mode did not switch back to priority") end

	-- Keep distance: offered by the picker, its range chip cycles 3 -> 4 -> 5 -> 2
	local dist
	for _, e in ipairs(acts) do if e.step.kind == "distance" then dist = e end end
	local hasLegacy = false
	for _, e in ipairs(acts) do if e.step.kind == "approach" or e.step.kind == "back" then hasLegacy = true end end
	if hasLegacy then T.log("BAD the picker still offers Approach or Step back") end
	if not dist then T.log("BAD the picker does not offer Keep distance") else
		d:appendStep(dist.step) T.wait(300)
		local ds = d:step()
		T.log("distance step range", tostring(ds.range), "summary", d:stepSub(ds))
		local ru = d.ui_by_ui[d.b_range]
		if ru.x < -1000 then T.log("BAD range chip not shown for Keep distance") end
		T.tap(btn(d.b_range)) T.wait(200)
		if ds.range ~= 4 then T.log("BAD range did not cycle to 4, got", tostring(ds.range)) end
		T.tap(btn(d.b_range)) T.wait(200) T.tap(btn(d.b_range)) T.wait(200)
		if ds.range ~= 2 then T.log("BAD range did not wrap to 2, got", tostring(ds.range)) end
		checkBounds("distance step")
		T.shot("editor-distance")
	end
	local swap
	for _, e in ipairs(acts) do if e.step.kind == "swap" then swap = e end end
	if not swap then T.log("BAD the picker does not offer Swap weapons") end

	-- the class routine entry only when the template module has something for this class
	local ok, AT = pcall(require, "mod.class.ActTemplates")
	local n = d.c_rail.sections[1] and #d.c_rail.sections[1].items or 0
	T.log("template module", tostring(ok and AT ~= nil), "rail entries", n)

	-- the added steps are test debris: remove them
	for i = #r.steps, 1, -1 do local s = r.steps[i] if s == st or (sustain and s.tid == sustain.step.tid and s.kind == "talent") or s.kind == "distance" then table.remove(r.steps, i) end end
	r.pos = 1
	T.key("EXIT") T.wait(400)
	T.log("closed", tostring(not game:hasDialog(d)))
	T.log("finished")
end
