-- ToME iOS port: mobile-native character creation.
-- A five-step walk (Who, Race, Class, Difficulty, Start) over the stock
-- Birther's descriptor logic: this file only replaces the widgets, every
-- rule about what is allowed/locked/applied still lives in mod.dialogs.Birther.

require "engine.class"
local Birther = require "mod.dialogs.Birther"
local Dialog = require "engine.ui.Dialog"
local Button = require "engine.ui.Button"
local Textbox = require "engine.ui.Textbox"
local TextzoneList = require "engine.ui.TextzoneList"
local FontPackage = require "engine.FontPackage"
local Tiles = require "engine.Tiles"
local Entity = require "engine.Entity"
local Object = require "mod.class.Object"

module(..., package.seeall, class.inherit(Birther))

local K = require "engine.ui.TouchKit"
local GOLD, CARD, CARD_SEL, PANE = K.GOLD, K.CARD, K.CARD_SEL, K.PANE
local font, text, draw, quad, frame, circle, wrap, pitch = K.font, K.text, K.draw, K.quad, K.frame, K.circle, K.wrap, K.pitch
local Rail, Flow = K.Rail, K.Flow

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
