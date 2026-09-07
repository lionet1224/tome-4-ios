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
local ListColumns = require "engine.ui.ListColumns"
local TextzoneList = require "engine.ui.TextzoneList"
local Separator = require "engine.ui.Separator"
local Image = require "engine.ui.Image"

module(..., package.seeall, class.inherit(Dialog))

function _M:init(party)
	if require("engine.TouchInput").active() then return self:initTouch(party) end
	self.party = party

	Dialog.init(self, _t"Ingredients collected", game.w * 0.8, game.h * 0.8)

	self.c_desc = TextzoneList.new{width=math.floor(self.iw / 2 - 10), scrollbar=true, height=self.ih}

	self:generateList()

	local vsep = Separator.new{dir="horizontal", size=self.ih - 10}
	self.c_list = ListColumns.new{width=math.floor(self.iw / 2 - vsep.w / 2), height=self.ih - 10, scrollbar=true, sortable=true, columns={
		{name=_t"Ingredient", width=50, display_prop="name", sort="name"},
		{name=_t"Category", width=30, display_prop="cat", sort="cat"},
		{name=_t"Quantity", width=20, display_prop="nb", sort="nb"},
	}, list=self.list, fct=function(item) end, select=function(item, sel) self:select(item) end}

	self:loadUI{
		{left=0, top=0, ui=self.c_list},
		{right=0, top=0, ui=self.c_desc},
		{hcenter=0, top=5, ui=vsep},
	}
	self:setFocus(self.c_list)
	self:setupUI()
	self:select(self.list[1])

	self.key:addBinds{
		EXIT = function() game:unregisterDialog(self) end,
	}
end

function _M:generateList()
	-- Makes up the list
	local list = {}
	local i = 0
	for id, nb in pairs(self.party.ingredients) do
		local d = self.party:getIngredient(id)
		list[#list+1] = { id=id, ent=d.display_entity, plain=_t(d.name, "entity name"), dname=d.name, name=d.display_entity:getDisplayString(true):add(_t(d.name, "entity name")), desc=util.getval(d.desc), cat=_t(d.type, "entity type"), nb=nb==-1 and "inf" or tostring(nb) }
		i = i + 1
	end
	-- Add known artifacts
	table.sort(list, function(a, b) return a.dname < b.dname end)
	self.list = list
end

function _M:select(item)
	if item then
		self.c_desc:switchItem(item, ("#GOLD#Category:#AQUAMARINE# %s\n#GOLD#Ingredient:#0080FF# %s\n#GOLD#Quantity:#0080FF# %s\n#GOLD#Text:#ANTIQUE_WHITE# %s"):tformat(item.cat, item.name:toString(), item.nb, item.desc))
	end
end

---------------------------------------------------------------------------
-- iOS port: ingredient cards (icon, name, category · count) and the description
-- in a bottom sheet (portrait) or a right pane (landscape)
---------------------------------------------------------------------------
function _M:initTouch(party)
	local K = require "engine.ui.TouchKit"
	local TI = require "engine.TouchInput"
	local Tiles = require "engine.Tiles"
	self.party = party
	self.tiles = Tiles.new(64, 64, nil, nil, true, nil)
	self.touch_args = {party}
	self:generateList()
	local sa = TI.safeArea()
	self.portrait = TI.portrait()
	local w = math.floor((game.w - sa.l - sa.r) * 0.94)
	local h = math.floor((game.h - sa.t - sa.b) * 0.9)
	Dialog.init(self, _t"Ingredients collected", w, h)
	if self.portrait then
		self.sheet_h = 300
		self.sheet_y = self.ih - self.sheet_h
		self.c_flow = K.Flow.new{width=self.iw, height=self.sheet_y - 8}
		local dh = self.sheet_h - 16
		self.c_desc = TextzoneList.new{focus_check=true, scrollbar=true, width=self.iw - 16, height=dh, dest_area={h=dh}}
		self:loadUI{
			{left=0, top=0, ui=self.c_flow},
			{left=8, top=self.sheet_y + 8, ui=self.c_desc},
		}
	else
		self.list_w = math.floor(self.iw * 0.55)
		self.c_flow = K.Flow.new{width=self.list_w, height=self.ih}
		local dw = self.iw - self.list_w - 16 - 8
		self.c_desc = TextzoneList.new{focus_check=true, scrollbar=true, width=dw, height=self.ih - 16, dest_area={h=self.ih - 16}}
		self:loadUI{
			{left=0, top=0, ui=self.c_flow},
			{left=self.list_w + 16, top=8, ui=self.c_desc},
		}
	end
	self:setupUI()
	self:setFocus(self.c_flow)
	self:buildTouch()
	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end }
end

function _M:buildTouch()
	local items = {}
	for _, it in ipairs(self.list) do
		local d = self.party:getIngredient(it.id or "") or nil
		items[#items+1] = {name=it.plain or tostring(it.dname), sub=("%s · %s"):format(tostring(it.cat), it.nb == "inf" and _t"unlimited" or it.nb), data=it,
			icon=it.ent and function(x, y, size) pcall(it.ent.toScreen, it.ent, self.tiles, x, y, size, size) end or nil,
			on_tap=function() self:select(it) self.cur = it end}
	end
	if #items == 0 then
		items[1] = {name=_t"No ingredients yet", sub=_t"Alchemists' quest ingredients you collect will be listed here."}
	end
	self.c_flow:setSections{{title=_t"Ingredients", items=items, cols=self.portrait and 1 or nil, min_w=240, row_h=72, icon_size=44}}
	if self.list[1] then self:select(self.list[1]) self.cur = self.list[1] end
end

function _M:touch_reopen()
	local d = _M.new(self.touch_args[1])
	if self.cur and d.list then for _, it in ipairs(d.list) do if it.dname == self.cur.dname then d:select(it) d.cur = it break end end end
	return d
end

function _M:innerDisplayBack(x, y, nb_keyframes)
	if not self.c_flow then return end
	local K = require "engine.ui.TouchKit"
	if self.portrait then
		K.quad(x + self.ix, y + self.iy, self.iw, self.sheet_y - 8, {18, 19, 23})
		K.quad(x + self.ix, y + self.iy + self.sheet_y, self.iw, self.sheet_h, {26, 28, 34})
	else
		K.quad(x + self.ix, y + self.iy, self.list_w, self.ih, {18, 19, 23})
		K.quad(x + self.ix + self.list_w + 8, y + self.iy, self.iw - self.list_w - 8, self.ih, {26, 28, 34})
	end
end
