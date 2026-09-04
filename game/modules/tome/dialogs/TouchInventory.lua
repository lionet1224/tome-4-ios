-- ToME - Tales of Maj'Eyal
-- iOS port: the inventory as a touch screen. Category tabs, an equipment strip,
-- a finger-sized item list, the description on the right, and the obvious
-- action for the selected item on a big button at the right thumb.

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local Button = require "engine.ui.Button"
local Tabs = require "engine.ui.Tabs"
local TextzoneList = require "engine.ui.TextzoneList"
local Base = require "engine.ui.Base"
local Focusable = require "engine.ui.Focusable"
local FontPackage = require "engine.FontPackage"
local TouchItemList = require "mod.dialogs.elements.TouchItemList"

module(..., package.seeall, class.inherit(Dialog))

-- the strip of worn slots along the top
local EquipStrip = class.inherit(Base, Focusable){}
function EquipStrip:init(t)
	self.actor = t.actor
	self.on_select = t.on_select
	self.box = 56
	self.gap = 6
	self.slots = {}
	for id, def in ipairs(self.actor.inven_def) do
		if def.is_worn and self.actor.inven[id] and def.show_equip ~= false then self.slots[#self.slots+1] = {id=id, def=def} end
	end
	self.w = t.width
	self.h = self.box + 20
	Base.init(self, t)
end
function EquipStrip:generate()
	self.mouse:reset()
	self.key:reset()
	self.labels = {}
	self.mouse:registerZone(0, 0, self.w, self.h, function(button, x, y, xrel, yrel, bx, by, event)
		-- hold-then-drag on a worn slot = pick that item up
		if event == "motion" and self.on_drag and not self.dragging then
			local TI = require "engine.TouchInput"
			local t = TI.t
			if t and t.held and t.hover and self.last_screen_x then
				local i0 = math.floor((t.x0 - self.last_screen_x) / (self.box + self.gap)) + 1
				local s0 = self.slots[i0]
				local inv = s0 and self.actor.inven[s0.id]
				if inv and inv[1] then self.dragging = true self.on_drag({object=inv[1], inven=s0.id, item=1, worn=true}, s0) end
			end
			return
		end
		if event ~= "button" or button ~= "left" then return end
		local i = math.floor(x / (self.box + self.gap)) + 1
		local s = self.slots[i]
		if s then
			local inv = self.actor.inven[s.id]
			self.sel = i
			if inv and inv[1] then self.on_select({object=inv[1], inven=s.id, item=1, worn=true}, s) else self.on_select(nil, s) end
		end
	end)
end
function EquipStrip:label(str)
	local d = self.labels[str]
	if not d then
		self.small = self.small or core.display.newFont(FontPackage:getFont("default"), 13)
		local w = self.small:size(str) + 4
		d = self.small:draw(str, w, 200, 195, 180, true)[1]
		d.w = math.min(d.w, w)
		self.labels[str] = d
	end
	return d
end
function EquipStrip:slotAt(sx)
	if not self.last_screen_x then return nil end
	local i = math.floor((sx - self.last_screen_x) / (self.box + self.gap)) + 1
	return self.slots[i], i
end

function EquipStrip:display(x, y, nb_keyframes, screen_x, screen_y)
	self.last_screen_x, self.last_screen_y = screen_x, screen_y
	for i, s in ipairs(self.slots) do
		local bx = x + (i - 1) * (self.box + self.gap)
		local inv = self.actor.inven[s.id]
		local o = inv and inv[1]
		core.display.drawQuad(bx, y, self.box, self.box, 20, 20, 24, o and 210 or 90)
		if i == self.sel or i == self.drop_hint then
			local ok = i == self.drop_hint and self.drop_ok
			local r, g, b = 255, 215, 0
			if i == self.drop_hint then r, g, b = ok and 120 or 230, ok and 230 or 80, ok and 120 or 60 end
			for _, e in ipairs{{bx, y, self.box, 3}, {bx, y + self.box - 3, self.box, 3}, {bx, y, 3, self.box}, {bx + self.box - 3, y, 3, self.box}} do core.display.drawQuad(e[1], e[2], e[3], e[4], r, g, b, 255) end
		end
		if o then pcall(o.toScreen, o, nil, bx + 4, y + 4, self.box - 8, self.box - 8) end
		local name = tostring(s.def.name or s.def.short_name):lower():gsub("^in ", ""):gsub("^on ", ""):gsub("^around ", "")
		if #name > 9 then name = name:sub(1, 8) end
		local d = self:label(name)
		d._tex:toScreenFull(bx + (self.box - d.w) / 2, y + self.box + 2, d.w, d.h, d._tex_w, d._tex_h)
	end
end

function _M:init(title, actor, filter, action, on_select)
	self.actor = actor
	self.filter = filter
	self.action = action
	self.on_select_cb = on_select
	self.chooser = filter ~= nil -- a "pick an item for X" flow: the big button chooses
	self.base_title = (title or _t"Inventory"):gsub("%s+%-%s+.*$", "") -- the caller passes "Title - Encumbrance x/y"
	self.tab = "all"
	self.bigfont = core.display.newFont(FontPackage:getFont("default"), 22)
	-- what class/Game.lua's chest-at-the-stairs flow pokes on the old dialog
	self.c_inven = {switchTab=function(_, t) self:switchTab(t and t.kind) end}
	Dialog.init(self, title or self.base_title, game.w * 0.96, game.h * 0.96)
	self:build()
	self:loadUI(self.uis_def)
	self:setupUI()
	self:refresh()
	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end }
	-- drag and drop: a hold-then-drag picks an item up, its release is reported here
	require("engine.TouchInput").on_hover_end = function(x, y) self:dropAt(x, y) end
end

--- Hold-then-drag started on an item (list row or worn slot)
function _M:startDrag(e)
	self.drag = e
	self.cur = e
	print("[TOUCH] drag item", tostring(e.object.name), e.worn and "(worn)" or "")
end

--- Which strip slot (if any) is under screen x,y and whether the dragged item fits it
function _M:dropTarget(x, y)
	local st = self.c_strip
	if not st.last_screen_y or y < st.last_screen_y or y > st.last_screen_y + st.h then return nil end
	local slot, i = st:slotAt(x)
	if not slot then return nil end
	local o = self.drag and self.drag.object
	local ok = o and not self.drag.worn and o:wornInven() and self.actor:canWearObject(o, slot.def.short_name or slot.def.name) and true or false
	return slot, i, ok
end

function _M:dropAt(x, y)
	local e = self.drag
	self.drag = nil
	self.c_list.dragging = nil
	self.c_strip.dragging = nil
	self.c_strip.drop_hint = nil
	if not e then return end
	local UseItemDialog = require "mod.dialogs.UseItemDialog"
	local onuse = function(_, _, _, stop) self:onUsed(stop) end
	local slot, i, ok = self:dropTarget(x, y)
	if slot and not e.worn then
		if not ok then game.logPlayer(self.actor, "%s does not go there.", e.object:getName{do_color=true}) print("[TOUCH] drop refused") return end
		print("[TOUCH] drop -> wear", tostring(e.object.name), slot.def.name)
		local inv = self.actor:getInven(slot.id)
		if inv and #inv >= (inv.max or 1) then self.actor:doWear(e.inven, e.item, e.object, self.actor, slot.id, 1)
		else self.actor:doWear(e.inven, e.item, e.object, self.actor) end
		self:onUsed(false)
		return
	end
	-- a worn item dropped on the list = take it off
	local l = self.c_list
	if e.worn and l.last_screen_y and y >= l.last_screen_y and y <= l.last_screen_y + l.h and x >= l.last_screen_x and x <= l.last_screen_x + l.w then
		print("[TOUCH] drop -> take off", tostring(e.object.name))
		UseItemDialog.new(false, self.actor, e.object, e.item, e.inven, onuse):use({action="takeoff"})
		return
	end
	print("[TOUCH] drop cancelled")
end

--- The dragged item follows the finger; the slot under it lights up
function _M:innerDisplay(x, y, nb_keyframes)
	local e = self.drag
	if not e then return end
	local TI = require "engine.TouchInput"
	local t = TI.t
	if not t then return end
	local slot, i, ok = self:dropTarget(t.x, t.y)
	self.c_strip.drop_hint, self.c_strip.drop_ok = (slot and not e.worn) and i or nil, ok
	pcall(e.object.toScreen, e.object, nil, t.x - 30, t.y - 70, 60, 60)
end

local TABS = {
	{title=_t"All", kind="all", filter=function(o) return not o.__transmo end},
	{title=_t"Weapons", kind="weapons", filter=function(o) return not o.__transmo and (o.type == "weapon" or o.type == "ammo") end},
	{title=_t"Armour", kind="armors", filter=function(o) return not o.__transmo and o.type == "armor" end},
	{title=_t"Jewelry", kind="jewelry", filter=function(o) return not o.__transmo and o.type == "jewelry" end},
	{title=_t"Inscriptions", kind="inscriptions", filter=function(o) return not o.__transmo and o.type == "scroll" end},
	{title=_t"Tools", kind="tools", filter=function(o) return not o.__transmo and (o.type == "charm" or o.type == "tool" or o.type == "lite" or o.type == "gem" or o.type == "alchemist-gem") end},
	{title=_t"Other", kind="misc", filter=function(o) return not o.__transmo and not (o.type == "weapon" or o.type == "ammo" or o.type == "armor" or o.type == "jewelry" or o.type == "scroll" or o.type == "charm" or o.type == "tool" or o.type == "lite" or o.type == "gem" or o.type == "alchemist-gem") end},
	{title=_t"Chest", kind="transmo", filter=function(o) return o.__transmo end},
}

function _M:build()
	local tabs = {}
	for _, t in ipairs(TABS) do if t.kind ~= "transmo" or self.actor:attr("has_transmo") then tabs[#tabs+1] = {title=t.title, kind=t.kind} end end
	self.c_tabs = Tabs.new{width=self.iw, tabs=tabs, on_change=function(kind) self.tab = kind if self.c_list then self:refresh() end end}
	self.c_strip = EquipStrip.new{width=self.iw, actor=self.actor, on_select=function(e, slot) self:selectWorn(e, slot) end, on_drag=function(e) self:startDrag(e) end}
	local bh = 56
	local list_h = self.ih - self.c_tabs.h - self.c_strip.h - bh - 30
	self.list_w = math.floor(self.iw * 0.56)
	self.c_list = TouchItemList.new{width=self.list_w, height=list_h, actor=self.actor, scrollbar=true, items={},
		on_select=function(e) self:selectEntry(e) end, on_use=function(e) self:primary() end, on_drag=function(e) self:startDrag(e) end}
	self.c_desc = TextzoneList.new{focus_check=true, scrollbar=true, width=self.iw - self.list_w - 20, height=list_h, dest_area={h=list_h}}
	self.b_primary = Button.new{text=_t"Select an item", width=260, font=self.bigfont, fct=function() self:primary() end}
	self.b_more = Button.new{text=_t"More...", width=150, font=self.bigfont, fct=function() self:more() end}
	self.b_compare = Button.new{text=_t"Compare", width=170, font=self.bigfont, fct=function() self:compare() end}
	self.b_keep = Button.new{text=_t"Keep", width=120, font=self.bigfont, fct=function() self:keep() end}
	self.uis_def = {
		{left=0, top=0, ui=self.c_tabs},
		{left=0, top=self.c_tabs.h + 6, ui=self.c_strip},
		{left=0, top=self.c_tabs.h + self.c_strip.h + 12, ui=self.c_list},
		{left=self.list_w + 20, top=self.c_tabs.h + self.c_strip.h + 12, ui=self.c_desc},
		{right=0, bottom=0, ui=self.b_primary},
		{right=self.b_primary, bottom=0, ui=self.b_more},
		{right=self.b_more, bottom=0, ui=self.b_compare},
		{right=self.b_compare, bottom=0, ui=self.b_keep},
	}
end

function _M:switchTab(kind)
	if not kind then return end
	for _, t in ipairs(self.c_tabs.tabs) do if t.kind == kind then self.c_tabs:select(kind) return end end
	self.tab = kind
	self:refresh()
end

function _M:tabFilter()
	for _, t in ipairs(TABS) do if t.kind == self.tab then return t.filter end end
	return TABS[1].filter
end

function _M:refresh()
	local inven = self.actor:getInven(self.actor.INVEN_INVEN) or {}
	local f = self:tabFilter()
	local items = {}
	for i, o in ipairs(inven) do
		if f(o) and (not self.filter or self.filter(o)) then items[#items+1] = {object=o, inven=self.actor.INVEN_INVEN, item=i} end
	end
	self.c_list:setItems(items)
	if self.cur and self.cur.object then
		local found = false
		for i, e in ipairs(items) do if e.object == self.cur.object then found = true self.c_list:select(i, true) self.cur = e end end
		if not found and not self.cur.worn then self.cur = nil self.c_desc:erase() end
	end
	self:updateButtons()
end

function _M:selectEntry(e)
	self.cur = e
	self.c_strip.sel = nil
	local o = e.object
	local ok, desc = pcall(o.getDesc, o, {do_color=true}, self.actor:getInven(o:wornInven()), nil, self.actor)
	if ok and desc then self.c_desc:erase() self.c_desc:switchItem(desc, desc) end
	if self.on_select_cb then pcall(self.on_select_cb, e) end
	self:updateButtons()
end

function _M:selectWorn(e, slot)
	self.c_list.sel = nil
	if not e then self.cur = nil self.c_desc:erase() self.c_desc:switchItem(slot.def.name, ("%s: nothing worn."):format(slot.def.name)) self:updateButtons() return end
	self.cur = e
	local o = e.object
	local ok, desc = pcall(o.getDesc, o, {do_color=true}, nil, nil, self.actor)
	if ok and desc then self.c_desc:erase() self.c_desc:switchItem(desc, desc) end
	self:updateButtons()
end

--- The obvious action for the selected item: name and UseItemDialog action id
function _M:primaryFor(e)
	if not e then return nil end
	local o = e.object
	if self.chooser then return _t"Choose", "choose" end
	if e.worn or e.inven ~= self.actor.INVEN_INVEN then return _t"Take off", "takeoff" end
	-- chest items: wearing / using is the point; "Keep" has its own button
	if o:wornInven() and self.actor:getInven(o:wornInven()) then return _t"Wield / wear", "wear" end
	if o:canUseObject() then return _t"Use", "use" end
	if o.__transmo then return _t"Keep (to inventory)", "toinven" end
	return _t"Drop", "drop"
end

function _M:updateButtons()
	local name = self:primaryFor(self.cur)
	self.b_primary.text = name or _t"Select an item"
	self.b_primary:generate()
	-- keep the two buttons anchored bottom-right after the width change
	for _, ui in ipairs(self.uis) do
		if ui.ui == self.b_primary then ui.x = self.iw - self.b_primary.w ui.ui.mouse.delegate_offset_x = ui.x
		elseif ui.ui == self.b_more then ui.x = self.iw - self.b_primary.w - self.b_more.w - 6 ui.ui.mouse.delegate_offset_x = ui.x
		elseif ui.ui == self.b_compare then ui.x = self.iw - self.b_primary.w - self.b_more.w - self.b_compare.w - 12 ui.ui.mouse.delegate_offset_x = ui.x
		elseif ui.ui == self.b_keep then
			-- only for chest items: otherwise parked off-screen
			local chest = self.cur and self.cur.object and self.cur.object.__transmo
			ui.x = chest and (self.iw - self.b_primary.w - self.b_more.w - self.b_compare.w - self.b_keep.w - 18) or -10000
			ui.ui.mouse.delegate_offset_x = ui.x
		end
	end
end

function _M:onUsed(stop)
	self:refresh()
	if self.actor.getEncumberTitleUpdator then self:updateTitle(self.actor:getEncumberTitleUpdator(self.base_title)()) end
	if stop then game:unregisterDialog(self) end
end

function _M:primary()
	local e = self.cur
	if not e then return end
	local name, act = self:primaryFor(e)
	print("[TOUCH] inventory primary", act, e.object.name)
	if act == "choose" then
		if self.action and self.action(e.object, e.inven, e.item, "left", "button") then game:unregisterDialog(self) end
		return
	end
	local UseItemDialog = require "mod.dialogs.UseItemDialog"
	local ud = UseItemDialog.new(false, self.actor, e.object, e.item, e.inven, function(_, _, _, stop) self:onUsed(stop) end)
	ud:use({action=act})
end

--- Chest item: move it to the normal inventory (it will not be transmogrified)
function _M:keep()
	local e = self.cur
	if not e or not e.object.__transmo then return end
	print("[TOUCH] inventory keep", e.object.name)
	local UseItemDialog = require "mod.dialogs.UseItemDialog"
	local ud = UseItemDialog.new(false, self.actor, e.object, e.item, e.inven, function(_, _, _, stop) self:onUsed(stop) end)
	ud:use({action="toinven"})
end

--- Side by side with what is worn in the item's slot
function _M:compare()
	local e = self.cur
	if not e then return end
	local o = e.object
	local wi = o:wornInven()
	if not wi or not self.actor:getInven(wi) then Dialog:simplePopup(_t"Compare", _t"This is not something you wear.") return end
	local worn = {}
	for _, w in ipairs(self.actor:getInven(wi)) do if w ~= o then worn[#worn+1] = w end end
	local on_wear = nil
	if not e.worn and e.inven == self.actor.INVEN_INVEN then
		on_wear = function()
			local UseItemDialog = require "mod.dialogs.UseItemDialog"
			local ud = UseItemDialog.new(false, self.actor, o, e.item, e.inven, function(_, _, _, stop) self:onUsed(stop) end)
			ud:use({action="wear"})
		end
	end
	print("[TOUCH] compare", o.name, #worn)
	game:registerDialog(require("mod.dialogs.TouchCompare").new(self.actor, o, worn, on_wear))
end

function _M:more()
	local e = self.cur
	if not e then return end
	local UseItemDialog = require "mod.dialogs.UseItemDialog"
	game:registerDialog(UseItemDialog.new(false, self.actor, e.object, e.item, e.inven, function(_, _, _, stop) self:onUsed(stop) end))
end

-- the default inventory action (class/Game.lua) calls these after an item was used
function _M:generateList() self:refresh() end
function _M:generate()
	Dialog.generate(self)
end
function _M:unload()
	require("engine.TouchInput").on_hover_end = nil
	local inven = self.actor:getInven(self.actor.INVEN_INVEN)
	if inven then for _, o in ipairs(inven) do o:forAllStack(function(so) so.__new_pickup = nil end) end end
end
