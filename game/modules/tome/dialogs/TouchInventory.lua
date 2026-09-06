-- ToME - Tales of Maj'Eyal
-- iOS port: the inventory as a touch screen (see tools/ios/design/inventory-mockup.html).
-- Left: your character with the worn slots around it. Middle: filter chips and
-- finger-sized item rows. Right: the selected item compared with what is worn in
-- its slot, and the actions. Tap = compare, double-tap = the primary action,
-- hold-then-drag = move an item onto a slot (or a worn item into the list).

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local Button = require "engine.ui.Button"
local Base = require "engine.ui.Base"
local Focusable = require "engine.ui.Focusable"
local TextzoneList = require "engine.ui.TextzoneList"
local FontPackage = require "engine.FontPackage"
local TouchItemList = require "mod.dialogs.elements.TouchItemList"
local K = require "engine.ui.TouchKit"

module(..., package.seeall, class.inherit(Dialog))

------------------------------------------------------------------------
-- the character with its slots (layout from ActorInventory.equipdolls)
------------------------------------------------------------------------
local Doll = class.inherit(Base, Focusable){}
function Doll:init(t)
	self.actor = t.actor
	self.on_select = t.on_select
	self.on_drag = t.on_drag
	self.w, self.h = t.width, t.height
	local doll = self.actor.equipdolls and self.actor.equipdolls[type(self.actor.equipdoll) == "string" and self.actor.equipdoll or "default"] or self.actor.equipdolls.default
	self.doll = doll
	-- the doll definition is laid out on a ~312x456 grid: scale it into our pane
	local dw, dh = 312 + 48, 456 + 48
	self.sc = math.min((self.w - 16) / dw, (self.h - 16) / dh)
	-- frames are ~60 grid units apart: keep them from overlapping once scaled
	self.box = math.max(44, math.floor(58 * self.sc))
	self.ox, self.oy = math.floor((self.w - dw * self.sc) / 2), 8
	self.slots = {}
	for id, def in ipairs(self.actor.inven_def) do
		local inv = self.actor.inven[id]
		local pos = doll.list[def.short_name]
		if def.is_worn and inv and pos then
			for k, p in ipairs(pos) do
				self.slots[#self.slots+1] = {id=id, def=def, item=k, x=self.ox + p.x * self.sc - 8, y=self.oy + p.y * self.sc - 8}
			end
		end
	end
	Base.init(self, t)
end
function Doll:generate()
	self.mouse:reset()
	self.key:reset()
	self.frame = self:getUITexture(self.doll.itemframe)
	self.frame_sel = self:getUITexture(self.doll.itemframe_sel)
	self.small = core.display.newFont(FontPackage:getFont("default"), 12)
	self.labels = {}
	self.mouse:registerZone(0, 0, self.w, self.h, function(button, x, y, xrel, yrel, bx, by, event)
		if event == "motion" and self.on_drag and not self.dragging then
			local TI = require "engine.TouchInput"
			local t = TI.t
			if t and t.held and t.hover and self.last_screen_x then
				local s = self:slotAtLocal(t.x0 - self.last_screen_x, t.y0 - self.last_screen_y)
				local inv = s and self.actor.inven[s.id]
				local o = inv and inv[s.item]
				if o then self.dragging = true self.on_drag({object=o, inven=s.id, item=s.item, worn=true}, s) end
			end
			return
		end
		if event ~= "button" or button ~= "left" then return end
		local s = self:slotAtLocal(x, y)
		if s then
			local inv = self.actor.inven[s.id]
			local o = inv and inv[s.item]
			self.sel = s
			self.on_select(o and {object=o, inven=s.id, item=s.item, worn=true} or nil, s)
		end
	end)
end
function Doll:slotAtLocal(x, y)
	-- frames may overlap once the doll is scaled down: take the nearest centre
	local best, bd
	for _, s in ipairs(self.slots) do
		if x >= s.x and x < s.x + self.box and y >= s.y and y < s.y + self.box then
			local d = (x - s.x - self.box / 2)^2 + (y - s.y - self.box / 2)^2
			if not bd or d < bd then best, bd = s, d end
		end
	end
	return best
end
function Doll:slotAtScreen(x, y)
	if not self.last_screen_x then return nil end
	return self:slotAtLocal(x - self.last_screen_x, y - self.last_screen_y)
end
function Doll:label(str)
	local d = self.labels[str]
	if not d then
		local w = self.small:size(str) + 4
		d = self.small:draw(str, w, 170, 165, 150, true)[1]
		d.w = math.min(d.w, w)
		self.labels[str] = d
	end
	return d
end
function Doll:display(x, y, nb_keyframes, screen_x, screen_y)
	self.last_screen_x, self.last_screen_y = screen_x, screen_y
	local d = self.doll
	-- the character, drawn from its own tile with its gear
	local dx, dy = x + self.ox + d.doll_x * self.sc - 8, y + self.oy + d.doll_y * self.sc - 8
	local dsz = (d.doll_w or 128) * self.sc * 1.15
	core.display.drawQuad(dx - 6, dy - 6, dsz + 12, dsz + 12, 20, 22, 28, 200)
	pcall(self.actor.toScreen, self.actor, nil, dx, dy, dsz, dsz)
	for _, s in ipairs(self.slots) do
		local inv = self.actor.inven[s.id]
		local o = inv and inv[s.item]
		local bx, by = x + s.x, y + s.y
		local f = self.frame
		local hint = self.drop_hint
		if hint and hint.id == s.id and hint.item == s.item then
			core.display.drawQuad(bx - 3, by - 3, self.box + 6, self.box + 6, self.drop_ok and 120 or 230, self.drop_ok and 230 or 80, self.drop_ok and 120 or 60, 255)
		elseif self.sel == s then
			f = self.frame_sel
		end
		f.t:toScreenFull(bx, by, self.box, self.box, f.tw, f.th)
		if o then pcall(o.toScreen, o, nil, bx + 6, by + 6, self.box - 12, self.box - 12)
		else
			local back = s.def.infos and s.def.infos.equipdoll_back
			if back then local okb, bt = pcall(self.getUITexture, self, back) if okb and bt then bt.t:toScreenFull(bx + 8, by + 8, self.box - 16, self.box - 16, bt.tw, bt.th, 1, 1, 1, 0.35) end end
		end
		local name = tostring(s.def.name or s.def.short_name):lower():gsub("^in ", ""):gsub("^on ", ""):gsub("^around ", "")
		if #name > 9 then name = name:sub(1, 9) end
		local l = self:label(name)
		l._tex:toScreenFull(bx + (self.box - l.w) / 2, by + self.box + 1, l.w, l.h, l._tex_w, l._tex_h)
	end
end

------------------------------------------------------------------------
-- portrait: the worn slots as a compact grid (always visible above the list,
-- so a new item can be judged against what is on). Icons only: the slot name
-- and the item go in the card when a cell is tapped.
------------------------------------------------------------------------
local WornGrid = class.inherit(Base, Focusable){}
function WornGrid:init(t)
	self.actor = t.actor
	self.on_select = t.on_select
	self.cols, self.cw, self.ch = 8, 76, 60
	self.w = t.width
	local doll = self.actor.equipdolls and self.actor.equipdolls[type(self.actor.equipdoll) == "string" and self.actor.equipdoll or "default"] or self.actor.equipdolls.default
	self.doll = doll
	self.slots = {}
	-- the same slots, in the same order, as the paper doll
	for id, def in ipairs(self.actor.inven_def) do
		local inv = self.actor.inven[id]
		local pos = doll.list[def.short_name]
		if def.is_worn and inv and pos then
			for k = 1, #pos do
				local i = #self.slots
				self.slots[i + 1] = {id=id, def=def, item=k, x=(i % self.cols) * self.cw, y=math.floor(i / self.cols) * self.ch}
			end
		end
	end
	self.rows = math.max(1, math.ceil(#self.slots / self.cols))
	self.h = self.rows * self.ch
	self.hilite = {}
	Base.init(self, t)
end
function WornGrid:generate()
	self.mouse:reset()
	self.key:reset()
	self.frame = self:getUITexture(self.doll.itemframe)
	self.frame_sel = self:getUITexture(self.doll.itemframe_sel)
	self.mouse:registerZone(0, 0, self.w, self.h, function(button, x, y, xrel, yrel, bx, by, event)
		if event ~= "button" or button ~= "left" then return end
		local s = self:slotAtLocal(x, y)
		if not s then return end
		local inv = self.actor.inven[s.id]
		local o = inv and inv[s.item]
		self.sel = s
		self.on_select(o and {object=o, inven=s.id, item=s.item, worn=true} or nil, s)
	end)
end
function WornGrid:slotAtLocal(x, y)
	for _, s in ipairs(self.slots) do
		if x >= s.x and x < s.x + self.cw and y >= s.y and y < s.y + self.ch then return s end
	end
	return nil
end
--- Mark the cells an object would go into (both fingers for a ring); nil clears
function WornGrid:setHilite(inven_id)
	self.hilite = {}
	if not inven_id then return end
	for _, s in ipairs(self.slots) do if s.id == inven_id then self.hilite[s] = true end end
end
function WornGrid:hilited()
	local n = 0
	for _ in pairs(self.hilite) do n = n + 1 end
	return n
end
function WornGrid:display(x, y, nb_keyframes, screen_x, screen_y)
	self.last_screen_x, self.last_screen_y = screen_x, screen_y
	local fs = 48 -- the frame, centred in the cell; the icon sits inside it
	for _, s in ipairs(self.slots) do
		local inv = self.actor.inven[s.id]
		local o = inv and inv[s.item]
		local cx, cy = x + s.x, y + s.y
		core.display.drawQuad(cx + 1, cy + 1, self.cw - 2, self.ch - 2, 24, 26, 32, 200)
		local fx, fy = cx + math.floor((self.cw - fs) / 2), cy + math.floor((self.ch - fs) / 2)
		local f = (self.sel == s) and self.frame_sel or self.frame
		f.t:toScreenFull(fx, fy, fs, fs, f.tw, f.th, 1, 1, 1, o and 1 or 0.45)
		if o then pcall(o.toScreen, o, nil, fx + 4, fy + 4, fs - 8, fs - 8)
		else
			local back = s.def.infos and s.def.infos.equipdoll_back
			if back then local okb, bt = pcall(self.getUITexture, self, back) if okb and bt then bt.t:toScreenFull(fx + 7, fy + 7, fs - 14, fs - 14, bt.tw, bt.th, 1, 1, 1, 0.3) end end
		end
		if self.hilite[s] or self.sel == s then K.frame(cx + 1, cy + 1, self.cw - 2, self.ch - 2, K.GOLD, 2) end
	end
end

------------------------------------------------------------------------
-- filter chips
------------------------------------------------------------------------
local Chips = class.inherit(Base, Focusable){}
function Chips:init(t)
	self.items = t.items
	self.on_change = t.on_change
	self.w, self.h = t.width, 50
	self.cur = t.default or self.items[1].kind
	Base.init(self, t)
end
function Chips:generate()
	self.mouse:reset()
	self.key:reset()
	self.tex = {}
	-- lay the chips out; shrink padding then font until the row fits
	for _, try in ipairs{{17, 26, 6}, {17, 14, 4}, {15, 12, 4}, {13, 10, 3}} do
		self.font_c = core.display.newFont(FontPackage:getFont("default"), try[1])
		local x = 0
		for _, it in ipairs(self.items) do
			local w = self.font_c:size(it.title) + try[2]
			it.x, it.w = x, w
			x = x + w + try[3]
		end
		if x - try[3] <= self.w then break end
	end
	self.mouse:registerZone(0, 0, self.w, self.h, function(button, x, y, xrel, yrel, bx, by, event)
		if event ~= "button" or button ~= "left" then return end
		for _, it in ipairs(self.items) do if x >= it.x and x < it.x + it.w then self.cur = it.kind self.on_change(it.kind) return end end
	end)
end
function Chips:display(x, y)
	for _, it in ipairs(self.items) do
		local on = it.kind == self.cur
		core.display.drawQuad(x + it.x, y + 6, it.w, 38, on and 210 or 36, on and 170 or 39, on and 74 or 47, 255)
		if not self.tex[it.kind] then
			local w = self.font_c:size(it.title) + 4
			local d = self.font_c:draw(it.title, w, 255, 255, 255, true)[1]
			d.w = math.min(d.w, w)
			self.tex[it.kind] = d
		end
		local d = self.tex[it.kind]
		local r, g, b = 1, 1, 1
		if on then r, g, b = 0.11, 0.08, 0.06 else r, g, b = 0.72, 0.7, 0.62 end
		d._tex:toScreenFull(x + it.x + (it.w - d.w) / 2, y + 6 + (38 - d.h) / 2, d.w, d.h, d._tex_w, d._tex_h, r, g, b, 1)
	end
end

------------------------------------------------------------------------
-- the compare card: item header + stat table (new | worn)
------------------------------------------------------------------------
local Card = class.inherit(Base, Focusable){}
local STATS = {
	{k="dam", n=_t"Damage", get=function(o) return o.combat and o.combat.dam end},
	{k="apr", n=_t"Armour pen.", get=function(o) return o.combat and o.combat.apr end},
	{k="atk", n=_t"Accuracy", get=function(o) return o.combat and o.combat.atk end},
	{k="crit", n=_t"Crit chance", get=function(o) return o.combat and o.combat.physcrit end, unit="%"},
	{k="armor", n=_t"Armour", get=function(o) return o.wielder and o.wielder.combat_armor end},
	{k="def", n=_t"Defence", get=function(o) return o.wielder and o.wielder.combat_def end},
	{k="enc", n=_t"Weight", get=function(o) return o.encumber end, lower_better=true},
}
function Card:init(t)
	self.w, self.h = t.width, t.height
	self.actor = t.actor
	Base.init(self, t)
end
function Card:generate()
	self.mouse:reset() self.key:reset()
	self.f_title = core.display.newFont(FontPackage:getFont("default"), 22)
	self.f_small = core.display.newFont(FontPackage:getFont("default"), 14)
	self.f_row = core.display.newFont(FontPackage:getFont("default"), 17)
	self.texts = {}
end
function Card:text(font, str, r, g, b)
	local key = tostring(font).."|"..str.."|"..r..","..g..","..b
	local d = self.texts[key]
	if not d then
		local w = font:size((str:gsub("#[^#]*#", ""))) + 6
		d = font:draw(str, w, r, g, b, true)[1]
		if d then d.w = math.min(d.w, w) end
		self.texts[key] = d
	end
	return d
end
function Card:set(o, worn, kind)
	self.o, self.worn, self.kind = o, worn, kind
	self.texts = {}
	self.rows = {}
	if not o then return end
	for _, st in ipairs(STATS) do
		local a = st.get(o)
		local b = worn and st.get(worn) or nil
		if a or b then
			local dir = nil
			if a and b and a ~= b then dir = (a > b) and "up" or "down" if st.lower_better then dir = dir == "up" and "down" or "up" end end
			self.rows[#self.rows+1] = {n=st.n, a=a and (("%s%s"):format(math.floor(a * 10) / 10, st.unit or "")) or "-", b=b and (("%s%s"):format(math.floor(b * 10) / 10, st.unit or "")) or "-", dir=dir}
		end
	end
end
function Card:contentHeight()
	return 70 + (#self.rows > 0 and (28 + #self.rows * 32 + 8) or 0)
end
function Card:display(x, y, nb_keyframes, screen_x, screen_y)
	self.last_sx, self.last_sy = screen_x or x, screen_y or y
	local o = self.o
	if not o then
		local d = self:text(self.f_row, _t"Tap an item to see how it compares with what you wear.", 142, 136, 120)
		if d then d._tex:toScreenFull(x + 10, y + 20, d.w, d.h, d._tex_w, d._tex_h) end
		return
	end
	core.display.drawQuad(x, y, 60, 60, 14, 15, 18, 255)
	pcall(o.toScreen, o, nil, x + 6, y + 6, 48, 48)
	local ok, name = pcall(o.getName, o, {do_color=true, no_count=true})
	local nd = self:text(self.f_title, ok and tostring(name) or tostring(o.name), 255, 255, 255)
	if nd then
		local maxw = self.w - 72
		core.display.glScissor(true, self.last_sx + 72, self.last_sy, maxw, 70)
		nd._tex:toScreenFull(x + 72, y + 6, nd.w, nd.h, nd._tex_w, nd._tex_h)
		core.display.glScissor(false)
	end
	local kind = self.kind or ""
	if self.worn then local okw, wn = pcall(self.worn.getName, self.worn, {do_color=true, no_count=true}) kind = kind.."  ·  "..(_t"replaces ")..(okw and tostring(wn) or self.worn.name) end
	local kd = self:text(self.f_small, kind, 160, 155, 140)
	if kd then
		core.display.glScissor(true, self.last_sx + 72, self.last_sy, self.w - 72, 70)
		kd._tex:toScreenFull(x + 72, y + 40, kd.w, kd.h, kd._tex_w, kd._tex_h)
		core.display.glScissor(false)
	end
	if #self.rows == 0 then return end
	local ty = y + 70
	core.display.drawQuad(x, ty, self.w, 28 + #self.rows * 32 + 8, 30, 32, 40, 255)
	local h1 = self:text(self.f_small, _t"STAT", 142, 136, 120)
	local h2 = self:text(self.f_small, self.worn and _t"NEW" or _t"VALUE", 240, 212, 138)
	local h3 = self:text(self.f_small, _t"WORN", 142, 136, 120)
	local c2, c3 = x + self.w - 170, x + self.w - 80
	if h1 then h1._tex:toScreenFull(x + 12, ty + 7, h1.w, h1.h, h1._tex_w, h1._tex_h) end
	if h2 then h2._tex:toScreenFull(c2 + 70 - h2.w, ty + 7, h2.w, h2.h, h2._tex_w, h2._tex_h) end
	if self.worn and h3 then h3._tex:toScreenFull(c3 + 70 - h3.w, ty + 7, h3.w, h3.h, h3._tex_w, h3._tex_h) end
	core.display.drawQuad(x, ty + 27, self.w, 1, 60, 62, 70, 255)
	local ry = ty + 32
	for _, r in ipairs(self.rows) do
		local nd2 = self:text(self.f_row, r.n, 235, 230, 215)
		local cr, cg, cb = 235, 230, 215
		if r.dir == "up" then cr, cg, cb = 123, 211, 137 elseif r.dir == "down" then cr, cg, cb = 224, 122, 106 end
		local va = self:text(self.f_row, r.a..(r.dir == "up" and " ^" or r.dir == "down" and " v" or ""), cr, cg, cb)
		local vb = self:text(self.f_row, r.b, 142, 136, 120)
		if nd2 then nd2._tex:toScreenFull(x + 12, ry + 4, nd2.w, nd2.h, nd2._tex_w, nd2._tex_h) end
		if va then va._tex:toScreenFull(c2 + 70 - va.w, ry + 4, va.w, va.h, va._tex_w, va._tex_h) end
		if self.worn and vb then vb._tex:toScreenFull(c3 + 70 - vb.w, ry + 4, vb.w, vb.h, vb._tex_w, vb._tex_h) end
		ry = ry + 32
	end
end

------------------------------------------------------------------------
-- the dialog
------------------------------------------------------------------------
local TABS = {
	{title=_t"All", kind="all", filter=function(o) return not o.__transmo end},
	{title=_t"Weapons", short=_t"Weap.", kind="weapons", filter=function(o) return not o.__transmo and (o.type == "weapon" or o.type == "ammo") end},
	{title=_t"Armour", short=_t"Arm.", kind="armors", filter=function(o) return not o.__transmo and o.type == "armor" end},
	{title=_t"Jewelry", short=_t"Jewel.", kind="jewelry", filter=function(o) return not o.__transmo and o.type == "jewelry" end},
	{title=_t"Inscr.", short=_t"Insc.", kind="inscriptions", filter=function(o) return not o.__transmo and o.type == "scroll" end},
	{title=_t"Tools", kind="tools", filter=function(o) return not o.__transmo and (o.type == "charm" or o.type == "tool" or o.type == "lite" or o.type == "gem" or o.type == "alchemist-gem") end},
	{title=_t"Other", kind="misc", filter=function(o) return not o.__transmo and not (o.type == "weapon" or o.type == "ammo" or o.type == "armor" or o.type == "jewelry" or o.type == "scroll" or o.type == "charm" or o.type == "tool" or o.type == "lite" or o.type == "gem" or o.type == "alchemist-gem") end},
	{title=_t"Chest", kind="transmo", filter=function(o) return o.__transmo end},
}

function _M:init(title, actor, filter, action, on_select)
	self.touch_args = {title=title, actor=actor, filter=filter, action=action, on_select=on_select}
	self.actor = actor
	self.filter = filter
	self.action = action
	self.on_select_cb = on_select
	self.chooser = filter ~= nil
	self.base_title = (title or _t"Pack"):gsub("%s+%-%s+.*$", "")
	self.tab = "all"
	self.bigfont = core.display.newFont(FontPackage:getFont("default"), 22)
	self.c_inven = {switchTab=function(_, t) self:switchTab(t and t.kind) end} -- what class/Game.lua's chest flow pokes
	Dialog.init(self, title or self.base_title, game.w * 0.96, game.h * 0.96)
	self:build()
	self:loadUI(self.uis_def)
	self:setupUI()
	self:showPane()
	self:refresh()
	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end }
	require("engine.TouchInput").on_hover_end = function(x, y) self:dropAt(x, y) end
end

function _M:build()
	self.portrait = require("engine.TouchInput").portrait()
	self.sheet_y = 0
	if self.portrait then return self:buildPortrait() end
	local gap = 12
	self.doll_w = 330
	self.card_w = 390
	self.list_w = self.iw - self.doll_w - self.card_w - 2 * gap
	local ph = self.ih
	self.c_doll = Doll.new{width=self.doll_w, height=ph, actor=self.actor, on_select=function(e, slot) self:selectWorn(e, slot) end, on_drag=function(e) self:startDrag(e) end}
	local chips = {}
	for _, t in ipairs(TABS) do if t.kind ~= "transmo" or self.actor:attr("has_transmo") then chips[#chips+1] = {title=t.title, kind=t.kind} end end
	self.c_chips = Chips.new{width=self.list_w, items=chips, default="all", on_change=function(kind) self.tab = kind if self.c_list then self:refresh() end end}
	-- a strip under the chips for the chest hint (only when the character owns the chest)
	self.banner_h = self.actor:attr("has_transmo") and 40 or 0
	self.c_list = TouchItemList.new{width=self.list_w, height=ph - self.c_chips.h - 6 - self.banner_h, actor=self.actor, scrollbar=true, items={},
		on_select=function(e) self:selectEntry(e) end, on_use=function(e) self:primary() end, on_drag=function(e) self:startDrag(e) end}
	local bh = 56
	self.c_card = Card.new{width=self.card_w, height=200, actor=self.actor}
	self.desc_h = ph - 200 - bh * 2 - 30
	self.c_desc = TextzoneList.new{focus_check=true, scrollbar=true, width=self.card_w, height=self.desc_h, dest_area={h=self.desc_h}}
	self.b_primary = Button.new{text=_t"Select an item", width=self.card_w, font=self.bigfont, fct=function() self:primary() end}
	local cw = math.floor((self.card_w - 12) / 3)
	self.b_drop = Button.new{text=_t"Drop", width=cw, font=self.bigfont, fct=function() self:act("drop") end}
	self.b_transmo = Button.new{text=_t"Transmog.", width=cw, font=self.bigfont, fct=function() self:act("transmo") end}
	self.b_more = Button.new{text=_t"More...", width=cw, font=self.bigfont, fct=function() self:more() end}
	local cx = self.doll_w + gap + self.list_w + gap
	self.uis_def = {
		{left=0, top=0, ui=self.c_doll},
		{left=self.doll_w + gap, top=0, ui=self.c_chips},
		{left=self.doll_w + gap, top=self.c_chips.h + 6 + self.banner_h, ui=self.c_list},
		{left=cx, top=0, ui=self.c_card},
		{left=cx, top=206, ui=self.c_desc},
		{left=cx, bottom=bh + 6, ui=self.b_primary},
		{left=cx, bottom=0, ui=self.b_drop},
		{left=cx + cw + 6, bottom=0, ui=self.b_transmo},
		{left=cx + 2 * (cw + 6), bottom=0, ui=self.b_more},
	}
end

--- Portrait (645x1398): one column. Chips across the top, the worn slots as a
-- grid under them, the list in the middle, a fixed bottom sheet with the compare
-- card, the description and the buttons. The paper doll (landscape) is parked
-- off-screen (hidden uis still take taps).
function _M:buildPortrait()
	local gap = 8
	local bh = 56
	self.doll_w = 330
	self.list_w = self.iw
	self.card_w = self.iw
	self.sheet_h = 520
	local chips = {}
	for _, t in ipairs(TABS) do if t.kind ~= "transmo" or self.actor:attr("has_transmo") then chips[#chips+1] = {title=t.short or t.title, kind=t.kind} end end
	self.c_chips = Chips.new{width=self.iw, items=chips, default="all", on_change=function(kind) self:switchTab(kind) end}
	self.banner_h = self.actor:attr("has_transmo") and 40 or 0
	-- what is worn, always in view between the chips and the list
	self.c_grid = WornGrid.new{width=self.iw, actor=self.actor, on_select=function(e, slot) self:selectWorn(e, slot) end}
	self.grid_top = self.c_chips.h + 6 + self.banner_h
	self.pane_top = self.grid_top + self.c_grid.h + 6
	self.sheet_y = self.ih - self.sheet_h
	self.pane_h = self.sheet_y - gap - self.pane_top
	-- the paper doll stays for landscape; in portrait it is parked off-screen for good
	self.c_doll = Doll.new{width=self.doll_w, height=self.pane_h, actor=self.actor, on_select=function(e, slot) self:selectWorn(e, slot) end, on_drag=function(e) self:startDrag(e) end}
	self.c_list = TouchItemList.new{width=self.iw, height=self.pane_h, actor=self.actor, scrollbar=true, items={},
		on_select=function(e) self:selectEntry(e) end, on_use=function(e) self:primary() end, on_drag=function(e) self:startDrag(e) end}
	self.c_card = Card.new{width=self.iw, height=200, actor=self.actor}
	self.desc_h = self.sheet_h - 200 - bh * 2 - 30
	self.c_desc = TextzoneList.new{focus_check=true, scrollbar=true, width=self.iw, height=self.desc_h, dest_area={h=self.desc_h}}
	-- Button adds 16 px of frame to the requested width
	self.b_primary = Button.new{text=_t"Select an item", width=self.iw - 16, font=self.bigfont, fct=function() self:primary() end}
	local cw = math.floor((self.iw - 16 - 12) / 3)
	self.b_drop = Button.new{text=_t"Drop", width=cw, font=self.bigfont, fct=function() self:act("drop") end}
	self.b_transmo = Button.new{text=_t"Transmog.", width=cw, font=self.bigfont, fct=function() self:act("transmo") end}
	self.b_more = Button.new{text=_t"More...", width=cw, font=self.bigfont, fct=function() self:more() end}
	self.uis_def = {
		{left=0, top=0, ui=self.c_chips},
		{left=0, top=self.grid_top, ui=self.c_grid},
		{left=math.floor((self.iw - self.doll_w) / 2), top=self.pane_top, ui=self.c_doll},
		{left=0, top=self.pane_top, ui=self.c_list},
		{left=0, top=self.sheet_y, ui=self.c_card},
		{left=0, top=self.sheet_y + 206, ui=self.c_desc},
		{left=0, bottom=bh + 6, ui=self.b_primary},
		{left=0, bottom=0, ui=self.b_drop},
		{left=cw + 6, bottom=0, ui=self.b_transmo},
		{left=2 * (cw + 6), bottom=0, ui=self.b_more},
	}
end

--- Park a ui off-screen (or bring it back to where setupUI put it)
function _M:park(ui, off)
	local e = self.ui_by_ui[ui]
	if not e then return end
	if off then
		if not e.home_x then e.home_x, e.home_y = e.x, e.y end
		e.x, e.y = 100000, 100000
	elseif e.home_x then
		e.x, e.y = e.home_x, e.home_y
	end
	e.hidden = off and true or false
	ui.mouse.delegate_offset_x, ui.mouse.delegate_offset_y = e.x, e.y
	if ui.positioned then ui:positioned(e.x, e.y, (self.display_x or 0) + e.x, (self.display_y or 0) + e.y) end
end

--- Portrait: the worn grid is always in view, the doll never (the list stays)
function _M:showPane()
	if not self.portrait then return end
	self:park(self.c_doll, true)
	self:park(self.c_list, false)
end

function _M:switchTab(kind)
	if not kind then return end
	self.tab = kind
	self.c_chips.cur = kind
	if kind == "transmo" then self.chest_mode = true end
	self:showPane()
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
		if not found and not self.cur.worn then self.cur = nil end
	end
	self:showCurrent()
end

function _M:wornFor(o)
	local wi = o and o:wornInven()
	local inv = wi and self.actor:getInven(wi)
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

--- Update the card, the description and the buttons for self.cur
function _M:showCurrent()
	local e = self.cur
	local o = e and e.object
	local worn = (o and not e.worn) and self:wornFor(o) or nil
	self.c_card:set(o, worn, o and self:kindOf(o) or nil)
	if self.c_grid then
		-- the cells a pack item would go into, or the worn item's own cell
		if o and e.worn then self.c_grid:setHilite(e.inven)
		elseif o and o:wornInven() and self.actor:getInven(o:wornInven()) then self.c_grid:setHilite(o:wornInven())
		else self.c_grid:setHilite(nil) end
	end
	self:fitDesc()
	self.c_desc:erase()
	if o then
		local ok, d = pcall(o.getDesc, o, {do_color=true}, (not e.worn) and o:wornInven() and self.actor:getInven(o:wornInven()) or nil, nil, self.actor)
		if ok and d then self.c_desc:switchItem(d, d) end
	end
	local name = self:primaryFor(e)
	self.b_primary.text = name or _t"Select an item"
	self.b_primary:generate()
	self.b_transmo.text = (o and o.__transmo) and _t"Keep" or _t"Transmog."
	self.b_transmo:generate()
end

-- the compare card grows with its stat rows: keep the description below it, scrolling in what is left
function _M:fitDesc()
	local h = math.max(90, self.c_card:contentHeight())
	if self.c_card.h == h and self.c_desc_h_fit == h then return end
	self.c_card.h = h
	local bh = 56
	local top = (self.sheet_y or 0) + h + 6
	local dh = math.max(60, self.ih - top - bh * 2 - 30)
	local old = self.c_desc
	self.c_desc = TextzoneList.new{focus_check=true, scrollbar=true, width=self.card_w, height=dh, dest_area={h=dh}}
	local entry = self.ui_by_ui[old]
	if entry then
		entry.ui = self.c_desc
		entry.y = self.iy + top
		self.ui_by_ui[old] = nil
		self.ui_by_ui[self.c_desc] = entry
	end
	self.desc_h = dh
	self.c_desc_h_fit = h
end

function _M:selectEntry(e)
	self.cur = e
	self.c_doll.sel = nil
	if self.c_grid then self.c_grid.sel = nil end
	if self.on_select_cb then pcall(self.on_select_cb, e) end
	self:showCurrent()
end

function _M:selectWorn(e, slot)
	self.c_list.sel = nil
	self.cur = e
	-- the grid or the doll called us; keep the other one's marker in step
	if self.c_grid and slot then self.c_grid.sel = nil for _, s in ipairs(self.c_grid.slots) do if s.id == slot.id and s.item == slot.item then self.c_grid.sel = s end end end
	self:showCurrent()
end

function _M:primaryFor(e)
	if not e then return nil end
	local o = e.object
	if self.chooser then return _t"Choose", "choose" end
	if e.worn or e.inven ~= self.actor.INVEN_INVEN then return _t"Take off", "takeoff" end
	if o:wornInven() and self.actor:getInven(o:wornInven()) then return _t"Wield / wear", "wear" end
	if o:canUseObject() then return _t"Use", "use" end
	if o.__transmo then return _t"Keep (to inventory)", "toinven" end
	return _t"Drop", "drop"
end

function _M:onUsed(stop)
	self:refresh()
	if self.actor.getEncumberTitleUpdator then self:updateTitle(self.actor:getEncumberTitleUpdator(self.base_title)()) end
	if stop then game:unregisterDialog(self) end
end

function _M:act(action)
	local e = self.cur
	if not e then return end
	if action == "transmo" and e.object.__transmo then action = "toinven" end
	print("[TOUCH] inventory", action, e.object.name)
	local UseItemDialog = require "mod.dialogs.UseItemDialog"
	local ud = UseItemDialog.new(false, self.actor, e.object, e.item, e.inven, function(_, _, _, stop) self:onUsed(stop) end)
	ud:use({action=action})
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
	self:act(act)
end

function _M:more()
	local e = self.cur
	if not e then return end
	local UseItemDialog = require "mod.dialogs.UseItemDialog"
	game:registerDialog(UseItemDialog.new(false, self.actor, e.object, e.item, e.inven, function(_, _, _, stop) self:onUsed(stop) end))
end

-- drag and drop --------------------------------------------------------
function _M:startDrag(e)
	if self.drag then return end
	if self.portrait then self.c_list.dragging = nil self.c_doll.dragging = nil return end
	self.drag = e
	self.cur = e
	self:showCurrent()
	print("[TOUCH] drag item", tostring(e.object.name), e.worn and "(worn)" or "")
end

function _M:dropTarget(x, y)
	local s = self.c_doll:slotAtScreen(x, y)
	if not s then return nil end
	local o = self.drag and self.drag.object
	local ok = false
	if o and not self.drag.worn and o:wornInven() then
		-- its own slot always fits (replacing what is there); other slots only if the game allows
		if self.actor:getInven(o:wornInven()) == self.actor.inven[s.id] then ok = true
		else local can, why = self.actor:canWearObject(o, s.def.short_name) ok = can and true or false if not ok then self.drop_why = why end end
	end
	return s, ok
end

function _M:dropAt(x, y)
	local e = self.drag
	self.c_list.dragging = nil
	self.c_doll.dragging = nil
	self.c_doll.drop_hint = nil
	if not e then return end
	local s, ok = self:dropTarget(x, y) -- needs self.drag: resolve before clearing it
	self.drag = nil
	if s and not e.worn then
		if not ok then game.logPlayer(self.actor, "%s does not go there.", e.object:getName{do_color=true}) print("[TOUCH] drop refused") return end
		print("[TOUCH] drop -> wear", tostring(e.object.name), s.def.name)
		local inv = self.actor:getInven(s.id)
		if inv and inv[s.item] then self.actor:doWear(e.inven, e.item, e.object, self.actor, s.id, s.item)
		else self.actor:doWear(e.inven, e.item, e.object, self.actor) end
		self:onUsed(false)
		return
	end
	local l = self.c_list
	if e.worn and l.last_screen_y and y >= l.last_screen_y and y <= l.last_screen_y + l.h and x >= l.last_screen_x and x <= l.last_screen_x + l.w then
		print("[TOUCH] drop -> take off", tostring(e.object.name))
		self:act("takeoff")
		return
	end
	print("[TOUCH] drop cancelled")
end

function _M:innerDisplay(x, y, nb_keyframes)
	-- chest hint strip under the chips
	if self.banner_h > 0 and self.tab == "transmo" then
		local bx, by = x + self.ix + (self.portrait and 0 or self.doll_w + 12), y + self.iy + self.c_chips.h + 4
		local strong = self.chest_mode
		K.quad(bx, by, self.list_w, self.banner_h - 4, strong and {60, 46, 16} or {29, 31, 38})
		local msg = strong and _t"Leaving the level: whatever stays in the chest is transmogrified into gold. Keep or wear what you want first." or _t"Items in the chest are transmogrified into gold when you leave the level."
		for i, l in ipairs(K.wrap(msg, K.font(12), self.list_w - 20, 2)) do K.draw(K.text(l, 12, 240, 220, 150, false, self.list_w - 20), bx + 10, by + 4 + (i - 1) * 16) end
	end
	local e = self.drag
	if not e then return end
	local t = require("engine.TouchInput").t
	if not t then return end
	local s, ok = self:dropTarget(t.x, t.y)
	self.c_doll.drop_hint, self.c_doll.drop_ok = (s and not e.worn) and s or nil, ok
	-- innerDisplay draws in the dialog's translated space: convert the finger position
	pcall(e.object.toScreen, e.object, nil, x + (t.x - (self.display_x or 0)) - 32, y + (t.y - (self.display_y or 0)) - 80, 64, 64)
end

--- Rotation: build a fresh dialog for the new orientation carrying the tab and the selection
function _M:touch_reopen()
	local a = self.touch_args
	local nd = _M.new(a.title, a.actor, a.filter, a.action, a.on_select)
	nd.chest_mode = self.chest_mode
	local tab = self.tab
	if tab == "worn" then tab = "all" end
	if tab and tab ~= nd.tab then nd:switchTab(tab) end
	local cur = self.cur
	if cur and cur.object then
		if cur.worn then
			nd.cur = {object=cur.object, inven=cur.inven, item=cur.item, worn=true}
			for _, sl in ipairs(nd.c_doll.slots) do if sl.id == cur.inven and sl.item == cur.item then nd.c_doll.sel = sl end end
			if nd.c_grid then for _, sl in ipairs(nd.c_grid.slots) do if sl.id == cur.inven and sl.item == cur.item then nd.c_grid.sel = sl end end end
		else
			for i, e in ipairs(nd.c_list.items) do if e.object == cur.object then nd.c_list:select(i, true) nd.cur = e end end
		end
		nd:showCurrent()
	end
	return nd
end

function _M:generateList() self:refresh() end
function _M:generate() Dialog.generate(self) end
function _M:unload()
	require("engine.TouchInput").on_hover_end = nil
	local inven = self.actor:getInven(self.actor.INVEN_INVEN)
	if inven then for _, o in ipairs(inven) do o:forAllStack(function(so) so.__new_pickup = nil end) end end
end
