-- ToME iOS port: mobile-native talent browser.
-- Cards per talent group in a drag-scrolling pane, the full description on the
-- right, and a slot picker to put a talent on the hotkey wheel. The rules
-- (what is usable, auto-use, confirmation, hotkey table) are the same ones
-- mod.dialogs.UseTalents applies; only the widgets differ.

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local Button = require "engine.ui.Button"
local TextzoneList = require "engine.ui.TextzoneList"
local K = require "engine.ui.TouchKit"

module(..., package.seeall, class.inherit(Dialog))

local GOLD, CARD, PANE = K.GOLD, K.CARD, K.PANE
local font, text, draw, quad, frame = K.font, K.text, K.draw, K.quad, K.frame
local Flow = K.Flow

_M.SLOTS_PER_PAGE = 12
_M.WHEEL_PAGES = 3

local AUTO_MODES = {
	{mode=1, name=_t"Auto-use when available"},
	{mode=2, name=_t"Auto-use when no enemies are visible"},
	{mode=3, name=_t"Auto-use when enemies are visible"},
	{mode=4, name=_t"Auto-use when enemies are visible and adjacent"},
	{mode=5, name=_t"Auto-use when out of combat"},
}

function _M:init(actor)
	self.actor = actor
	actor.hotkey = actor.hotkey or {}
	self.mode = "browse"
	self.bigfont = font(22)
	Dialog.init(self, ("Talents: %s"):tformat(actor:getName()), game.w * 0.98, game.h * 0.98)

	local gap = 12
	self.detail_w = 400
	self.content_w = self.iw - self.detail_w - gap
	self.c_flow = Flow.new{width=self.content_w, height=self.ih}

	local bh = 56
	self.desc_y = 104
	local desc_h = self.ih - self.desc_y - bh * 2 - 16
	self.c_desc = TextzoneList.new{focus_check=true, scrollbar=true, width=self.detail_w - 16, height=desc_h, dest_area={h=desc_h}}
	local half = math.floor((self.detail_w - 8) / 2)
	self.b_use = Button.new{text=_t"Use", width=self.detail_w, font=self.bigfont, fct=function() self:useCurrent() end}
	self.b_wheel = Button.new{text=_t"Put on bar", width=half, font=self.bigfont, fct=function() self:openSlots() end}
	self.b_auto = Button.new{text=_t"Auto-use", width=half, font=self.bigfont, fct=function() self:autoMenu() end}
	self.b_back = Button.new{text=_t"Back", width=self.detail_w, font=self.bigfont, fct=function() self:closeSlots() end}

	local dx = self.content_w + gap
	self:loadUI{
		{left=0, top=0, ui=self.c_flow},
		{left=dx + 8, top=self.desc_y, ui=self.c_desc},
		{left=dx, bottom=bh + 8, ui=self.b_use},
		{left=dx, bottom=0, ui=self.b_wheel},
		{left=dx + half + 8, bottom=0, ui=self.b_auto},
		{left=dx, bottom=0, ui=self.b_back},
	}
	self:setupUI()
	for _, b in ipairs{self.b_use, self.b_wheel, self.b_auto, self.b_back} do
		local u = self.ui_by_ui[b]
		u.home_x, u.home_y = u.x, u.y
	end
	self:setFocus(self.c_flow)
	self.built = true
	self:refresh()

	-- physical hotkey keys still bind the shown talent (keyboard / desktop emulation)
	engine.interface.PlayerHotkeys:bindAllHotkeys(self.key, function(i) self:assignSlot(i) end)
	self.key:addBinds{
		EXIT = function()
			if self.mode == "slots" then self:closeSlots() else game:unregisterDialog(self) end
		end,
	}
end

-- hidden uis still receive taps: park unused buttons off-screen instead
function _M:place(ui, show)
	local u = self.ui_by_ui[ui]
	if not u then return end
	if show then u.x, u.y = u.home_x, u.home_y else u.x, u.y = -9999, -9999 end
end

---------------------------------------------------------------------------
-- talent list
---------------------------------------------------------------------------

function _M:slotOf(tid)
	for i = 1, _M.SLOTS_PER_PAGE * (self.actor.nb_hotkey_pages or 1) do
		local hk = self.actor.hotkey[i]
		if hk and hk[1] == "talent" and hk[2] == tid then return i end
	end
end

function _M:status(t)
	local who = self.actor
	local s, ok = _t"Ready", true
	if who:isTalentCoolingDown(t) then s, ok = ("Cooling down: %s turns"):tformat(who:isTalentCoolingDown(t)), false
	elseif not who:preUseTalent(t, true, true) then s, ok = _t"Unavailable", false
	elseif t.is_object_use then s = _t"Object power"
	elseif t.mode == "sustained" then s = who:isTalentActive(t.id) and _t"Sustaining" or _t"Sustain"
	elseif t.mode == "passive" then s = _t"Passive" end
	if who:isTalentAuto(t.id) then s = s .. _t" · auto" end
	if who:isTalentConfirmable(t.id) then s = s .. _t" · asks first" end
	return s, ok
end

function _M:generateList()
	local who = self.actor
	local groups = {
		{key="actives", title=_t"Activable talents", items={}},
		{key="objects", title=_t"Object powers", items={}},
		{key="sustains", title=_t"Sustainable talents", items={}},
		{key="sustained", title=_t"Sustained talents", items={}},
		{key="cooldowns", title=_t"Cooling down", items={}},
		{key="unavailables", title=_t"Unavailable", items={}},
		{key="passives", title=_t"Passive talents", items={}},
	}
	local by = {}
	for _, g in ipairs(groups) do by[g.key] = g.items end
	local tiles = game.uiset and game.uiset.hotkeys_display_icons and game.uiset.hotkeys_display_icons.tiles
	for _, t in pairs(who.talents_def) do
		if who:knowTalent(t.id) and not (t.hide and t.mode == "passive") then
			local key = (t.mode == "sustained" and "sustains") or (t.mode == "passive" and "passives") or (t.is_object_use and "objects") or "actives"
			if who:isTalentCoolingDown(t) then key = "cooldowns"
			elseif not who:preUseTalent(t, true, true) then key = "unavailables"
			elseif t.mode == "sustained" and who:isTalentActive(t.id) then key = "sustained" end
			if t.display_entity and tiles then pcall(t.display_entity.getMapObjects, t.display_entity, tiles, {}, 1) end
			local tname = t.is_object_use and tostring(who:getTalentDisplayName(t)) or tostring(t.name)
			local status, ok = self:status(t)
			by[key][#by[key]+1] = {talent=t.id, t=t, cname=tname, status=status, ok=ok, entity=t.display_entity}
		end
	end
	for _, g in ipairs(groups) do table.sort(g.items, function(a, b) return a.cname < b.cname end) end
	self.groups = groups
end

function _M:drawIcon(e, x, y, size, tid, dim)
	local tiles = game.uiset and game.uiset.hotkeys_display_icons and game.uiset.hotkeys_display_icons.tiles
	if e then pcall(e.toScreen, e, tiles, x, y, size, size) end
	if dim then quad(x, y, size, size, {0, 0, 0}, 110) end
	-- wheel badge: the slot number in a small gold tag
	local slot = tid and self:slotOf(tid)
	if slot then
		local d = text(tostring(slot), 11, 27, 21, 16, true)
		if d then
			quad(x + size - d.w - 6, y + size - 16, d.w + 6, 16, GOLD)
			draw(d, x + size - d.w - 3, y + size - 15)
		end
	end
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
					icon=function(x, y, size) self:drawIcon(entry.entity, x, y, size, entry.talent, not entry.ok) end,
					on_tap=function() self:select(entry) end}
			end
			secs[#secs+1] = {title=g.title, items=items, min_w=200, row_h=66, icon_size=44}
		end
	end
	if #secs == 0 then secs[1] = {title=_t"Talents", items={{name=_t"No talents known yet", sub=_t"Level up to learn some."}}, cols=1, row_h=66} end
	self.c_flow:setSections(secs)
	self.c_flow.scrollbar.pos = util.minBound(pos, 0, self.c_flow.scrollbar.max)
	if self.cur then
		-- the entry table was rebuilt: find it again so the status line follows the game
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

function _M:showDetail()
	local e = self.cur
	if not e then
		self.c_desc:switchItem("none", _t"Tap a talent to read about it.")
		self:place(self.b_use, false) self:place(self.b_wheel, false) self:place(self.b_auto, false) self:place(self.b_back, false)
		return
	end
	self.c_desc:switchItem(e.talent .. "|" .. tostring(e.status), self.actor:getTalentFullDescription(e.t))
	local t = e.t
	local passive = t.mode == "passive"
	if self.mode == "slots" then
		self:place(self.b_use, false) self:place(self.b_wheel, false) self:place(self.b_auto, false) self:place(self.b_back, true)
		return
	end
	self:place(self.b_back, false)
	self:place(self.b_use, not passive)
	self:place(self.b_wheel, not passive)
	self:place(self.b_auto, not passive)
	local label = _t"Use"
	if t.mode == "sustained" then label = self.actor:isTalentActive(t.id) and _t"Deactivate" or _t"Activate" end
	if self.b_use.text ~= label then self.b_use.text = label self.b_use:generate() end
	local wl = self:slotOf(t.id) and _t"Move on bar" or _t"Put on bar"
	if self.b_wheel.text ~= wl then self.b_wheel.text = wl self.b_wheel:generate() end
	local al = self.actor:isTalentAuto(t.id) and _t"Auto: on" or _t"Auto-use"
	if self.b_auto.text ~= al then self.b_auto.text = al self.b_auto:generate() end
end

function _M:useCurrent()
	local e = self.cur
	if not e or e.t.mode == "passive" then return end
	game:unregisterDialog(self)
	self.actor:useTalent(e.talent)
end

---------------------------------------------------------------------------
-- auto-use / confirmation (the same options UseTalents offers on right click)
---------------------------------------------------------------------------

function _M:autoMenu()
	local e = self.cur
	if not e or e.t.mode == "passive" then return end
	local t, tid = e.t, e.talent
	local automode = self.actor:isTalentAuto(t)
	local list = {}
	for _, m in ipairs(AUTO_MODES) do
		list[#list+1] = {name=(automode == m.mode and _t"#YELLOW#On: " or "") .. m.name, mode=m.mode}
	end
	if automode then list[#list+1] = {name=_t"Disable auto-use", what="auto-dis"} end
	if self.actor:isTalentConfirmable(t) then list[#list+1] = {name=_t"#YELLOW#Stop asking before use", what="unset-confirm"}
	else list[#list+1] = {name=_t"Ask for confirmation before use", what="set-confirm"} end
	Dialog:listPopup(("%s"):format(tostring(e.cname)), _t"Automatic use", list, 500, 500, function(b)
		if not b then return end
		if b.mode then
			if automode == b.mode then self.actor:checkSetTalentAuto(tid, false)
			else self.actor:checkSetTalentAuto(tid, true, b.mode) end
		elseif b.what == "auto-dis" then self.actor:checkSetTalentAuto(tid, false)
		elseif b.what == "set-confirm" then self.actor:setTalentConfirmable(tid, true)
		elseif b.what == "unset-confirm" then self.actor:setTalentConfirmable(tid, false) end
		self.actor.changed = true
		self:refresh(true)
	end)
end

---------------------------------------------------------------------------
-- wheel slots
---------------------------------------------------------------------------

function _M:slotLabel(i)
	local hk = self.actor.hotkey[i]
	if not hk then return _t"empty", nil, true end
	if hk[1] == "talent" then
		local t = self.actor:getTalentFromId(hk[2])
		return t and tostring(t.name) or tostring(hk[2]), t and t.display_entity or nil, false
	elseif hk[1] == "inventory" then
		return tostring(hk[2]), nil, false
	end
	return tostring(hk[2] or hk[1]), nil, false
end

function _M:openSlots()
	local e = self.cur
	if not e or e.t.mode == "passive" then return end
	-- the shared bar picker (the item sheet uses the same one)
	local Picker = require "mod.dialogs.TouchSlotPicker"
	local mine = self:slotOf(e.talent)
	game:registerDialog(Picker.new(self.actor, ("Put %s on the bar"):tformat(tostring(e.cname)), function(slot) self:assignSlot(slot) end, mine,
		{subject=tostring(e.cname), on_remove=function() self:unassign() end}))
end

function _M:closeSlots()
	self.mode = "browse"
	self:refresh()
	self.c_flow.scrollbar.pos = util.minBound(self.browse_scroll or 0, 0, self.c_flow.scrollbar.max)
end

-- put the shown talent in hotkey slot i (one slot per talent, like UseTalents)
function _M:assignSlot(i)
	local e = self.cur
	if not e or e.t.mode == "passive" then return end
	for k = 1, _M.SLOTS_PER_PAGE * (self.actor.nb_hotkey_pages or 1) do
		local hk = self.actor.hotkey[k]
		if hk and hk[1] == "talent" and hk[2] == e.talent then self.actor.hotkey[k] = nil end
	end
	self.actor.hotkey[i] = {"talent", e.talent}
	self.actor.changed = true
	print("[TOUCH] talent -> bar slot", tostring(e.talent), i)
	if self.mode == "slots" then self:closeSlots() else self:refresh(true) end
end

function _M:unassign()
	local e = self.cur
	if not e then return end
	for k = 1, _M.SLOTS_PER_PAGE * (self.actor.nb_hotkey_pages or 1) do
		local hk = self.actor.hotkey[k]
		if hk and hk[1] == "talent" and hk[2] == e.talent then self.actor.hotkey[k] = nil end
	end
	self.actor.changed = true
	print("[TOUCH] talent off bar", tostring(e.talent))
	if self.mode == "slots" then self:closeSlots() else self:refresh(true) end
end

---------------------------------------------------------------------------
-- drawing
---------------------------------------------------------------------------

function _M:innerDisplayBack(x, y, nb_keyframes)
	x, y = x + self.ix, y + self.iy
	quad(x, y, self.content_w, self.ih, {18, 19, 23})
	local dx = x + self.content_w + 12
	quad(dx, y, self.detail_w, self.ih, PANE)
	local e = self.cur
	if not e then
		draw(text(self.mode == "slots" and _t"Pick a slot" or _t"Talents", 22, 240, 212, 138, true), dx + 12, y + 16)
		return
	end
	local sz = 64
	quad(dx + 12, y + 12, sz + 8, sz + 8, {14, 15, 18})
	self:drawIcon(e.entity, dx + 16, y + 16, sz, e.talent, not e.ok)
	local tx = dx + 12 + sz + 20
	local maxw = self.detail_w - (tx - dx) - 12
	draw(text(e.cname, 22, 240, 212, 138, true, maxw), tx, y + 16)
	local sc = e.ok and {123, 211, 137} or {224, 122, 106}
	draw(text(e.status, 13, sc[1], sc[2], sc[3], false, maxw), tx, y + 48)
	if self.mode == "slots" then
		draw(text(_t"Tap a slot: this is the order of the skill drawer", 13, 142, 136, 120, false, maxw), tx, y + 68)
	else
		local slot = self:slotOf(e.talent)
		draw(text(slot and ("On the wheel: slot %d, page %d"):tformat(slot, math.floor((slot - 1) / _M.SLOTS_PER_PAGE) + 1) or _t"Not on the bar", 13, 142, 136, 120, false, maxw), tx, y + 68)
	end
end
