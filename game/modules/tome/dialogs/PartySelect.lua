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
require "engine.ui.Dialog"
local List = require "engine.ui.List"
local GetQuantity = require "engine.dialogs.GetQuantity"

module(..., package.seeall, class.inherit(engine.ui.Dialog))

function _M:init()
	if require("engine.TouchInput").active() then return self:initTouch() end
	self:generateList()
	engine.ui.Dialog.init(self, _t"Switch to which character?", 1, 1)

	local list = List.new{width=400, nb_items=#self.list, list=self.list, fct=function(item) self:use(item) end}

	self:loadUI{
		{left=0, top=0, ui=list},
	}
	self:setupUI(true, true)

	self.key:addCommands{ __TEXTINPUT = function(c) if self.list and self.list.chars[c] then self:use(self.list[self.list.chars[c]]) end end}
	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end, }
end

function _M:on_register()
	game:onTickEnd(function() self.key:unicodeInput(true) end)
end

function _M:use(item)
	if not item then return end
	game:unregisterDialog(self)

	game.party:select(item.actor)
end

function _M:generateList()
	local list = {}

	for i, act in ipairs(game.party.m_list) do
		if game.party:canControl(act) or game.party:canOrder(act) then
			list[#list+1] = {name=act.name, actor=act}
		end
	end

	local chars = {}
	for i, v in ipairs(list) do
		v.name = self:makeKeyChar(i)..") "..v.name
		chars[self:makeKeyChar(i)] = i
	end
	list.chars = chars

	self.list = list
end

---------------------------------------------------------------------------
-- iOS port: member cards (sprite, name, level and kind, life) in a Flow; tap = take control
---------------------------------------------------------------------------
function _M:initTouch()
	local K = require "engine.ui.TouchKit"
	local TI = require "engine.TouchInput"
	local Tiles = require "engine.Tiles"
	self.tiles = Tiles.new(64, 64, nil, nil, true, nil)
	self.members = {}
	for _, act in ipairs(game.party.m_list) do
		if game.party:canControl(act) or game.party:canOrder(act) then self.members[#self.members+1] = act end
	end
	local sa = TI.safeArea()
	self.portrait = TI.portrait()
	local w = math.floor((game.w - sa.l - sa.r) * (self.portrait and 0.94 or 0.7))
	local rows = math.max(1, #self.members)
	local h = math.min(math.floor((game.h - sa.t - sa.b) * 0.85), 40 + rows * 100)
	engine.ui.Dialog.init(self, _t"Switch to which character?", w, h)
	self.c_flow = K.Flow.new{width=self.iw, height=self.ih}
	self:loadUI{ {left=0, top=0, ui=self.c_flow} }
	self:setupUI()
	self:setFocus(self.c_flow)
	self:buildTouch()
	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end }
end

function _M:memberSub(act)
	local parts = {}
	if act.level then parts[#parts+1] = ("Level %d"):tformat(act.level) end
	local kind = act.descriptor and act.descriptor.subclass or act.subtype or act.type
	if kind then parts[#parts+1] = tostring(kind):gsub("^%l", string.upper) end
	if act.max_life and act.max_life > 0 then parts[#parts+1] = ("%d / %d life"):format(math.floor(act.life or 0), math.floor(act.max_life)) end
	if act == game.player then parts[#parts+1] = _t"in control" end
	return table.concat(parts, " · ")
end

function _M:buildTouch()
	local items = {}
	for _, act in ipairs(self.members) do
		items[#items+1] = {name=act.name, sub=self:memberSub(act), sel=(act == game.player), data=act,
			icon=function(x, y, size) pcall(act.toScreen, act, self.tiles, x, y, size, size) end,
			on_tap=function() self:use({actor=act}) end}
	end
	if #items == 0 then items[1] = {name=_t"Nobody to switch to", sub=_t"No party member can be controlled right now."} end
	self.c_flow:setSections{{title=_t"Party", items=items, cols=1, row_h=92, icon_size=64}}
end

function _M:touch_reopen() return _M.new() end

function _M:innerDisplayBack(x, y, nb_keyframes)
	if not self.c_flow then return end
	require("engine.ui.TouchKit").quad(x + self.ix, y + self.iy, self.iw, self.ih, {18, 19, 23})
end
