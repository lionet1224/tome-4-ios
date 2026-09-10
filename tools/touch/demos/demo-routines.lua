-- The routine editor: a priority list of steps, the When chip, the mode toggle, the class routine. Portrait.
return function(T)
	local L = dofile("/touch-demo-lib.lua")
	L.prelude(T)
	local p = game.player
	local d = require("mod.dialogs.TouchRoutines").new(p)
	game:registerDialog(d) T.wait(2500)
	local function btn(b) local u = d.ui_by_ui[b] return d.display_x + u.x + b.w / 2, d.display_y + u.y + b.h / 2 end
	-- a talent step to play with
	local r = p:actRoutine()
	local tid for id in pairs(p.talents) do local t = p:getTalentFromId(id) if t and t.mode == "activated" and t.cooldown then tid = id break end end
	if tid then r.steps[#r.steps+1] = {kind="talent", tid=tid, target="nearest", if_unusable="approach"} d.sel_step = #r.steps if d.refresh then d:refresh() end end
	T.wait(2000)
	if d.b_when and d.ui_by_ui[d.b_when] then for _ = 1, 4 do T.tap(btn(d.b_when)) T.wait(1300) end end
	if d.b_mode and d.ui_by_ui[d.b_mode] then T.tap(btn(d.b_mode)) T.wait(1800) T.tap(btn(d.b_mode)) T.wait(1500) end
	if d.b_add and d.ui_by_ui[d.b_add] then T.tap(btn(d.b_add)) T.wait(3000) T.key("EXIT") T.wait(1200) end
	T.key("EXIT") T.wait(800)
	T.log("finished")
end
