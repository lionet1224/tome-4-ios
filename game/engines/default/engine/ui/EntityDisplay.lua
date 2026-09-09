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

--- A generic entity display
-- @classmod engine.ui.EntityDisplay
module(..., package.seeall, class.inherit(Base))

function _M:init(t)
	self.entity = t.entity
	self.w = assert(t.width, "no entity width")
	self.h = assert(t.height, "no entity height")
	self.back_color = t.back_color
	self.back_image = t.back_image

	Base.init(self, t)
end

function _M:generate()
	self.mouse:reset()
	self.key:reset()

	if self.back_image then
		self.back_texture = self:getUITexture(self.back_image)
	end
end

function _M:display(x, y)
	if not self.entity then return end

	if self.back_color then
		core.display.drawQuad(x, y, self.w, self.h, unpack(self.back_color))
	end
	if self.back_texture then
		self.back_texture.t:toScreenFull(x + (self.w - self.back_texture.w) / 2, y + (self.h - self.back_texture.h) / 2, self.back_texture.w, self.back_texture.h, self.back_texture.tw, self.back_texture.th)
	end

	self.entity:toScreen(nil, x, y, self.w, self.h)
end
