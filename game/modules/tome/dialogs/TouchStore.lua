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
local Card = require("mod.dialogs.TouchCompare").Card

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
	-- portrait: the purse line does not fit the title bar; it is drawn in the sheet instead
	if require("engine.TouchInput").portrait() then return self.base_title end
	return self.base_title..(" (pays up to %0.2f gold, your gold: %0.2f)"):tformat(self.store_actor.store.purse, self.actor_actor.money)
end

function _M:purseLine()
	return ("Pays up to %0.2f gold  ·  you have %0.2f gold"):tformat(self.store_actor.store.purse, self.actor_actor.money)
end

function _M:build()
	self.c_tabs = Tabs.new{width=self.iw, tabs={{title=_t"Buy", kind="buy"}, {title=_t"Sell", kind="sell"}}, on_change=function(kind) self.mode = kind self.cur = nil if self.c_list then self:showCard(nil) self.c_desc:erase() self:refresh() end end}
	local bh = 56
	if self.portrait then
		-- portrait: Buy / Sell tabs on top, the list fills the width, the description
		-- and the action button are a bottom sheet
		self.sheet_h = 440
		self.sheet_y = self.ih - self.sheet_h
		self.list_w = self.iw
		local list_h = self.sheet_y - self.c_tabs.h - 16 - 24 -- 24: the purse line under the tabs
		self.c_list = TouchItemList.new{width=self.iw, height=list_h, actor=self.actor_actor, scrollbar=true, items={},
			on_select=function(e) self:selectEntry(e) end, on_use=function(e) self:primary() end}
		-- the compare card (item header + NEW / WORN table) above the description
		self.card_w = self.iw - 16
		self.card_x, self.card_y = 8, self.sheet_y + 8
		self.desc_bottom = bh + 16
		self.c_card = Card.new{width=self.card_w, height=90, actor=self.actor_actor}
		local dh = self.sheet_h - 8 - 90 - 6 - self.desc_bottom
		self.c_desc = TextzoneList.new{focus_check=true, scrollbar=true, width=self.card_w, height=dh, dest_area={h=dh}}
		self.b_primary = Button.new{text=_t"Select an item", width=300, font=self.bigfont, fct=function() self:primary() end}
		self.uis_def = {
			{left=0, top=0, ui=self.c_tabs},
			{left=0, top=self.c_tabs.h + 32, ui=self.c_list},
			{left=self.card_x, top=self.card_y, ui=self.c_card},
			{left=self.card_x, top=self.card_y + 90 + 6, ui=self.c_desc},
			{right=0, bottom=0, ui=self.b_primary},
		}
		return
	end
	local list_h = self.ih - self.c_tabs.h - bh - 24
	self.list_w = math.floor(self.iw * 0.56)
	self.c_list = TouchItemList.new{width=self.list_w, height=list_h, actor=self.actor_actor, scrollbar=true, items={},
		on_select=function(e) self:selectEntry(e) end, on_use=function(e) self:primary() end}
	-- the compare card (item header + NEW / WORN table) above the description
	self.card_w = self.iw - self.list_w - 20
	self.card_x, self.card_y = self.list_w + 20, self.c_tabs.h + 8
	self.desc_bottom = bh + 16
	self.c_card = Card.new{width=self.card_w, height=90, actor=self.actor_actor}
	local dh = list_h - 90 - 6
	self.c_desc = TextzoneList.new{focus_check=true, scrollbar=true, width=self.card_w, height=dh, dest_area={h=dh}}
	self.b_primary = Button.new{text=_t"Select an item", width=300, font=self.bigfont, fct=function() self:primary() end}
	self.uis_def = {
		{left=0, top=0, ui=self.c_tabs},
		{left=0, top=self.c_tabs.h + 8, ui=self.c_list},
		{left=self.card_x, top=self.card_y, ui=self.c_card},
		{left=self.card_x, top=self.card_y + 90 + 6, ui=self.c_desc},
		{right=0, bottom=0, ui=self.b_primary},
	}
end

--- What the actor wears where this item would go (nil when nothing / not equipment)
function _M:wornFor(o)
	local wi = o and o.wornInven and o:wornInven()
	local inv = wi and self.actor_actor and self.actor_actor:getInven(wi)
	if not inv then return nil end
	for _, w in ipairs(inv) do if w ~= o then return w end end
	return nil
end

function _M:kindOf(o)
	local parts = {}
	if o.type then parts[#parts+1] = tostring(o.type) end
	if o.subtype and o.subtype ~= o.type then parts[#parts+1] = tostring(o.subtype) end
	return table.concat(parts, " · ")
end

--- The card grows with its stat rows; the description takes what is left
-- (a TextzoneList cannot change height: it is rebuilt in place)
function _M:fitDesc()
	local h = self.c_card.o and math.max(90, self.c_card:contentHeight()) or 90
	if self.c_card.h == h and self.c_desc_h_fit == h then return end
	self.c_card.h = h
	local top = self.card_y + h + 6
	local dh
	if self.portrait then dh = math.max(60, self.sheet_y + self.sheet_h - top - self.desc_bottom)
	else dh = math.max(60, self.ih - top - self.desc_bottom) end
	local old = self.c_desc
	self.c_desc = TextzoneList.new{focus_check=true, scrollbar=true, width=self.card_w, height=dh, dest_area={h=dh}}
	local entry = self.ui_by_ui[old]
	if entry then
		entry.ui = self.c_desc
		entry.y = self.iy + top
		self.ui_by_ui[old] = nil
		self.ui_by_ui[self.c_desc] = entry
	end
	self.c_desc_h_fit = h
end

--- Fill the compare card for an object (nil clears it) and re-fit the description
function _M:showCard(o)
	if not self.c_card then return end
	if o then self.c_card:set(o, self:wornFor(o), self:kindOf(o)) else self.c_card:set(nil) end
	self:fitDesc()
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
		if not found then self.cur = nil self:showCard(nil) self.c_desc:erase() end
	end
	self:updateButtons()
end

function _M:selectEntry(e)
	self.cur = e
	self:showCard(e.object)
	-- the stock store description has no comparison: rebuild it as the price line
	-- plus the desktop's ctrl comparison against what is worn in that slot
	local o = e.object
	self.desc_compared, self.desc_text = false, nil
	local ok, d = pcall(function()
		local price = self.descprice and self.descprice(self.mode, o) or nil
		local money = self.actor_actor and self.actor_actor.money or 0
		local ds = tstring{}
		if price then
			ds:add({"font", "bold"}, {"color", "GOLD"}, ((self.mode == "buy" and _t"Buy for: %0.2f gold (You have %0.2f gold)" or _t"Sell for: %0.2f gold (You have %0.2f gold)"):format(price, money)), {"font", "normal"}, {"color", "LAST"}, true, true)
		end
		local cmp = o:wornInven() and self.actor_actor and self.actor_actor:getInven(o:wornInven()) or nil
		if cmp and #cmp == 0 then cmp = nil end
		ds:merge(o:getDesc({do_color=true, force_compare=true}, cmp, nil, self.actor_actor))
		self.desc_compared = cmp ~= nil
		return ds
	end)
	if not ok or not d then ok, d = pcall(self.desc, self.mode, o) end
	if ok and d then self.c_desc:erase() self.c_desc:switchItem(d, d) self.desc_text = type(d) == "table" and d.toString and d:toString() or tostring(d) end
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
	-- the purse line above the tabs (the title bar is too narrow for it)
	local d = K.text(self:purseLine(), 18, 240, 212, 138, false, self.iw - 16)
	if d then K.draw(d, x + self.ix + 8, y + self.iy + self.c_tabs.h + 4) end
end

-- the store calls these after a transaction
function _M:updateStore()
	self:refresh()
	self:updateTitle(self:getStoreTitle())
end
function _M:generateList() self:refresh() end
