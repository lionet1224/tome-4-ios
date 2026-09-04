-- ToME - Tales of Maj'Eyal
-- iOS port: a finger-sized list of "label ...... value" rows with section
-- headers, for the touch character sheet. Tap a row to select it (the
-- sheet shows its explanation); drag or wheel to scroll.

require "engine.class"
local Base = require "engine.ui.Base"
local Focusable = require "engine.ui.Focusable"
local Slider = require "engine.ui.Slider"

module(..., package.seeall, class.inherit(Base, Focusable))

function _M:init(t)
	self.w = assert(t.width, "no width")
	self.h = assert(t.height, "no height")
	self.rows = t.rows or {}
	self.on_select = t.on_select
	self.row_h = 44
	self.head_h = 40
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
	self:setRows(self.rows)
	self.mouse:registerZone(0, 0, self.w, self.h, function(button, x, y, xrel, yrel, bx, by, event)
		if event == "button" and button == "wheelup" then if self.scrollbar then self.scroll_inertia = math.min(self.scroll_inertia, 0) - 5 end return
		elseif event == "button" and button == "wheeldown" then if self.scrollbar then self.scroll_inertia = math.max(self.scroll_inertia, 0) + 5 end return end
		if event ~= "button" or button ~= "left" then return end
		local sy = y + (self.scrollbar and self.scrollbar.pos or 0)
		for i, r in ipairs(self.rows) do
			if sy >= r.y1 and sy < r.y2 and not r.head then self.sel = i if self.on_select then self.on_select(r) end return end
		end
	end)
end

function _M:text(str, r, g, b, bold)
	local key = str.."|"..r..","..g..","..b..(bold and "b" or "")
	local d = self.texts[key]
	if not d then
		if bold then self.font:setStyle("bold") end
		local w = self.font:size((str:gsub("#[^#]*#", ""))) + 8
		local list = self.font:draw(str, w, r, g, b, true)
		if bold then self.font:setStyle("normal") end
		d = list and list[1] or nil
		if d then d.w = math.min(d.w, w) end
		self.texts[key] = d
	end
	return d
end

function _M:drawText(d, x, y)
	if not d then return end
	d._tex:toScreenFull(x + 2, y + 2, d.w, d.h, d._tex_w, d._tex_h, 0, 0, 0, 0.7)
	d._tex:toScreenFull(x, y, d.w, d.h, d._tex_w, d._tex_h)
end

function _M:setRows(rows)
	self.rows = rows or {}
	local y = 0
	for _, r in ipairs(self.rows) do
		if r.head then
			r.text_label = self:text(r.label, 130, 200, 255, true)
			r.y1, r.y2 = y, y + self.head_h
			y = y + self.head_h
		else
			r.text_label = self:text(r.label or "", 235, 230, 215)
			r.text_value = r.value and r.value ~= "" and self:text(r.value, 120, 255, 120) or nil
			r.y1, r.y2 = y, y + self.row_h
			y = y + self.row_h
		end
	end
	self.max_h = y
	if self.scrollbar then
		self.scrollbar.max = math.max(0, self.max_h - self.h + 8)
		self.scrollbar.pos = util.minBound(self.scrollbar.pos or 0, 0, self.scrollbar.max)
	end
	self.sel = nil
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
	for i, r in ipairs(self.rows) do
		local ry = y + sy + r.y1
		local rh = r.y2 - r.y1
		if ry + rh >= y and ry <= y + self.h then
			if r.head then
				core.display.drawQuad(x, ry + 6, right, rh - 8, 30, 34, 44, 200)
				core.display.drawQuad(x, ry + rh - 3, right, 1, 130, 200, 255, 120)
				if r.text_label then self:drawText(r.text_label, x + 10, ry + (rh - r.text_label.h) / 2 + 2) end
			else
				if i == self.sel then core.display.drawQuad(x, ry, right, rh - 2, 255, 215, 0, 35)
				elseif i % 2 == 0 then core.display.drawQuad(x, ry, right, rh - 2, 255, 255, 255, 8) end
				if r.text_label then self:drawText(r.text_label, x + 16, ry + (rh - r.text_label.h) / 2) end
				if r.text_value then self:drawText(r.text_value, x + right - 12 - r.text_value.w, ry + (rh - r.text_value.h) / 2) end
			end
		end
	end
	core.display.glScissor(false)
	if self.scrollbar and self.scrollbar.max > 0 then self.scrollbar:display(x + self.w - self.scrollbar.w, y) end
end
