-- ToME iOS port: the journal as one mobile-native screen.
-- Three tabs (Quests, Lore, Achievements) over the data the stock ShowQuests /
-- ShowLore / ShowAchievements dialogs read; cards on the left, the full text on
-- the right, everything drag-scrollable.

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local Tabs = require "engine.ui.Tabs"
local TextzoneList = require "engine.ui.TextzoneList"
local Tiles = require "engine.Tiles"
local Image = require "engine.ui.Image"
local Quest = require "engine.Quest"
local K = require "engine.ui.TouchKit"

module(..., package.seeall, class.inherit(Dialog))

local TABS = {
	{title=_t"Quests", kind="quests"},
	{title=_t"Lore", kind="lore"},
	{title=_t"Achievements", kind="achievements"},
}

--- @param start_tab "quests" | "lore" | "achievements"
--- @param select_id optional quest id to open (what QuestPopup passes)
function _M:init(start_tab, select_id)
	self.player = game.player
	self.party = game.party
	self.actor = (game.party and game.party.findMember and game.party:findMember{main=true}) or game.player
	self.kind = start_tab or "quests"
	self.filters = {quests="active", achievements="earned"}
	self.select_quest = select_id
	self.tiles = Tiles.new(16, 16, nil, nil, true)
	self.icon_cache = {}

	Dialog.init(self, _t"Journal", game.w * 0.96, game.h * 0.96)

	self.c_tabs = Tabs.new{width=self.iw, tabs=TABS, on_change=function(kind) self:switchTab(kind) end}
	local top = self.c_tabs.h + 10
	local list_h = self.ih - top
	self.list_w = math.floor(self.iw * 0.55)
	self.gap = 16
	self.detail_w = self.iw - self.list_w - self.gap
	self.hero_h = 132
	self.c_flow = K.Flow.new{width=self.list_w, height=list_h}
	local desc_h = list_h - self.hero_h - 8
	self.c_desc = TextzoneList.new{focus_check=true, scrollbar=true, width=self.detail_w - 16, height=desc_h, dest_area={h=desc_h}}

	self:loadUI{
		{left=0, top=0, ui=self.c_tabs},
		{left=0, top=top, ui=self.c_flow},
		{left=self.list_w + self.gap + 8, top=top + self.hero_h, ui=self.c_desc},
	}
	self:setupUI()
	self:setFocus(self.c_flow)
	self.built = true
	if self.c_tabs.select then self.c_tabs:select(self.kind) end
	self:switchTab(self.kind)

	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end }
end

function _M:switchTab(kind)
	if not self.built then return end -- Tabs:generate selects during construction
	self.kind = kind
	self.cur = nil
	self.c_flow.scrollbar.pos = 0
	self:refresh()
end

-- filter chips as a row of centred cards at the top of the flow
function _M:chipSection(chips, cur, on_pick)
	local items = {}
	for _, c in ipairs(chips) do
		items[#items+1] = {name=c.title, sel=cur == c.kind, on_tap=function() on_pick(c.kind) end}
	end
	return {items=items, cols=#chips, row_h=48, center=true}
end

function _M:refresh()
	local secs = {}
	if self.kind == "quests" then secs = self:questSections()
	elseif self.kind == "lore" then secs = self:loreSections()
	else secs = self:achievementSections() end
	self.c_flow:setSections(secs)
	self:showDetail()
end

------------------------------------------------------------------------
-- Quests
------------------------------------------------------------------------
local STATUS_COLOR = {
	[Quest.PENDING] = {240, 212, 138},
	[Quest.COMPLETED] = {123, 211, 137},
	[Quest.DONE] = {123, 211, 137},
	[Quest.FAILED] = {224, 122, 106},
}

function _M:questList()
	local list = {}
	for id, q in pairs(self.actor.quests or {}) do
		list[#list+1] = {name=q.name, quest=q, status=q.status_text[q.status], status_order=q.status, desc=q:desc(self.actor)}
	end
	if game.turn then table.sort(list, function(a, b) return (a.quest.gained_turn or 0) < (b.quest.gained_turn or 0) end)
	else table.sort(list, function(a, b) return a.quest.name < b.quest.name end) end
	return list
end

function _M:questSections()
	local secs = {}
	local f = self.filters.quests
	secs[#secs+1] = self:chipSection({{title=_t"Active", kind="active"}, {title=_t"Done", kind="done"}}, f, function(k) self.filters.quests = k self.cur = nil self:refresh() end)
	local items = {}
	local list = self:questList()
	local pick
	for _, e in ipairs(list) do
		local active = e.quest:isStatus(Quest.PENDING)
		if (f == "active") == active then
			local it = {name=e.name, sub=(active and K.pitch(e.desc) or e.status), data=e, kind="quest",
				sel=self.cur and self.cur.data == e, on_tap=function(it) self:pick(it) end}
			items[#items+1] = it
			if self.select_quest and e.quest.id == self.select_quest then pick = it end
		end
	end
	if #items == 0 then items[1] = {name=(f == "active") and _t"No active quests" or _t"Nothing finished yet", sub=_t"Talk to people and explore."} end
	secs[#secs+1] = {title=(f == "active") and _t"In progress" or _t"Finished", items=items, cols=1, row_h=84}
	if pick then self.select_quest = nil self.cur = pick pick.sel = true
	elseif self.select_quest then
		-- the wanted quest sits under the other chip
		local other = (f == "active") and "done" or "active"
		for _, e in ipairs(list) do if e.quest.id == self.select_quest then self.filters.quests = other return self:questSections() end end
		self.select_quest = nil
	end
	return secs
end

------------------------------------------------------------------------
-- Lore
------------------------------------------------------------------------
function _M:loreSections()
	local secs = {}
	local src = self.party or self.player
	local cats, bycat = {}, {}
	local nb = 0
	for id, _ in pairs(src.lore_known or {}) do
		local l = src:getLore(id, true)
		if l then
			local cat = _t(l.category or "misc", "newLore category")
			if not bycat[cat] then bycat[cat] = {} cats[#cats+1] = cat end
			table.insert(bycat[cat], {name=l.name, desc=util.getval(l.lore), cat=cat, order=l.order or 0, image=l.image, lore=l})
			nb = nb + 1
		end
	end
	table.sort(cats)
	for _, cat in ipairs(cats) do
		local list = bycat[cat]
		table.sort(list, function(a, b) return a.order < b.order end)
		local items = {}
		for _, e in ipairs(list) do
			items[#items+1] = {name=e.name, sub=e.order and e.order > 0 and ("#%d"):format(e.order) or nil, data=e, kind="lore",
				sel=self.cur and self.cur.data == e, on_tap=function(it) self:pick(it) end}
		end
		secs[#secs+1] = {title=("%s (%d)"):format(cat, #items), items=items, min_w=200, row_h=(#items > 0) and 64 or 64}
	end
	if nb == 0 then
		secs[#secs+1] = {title=_t"Lore", items={{name=_t"Nothing found yet", sub=_t"Notes and books you pick up show up here."}}, cols=1, row_h=84}
	end
	return secs
end

------------------------------------------------------------------------
-- Achievements
------------------------------------------------------------------------
function _M:achievementIcon(a)
	local img = a.image or "trophy_gold.png"
	local tex = self.icon_cache[img]
	if tex == nil then
		local ok, image = pcall(self.tiles.loadImage, self.tiles, img)
		if ok and image then tex = {image:glTexture()} else tex = false end
		self.icon_cache[img] = tex
	end
	return tex or nil
end

function _M:achievementVisible(a)
	-- the stock "main"/"all" rule: difficulty-specific duplicates only for the current difficulty
	if a.no_difficulty_duplicate then return true end
	if not (a.difficulty or a.permadeath) then return true end
	return (not a.difficulty or a.difficulty == game.difficulty) and (not a.permadeath or a.permadeath == game.permadeath)
end

function _M:achievementSections()
	local secs = {}
	local f = self.filters.achievements
	secs[#secs+1] = self:chipSection({{title=_t"Earned", kind="earned"}, {title=_t"Locked", kind="locked"}}, f, function(k) self.filters.achievements = k self.cur = nil self:refresh() end)
	local list = {}
	for _, a in ipairs(world.achiev_defs) do
		if self:achievementVisible(a) then
			local data = world.achieved[a.id]
			local earned = data ~= nil
			if (f == "earned") == earned then
				local name, desc = a.name, a.desc
				if not earned then
					if a.show == "none" then name, desc = "???", _t"-- Unknown --"
					elseif a.show == "name" then desc = _t"-- Unknown --"
					elseif a.show ~= "full" and not a.show then name = nil end -- hidden until earned
				end
				if name then
					list[#list+1] = {name=name, desc=desc, category=a.category or "--", when=data and data.when or "--", who=data and data.who or "--", a=a, id=a.id, earned=earned}
				end
			end
		end
	end
	table.sort(list, function(a, b) if a.category ~= b.category then return a.category < b.category end return a.name < b.name end)
	local items = {}
	for _, e in ipairs(list) do
		local a = e.a
		items[#items+1] = {name=e.name, sub=e.earned and e.when or e.category, data=e, kind="achievement",
			icon=function(x, y, size) local tex = self:achievementIcon(a) if tex then tex[1]:toScreenFull(x, y, size, size, tex[2], tex[3]) end end,
			sel=self.cur and self.cur.data == e, on_tap=function(it) self:pick(it) end}
	end
	if #items == 0 then items[1] = {name=(f == "earned") and _t"None yet" or _t"Everything is earned", sub=_t"Keep playing."} end
	secs[#secs+1] = {title=(f == "earned") and (("%d earned"):format(#list)) or (("%d to go"):format(#list)), items=items, min_w=260, row_h=72, icon_size=44}
	return secs
end

function _M:getTrack(a)
	if not a.track then return nil end
	local src = self.player
	local id = a.id
	local data = nil
	if a.mode == "world" then
		world.achievement_data = world.achievement_data or {}
		world.achievement_data[id] = world.achievement_data[id] or {}
		data = world.achievement_data[id]
	elseif a.mode == "game" then
		game.achievement_data = game.achievement_data or {}
		game.achievement_data[id] = game.achievement_data[id] or {}
		data = game.achievement_data[id]
	elseif a.mode == "player" then
		src.achievement_data = src.achievement_data or {}
		src.achievement_data[id] = src.achievement_data[id] or {}
		data = src.achievement_data[id]
	end
	local ok, track = pcall(a.track, data, src)
	if ok then return track end
	return nil
end

------------------------------------------------------------------------
-- Detail pane
------------------------------------------------------------------------
function _M:pick(it)
	self.cur = it
	-- keep the gold frame on the tapped card without rebuilding the lists
	for _, sec in ipairs(self.c_flow.sections) do
		for _, o in ipairs(sec.items) do if o.data then o.sel = (o == it) end end
	end
	self:showDetail()
end

function _M:showDetail()
	local it = self.cur
	self.image = nil
	if not it then
		local hint = self.kind == "quests" and _t"Tap a quest to read its log." or (self.kind == "lore" and _t"Tap an entry to read it." or _t"Tap an achievement for its details.")
		self.c_desc:switchItem("hint" .. self.kind, hint)
		return
	end
	local e = it.data
	if it.kind == "quest" then
		self.c_desc:switchItem(e, e.desc or "")
	elseif it.kind == "lore" then
		self.c_desc:switchItem(e, e.desc or "")
		if e.image then
			if type(e.image) == "string" then
				local ok, img = pcall(Image.new, {file="lore/" .. e.image, auto_width=true, auto_height=true})
				if ok and img and img.w and img.w > 0 then
					local r = img.w / img.h
					img.w = math.min(self.detail_w - 32, img.w)
					img.h = img.w / r
					if img.h > 200 then img.h = 200 img.w = img.h * r end
					e.image = img
				else e.image = nil end
			end
			self.image = e.image
		end
	else
		local a = e.a
		local also = ""
		if self.player and self.player.achievements and self.player.achievements[e.id] then also = _t"#GOLD#Also earned by this character#LAST#\n" end
		local desc = (e.earned and ("#GOLD#Earned:#LAST# %s\n#GOLD#By:#LAST# %s\n%s\n"):tformat(e.when, e.who, also) or ""):toTString()
		desc:add({"color", "GOLD"}, _t"Description: ", {"color", "LAST"}, tostring(e.desc or ""), true)
		local track = self:getTrack(a)
		if track then desc:add(true, {"color", "GOLD"}, _t"Progress: ", {"color", "LAST"}) desc:merge(track) end
		self.c_desc:switchItem(e, desc)
	end
end

function _M:innerDisplayBack(x, y, nb_keyframes)
	x, y = x + self.ix, y + self.iy
	local top = self.c_tabs.h + 10
	local dx, dy = x + self.list_w + self.gap, y + top
	K.quad(x, dy, self.list_w, self.ih - top, {18, 19, 23})
	K.quad(dx, dy, self.detail_w, self.ih - top, K.PANE)
	local it = self.cur
	local tx = dx + 12
	local title, meta, meta_color
	if it then
		local e = it.data
		if it.kind == "achievement" then
			local tex = self:achievementIcon(e.a)
			if tex then
				K.quad(dx + 12, dy + 12, 104, 104, {14, 15, 18})
				tex[1]:toScreenFull(dx + 16, dy + 16, 96, 96, tex[2], tex[3])
				tx = dx + 12 + 104 + 16
			end
			title = it.name
			meta = e.earned and (_t"Earned " .. tostring(e.when) .. (e.who and e.who ~= "--" and (" · " .. tostring(e.who)) or "")) or (_t"Locked · " .. tostring(e.category))
			meta_color = e.earned and {123, 211, 137} or {142, 136, 120}
		elseif it.kind == "lore" then
			title = e.name
			meta = tostring(e.cat) .. (e.order and e.order > 0 and (" · #" .. e.order) or "")
		else
			title = e.name
			meta = tostring(e.status or "")
			meta_color = STATUS_COLOR[e.quest and e.quest.status] or {142, 136, 120}
		end
	else
		title = TABS[1].title
		for _, t in ipairs(TABS) do if t.kind == self.kind then title = t.title end end
		meta = self.kind == "quests" and _t"Your log" or (self.kind == "lore" and _t"What you have read" or _t"What you have done")
	end
	local maxw = dx + self.detail_w - 12 - tx
	local lines = K.wrap(title, K.font(22), maxw, 2)
	local ty = dy + 18
	for _, l in ipairs(lines) do K.draw(K.text(l, 22, 240, 212, 138, true, maxw), tx, ty) ty = ty + 28 end
	if meta and meta ~= "" then
		local c = meta_color or {142, 136, 120}
		for _, l in ipairs(K.wrap((meta:gsub("#[^#]*#", "")), K.font(13), maxw, 2)) do K.draw(K.text(l, 13, c[1], c[2], c[3], false, maxw), tx, ty) ty = ty + 18 end
	end
	-- lore illustration under the text pane, scaled to the pane
	if self.image and self.image.w then
		local ih = math.min(self.image.h, 200)
		local iw = self.image.w
		local ix, iy = dx + self.detail_w - iw - 12, y + self.ih - ih - 8
		pcall(self.image.display, self.image, ix, iy)
	end
end
