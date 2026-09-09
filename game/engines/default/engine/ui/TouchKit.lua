-- ToME iOS port: shared pieces for the touch dialogs (birther, chat, talents...).
-- Text cache, flat drawing helpers, word wrap, and two widgets: Rail (step list)
-- and Flow (sections of finger-sized cards in one drag-scrolling pane).

require "engine.class"
local Base = require "engine.ui.Base"
local Focusable = require "engine.ui.Focusable"
local Slider = require "engine.ui.Slider"
local FontPackage = require "engine.FontPackage"

module(..., package.seeall)

local GOLD = {210, 170, 74}
local CARD = {29, 31, 38}
local CARD_SEL = {43, 39, 24}
local PANE = {24, 26, 32}

-- shared text cache: one texture per (font size, string, colour)
local fonts = {}
-- touch.ui_scale (0.9 / 1 / 1.1) scales every kit font; layouts keep their pixel
-- boxes, so the range is deliberately narrow
local function uiScale()
	local ok, TI = pcall(require, "engine.TouchInput")
	local v = ok and TI.setting and tonumber(TI.setting("ui_scale")) or 1
	if not v or v < 0.8 or v > 1.5 then v = 1 end
	return v
end
local function font(size)
	local sz = math.floor(size * uiScale() + 0.5)
	if not fonts[sz] then fonts[sz] = core.display.newFont(FontPackage:getFont("default"), sz) end
	return fonts[sz]
end
_M.uiScale = uiScale
local texts = {}
local function text(str, size, r, g, b, bold, maxw)
	str = tostring(str or "")
	local f = font(size)
	-- measure in the style we draw with: bold glyphs are wider
	if bold then f:setStyle("bold") end
	if maxw then
		-- ellipsis when the string does not fit
		local plain = str:gsub("#[^#]*#", "")
		if f:size(plain) > maxw then
			local n = #plain
			while n > 1 and f:size(plain:sub(1, n) .. "...") > maxw do n = n - 1 end
			str = plain:sub(1, n) .. "..."
		end
	end
	local key = size .. "@" .. uiScale() .. "|" .. r .. "," .. g .. "," .. b .. (bold and "b" or "") .. "|" .. str
	local d = texts[key]
	if not d then
		local w = f:size((str:gsub("#[^#]*#", ""))) + 6
		local list = f:draw(str, w, r, g, b, true)
		d = list and list[1] or false
		if d then d.w = math.min(d.w, w) end
		texts[key] = d
	end
	if bold then f:setStyle("normal") end
	return d or nil
end
-- Untextured quads are batched: quad()/frame() append to a flat list and
-- flush() issues one draw (core.display.drawQuadBatch). Anything that draws
-- something else (text, textures, ring wedges, a scissor change) must flush
-- first so the draw order stays exactly what the caller wrote.
local batch, batch_n = {}, 0
local batched = core.display.drawQuadBatch ~= nil
-- batching is only on inside code that knows where its ordering boundaries are
-- (Flow/Rail displays, or a caller between beginBatch() and endBatch()); every
-- other quad draws immediately, so dialogs mixing kit quads with engine widgets
-- keep their order
local batching = false
local function flush()
	if batch_n == 0 then return end
	core.display.drawQuadBatch(batch, batch_n)
	batch_n = 0
end
local function quad(x, y, w, h, c, a)
	if not (batched and batching) then core.display.drawQuad(x, y, w, h, c[1], c[2], c[3], a or 255) return end
	local i = batch_n * 8
	batch[i + 1], batch[i + 2], batch[i + 3], batch[i + 4] = x, y, w, h
	batch[i + 5], batch[i + 6], batch[i + 7], batch[i + 8] = c[1], c[2], c[3], a or 255
	batch_n = batch_n + 1
	if batch_n >= 2048 then flush() end
end
local function draw(d, x, y, a)
	if not d then return 0 end
	flush()
	d._tex:toScreenFull(x, y, d.w, d.h, d._tex_w, d._tex_h, 1, 1, 1, a or 1)
	return d.w
end
local function frame(x, y, w, h, c, t)
	t = t or 2
	quad(x, y, w, t, c) quad(x, y + h - t, w, t, c) quad(x, y, t, h, c) quad(x + w - t, y, t, h, c)
end
local function circle(cx, cy, r, c, a, ring)
	flush()
	if core.display.drawRingWedge then core.display.drawRingWedge(cx, cy, ring or 0, r, 0, 360, c[1], c[2], c[3], math.floor((a or 1) * 255)) end
end
-- greedy word wrap into at most n lines; the last line carries the rest (ellipsis by text())
local function wrap(str, f, maxw, n)
	local lines, line = {}, ""
	local words = {}
	for w in tostring(str or ""):gmatch("%S+") do words[#words+1] = w end
	local i = 1
	while i <= #words do
		local try = line == "" and words[i] or (line .. " " .. words[i])
		if f:size(try) > maxw and line ~= "" then
			if #lines == n - 1 then line = line .. " " .. table.concat(words, " ", i) break end
			lines[#lines+1] = line line = ""
		else line = try i = i + 1 end
	end
	if line ~= "" then lines[#lines+1] = line end
	return lines
end
-- true while a finger rests (no drag yet) inside a screen-space rect: press feedback
local function pressed(x, y, w, h)
	local TI = require "engine.TouchInput"
	local t = TI.active() and TI.t
	if not t or t.moved or not t.x0 then return false end
	return t.x0 >= x and t.x0 < x + w and t.y0 >= y and t.y0 < y + h
end
-- first sentence of a description, for the one-line pitch on a card
local function pitch(desc)
	if type(desc) == "table" then
		-- descriptors often open with a one-line title ("#GOLD#Normal mode#WHITE#"): skip it
		local first = tostring(desc[1] or ""):gsub("#[^#]*#", "")
		if #desc > 1 and #first < 40 and not first:find("[%.!?]") then desc = desc[2] else desc = desc[1] end
	end
	desc = tostring(desc or ""):gsub("#[^#]*#", ""):gsub("^%s+", "")
	-- same title-line convention inside a single string ("Normal mode\nProvides ...")
	local first, rest = desc:match("^([^\n]*)\n%s*(.+)$")
	if first and #first < 40 and not first:find("[%.!?]") then desc = rest end
	local s = desc:match("^(.-[%.!?])%s") or desc
	if #s > 90 then s = s:sub(1, 88) .. "..." end
	return s
end

---------------------------------------------------------------------------
-- Rail: the step list on the left
---------------------------------------------------------------------------
local Rail = class.inherit(Base, Focusable){}
function Rail:init(t)
	self.w, self.h = t.width, t.height
	self.steps = t.steps -- {name=, value=fct, reach=fct, done=fct}
	self.on_pick = t.on_pick
	self.row_h = 60
	Base.init(self, t)
end
function Rail:generate()
	self.mouse:reset()
	self.key:reset()
	self.mouse:registerZone(0, 0, self.w, self.h, function(button, x, y, xrel, yrel, bx, by, event)
		if event ~= "button" or button ~= "left" then return end
		local i = math.floor((y - 6) / (self.row_h + 4)) + 1
		if self.steps[i] then self.on_pick(i) end
	end)
end
function Rail:display(x, y, nb_keyframes)
	local was = batching
	batching = true
	for i, s in ipairs(self.steps) do
		local ry = y + 6 + (i - 1) * (self.row_h + 4)
		local cur = i == self.cur
		local done = s.done() and i ~= self.cur
		local reach = s.reach()
		local a = reach and 1 or 0.35
		if cur then quad(x + 4, ry, self.w - 8, self.row_h, {36, 39, 47}) end
		local cx, cy = x + 26, ry + self.row_h / 2
		if done then circle(cx, cy, 15, {123, 211, 137}, a) circle(cx, cy, 6, {16, 32, 26}, a)
		else
			circle(cx, cy, 15, cur and GOLD or {60, 63, 72}, a, 13)
			draw(text(tostring(i), 14, cur and 240 or 150, cur and 212 or 150, cur and 138 or 150, true), cx - 5, cy - 10, a)
		end
		local v = s.value()
		local ny = (v and v ~= "") and ry + 10 or ry + 18
		draw(text(s.name, 16, cur and 234 or 200, cur and 227 or 195, cur and 209 or 180, cur), x + 50, ny, a)
		if v and v ~= "" then draw(text(v, 12, 142, 136, 120, false, self.w - 58), x + 50, ry + 34, a) end
	end
	flush()
	batching = was
end

---------------------------------------------------------------------------
-- Flow: sections of cards, one pixel scroller (drag to scroll)
---------------------------------------------------------------------------
local Flow = class.inherit(Base, Focusable){}
function Flow:init(t)
	self.w, self.h = t.width, t.height
	self.sections = {}
	self.scrollbar = Slider.new{size=self.h, max=1}
	self.scroll_inertia = 0
	Base.init(self, t)
end
function Flow:generate()
	self.mouse:reset()
	self.key:reset()
	self.mouse:registerZone(0, 0, self.w, self.h, function(button, x, y, xrel, yrel, bx, by, event)
		if event == "button" and button == "wheelup" then self.scroll_inertia = math.min(self.scroll_inertia, 0) - 5 return
		elseif event == "button" and button == "wheeldown" then self.scroll_inertia = math.max(self.scroll_inertia, 0) + 5 return end
		if event ~= "button" or button ~= "left" then return end
		local sy = y + self.scrollbar.pos
		for _, sec in ipairs(self.sections) do
			for _, it in ipairs(sec.items) do
				if x >= it.x and x < it.x + it.w and sy >= it.y and sy < it.y + it.h then
					if it.on_tap then it.on_tap(it) end
					return
				end
			end
		end
	end)
end
-- sections: {title=, items={{name, sub, icon=fct(x,y,size), locked, sel, on_tap}}, cols=, min_w=, row_h=, spacer=}
function Flow:setSections(sections)
	self.sections = sections
	local y = 4
	local gap = 8
	for _, sec in ipairs(sections) do
		y = y + (sec.spacer or 0)
		if sec.title then sec.ty = y y = y + 30 end
		local cols = sec.cols or math.max(1, math.floor((self.w - 4 + gap) / ((sec.min_w or 170) + gap)))
		local cw = math.floor((self.w - 4 - (cols - 1) * gap) / cols)
		local rh = sec.row_h or 92
		for i, it in ipairs(sec.items) do
			local c, r = (i - 1) % cols, math.floor((i - 1) / cols)
			it.x, it.y, it.w, it.h = 2 + c * (cw + gap), y + r * (rh + gap), cw, rh
		end
		local rows = math.ceil(#sec.items / cols)
		y = y + rows * (rh + gap) + 10
	end
	self.total_h = y
	self.scrollbar.max = math.max(0, y - self.h)
	self.scrollbar.pos = util.minBound(self.scrollbar.pos, 0, self.scrollbar.max)
end
function Flow:display(x, y, nb_keyframes, screen_x, screen_y)
	self.last_screen_x, self.last_screen_y = screen_x, screen_y
	self.scrollbar.pos = util.minBound(self.scrollbar.pos + self.scroll_inertia, 0, self.scrollbar.max)
	if self.scroll_inertia > 0 then self.scroll_inertia = math.max(self.scroll_inertia - 1, 0)
	elseif self.scroll_inertia < 0 then self.scroll_inertia = math.min(self.scroll_inertia + 1, 0) end
	local oy = y - self.scrollbar.pos
	flush()
	core.display.glScissor(true, screen_x, screen_y, self.w, self.h)
	local was = batching
	batching = true
	for _, sec in ipairs(self.sections) do
		if sec.title and sec.ty + 30 - self.scrollbar.pos > 0 and sec.ty - self.scrollbar.pos < self.h then
			draw(text(sec.title:upper(), 12, 142, 136, 120, true), x + 6, oy + sec.ty + 8)
		end
		for _, it in ipairs(sec.items) do
			local iy = oy + it.y
			if iy + it.h > y and iy < y + self.h then
				local a = it.locked and 0.4 or 1
				local down = screen_x and pressed(screen_x + it.x, screen_y + it.y - self.scrollbar.pos, it.w, it.h)
				quad(x + it.x, iy, it.w, it.h, down and {62, 58, 40} or (it.sel and CARD_SEL or CARD))
				if it.sel then frame(x + it.x, iy, it.w, it.h, GOLD, 2) end
				local tx = x + it.x + 10
				local ty = iy + 8
				if it.icon and sec.icon_only then
					local size = math.min(it.h - 16, sec.icon_size or 40)
					flush() batching = false
					pcall(it.icon, x + it.x + (it.w - size) / 2, iy + 4, size)
					batching = true
					if it.name then draw(text(it.name, 11, 200, 195, 180, false, it.w - 6), x + it.x + 3, iy + it.h - 16, a) end
				elseif sec.center then
					local d = text(it.name, 17, 234, 227, 209, true, it.w - 16)
					if d then draw(d, x + it.x + (it.w - d.w) / 2, iy + (it.sub and 8 or (it.h - d.h) / 2), a) end
					if it.sub then local s = text(it.sub, 12, 142, 136, 120, false, it.w - 16) if s then draw(s, x + it.x + (it.w - s.w) / 2, iy + it.h - 24, a) end end
				elseif sec.rows then
					draw(text(it.name, 15, 142, 136, 120, false), tx, iy + (it.h - 20) / 2, a)
					local v = text(it.sub or "", 17, 234, 227, 209, true, it.w - 140 - 60)
					if v then draw(v, x + it.x + it.w - 60 - v.w, iy + (it.h - v.h) / 2, a) end
					draw(text(_t"edit", 13, 240, 212, 138), x + it.x + it.w - 44, iy + (it.h - 18) / 2, a)
				else
					if it.icon then
						local size = math.min(it.h - 16, sec.icon_size or 40)
						flush() batching = false
						pcall(it.icon, tx, ty, size)
						batching = true
						tx = tx + size + 8
					end
					local maxw = x + it.x + it.w - tx - 8
					draw(text(it.name, 17, 234, 227, 209, true, maxw), tx, ty, a)
					if it.sub then
						local nl = it.h >= 84 and 2 or 1
						for li, l in ipairs(wrap(it.sub, font(12), maxw, nl)) do draw(text(l, 12, 142, 136, 120, false, maxw), tx, ty + 28 + (li - 1) * 18, a) end
					end
					if it.locked then draw(text(_t"locked", 11, 224, 122, 106, true), tx, iy + it.h - 20, 1) end
				end
			end
		end
	end
	flush()
	core.display.glScissor(false)
	if self.scrollbar.max > 0 then
		-- a slim indicator instead of the engine scrollbar
		local frac = self.h / self.total_h
		local bh = math.max(20, self.h * frac)
		local by = (self.h - bh) * (self.scrollbar.pos / self.scrollbar.max)
		quad(x + self.w - 4, y + by, 3, bh, {120, 120, 120}, 120)
	end
	flush()
	batching = was
end


_M.GOLD, _M.CARD, _M.CARD_SEL, _M.PANE = GOLD, CARD, CARD_SEL, PANE
_M.font, _M.text, _M.draw, _M.quad, _M.frame, _M.circle, _M.wrap, _M.pitch = font, text, draw, quad, frame, circle, wrap, pitch
_M.flush = flush -- call before drawing anything that is not a kit quad/text, and at the end of a display()
-- opt-in batching for a caller that only draws kit quads and text between the two calls
_M.beginBatch = function() batching = batched end
_M.endBatch = function() flush() batching = false end
_M.pressed = pressed
_M.Rail, _M.Flow = Rail, Flow
