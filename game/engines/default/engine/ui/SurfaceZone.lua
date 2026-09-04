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
local Base = require "engine.ui.Base"
local Focusable = require "engine.ui.Focusable"

--- A generic UI surface zone
-- @classmod engine.ui.SurfaceZone
module(..., package.seeall, class.inherit(Base, Focusable))

function _M:init(t)
	self.w = assert(t.width, "no surface zone width")
	self.h = assert(t.height, "no surface zone height")
	self.alpha = t.alpha or 200
	-- iOS port: scroll_h = a content surface taller than the visible zone; the
	-- zone then scrolls (finger drag via engine.ui.Dialog, wheel here)
	self.content_h = (t.scroll_h and t.scroll_h > self.h) and math.floor(t.scroll_h) or self.h
	if self.content_h > self.h then
		self.scrollbar = {pos=0, max=self.content_h - self.h, w=0}
		self.can_focus_mouse = true
	end

	self.s = core.display.newSurface(self.w, self.content_h)

	self.texture, self.texture_w, self.texture_h = self.s:glTexture()

	self.color = t.color or {r=255, g=255, b=255}

	Base.init(self, t)
end

function _M:generate()
	self.mouse:reset()
	self.key:reset()

	self.s:updateTexture(self.texture)

	if self.scrollbar then
		self.mouse:registerZone(0, 0, self.w, self.h, function(button, x, y, xrel, yrel, bx, by, event)
			if event == "button" and button == "wheelup" then self.scrollbar.pos = util.bound(self.scrollbar.pos - 40, 0, self.scrollbar.max)
			elseif event == "button" and button == "wheeldown" then self.scrollbar.pos = util.bound(self.scrollbar.pos + 40, 0, self.scrollbar.max) end
		end)
	end
	self.can_focus = false
end

function _M:update()
	self.s:updateTexture(self.texture)
end

function _M:display(x, y)
	if self.scrollbar then
		local pos = util.bound(self.scrollbar.pos or 0, 0, self.scrollbar.max)
		self.scrollbar.pos = pos
		local u2 = self.w / self.texture_w
		local v1, v2 = pos / self.texture_h, (pos + self.h) / self.texture_h
		if self.text_shadow then self.texture:toScreenPrecise(x+2, y+2, self.w, self.h, 0, u2, v1, v2, 0, 0, 0, self.text_shadow) end
		self.texture:toScreenPrecise(x, y, self.w, self.h, 0, u2, v1, v2)
		return
	end
	if self.text_shadow then self.texture:toScreenFull(x+2, y+2, self.w, self.h, self.texture_w, self.texture_h, 0, 0, 0, self.text_shadow) end
	self.texture:toScreenFull(x, y, self.w, self.h, self.texture_w, self.texture_h)
end
