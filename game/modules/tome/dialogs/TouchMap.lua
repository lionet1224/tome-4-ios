-- ToME iOS port: the level map as a touch screen.
-- The explored level fills the pane (scaled to fit, or pan with a finger drag
-- when it cannot), a tap on a tile auto-travels there like a desktop map
-- click, and the side pane offers the useful shortcuts: go to the exit /
-- stairs, zoom, close. The minimap grid size is restored on close.

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local Button = require "engine.ui.Button"
local GenericContainer = require "engine.ui.GenericContainer"
local Map = require "engine.Map"
local K = require "engine.ui.TouchKit"

module(..., package.seeall, class.inherit(Dialog))

local PANE_W = 230

function _M:init(mm_mode)
	self.mm_mode = mm_mode
	self.touch_args = {mm_mode=mm_mode}
	self.title_shadow = false
	local map = game.level.map
	self.map = map
	self.portrait = require("engine.TouchInput").portrait()

	self.no_close_bar = true -- has its own Close button
	Dialog.init(self, ("Map: #0080FF#%s"):tformat(game.old_zone_name or (game.zone and game.zone.name) or ""), game.w * 0.96, game.h * 0.96)

	local gap = 12
	if self.portrait then
		-- portrait: the map fills the width, the pane becomes a bottom sheet
		self.sheet_h = 300
		self.map_w = self.iw
		self.map_h = self.ih - self.sheet_h - gap
	else
		self.map_w = self.iw - PANE_W - gap
		self.map_h = self.ih
	end
	-- fit what is explored (not the whole, mostly black, level) into the pane
	local x0, y0, x1, y1 = self:knownBounds()
	self.known = {x0, y0, x1, y1}
	local bw, bh = x1 - x0 + 1, y1 - y0 + 1
	self.fit_size = math.max(2, math.floor(math.min(self.map_w / bw, self.map_h / bh)))
	self.bsize = util.bound(self.fit_size, 6, 36)
	self.scroll_x, self.scroll_y = 0, 0
	self:centerOn(math.floor((x0 + x1) / 2), math.floor((y0 + y1) / 2))

	local mc = GenericContainer.new{width=self.map_w, height=self.map_h}
	self.c_map = mc
	mc.mouse:registerZone(0, 0, mc.w, mc.h, function(button, mx, my, xrel, yrel, bx, by, event)
		if event ~= "button" or button ~= "left" then return end
		-- a plain tap: travel there (drags never reach here, the Dialog swallows them)
		local tx, ty = self:tileAt(bx, by)
		if not tx then return end
		print("[TOUCH] map travel to", tx, ty)
		game:unregisterDialog(self)
		game.player:mouseMove(tx, ty)
	end, nil, nil, true)

	local bigfont = K.font(22)
	if self.portrait then
		-- Button adds 16 px of frame to the requested width
		local full = self.iw - 16
		local third = math.floor((self.iw - 12) / 3) - 16
		local half = math.floor((self.iw - 6) / 2) - 16
		self.b_exit = Button.new{text=self:exitLabel(), width=full, font=bigfont, fct=function() self:goExit() end}
		self.b_center = Button.new{text=_t"Find me", width=third, font=bigfont, fct=function() self:centerOn(game.player.x, game.player.y) end}
		self.b_zin = Button.new{text=_t"Zoom in", width=third, font=bigfont, fct=function() self:zoom(1) end}
		self.b_zout = Button.new{text=_t"Zoom out", width=third, font=bigfont, fct=function() self:zoom(-1) end}
		self.b_places = Button.new{text=_t"Places", width=half, font=bigfont, fct=function() game:unregisterDialog(self) game:registerDialog(require("mod.dialogs.TouchPlaces").new()) end}
		self.b_close = Button.new{text=_t"Close", width=half, font=bigfont, fct=function() game:unregisterDialog(self) end}
		local sy = self.map_h + gap
		local bh = self.b_exit.h + 8
		self.sheet_y = sy
		self:loadUI{
			{left=0, top=0, ui=mc},
			{left=0, top=sy + 96, ui=self.b_exit},
			{left=0, top=sy + 96 + bh, ui=self.b_center},
			{left=third + 16 + 6, top=sy + 96 + bh, ui=self.b_zin},
			{left=2 * (third + 16 + 6), top=sy + 96 + bh, ui=self.b_zout},
			{left=0, bottom=0, ui=self.b_places},
			{left=half + 16 + 6, bottom=0, ui=self.b_close},
		}
	else
	local bw = PANE_W
	self.b_exit = Button.new{text=self:exitLabel(), width=bw, font=bigfont, fct=function() self:goExit() end}
	self.b_zin = Button.new{text=_t"Zoom in", width=math.floor((bw - 8) / 2), font=bigfont, fct=function() self:zoom(1) end}
	self.b_zout = Button.new{text=_t"Zoom out", width=math.floor((bw - 8) / 2), font=bigfont, fct=function() self:zoom(-1) end}
	self.b_center = Button.new{text=_t"Find me", width=bw, font=bigfont, fct=function() self:centerOn(game.player.x, game.player.y) end}
	self.b_close = Button.new{text=_t"Close", width=bw, font=bigfont, fct=function() game:unregisterDialog(self) end}
	self.b_places = Button.new{text=_t"Places", width=bw, font=bigfont, fct=function() game:unregisterDialog(self) game:registerDialog(require("mod.dialogs.TouchPlaces").new()) end}

	local px = self.map_w + gap
	self:loadUI{
		{left=0, top=0, ui=mc},
		{left=px, top=110, ui=self.b_exit},
		{left=px, top=110 + self.b_exit.h + 8, ui=self.b_center},
		{left=px, top=110 + (self.b_exit.h + 8) * 2, ui=self.b_zin},
		{left=px + math.floor((bw - 8) / 2) + 8, top=110 + (self.b_exit.h + 8) * 2, ui=self.b_zout},
		{left=px, bottom=self.b_close.h + 8, ui=self.b_places},
		{left=px, bottom=0, ui=self.b_close},
	}
	end
	self.key:addBind("EXIT", function() game:unregisterDialog(self) end)
	self.key:addBind("ACCEPT", function() game:unregisterDialog(self) end)
	self.key:addBind("SHOW_MAP", function() game:unregisterDialog(self) end)
	self:setupUI()
	self:setFocus(mc)
	if not self.exit_target then self.ui_by_ui[self.b_exit].x = -9999 end -- hidden widgets still get taps: park it

	game:playSound("actions/read")
	game.uiset.no_minimap = true
	map._map:setupMiniMapGridSize(self.bsize)
end

function _M:unload()
	game.uiset.no_minimap = nil
	if game.level then game.uiset:setupMinimap(game.level) end
	if self.mm_mode then self.mm_mode() end
end

--- Rotation: a fresh dialog for the new orientation, same zoom and view
function _M:touch_reopen()
	local nd = _M.new(self.touch_args.mm_mode)
	nd.bsize = self.bsize
	nd.map._map:setupMiniMapGridSize(nd.bsize)
	local cx, cy = self:tileAt(self.map_w / 2, self.map_h / 2)
	if cx then nd:centerOn(cx, cy) else nd:clampScroll() end
	return nd
end

-- bounding box of the tiles the player has seen or remembers, padded a little and
-- never smaller than 16x16 so a fresh level is not blown up absurdly
function _M:knownBounds()
	local map = self.map
	local x0, y0, x1, y1 = map.w, map.h, -1, -1
	for x = 0, map.w - 1 do for y = 0, map.h - 1 do
		if map.remembers(x, y) or map.seens(x, y) then
			if x < x0 then x0 = x end
			if y < y0 then y0 = y end
			if x > x1 then x1 = x end
			if y > y1 then y1 = y end
		end
	end end
	local p = game.player
	if p and p.x then
		x0, y0, x1, y1 = math.min(x0, p.x), math.min(y0, p.y), math.max(x1, p.x), math.max(y1, p.y)
	end
	if x1 < 0 then return 0, 0, map.w - 1, map.h - 1 end
	x0, y0, x1, y1 = x0 - 3, y0 - 3, x1 + 3, y1 + 3
	local mn = 16
	if x1 - x0 + 1 < mn then local d = mn - (x1 - x0 + 1) x0, x1 = x0 - math.floor(d / 2), x1 + math.ceil(d / 2) end
	if y1 - y0 + 1 < mn then local d = mn - (y1 - y0 + 1) y0, y1 = y0 - math.floor(d / 2), y1 + math.ceil(d / 2) end
	return math.max(0, x0), math.max(0, y0), math.min(map.w - 1, x1), math.min(map.h - 1, y1)
end

-- tiles visible in the pane at the current zoom
function _M:tilesShown()
	return math.floor(self.map_w / self.bsize), math.floor(self.map_h / self.bsize)
end

function _M:clampScroll()
	local tw, th = self:tilesShown()
	self.scroll_x = util.bound(self.scroll_x, 0, math.max(0, self.map.w - tw))
	self.scroll_y = util.bound(self.scroll_y, 0, math.max(0, self.map.h - th))
end

function _M:centerOn(x, y)
	local tw, th = self:tilesShown()
	self.scroll_x = x - math.floor(tw / 2)
	self.scroll_y = y - math.floor(th / 2)
	self:clampScroll()
end

function _M:zoom(dir)
	local cx, cy = self:tileAt(self.map_w / 2, self.map_h / 2)
	self.bsize = util.bound(self.bsize + dir * 3, math.min(self.fit_size, 40), 40)
	self.map._map:setupMiniMapGridSize(self.bsize)
	if cx then self:centerOn(cx, cy) else self:clampScroll() end
end

-- when the whole level is smaller than the pane it is centred: pixel offset of the grid
function _M:gridOffset()
	local ox = math.max(0, math.floor((self.map_w - self.map.w * self.bsize) / 2))
	local oy = math.max(0, math.floor((self.map_h - self.map.h * self.bsize) / 2))
	return ox, oy
end

-- pane-local pixel -> map tile (nil when outside the level)
function _M:tileAt(bx, by)
	local ox, oy = self:gridOffset()
	local tx, ty = self.scroll_x + math.floor((bx - ox) / self.bsize), self.scroll_y + math.floor((by - oy) / self.bsize)
	if tx < 0 or ty < 0 or tx >= self.map.w or ty >= self.map.h then return nil end
	return tx, ty
end

-- the nearest known way out: a zone exit first, else any stairs
function _M:findExit()
	local map = self.map
	local p = game.player
	local best, bd, kind
	for x = 0, map.w - 1 do for y = 0, map.h - 1 do
		if map.remembers(x, y) then
			local g = map(x, y, Map.TERRAIN)
			if g and g.change_level then
				local k = g.change_zone and 2 or 1
				local d = core.fov.distance(p.x, p.y, x, y)
				if not best or k > kind or (k == kind and d < bd) then best, bd, kind = {x=x, y=y, g=g}, d, k end
			end
		end
	end end
	return best, kind
end

function _M:exitLabel()
	local e, kind = self:findExit()
	self.exit_target = e
	if not e then return _t"No exit known" end
	if kind == 2 then return _t"Go to the exit" end
	return (e.g.change_level or 0) < 0 and _t"Go to stairs up" or _t"Go to stairs down"
end

function _M:goExit()
	local e = self.exit_target
	if not e then return end
	print("[TOUCH] map travel to exit", e.x, e.y)
	game:unregisterDialog(self)
	game.player:mouseMove(e.x, e.y)
end

function _M:innerDisplayBack(x, y, nb_keyframes)
	-- side pane (landscape) or bottom sheet (portrait)
	local px, py, pw
	if self.portrait then
		px, py, pw = x + self.ix, y + self.iy + self.sheet_y, self.iw
		K.quad(px, py, pw, self.sheet_h, K.PANE)
	else
		px, py, pw = x + self.ix + self.map_w + 12, y + self.iy, PANE_W
		K.quad(px, py, pw, self.ih, K.PANE)
	end
	local zone = game.zone and (game.zone.display_name or game.zone.name) or ""
	if type(zone) == "function" then zone = zone(game.zone) end
	zone = tostring(zone or "")
	K.draw(K.text(zone, 20, 240, 212, 138, true, pw - 16), px + 8, py + 10)
	local lvl = game.level and game.level.level or 1
	K.draw(K.text((_t"Level %d · %dx%d"):format(lvl, self.map.w, self.map.h), 13, 142, 136, 120), px + 8, py + 40)
	K.draw(K.text(_t"Tap a tile to travel there. Drag to pan.", 12, 142, 136, 120, false, pw - 16), px + 8, py + 62)
	if self.exit_target then K.draw(K.text((_t"Exit at %d,%d"):format(self.exit_target.x, self.exit_target.y), 12, 142, 136, 120), px + 8, py + 82) end
end

function _M:innerDisplay(x, y, nb_keyframes)
	if not game.level then return end
	local map = self.map
	local mx, my = x + self.ix, y + self.iy
	-- drawing happens in the dialog's translated space; fingers arrive in screen space
	self.map_sx, self.map_sy = (self.display_x or 0) + self.ix, (self.display_y or 0) + self.iy

	-- finger pan: the Dialog eats drag motion, so read the gesture state directly
	local TI = require "engine.TouchInput"
	local t = TI.active() and TI.t
	if t and t.moved and not t.held and t.x0 and t.x0 >= self.map_sx and t.x0 < self.map_sx + self.map_w and t.y0 >= self.map_sy and t.y0 < self.map_sy + self.map_h then
		if self.pan_t ~= t then self.pan_t, self.pan_sx, self.pan_sy = t, self.scroll_x, self.scroll_y end
		self.scroll_x = self.pan_sx - math.floor((t.x - t.x0) / self.bsize + 0.5)
		self.scroll_y = self.pan_sy - math.floor((t.y - t.y0) / self.bsize + 0.5)
		self:clampScroll()
	elseif not t then
		self.pan_t = nil
	end

	local tw, th = self:tilesShown()
	tw, th = math.min(tw, map.w), math.min(th, map.h)
	local ox, oy = self:gridOffset()
	K.quad(mx, my, self.map_w, self.map_h, {12, 13, 16})
	core.display.glScissor(true, self.map_sx, self.map_sy, self.map_w, self.map_h)
	map:minimapDisplay(mx + ox, my + oy, self.scroll_x, self.scroll_y, tw, th, 0.95)
	mx, my = mx + ox, my + oy
	-- the player, ringed so it reads at any zoom
	local p = game.player
	if p and p.x then
		local cx = mx + (p.x - self.scroll_x + 0.5) * self.bsize
		local cy = my + (p.y - self.scroll_y + 0.5) * self.bsize
		local r = math.max(6, self.bsize * 0.9)
		local pulse = 0.6 + 0.4 * math.abs(math.sin(core.game.getTime() / 400))
		K.circle(cx, cy, r + 3, K.GOLD, pulse, r)
	end
	-- the exit marker
	local e = self.exit_target
	if e then
		local cx = mx + (e.x - self.scroll_x + 0.5) * self.bsize
		local cy = my + (e.y - self.scroll_y + 0.5) * self.bsize
		K.frame(cx - self.bsize / 2 - 2, cy - self.bsize / 2 - 2, self.bsize + 4, self.bsize + 4, {123, 211, 137}, 2)
	end
	core.display.glScissor(false)
	K.frame(mx - ox, my - oy, self.map_w, self.map_h, {40, 43, 52}, 1)
end
