-- ToME - Tales of Maj'Eyal
-- iOS port: shops as a touch screen: Buy / Sell tabs, finger-sized rows with
-- prices, the description on the right, one big button.

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local Button = require "engine.ui.Button"
local Tabs = require "engine.ui.Tabs"
local TextzoneList = require "engine.ui.TextzoneList"
local FontPackage = require "engine.FontPackage"
local TouchItemList = require "mod.dialogs.elements.TouchItemList"

module(..., package.seeall, class.inherit(Dialog))

function _M:init(title, store_inven, actor_inven, store_filter, actor_filter, action, desc, descprice, allow_sell, allow_buy, on_select, store_actor, actor_actor)
	self.touch_args = {title, store_inven, actor_inven, store_filter, actor_filter, action, desc, descprice, allow_sell, allow_buy, on_select, store_actor, actor_actor}
	self.portrait = require("engine.TouchInput").portrait()
	self.on_select = on_select
	self.allow_sell, self.allow_buy = allow_sell, allow_buy
	self.action = action
	self.desc = desc
	self.descprice = descprice
	self.store_inven = store_inven
	self.actor_inven = actor_inven
	self.store_filter = store_filter
	self.actor_filter = actor_filter
	self.store_actor = store_actor
	self.actor_actor = actor_actor
	self.base_title = title or _t"Store"
	self.mode = "buy"
	self.bigfont = core.display.newFont(FontPackage:getFont("default"), 22)
	Dialog.init(self, self:getStoreTitle(), game.w * 0.96, game.h * 0.96)
	self:build()
	self:loadUI(self.uis_def)
	self:setupUI()
	self:refresh()
	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end }
end

function _M:getStoreTitle()
	return self.base_title..(" (pays up to %0.2f gold, your gold: %0.2f)"):tformat(self.store_actor.store.purse, self.actor_actor.money)
end

function _M:build()
	self.c_tabs = Tabs.new{width=self.iw, tabs={{title=_t"Buy", kind="buy"}, {title=_t"Sell", kind="sell"}}, on_change=function(kind) self.mode = kind self.cur = nil if self.c_list then self.c_desc:erase() self:refresh() end end}
	local bh = 56
	if self.portrait then
		-- portrait: Buy / Sell tabs on top, the list fills the width, the description
		-- and the action button are a bottom sheet
		self.sheet_h = 400
		self.sheet_y = self.ih - self.sheet_h
		self.list_w = self.iw
		local list_h = self.sheet_y - self.c_tabs.h - 16
		self.c_list = TouchItemList.new{width=self.iw, height=list_h, actor=self.actor_actor, scrollbar=true, items={},
			on_select=function(e) self:selectEntry(e) end, on_use=function(e) self:primary() end}
		local dh = self.sheet_h - bh - 16
		self.c_desc = TextzoneList.new{focus_check=true, scrollbar=true, width=self.iw - 16, height=dh, dest_area={h=dh}}
		self.b_primary = Button.new{text=_t"Select an item", width=300, font=self.bigfont, fct=function() self:primary() end}
		self.uis_def = {
			{left=0, top=0, ui=self.c_tabs},
			{left=0, top=self.c_tabs.h + 8, ui=self.c_list},
			{left=8, top=self.sheet_y + 8, ui=self.c_desc},
			{right=0, bottom=0, ui=self.b_primary},
		}
		return
	end
	local list_h = self.ih - self.c_tabs.h - bh - 24
	self.list_w = math.floor(self.iw * 0.56)
	self.c_list = TouchItemList.new{width=self.list_w, height=list_h, actor=self.actor_actor, scrollbar=true, items={},
		on_select=function(e) self:selectEntry(e) end, on_use=function(e) self:primary() end}
	self.c_desc = TextzoneList.new{focus_check=true, scrollbar=true, width=self.iw - self.list_w - 20, height=list_h, dest_area={h=list_h}}
	self.b_primary = Button.new{text=_t"Select an item", width=300, font=self.bigfont, fct=function() self:primary() end}
	self.uis_def = {
		{left=0, top=0, ui=self.c_tabs},
		{left=0, top=self.c_tabs.h + 8, ui=self.c_list},
		{left=self.list_w + 20, top=self.c_tabs.h + 8, ui=self.c_desc},
		{right=0, bottom=0, ui=self.b_primary},
	}
end

function _M:refresh()
	local items = {}
	if self.mode == "buy" then
		for i, o in ipairs(self.store_inven) do
			if not self.store_filter or self.store_filter(o) then items[#items+1] = {object=o, inven=self.store_inven, item=i, price=self.descprice("buy", o)} end
		end
	else
		for i, o in ipairs(self.actor_inven) do
			if (not self.actor_filter or self.actor_filter(o)) and not o.__transmo then items[#items+1] = {object=o, inven=self.actor_inven, item=i, price=self.descprice("sell", o)} end
		end
	end
	self.c_list:setItems(items)
	if self.cur then
		local found = false
		for i, e in ipairs(items) do if e.object == self.cur.object then found = true self.c_list:select(i, true) self.cur = e end end
		if not found then self.cur = nil self.c_desc:erase() end
	end
	self:updateButtons()
end

function _M:selectEntry(e)
	self.cur = e
	local ok, d = pcall(self.desc, self.mode, e.object)
	if ok and d then self.c_desc:erase() self.c_desc:switchItem(d, d) end
	if self.on_select then pcall(self.on_select, e) end
	self:updateButtons()
end

function _M:updateButtons()
	local txt = _t"Select an item"
	if self.cur then
		local price = self.cur.price and tostring(self.cur.price) or ""
		txt = (self.mode == "buy" and _t"Buy" or _t"Sell")..(price ~= "" and ("  "..price) or "")
	end
	self.b_primary.text = txt
	self.b_primary:generate()
	for _, ui in ipairs(self.uis) do
		if ui.ui == self.b_primary then ui.x = self.iw - self.b_primary.w ui.ui.mouse.delegate_offset_x = ui.x end
	end
end

function _M:primary()
	local e = self.cur
	if not e then return end
	print("[TOUCH] store", self.mode, e.object.name)
	if self.mode == "buy" then
		if util.getval(self.allow_buy, e.object, e.item) then self.action("buy", e.object, e.item) end
	else
		if util.getval(self.allow_sell, e.object, e.item) then self.action("sell", e.object, e.item) end
	end
end

--- Rotation: a fresh dialog for the new orientation, same tab and selection
function _M:touch_reopen()
	local nd = _M.new(unpack(self.touch_args, 1, 13))
	if self.mode ~= nd.mode then nd.c_tabs:select(self.mode) end
	if self.cur and self.cur.object then
		for i, e in ipairs(nd.c_list.items) do if e.object == self.cur.object then nd.c_list:select(i, true) nd:selectEntry(e) end end
	end
	return nd
end

function _M:innerDisplayBack(x, y, nb_keyframes)
	if not self.portrait then return end
	local K = require "engine.ui.TouchKit"
	K.quad(x + self.ix, y + self.iy + self.sheet_y, self.iw, self.sheet_h, K.PANE)
end

-- the store calls these after a transaction
function _M:updateStore()
	self:refresh()
	self:updateTitle(self:getStoreTitle())
end
function _M:generateList() self:refresh() end
