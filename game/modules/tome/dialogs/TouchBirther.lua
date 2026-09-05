-- ToME iOS port: mobile-native character creation.
-- A five-step walk (Who, Race, Class, Difficulty, Start) over the stock
-- Birther's descriptor logic: this file only replaces the widgets, every
-- rule about what is allowed/locked/applied still lives in mod.dialogs.Birther.

require "engine.class"
local Birther = require "mod.dialogs.Birther"
local Dialog = require "engine.ui.Dialog"
local Base = require "engine.ui.Base"
local Focusable = require "engine.ui.Focusable"
local Button = require "engine.ui.Button"
local Textbox = require "engine.ui.Textbox"
local TextzoneList = require "engine.ui.TextzoneList"
local Slider = require "engine.ui.Slider"
local FontPackage = require "engine.FontPackage"
local Tiles = require "engine.Tiles"
local Entity = require "engine.Entity"
local Object = require "mod.class.Object"

module(..., package.seeall, class.inherit(Birther))

local GOLD = {210, 170, 74}
local CARD = {29, 31, 38}
local CARD_SEL = {43, 39, 24}
local PANE = {24, 26, 32}

-- shared text cache: one texture per (font size, string, colour)
local fonts = {}
local function font(size)
	if not fonts[size] then fonts[size] = core.display.newFont(FontPackage:getFont("default"), size) end
	return fonts[size]
end
local texts = {}
local function text(str, size, r, g, b, bold, maxw)
	str = tostring(str or "")
	local f = font(size)
	if maxw then
		-- ellipsis when the string does not fit
		local plain = str:gsub("#[^#]*#", "")
		if f:size(plain) > maxw then
			local n = #plain
			while n > 1 and f:size(plain:sub(1, n) .. "...") > maxw do n = n - 1 end
			str = plain:sub(1, n) .. "..."
		end
	end
	local key = size .. "|" .. r .. "," .. g .. "," .. b .. (bold and "b" or "") .. "|" .. str
	local d = texts[key]
	if not d then
		if bold then f:setStyle("bold") end
		local w = f:size((str:gsub("#[^#]*#", ""))) + 6
		local list = f:draw(str, w, r, g, b, true)
		if bold then f:setStyle("normal") end
		d = list and list[1] or false
		if d then d.w = math.min(d.w, w) end
		texts[key] = d
	end
	return d or nil
end
local function draw(d, x, y, a)
	if not d then return 0 end
	d._tex:toScreenFull(x, y, d.w, d.h, d._tex_w, d._tex_h, 1, 1, 1, a or 1)
	return d.w
end
local function quad(x, y, w, h, c, a) core.display.drawQuad(x, y, w, h, c[1], c[2], c[3], a or 255) end
local function frame(x, y, w, h, c, t)
	t = t or 2
	quad(x, y, w, t, c) quad(x, y + h - t, w, t, c) quad(x, y, t, h, c) quad(x + w - t, y, t, h, c)
end
local function circle(cx, cy, r, c, a, ring)
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
	core.display.glScissor(true, screen_x, screen_y, self.w, self.h)
	for _, sec in ipairs(self.sections) do
		if sec.title and sec.ty + 30 - self.scrollbar.pos > 0 and sec.ty - self.scrollbar.pos < self.h then
			draw(text(sec.title:upper(), 12, 142, 136, 120, true), x + 6, oy + sec.ty + 8)
		end
		for _, it in ipairs(sec.items) do
			local iy = oy + it.y
			if iy + it.h > y and iy < y + self.h then
				local a = it.locked and 0.4 or 1
				quad(x + it.x, iy, it.w, it.h, it.sel and CARD_SEL or CARD)
				if it.sel then frame(x + it.x, iy, it.w, it.h, GOLD, 2) end
				local tx = x + it.x + 10
				local ty = iy + 8
				if it.icon and sec.icon_only then
					local size = math.min(it.h - 16, sec.icon_size or 40)
					pcall(it.icon, x + it.x + (it.w - size) / 2, iy + 4, size)
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
						pcall(it.icon, tx, ty, size)
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
	core.display.glScissor(false)
	if self.scrollbar.max > 0 then
		-- a slim indicator instead of the engine scrollbar
		local frac = self.h / self.total_h
		local bh = math.max(20, self.h * frac)
		local by = (self.h - bh) * (self.scrollbar.pos / self.scrollbar.max)
		quad(x + self.w - 4, y + by, 3, bh, {120, 120, 120}, 120)
	end
end

---------------------------------------------------------------------------
-- The dialog
---------------------------------------------------------------------------
_M.STEPS = {"who", "race", "class", "difficulty", "start"}

function _M:init(title, actor, order, at_end, quickbirth, w, h)
	if __IOS__ then require("mod.class.TouchWheel").applyUnlocks() end
	self.quickbirth = quickbirth
	self.actor = actor:cloneFull()
	self.actor_base = actor
	self.order = order
	self.at_end = at_end
	self.selected_cosmetic_options = nil
	self.tiles = Tiles.new(64, 64, nil, nil, true, nil)
	self.previews = {}
	self.step = 1

	Dialog.init(self, _t"New character", game.w * 0.98, game.h * 0.98)

	self.obj_list = Object:loadList("/data/general/objects/objects.lua")
	self.obj_list_by_name = {}
	for i, e in ipairs(self.obj_list) do if e.name and (e.rarity or e.define_as) then self.obj_list_by_name[e.name] = e end end

	self.descriptors = {}
	self.descriptors_by_type = {}
	self.to_reset_cosmetic = {}
	self.c_options = {} -- updateDescriptors pokes .hide
	self.c_female, self.c_male = {checked=true}, {checked=false} -- randomBirth pokes .checked

	local bigfont = font(22)
	self.c_name = Textbox.new{title="", text=(not config.settings.cheat and game.player_name == "player") and (config.settings.autopilot and ("Soak_%d"):format(os.time()) or "Adventurer") or game.player_name, chars=24, max_len=50, fct=function() end,
		on_change=function() self:setDescriptor() end}
	self.b_dice = Button.new{text=_t"Random", font=bigfont, fct=function() self:randomName() self:setDescriptor() end}

	self:generateCampaigns()
	self:generateDifficulties()
	self:generatePermadeaths()
	self:setDescriptor("base", "base")
	self:setDescriptor("world", self.default_campaign)
	self:setDescriptor("difficulty", self.default_difficulty)
	self:setDescriptor("permadeath", self.default_permadeath)
	self:setDescriptor("sex", "Female")
	if config.settings.tome.default_birth and config.settings.tome.default_birth.sex then
		self.c_female.checked = config.settings.tome.default_birth.sex == "Female"
		self.c_male.checked = not self.c_female.checked
		self:setDescriptor("sex", self.c_female.checked and "Female" or "Male")
	end
	self:generateRaces()
	self:generateClasses()

	-- layout: rail | content | detail
	local gap = 12
	self.rail_w, self.detail_w = 200, 400
	self.content_w = self.iw - self.rail_w - self.detail_w - 2 * gap
	self.c_rail = Rail.new{width=self.rail_w, height=self.ih, on_pick=function(i) self:goStep(i) end, steps={
		{name=_t"Who", value=function() return self.c_name.text ~= "" and (self.c_name.text .. ", " .. (self.descriptors_by_type.sex == "Female" and _t"female" or _t"male")) or "" end, reach=function() return true end, done=function() return self.c_name.text:len() >= 2 end},
		{name=_t"Race", value=function() return self.sel_race and self.sel_race.basename:toString() or "" end, reach=function() return self:canReach(2) end, done=function() return self.sel_race ~= nil end},
		{name=_t"Class", value=function() return self.sel_class and self.sel_class.basename:toString() or "" end, reach=function() return self:canReach(3) end, done=function() return self.sel_class ~= nil end},
		{name=_t"Difficulty", value=function() return tostring(self.descriptors_by_type.difficulty) .. " · " .. tostring(self.descriptors_by_type.permadeath) end, reach=function() return self:canReach(4) end, done=function() return self.step > 4 end},
		{name=_t"Start", value=function() return "" end, reach=function() return self:canReach(5) end, done=function() return false end},
	}}
	self.c_flow = Flow.new{width=self.content_w, height=self.ih}
	self.desc_y = 236
	local bh = 60
	self.c_desc = TextzoneList.new{focus_check=true, scrollbar=true, width=self.detail_w - 16, height=self.ih - self.desc_y - bh - 14, dest_area={h=self.ih - self.desc_y - bh - 14}}
	self.b_back = Button.new{text=_t"Back", width=120, font=bigfont, fct=function() self:goStep(self.step - 1) end}
	self.b_next = Button.new{text=_t"Next", width=self.detail_w - 120 - 8, font=bigfont, fct=function() self:nextPressed() end}
	self.c_ok = self.b_next -- Birther:atEnd looks at ui_by_ui[c_ok].hidden

	local cx = self.rail_w + gap
	local dx = cx + self.content_w + gap
	self:loadUI{
		{left=0, top=0, ui=self.c_rail},
		{left=cx, top=0, ui=self.c_flow},
		{left=dx + 8, top=self.desc_y, ui=self.c_desc},
		{left=dx, bottom=0, ui=self.b_back},
		{left=dx + 128, bottom=0, ui=self.b_next},
		{left=cx + 8, top=44, ui=self.c_name},
		{left=cx + 8 + self.c_name.w + 8, top=44, ui=self.b_dice},
	}
	self:setupUI()
	self.name_pos = {x=self.ui_by_ui[self.c_name].x, y=self.ui_by_ui[self.c_name].y, dx=self.ui_by_ui[self.b_dice].x, dy=self.ui_by_ui[self.b_dice].y}
	self.built = true
	self:setFocus(self.c_flow)
	self:goStep(1)
	-- Escape (two-finger tap, close box) steps back; from the first step it cancels.
	-- The soak autopilot dismisses every dialog with EXIT, so it must not quit there.
	self.key:addBinds{ EXIT = function()
		local okap, AP = pcall(require, "mod.class.AutoPilot")
		if okap and AP.enabled() then return end
		if self.step > 1 then self:goStep(self.step - 1) else self:atEnd("quit") end
	end }

end

-- autopilot soak: once registered, roll the first race/class and play
function _M:on_register()
	Birther.on_register(self)
	local ok, AP = pcall(require, "mod.class.AutoPilot")
	if ok and AP.enabled() and game.creating_player then
		game:onTickEnd(function()
			local okb, err = pcall(function()
				self:raceUse(self.all_races[1].nodes[1])
				self:classUse(self.all_classes[1].nodes[1])
				AP.event("birther_state", {subrace=tostring(self.descriptors_by_type.subrace), subclass=tostring(self.descriptors_by_type.subclass), race=tostring(self.descriptors_by_type.race)})
				self:atEnd("created")
			end)
			if not okb then AP.event("autopilot_error", {err=tostring(err)}) end
		end)
	end
end

function _M:canReach(i)
	if i <= 1 then return true end
	if self.c_name.text:len() < 2 then return false end
	if i >= 3 and not self.sel_race then return false end
	if i >= 4 and not self.sel_class then return false end
	if i >= 5 and not self.ready then return false end
	return true
end

-- Birther hooks --------------------------------------------------------------

function _M:setDescriptor(key, val)
	if key then self.descriptors_by_type[key] = val print("[BIRTHER] set descriptor", key, val) end
	self:updateDescriptors()
	self:setTile()
	local ok = self.c_name.text:len() >= 2
	for _, o in ipairs(self.order) do if not self.descriptors_by_type[o] then ok = false break end end
	self.ready = ok
	if self.built then self:refresh() end
end

function _M:raceUse(item)
	if not item then return end
	if item.nodes then
		if item.locked then self:focusItem(item) return end
		self.race_parent = item
		-- a single lineage: pick it right away
		local only
		for _, n in ipairs(item.nodes) do if not n.locked then if only then only = false break else only = n end end end
		if only then return self:raceUse(only) end
		self:focusItem(item)
		self:refresh()
		self:revealSection(2)
	elseif not item.locked and item.basename then
		self.race_parent = nil
		for _, r in ipairs(self.all_races) do if r.id == item.pid then self.race_parent = r end end
		self.sel_race = item
		self.previews = {}
		self:setDescriptor("race", item.pid)
		self:setDescriptor("subrace", item.id)
		self:generateClasses()
		self:focusItem(item)
	else
		self:focusItem(item)
	end
end

function _M:classUse(item)
	if not item then return end
	if item.nodes then
		if item.locked then self:focusItem(item) return end
		self.class_parent = item
		self:focusItem(item)
		self:refresh()
		self:revealSection(2)
	elseif not item.locked and item.basename then
		self.class_parent = nil
		for _, c in ipairs(self.all_classes) do if c.id == item.pid then self.class_parent = c end end
		self.sel_class = item
		self:setDescriptor("class", item.pid)
		self:setDescriptor("subclass", item.id)
		self:focusItem(item)
	else
		self:focusItem(item)
	end
end

-- the stock generators only re-validate the selection through the tree widgets: do it here
function _M:generateRaces()
	Birther.generateRaces(self)
	if not self.sel_race then return end
	local found
	for _, r in ipairs(self.all_races) do for _, n in ipairs(r.nodes) do if n.id == self.sel_race.id and not n.locked then found = n end end end
	if found then self.sel_race = found
	else self.sel_race, self.race_parent = nil, nil self:setDescriptor("race", nil) self:setDescriptor("subrace", nil) end
end
function _M:generateClasses()
	Birther.generateClasses(self)
	if not self.sel_class then return end
	local found
	for _, c in ipairs(self.all_classes) do for _, n in ipairs(c.nodes) do if n.id == self.sel_class.id and not n.locked then found = n end end end
	if found then self.sel_class = found
	else self.sel_class, self.class_parent = nil, nil self:setDescriptor("class", nil) self:setDescriptor("subclass", nil) end
end

function _M:atEnd(v)
	if v == "created" then
		if not self.ready then return end
		self.ui_by_ui[self.c_ok].hidden = false
	end
	return Birther.atEnd(self, v)
end

function _M:randomBirth()
	Birther.randomBirth(self)
	self:setDescriptor()
	self:goStep(5)
end

function _M:on_focus() end

-- steps ----------------------------------------------------------------------

function _M:goStep(i)
	i = util.bound(i, 1, #_M.STEPS)
	if not self:canReach(i) then return end
	if self.step ~= i then self.c_flow.scrollbar.pos = 0 end
	self.step = i
	self.c_rail.cur = i
	self.cur_item = nil
	-- the name box (and its keyboard) only exist on the first step
	local nm, dc = self.ui_by_ui[self.c_name], self.ui_by_ui[self.b_dice]
	if i == 1 then nm.x, nm.y, dc.x, dc.y = self.name_pos.x, self.name_pos.y, self.name_pos.dx, self.name_pos.dy
	else nm.x, nm.y, dc.x, dc.y = -9999, -9999, -9999, -9999 if self.focus_ui and self.focus_ui.ui == self.c_name then self:setFocus(self.c_flow) end end
	self:refresh()
end

-- scroll the flow so a section's title sits near the top
function _M:revealSection(i)
	local sec = self.c_flow.sections[i]
	if not sec or not sec.ty then return end
	self.c_flow.scrollbar.pos = util.minBound(sec.ty - 8, 0, self.c_flow.scrollbar.max)
end

function _M:nextPressed()
	if self.step >= 5 then self:atEnd("created") return end
	self:goStep(self.step + 1)
end

function _M:refresh()
	if not self.built then return end
	local s = _M.STEPS[self.step]
	local secs = {}
	if s == "who" then
		secs[#secs+1] = {spacer=100, items={}} -- the name box sits here (a real widget)
		local sex = {}
		for _, n in ipairs{"Female", "Male"} do
			local d = self.birth_descriptor_def.sex[n]
			sex[#sex+1] = {name=d.display_name or n, sel=self.descriptors_by_type.sex == n, desc=d.desc, on_tap=function()
				self.c_female.checked = n == "Female" self.c_male.checked = n == "Male"
				self:setDescriptor("sex", n) self:focusItem({name=n, desc=d.desc})
			end}
		end
		secs[#secs+1] = {title=_t"Sex", items=sex, cols=2, row_h=60, center=true}
	elseif s == "race" then
		secs[#secs+1] = {title=_t"Race", items=self:cardsFor(self.all_races, self.race_parent, function(it) self:raceUse(it) end, true)}
		if self.race_parent and not self.race_parent.locked and #self.race_parent.nodes > 1 then
			secs[#secs+1] = {title=(_t"%s lineage"):format(self.race_parent.id), items=self:cardsFor(self.race_parent.nodes, self.sel_race, function(it) self:raceUse(it) end)}
		end
		if self.sel_race then
			for _, group in ipairs(self.cosmetic_options or {}) do
				local items = {}
				for _, opt in ipairs(group.nodes) do
					if not opt.nodes then
						items[#items+1] = {name=opt.name, sel=self:cosmeticSelected(opt), data=opt, icon=function(x, y, size) self:drawPreview(opt, x, y, size) end,
							on_tap=function() self:toggleCosmetic(opt) end}
					end
				end
				if #items > 0 then
					-- some groups combine (a beard and a scar), others are one-of: say which
					local multi = self.cosmetic_options_config[group.kind] == "multiple"
					secs[#secs+1] = {title=tostring(group.name) .. (multi and _t" · pick any" or _t" · pick one"), items=items, min_w=84, row_h=88, icon_size=64, icon_only=true}
				end
			end
		end
	elseif s == "class" then
		secs[#secs+1] = {title=_t"Class", items=self:cardsFor(self.all_classes, self.class_parent, function(it) self:classUse(it) end, true)}
		if self.class_parent and not self.class_parent.locked then
			secs[#secs+1] = {title=(_t"%s paths"):format(self.class_parent.id), items=self:cardsFor(self.class_parent.nodes, self.sel_class, function(it) self:classUse(it) end)}
		end
	elseif s == "difficulty" then
		local function seg(list, cur, fct)
			local items = {}
			for _, it in ipairs(list) do
				local name = tostring(it.locked and it.id or it.name):gsub("#[^#]*#", ""):gsub("%s*:.*$", "")
				items[#items+1] = {name=name, sub=pitch(it.desc), sel=cur == it.id, locked=it.locked, data=it, on_tap=function() self:focusItem(it) if not it.locked then fct(it) end end}
			end
			return items
		end
		if #self.all_campaigns > 1 then
			secs[#secs+1] = {title=_t"Campaign", items=seg(self.all_campaigns, self.descriptors_by_type.world, function(it) self:campaignUse(it) self:refresh() end), cols=2, row_h=88}
		end
		secs[#secs+1] = {title=_t"Difficulty", items=seg(self.all_difficulties, self.descriptors_by_type.difficulty, function(it) self:difficultyUse(it) self:refresh() end), min_w=150, row_h=88}
		secs[#secs+1] = {title=_t"Death", items=seg(self.all_permadeaths, self.descriptors_by_type.permadeath, function(it) self:permadeathUse(it) self:refresh() end), min_w=150, row_h=88}
	else
		local rows = {
			{name=_t"Name", sub=self.c_name.text .. " · " .. tostring(self.descriptors_by_type.sex), go=1},
			{name=_t"Race", sub=self.sel_race and (self.sel_race.basename:toString() .. " " .. self.sel_race.pid) or "—", go=2},
			{name=_t"Class", sub=self.sel_class and self.sel_class.basename:toString() or "—", go=3},
			{name=_t"Difficulty", sub=tostring(self.descriptors_by_type.difficulty), go=4},
			{name=_t"Death", sub=tostring(self.descriptors_by_type.permadeath), go=4},
		}
		if #self.all_campaigns > 1 then table.insert(rows, 4, {name=_t"Campaign", sub=tostring(self.descriptors_by_type.world), go=4}) end
		for _, r in ipairs(rows) do r.on_tap = function() self:goStep(r.go) end end
		secs[#secs+1] = {title=_t"Your character", items=rows, cols=1, row_h=52, rows=true}
		local more = {
			{name=_t"Tutorial", sub=_t"Learn the basics first", on_tap=function() self:tutorial() end},
			{name=_t"Random", sub=_t"Roll everything", on_tap=function() self:randomBirth() end},
			{name=_t"Premade", sub=_t"Load a saved character", on_tap=function() self:loadPremadeUI() end},
			{name=_t"Custom tile", sub=_t"Pick another sprite", on_tap=function() self:selectTile() end},
		}
		secs[#secs+1] = {title=_t"More", items=more, min_w=170, row_h=64}
	end
	self.c_flow:setSections(secs)
	self.b_back.text = self.step == 1 and _t"Cancel" or _t"Back"
	self.b_back.fct = function() if self.step == 1 then self:atEnd("quit") else self:goStep(self.step - 1) end end
	self.b_back:generate()
	local nt = self.step == 5 and _t"Begin" or (self.step == 4 and _t"Review" or _t"Next")
	if self.b_next.text ~= nt then self.b_next.text = nt self.b_next:generate() end
	self.next_ok = self.step == 5 and self.ready or (self.step < 5 and self:canReach(self.step + 1))
	self.ui_by_ui[self.c_ok].hidden = false
	self:showDetail()
end

function _M:cardsFor(list, sel, fct, parents)
	local items = {}
	for _, it in ipairs(list) do
		local icon
		local def = it.def or (parents and it.nodes and it.nodes[1] and it.nodes[1].def)
		if def and def.display_entity32 then icon = function(x, y, size) def.display_entity32:toScreen(self.tiles, x, y, size, size) end end
		local sprite_id = (it.pid and not it.locked and self.birth_descriptor_def.subrace[it.id]) and it.id or nil
		if not sprite_id and parents and it.nodes and not it.locked then
			for _, n in ipairs(it.nodes) do if not n.locked and self.birth_descriptor_def.subrace[n.id] then sprite_id = n.id break end end
		end
		if not icon and sprite_id then
			local img = "player/" .. sprite_id:lower():gsub("[^a-z0-9_]", "_") .. "_" .. tostring(self.descriptors_by_type.sex or "Female"):lower() .. ".png"
			local e = Entity.new{image=img}
			icon = function(x, y, size) e:toScreen(self.tiles, x, y, size, size) end
		end
		items[#items+1] = {name=it.basename or it.id, sub=pitch(it.desc), locked=it.locked, icon=icon, data=it,
			sel=(sel == it) or (sel and sel.id == it.id) or false, on_tap=function() fct(it) end}
	end
	return items
end

-- detail pane ---------------------------------------------------------------

function _M:focusItem(item)
	self.cur_item = item
	self:showDetail()
end

function _M:showDetail()
	local it = self.cur_item
	local desc
	if it and it.desc then desc = it.desc
	elseif self.step == 1 then desc = _t"Your name is what the log calls you and what the high scores remember. Tap Random for one that fits your race."
	elseif self.step == 5 then desc = _t"Everything can still be changed from the list on the left. Begin when you are ready."
	elseif self.step == 4 then desc = _t"Difficulty and death rules cannot be changed once the game starts."
	else desc = _t"Tap a card to read about it." end
	if type(desc) == "table" then desc = table.concat(desc, "\n") end
	self.c_desc:switchItem(it or desc, desc)
end

local STAT_NAMES = {str=_t"Str", dex=_t"Dex", con=_t"Con", mag=_t"Mag", wil=_t"Wil", cun=_t"Cun", lck=_t"Lck"}
local STAT_ORDER = {"str", "dex", "con", "mag", "wil", "cun", "lck"}
function _M:statChips(it)
	local chips = {}
	local def = it and it.data and it.data.id and (self.birth_descriptor_def.subrace[it.data.id] or self.birth_descriptor_def.subclass[it.data.id])
	if it and it.id and not def then def = self.birth_descriptor_def.subrace[it.id] or self.birth_descriptor_def.subclass[it.id] end
	if not def or (it.data and it.data.nodes) or it.nodes then return chips end
	if def.stats then for _, k in ipairs(STAT_ORDER) do local v = def.stats[k] if v and v ~= 0 then chips[#chips+1] = {STAT_NAMES[k], ("%+d"):format(v), v > 0} end end end
	if def.copy and def.copy.life_rating then chips[#chips+1] = {_t"Life", ("%+d/lvl"):format(def.copy.life_rating), def.copy.life_rating > 0} end
	if def.experience and def.experience ~= 1 then chips[#chips+1] = {_t"XP cost", ("%+d%%"):format((def.experience - 1) * 100), def.experience < 1} end
	return chips
end

function _M:innerDisplayBack(x, y, nb_keyframes)
	self.preview_budget = 0
	x, y = x + self.ix, y + self.iy
	local dx = x + self.rail_w + 12 + self.content_w + 12
	local dy = y
	-- panes
	quad(x, y, self.rail_w, self.ih, PANE)
	quad(x + self.rail_w + 12, y, self.content_w, self.ih, {18, 19, 23})
	quad(dx, dy, self.detail_w, self.ih, PANE)
	-- name label on the first step
	if self.step == 1 then draw(text(_t"NAME", 12, 142, 136, 120, true), x + self.rail_w + 12 + 8, y + 12) end
	-- hero: the character as it will look, name and one line
	local sz = 112
	quad(dx + 12, dy + 12, sz + 8, sz + 8, {14, 15, 18})
	if self.actor.image then pcall(self.actor.toScreen, self.actor, self.tiles, dx + 16, dy + 16, sz, sz) end
	local it = self.cur_item
	local title = (it and (it.basename and it.basename:toString() or it.name)) or self.c_name.text
	if type(title) == "table" then title = title:toString() end
	local sub
	if it and it.desc then sub = pitch(it.desc)
	else sub = (self.sel_race and (self.sel_race.basename:toString() .. " ") or "") .. (self.sel_class and self.sel_class.basename:toString() or "") end
	local tx = dx + 12 + sz + 20
	draw(text(title, 22, 240, 212, 138, true, self.detail_w - (tx - dx) - 12), tx, dy + 20)
	if sub and sub ~= "" then
		-- two lines of the pitch
		local maxw = self.detail_w - (tx - dx) - 12
		for li, l in ipairs(wrap(sub, font(13), maxw, 3)) do draw(text(l, 13, 142, 136, 120, false, maxw), tx, dy + 54 + (li - 1) * 18) end
	end
	if self.step == 3 and self.descriptors_by_type.subclass then
		local sc = self.birth_descriptor_def.subclass[self.descriptors_by_type.subclass]
		if sc and sc.display_entity128 then pcall(sc.display_entity128.toScreen, sc.display_entity128, self.tiles, dx + self.detail_w - 60, dy + 12, 48, 48) end
	end
	-- stat chips
	local chips = self:statChips(it)
	local cw = math.floor((self.detail_w - 24 - 2 * 6) / 3)
	for i, c in ipairs(chips) do
		if i > 6 then break end
		local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
		local cx, cy = dx + 12 + col * (cw + 6), dy + 12 + sz + 16 + row * 44
		quad(cx, cy, cw, 40, {36, 39, 47})
		draw(text(c[1]:upper(), 10, 142, 136, 120, true), cx + 8, cy + 4)
		draw(text(c[2], 16, c[3] and 123 or 224, c[3] and 211 or 122, c[3] and 137 or 106, true), cx + 8, cy + 17)
	end
end

function _M:innerDisplay(x, y, nb_keyframes)
	local b = self.ui_by_ui[self.b_next]
	if not b then return end
	if not self.next_ok then
		-- dim the Next button when the step is not complete
		quad(x + b.x, y + b.y, self.b_next.w, self.b_next.h, {14, 15, 18}, 150)
	elseif self.step == 5 then
		-- Begin: a gold frame so it reads as the one big action
		frame(x + b.x - 3, y + b.y - 3, self.b_next.w + 6, self.b_next.h + 6, GOLD, 3)
	end
end

-- cosmetics ----------------------------------------------------------------

function _M:cosmeticSelected(opt)
	local s = self.selected_cosmetic_options and self.selected_cosmetic_options[opt.kind]
	if not s then return false end
	if self.cosmetic_options_config[opt.kind] == "single" then return s == opt end
	return table.hasInList(s, opt)
end

function _M:toggleCosmetic(item)
	self.selected_cosmetic_options = self.selected_cosmetic_options or {}
	local kind = item.kind
	if self.cosmetic_options_config[kind] == "single" then
		if self.selected_cosmetic_options[kind] == item then self.selected_cosmetic_options[kind] = nil
		else self.selected_cosmetic_options[kind] = item end
	elseif self.cosmetic_options_config[kind] == "multiple" then
		self.selected_cosmetic_options[kind] = self.selected_cosmetic_options[kind] or {}
		if table.hasInList(self.selected_cosmetic_options[kind], item) then table.removeFromList(self.selected_cosmetic_options[kind], item)
		else table.insert(self.selected_cosmetic_options[kind], item) end
		if #self.selected_cosmetic_options[kind] == 0 then self.selected_cosmetic_options[kind] = nil end
	end
	for _, ii in ipairs(self.cosmetic_options_flat) do ii.selected = self:cosmeticSelected(ii) end
	self:setTile(nil, nil, nil, false, true)
	self:focusItem({name=item.name, desc=(_t"%s. Cosmetic only: it changes how your character looks, nothing else."):format(item.name)})
	self:refresh()
end

-- a small clone of the character wearing just this option, built lazily (a couple per frame)
function _M:drawPreview(opt, x, y, size)
	local p = self.previews[opt]
	if p == nil then
		self.preview_budget = (self.preview_budget or 0)
		if self.preview_budget >= 2 then return end
		self.preview_budget = self.preview_budget + 1
		local ok, clone = pcall(function()
			local clone = self.actor:cloneFull()
			local old_actor, old_sel, old_reset = self.actor, self.selected_cosmetic_options, self.to_reset_cosmetic
			self.actor, self.to_reset_cosmetic = clone, {}
			local sel = table.clone(old_sel or {}, false)
			if self.cosmetic_options_config[opt.kind] == "single" then sel[opt.kind] = opt
			else sel[opt.kind] = {opt} end
			self.selected_cosmetic_options = sel
			pcall(self.setTile, self, nil, nil, nil, false, true)
			self.actor, self.selected_cosmetic_options, self.to_reset_cosmetic = old_actor, old_sel, old_reset
			return clone
		end)
		p = ok and clone or false
		self.previews[opt] = p
	end
	if p then pcall(p.toScreen, p, self.tiles, x, y, size, size) end
end
