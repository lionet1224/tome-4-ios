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
local Base = require "engine.dialogs.ShowPickupFloor"
local Dialog = require "engine.ui.Dialog"
local Button = require "engine.ui.Button"
local TextzoneList = require "engine.ui.TextzoneList"
local TouchItemList = require "mod.dialogs.elements.TouchItemList"
local K = require "engine.ui.TouchKit"

module(..., package.seeall, class.inherit(Base))

local function touchActive()
	local ok, TI = pcall(require, "engine.TouchInput")
	return ok and TI and TI.active and TI.active()
end

function _M:init(...)
	-- iOS port: finger rows, tap = take, hold = read; see initTouch
	if touchActive() then return self:initTouch(...) end
	Base.init(self, ...)

	self.key.any_key = function(sym)
		-- Control resets the tooltip
		if (sym == self.key._LCTRL or sym == self.key._RCTRL) and self.cur_item then self.cur_item.desc = nil self:select(self.cur_item) end
	end

	for i, item in ipairs(self.list) do item.desc = nil end

	self:select(self.list[1])
end

function _M:select(item)
	if item then
		self.cur_item = item
		if not item.desc or item.ctrl_state ~= core.key.modState("ctrl") then
			item.ctrl_state = core.key.modState("ctrl")
			item.desc = item.object:getDesc({do_color=true}, self.actor:getInven(item.object:wornInven()))
			self.c_desc:createItem(item, item.desc)
		end
		self.c_desc:switchItem(item, item.desc)
	end
end

function _M:updateTitle(title)
	Base.updateTitle(self, title)

	local green = colors.LIGHT_GREEN
	local red = colors.LIGHT_RED

	local enc, max = self.actor:getEncumbrance(), self.actor:getMaxEncumbrance()
	local v = math.min(enc, max) / max
	self.title_fill = self.iw * v
	self.title_fill_color = {
		r = util.lerp(green.r, red.r, v),
		g = util.lerp(green.g, red.g, v),
		b = util.lerp(green.b, red.b, v),
	}
end

function _M:drawFrame(x, y, r, g, b, a)
	Base.drawFrame(self, x, y, r, g, b, a)
	if r == 0 then return end -- Drawing the shadow
	if self.ui ~= "metal" then return end
	if not self.title_fill then return end

	core.display.drawQuad(x + self.frame.title_x, y + self.frame.title_y, self.title_fill, self.frame.title_h, self.title_fill_color.r, self.title_fill_color.g, self.title_fill_color.b, 60)
end

------------------------------------------------------------------------
-- iOS port: touch layout. Rows are TouchItemList entries (icon, name,
-- subtitle, better/worse tag against worn gear); a tap takes the item, a
-- hold shows its description in the right pane. Take all / Done are big
-- buttons. Same action/filter/takeAll semantics as the desktop dialog.
------------------------------------------------------------------------
function _M:initTouch(title, x, y, filter, action, takeall, actor)
	self.touch = true
	self.x, self.y = x, y
	self.filter = filter
	self.action = action
	self.actor = actor
	self.touch_args = {title=title, x=x, y=y, filter=filter, action=action, takeall=takeall, actor=actor}
	self.bigfont = K.font(22)
	self.portrait = require("engine.TouchInput").portrait()
	Dialog.init(self, _t"On the floor", game.w * 0.96, game.h * 0.9)

	local gap, pane_w, bh = 12, 380, 56
	local takeall_txt = takeall and tostring(takeall):gsub("^%(%*%)%s*", "") or _t"Take all"
	if self.portrait then
		-- portrait: rows fill the width, the pane becomes a bottom sheet
		self.sheet_h = 400
		self.sheet_y = self.ih - self.sheet_h
		self.pane_w = self.iw
		self.c_list = TouchItemList.new{width=self.iw, height=self.sheet_y - gap, actor=actor, scrollbar=true, items={},
			on_select=function(e) self:use(e) end, on_use=function(e) self:showDesc(e) end}
		local dh = self.sheet_h - bh * 2 - 16 - 40
		self.c_desc = TextzoneList.new{focus_check=true, scrollbar=true, width=self.iw - 16, height=dh, dest_area={h=dh}}
		-- Button adds 16 px of frame to the requested width
		self.b_all = Button.new{text=takeall_txt, width=self.iw - 16, font=self.bigfont, fct=function() self:takeAll() end}
		self.b_done = Button.new{text=_t"Done", width=self.iw - 16, font=self.bigfont, fct=function() game:unregisterDialog(self) end}

		self:generateList()

		self:loadUI{
			{left=0, top=0, ui=self.c_list},
			{left=8, top=self.sheet_y + 40, ui=self.c_desc},
			{left=0, bottom=bh + 8, ui=self.b_all},
			{left=0, bottom=0, ui=self.b_done},
		}
	else
	self.pane_w = pane_w
	self.c_list = TouchItemList.new{width=self.iw - pane_w - gap, height=self.ih, actor=actor, scrollbar=true, items={},
		on_select=function(e) self:use(e) end, on_use=function(e) self:showDesc(e) end}
	local dh = self.ih - bh * 2 - 16 - 40
	self.c_desc = TextzoneList.new{focus_check=true, scrollbar=true, width=pane_w - 16, height=dh, dest_area={h=dh}}
	self.b_all = Button.new{text=takeall_txt, width=pane_w, font=self.bigfont, fct=function() self:takeAll() end}
	self.b_done = Button.new{text=_t"Done", width=pane_w, font=self.bigfont, fct=function() game:unregisterDialog(self) end}

	self:generateList()

	local px = self.iw - pane_w
	self:loadUI{
		{left=0, top=0, ui=self.c_list},
		{left=px + 8, top=40, ui=self.c_desc},
		{left=px, bottom=bh + 8, ui=self.b_all},
		{left=px, bottom=0, ui=self.b_done},
	}
	end
	self:setFocus(self.c_list)
	self:setupUI()
	self.key:addBinds{
		EXIT = function() game:unregisterDialog(self) end,
	}
	self:showDesc(nil)
end

--- Rotation: a fresh touch dialog for the new orientation, same item read about
function _M:touch_reopen()
	if not self.touch then return nil end
	local a = self.touch_args
	local nd = _M.new(a.title, a.x, a.y, a.filter, a.action, a.takeall, a.actor)
	if self.cur_item and self.cur_item.object then
		for _, e in ipairs(nd.list) do if e.object == self.cur_item.object then nd:showDesc(e) end end
	end
	return nd
end

-- the desktop dialog turns the keyboard on for letter shortcuts: not on a phone
function _M:on_register()
	if self.touch then return end
	return Base.on_register(self)
end

function _M:showDesc(e)
	if not self.touch then return end
	self.cur_item = e
	local desc
	if e and e.object then
		local ok, d = pcall(e.object.getDesc, e.object, {do_color=true}, self.actor and self.actor:getInven(e.object:wornInven()) or nil)
		desc = ok and d or tostring(e.object.name)
	else
		desc = _t"Tap an item to take it. Hold one to read about it first."
	end
	self.c_desc:switchItem(e or desc, desc)
end

function _M:generateList()
	if not self.touch then return Base.generateList(self) end
	local list = {}
	list.chars = {}
	local idx = 1
	while true do
		local o = game.level.map:getObject(self.x, self.y, idx)
		if not o then break end
		if not self.filter or self.filter(o) then
			list[#list+1] = { object=o, item=idx, name=o:getName() }
		end
		idx = idx + 1
	end
	self.list = list
	self.c_list:setItems(self.list)
	self.c_list.last_tap_i = nil -- a quick second tap must take the next row, not open a description
	self:updateTitle((_t"On the floor (%d)"):format(#list))
end

function _M:used()
	if not self.touch then return Base.used(self) end
	if self.taking_all then return end
	self:generateList()
	if #self.list == 0 then
		game:unregisterDialog(self)
		return false
	end
	if self.cur_item then
		-- the item read about may be gone now
		local still
		for _, e in ipairs(self.list) do if e.object == self.cur_item.object then still = e end end
		self:showDesc(still)
	end
	return true
end

function _M:innerDisplayBack(x, y, nb_keyframes)
	if not self.touch then return end
	local px, py
	if self.portrait then
		px, py = x + self.ix, y + self.iy + self.sheet_y
		K.quad(px, py, self.iw, self.sheet_h, K.PANE)
	else
		px, py = x + self.ix + self.iw - self.pane_w, y + self.iy
		K.quad(px, py, self.pane_w, self.ih, K.PANE)
	end
	if self.actor and self.actor.getEncumbrance then
		local enc, max = self.actor:getEncumbrance(), self.actor:getMaxEncumbrance()
		local heavy = enc > max
		K.draw(K.text((_t"Carrying %d / %d"):format(enc, max), 14, heavy and 224 or 142, heavy and 122 or 136, heavy and 106 or 120, true), px + 8, py + 12)
	end
end
