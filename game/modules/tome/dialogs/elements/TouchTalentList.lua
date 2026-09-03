-- ToME - Tales of Maj'Eyal
-- iOS port: a vertical, finger-sized talent/stat list for the level-up
-- dialog. One row per talent or stat with big + and - buttons; category
-- headers expand/collapse on tap. Scrolls by drag (engine.ui.Dialog turns a
-- finger drag into scrollbar.pos changes) or wheel.

require "engine.class"
local Base = require "engine.ui.Base"
local Focusable = require "engine.ui.Focusable"
local Slider = require "engine.ui.Slider"
local Tiles = require "engine.Tiles"

module(..., package.seeall, class.inherit(Base, Focusable))

local function asString(item, v)
	if type(v) == "function" then v = v(item) end
	if type(v) == "table" and v.toString then return v:toString() end
	return tostring(v or "")
end

function _M:init(t)
	self.tree = t.tree or {}
	self.w = assert(t.width, "no width")
	self.h = assert(t.height, "no height")
	self.tooltip = assert(t.tooltip, "no tooltip")
	self.on_use = assert(t.on_use, "no on_use")
	self.on_expand = t.on_expand
	self.can_add = t.can_add -- function(item) -> are there points to spend on it
	self.no_cross = t.no_cross
	self.icon_size = 48
	self.row_h = 68
	self.head_h = 46
	self.btn_w, self.btn_h = 62, 54
	self.scrollbar = t.scrollbar
	self.scroll_inertia = 0
	self.tiles = Tiles.new(self.icon_size, self.icon_size, "/data/font/DroidSansMono.ttf", 10, true, true)
	self.tiles.use_images = true
	self.tiles.force_back_color = {r=0, g=0, b=0}
	self.plus = _M:getUITexture("ui/plus.png")
	self.minus = _M:getUITexture("ui/minus.png")
	self.bfont = core.display.newFont(require("engine.FontPackage"):getFont("default"), 28)
	Base.init(self, t)
end

function _M:generate()
	self.mouse:reset()
	self.key:reset()
	self.scroll_inertia = 0
	if self.scrollbar then self.scrollbar = Slider.new{size=self.h, max=1} end
	self.rows = {}
	self.texts = {}
	self:redrawAllItems()

	self.mouse:registerZone(0, 0, self.w, self.h, function(button, x, y, xrel, yrel, bx, by, event)
		if event == "button" and button == "wheelup" then if self.scrollbar then self.scroll_inertia = math.min(self.scroll_inertia, 0) - 5 end return
		elseif event == "button" and button == "wheeldown" then if self.scrollbar then self.scroll_inertia = math.max(self.scroll_inertia, 0) + 5 end return end
		if event ~= "button" or (button ~= "left" and button ~= "right") then return end
		local sy = y + (self.scrollbar and self.scrollbar.pos or 0)
		for _, r in ipairs(self.rows) do
			if sy >= r.y1 and sy < r.y2 then
				local item = r.item
				local right = self.w - (self.scrollbar and self.scrollbar.w + 6 or 0)
				local px, mx = right - self.btn_w - 6, right - 2 * self.btn_w - 12
				if x >= px then
					print("[TOUCH] levelup +", asString(item, item.name or item.rawname))
					self:select(item)
					self.on_use(item, true)
				elseif x >= mx then
					print("[TOUCH] levelup -", asString(item, item.name or item.rawname))
					self:select(item)
					self.on_use(item, false)
				elseif button == "right" then
					self.on_use(item, false)
				elseif item.type then
					self:onExpand(item)
				else
					self:select(item)
				end
				return
			end
		end
	end)
	self.key:addBinds{
		ACCEPT = function() if self.sel_item then self.on_use(self.sel_item, true) end end,
	}
end

function _M:selectFirst()
	for _, r in ipairs(self.rows) do if not r.head then self:select(r.item) return end end
end

function _M:select(item)
	self.sel_item = item
	self.tooltip(item)
end

function _M:updateTooltip()
	if self.sel_item then self.tooltip(self.sel_item) end
end

function _M:onUse(item, inc)
	self.on_use(item, inc)
end

function _M:onExpand(item, inc)
	item.shown = not item.shown
	if self.on_expand then self.on_expand(item) end
	self:redrawAllItems()
end

function _M:text(str, r, g, b, bold, big)
	local key = str.."|"..r..","..g..","..b..(bold and "b" or "")..(big and "B" or "")
	local d = self.texts[key]
	if not d then
		local font = big and self.bfont or self.font
		if bold then font:setStyle("bold") end
		d = font:draw(str, font:size(str), r, g, b, true)[1]
		if bold then font:setStyle("normal") end
		self.texts[key] = d
	end
	return d
end

function _M:drawText(d, x, y, shadow)
	if not d then return end
	if shadow then d._tex:toScreenFull(x + 2, y + 2, d.w, d.h, d._tex_w, d._tex_h, 0, 0, 0, 0.7) end
	d._tex:toScreenFull(x, y, d.w, d.h, d._tex_w, d._tex_h)
end

function _M:redrawAllItems()
	self.texts = {}
	local rows = {}
	local y = 0
	for i = 1, #self.tree do
		local tree = self.tree[i]
		if tree.type then
			local c = tree:color()
			tree.text_name = self:text(asString(tree, tree.rawname), c[1], c[2], c[3], true)
			rows[#rows+1] = {item=tree, y1=y, y2=y + self.head_h, head=true}
			y = y + self.head_h
		end
		if tree.shown then
			for j = 1, #tree.nodes do
				local tal = tree.nodes[j]
				local c = tal:color()
				local changed = c[1] == 255 and c[2] == 215 and c[3] == 0
				local shadow = util.getval(tal.do_shadow, tal) and not changed
				tal.touch_changed, tal.touch_shadow = changed, shadow
				local nr, ng, nb = 255, 255, 255
				if shadow then nr, ng, nb = 140, 140, 140 elseif changed then nr, ng, nb = 255, 215, 0 end
				tal.text_name = self:text(asString(tal, tal.name), nr, ng, nb)
				local st = asString(tal, tal.status)
				if changed then st = st:gsub("#[^#]*#", "") end -- plain, in gold
				tal.text_status = self:text(st, c[1], c[2], c[3])
				rows[#rows+1] = {item=tal, y1=y, y2=y + self.row_h}
				y = y + self.row_h
			end
		end
		y = y + 6
	end
	self.rows = rows
	self.max_h = y
	if self.scrollbar then
		self.scrollbar.max = math.max(0, self.max_h - self.h + 8)
		self.scrollbar.pos = util.minBound(self.scrollbar.pos or 0, 0, self.scrollbar.max)
	end
end

function _M:drawButtons(x, y, can_minus, can_plus)
	local bw, bh = self.btn_w, self.btn_h
	local by = y + 6
	local right = self.w - (self.scrollbar and self.scrollbar.w + 6 or 0)
	local mx, px = x + right - 2 * bw - 12, x + right - bw - 6
	local am, ap = can_minus and 230 or 90, can_plus and 230 or 90
	core.display.drawQuad(mx, by, bw, bh, 30, 28, 24, am)
	core.display.drawQuad(px, by, bw, bh, 42, 34, 16, ap)
	core.display.drawQuad(mx, by, bw, 2, 59, 52, 39, am) core.display.drawQuad(mx, by + bh - 2, bw, 2, 59, 52, 39, am)
	core.display.drawQuad(px, by, bw, 2, 140, 112, 48, ap) core.display.drawQuad(px, by + bh - 2, bw, 2, 140, 112, 48, ap)
	local m = can_minus and self:text("-", 255, 215, 0, true, true) or self:text("-", 90, 86, 76, true, true)
	local p = can_plus and self:text("+", 240, 212, 138, true, true) or self:text("+", 90, 86, 76, true, true)
	self:drawText(m, mx + (bw - m.w) / 2, by + (bh - m.h) / 2)
	self:drawText(p, px + (bw - p.w) / 2, by + (bh - p.h) / 2)
end

function _M:drawRow(r, x, y)
	local item = r.item
	if r.head then
		core.display.drawQuad(x, y, self.w, self.head_h - 2, 32, 30, 26, 200)
		local cross = item.shown and self.minus or self.plus
		local tx = x + 8
		if not self.no_cross then
			cross.t:toScreenFull(tx, y + (self.head_h - cross.h) / 2, cross.w, cross.h, cross.tw, cross.th)
			tx = tx + cross.w + 8
		end
		self:drawText(item.text_name, tx, y + (self.head_h - item.text_name.h) / 2, true)
		local c = item:color()
		local changed = c[1] == 255 and c[2] == 215 and c[3] == 0
		self:drawButtons(x, y - 4, changed, not self.can_add or self.can_add(item))
		return
	end
	if item == self.sel_item then core.display.drawQuad(x, y, self.w, self.row_h - 2, 255, 215, 0, 35) end
	local ix, iy = x + 8, y + (self.row_h - self.icon_size) / 2
	item.entity:toScreen(self.tiles, ix, iy, self.icon_size, self.icon_size)
	if item.touch_shadow then core.display.drawQuad(ix, iy, self.icon_size, self.icon_size, 0, 0, 0, 170) end
	local c = item:color()
	core.display.drawQuad(ix - 2, iy - 2, self.icon_size + 4, 2, c[1], c[2], c[3], 255)
	core.display.drawQuad(ix - 2, iy + self.icon_size, self.icon_size + 4, 2, c[1], c[2], c[3], 255)
	core.display.drawQuad(ix - 2, iy, 2, self.icon_size, c[1], c[2], c[3], 255)
	core.display.drawQuad(ix + self.icon_size, iy, 2, self.icon_size, c[1], c[2], c[3], 255)
	local tx = ix + self.icon_size + 12
	self:drawText(item.text_name, tx, y + 8, true)
	self:drawText(item.text_status, tx, y + 10 + item.text_name.h, true)
	local can_plus = not item.touch_shadow and (not self.can_add or self.can_add(item))
	self:drawButtons(x, y + (self.row_h - self.btn_h) / 2 - 6, item.touch_changed, can_plus)
end

function _M:display(x, y, nb_keyframes, screen_x, screen_y)
	self.last_display_x, self.last_display_y = screen_x, screen_y
	if self.scrollbar then
		self.scrollbar.pos = util.minBound(self.scrollbar.pos + self.scroll_inertia, 0, self.scrollbar.max)
		if self.scroll_inertia > 0 then self.scroll_inertia = math.max(self.scroll_inertia - 1, 0)
		elseif self.scroll_inertia < 0 then self.scroll_inertia = math.min(self.scroll_inertia + 1, 0) end
		if self.scrollbar.pos == 0 or self.scrollbar.pos == self.scrollbar.max then self.scroll_inertia = 0 end
	end
	local sy = self.scrollbar and -self.scrollbar.pos or 0
	core.display.glScissor(true, screen_x, screen_y, self.w, self.h)
	for _, r in ipairs(self.rows) do
		local ry = y + sy + r.y1
		if ry + (r.y2 - r.y1) >= y and ry <= y + self.h then self:drawRow(r, x, ry) end
	end
	core.display.glScissor(false)
	if self.scrollbar and self.scrollbar.max > 0 then self.scrollbar:display(x + self.w - self.scrollbar.w, y) end
end
