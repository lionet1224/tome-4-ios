-- Screenshot sweep of the game's dialogs on the touch UI (engine.TouchInput script).
-- Each entry opens a dialog, waits, shoots, then closes it with EXIT.
return function(T)
	local function open(name, fct)
		local ok, err = pcall(fct)
		if not ok then T.log("open failed", name, err) return end
		T.wait(900)
		T.shot(name)
		T.key("EXIT") T.wait(300) T.key("EXIT") T.wait(300)
	end
	T.wait(1500)
	T.key("EXIT") T.wait(6000)          -- birth level-up, then the birth finishes
	T.shot("welcome") T.key("EXIT") T.wait(600)
	local p = game.player
	open("game-menu", function() game.key:triggerVirtual("EXIT") end)
	open("inventory", function() game.key:triggerVirtual("SHOW_INVENTORY") end)
	open("character-sheet", function() game.key:triggerVirtual("SHOW_CHARACTER_SHEET") end)
	open("talents", function() game.key:triggerVirtual("USE_TALENTS") end)
	open("quests", function() game.key:triggerVirtual("SHOW_QUESTS") end)
	open("message-log", function() game.key:triggerVirtual("SHOW_MESSAGE_LOG") end)
	open("map", function() game.key:triggerVirtual("SHOW_MAP") end)
	open("levelup", function() game.key:triggerVirtual("LEVELUP") end)
	open("game-options", function() game:registerDialog(require("mod.dialogs.GameOptions").new()) end)
	open("key-bindings", function() game:registerDialog(require("engine.dialogs.KeyBinder").new(game.key)) end)
	open("audio-options", function() game:registerDialog(require("engine.dialogs.AudioOptions").new()) end)
	open("video-options", function() game:registerDialog(require("engine.dialogs.VideoOptions").new()) end)
	open("get-quantity", function() game:registerDialog(require("engine.dialogs.GetQuantity").new("Drop how many?", "1 to 5", 5, 5, function() end, 1)) end)
	open("get-text", function() game:registerDialog(require("engine.dialogs.GetText").new("Name", "Name", 1, 30, function() end, nil, "Soak")) end)
	open("yesno", function() require("engine.ui.Dialog"):yesnoPopup("Save and go back to main menu?", "Save and go back to main menu?", function() end) end)
	open("simple-popup", function() require("engine.ui.Dialog"):simplePopup("Impossible", "You must wear this object to use it!") end)
	open("lore", function() local defs = require("mod.class.interface.PartyLore").lore_defs local id = defs[1] and defs[1].id game.party:learnLore(id, true, true, true) game:registerDialog(require("mod.dialogs.LorePopup").new(id, game.w * 0.6, nil, true)) end)
	open("quest-popup", function() local q for k, v in pairs(p.quests or {}) do q = v break end if q then game:registerDialog(require("mod.dialogs.QuestPopup").new(q, p)) end end)
	open("achievement", function() local a for k, v in pairs(require("engine.interface.WorldAchievements").achievements or {}) do a = v break end if a then game:registerDialog(require("mod.dialogs.Achievement").new(a)) end end)
	open("pickup-floor", function() local o = game.zone:makeEntity(game.level, "object", {type="weapon"}, nil, true) if o then game.zone:addEntity(game.level, o, "object", p.x, p.y) end game.key:triggerVirtual("PICKUP_FLOOR") end)
	open("show-map-dialog", function() game:registerDialog(require("mod.dialogs.ShowMap").new()) end)
	open("chat-log", function() game:registerDialog(require("mod.dialogs.ShowChatLog").new("Chat", 0.6, profile.chat, "talk")) end)
	T.log("finished")
end
