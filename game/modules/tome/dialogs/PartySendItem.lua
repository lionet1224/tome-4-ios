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

module(..., package.seeall, class.inherit(engine.ui.Dialog))

function _M:init(source, o, inven, item, on_end)
	if require("engine.TouchInput").active() then return self:initTouch(source, o, inven, item, on_end) end
	self:generateList()
	self.on_end = on_end
	self.source = source
	self.inven = inven
	self.item = item
	self.o = o
	engine.ui.Dialog.init(self, _t"Give item to a party member", 1, 1)

	local list = List.new{width=400, nb_items=#self.list, list=self.list, fct=function(item) self:use(item) end}

	self:loadUI{
		{left=0, top=0, ui=list},
	}
	self:setupUI(true, true)

	self.key:addCommands{ __TEXTINPUT = function(c) if self.list and self.list.chars[c] then self:use(self.list[self.list.chars[c]]) end end}
	self.key:addBinds{
		EXIT = function() game:unregisterDialog(self) end,
	}
end

function _M:on_register()
	game:onTickEnd(function() self.key:unicodeInput(true) end)
end

function _M:use(item)
	if not item or not item.actor:canAddToInven(item.actor.INVEN_INVEN) or (item.actor:attr("sleep") and not item.actor:attr("lucid_dreamer")) then
		game.log("%s cannot receive items while asleep!", item.actor:getName():capitalize())
		return
	end
	if self.source:attr("sleep") and not self.source:attr("lucid_dreamer") then
		game.log("%s cannot transfer items while asleep!", self.source:getName():capitalize())
		return 
	end
	game:unregisterDialog(self)
	self.source:removeObject(self.inven, self.item, true)
	self.source:sortInven(self.inven)
	self.o.__transmo = nil
	item.actor:addObject(item.actor.INVEN_INVEN, self.o, true) -- force full stack transfer
	game.log("You give %s to %s.", self.o:getName{do_color=true}, item.actor:getName())
	item.actor:sortInven(item.actor.INVEN_INVEN)
	self.on_end()
end

function _M:generateList()
	local list = {}

	for i, act in ipairs(game.party.m_list) do
		if not act.no_inventory_access and act ~= game.player and act:getInven(act.INVEN_INVEN) then
			local warn = act:attr("sleep") and not act:attr("lucid_dreamer") and _t" #YELLOW#[SLEEPING]#LAST#" or ""
			if not act:canAddToInven(act.INVEN_INVEN) then warn = _t" #YELLOW#[NO ROOM]#LAST#" end
			list[#list+1] = {name=act.name..warn, actor=act}
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
-- iOS port: who gets the item: member cards with a warning line, tap = give
-- (same checks and transfer as the desktop list)
---------------------------------------------------------------------------
function _M:initTouch(source, o, inven, item, on_end)
	local K = require "engine.ui.TouchKit"
	local TI = require "engine.TouchInput"
	local Tiles = require "engine.Tiles"
	self.tiles = Tiles.new(64, 64, nil, nil, true, nil)
	self.on_end = on_end
	self.source = source
	self.inven = inven
	self.item = item
	self.o = o
	self.touch_args = {source, o, inven, item, on_end}
	self.recipients = {}
	for _, act in ipairs(game.party.m_list) do
		if not act.no_inventory_access and act ~= game.player and act:getInven(act.INVEN_INVEN) then
			local warn
			if act:attr("sleep") and not act:attr("lucid_dreamer") then warn = _t"asleep: cannot receive items" end
			if not act:canAddToInven(act.INVEN_INVEN) then warn = _t"no room" end
			self.recipients[#self.recipients+1] = {actor=act, warn=warn}
		end
	end
	local sa = TI.safeArea()
	self.portrait = TI.portrait()
	local w = math.floor((game.w - sa.l - sa.r) * (self.portrait and 0.94 or 0.7))
	local rows = math.max(1, #self.recipients)
	local h = math.min(math.floor((game.h - sa.t - sa.b) * 0.85), 40 + rows * 96)
	engine.ui.Dialog.init(self, ("Give %s to"):tformat(o:getName{do_color=true, no_count=true}), w, h)
	self.c_flow = K.Flow.new{width=self.iw, height=self.ih}
	self:loadUI{ {left=0, top=0, ui=self.c_flow} }
	self:setupUI()
	self:setFocus(self.c_flow)
	local items = {}
	for _, r in ipairs(self.recipients) do
		local act = r.actor
		local sub = r.warn or ("Level %d · %d / %d life"):format(act.level or 1, math.floor(act.life or 0), math.floor(act.max_life or 0))
		items[#items+1] = {name=act.name, sub=sub, data=act, locked=(r.warn ~= nil),
			icon=function(x, y, size) pcall(act.toScreen, act, self.tiles, x, y, size, size) end,
			on_tap=function() self:use({actor=act}) end}
	end
	if #items == 0 then items[1] = {name=_t"Nobody can carry it", sub=_t"No party member has a pack."} end
	self.c_flow:setSections{{title=_t"Party members", items=items, cols=1, row_h=88, icon_size=64}}
	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end }
end

function _M:touch_reopen()
	local a = self.touch_args
	return _M.new(a[1], a[2], a[3], a[4], a[5])
end

function _M:innerDisplayBack(x, y, nb_keyframes)
	if not self.c_flow then return end
	require("engine.ui.TouchKit").quad(x + self.ix, y + self.iy, self.iw, self.ih, {18, 19, 23})
end
