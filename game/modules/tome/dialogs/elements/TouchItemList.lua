-- ToME - Tales of Maj'Eyal
-- iOS port: a finger-sized list of objects (inventory, shops). Rows show the
-- icon, the coloured name, a short stats line and an upgrade hint. Tap a row
-- to select it; drag or wheel to scroll (engine.ui.Dialog turns drags into
-- scrollbar moves).

require "engine.class"
local Base = require "engine.ui.Base"
local Focusable = require "engine.ui.Focusable"
local Slider = require "engine.ui.Slider"

module(..., package.seeall, class.inherit(Base, Focusable))

--- Rough worth of an item for the "better?" hint: weapons by the actor's own
-- damage estimate, everything else by price
function _M.score(actor, o)
	if not o then return -1 end
	if o.combat and o.combat.dam and not o.archery and not o.archery_ammo then
		local ok, d = pcall(actor.combatDamage, actor, o.combat)
		if ok and d then return 1000 + d * 10 end
	end
	local ok, p = pcall(o.getPrice, o)
	return ok and tonumber(p) or 0
end

--- "better", "worse", "empty slot" or nil, comparing with what is worn there
function _M.verdict(actor, o)
	if not actor or not o or o.__transmo then return nil end
	local wi = o:wornInven()
	if not wi then return nil end
	local inv = actor:getInven(wi)
	if not inv then return nil end
	if #inv == 0 then return "empty" end
	local best = -1
	for _, w in ipairs(inv) do if w ~= o then best = math.max(best, _M.score(actor, w)) end end
	if best < 0 then return nil end
	local s = _M.score(actor, o)
	if s > best * 1.1 then return "better" elseif s < best * 0.9 then return "worse" end
	return nil
end

function _M:init(t)
	self.w = assert(t.width, "no width")
	self.h = assert(t.height, "no height")
	self.actor = t.actor
	self.on_select = t.on_select
	self.on_use = t.on_use
	self.items = t.items or {}
	self.icon_size = 48
	self.row_h = 66
	self.scrollbar = t.scrollbar
	self.scroll_inertia = 0
	Base.init(self, t)
end

function _M:generate()
	self.mouse:reset()
	self.key:reset()
	self.scroll_inertia = 0
	if self.scrollbar then self.scrollbar = Slider.new{size=self.h, max=1} end
	self.texts = {}
	self:setItems(self.items)
	self.mouse:registerZone(0, 0, self.w, self.h, function(button, x, y, xrel, yrel, bx, by, event)
		if event == "button" and button == "wheelup" then if self.scrollbar then self.scroll_inertia = math.min(self.scroll_inertia, 0) - 5 end return
		elseif event == "button" and button == "wheeldown" then if self.scrollbar then self.scroll_inertia = math.max(self.scroll_inertia, 0) + 5 end return end
		if event ~= "button" or (button ~= "left" and button ~= "right") then return end
		local sy = y + (self.scrollbar and self.scrollbar.pos or 0)
		local i = math.floor(sy / self.row_h) + 1
		local e = self.items[i]
		if not e then return end
		if button == "right" then if self.on_use then self.on_use(e) end return end
		self:select(i)
	end)
	self.key:addBinds{
		ACCEPT = function() local e = self.items[self.sel or 0] if e and self.on_use then self.on_use(e) end end,
		MOVE_UP = function() self:select(math.max(1, (self.sel or 1) - 1)) end,
		MOVE_DOWN = function() self:select(math.min(#self.items, (self.sel or 0) + 1)) end,
	}
end

function _M:select(i, silent)
	self.sel = i
	local e = self.items[i]
	if e and self.on_select and not silent then self.on_select(e) end
end

function _M:text(str, r, g, b, bold)
	local key = str.."|"..r..","..g..","..b..(bold and "b" or "")
	local d = self.texts[key]
	if not d then
		if bold then self.font:setStyle("bold") end
		-- font:draw returns a texture as wide as asked; measure the text (markup stripped) first
		local w = self.font:size((str:gsub("#[^#]*#", ""))) + 8
		local list = self.font:draw(str, w, r, g, b, true)
		if bold then self.font:setStyle("normal") end
		d = list and list[1] or nil
		if d then d.w = math.min(d.w, w) end
		self.texts[key] = d
	end
	return d
end

function _M:drawText(d, x, y, maxw)
	if not d then return end
	local w = math.min(d.w, maxw or d.w)
	d._tex:toScreenFull(x + 2, y + 2, w, d.h, d._tex_w, d._tex_h, 0, 0, 0, 0.7)
	d._tex:toScreenFull(x, y, w, d.h, d._tex_w, d._tex_h)
end

local function subtitle(o)
	local parts = {}
	if o.type then parts[#parts+1] = tostring(o.subtype or o.type) end
	if o.combat and o.combat.dam then parts[#parts+1] = ("dmg %d"):format(o.combat.dam) end
	if o.wielder and o.wielder.combat_armor then parts[#parts+1] = ("armour %d"):format(o.wielder.combat_armor) end
	if o.wielder and o.wielder.combat_def then parts[#parts+1] = ("def %d"):format(o.wielder.combat_def) end
	if o.encumber then parts[#parts+1] = ("%0.1f enc"):format(o.encumber) end
	return table.concat(parts, "  ·  ")
end

function _M:setItems(items)
	self.items = items or {}
	self.texts = self.texts or {}
	for _, e in ipairs(self.items) do
		local o = e.object
		local ok, name = pcall(o.getName, o, {do_color=true})
		e.text_name = self:text(ok and tostring(name) or tostring(o.name), 255, 255, 255)
		e.text_sub = self:text(e.sub or subtitle(o), 170, 165, 150)
		if e.price then e.text_price = self:text(tostring(e.price), 240, 212, 138, true) end
		local v = e.verdict
		if v == nil and self.actor then v = _M.verdict(self.actor, o) end
		if v == "better" then e.text_badge = self:text(_t"likely better", 120, 230, 120, true)
		elseif v == "worse" then e.text_badge = self:text(_t"worse", 150, 150, 150)
		elseif v == "empty" then e.text_badge = self:text(_t"empty slot", 240, 212, 138)
		else e.text_badge = nil end
	end
	if self.scrollbar then
		self.scrollbar.max = math.max(0, #self.items * self.row_h - self.h + 8)
		self.scrollbar.pos = util.minBound(self.scrollbar.pos or 0, 0, self.scrollbar.max)
	end
	if self.sel and self.sel > #self.items then self.sel = nil end
end

function _M:display(x, y, nb_keyframes, screen_x, screen_y)
	if self.scrollbar then
		self.scrollbar.pos = util.minBound(self.scrollbar.pos + self.scroll_inertia, 0, self.scrollbar.max)
		if self.scroll_inertia > 0 then self.scroll_inertia = math.max(self.scroll_inertia - 1, 0)
		elseif self.scroll_inertia < 0 then self.scroll_inertia = math.min(self.scroll_inertia + 1, 0) end
		if self.scrollbar.pos == 0 or self.scrollbar.pos == self.scrollbar.max then self.scroll_inertia = 0 end
	end
	local sy = self.scrollbar and -self.scrollbar.pos or 0
	local right = self.w - (self.scrollbar and self.scrollbar.w + 6 or 0)
	core.display.glScissor(true, screen_x, screen_y, self.w, self.h)
	for i, e in ipairs(self.items) do
		local ry = y + sy + (i - 1) * self.row_h
		if ry + self.row_h >= y and ry <= y + self.h then
			if i == self.sel then core.display.drawQuad(x, ry, right, self.row_h - 2, 255, 215, 0, 35)
			elseif i % 2 == 0 then core.display.drawQuad(x, ry, right, self.row_h - 2, 255, 255, 255, 8) end
			local o = e.object
			local ix, iy = x + 8, ry + (self.row_h - self.icon_size) / 2
			pcall(o.toScreen, o, nil, ix, iy, self.icon_size, self.icon_size)
			if e.worn then core.display.drawQuad(ix - 2, iy + self.icon_size, self.icon_size + 4, 2, 120, 230, 120, 255) end
			local tx = ix + self.icon_size + 12
			local maxw = right - tx - 8
			if e.text_price then maxw = maxw - e.text_price.w - 12 end
			if e.text_badge then maxw = maxw - e.text_badge.w - 12 end
			self:drawText(e.text_name, tx, ry + 8, maxw)
			self:drawText(e.text_sub, tx, ry + 10 + (e.text_name and e.text_name.h or 20), maxw)
			local rx = x + right - 8
			if e.text_price then rx = rx - e.text_price.w self:drawText(e.text_price, rx, ry + 10) rx = rx - 12 end
			if e.text_badge then rx = rx - e.text_badge.w self:drawText(e.text_badge, rx, ry + 10) end
		end
	end
	core.display.glScissor(false)
	if self.scrollbar and self.scrollbar.max > 0 then self.scrollbar:display(x + self.w - self.scrollbar.w, y) end
end
