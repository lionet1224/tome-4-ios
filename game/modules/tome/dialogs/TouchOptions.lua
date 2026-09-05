-- ToME iOS port: settings-app layout for the game options.
-- Reuses every entry table the stock GameOptions builds (generateList* per tab):
-- each entry keeps its `status` and `fct`, only the widgets change. Sections on
-- the left, finger rows on the right (label, one-line pitch, value pill).

require "engine.class"
local GameOptions = require "mod.dialogs.GameOptions"
local Dialog = require "engine.ui.Dialog"
local Base = require "engine.ui.Base"
local Focusable = require "engine.ui.Focusable"
local Slider = require "engine.ui.Slider"
local Button = require "engine.ui.Button"
local K = require "engine.ui.TouchKit"

module(..., package.seeall, class.inherit(GameOptions))

local GOLD, CARD, CARD_SEL, PANE = K.GOLD, K.CARD, K.CARD_SEL, K.PANE
local font, text, draw, quad, frame, pitch = K.font, K.text, K.draw, K.quad, K.frame, K.pitch

local ON_WORDS = {enabled=true, on=true, yes=true, ["true"]=true}
local OFF_WORDS = {disabled=true, off=true, no=true, ["false"]=true, never=true}

---------------------------------------------------------------------------
-- Rows: the option list, one pixel scroller (finger drag scrolls it)
---------------------------------------------------------------------------
local Rows = class.inherit(Base, Focusable){}
function Rows:init(t)
	self.w, self.h = t.width, t.height
	self.items = {}
	self.row_h = 68
	self.on_tap = t.on_tap
	self.scrollbar = Slider.new{size=self.h, max=1}
	self.scroll_inertia = 0
	Base.init(self, t)
end
function Rows:generate()
	self.mouse:reset()
	self.key:reset()
	self.mouse:registerZone(0, 0, self.w, self.h, function(button, x, y, xrel, yrel, bx, by, event)
		if event == "button" and button == "wheelup" then self.scroll_inertia = math.min(self.scroll_inertia, 0) - 5 return
		elseif event == "button" and button == "wheeldown" then self.scroll_inertia = math.max(self.scroll_inertia, 0) + 5 return end
		if event ~= "button" or button ~= "left" then return end
		local sy = y + self.scrollbar.pos
		local i = math.floor((sy - 4) / (self.row_h + 6)) + 1
		local it = self.items[i]
		if it and self.on_tap then self.on_tap(it, i) end
	end)
end
function Rows:setItems(items)
	self.items = items
	for i, it in ipairs(items) do
		it.x, it.y, it.w, it.h = 2, 4 + (i - 1) * (self.row_h + 6), self.w - 4, self.row_h
	end
	self.total_h = 4 + #items * (self.row_h + 6)
	self.scrollbar.max = math.max(0, self.total_h - self.h)
	self.scrollbar.pos = util.minBound(self.scrollbar.pos, 0, self.scrollbar.max)
end
-- current value of a row, as plain text
function Rows.valueOf(it)
	local ok, v = pcall(it.status, it.entry)
	if not ok or v == nil then return "" end
	if type(v) == "table" and v.toString then v = v:toString() end
	return (tostring(v):gsub("#[^#]*#", ""))
end
function Rows:display(x, y, nb_keyframes, screen_x, screen_y)
	self.last_screen_x, self.last_screen_y = screen_x, screen_y
	self.scrollbar.pos = util.minBound(self.scrollbar.pos + self.scroll_inertia, 0, self.scrollbar.max)
	if self.scroll_inertia > 0 then self.scroll_inertia = math.max(self.scroll_inertia - 1, 0)
	elseif self.scroll_inertia < 0 then self.scroll_inertia = math.min(self.scroll_inertia + 1, 0) end
	local oy = y - self.scrollbar.pos
	core.display.glScissor(true, screen_x, screen_y, self.w, self.h)
	for _, it in ipairs(self.items) do
		local iy = oy + it.y
		if iy + it.h > y and iy < y + self.h then
			quad(x + it.x, iy, it.w, it.h, CARD)
			local val = Rows.valueOf(it)
			local lv = val:lower()
			-- value on the right: a pill for on/off, plain gold text otherwise
			local vw = 0
			if ON_WORDS[lv] or OFF_WORDS[lv] then
				local on = ON_WORDS[lv]
				local d = text(val:upper(), 12, on and 16 or 200, on and 32 or 195, on and 26 or 180, true)
				local pw = (d and d.w or 30) + 24
				local px = x + it.x + it.w - 12 - pw
				quad(px, iy + (it.h - 30) / 2, pw, 30, on and {123, 211, 137} or {60, 63, 72})
				if d then draw(d, px + 12, iy + (it.h - d.h) / 2) end
				vw = pw + 12
			else
				local maxw = math.floor(it.w * 0.38)
				local d = text(val, 15, 240, 212, 138, true, maxw)
				if d then draw(d, x + it.x + it.w - 12 - d.w, iy + (it.h - d.h) / 2) vw = d.w + 12 end
			end
			local maxw = it.w - 24 - vw - 8
			draw(text(it.label, 17, 234, 227, 209, true, maxw), x + it.x + 12, iy + 10)
			if it.pitch and it.pitch ~= "" then draw(text(it.pitch, 12, 142, 136, 120, false, maxw), x + it.x + 12, iy + 38) end
		end
	end
	core.display.glScissor(false)
	if self.scrollbar.max > 0 then
		local frac = self.h / self.total_h
		local bh = math.max(20, self.h * frac)
		local by = (self.h - bh) * (self.scrollbar.pos / self.scrollbar.max)
		quad(x + self.w - 4, y + by, 3, bh, {120, 120, 120}, 120)
	end
end

---------------------------------------------------------------------------
-- The dialog
---------------------------------------------------------------------------
function _M:init()
	-- we can be called from the boot menu, so make sure to load initial settings in this case
	dofile("/mod/settings.lua")

	Dialog.init(self, _t"Options", game.w * 0.96, game.h * 0.96)

	-- what the stock entry builders poke: zone sizes and the list they redraw into
	self.c_desc = {w=600, h=30}
	self.c_list = {drawItem=function() end}
	self.touch_lw = 0

	self.sections = {}
	local function section(kind, title, sub) self.sections[#self.sections+1] = {kind=kind, name=title, sub=sub} end
	if require("engine.TouchInput").active() then section("touch", _t"Touch", _t"Wheels, Act, auto stops") end
	section("gameplay", _t"Gameplay", _t"Warnings, auto-explore, saving")
	section("ui", _t"Interface", _t"Look, fonts, HUD, tooltips")
	section("audio", _t"Audio", _t"Music and effects")
	section("video", _t"Video", _t"Resolution and shaders")
	section("online", _t"Online", _t"Chat, vault, Discord")
	section("misc", _t"Misc", _t"Background saves, censor")
	-- addon tabs, as the stock dialog collects them
	local hooks = {}
	self:triggerHook{"GameOptions:tabs", tab=function(title, fct)
		local id = #hooks + 1
		hooks[id] = true
		self['generateListHooktab'..id] = fct
		section("hooktab"..id, title, _t"Addon")
	end}
	self.lists = {}

	local gap = 12
	self.nav_w = 230
	self.rows_w = self.iw - self.nav_w - gap
	self.c_nav = K.Flow.new{width=self.nav_w, height=self.ih}
	self.c_rows = Rows.new{width=self.rows_w, height=self.ih, on_tap=function(it) self:tapRow(it) end}

	self:loadUI{
		{left=0, top=0, ui=self.c_nav},
		{left=self.nav_w + gap, top=0, ui=self.c_rows},
	}
	self:setupUI()
	self:setFocus(self.c_rows)
	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end }
	self:switchTo(self.sections[1].kind)
end

-- the stock builder for a section, run once and cached
function _M:listFor(kind)
	if self.lists[kind] then return self.lists[kind] end
	local list
	if kind == "audio" then
		list = {{name=_t"Audio options", desc=_t"Music and sound effect volumes.", status=function() return _t"open" end, fct=function() game:registerDialog(require("engine.dialogs.AudioOptions").new()) end}}
	elseif kind == "video" then
		list = {{name=_t"Video options", desc=_t"Resolution, fullscreen, shaders and frame rate.", status=function() return _t"open" end, fct=function() game:registerDialog(require("engine.dialogs.VideoOptions").new()) end}}
	else
		local fct = self['generateList'..kind:capitalize()]
		if fct then
			self.list = nil
			local ok, err = pcall(fct, self)
			if not ok then print("[TOUCH] options section failed", kind, err) end
			list = self.list or {}
			self:triggerHook{"GameOptions:generateList", list=list, kind=kind}
		else list = {} end
	end
	self.lists[kind] = list
	return list
end

function _M:switchTo(kind)
	self.kind = kind
	self.c_rows.scrollbar.pos = 0
	local items = {}
	for _, e in ipairs(self:listFor(kind)) do
		local label = e.name
		if type(label) == "table" and label.toString then label = label:toString() end
		label = tostring(label or ""):gsub("#[^#]*#", "")
		local desc = e.desc or (e.zone and e.zone.text) or ""
		items[#items+1] = {label=label, pitch=pitch(desc), status=e.status or function() return "" end, fct=e.fct, entry=e}
	end
	self.c_rows:setItems(items)
	self:refreshNav()
end

function _M:refreshNav()
	local items = {}
	for _, s in ipairs(self.sections) do
		items[#items+1] = {name=s.name, sub=s.sub, sel=s.kind == self.kind, on_tap=function() self:switchTo(s.kind) end}
	end
	self.c_nav:setSections{{items=items, cols=1, row_h=64}}
end

function _M:tapRow(it)
	if not it.fct then return end
	local ok, err = pcall(it.fct, it.entry)
	if not ok then print("[TOUCH] option failed", it.label, err) end
	-- values are read live at draw time; the stock code also asks the list to redraw
end

function _M:innerDisplayBack(x, y, nb_keyframes)
	x, y = x + self.ix, y + self.iy
	quad(x, y, self.nav_w, self.ih, PANE)
	quad(x + self.nav_w + 12, y, self.rows_w, self.ih, {18, 19, 23})
end
