-- ToME iOS port: mobile-native prodigies (uber talents) screen.
-- Cards per stat group (and evolutions) in a drag-scrolling pane, the full
-- description and requirement list on the right, one big Learn button.
-- The rules are the ones mod.dialogs.UberTalent applies: a choice is only
-- marked in levelup_end_prodigies and spends a point; LevelupDialog learns it
-- when the level-up is accepted. Same constructor as UberTalent.new.

require "engine.class"
require "mod.class.interface.TooltipsData"
local Dialog = require "engine.ui.Dialog"
local Button = require "engine.ui.Button"
local TextzoneList = require "engine.ui.TextzoneList"
local K = require "engine.ui.TouchKit"

module(..., package.seeall, class.inherit(Dialog, mod.class.interface.TooltipsData))

local GOLD, CARD, PANE = K.GOLD, K.CARD, K.PANE
local font, text, draw, quad, frame = K.font, K.text, K.draw, K.quad, K.frame
local Flow = K.Flow

local GROUPS = {
	{type="uber/strength", title=_t"Strength"},
	{type="uber/dexterity", title=_t"Dexterity"},
	{type="uber/constitution", title=_t"Constitution"},
	{type="uber/magic", title=_t"Magic"},
	{type="uber/willpower", title=_t"Willpower"},
	{type="uber/cunning", title=_t"Cunning"},
}

_M.tuttext = _t"Prodigies are special talents that only the most powerful of characters can attain. All of them require at least 50 in a core stat and many also have more special demands. You can learn a new prodigy at level 25 and 42."
_M.evotext = _t"Evolutions are special prodigies specific to a class or race. Only one evolution can be chosen, if any are available at all."

function _M:init(actor, levelup_end_prodigies)
	self.actor = actor
	self.levelup_end_prodigies = levelup_end_prodigies or {}
	self.touch_args = {actor, self.levelup_end_prodigies}
	self.bigfont = font(22)

	self.actor_dup = actor:clone()
	self.actor_dup.uid = actor.uid -- Yes ...

	Dialog.init(self, ("Prodigies: %s"):tformat(actor:getName()), game.w * 0.98, game.h * 0.98)

	local gap = 12
	local bh = 56
	-- portrait (phone held upright): the cards take the full width, the
	-- header, description and Learn button live in a bottom sheet
	self.portrait = require("engine.TouchInput").portrait()
	if self.portrait then
		self.detail_w, self.content_w = self.iw, self.iw
		self.head_h = 128                       -- icon, name, status (two lines), points
		local desc_h = 190
		self.sheet_h = self.head_h + desc_h + bh + 8
		self.sheet_y = self.ih - self.sheet_h
		self.desc_y = self.sheet_y + self.head_h
		self.c_flow = Flow.new{width=self.iw, height=self.sheet_y - 8}
		self.c_desc = TextzoneList.new{focus_check=true, scrollbar=true, width=self.iw - 16, height=desc_h, dest_area={h=desc_h}}
		-- Button adds 16 px of frame to the requested width
		self.b_learn = Button.new{text=_t"Learn", width=self.iw - 16, font=self.bigfont, fct=function() self:useCurrent() end}
		self:loadUI{
			{left=0, top=0, ui=self.c_flow},
			{left=8, top=self.desc_y, ui=self.c_desc},
			{left=0, bottom=0, ui=self.b_learn},
		}
		self:setupUI()
	else
	self.detail_w = 400
	self.content_w = self.iw - self.detail_w - gap
	self.c_flow = Flow.new{width=self.content_w, height=self.ih}

	self.desc_y = 128
	local desc_h = self.ih - self.desc_y - bh - 16
	self.c_desc = TextzoneList.new{focus_check=true, scrollbar=true, width=self.detail_w - 16, height=desc_h, dest_area={h=desc_h}}
	self.b_learn = Button.new{text=_t"Learn", width=self.detail_w, font=self.bigfont, fct=function() self:useCurrent() end}

	local dx = self.content_w + gap
	self:loadUI{
		{left=0, top=0, ui=self.c_flow},
		{left=dx + 8, top=self.desc_y, ui=self.c_desc},
		{left=dx, bottom=0, ui=self.b_learn},
	}
	self:setupUI()
	end
	do
		local u = self.ui_by_ui[self.b_learn]
		u.home_x, u.home_y = u.x, u.y
	end
	self:setFocus(self.c_flow)

	self.key:addBinds{
		EXIT = function() game:unregisterDialog(self) end,
	}

	-- same setup as the stock dialog: the uber trees must be known to be browsed
	self.actor:learnTalentType("uber/strength", true)
	self.actor:learnTalentType("uber/dexterity", true)
	self.actor:learnTalentType("uber/constitution", true)
	self.actor:learnTalentType("uber/magic", true)
	self.actor:learnTalentType("uber/willpower", true)
	self.actor:learnTalentType("uber/cunning", true)

	self.fake_evol_attr = 0
	for tid, v in pairs(self.levelup_end_prodigies) do if v then
		local t = self.actor:getTalentFromId(tid)
		if t and (t.is_class_evolution or t.is_race_evolution) then
			self.fake_evol_attr = self.fake_evol_attr + 1
			self.actor:attr("has_evolution", 1)
		end
	end end
	self.actor.is_in_uber_dialog = self

	self.built = true
	self:refresh()
end

function _M:on_register()
	game:onTickEnd(function() self.key:unicodeInput(true) end)
end

function _M:unload()
	if self.fake_evol_attr > 0 then self.actor:attr("has_evolution", -self.fake_evol_attr) end
	self.actor.is_in_uber_dialog = nil
end

function _M:ignoreUnlocks()
	return false
end

-- hidden uis still receive taps: park the button off-screen instead
function _M:place(ui, show)
	local u = self.ui_by_ui[ui]
	if not u then return end
	if show then u.x, u.y = u.home_x, u.home_y else u.x, u.y = -9999, -9999 end
end

---------------------------------------------------------------------------
-- list
---------------------------------------------------------------------------

function _M:isPending(tid)
	return self.levelup_end_prodigies[tid] and true or false
end

-- one line under the card name
function _M:status(t)
	if self.actor:knowTalent(t) then return _t"Learned", "known" end
	if self:isPending(t.id) then return _t"Chosen: learned when you accept", "pending" end
	local ok, why = self.actor:canLearnTalent(t)
	if ok then
		if (self.actor.unused_prodigies or 0) > 0 or config.settings.cheat then return _t"Available", "ok" end
		return _t"Available, no point left", "nopoint"
	end
	why = tostring(why or _t"requirements not met"):gsub("#[^#]*#", "")
	local stat = why:match("^not enough stat: (%w+)")
	if stat then
		local req = t.require
		if type(req) == "function" then req = req(self.actor, t) end
		local need = req and req.stat and req.stat[stat:lower()]
		if type(need) == "table" then need = need[1] end
		if need then return ("Needs %s %d"):tformat(stat, need), "locked" end
		return ("Needs more %s"):tformat(stat), "locked"
	end
	if #why > 60 then why = require("engine.ui.TouchKit").u8cut(why, 58) .. "..." end
	return why:sub(1, 1):upper() .. why:sub(2), "locked"
end

function _M:generateList()
	local groups = {}
	for _, g in ipairs(GROUPS) do groups[#groups+1] = {title=g.title, type=g.type, items={}} end
	local evos = {title=_t"Evolutions", items={}}
	local bytype = {}
	for i, g in ipairs(groups) do bytype[g.type] = g end
	local tiles = game.uiset and game.uiset.hotkeys_display_icons and game.uiset.hotkeys_display_icons.tiles

	for tid, t in pairs(self.actor.talents_def) do
		if t.uber and not t.not_listed then
			if
			    (
			    	not t.is_class_evolution or
			    	((type(t.is_class_evolution) == "string" and self.actor:hasDescriptor("subclass", t.is_class_evolution))) or
			    	((type(t.is_class_evolution) == "function" and t.is_class_evolution(self.actor, t)))
			    ) and
			    (
			    	not t.is_race_evolution or
			    	((type(t.is_race_evolution) == "string" and self.actor:hasDescriptor("subrace", t.is_race_evolution))) or
			    	((type(t.is_race_evolution) == "function" and t.is_race_evolution(self.actor, t)))
			    ) and
			    (not t.requires_unlock or profile.mod.allow_build[t.requires_unlock] or self:ignoreUnlocks())
			    then
				if t.display_entity and tiles then pcall(t.display_entity.getMapObjects, t.display_entity, tiles, {}, 1) end
				local status, kind = self:status(t)
				local e = {talent=t.id, t=t, cname=tostring(t.name), status=status, kind=kind, entity=t.display_entity}
				if not t.is_race_evolution and not t.is_class_evolution then
					local g = bytype[t.type[1]]
					if g then g.items[#g.items+1] = e end
				else
					evos.items[#evos.items+1] = e
				end
			end
		end
	end
	for _, g in ipairs(groups) do table.sort(g.items, function(a, b) return a.cname < b.cname end) end
	table.sort(evos.items, function(a, b) return a.cname < b.cname end)
	self.has_evos = #evos.items > 0
	if self.has_evos then groups[#groups+1] = evos end
	self.groups = groups
end

function _M:drawIcon(e, x, y, size, kind)
	local tiles = game.uiset and game.uiset.hotkeys_display_icons and game.uiset.hotkeys_display_icons.tiles
	quad(x, y, size, size, {14, 15, 18})
	if e then pcall(e.toScreen, e, tiles, x, y, size, size) end
	if kind == "locked" or kind == "nopoint" then quad(x, y, size, size, {0, 0, 0}, 110) end
	if kind == "known" or kind == "pending" then frame(x, y, size, size, kind == "known" and {123, 211, 137} or GOLD, 2) end
end

function _M:refresh(keep_scroll)
	if not self.built then return end
	local pos = keep_scroll and self.c_flow.scrollbar.pos or 0
	self:generateList()
	local secs = {}
	for _, g in ipairs(self.groups) do
		if #g.items > 0 then
			local items = {}
			for _, e in ipairs(g.items) do
				local entry = e
				items[#items+1] = {name=e.cname, sub=e.status, data=e, sel=self.cur and self.cur.talent == e.talent,
					icon=function(x, y, size) self:drawIcon(entry.entity, x, y, size, entry.kind) end,
					on_tap=function() self:select(entry) end}
			end
			secs[#secs+1] = {title=g.title, items=items, min_w=200, row_h=66, icon_size=44}
		end
	end
	if #secs == 0 then secs[1] = {title=_t"Prodigies", items={{name=_t"No prodigy available", sub=_t"None can be shown for this character."}}, cols=1, row_h=66} end
	self.c_flow:setSections(secs)
	self.c_flow.scrollbar.pos = util.minBound(pos, 0, self.c_flow.scrollbar.max)
	if self.cur then
		local found
		for _, g in ipairs(self.groups) do for _, e in ipairs(g.items) do if e.talent == self.cur.talent then found = e end end end
		self.cur = found
	end
	self:showDetail()
end

function _M:select(e)
	self.cur = e
	for _, sec in ipairs(self.c_flow.sections) do for _, it in ipairs(sec.items) do it.sel = it.data and it.data.talent == e.talent end end
	self:showDetail()
end

-- requirements (met in green, unmet in red, from the engine) + full description
function _M:getTalentDesc(e)
	local text = tstring{}
	local t = e.t
	local req = self.actor:getTalentReqDesc(e.talent)
	if req then text:merge(req) end
	if self.actor:knowTalent(t) then
		text:merge(self.actor:getTalentFullDescription(t))
	else
		text:merge(self.actor:getTalentFullDescription(t, 1))
	end
	return text
end

function _M:showDetail()
	local e = self.cur
	if not e then
		local intro = tstring{}
		intro:add(self.tuttext)
		if self.has_evos then intro:add(true, true, self.evotext) end
		self.c_desc:switchItem("none", intro)
		self:place(self.b_learn, false)
		return
	end
	self.c_desc:switchItem(e.talent .. "|" .. tostring(e.status), self:getTalentDesc(e))
	local label
	if e.kind == "pending" then label = _t"Unchoose"
	elseif e.kind == "ok" then label = _t"Learn"
	elseif e.kind == "locked" and config.settings.cheat then label = _t"Learn (cheat)" end
	self:place(self.b_learn, label ~= nil)
	if label and self.b_learn.text ~= label then self.b_learn.text = label self.b_learn:generate() end
end

-- exactly the stock UberTalent:use rules
function _M:use(item)
	local t = self.actor:getTalentFromId(item.talent)
	if self.actor:knowTalent(item.talent) then
	elseif self.levelup_end_prodigies[item.talent] then
		self.levelup_end_prodigies[item.talent] = false
		self.actor.unused_prodigies = self.actor.unused_prodigies + 1
		if t.is_class_evolution or t.is_race_evolution then
			self.actor:attr("has_evolution", -1)
			self.fake_evol_attr = self.fake_evol_attr - 1
		end
	elseif (self.actor:canLearnTalent(self.actor:getTalentFromId(item.talent)) and self.actor.unused_prodigies > 0) or config.settings.cheat then
		if not self.levelup_end_prodigies[item.talent] then
			self.levelup_end_prodigies[item.talent] = true
			self.actor.unused_prodigies = math.max(0, self.actor.unused_prodigies - 1)
			if t.is_class_evolution or t.is_race_evolution then
				self.actor:attr("has_evolution", 1)
				self.fake_evol_attr = self.fake_evol_attr + 1
			end
		end
	end
	print("[TOUCH] prodigy", item.talent, self.levelup_end_prodigies[item.talent] and "chosen" or "unchosen", "points", self.actor.unused_prodigies)
	self:refresh(true)
end

function _M:useCurrent()
	if self.cur then self:use(self.cur) end
end

---------------------------------------------------------------------------
-- drawing
---------------------------------------------------------------------------

function _M:innerDisplayBack(x, y, nb_keyframes)
	x, y = x + self.ix, y + self.iy
	if self.portrait then return self:innerDisplayBackPortrait(x, y) end
	quad(x, y, self.content_w, self.ih, {18, 19, 23})
	local dx = x + self.content_w + 12
	quad(dx, y, self.detail_w, self.ih, PANE)
	local e = self.cur
	local points = self.actor.unused_prodigies or 0
	local pd = text((_t"Points left: %d"):format(points), 15, points > 0 and 240 or 142, points > 0 and 212 or 136, points > 0 and 138 or 120, true)
	if not e then
		draw(text(_t"Prodigies", 22, 240, 212, 138, true), dx + 12, y + 16)
		draw(pd, dx + 12, y + 52)
		return
	end
	local sz = 64
	quad(dx + 12, y + 12, sz + 8, sz + 8, {14, 15, 18})
	self:drawIcon(e.entity, dx + 16, y + 16, sz, e.kind)
	local tx = dx + 12 + sz + 20
	local maxw = self.detail_w - (tx - dx) - 12
	draw(text(e.cname, 22, 240, 212, 138, true, maxw), tx, y + 16)
	local sc = {142, 136, 120}
	if e.kind == "ok" then sc = {123, 211, 137}
	elseif e.kind == "known" or e.kind == "pending" then sc = {240, 212, 138}
	elseif e.kind == "locked" then sc = {224, 122, 106} end
	for li, l in ipairs(K.wrap(e.status, font(15), maxw, 2)) do draw(text(l, 15, sc[1], sc[2], sc[3], false, maxw), tx, y + 46 + (li - 1) * 20) end
	draw(pd, tx, y + 92)
end

-- portrait: cards on top, the selected prodigy's header at the top of the
-- bottom sheet (description and Learn are uis placed in the sheet)
function _M:innerDisplayBackPortrait(x, y)
	quad(x, y, self.iw, self.sheet_y - 8, {18, 19, 23})
	local sy = y + self.sheet_y
	quad(x, sy, self.iw, self.sheet_h, PANE)
	quad(x, sy, self.iw, 2, {60, 63, 72})
	local e = self.cur
	local points = self.actor.unused_prodigies or 0
	local pd = text((_t"Points left: %d"):format(points), 15, points > 0 and 240 or 142, points > 0 and 212 or 136, points > 0 and 138 or 120, true)
	if not e then
		draw(text(_t"Prodigies", 22, 240, 212, 138, true), x + 12, sy + 16)
		draw(pd, x + 12, sy + 52)
		return
	end
	local sz = 64
	quad(x + 12, sy + 12, sz + 8, sz + 8, {14, 15, 18})
	self:drawIcon(e.entity, x + 16, sy + 16, sz, e.kind)
	local tx = x + 12 + sz + 20
	local maxw = self.iw - (tx - x) - 12
	draw(text(e.cname, 22, 240, 212, 138, true, maxw), tx, sy + 16)
	local sc = {142, 136, 120}
	if e.kind == "ok" then sc = {123, 211, 137}
	elseif e.kind == "known" or e.kind == "pending" then sc = {240, 212, 138}
	elseif e.kind == "locked" then sc = {224, 122, 106} end
	for li, l in ipairs(K.wrap(e.status, font(15), maxw, 2)) do draw(text(l, 15, sc[1], sc[2], sc[3], false, maxw), tx, sy + 46 + (li - 1) * 20) end
	draw(pd, tx, sy + 92)
end

-- a rotation: the game swaps this dialog for a fresh one laid out for the
-- new orientation, keeping the prodigy being read (the old dialog's unload
-- has already given back its evolution attribute; init takes it again)
function _M:touch_reopen()
	local d = _M.new(unpack(self.touch_args))
	local tid = self.cur and self.cur.talent
	if tid then
		for _, g in ipairs(d.groups or {}) do for _, e in ipairs(g.items) do if e.talent == tid then d:select(e) end end end
	end
	return d
end
