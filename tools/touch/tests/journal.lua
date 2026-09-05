-- Touch journal (quests / lore / achievements) walk-through for the simulator harness.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p = game.player
	-- fake state: one known lore entry and one earned achievement, no popups
	local defs = require("mod.class.interface.PartyLore").lore_defs
	local def
	for _, l in ipairs(defs) do if type(l.lore) == "string" and l.name and l.id then def = l break end end
	if def then pcall(function() game.party:learnLore(def.id, true, true, true) end) end
	T.log("lore", tostring(def and def.id))
	local a = world.achiev_defs[1]
	if a then
		world.achieved[a.id] = world.achieved[a.id] or {turn=game.turn, who=tostring(p.name), when=os.date("%Y-%m-%d %H:%M:%S")}
		p.achievements = p.achievements or {}
		p.achievements[a.id] = p.achievements[a.id] or world.achieved[a.id]
	end
	T.log("achievement", tostring(a and a.id))

	local d = require("mod.dialogs.TouchJournal").new("quests")
	game:registerDialog(d)
	T.wait(800) T.shot("journal-quests")
	local function itemAt(sec, i)
		local it = d.c_flow.sections[sec] and d.c_flow.sections[sec].items[i]
		if not it then return nil end
		return d.c_flow.last_screen_x + it.x + it.w / 2, d.c_flow.last_screen_y + it.y + it.h / 2 - d.c_flow.scrollbar.pos
	end
	-- first quest card (section 2: section 1 is the Active/Done chips)
	local x, y = itemAt(2, 1)
	if x then T.tap(x, y) T.wait(400) end
	T.log("quest picked", tostring(d.cur and d.cur.name))
	-- Done chip
	x, y = itemAt(1, 2)
	if x then T.tap(x, y) T.wait(400) T.shot("journal-quests-done") end

	-- Lore tab: tap it (tabs sit at the top of the dialog)
	local tabs = d.ui_by_ui[d.c_tabs]
	local tab2 = d.c_tabs.uis[2]
	if tabs and tab2 then T.tap(d.display_x + tabs.x + tab2.x + tab2.ui.w / 2, d.display_y + tabs.y + tab2.ui.h / 2) T.wait(500) end
	if d.kind ~= "lore" then d.c_tabs:select("lore") d:switchTab("lore") T.wait(300) end
	T.log("tab", tostring(d.kind))
	x, y = itemAt(1, 1)
	if x then T.tap(x, y) T.wait(500) end
	T.log("lore picked", tostring(d.cur and d.cur.name))
	T.shot("journal-lore")

	-- Achievements tab
	local tab3 = d.c_tabs.uis[3]
	if tabs and tab3 then T.tap(d.display_x + tabs.x + tab3.x + tab3.ui.w / 2, d.display_y + tabs.y + tab3.ui.h / 2) T.wait(500) end
	if d.kind ~= "achievements" then d.c_tabs:select("achievements") d:switchTab("achievements") T.wait(300) end
	T.log("tab", tostring(d.kind))
	x, y = itemAt(2, 1)
	if x then T.tap(x, y) T.wait(500) end
	T.log("achievement picked", tostring(d.cur and d.cur.name))
	T.shot("journal-achievements")
	-- Locked chip, then scroll the list
	x, y = itemAt(1, 2)
	if x then T.tap(x, y) T.wait(400) end
	x, y = itemAt(2, 1)
	if x then T.swipe(x, y + 250, x, y, 400) T.wait(600) end
	T.log("flow scroll", tostring(d.c_flow.scrollbar.pos))
	T.shot("journal-locked")
	T.log("finished")
end
