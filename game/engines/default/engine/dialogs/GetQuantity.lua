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
local Module = require "engine.Module"
local Dialog = require "engine.ui.Dialog"
local Button = require "engine.ui.Button"
local Numberbox = require "engine.ui.Numberbox"

--- Generic popup for getting quantity
-- @classmod engine.dialogs.GetQuantity
module(..., package.seeall, class.inherit(Dialog))

function _M:init(title, prompt, default, max, action, min)
	self.action = action
	-- iOS port: finger layout (drag bar, steppers, chips), no keyboard
	local okti, TI = pcall(require, "engine.TouchInput")
	if okti and TI.active and TI.active() then return self:initTouch(title, prompt, default, max, min) end

	Dialog.init(self, title or _t"Quantity", 320, 110)

	local c_box = Numberbox.new{title=prompt and (prompt..": ") or "", number=default or 0, max=max, min=min, chars=10, fct=function(text) self:okclick() end}
	self.c_box = c_box
	local ok = require("engine.ui.Button").new{text=_t"Accept", fct=function() self:okclick() end}
	local cancel = require("engine.ui.Button").new{text=_t"Cancel", fct=function() self:cancelclick() end}

	self:loadUI{
		{left=0, top=0, padding_h=10, ui=c_box},
		{left=0, bottom=0, ui=ok},
		{right=0, bottom=0, ui=cancel},
	}
	self:setFocus(c_box)
	self:setupUI(true, true)

	self.key:addBinds{
		EXIT = function() game:unregisterDialog(self) end,
	}
end

function _M:okclick()
	self.qty = self.c_box.number
	if self.qty then
		game:unregisterDialog(self)
		self.action(self.qty)
	else
		Dialog:simplePopup(_t"Error", _t"Enter a quantity.")
	end
end

function _M:cancelclick()
	self.key:triggerVirtual("EXIT")
end

------------------------------------------------------------------------
-- Touch layout
------------------------------------------------------------------------
local Base = require "engine.ui.Base"
local Focusable = require "engine.ui.Focusable"

-- a drag bar: tap or drag along it to set `number` between min and max
local Bar = class.inherit(Base, Focusable){}
function Bar:init(t)
	self.w, self.h = t.width, 64
	self.min, self.max = t.min, t.max
	self.number = t.number
	self.on_change = t.on_change
	Base.init(self, t)
end
function Bar:generate()
	self.mouse:reset()
	self.key:reset()
	self.mouse:registerZone(0, 0, self.w, self.h, function(button, x, y, xrel, yrel, bx, by, event)
		if event == "button" and button == "left" then self:setFromX(x) end
	end)
end
function Bar:setFromX(x)
	local pad = 12
	local f = util.bound((x - pad) / math.max(1, self.w - 2 * pad), 0, 1)
	self:set(self.min + f * (self.max - self.min))
end
function Bar:set(v)
	v = util.bound(math.floor(v + 0.5), self.min, self.max)
	if v ~= self.number then self.number = v if self.on_change then self.on_change(v) end end
end
function Bar:display(x, y, nb_keyframes, screen_x, screen_y)
	self.last_screen_x, self.last_screen_y = screen_x, screen_y
	-- a plain finger drag never reaches the mouse zone (the dialog swallows it): read the finger directly
	local okti, TI = pcall(require, "engine.TouchInput")
	local t = okti and TI.t
	if t and t.moved and not t.held and screen_x and t.x0 >= screen_x and t.x0 < screen_x + self.w and t.y0 >= screen_y - 20 and t.y0 < screen_y + self.h + 20 then
		self:setFromX(t.x - screen_x)
	end
	local K = require "engine.ui.TouchKit"
	local pad = 12
	local tw = self.w - 2 * pad
	local f = (self.max > self.min) and (self.number - self.min) / (self.max - self.min) or 1
	local cy = y + self.h / 2
	K.quad(x + pad, cy - 6, tw, 12, {40, 43, 52})
	K.quad(x + pad, cy - 6, math.floor(tw * f), 12, K.GOLD)
	local kx = x + pad + tw * f
	K.circle(kx, cy, 22, {20, 22, 28})
	K.circle(kx, cy, 18, K.GOLD)
	local dmin = K.text(tostring(self.min), 13, 142, 136, 120)
	local dmax = K.text(tostring(self.max), 13, 142, 136, 120)
	if dmin then K.draw(dmin, x + pad, y + self.h - 16) end
	if dmax then K.draw(dmax, x + self.w - pad - dmax.w, y + self.h - 16) end
end

function _M:initTouch(title, prompt, default, max, min)
	local K = require "engine.ui.TouchKit"
	self.min = min or 0
	self.max = max or math.huge
	if self.max == math.huge then self.max = math.max(self.min + 1, (default or 0) * 4, 100) end -- unbounded: give the bar a sane reach
	self.prompt = prompt
	-- >720 wide on purpose: keeps clear of the generic 1.5x small-dialog scaling
	Dialog.init(self, title or _t"Quantity", 760, 400)
	local bigfont = K.font(26)
	self.c_bar = Bar.new{width=self.iw - 2 * 76 - 16, min=self.min, max=self.max, number=util.bound(default or self.min, self.min, self.max)}
	self.c_box = self.c_bar -- okclick reads .number
	local function step(d) return function() self.c_bar:set(self.c_bar.number + d) end end
	self.b_minus = Button.new{text="  -  ", width=68, font=bigfont, fct=step(-1)}
	self.b_plus = Button.new{text="  +  ", width=68, font=bigfont, fct=step(1)}
	local cw = math.floor((self.iw - 16) / 3)
	self.b_one = Button.new{text=_t"1", width=cw, font=bigfont, fct=function() self.c_bar:set(math.max(self.min, 1)) end}
	self.b_half = Button.new{text=_t"Half", width=cw, font=bigfont, fct=function() self.c_bar:set(math.floor((self.min + self.max) / 2)) end}
	self.b_all = Button.new{text=_t"All", width=cw, font=bigfont, fct=function() self.c_bar:set(self.max) end}
	local bw = math.floor((self.iw - 8) / 2)
	self.b_cancel = Button.new{text=_t"Cancel", width=bw, font=bigfont, fct=function() self:cancelclick() end}
	self.b_ok = Button.new{text=_t"OK", width=bw, font=bigfont, fct=function() self:okclick() end}
	self.bar_top = 118
	self:loadUI{
		{left=0, top=self.bar_top, ui=self.b_minus},
		{left=76, top=self.bar_top - 6, ui=self.c_bar},
		{right=0, top=self.bar_top, ui=self.b_plus},
		{left=0, top=self.bar_top + 76, ui=self.b_one},
		{left=cw + 8, top=self.bar_top + 76, ui=self.b_half},
		{right=0, top=self.bar_top + 76, ui=self.b_all},
		{left=0, bottom=0, ui=self.b_cancel},
		{right=0, bottom=0, ui=self.b_ok},
	}
	self:setupUI()
	self:setFocus(self.c_bar)
	self.key:addBinds{
		EXIT = function() game:unregisterDialog(self) end,
		ACCEPT = function() self:okclick() end,
		MOVE_LEFT = step(-1), MOVE_RIGHT = step(1),
	}
end

function _M:innerDisplayBack(x, y, nb_keyframes)
	if not self.c_bar then return end
	local K = require "engine.ui.TouchKit"
	x, y = x + self.ix, y + self.iy
	if self.prompt and self.prompt ~= "" then
		local d = K.text(self.prompt, 16, 142, 136, 120, false, self.iw)
		if d then K.draw(d, x + (self.iw - d.w) / 2, y + 6) end
	end
	local d = K.text(tostring(self.c_bar.number), 48, 240, 212, 138, true)
	if d then K.draw(d, x + (self.iw - d.w) / 2, y + 34) end
end
