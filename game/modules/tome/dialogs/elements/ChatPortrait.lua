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
local Tiles = require "engine.Tiles"
local Base = require "engine.ui.Base"
local ActorFrame = require "engine.ui.ActorFrame"

--- A generic UI image
-- @classmod engine.ui.Image
module(..., package.seeall, class.inherit(Base))

function _M:init(t)
	self.side = assert(t.side, "no ChatPortrait side")
	self.actor = assert(t.actor, "no ChatPortrait actor")
	
	self.name = t.actor.getName and t.actor:getName() or _t(t.actor.name) or _t"???"
	if t.actor.moddable_tile then
		self.actor_frame = ActorFrame.new{actor=t.actor, w=128, h=128, allow_cb=false, allow_shader=false}
	elseif t.actor.image == "invis.png" and t.actor.add_mos and t.actor.add_mos[1] and t.actor.add_mos[1].image then
		self.image = Tiles:loadImage(t.actor.add_mos[1].image)
	else
		self.image = Tiles:loadImage(t.actor.image)
	end
	if self.image then
		local iw, ih = self.image:getSize()
		self.oiw, self.oih = iw, ih
		if iw <= 64 then iw, ih = iw * 2, ih * 2 end
		self.iw, self.ih = iw, ih
		if self.image.getEmptyMargins and not t.actor.ignore_margins then
			local x1, x2, y1, y2 = self.image:getEmptyMargins()
			self.iy = y1
		else
			self.iy = 0
		end
	else
		self.iy = 0
		self.iw, self.ih = 128, 128
	end

	self.h_deco = 0

	Base.init(self, t)
end

function _M:generate()
	self.mouse:reset()
	self.key:reset()

	self.front = self:getUITexture("ui/portrait_frame_front.png")
	self.back = self:getUITexture("ui/portrait_frame_back.png")
	self.deco_downs = {}
	for i in ipairs_value{16, 32, 48, 64, 80} do
		self.deco_downs[i] = self:getUITexture("ui/chat_ui_deco_padding_"..self.side.."_down_"..i..".png")
	end
	self.deco_down = nil
	self.deco_up = self:getUITexture("ui/chat_ui_deco_padding_"..self.side.."_up.png")
	self.w, self.h = self.front.w, self.front.h

	if self.actor.chat_portrait_background then
		self.back_texture = self:getUITexture(self.actor.chat_portrait_background)
		if self.actor.chat_portrait_size then
			self.iw, self.ih = self.iw * self.actor.chat_portrait_size, self.ih * self.actor.chat_portrait_size
		end
	end

	if self.image then self.item = {self.image:glTexture(false, true)} end

	self.name_tex = self:drawFontLine(self.font, self.name, nil, 0xff, 0xee, 0xcb)
end

function _M:adjustHeight(h)
	self.h_deco = h - self.back.h
	local ch = math.find_closest_lower(self.h_deco, {16, 32, 48, 64, 80})
	if not ch then
		self.deco_down = nil
	else
		self.deco_down = self.deco_downs[ch]
	end
end

function _M:display(x, y, nb_keyframes, screen_x, screen_y)
	local deco_x
	if self.deco_down and self.h_deco >= self.deco_up.h + self.deco_down.h then
		if self.side == "left" then deco_x = x + self.back.w - self.deco_up.w else deco_x = x end
		self.deco_up.t:toScreenFull(deco_x, y, self.deco_up.w, self.deco_up.h, self.deco_up.tw, self.deco_up.th)
		y = y + self.deco_up.h
		screen_y = screen_y + self.deco_up.h
	end
	if self.deco_down then
		if self.side == "left" then deco_x = x + self.back.w - self.deco_down.w else deco_x = x end
		local deco_h = math.min(self.deco_down.h, self.h_deco)
		self.deco_down.t:toScreenFull(deco_x, y + self.back.h, self.deco_down.w, deco_h, self.deco_down.tw, self.deco_down.th)
	end

	self.back.t:toScreenFull(x, y, self.back.w, self.back.h, self.back.tw, self.back.th)

	if self.back_texture then
		self.back_texture.t:toScreenFull(x + 15, y + 15, self.back_texture.w, self.back_texture.h, self.back_texture.tw, self.back_texture.th)
	end

	core.display.glScissor(true, screen_x + 15, screen_y + 15, 128, 192)
	local dx, dy = x + 15 + (128 - self.iw) / 2, y + 15 + (192 - self.ih) / 2
	if self.ih > 192 then dy = y + 15 end
	if self.actor_frame then
		self.actor_frame:display(dx, dy - self.iy)
	elseif self.item then
		self.item[1]:toScreenFull(dx, dy - self.iy, self.iw, self.ih, self.item[2] * self.iw / self.oiw, self.item[3] * self.ih / self.oih)
	end
	core.display.glScissor(false)

	self.front.t:toScreenFull(x, y, self.front.w, self.front.h, self.front.tw, self.front.th)

	core.display.glScissor(true, screen_x + 4, screen_y + 229, 152, 23)
	-- Center if it fits, left align is not
	if self.name_tex.w <= 153 then
		self:textureToScreen(self.name_tex, x + 80 - self.name_tex.w / 2, y + 240 - self.name_tex.h / 2)
	else
		self:textureToScreen(self.name_tex, x + 4, y + 240 - self.name_tex.h / 2)
	end
	core.display.glScissor(false)
end
