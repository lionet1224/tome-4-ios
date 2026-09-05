-- Touch quest + lore popups for the simulator harness.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Quest = require "engine.Quest"
	local p = game.player
	-- a real quest object: the first the player has
	local quest
	for id, _ in pairs(p.quests or {}) do quest = p:hasQuest(id) if quest then break end end
	T.log("quest", tostring(quest and quest.name))
	local function btn(d, b) local u = d.ui_by_ui[b] return d.display_x + u.x + b.w / 2, d.display_y + u.y + b.h / 2 end
	if quest then
		local d = require("mod.dialogs.QuestPopup").new(quest, Quest.PENDING)
		game:registerDialog(d)
		T.wait(600) T.shot("quest-popup")
		T.log("quest popup touch", tostring(d.touch), "desc h", tostring(d.c_desc and d.c_desc.h))
		T.tap(btn(d, d.b_ok)) T.wait(400)
		T.log("quest popup closed", tostring(not game:hasDialog(d)))
	end
	-- a lore entry with a string text and (if possible) an image, through the normal popup path
	local defs = require("mod.class.interface.PartyLore").lore_defs
	local def
	for _, l in ipairs(defs) do if type(l.lore) == "string" and l.name and l.id and l.image then def = l break end end
	if not def then for _, l in ipairs(defs) do if type(l.lore) == "string" and l.name and l.id then def = l break end end end
	T.log("lore", tostring(def and def.id), "image", tostring(def and def.image))
	if def then
		game.party.lore_known = game.party.lore_known or {}
		game.party.lore_known[def.id] = nil
		game.party:learnLore(def.id, false, true, true)
		T.wait(800)
		local d = game.dialogs[#game.dialogs]
		T.log("top dialog", tostring(d and d.__CLASSNAME), "touch", tostring(d and d.touch))
		T.shot("lore-popup")
		if d and d.b_ok then T.tap(btn(d, d.b_ok)) T.wait(400) end
		T.log("lore popup closed", tostring(not game:hasDialog(d)))
	end
	T.log("dialogs left", tostring(#game.dialogs))
	T.log("finished")
end
