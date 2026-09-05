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
	self.title_shadow = false
	local map = game.level.map
	self.map = map

	Dialog.init(self, ("Map: #0080FF#%s"):tformat(game.old_zone_name or (game.zone and game.zone.name) or ""), game.w * 0.96, game.h * 0.96)

	local gap = 12
	self.map_w = self.iw - PANE_W - gap
	self.map_h = self.ih
	-- fit the whole level if we can; otherwise a readable size and panning
	self.fit_size = math.max(2, math.floor(math.min(self.map_w / map.w, self.map_h / map.h)))
	self.bsize = util.bound(self.fit_size, 6, 24)
	self.scroll_x, self.scroll_y = 0, 0
	self:centerOn(game.player.x, game.player.y)

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
	local bw = PANE_W
	self.b_exit = Button.new{text=self:exitLabel(), width=bw, font=bigfont, fct=function() self:goExit() end}
	self.b_zin = Button.new{text=_t"Zoom in", width=math.floor((bw - 8) / 2), font=bigfont, fct=function() self:zoom(1) end}
	self.b_zout = Button.new{text=_t"Zoom out", width=math.floor((bw - 8) / 2), font=bigfont, fct=function() self:zoom(-1) end}
	self.b_center = Button.new{text=_t"Find me", width=bw, font=bigfont, fct=function() self:centerOn(game.player.x, game.player.y) end}
	self.b_close = Button.new{text=_t"Close", width=bw, font=bigfont, fct=function() game:unregisterDialog(self) end}

	local px = self.map_w + gap
	self:loadUI{
		{left=0, top=0, ui=mc},
		{left=px, top=110, ui=self.b_exit},
		{left=px, top=110 + self.b_exit.h + 8, ui=self.b_center},
		{left=px, top=110 + (self.b_exit.h + 8) * 2, ui=self.b_zin},
		{left=px + math.floor((bw - 8) / 2) + 8, top=110 + (self.b_exit.h + 8) * 2, ui=self.b_zout},
		{left=px, bottom=0, ui=self.b_close},
	}
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
	self.bsize = util.bound(self.bsize + dir * 3, 4, 40)
	self.map._map:setupMiniMapGridSize(self.bsize)
	if cx then self:centerOn(cx, cy) else self:clampScroll() end
end

-- pane-local pixel -> map tile (nil when outside the level)
function _M:tileAt(bx, by)
	local tx, ty = self.scroll_x + math.floor(bx / self.bsize), self.scroll_y + math.floor(by / self.bsize)
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
	-- side pane
	local px = x + self.ix + self.map_w + 12
	local py = y + self.iy
	K.quad(px, py, PANE_W, self.ih, K.PANE)
	local zone = game.zone and (game.zone.display_name or game.zone.name) or ""
	if type(zone) == "function" then zone = zone(game.zone) end
	zone = tostring(zone or "")
	K.draw(K.text(zone, 20, 240, 212, 138, true, PANE_W - 16), px + 8, py + 10)
	local lvl = game.level and game.level.level or 1
	K.draw(K.text((_t"Level %d · %dx%d"):format(lvl, self.map.w, self.map.h), 13, 142, 136, 120), px + 8, py + 40)
	K.draw(K.text(_t"Tap a tile to travel there. Drag to pan.", 12, 142, 136, 120, false, PANE_W - 16), px + 8, py + 62)
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
	K.quad(mx, my, self.map_w, self.map_h, {12, 13, 16})
	core.display.glScissor(true, mx, my, self.map_w, self.map_h)
	map:minimapDisplay(mx, my, self.scroll_x, self.scroll_y, tw, th, 0.95)
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
	K.frame(mx, my, self.map_w, self.map_h, {40, 43, 52}, 1)
end
