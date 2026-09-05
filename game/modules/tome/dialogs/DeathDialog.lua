-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2019 Nicolas Casalini
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

require "engine.class"
local Shader = require "engine.Shader"
local Dialog = require "engine.ui.Dialog"
local Textzone = require "engine.ui.Textzone"
local Separator = require "engine.ui.Separator"
local List = require "engine.ui.List"
local Savefile = require "engine.Savefile"
local Map = require "engine.Map"
local Tiles = require "engine.Tiles"
local TextzoneList = require "engine.ui.TextzoneList"

module(..., package.seeall, class.inherit(Dialog))

function _M:init(actor, opts)
	self.actor = actor
	self.ui = "deathbox"
	-- iOS port: the touch layout (character card + big choice cards) lives in initTouch
	if require("engine.TouchInput").active() then return self:initTouch(actor, opts) end
	-- iOS port: the fixed 500x600 box does not fit a phone in landscape (645 high)
	local W, H = 500, 600
	if require("engine.TouchInput").active() then W, H = math.floor(game.w * 0.7), math.floor(game.h * 0.92) end
	Dialog.init(self, _t"You have #LIGHT_RED#died#LAST#!", W, H)

	actor:saveUUID()

	self:generateList()
	if self.dont_show then return end
	if not config.settings.cheat then game:onTickEnd(function() game:saveGame() end) end

	self:setupDescription()

	self:setTitleShadowShader(Shader.default.textoutline and Shader.default.textoutline.shad, 1.5)

	self.c_list = List.new{width=self.iw, nb_items=#self.list, list=self.list, fct=function(item) self:use(item) end, select=function(item) self.cur_item = item end}

	self.graphical_options = {
		blood_life = {
			available   = self:getUITexture("ui/active_blood_life.png"),
			unavailable = self:getUITexture("ui/inactive_blood_life.png"),
		},
		consume = {
			available   = self:getUITexture("ui/active_consume.png"),
			unavailable = self:getUITexture("ui/inactive_consume.png"),
		},
		skeleton = {
			available   = self:getUITexture("ui/active_skeleton.png"),
			unavailable = self:getUITexture("ui/inactive_skeleton.png"),
		},
	}


	if self.c_achv then
		self:loadUI{
			{left=0, top=0, ui=self.c_desc},
			{left=0, top=self.c_desc.h, ui=self.c_achv},
			{left=5, top=self.c_desc.h+self.c_achv.h, padding_h=10, ui=Separator.new{ui="deathbox", dir="vertical", size=self.iw - 10}},
			{left=0, bottom=0, ui=self.c_list},
		}
	else
		self:loadUI{
			{left=0, top=0, ui=self.c_desc},
			{left=5, top=self.c_desc.h, padding_h=10, ui=Separator.new{ui="deathbox", dir="vertical", size=self.iw - 10}},
			{left=0, bottom=0, ui=self.c_list},
		}
	end
	self:setFocus(self.c_list)
	self:setupUI(false, true)
end

function _M:setupDescription()
	self.c_desc = Textzone.new{width=self.iw, auto_height=true, text=_t[[Death in #{bold}#Tales of Maj'Eyal#{normal}# is usually permanent, but if you have a means of resurrection it will be proposed in the menu below.
You can dump your character data to a file to remember her/him forever, or you can exit and try once again to survive in the wilds!
]]}
	self.c_desc:setTextShadow(1)
	self.c_desc:setShadowShader(Shader.default.textoutline and Shader.default.textoutline.shad, 1.2)

	if #game.party.on_death_show_achieved > 0 then
		self.c_achv = Textzone.new{width=self.iw, scrollbar=true, height=100, text=("#LIGHT_GREEN#During your game you#WHITE#:\n* %s"):tformat(table.concat(game.party.on_death_show_achieved, "\n* "))}
	end
end

--- Clean the actor from debuffs/buffs
function _M:cleanActor(actor)
	local effs = {}

	-- Remove chronoworlds
	game:chronoCancel()

	-- Go through all spell effects
	for eff_id, p in pairs(actor.tmp) do
		local e = actor.tempeffect_def[eff_id]
		effs[#effs+1] = {"effect", eff_id}
	end

	-- Go through all sustained spells
	for tid, act in pairs(actor.sustain_talents) do
		if act then
			effs[#effs+1] = {"talent", tid}
		end
	end

	while #effs > 0 do
		local eff = rng.tableRemove(effs)

		if eff[1] == "effect" then
			actor:removeEffect(eff[2], false, true)
		else
			actor:forceUseTalent(eff[2], {ignore_energy=true, no_equilibrium_fail=true, no_paradox_fail=true, save_cleanup=true})
		end
	end
end

--- Restore resources
function _M:restoreResources(actor)
	if actor.resetToFull then
		actor:resetToFull()
		actor.energy.value = game.energy_to_act
	end
end

--- Basic resurrection
function _M:resurrectBasic(actor, reason)
	actor.dead = false
	actor.died = (actor.died or 0) + 1
	
	-- Find the position of the last dead
	local last = game.party:findLastDeath()

	local x, y = util.findFreeGrid(last.x, last.y, 20, true, {[Map.ACTOR]=true})
	if not x then x, y = last.x, last.y end
	
	-- invulnerable while moving so we don't get killed twice
	local old_invuln = actor.invulnerable
	actor.invulnerable = 1
	actor.x, actor.y = nil, nil
	actor:move(x, y, true)
	actor.invulnerable = old_invuln

	game.level:addEntity(actor)
	game:unregisterDialog(self)
	game.level.map:redisplay()
	actor.energy.value = game.energy_to_act

	-- apply cursed equipment
	if actor.hasTalent and actor.hasTalent(actor.T_DEFILING_TOUCH) then
		local t = actor:getTalentFromId(actor.T_DEFILING_TOUCH)
		t.updateCurses(actor, t, true)
	end

	actor.changed = true
	game.paused = true

	actor:checkTwoHandedPenalty()

	actor:fireTalentCheck("callbackOnResurrect", reason or "unknown")
end

--- Send the party to the Eidolon Plane
function _M:eidolonPlane()
--	self.actor:setEffect(self.actor.EFF_EIDOLON_PROTECT, 1, {})
	game:onTickEnd(function()
		if not self.actor:attr("infinite_lifes") then
			self.actor:attr("easy_mode_lifes", -1)
			local nb = self.actor:attr("easy_mode_lifes") and self.actor:attr("easy_mode_lifes") or 0
			local style
			if(nb > 0) then style = ("#LIGHT_RED#You have %d life(s) left."):tformat(nb)
			else style = ("#LIGHT_RED#You have no more lives left."):tformat() end
			game.log(style)
		end

		local is_exploration = game.permadeath == game.PERMADEATH_INFINITE
		self:cleanActor(self.actor)
		self:resurrectBasic(self.actor, "eidolon_plane")
		for e, _ in pairs(game.party.members) do if e ~= self.actor then
			self:cleanActor(e)
		end end
		for uid, e in pairs(game.level.entities) do
			if not is_exploration or game.party:hasMember(e) then
				self:restoreResources(e)
			end
		end

		game.party:goToEidolon(self.actor)

		game.log("#LIGHT_RED#From the brink of death you seem to be yanked to another plane.")
		game.player:updateMainShader()
		if not config.settings.cheat then game:onTickEnd(function() game:saveGame() end) end

		self.actor:checkTwoHandedPenalty()
	end)
	return true
end

function _M:use(item)
	if not item then return end
	local act = item.action

	if type(act) == "function" then
		act()
	elseif act == "exit" then
		if item.subaction == "none" then
			util.showMainMenu()
		elseif item.subaction == "restart" then
			local addons = {}
			for add, _ in pairs(game.__mod_info.addons) do addons[#addons+1] = "'"..add.."'" end
			util.showMainMenu(false, engine.version[4], engine.version[1].."."..engine.version[2].."."..engine.version[3], game.__mod_info.short_name, game.save_name, true, ("auto_quickbirth=%q set_addons={%s}"):format(game:getPlayer(true).name, table.concat(addons, ", ")))
		elseif item.subaction == "restart-new" then
			util.showMainMenu(false, engine.version[4], engine.version[1].."."..engine.version[2].."."..engine.version[3], game.__mod_info.short_name, game.save_name, true)
		end
	elseif act == "dump" then
		game:registerDialog(require("mod.dialogs.CharacterSheet").new(self.actor))
	elseif act == "log" then
		game:registerDialog(require("mod.dialogs.ShowChatLog").new(_t"Message Log", 0.6, game.uiset.logdisplay, profile.chat))
	elseif act == "cheat" then
		game.logPlayer(self.actor, "#LIGHT_BLUE#You resurrect! CHEATER!")

		self:cleanActor(self.actor)
		self:resurrectBasic(self.actor, "cheat")
		self:restoreResources(self.actor)
		self.actor:check("on_resurrect", "cheat")
		self.actor:triggerHook{"Actor:resurrect", reason="cheat"}
	elseif act == "blood_life" then
		self.actor.blood_life = false
		game.logPlayer(self.actor, "#LIGHT_RED#The Blood of Life rushes through your dead body. You come back to life!")

		self:cleanActor(self.actor)
		self:resurrectBasic(self.actor, "blood_life")
		self:restoreResources(self.actor)
		world:gainAchievement("UNSTOPPABLE", actor)
		self.actor:check("on_resurrect", "blood_life")
		self.actor:triggerHook{"Actor:resurrect", reason="blood_life"}
		game:saveGame()
	elseif act == "threads" then
		game:chronoRestore("see_threads_base", true)
		game:onTickEnd(function()
			game:chronoCancel()
			game.player:removeEffect(game.player.EFF_SEE_THREADS)end
		)
		game:saveGame()
	elseif act == "easy_mode" then
		self:eidolonPlane()
	elseif act == "skeleton" then
		self.actor:attr("re-assembled", 1)
		game.logPlayer(self.actor, "#YELLOW#Your bones magically knit back together. You are once more able to dish out pain to your foes!")

		self:cleanActor(self.actor)
		self:resurrectBasic(self.actor, "skeleton")
		self:restoreResources(self.actor)
		world:gainAchievement("UNSTOPPABLE", actor)
		self.actor:check("on_resurrect", "skeleton")
		self.actor:triggerHook{"Actor:resurrect", reason="skeleton"}
		game:saveGame()
	elseif act:find("^consume") then
		local inven, item, o = item.inven, item.item, item.object
		self.actor:removeObject(inven, item)
		game.logPlayer(self.actor, "#YELLOW#Your %s is consumed and disappears! You come back to life!", o:getName{do_colour=true})

		self:cleanActor(self.actor)
		self:resurrectBasic(self.actor, "consume", o)
		self:restoreResources(self.actor)
		world:gainAchievement("UNSTOPPABLE", actor)
		self.actor:check("on_resurrect", "consume", o)
		o:check("on_resurrect", self.actor)
		self.actor:triggerHook{"Actor:resurrect", reason="consume", object=o}
		game:saveGame()
	end
end

function _M:generateList()
	local list = {}
	self.possible_items = {}
	local allow_res = true

	-- Pause the game
	game:onTickEnd(function()
		game.paused = true
		game.player.energy.value = game.energy_to_act
	end)

	if game.zone.is_eidolon_plane then
		game.logPlayer(self, "You managed to die on the eidolon plane! DIE!")
		game:onTickEnd(function() world:gainAchievement("EIDOLON_DEATH", self.actor) end)
		allow_res = false
	end

	if game.state.death_is_final then
		allow_res = false
	end

	local hd = {"DeathDialog:isDeathFinal"}
	if self:triggerHook(hd) then
		allow_res = false
	end

	if config.settings.cheat then list[#list+1] = {name=_t"Resurrect by cheating", action="cheat"} end
	if not self.actor.no_resurrect and allow_res then
		if self.actor:hasEffect(self.actor.EFF_SEE_THREADS) and game._chronoworlds then
			self:use{action="threads"}
			self.dont_show =true
			return
		end
		
		if self.actor:fireTalentCheck("callbackOnDeathbox", self, list) then return end

		if self.actor:attr("blood_life") and not self.actor:attr("undead") then list[#list+1] = {name=_t"Resurrect with the Blood of Life", action="blood_life"} end
		if self.actor:getTalentLevel(self.actor.T_SKELETON_REASSEMBLE) >= 5 and not self.actor:attr("re-assembled") then list[#list+1] = {name=_t"Re-assemble your bones and resurrect (Skeleton ability)", action="skeleton"} end

		local consumenb = 1
		self.actor:inventoryApplyAll(function(inven, item, o)
			if o.one_shot_life_saving and (not o.slot or inven.worn) then
				list[#list+1] = {name=("Resurrect by consuming %s"):tformat(o:getName{do_colour=true}), action="consume"..consumenb, inven=inven, item=item, object=o, is_consume=true}
				consumenb = consumenb + 1
				self.possible_items.consume = true
			end
		end)

		local can_auto_select = true
		for i, d in ipairs(list) do if d.force_choice then can_auto_select = false break end end

		if self.actor:attr("easy_mode_lifes") then
			list[#list+1] = {name=("Resurrect with Adventurer Mode (%d life(s) left)"):tformat(self.actor.easy_mode_lifes), action="easy_mode"}
			if can_auto_select then
				self:use{action="easy_mode"}
				self.dont_show = true
				return
			end
		end
		if self.actor:attr("infinite_lifes") then
			list[#list+1] = {name=_t"Resurrect with Exploration Mode", action="easy_mode"}
			if can_auto_select then
				self:use{action="easy_mode"}
				self.dont_show = true
				return
			end
		end
	end

	list[#list+1] = {name=(not profile.auth and _t"Message Log" or _t"Message/Chat log (allows to talk)"), action="log"}
	list[#list+1] = {name=_t"Character dump", action="dump"}
	list[#list+1] = {name=_t"Restart the same character", action="exit", subaction="restart"}
	list[#list+1] = {name=_t"Restart with a new character", action="exit", subaction="restart-new"}
	list[#list+1] = {name=_t"Exit to main menu", action="exit", subaction="none"}

	self.list = list
	for _, item in ipairs(list) do self.possible_items[item.action] = true end
end

function _M:innerDisplayBack(x, y, nb_keyframes, tx, ty)
	if self.touch then return self:touchDisplayBack(x, y, nb_keyframes) end
	x = x + self.frame.ox1
	y = y + self.frame.oy1

	if self.possible_items.blood_life then
		local d = self.graphical_options.blood_life[self.cur_item and self.cur_item.action == "blood_life" and "available" or "unavailable"]
		d.t:toScreenFull(x + self.frame.w - d.w, y, d.w, d.h, d.tw, d.th, 1, 1, 1, 1)
	end
	if self.possible_items.consume then
		local d = self.graphical_options.consume[self.cur_item and self.cur_item.is_consume and "available" or "unavailable"]
		d.t:toScreenFull(x, y, d.w, d.h, d.tw, d.th, 1, 1, 1, 1)
	end
	if self.possible_items.skeleton then
		local d = self.graphical_options.skeleton[self.cur_item and (self.cur_item.action == "skeleton" or self.cur_item.action == "lichform") and "available" or "unavailable"]
		d.t:toScreenFull(x, y + self.frame.h - d.h, d.w, d.h, d.tw, d.th, 1, 1, 1, 1)
	end
end

------------------------------------------------------------------------
-- iOS port: touch layout
------------------------------------------------------------------------
-- Same choices, same actions, same "no way out" rule as the desktop box:
-- a character card on the left (sprite, name, killer, run facts, the death
-- text and achievements), the choices as full-width cards on the right.
--
-- Preview (gallery / tests): DeathDialog.new(actor, {preview=true}) builds the
-- real choice list but every action only prints and closes; nothing on the
-- actor or the game is touched (no life consumed, no save, no pause).

local K = require "engine.ui.TouchKit"

function _M:initTouch(actor, opts)
	self.touch = true
	self.preview = opts and opts.preview or false
	self.no_close_box = true
	Dialog.init(self, _t"You have #LIGHT_RED#died#LAST#!", math.floor(game.w * 0.96), math.floor(game.h * 0.96))

	if self.preview then
		self:previewList()
	else
		actor:saveUUID()
		self:generateList()
		if self.dont_show then return end
		if not config.settings.cheat then game:onTickEnd(function() game:saveGame() end) end
	end

	self:setTitleShadowShader(Shader.default.textoutline and Shader.default.textoutline.shad, 1.5)
	self.tiles = Tiles.new(64, 64, nil, nil, true, nil)

	local gap = 12
	self.left_w = math.floor(self.iw * 0.42)
	self.hero_h = 200
	local right_w = self.iw - self.left_w - gap

	-- death text + achievements, scrolling under the character card
	local desc = _t[[Death in #{bold}#Tales of Maj'Eyal#{normal}# is usually permanent, but if you have a means of resurrection it will be proposed in the menu below.
You can dump your character data to a file to remember her/him forever, or you can exit and try once again to survive in the wilds!
]]
	if #game.party.on_death_show_achieved > 0 then
		desc = desc .. ("\n#LIGHT_GREEN#During your game you#WHITE#:\n* %s"):tformat(table.concat(game.party.on_death_show_achieved, "\n* "))
	end
	local desc_h = self.ih - self.hero_h - 8
	self.c_desc = TextzoneList.new{focus_check=true, scrollbar=true, width=self.left_w - 8, height=desc_h, dest_area={h=desc_h}}
	self.c_desc:switchItem("death", desc)

	-- the choices
	self.c_flow = K.Flow.new{width=right_w, height=self.ih}
	local items = {}
	for _, item in ipairs(self.list) do
		items[#items+1] = {name=tostring(item.name):gsub("#[^#]*#", ""), sub=item.sub or self:touchSub(item), data=item,
			on_tap=function() self.cur_item = item self:use(item) end}
	end
	self.c_flow:setSections{{title=_t"What now?", items=items, cols=1, row_h=64}}

	self:loadUI{
		{left=4, top=self.hero_h, ui=self.c_desc},
		{left=self.left_w + gap, top=0, ui=self.c_flow},
	}
	self:setFocus(self.c_flow)
	self:setupUI(false, true)
end

-- one line under each choice saying what it costs / does
function _M:touchSub(item)
	local a = item.action
	if type(a) == "function" then return _t"A talent brings you back"
	elseif a == "cheat" then return _t"Debug: come back for free"
	elseif a == "blood_life" then return _t"Spends the Blood of Life; you keep everything"
	elseif a == "skeleton" then return _t"Skeleton ability, once per character"
	elseif type(a) == "string" and a:find("^consume") then return _t"The item is destroyed; you keep everything else"
	elseif a == "easy_mode" then
		if self.actor:attr("infinite_lifes") then return _t"Exploration mode: unlimited lives" end
		local n = self.actor:attr("easy_mode_lifes") or 0
		return (_t"Uses one of your %d remaining lives; you wake on the Eidolon plane"):format(n)
	elseif a == "threads" then return _t"Rewind to before the fight"
	elseif a == "log" then return _t"Read what happened"
	elseif a == "dump" then return _t"Open the character sheet one last time"
	elseif a == "exit" then
		if item.subaction == "restart" then return _t"Same race and class, a fresh game"
		elseif item.subaction == "restart-new" then return _t"Back to character creation"
		else return _t"Leave this character behind" end
	end
	return ""
end

-- The choice list exactly as generateList builds it, minus every side effect:
-- no pause, no achievement, no auto-resurrect, no talent callback. Every
-- action is replaced by a print + close.
function _M:previewList()
	local list = {}
	self.possible_items = {}
	local a = self.actor
	local allow_res = not (game.zone and game.zone.is_eidolon_plane)
	if config.settings.cheat then list[#list+1] = {name=_t"Resurrect by cheating", action="cheat"} end
	if not a.no_resurrect and allow_res then
		if a:attr("blood_life") and not a:attr("undead") then list[#list+1] = {name=_t"Resurrect with the Blood of Life", action="blood_life"} end
		if a:getTalentLevelRaw(a.T_SKELETON_REASSEMBLE) >= 5 and not a:attr("re-assembled") then list[#list+1] = {name=_t"Re-assemble your bones and resurrect (Skeleton ability)", action="skeleton"} end
		local consumenb = 1
		a:inventoryApplyAll(function(inven, item, o)
			if o.one_shot_life_saving and (not o.slot or inven.worn) then
				list[#list+1] = {name=("Resurrect by consuming %s"):tformat(o:getName{do_colour=true}), action="consume"..consumenb, is_consume=true}
				consumenb = consumenb + 1
			end
		end)
		if a:attr("easy_mode_lifes") then list[#list+1] = {name=("Resurrect with Adventurer Mode (%d life(s) left)"):tformat(a.easy_mode_lifes), action="easy_mode"} end
		if a:attr("infinite_lifes") then list[#list+1] = {name=_t"Resurrect with Exploration Mode", action="easy_mode"} end
	end
	list[#list+1] = {name=(not profile.auth and _t"Message Log" or _t"Message/Chat log (allows to talk)"), action="log"}
	list[#list+1] = {name=_t"Character dump", action="dump"}
	list[#list+1] = {name=_t"Restart the same character", action="exit", subaction="restart"}
	list[#list+1] = {name=_t"Restart with a new character", action="exit", subaction="restart-new"}
	list[#list+1] = {name=_t"Exit to main menu", action="exit", subaction="none"}
	-- the sub line is computed from the real action; the action itself is neutered afterwards
	for _, item in ipairs(list) do
		item.sub = self:touchSub(item)
		local name = tostring(item.name):gsub("#[^#]*#", "")
		item.action = function() print("[TOUCH] death preview action", name) game:unregisterDialog(self) end
		item.subaction = nil
	end
	self.list = list
end

function _M:touchDisplayBack(x, y, nb_keyframes)
	x, y = x + self.ix, y + self.iy
	local a = self.actor
	local T, quad, draw = K.text, K.quad, K.draw
	-- character card
	quad(x, y, self.left_w, self.hero_h - 8, K.PANE)
	local sz = 112
	quad(x + 12, y + 12, sz + 8, sz + 8, {14, 15, 18})
	if a.image then pcall(a.toScreen, a, self.tiles, x + 16, y + 16, sz, sz) end
	local tx = x + 12 + sz + 20
	local maxw = self.left_w - (tx - x) - 12
	draw(T(a.name or "?", 22, 240, 212, 138, true, maxw), tx, y + 16)
	local d = a.descriptor or {}
	draw(T(("Level %d %s %s"):format(a.level or 1, tostring(d.subrace or ""), tostring(d.subclass or "")), 13, 142, 136, 120, false, maxw), tx, y + 46)
	local killer = a.killedBy and a.killedBy.name or nil
	if self.preview and not killer then killer = _t"(preview)" end
	local kl = killer and (_t"Killed by " .. tostring(killer)) or _t"Killed"
	for i, l in ipairs(K.wrap(kl, K.font(15), maxw, 2)) do draw(T(l, 15, 224, 122, 106, true, maxw), tx, y + 68 + (i - 1) * 20) end
	-- run facts
	local facts = {}
	if game.zone and game.level then facts[#facts+1] = {_t"Where", ("%s %d"):format(tostring(game.zone.name), game.level.level or 1)} end
	facts[#facts+1] = {_t"Turn", tostring(math.floor((game.turn or 0) / 10))}
	if a:attr("easy_mode_lifes") then facts[#facts+1] = {_t"Lives", tostring(a:attr("easy_mode_lifes"))}
	elseif a:attr("infinite_lifes") then facts[#facts+1] = {_t"Lives", _t"unlimited"} end
	local cw = math.floor((self.left_w - 24 - 2 * 6) / 3)
	for i, f in ipairs(facts) do
		if i > 3 then break end
		local cx, cy = x + 12 + (i - 1) * (cw + 6), y + self.hero_h - 8 - 48
		quad(cx, cy, cw, 40, {36, 39, 47})
		draw(T(f[1]:upper(), 10, 142, 136, 120, true), cx + 8, cy + 4)
		draw(T(f[2], 15, 234, 227, 209, true, cw - 16), cx + 8, cy + 17)
	end
	-- the choices pane
	quad(x + self.left_w + 12, y, self.iw - self.left_w - 12, self.ih, K.PANE)
end
