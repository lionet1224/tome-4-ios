-- ToME iOS port: a short guide to the touch controls. Six pages, an illustration
-- drawn from kit primitives on the left, the words on the right. Shown once after
-- birth, and any time from More or Options -> Touch.

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local Button = require "engine.ui.Button"
local K = require "engine.ui.TouchKit"

module(..., package.seeall, class.inherit(Dialog))

local GOLD, CARD, PANE = K.GOLD, K.CARD, K.PANE
local INK = {234, 227, 209}
local MUTE = {142, 136, 120}
local RED = {224, 122, 106}
local GREEN = {123, 211, 137}
local DARK = {12, 13, 16}
local ACT = {208, 122, 74}

local function txt(str, size, c, bold, maxw) return K.text(str, size, c[1], c[2], c[3], bold, maxw) end
local function label(str, size, c, x, y, bold, maxw, a) K.draw(txt(str, size, c, bold, maxw), x, y, a) end
local function centered(str, size, c, cx, y, bold, a) local d = txt(str, size, c, bold) if d then K.draw(d, cx - d.w / 2, y, a) end end

-- a finger: a soft disc with a bright core
local function finger(x, y, a)
	a = a or 1
	K.circle(x, y, 22, {240, 212, 138}, 0.35 * a)
	K.circle(x, y, 12, {250, 240, 210}, a)
end
-- a dashed frame (destination tile)
local function dashed(x, y, w, h, c)
	local d, g = 8, 6
	for i = 0, w, d + g do K.quad(x + i, y, math.min(d, w - i), 3, c) K.quad(x + i, y + h - 3, math.min(d, w - i), 3, c) end
	for i = 0, h, d + g do K.quad(x, y + i, 3, math.min(d, h - i), c) K.quad(x + w - 3, y + i, 3, math.min(d, h - i), c) end
end
-- an axis aligned arrow made of quads
local function arrow(x, y, dx, len, c)
	-- dx = 1 right, -1 left, 0 down (dy handled by caller through len sign)
	if dx ~= 0 then
		local x0 = dx > 0 and x or x - len
		K.quad(x0, y - 3, len, 6, c)
		local hx = dx > 0 and x + len or x - len
		for i = 1, 10 do K.quad(hx - dx * i, y - 12 + i, 3, 24 - 2 * i, c) end
	else
		K.quad(x - 3, y, 6, len, c)
		for i = 1, 10 do K.quad(x - 12 + i, y + len - i, 24 - 2 * i, 3, c) end
	end
end
-- a HUD-style button box
local function hudbox(x, y, w, h, big, small, border, a)
	K.quad(x, y, w, h, {20, 22, 28}, math.floor(230 * (a or 1)))
	K.frame(x, y, w, h, border or {58, 61, 70}, 2)
	if big then centered(big, 26, INK, x + w / 2, y + h / 2 - 26, true, a) end
	if small then centered(small, 12, MUTE, x + w / 2, y + h - 22, false, a) end
end
-- a phone shaped frame with a tile grid inside; returns the grid origin and tile size
local function phone(x, y, w, h)
	K.quad(x, y, w, h, {10, 11, 13})
	K.frame(x, y, w, h, {50, 52, 60}, 3)
	local ts = 40
	local gx, gy = x + 12, y + 12
	local cols, rows = math.floor((w - 24) / ts), math.floor((h - 24) / ts)
	for i = 0, cols - 1 do for j = 0, rows - 1 do
		local n = ((i * 7 + j * 13) % 5)
		K.quad(gx + i * ts, gy + j * ts, ts - 1, ts - 1, {34 + n * 3, 62 + n * 4, 28 + n * 2})
	end end
	return gx, gy, ts, cols, rows
end

_M.PAGES = {
	{
		title = _t"Act and Auto",
		paras = {
			_t"Act does the next step of your routine: attack, approach, shoot, whatever you set up. Most of the time you just tap it.",
			_t"AUTO keeps acting and exploring on its own until a stop rule fires: low life, a low resource, or an elite in view. Then it hands back to you.",
			_t"Hold Act for its menu: restart the routine, skip a step, switch routines, or edit them. The strip above Act shows the routine; tap a box to jump to that step.",
		},
		draw = function(self, x, y, w, h, t)
			local px, py, pw, ph = x + 10, y + 20, w - 20, h - 40
			phone(px, py, pw, ph)
			local bw = 96
			local ax, ay = px + pw - 16 - bw, py + ph - 16 - bw
			hudbox(ax - bw - 10, ay, bw, bw, ">>", "AUTO")
			hudbox(ax, ay, bw, bw, "Z", "ACT", ACT)
			centered(_t"Approach", 12, MUTE, ax + bw / 2, ay + bw / 2 + 4)
			-- the routine strip
			label("Basic", 12, {240, 212, 138}, ax + 30, ay - 44)
			K.quad(ax + 36, ay - 26, 22, 18, {20, 22, 28}) K.frame(ax + 36, ay - 26, 22, 18, GOLD, 1) label("X", 11, INK, ax + 42, ay - 24)
			K.quad(ax + 62, ay - 26, 22, 18, {20, 22, 28}) label(">", 11, INK, ax + 69, ay - 24)
			-- a finger pressing Act
			local pulse = 0.75 + 0.25 * math.sin(t / 6)
			finger(ax + bw / 2 + 6, ay + bw / 2 + 8, pulse)
		end,
	},
	{
		title = _t"Fighting by hand",
		paras = {
			_t"Tap an enemy to target it. A gold ring marks it and the skill drawer opens at the bottom: ready skills first, cooling ones dimmed with the turns left.",
			_t"Tap a skill to cast it at the target. SKILLS opens and closes the drawer whenever you like. With no target, a skill hits the nearest enemy, or asks you to aim when nothing is around.",
			_t"The X card closes the drawer and drops the target.",
		},
		draw = function(self, x, y, w, h, t)
			local px, py, pw, ph = x + 10, y + 20, w - 20, h - 40
			local gx, gy, ts, cols, rows = phone(px, py, pw, ph)
			-- you and the enemy
			local yx, yy = gx + 1 * ts, gy + 2 * ts
			local ex, ey = gx + 4 * ts, gy + 1 * ts
			centered("@", 26, {240, 212, 138}, yx + ts / 2, yy + 5, true)
			centered("g", 26, RED, ex + ts / 2, ey + 5, true)
			local pulse = 1 + 0.08 * math.sin(t / 5)
			local r = (ts + 6) * pulse
			K.frame(ex + ts / 2 - r / 2, ey + ts / 2 - r / 2, r, r, GOLD, 3)
			finger(ex + ts / 2 + 14, ey + ts / 2 + 12, 0.8)
			-- the drawer
			local dh = 78
			local dx, dy, dw = px + 12, py + ph - dh - 12, pw - 24 - 70
			K.quad(dx, dy, dw, dh, {20, 22, 28}, 235) K.frame(dx, dy, dw, dh, {58, 61, 70}, 2)
			label(_t"goblin", 13, INK, dx + 10, dy + 12, true)
			label(_t"tap a skill", 10, MUTE, dx + 10, dy + 34)
			local cx = dx + 92
			for i = 1, 4 do
				local ready = i <= 2
				K.quad(cx, dy + 8, 50, dh - 16, {36, 39, 47}, ready and 255 or 120)
				if ready then K.frame(cx, dy + 8, 50, dh - 16, GOLD, 2) else label("3", 12, RED, cx + 34, dy + 10, true) end
				centered(({"A", "S", "H", "F"})[i], 20, ready and INK or MUTE, cx + 25, dy + 18, true, ready and 1 or 0.6)
				cx = cx + 56
			end
			K.quad(dx + dw - 40, dy + dh / 2 - 16, 32, 32, {36, 39, 47}) centered("X", 16, INK, dx + dw - 24, dy + dh / 2 - 10, true)
			hudbox(px + pw - 12 - 60, dy + dh - 60, 60, 60, nil, _t"SKILLS", GOLD)
		end,
	},
	{
		title = _t"Moving",
		paras = {
			_t"Drag anywhere on the map. The destination tile lights up while your finger is down; release to step, drag back to the middle to cancel. Hold still at the end to keep walking.",
			_t"While an enemy is in view this is the only way to walk, so a stray tap can never spend several turns. With the coast clear, tap a tile to walk there.",
			_t"Tap yourself to wait a turn, or to take the stairs and enter a zone when you stand on them.",
		},
		draw = function(self, x, y, w, h, t)
			local px, py, pw, ph = x + 10, y + 20, w - 20, h - 40
			local gx, gy, ts, cols, rows = phone(px, py, pw, ph)
			local yx, yy = gx + 2 * ts, gy + 2 * ts
			centered("@", 26, {240, 212, 138}, yx + ts / 2, yy + 5, true)
			-- destination one tile to the right, dashed, with a bar on the far side
			dashed(yx + ts, yy, ts, ts, GOLD)
			K.quad(yx + 2 * ts - 6, yy + 4, 4, ts - 8, GOLD)
			-- the finger travels from the player outward and back
			local phase = (t % 60) / 60
			local off = phase < 0.6 and (phase / 0.6) or (1 - (phase - 0.6) / 0.4)
			finger(yx + ts / 2 + off * 70, yy + ts / 2 + 10, 0.9)
			arrow(yx + ts / 2 + 8, yy + ts + 26, 1, 60, {240, 212, 138})
			label(_t"release = step", 12, MUTE, yx - 10, yy + ts + 42)
		end,
	},
	{
		title = _t"Holds, two fingers, pinch",
		paras = {
			_t"Hold a tile for its menu: inspect what is there, mark a creature for Act, travel to the spot.",
			_t"Tap with two fingers to go back: it closes menus and cancels aiming, the same as Escape.",
			_t"Pinch to zoom the map in and out.",
		},
		draw = function(self, x, y, w, h, t)
			local px, py, pw, ph = x + 10, y + 20, w - 20, h - 40
			local gx, gy, ts = phone(px, py, pw, ph)
			-- hold: a finger with a growing ring and a small menu
			local hx, hy = gx + 2 * ts, gy + 2 * ts
			local grow = (t % 40) / 40
			K.circle(hx, hy, 14 + grow * 22, {240, 212, 138}, 0.5 * (1 - grow), 12 + grow * 22)
			finger(hx, hy, 1)
			K.quad(hx + 30, hy - 40, 120, 74, {20, 22, 28}, 235) K.frame(hx + 30, hy - 40, 120, 74, {58, 61, 70}, 2)
			label(_t"Inspect", 12, INK, hx + 40, hy - 34) label(_t"Mark for Act", 12, INK, hx + 40, hy - 12) label(_t"Travel here", 12, INK, hx + 40, hy + 10)
			-- two fingers
			local tx, ty = gx + 6 * ts, gy + 1 * ts
			finger(tx, ty, 0.9) finger(tx + 46, ty + 6, 0.9)
			label(_t"two fingers = back", 12, MUTE, tx - 40, ty + 40)
			-- pinch
			local cx, cy = gx + 5 * ts, gy + 4.2 * ts
			local sp = 24 + 22 * (0.5 + 0.5 * math.sin(t / 8))
			finger(cx - sp, cy, 0.9) finger(cx + sp, cy, 0.9)
			arrow(cx - sp - 20, cy, -1, 26, MUTE) arrow(cx + sp + 20, cy, 1, 26, MUTE)
			label(_t"pinch = zoom", 12, MUTE, cx - 40, cy + 34)
		end,
	},
	{
		title = _t"Everything else",
		paras = {
			_t"The More button (three dots) above SKILLS holds the rest: level up, Places, inventory, character, talents, journal, map, rest, explore and options.",
			_t"Places lists the towns, dungeons, shops, people and exits you know here; tap one to travel to it. In the inventory, drag an item onto your character to wear it, or double-tap it.",
			_t"Talents lets you put skills on the wheel or the drawer and set auto-use.",
		},
		draw = function(self, x, y, w, h, t)
			local px, py, pw, ph = x + 10, y + 20, w - 20, h - 40
			phone(px, py, pw, ph)
			hudbox(px + pw - 12 - 60, py + 14, 60, 30, nil, nil)
			centered("...", 20, INK, px + pw - 12 - 30, py + 10, true)
			local items = {_t"Level up!", _t"Places", _t"Inventory", _t"Character sheet", _t"Talents", _t"Journal", _t"Level map", _t"Rest", _t"Explore", _t"Options"}
			local lx, ly, lw = px + 40, py + 20, pw - 130
			K.quad(lx - 10, ly - 8, lw + 20, #items * 26 + 16, {20, 22, 28}, 235) K.frame(lx - 10, ly - 8, lw + 20, #items * 26 + 16, {58, 61, 70}, 2)
			local hi = math.floor(t / 20) % #items + 1
			for i, it in ipairs(items) do
				if i == hi then K.quad(lx, ly + (i - 1) * 26, lw, 24, {43, 39, 24}) K.frame(lx, ly + (i - 1) * 26, lw, 24, GOLD, 1) end
				label(it, 13, i == hi and {240, 212, 138} or INK, lx + 10, ly + (i - 1) * 26 + 4, i == hi)
			end
		end,
	},
	{
		title = _t"Auto and safety",
		paras = {
			_t"The strip under the minimap shows only skills that are cooling down, with the turns left.",
			_t"AUTO stops and buzzes when your life or a resource drops below your limits, or when an elite comes into view. The limits and the buzz live in Options, Touch.",
			_t"Routines skip a skill on cooldown without spending a turn unless you tell them otherwise. Hold Act to edit routines.",
		},
		draw = function(self, x, y, w, h, t)
			local px, py, pw, ph = x + 10, y + 20, w - 20, h - 40
			phone(px, py, pw, ph)
			-- minimap and pips
			local mx, my = px + pw - 12 - 120, py + 12
			K.quad(mx, my, 120, 80, {216, 201, 160}) K.frame(mx, my, 120, 80, {90, 74, 32}, 2)
			for i, n in ipairs{"4", "12"} do
				local qx = mx + 120 - i * 40
				K.quad(qx, my + 88, 36, 36, {40, 8, 8}) K.frame(qx, my + 88, 36, 36, {106, 32, 32}, 1)
				centered(n, 14, {255, 192, 176}, qx + 18, my + 96, true)
			end
			label(_t"cooling down", 12, MUTE, mx - 4, my + 130)
			-- AUTO with a stop badge
			local bw = 96
			local ax, ay = px + pw - 16 - bw * 2 - 10, py + ph - 16 - bw
			hudbox(ax, ay, bw, bw, ">>", "AUTO")
			hudbox(ax + bw + 10, ay, bw, bw, "Z", "ACT", ACT)
			local blink = math.floor(t / 15) % 2 == 0
			K.quad(ax - 6, ay - 28, 150, 24, RED, blink and 255 or 160)
			label(_t"Stopped: elite in view", 12, {30, 10, 10}, ax + 2, ay - 24, true)
		end,
	},
}

function _M:init(opts)
	self.opts = opts or {}
	self.page = 1
	self.anim = 0
	Dialog.init(self, _t"Controls reference", game.w * 0.96, game.h * 0.96)
	-- portrait: the illustration across the top, the words under it
	self.portrait = require("engine.TouchInput").portrait()
	if self.portrait then
		self.ill_w = self.iw
		self.ill_h = math.floor(self.ih * 0.42)
		self.text_x = 0
		self.text_y = self.ill_h + 12
		self.text_w = self.iw
	else
		self.ill_w = math.floor(self.iw * 0.45)
		self.ill_h = self.ih
		self.text_x = self.ill_w + 16
		self.text_y = 0
		self.text_w = self.iw - self.text_x
	end
	local bigfont = K.font(22)
	self.b_back = Button.new{text=_t"Back", width=140, font=bigfont, fct=function() self:go(-1) end}
	self.b_next = Button.new{text=_t"Next", width=220, font=bigfont, fct=function() if self.page >= #_M.PAGES then self:finish() else self:go(1) end end}
	self:loadUI{
		{left=self.text_x, bottom=0, ui=self.b_back},
		{right=0, bottom=0, ui=self.b_next},
	}
	self:setupUI()
	self.key:addBinds{
		EXIT = function() self:finish(true) end,
		MOVE_LEFT = function() self:go(-1) end,
		MOVE_RIGHT = function() self:go(1) end,
	}
	self:refresh()
end

function _M:go(d)
	self.page = util.bound(self.page + d, 1, #_M.PAGES)
	self:refresh()
end

--- Rotation: a fresh dialog for the new orientation, on the same page
function _M:touch_reopen()
	local d = _M.new(self.opts)
	d.page = self.page
	d:refresh()
	return d
end

function _M:refresh()
	local last = self.page >= #_M.PAGES
	local nt = last and _t"Done" or _t"Next"
	if self.b_next.text ~= nt then self.b_next.text = nt self.b_next:generate() end
	self.b_back.text = self.page == 1 and _t"Skip" or _t"Back"
	self.b_back.fct = function() if self.page == 1 then self:finish(true) else self:go(-1) end end
	self.b_back:generate()
end

-- remember that the guide was seen (kept with the other touch settings)
function _M:finish(skipped)
	local TW = require "mod.class.TouchWheel"
	if not (config.settings.touch and config.settings.touch.tutorial_seen) then TW.set("tutorial_seen", true) end
	game:unregisterDialog(self)
end

-- a horizontal swipe on the illustration turns the page (acted on when the finger lifts)
function _M:trackSwipe()
	local TI = require "engine.TouchInput"
	local t = TI.active() and TI.t
	local ix, iy = (self.display_x or 0) + self.ix, (self.display_y or 0) + self.iy
	if t and t.moved and not t.held and t.x0 and t.x0 >= ix and t.x0 < ix + self.ill_w and t.y0 >= iy and t.y0 < iy + self.ill_h then
		self.swipe = {dx = t.x - t.x0}
	elseif not t and self.swipe then
		local dx = self.swipe.dx
		self.swipe = nil
		if dx <= -80 then self:go(1) elseif dx >= 80 then self:go(-1) end
	end
end

function _M:innerDisplayBack(x, y, nb_keyframes)
	self.anim = self.anim + (nb_keyframes or 1)
	self:trackSwipe()
	x, y = x + self.ix, y + self.iy
	local page = _M.PAGES[self.page]
	-- panes
	K.quad(x, y, self.ill_w, self.ill_h, PANE)
	if self.portrait then
		K.quad(x, y + self.text_y, self.text_w, self.ih - self.text_y, {18, 19, 23})
	else
		K.quad(x + self.text_x, y, self.text_w, self.ih, {18, 19, 23})
	end
	-- illustration
	if page.draw then pcall(page.draw, self, x, y, self.ill_w, self.ill_h - 40, self.anim) end
	-- page dots under the illustration
	local n = #_M.PAGES
	local dx = x + self.ill_w / 2 - (n * 18) / 2
	for i = 1, n do
		if i == self.page then K.circle(dx + (i - 1) * 18 + 6, y + self.ill_h - 18, 6, GOLD, 1)
		else K.circle(dx + (i - 1) * 18 + 6, y + self.ill_h - 18, 5, {80, 83, 92}, 1) end
	end
	-- words
	local tx, ty = x + self.text_x + 14, y + self.text_y + 10
	label(("%d / %d"):format(self.page, n), 12, MUTE, tx, ty)
	label(page.title, 26, {240, 212, 138}, tx, ty + 18, true, self.text_w - 28)
	local yy = ty + 62
	local f = K.font(17)
	for _, p in ipairs(page.paras) do
		for _, l in ipairs(K.wrap(p, f, self.text_w - 28, 30)) do
			label(l, 17, INK, tx, yy, false, self.text_w - 28)
			yy = yy + 24
		end
		yy = yy + 10
	end
	if self.page == n then label(_t"You can reopen this guide from More or Options.", 13, MUTE, tx, y + self.ih - 66 - 20, false, self.text_w - 28) end
end
