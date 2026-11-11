-- ToME - Tales of Maj'Eyal
-- iOS port: mobile-native character sheet.
--
-- CharacterSheet.new(actor) is called from many places (Inspect on the map
-- menu, the strip header, the who-block, talents / prodigies dialogs); on a
-- touch device CharacterSheet:init hands over to build() below, so every call
-- site keeps working and `self` stays a CharacterSheet (its drawDialog code
-- is still what produces the numbers: collectTouchLines runs it against a
-- recorder and touchRowsFromLines turns the lines into label/value rows).
--
-- Layout: header (sprite, name, level, race/class, life + resource bars),
-- a chip row (General · Offense · Defense · Talents · Equipment), the rows
-- (stat list) or cards (talents) taking the width, and a bottom sheet with
-- the tapped row's explanation. Landscape puts the sheet to the right.

require "engine.class"
local Base = require "engine.ui.Base"
local Focusable = require "engine.ui.Focusable"
local Dialog = require "engine.ui.Dialog"
local Button = require "engine.ui.Button"
local TextzoneList = require "engine.ui.TextzoneList"
local FontPackage = require "engine.FontPackage"
local TouchStatList = require "mod.dialogs.elements.TouchStatList"
local K = require "engine.ui.TouchKit"

module(..., package.seeall)

local GOLD, CARD, PANE = K.GOLD, K.CARD, K.PANE
local font, text, draw, quad, frame = K.font, K.text, K.draw, K.quad, K.frame
local Flow = K.Flow

_M.TABS = {
	{title=_t"General", kind="general"},
	{title=_t"Offense", kind="attack"},
	{title=_t"Defense", kind="defence"},
	{title=_t"Talents", kind="talents"},
	{title=_t"Equipment", kind="equipment"},
}

------------------------------------------------------------------------
-- chips (same widget the inventory uses)
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
	for _, try in ipairs{{17, 26, 6}, {17, 14, 4}, {16, 12, 4}, {15, 10, 3}} do
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
function Chips:select(kind) self.cur = kind end
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

local function normalizeKind(k)
	if k == "defense" then return "defence" end
	for _, t in ipairs(_M.TABS) do if t.kind == k then return k end end
	return "general"
end

------------------------------------------------------------------------
-- build: called from CharacterSheet:initTouch with the CharacterSheet instance
------------------------------------------------------------------------
function _M.build(self, actor, start_tab)
	local TI = require "engine.TouchInput"
	-- the instance is a CharacterSheet: give it this module's methods
	for _, k in ipairs{"touchPark", "touchSwitch", "touchTalentSections", "touchSelectCard", "touchRefresh", "touchShow", "touchDetail", "touchHeader", "touchDisplayBack"} do self[k] = _M[k] end
	self.actor = actor
	self.touch = true
	self.touch_args = {actor, start_tab}
	-- what the desktop drawing code (run by collectTouchLines) expects on self
	self.font = core.display.newFont(FontPackage:getFont("mono_small", "mono"))
	self.font_w, self.font_h = self.font:size(' ')
	self.font_h = self.font:lineSkip()
	self.talent_sorting = config.settings.tome.charsheet_talent_sorting or 1
	self.equip_set = self.actor.off_weapon_slots and "off" or "main"
	self.bigfont = font(22)
	self.kind = normalizeKind(start_tab)
	self.portrait = TI.portrait()
	self.is_player = (actor == game.player) or (game.party and game.party:hasMember(actor))

	self.no_close_bar = true -- has its own Close button
	Dialog.init(self, _t"Character sheet", game.w * 0.96, game.h * 0.96)
	self.w_desktop = self.w
	self.touch_static_bg = true
	-- the desktop class draws a big sprite in innerDisplay, binds letter keys and
	-- turns unicode input on when registered: none of that on touch
	self.innerDisplay = function() end
	self.innerDisplayBack = function(d, x, y) _M.touchDisplayBack(d, x, y) end
	self.on_register = function() end
	self.updateKeys = function() end

	local bh = 56
	local chips = {}
	for _, t in ipairs(_M.TABS) do chips[#chips+1] = {title=t.title, kind=t.kind} end
	self.c_chips = Chips.new{width=self.iw, items=chips, default=self.kind, on_change=function(kind) self:touchSwitch(kind) end}

	local uis
	if self.portrait then
		self.head_h = 124
		self.sheet_h = 380
		self.sheet_y = self.ih - self.sheet_h
		self.list_x, self.list_y = 0, self.head_h + self.c_chips.h + 8
		self.list_w, self.list_h = self.iw, self.sheet_y - 8 - self.list_y
		local info_h = self.sheet_h - 8 - bh - 16
		self.c_info = TextzoneList.new{focus_check=true, scrollbar=true, width=self.iw - 16, height=info_h, dest_area={h=info_h}}
		self.info_x, self.info_y = 8, self.sheet_y + 8
		-- Button adds 16 px of frame to the requested width
		local third = math.floor((self.iw - 12) / 3) - 16
		self.b_close = Button.new{text=_t"Close", width=self.is_player and third or (self.iw - 16), font=self.bigfont, fct=function() game:unregisterDialog(self) end}
		self.b_levelup = Button.new{text=_t"Level up", width=third, font=self.bigfont, fct=function() game:unregisterDialog(self) game.key:triggerVirtual("LEVELUP") end}
		self.b_inven = Button.new{text=_t"Inventory", width=third, font=self.bigfont, fct=function() game:unregisterDialog(self) game.key:triggerVirtual("SHOW_INVENTORY") end}
		uis = {
			{left=0, top=self.head_h, ui=self.c_chips},
			{left=8, top=self.info_y, ui=self.c_info},
			{left=0, bottom=0, ui=self.b_close},
			{left=third + 16 + 6, bottom=0, ui=self.b_levelup},
			{left=2 * (third + 16 + 6), bottom=0, ui=self.b_inven},
		}
	else
		self.head_h = 112
		self.list_x, self.list_y = 0, self.head_h + self.c_chips.h + 8
		self.list_w = math.floor(self.iw * 0.55)
		self.list_h = self.ih - self.list_y
		local info_w = self.iw - self.list_w - 12
		local info_h = self.ih - self.list_y - bh - 8
		self.c_info = TextzoneList.new{focus_check=true, scrollbar=true, width=info_w - 8, height=info_h, dest_area={h=info_h}}
		self.info_x, self.info_y = self.list_w + 12 + 8, self.list_y
		local third = math.floor((info_w - 12) / 3) - 16
		self.b_close = Button.new{text=_t"Close", width=self.is_player and third or (info_w - 16), font=self.bigfont, fct=function() game:unregisterDialog(self) end}
		self.b_levelup = Button.new{text=_t"Level up", width=third, font=self.bigfont, fct=function() game:unregisterDialog(self) game.key:triggerVirtual("LEVELUP") end}
		self.b_inven = Button.new{text=_t"Inventory", width=third, font=self.bigfont, fct=function() game:unregisterDialog(self) game.key:triggerVirtual("SHOW_INVENTORY") end}
		uis = {
			{left=0, top=self.head_h, ui=self.c_chips},
			{left=self.info_x, top=self.info_y, ui=self.c_info},
			{left=self.list_w + 12, bottom=0, ui=self.b_close},
			{left=self.list_w + 12 + third + 16 + 6, bottom=0, ui=self.b_levelup},
			{left=self.list_w + 12 + 2 * (third + 16 + 6), bottom=0, ui=self.b_inven},
		}
	end
	if (actor.unused_stats or 0) > 0 or (actor.unused_talents or 0) > 0 or (actor.unused_generics or 0) > 0 or (actor.unused_talents_types or 0) > 0 then self.b_levelup.glow = 0.6 end

	-- the rows (stats / equipment) and the cards (talents) share the same area; the unused one is parked
	self.c_list = TouchStatList.new{width=self.list_w, height=self.list_h, scrollbar=true, rows={}, on_select=function(r) self:touchDetail(r) end}
	self.c_flow = Flow.new{width=self.list_w, height=self.list_h}
	table.insert(uis, {left=self.list_x, top=self.list_y, ui=self.c_list})
	table.insert(uis, {left=self.list_x, top=self.list_y, ui=self.c_flow})

	self:loadUI(uis)
	self:setupUI()
	for _, u in ipairs(self.uis) do u.home_x, u.home_y = u.x, u.y end
	if not self.is_player then
		self:touchPark(self.b_levelup, false)
		self:touchPark(self.b_inven, false)
	end
	self:touchRefresh()
	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end }

	-- rotation hook: a fresh sheet on the same tab
	self.touch_reopen = function(d)
		local nd = require("mod.dialogs.CharacterSheet").new(d.actor, d.kind)
		return nd
	end
	-- the chip row highlight follows the tab
	self.c_chips:select(self.kind)
	return self
end

-- hidden uis still receive taps: park unused ones off-screen
function _M.touchPark(self, ui, show)
	local u = self.ui_by_ui[ui]
	if not u then return end
	if show then u.x, u.y = u.home_x, u.home_y else u.x, u.y = 100000, 100000 end
	u.hidden = not show
	if ui.mouse then ui.mouse.delegate_offset_x, ui.mouse.delegate_offset_y = u.x, u.y end
end

function _M.touchSwitch(self, kind)
	self.kind = normalizeKind(kind)
	self.c_chips:select(self.kind)
	self:touchRefresh()
end

------------------------------------------------------------------------
-- content per tab
------------------------------------------------------------------------
local function talentIcon(t)
	local tiles = game.uiset and game.uiset.hotkeys_display_icons and game.uiset.hotkeys_display_icons.tiles
	local e = t.display_entity
	if not e then return nil end
	if tiles then pcall(e.getMapObjects, e, tiles, {}, 1) end
	return function(x, y, size) pcall(e.toScreen, e, tiles, x, y, size, size) end
end

--- Talent cards grouped by category / type, the same grouping the desktop sheet uses
function _M.touchTalentSections(self)
	local a = self.actor
	local groups, order = {}, {}
	for _, t in pairs(a.talents_def) do
		if a:knowTalent(t.id) and (not t.hide or t.hide ~= "always") then
			local tt = a:getTalentTypeFrom(t.type[1])
			local gname
			if tt.type:match("inscriptions/.*") then gname = _t"Inscriptions"
			elseif tt.type:match("uber/.*") then gname = _t"Prodigies"
			elseif tt.type:match(".*/objects") then gname = _t"Item talents"
			else
				local mastery = a:getTalentTypeMastery(tt.type)
				local cat = _t(tt.type:gsub("/.*", ""), "talent category"):bookCapitalize()
				gname = ("%s / %s (x%.2f)"):format(cat, (tt.name or ""):bookCapitalize(), mastery)
			end
			if not groups[gname] then groups[gname] = {} order[#order+1] = gname end
			local lvl = a:getTalentLevelRaw(t)
			local mode = t.mode == "sustained" and (a:isTalentActive(t.id) and _t"sustain · active" or _t"sustain") or t.mode == "passive" and _t"passive" or _t"active"
			table.insert(groups[gname], {name=t.name, sub=("Level %d · %s"):tformat(lvl, mode), icon=talentIcon(t), data={talent=t},
				on_tap=function(it) self:touchSelectCard(it) end})
		end
	end
	table.sort(order, function(x, y)
		local rank = {[_t"Inscriptions"]=1, [_t"Prodigies"]=2, [_t"Item talents"]=3}
		local rx, ry = rank[x] or 10, rank[y] or 10
		if rx ~= ry then return rx < ry end
		return x < y
	end)
	local secs = {}
	for _, g in ipairs(order) do
		table.sort(groups[g], function(x, y) return x.name < y.name end)
		secs[#secs+1] = {title=g, items=groups[g], min_w=200, row_h=74, icon_size=40}
	end
	if #secs == 0 then secs[1] = {title=_t"Talents", items={{name=_t"No talents known"}}, cols=1, row_h=60} end
	return secs
end

function _M.touchSelectCard(self, it)
	for _, sec in ipairs(self.c_flow.sections) do for _, o in ipairs(sec.items) do o.sel = (o == it) end end
	self.cur_card = it
	local t = it.data and it.data.talent
	if t then
		local ok, d = pcall(self.actor.getTalentFullDescription, self.actor, t)
		self:touchShow(ok and d or tostring(t.name))
	end
end

function _M.touchRefresh(self)
	local kind = self.kind
	if kind == "talents" then
		self.c_flow:setSections(self:touchTalentSections())
		self.c_flow.scrollbar.pos = 0
		self:touchPark(self.c_flow, true)
		self:touchPark(self.c_list, false)
		self.cur_card = nil
		local hint = _t"#GREY#Tap a talent for its description.#LAST#"
		self:touchShow(hint)
		self.touch_rows = 0
		for _, sec in ipairs(self.c_flow.sections) do self.touch_rows = self.touch_rows + #sec.items end
		return
	end
	local rows
	if kind == "equipment" then
		rows = self:touchEquipmentRows()
	else
		rows = self:touchRowsFromLines(self:collectTouchLines(kind))
		if kind == "general" and self.is_player then
			local kills = self.actor.all_kills_kind or {}
			local secs = (game.total_playtime or 0) + (os.time() - (game.last_update or game.real_starttime or os.time()))
			local head = {
				{head=true, label=_t"Adventure"},
				{label=_t"Day / month", value=("%d / %s"):format(game.turn / game.calendar.DAY, game.calendar:getMonthName(game.calendar:getDayOfYear(game.turn)))},
				{label=_t"Time playing", value=("%dh %02dm"):format(math.floor(secs / 3600), math.floor(secs / 60) % 60)},
				{label=_t"Creatures killed", value=tostring(kills.creature or 0)},
				{label=_t"Elites / rares / bosses", value=("#YELLOW#%d#LAST# / #SALMON#%d#LAST# / #ORANGE#%d#LAST#"):format(kills.elite or 0, kills.rare or 0, kills.boss or 0)},
			}
			for i = #head, 1, -1 do table.insert(rows, 1, head[i]) end
		end
	end
	if #rows == 0 then rows = {{label=_t"Nothing to show", value=""}} end
	self.c_list:setRows(rows)
	self.touch_rows = #rows
	self:touchPark(self.c_list, true)
	self:touchPark(self.c_flow, false)
	local hint = kind == "equipment" and _t"#GREY#Tap an item for its description.#LAST#" or _t"#GREY#Tap a line for its explanation.#LAST#"
	self:touchShow(hint)
end

function _M.touchShow(self, txt)
	self.touch_text = txt
	self.c_info:erase()
	self.c_info:switchItem(txt, txt, true)
end

function _M.touchDetail(self, r)
	local txt
	if r.object then
		local ok, d = pcall(r.object.getDesc, r.object, {do_color=true}, nil, nil, self.actor)
		txt = ok and d or tostring(r.object.name)
	elseif r.tip then
		txt = r.tip
	else
		txt = r.colored or (r.label..(r.value ~= "" and (": "..r.value) or ""))
	end
	self:touchShow(txt)
end

------------------------------------------------------------------------
-- header + panes
------------------------------------------------------------------------
local function bar(x, y, w, h, v, max, c)
	quad(x, y, w, h, {24, 26, 32})
	local f = (max and max > 0) and util.bound(v / max, 0, 1) or 0
	if f > 0 then quad(x, y, math.floor(w * f), h, c) end
	frame(x, y, w, h, {58, 61, 70}, 1)
end

function _M.touchHeader(self, x, y)
	local a = self.actor
	local portrait = self.portrait
	local sz = portrait and 96 or 72
	quad(x, y, self.iw, self.head_h - 8, {22, 24, 30})
	quad(x + 6, y + 6, sz + 8, sz + 8, {14, 15, 18})
	pcall(a.toScreen, a, nil, x + 10, y + 10, sz, sz)
	local tx = x + sz + 26
	local tw = self.iw - (sz + 34)
	local ok, name = pcall(a.getName, a)
	draw(text(ok and tostring(name) or tostring(a.name), 24, 240, 212, 138, true, tw), tx, y + 8)
	local desc = a.descriptor or {}
	local who = {}
	if a.level then who[#who+1] = (_t"Level %d"):format(a.level) end
	if desc.subrace then who[#who+1] = tostring(desc.subrace) elseif a.type then who[#who+1] = tostring(a.type):capitalize() end
	if desc.subclass then who[#who+1] = tostring(desc.subclass) elseif a.subtype and not desc.subrace then who[#who+1] = tostring(a.subtype) end
	if a.rank and not self.is_player and a.TextRank then local ok2, rk = pcall(a.TextRank, a) if ok2 and rk then who[#who+1] = (tostring(rk):gsub("#[^#]*#", "")) end end
	draw(text(table.concat(who, " · "), 15, 200, 195, 180, false, tw), tx, y + 40)
	-- life then the first resources that matter for this actor
	local by = y + (portrait and 66 or 62)
	local bw = math.min(tw - 8, portrait and 300 or 260)
	if a.max_life then
		bar(tx, by, bw, 14, a.life or 0, a.max_life, {200, 40, 40})
		draw(text(("%d / %d"):format(math.floor(a.life or 0), math.floor(a.max_life)), 14, 235, 230, 215, true), tx + bw + 8, by - 2)
		by = by + 19
	end
	local n = 0
	for _, res in ipairs(a.resources_def or {}) do
		if n >= 2 then break end
		local max = a["max_"..res.short_name]
		local v = a[res.short_name]
		if max and max > 0 and v and (not res.talent or a:knowTalent(res.talent)) and not res.invert_values then
			local col = type(res.color) == "table" and res.color or {120, 160, 255}
			if type(col) == "string" then col = {120, 160, 255} end
			bar(tx, by, bw, 10, v, max, {col[1] or 120, col[2] or 160, col[3] or 255})
			draw(text(("%s %d / %d"):format(res.name or res.short_name, math.floor(v), math.floor(max)), 14, 200, 195, 180, false, tw - bw - 8), tx + bw + 8, by - 4)
			by = by + 16
			n = n + 1
		end
	end
end

function _M.touchDisplayBack(self, x, y)
	x, y = x + self.ix, y + self.iy
	self:touchHeader(x, y)
	if self.portrait then
		quad(x, y + self.sheet_y, self.iw, self.sheet_h, PANE)
		quad(x, y + self.sheet_y, self.iw, 2, {58, 61, 70})
	else
		quad(x + self.list_w + 12, y + self.list_y, self.iw - self.list_w - 12, self.ih - self.list_y, PANE)
	end
end
