-- Character creation: the five steps, the hero following race and class. Portrait.
return function(T)
	local L = dofile("/touch-demo-lib.lua")
	L.prelude(T)
	local TB = require "mod.dialogs.TouchBirther"
	local d = TB.new("demo", game.player, {"base", "world", "difficulty", "permadeath", "race", "subrace", "sex", "class", "subclass"}, function() end)
	game:registerDialog(d) T.wait(2500)
	local function btn(b) local u = d.ui_by_ui[b] return d.display_x + u.x + b.w / 2, d.display_y + u.y + b.h / 2 end
	local function parent(list, name) for _, r in ipairs(list) do if r.id == name then return r end end end
	if d.b_next then T.tap(btn(d.b_next)) T.wait(2000) end
	for _, race in ipairs{"Giant", "Elf", "Dwarf"} do local r = parent(d.all_races, race) if r then d:raceUse(r) T.wait(1800) end end
	local g = parent(d.all_races, "Dwarf") if g then local first for _, n in ipairs(g.nodes) do if not n.locked then first = n break end end if first then d:raceUse(first) T.wait(2000) end end
	if d.b_next then T.tap(btn(d.b_next)) T.wait(2000) end
	for _, cls in ipairs{"Mage", "Rogue", "Warrior"} do local c = parent(d.all_classes, cls) if c then d:classUse(c) T.wait(1800) end end
	local w = parent(d.all_classes, "Warrior") if w then local first for _, n in ipairs(w.nodes) do if not n.locked then first = n break end end if first then d:classUse(first) T.wait(2200) end end
	if d.b_next then T.tap(btn(d.b_next)) T.wait(2500) end
	T.key("EXIT") T.wait(800)
	T.log("finished")
end
