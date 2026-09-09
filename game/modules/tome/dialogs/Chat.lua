-- TE4 - T-Engine 4
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
local Chat = require "engine.dialogs.Chat"
local VariableList = require "engine.ui.VariableList"
local Textzone = require "engine.ui.Textzone"
local Separator = require "engine.ui.Separator"
local ChatPortrait = require "mod.dialogs.elements.ChatPortrait"
local Map = require "engine.Map"
local Entity = require "engine.Entity"

module(..., package.seeall, class.inherit(Chat))

function _M:init(chat, id, width)
	self.ui = "chat"
	self.force_title = ""
	self.force_min_h = 256

	Chat.init(self, chat, id, math.max(width, game.w * 0.4))
end

function _M:makeUI()
	self.c_desc = Textzone.new{has_box=true, ui="chat", font=self.chat.dialog_text_font, width=self.iw - 30, height=1, auto_height=true, text=self.text, can_focus=false}
	self.c_list = VariableList.new{font=self.chat.dialog_answer_font, width=self.iw, max_height=game.h * 0.70 - self.c_desc.h, list=self.list, fct=function(item) self:use(item) end, select=function(item) self:select(item) end}
	local npc_frame = ChatPortrait.new{ui="chat", side="right", actor=self:getActorPortraitFull(self.chat.npc_force_display_entity or self.npc.chat_display_entity or self.npc)}
	local player_frame = ChatPortrait.new{ui="chat", side="left", actor=self:getActorPortraitFull(self.chat.player_force_display_entity or self.player.chat_display_entity or self.player)}

	local uis = {
		{hcenter=0, top=-12, ui=self.c_desc},
		{right=0, bottom=0, ui=self.c_list},
		{left=-player_frame.w+self.frame.ox1-5, top=self.frame.oy1-self.iy, ui=player_frame, ignore_size=true},
		{right=-npc_frame.w-self.frame.ox2-5, top=self.frame.oy1-self.iy, ui=npc_frame, ignore_size=true},
	}

	-- Only for size info
	local back = self:getUITexture("ui/portrait_frame_back.png")

	self:loadUI(uis)
	self:setFocus(self.c_list)
	self:setupUI(false, true, function(w, h)
		local frameh = -self.frame.oy1 + self.frame.oy2
		-- Ensure minimal height
		if h + frameh < back.h then h = back.h - frameh end
		-- Ensure if it's too big but too small to not have the down deco, to increase it a it
		if h + frameh > back.h then
			if h + frameh < back.h + 16 then h = back.h - frameh + 16
			elseif h + frameh < back.h + 32 then h = back.h - frameh + 32
			elseif h + frameh < back.h + 48 then h = back.h - frameh + 48
			elseif h + frameh < back.h + 64 then h = back.h - frameh + 64
			elseif h + frameh < back.h + 80 then h = back.h - frameh + 80
			end
		end

		self.force_x = game.w / 2 - w / 2
		self.force_y = game.h - h - 20
		return w, h
	end)
	npc_frame:adjustHeight(self.h)
	player_frame:adjustHeight(self.h)
end

function _M:getActorPortraitFull(actor)
	local e = self:getActorPortrait(actor)
	if e.image and (e.image:find("talents/") or e.image:find("effects/")) then
		e = Entity.new{name=e.name, image=e.image, chat_portrait_background="ui/chat_talents_bg.png", chat_portrait_size=0.75}
	end
	return e
end

function _M:getActorPortrait(actor)
	local actor = actor.replace_display or actor
	
	-- Moddable tiles are already portrait sized
	if actor.moddable_tile and Map.tiles.no_moddable_tiles then return actor end

	-- No image at all ?
	if not actor.image then
		-- By any chance are we running a talent ?
		if self.player.getCurrentTalent and self.player:getCurrentTalent() then
			local t = self.player:getTalentFromId(self.player:getCurrentTalent())
			if t then
				local image = t.image or "portrait/unknown.png"
				if image:find("^talents/") and fs.exists("/data/gfx/shockbolt/"..image:gsub("^talents/", "portrait/")) then
					image = image:gsub("^talents/", "portrait/")
				end
				return Entity.new{name=t.name, image=image, chat_ignore_margins=true}
			else
				return Entity.new{name=actor.name, image="portrait/unknown.png", chat_ignore_margins=true}
			end
		else
			return Entity.new{name=actor.name, image="portrait/unknown.png", chat_ignore_margins=true}
		end
	end

	-- No need for anything special
	if actor.image:find("^portrait/") then return actor end

	-- Find the portrait
	if actor.isClassName and actor:isClassName("engine.Grid") and (actor.add_mos or actor.add_displays) then
		-- First one to have a portrait
		for i, mo in ripairs(actor.add_displays or {}) do
			if mo.image:find("^terrain/") and fs.exists("/data/gfx/shockbolt/"..mo.image:gsub("^terrain/", "portrait/")) then
				return Entity.new{name=actor.name, image=mo.image:gsub("^terrain/", "portrait/")}
			end
		end
		for i, mo in ripairs(actor.add_mos or {}) do
			if mo.image:find("^terrain/") and fs.exists("/data/gfx/shockbolt/"..mo.image:gsub("^terrain/", "portrait/")) then
				return Entity.new{name=actor.name, image=mo.image:gsub("^terrain/", "portrait/")}
			end
		end
		-- If not, first one
		if actor.add_displays then local mo = actor.add_displays[#actor.add_displays]
			if mo then return Entity.new{name=actor.name, image=mo.image} end
		end
		if actor.add_mos then local mo = actor.add_mos[#actor.add_mos]
			if mo then return Entity.new{name=actor.name, image=mo.image} end
		end
		-- If not, the terrain itself (how? we checked for one of add_mos & add_displays but heh)
		if actor.image:find("^terrain/") and fs.exists("/data/gfx/shockbolt/"..actor.image:gsub("^terrain/", "portrait/")) then
			return Entity.new{name=actor.name, image=actor.image:gsub("^terrain/", "portrait/")}
		end
	elseif actor.image == "invis.png" and actor.add_mos and actor.add_mos[1] and actor.add_mos[1].image and actor.add_mos[1].image:find("^npc/") and fs.exists("/data/gfx/shockbolt/"..actor.add_mos[1].image:gsub("^npc/", "portrait/")) then
		return Entity.new{name=actor.name, image=actor.add_mos[1].image:gsub("^npc/", "portrait/")}
	elseif actor.image:find("^npc/") and fs.exists("/data/gfx/shockbolt/"..actor.image:gsub("^npc/", "portrait/")) then
		return Entity.new{name=actor.name, image=actor.image:gsub("^npc/", "portrait/")}
	elseif actor.image:find("^player/") and fs.exists("/data/gfx/shockbolt/"..actor.image:gsub("^player/", "portrait/")) then
		return Entity.new{name=actor.name, image=actor.image:gsub("^player/", "portrait/")}
	elseif actor.image:find("^object/") and fs.exists("/data/gfx/shockbolt/"..actor.image:gsub("^object/", "portrait/")) then
		return Entity.new{name=actor.name, image=actor.image:gsub("^object/", "portrait/")}
	elseif actor.image:find("^object/artifact/") and fs.exists("/data/gfx/shockbolt/"..actor.image:gsub("^object/artifact/", "portrait/")) then
		return Entity.new{name=actor.name, image=actor.image:gsub("^object/artifact/", "portrait/")}
	elseif actor.image:find("^talents/") and fs.exists("/data/gfx/shockbolt/"..actor.image:gsub("^talents/", "portrait/")) then
		return Entity.new{name=actor.name, image=actor.image:gsub("^talents/", "portrait/")}
	elseif actor.image:find("^faction/") and fs.exists("/data/gfx/shockbolt/"..actor.image:gsub("^faction/", "portrait/")) then
		return Entity.new{name=actor.name, image=actor.image:gsub("^faction/", "portrait/")}
	end

	-- Last resort, use it as it is
	return actor
end
