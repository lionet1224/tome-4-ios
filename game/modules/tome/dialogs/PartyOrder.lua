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

local orders = {
	escort_rest = {-100, function(actor) return _t"Wait a few turns" end},
	escort_portal = {-99, function(actor) return _t"Where is the portal?" end},
	target = {1, function(actor) return ("Set the target [current: %s]"):tformat(actor.ai_target.actor and actor.ai_target.actor:getName() or _t"none") end},
	behavior = {2, function(actor) return ("Set behavior [current: %s]"):tformat(_t(actor.ai_tactic.type) or _t"default") end},
	anchor = {3, function(actor) return ("Set the leash anchor [current: %s]"):tformat(actor.ai_state.tactic_leash_anchor and _t(actor.ai_state.tactic_leash_anchor.name) or _t"none") end},
	leash = {4, function(actor) return ("Set the leash distance [current: %d]"):tformat(actor.ai_state.tactic_leash) end},
	talents = {5, function(actor) return (_t"Define tactical talents usage") end},
	rename = {6, function(actor) return (_t"Rename") end},
	dismiss = {7, function(actor) return (_t"Dismiss") end},
	pet_hound = {8, function(actor) return (_t"Pet the hound") end},
}

function _M:init(actor, def)
	if require("engine.TouchInput").active() then return self:initTouch(actor, def) end
	self.actor = actor
	self.def = def
	self:generateList()
	engine.ui.Dialog.init(self, ("Order: %s"):tformat(actor:getName()), 1, 1)

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

	game.party:giveOrder(self.actor, item.order)
end

function _M:generateList()
	local list = {}

	if not _M.additional_hook_fired then
		_M.additional_hook_fired = true
		self:triggerHook{"PartyOrder:define", orders=orders}
	end

	for o, _ in pairs(self.def.orders) do
		if orders[o] then
			list[#list+1] = {name=orders[o][2](self.actor), order=o, sort=orders[o][1]}
		end
	end
	table.sort(list, function(a,b) return a.sort < b.sort end)

	local chars = {}
	for i, v in ipairs(list) do
		v.name = self:makeKeyChar(i)..") "..v.name
		chars[self:makeKeyChar(i)] = i
	end
	list.chars = chars

	self.list = list
end

---------------------------------------------------------------------------
-- iOS port: the orders as cards; tap gives the order exactly as the desktop list did
---------------------------------------------------------------------------
function _M:initTouch(actor, def)
	local K = require "engine.ui.TouchKit"
	local TI = require "engine.TouchInput"
	self.actor = actor
	self.def = def
	self.touch_args = {actor, def}
	if not _M.additional_hook_fired then
		_M.additional_hook_fired = true
		self:triggerHook{"PartyOrder:define", orders=orders}
	end
	self.orders_list = {}
	for o, _ in pairs(def.orders or {}) do
		if orders[o] then self.orders_list[#self.orders_list+1] = {name=orders[o][2](actor), order=o, sort=orders[o][1]} end
	end
	table.sort(self.orders_list, function(a, b) return a.sort < b.sort end)
	local sa = TI.safeArea()
	self.portrait = TI.portrait()
	local w = math.floor((game.w - sa.l - sa.r) * (self.portrait and 0.94 or 0.7))
	local rows = math.max(1, #self.orders_list)
	local h = math.min(math.floor((game.h - sa.t - sa.b) * 0.85), 40 + rows * 72)
	engine.ui.Dialog.init(self, ("Order: %s"):tformat(actor:getName()), w, h)
	self.c_flow = K.Flow.new{width=self.iw, height=self.ih}
	self:loadUI{ {left=0, top=0, ui=self.c_flow} }
	self:setupUI()
	self:setFocus(self.c_flow)
	local items = {}
	for _, it in ipairs(self.orders_list) do
		-- "Set behavior [current: x]" -> name "Set behavior", sub "current: x"
		local name, cur = tostring(it.name):match("^(.-)%s*%[(.-)%]%s*$")
		items[#items+1] = {name=name or it.name, sub=cur, data=it, on_tap=function() self:use(it) end}
	end
	if #items == 0 then items[1] = {name=_t"No orders available", sub=_t"This companion takes no orders."} end
	self.c_flow:setSections{{title=_t"Orders", items=items, cols=1, row_h=64}}
	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end }
end

function _M:touch_reopen() return _M.new(self.touch_args[1], self.touch_args[2]) end

function _M:innerDisplayBack(x, y, nb_keyframes)
	if not self.c_flow then return end
	require("engine.ui.TouchKit").quad(x + self.ix, y + self.iy, self.iw, self.ih, {18, 19, 23})
end
