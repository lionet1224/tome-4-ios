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
local Dialog = require "engine.ui.Dialog"
local Separator = require "engine.ui.Separator"
local List = require "engine.ui.List"
local Button = require "engine.ui.Button"
local ButtonImage = require "engine.ui.ButtonImage"
local Textbox = require "engine.ui.Textbox"
local Textzone = require "engine.ui.Textzone"
local Checkbox = require "engine.ui.Checkbox"

module(..., package.seeall, class.inherit(Dialog))

function _M:init(actor, birth, finish)
	self.actor = actor
	self.birth = birth
	self.finish = finish

	Dialog.init(self, _t"Wanderer Options", 800, 300)

	local explain = Textzone.new{width=self.iw, auto_height=true, text=_t[[Welcome, wandering one! The Wanderer class uses a randomly selected set of talent trees.
You can now choose how this set is selected:]]}
	local explain_random = Textzone.new{width=self.iw - 32, auto_height=true, text=_t[[Simply make a random set of trees, this is the default option. If you want to share it with friends, you will find the seed in the character's sheet later on.]]}
	local explain_seed = Textzone.new{width=self.iw - 32, auto_height=true, text=_t[[If an other player gave you a seed to play, you can enter it here. Do note that while a seed will always work, you will only get the same talents set if you use the same DLC/addons.]]}

	local play = Button.new{text=_t"Play!", fct=function() game:unregisterDialog(self) self:makeWanderer() end}
	local sep = Separator.new{dir="vertical", size=self.iw}
	self.c_randomoption = Checkbox.new{title=_t"#{bold}##ANTIQUE_WHITE#Random#{normal}##LAST#", default=true,
		on_change=function(c) if c then self:swapMode("random") else self.c_randomoption.checked = true end end,
	}
	self.c_seedoption = Checkbox.new{title=_t"#{bold}##ANTIQUE_WHITE#Seed#{normal}##LAST#", default=false,
		on_change=function(c) if c then self:swapMode("seed") else self.c_seedoption.checked = true end end,
	}
	self.c_seed = Textbox.new{title="  "--[[do not translate]], text=__module_extra_info.tome_wanderer_seed or "", chars=40, max_len=200, fct=function() end, on_change=function(text) self:setSeed(text) end}
	self:setSeed(__module_extra_info.tome_wanderer_seed)

	self:loadUI{
		{left=0, top=0, ui=explain},
		{left=0, top=explain, ui=sep},
		{left=0, top=sep, ui=self.c_randomoption},
		{left=32, top=self.c_randomoption, ui=explain_random},
		{left=0, top=explain_random, ui=self.c_seedoption},
		{left=self.c_seedoption, top=explain_random, ui=self.c_seed, hidden=true},
		{left=32, top=self.c_seedoption, ui=explain_seed},
		{hcenter=0, bottom=0, ui=play},
	}
	self:setupUI(false, true)
end

function _M:swapMode(mode)
	if mode == "random" then
		self.c_randomoption.checked = true
		self.c_seedoption.checked = false
		self:toggleDisplay(self.c_seed, false)
	elseif mode == "seed" then
		self.c_randomoption.checked = false
		self.c_seedoption.checked = true
		self:toggleDisplay(self.c_seed, true)
	end
	self.mode = mode
end

function _M:setSeed(seed)
	if not seed then return end
	self.use_seed = seed
end

function _M:makeWanderer()
	local birth = self.birth
	local actor = self.actor
	local tts_class = {}
	local tts_generic = {}
	local tts_addons = {}

	-- Find all available trees
	for _, class in ipairs(birth.all_classes) do if class.id ~= "Adventurer" then
		for _, sclass in ipairs(class.nodes) do if sclass.def and ((not sclass.def.not_on_random_boss) or (sclass.id == "Stone Warden" and birth.descriptors_by_type.race == "Dwarf")) then
			if birth.birth_descriptor_def.subclass[sclass.id].talents_types then
				local tt = birth.birth_descriptor_def.subclass[sclass.id].talents_types
				if type(tt) == "function" then tt = tt(birth) end

				for t, _ in pairs(tt) do
					local tt_def = actor:getTalentTypeFrom(t)
					if tt_def then
						tts_addons[tt_def.source] = true
						if tt_def.generic then
							table.insert(tts_generic, t)
						else
							table.insert(tts_class, t)
						end
					end
				end
			end

			if birth.birth_descriptor_def.subclass[sclass.id].unlockable_talents_types then
				local tt = birth.birth_descriptor_def.subclass[sclass.id].unlockable_talents_types
				if type(tt) == "function" then tt = tt(birth) end

				for t, v in pairs(tt) do
					if profile.mod.allow_build[v[3]] then
						local tt_def = actor:getTalentTypeFrom(t)
						if tt_def then
							tts_addons[tt_def.source] = true
							if tt_def.generic then
								table.insert(tts_generic, t)
							else
								table.insert(tts_class, t)
							end
						end
					end
				end
			end
		end end
	end end
	actor.randventurer_class_trees = tts_class
	actor.randventurer_generic_trees = tts_generic
	
	-- Compute the addons fingerprint
	local md5 = require "md5"
	tts_addons['@vanilla@'] = nil
	actor.randventurer_addons = {game.__mod_info.version_string}
	for a, _ in pairs(tts_addons) do
		local addon = game.__mod_info and game.__mod_info.addons and game.__mod_info.addons[a]
		if addon then
			table.insert(actor.randventurer_addons, a.."-"..(addon.addon_version_txt or addon.version_txt or "???"))
		else -- Shouldnt happen but heh
			table.insert(actor.randventurer_addons, a)
		end
	end
	-- Sort addons so that the fingerprint has meaning ;)
	table.sort(actor.randventurer_addons)
	local addons_md5 = mime.b64(md5.sum(table.concat(actor.randventurer_addons,'|')))
	actor.randventurer_fingerprint = addons_md5

	-- Make the seed, or use the given one
	local seed = rng.range(1, 99999999)
	if self.mode == "seed" and self.use_seed then
		local error = function() game:onTickEnd(function() require("engine.ui.Dialog"):simplePopup(_t"Wanderer Seed", _t"The wanderer seed you used was generated for a different set of DLC/addons. Your character will still work fine but you may not have the same talent set as the person that shared the seed with you.") end) end
		local _, _, iseed, check = self.use_seed:find("^([0-9]+)%-(.*)$")
		if not check or not tonumber(iseed) then
			error()
		else
			seed = tonumber(iseed)
			if check ~= addons_md5 then error() end
		end
	end
	rng.seed(seed)
	table.sort(actor.randventurer_class_trees)
	table.sort(actor.randventurer_generic_trees)
	table.shuffle(actor.randventurer_class_trees)
	table.shuffle(actor.randventurer_generic_trees)

	actor.randventurer_seed = seed.."-"..addons_md5

	rng.seed(os.time())

	-- Give the starting trees
	actor:randventurerLearn("class", true)
	actor:randventurerLearn("class", true)
	actor:randventurerLearn("class", true)
	actor:randventurerLearn("generic", true)

	self.finish()
end
