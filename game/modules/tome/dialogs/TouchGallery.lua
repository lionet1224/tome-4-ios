-- ToME - Tales of Maj'Eyal
-- iOS port: a gallery of every dialog, each opened with faked game state so
-- they can be checked on the phone one by one (and screenshotted by the
-- sweep script, tools/touch/sweep.lua, which uses the same list).

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local List = require "engine.ui.List"
local Map = require "engine.Map"

module(..., package.seeall, class.inherit(Dialog))

local function spawnNPC()
	local p = game.player
	local npc = game.zone:makeEntity(game.level, "actor", {type="humanoid"}, nil, true) or game.zone:makeEntity(game.level, "actor", nil, nil, true)
	if not npc then return nil end
	local x, y = util.findFreeGrid(p.x, p.y, 5, true, {[Map.ACTOR]=true})
	if not x then return nil end
	game.zone:addEntity(game.level, npc, "actor", x, y)
	npc.__touch_gallery = true
	return npc
end

--- The list: {name, fct, note}. fct opens the dialog (state faked as needed).
function _M.entries()
	local p = game.player
	local key = function(k) return function() game.key:triggerVirtual(k) end end
	local dlg = function(mod, ...) local args = {...} return function() game:registerDialog(require(mod).new(unpack(args))) end end
	return {
		{name=_t"Game menu", fct=key("EXIT")},
		{name=_t"Inventory", fct=key("SHOW_INVENTORY")},
		{name=_t"Character sheet", fct=key("SHOW_CHARACTER_SHEET")},
		{name=_t"Talents", fct=key("USE_TALENTS"), note=_t"cards, wheel slots"},
		{name=_t"Journal", fct=key("SHOW_QUESTS"), note=_t"quests / lore / achievements"},
		{name=_t"Lore tab", fct=function() game:registerDialog(require("mod.dialogs.TouchJournal").new("lore")) end},
		{name=_t"Achievements tab", fct=function() game:registerDialog(require("mod.dialogs.TouchJournal").new("achievements")) end},
		{name=_t"How many? prompt", fct=function() game:registerDialog(require("engine.dialogs.GetQuantity").new(_t"How many?", _t"Drop", 3, 20, function(q) game.log("Picked %d", q) end)) end},
		{name=_t"Quest popup", fct=function() local q for id in pairs(p.quests or {}) do q = p:hasQuest(id) if q then break end end if q then game:registerDialog(require("mod.dialogs.QuestPopup").new(q, require("engine.Quest").PENDING)) end end},
		{name=_t"Lore popup", fct=function() local defs = require("mod.class.interface.PartyLore").lore_defs for _, l in ipairs(defs) do if type(l.lore) == "string" and l.image then require("mod.dialogs.LorePopup").new(l, game.w * 0.6, 0.8) break end end end},
		{name=_t"Act routines", fct=function() game:registerDialog(require("mod.dialogs.TouchRoutines").new(p)) end, note=_t"steps with icons, picker"},
		{name=_t"Death screen (preview)", fct=function() game:registerDialog(require("mod.dialogs.DeathDialog").new(p, {preview=true})) end, note=_t"no life used"},
		{name=_t"Message log", fct=key("SHOW_MESSAGE_LOG")},
		{name=_t"Level map", fct=key("SHOW_MAP")},
		{name=_t"Level up", fct=key("LEVELUP")},
		{name=_t"Prodigies", fct=function() game:registerDialog(require("mod.dialogs.TouchProdigies").new(p, {})) end},
		{name=_t"Game options", fct=dlg("mod.dialogs.TouchOptions")},
		{name=_t"Floor pickup", fct=function() for i = 1, 3 do local o = game.zone:makeEntity(game.level, "object", {type="weapon"}, nil, true) if o then game.level.map:addObject(p.x, p.y, o) end end p:playerPickup() end, note=_t"drops 3 weapons first"},
		{name=_t"Key bindings", fct=function() game:registerDialog(require("engine.dialogs.KeyBinder").new(game.key)) end},
		{name=_t"Audio options", fct=dlg("engine.dialogs.AudioOptions")},
		{name=_t"Video options", fct=dlg("engine.dialogs.VideoOptions")},
		{name=_t"Language", fct=dlg("engine.dialogs.LanguageSelect")},
		{name=_t"Quantity prompt", fct=function() game:registerDialog(require("engine.dialogs.GetQuantity").new(_t"Drop how many?", _t"1 to 5", 5, 5, function() end, 1)) end},
		{name=_t"Text prompt", fct=function() game:registerDialog(require("engine.dialogs.GetText").new(_t"Name", _t"Name", 1, 30, function() end, nil, "Soak")) end},
		{name=_t"Yes / no popup", fct=function() Dialog:yesnoPopup(_t"Save and go back to main menu?", _t"Save and go back to main menu?", function() end) end},
		{name=_t"Simple popup", fct=function() Dialog:simplePopup(_t"Impossible", _t"You must wear this object to use it!") end},
		{name=_t"Lore popup", fct=function()
			local defs = require("mod.class.interface.PartyLore").lore_defs
			local def
			for _, l in ipairs(defs) do if type(l.lore) == "string" and l.name then def = l break end end
			if not def then game.logPlayer(p, "No lore loaded yet.") return end
			game:registerDialog(require("mod.dialogs.LorePopup").new(def, game.w * 0.6))
		end},
		{name=_t"Quest popup", fct=function() local q for _, v in pairs(p.quests or {}) do q = v break end if q then game:registerDialog(require("mod.dialogs.QuestPopup").new(q, p)) end end},
		{name=_t"Achievement popup", fct=function() local defs = require("engine.interface.WorldAchievements").achiev_defs local a = defs[1] if a then game:registerDialog(require("engine.dialogs.Achievement").new(_t"Achievement", a)) end end},
		{name=_t"Item on the floor (pick up)", fct=function()
			for _ = 1, 2 do local o = game.zone:makeEntity(game.level, "object", {type="weapon"}, nil, true) if o then game.zone:addEntity(game.level, o, "object", p.x, p.y) end end
			game.key:triggerVirtual("PICKUP_FLOOR")
		end, note=_t"drops two weapons on your tile first"},
		{name=_t"NPC talk", fct=function()
			local npc = spawnNPC()
			if not npc then game.logPlayer(p, "Could not spawn a creature to talk to.") return end
			require("engine.Chat").new("golbug-explains", npc, p):invoke()
		end, note=_t"spawns a creature next to you"},
		{name=_t"Shop", fct=function()
			local st = game:getStore("SWORD_WEAPON")
			if not st then game.logPlayer(p, "No store definition.") return end
			st:loadup(game.level, game.zone)
			st:interact(p, "Test smith")
		end, note=_t"a faked weapon shop"},
	}
end

function _M:init()
	Dialog.init(self, _t"Touch UI gallery", game.w * 0.6, game.h * 0.9)
	local list = {}
	for _, e in ipairs(_M.entries()) do list[#list+1] = {name=e.name..(e.note and ("  #GREY#("..e.note..")#LAST#") or ""), entry=e} end
	self.c_list = List.new{width=self.iw, height=self.ih, scrollbar=true, list=list, fct=function(item) self:open(item.entry) end}
	self:loadUI{{left=0, top=0, ui=self.c_list}}
	self:setupUI()
	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end }
end

function _M:open(e)
	print("[TOUCH] gallery", e.name)
	local ok, err = pcall(e.fct)
	if not ok then game.logPlayer(game.player, "Could not open %s: %s", e.name, tostring(err)) print("[TOUCH] gallery failed", e.name, err) end
end
