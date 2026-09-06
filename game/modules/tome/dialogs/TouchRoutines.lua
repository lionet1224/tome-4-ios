-- ToME iOS port: mobile-native editor for the Act button's routines.
-- Routines on the left, the selected routine's steps as icon cards in the
-- middle, the selected step's controls on the right. The data model is the
-- one mod.class.Player uses (act_routines / act_active / step tables);
-- this file only changes how it is edited.

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local Button = require "engine.ui.Button"
local TextzoneList = require "engine.ui.TextzoneList"
local GetText = require "engine.dialogs.GetText"
local K = require "engine.ui.TouchKit"

module(..., package.seeall, class.inherit(Dialog))

local GOLD, CARD, PANE = K.GOLD, K.CARD, K.PANE
local font, text, draw, quad, frame, wrap = K.font, K.text, K.draw, K.quad, K.frame, K.wrap
local Flow = K.Flow

local BUILTINS = {
	{kind="bump", glyph="BUMP", desc=_t"Attack the target with your weapons by moving into it. Skipped when nothing is adjacent unless you tell it to step in."},
	{kind="approach", glyph="MOVE", desc=_t"Take one step toward the target. Useful after a ranged step so the routine closes the distance."},
	{kind="back", glyph="BACK", desc=_t"Take one step away from the enemies around you. Archers and casters put this after their attack."},
	{kind="wait", glyph="WAIT", desc=_t"Pass one turn. Lets cooldowns tick or enemies come to you."},
}
local UNUSABLE = {{"skip", _t"Skip"}, {"wait", _t"Wait"}, {"approach", _t"Step in"}}
local UNUSABLE_NAMES = {skip=_t"skip it", wait=_t"wait a turn", approach=_t"step in"}

function _M:init(actor)
	self.actor = actor
	actor:actRoutines()
	self.edit_idx = actor.act_active or 1
	self.mode = "steps"
	self.bigfont = font(22)
	Dialog.init(self, _t"Act routines", game.w * 0.98, game.h * 0.98)

	local gap = 12
	local bh = 52
	-- portrait (phone held upright): routine chips and their buttons on top,
	-- the steps full width, the step controls in a bottom sheet
	self.portrait = require("engine.TouchInput").portrait()
	if self.portrait then
		self.rail_w, self.detail_w, self.content_w = self.iw, self.iw, self.iw
		self.rail_h = 140                       -- chips (rows of three, scrolls past two rows)
		self.top_h = self.rail_h + 8 + bh + 8 + bh + 8
		self.sheet_h = 80 + 150 + 3 * (bh + 8) + 8
		self.sheet_y = self.ih - self.sheet_h
		self.c_rail = Flow.new{width=self.iw, height=self.rail_h}
		-- Button adds 16 px of frame to the requested width
		local half = math.floor((self.iw - 6) / 2) - 16
		local third = math.floor((half + 16 - 12) / 3) - 16
		self.b_cool = Button.new{text=_t"Cooldowns: skip", width=half, font=font(17), fct=function() local r = self:routine() if r then r.skip_cooldown = (r.skip_cooldown == false) and true or false self.actor.changed = true self:refresh(true) end end}
		self.b_use = Button.new{text=_t"Use this routine", width=self.iw - 16, font=self.bigfont, fct=function() self:useRoutine() end}
		self.b_rename = Button.new{text=_t"Rename", width=third, font=font(17), fct=function() self:renameRoutine() end}
		self.b_copy = Button.new{text=_t"Copy", width=third, font=font(17), fct=function() self:copyRoutine() end}
		self.b_delete = Button.new{text=_t"Delete", width=third, font=font(17), fct=function() self:deleteRoutine() end}
		local flow_h = self.sheet_y - self.top_h - bh - 16
		self.c_flow = Flow.new{width=self.iw, height=flow_h}
		self.b_add = Button.new{text=_t"Add step", width=self.iw - 16, font=self.bigfont, fct=function() self:openPicker() end}
		self.b_cancel = Button.new{text=_t"Cancel", width=self.iw - 16, font=self.bigfont, fct=function() self:closePicker() end}
		self.desc_y = self.sheet_y + 80
		local desc_h = 150
		self.c_desc = TextzoneList.new{focus_check=true, scrollbar=true, width=self.iw - 16, height=desc_h, dest_area={h=desc_h}}
		self.b_target = Button.new{text=_t"Target", width=self.iw - 16, font=font(19), fct=function() self:pickTarget() end}
		local seg = math.floor((self.iw - 12) / 3) - 16
		self.b_unusable = {}
		for i, u in ipairs(UNUSABLE) do
			local key = u[1]
			self.b_unusable[i] = Button.new{text=u[2], width=seg, font=font(17), fct=function() self:setUnusable(key) end}
		end
		self.b_up = Button.new{text=_t"Up", width=seg, font=font(17), fct=function() self:moveStep(-1) end}
		self.b_down = Button.new{text=_t"Down", width=seg, font=font(17), fct=function() self:moveStep(1) end}
		self.b_remove = Button.new{text=_t"Remove", width=seg, font=font(17), fct=function() self:removeStep() end}
		local row2 = self.rail_h + 8 + bh + 8
		self:loadUI{
			{left=0, top=0, ui=self.c_rail},
			{left=0, top=self.rail_h + 8, ui=self.b_use},
			{left=0, top=row2, ui=self.b_cool},
			{left=half + 6, top=row2, ui=self.b_rename},
			{left=half + 6 + third + 6, top=row2, ui=self.b_copy},
			{left=half + 6 + 2 * (third + 6), top=row2, ui=self.b_delete},
			{left=0, top=self.top_h, ui=self.c_flow},
			{left=0, top=self.top_h + flow_h + 8, ui=self.b_add},
			{left=0, top=self.top_h + flow_h + 8, ui=self.b_cancel},
			{left=8, top=self.desc_y, ui=self.c_desc},
			{left=0, bottom=(bh + 8) * 2, ui=self.b_target},
			{left=0, bottom=bh + 8, ui=self.b_unusable[1]},
			{left=seg + 6, bottom=bh + 8, ui=self.b_unusable[2]},
			{left=2 * (seg + 6), bottom=bh + 8, ui=self.b_unusable[3]},
			{left=0, bottom=0, ui=self.b_up},
			{left=seg + 6, bottom=0, ui=self.b_down},
			{left=2 * (seg + 6), bottom=0, ui=self.b_remove},
		}
		self:setupUI()
	else
	self.rail_w, self.detail_w = 250, 380
	self.content_w = self.iw - self.rail_w - self.detail_w - 2 * gap
	-- rail: routine cards over four buttons
	self.c_rail = Flow.new{width=self.rail_w, height=self.ih - bh * 3 - 24}
	self.b_cool = Button.new{text=_t"Cooldowns: skip", width=self.rail_w, font=font(17), fct=function() local r = self:routine() if r then r.skip_cooldown = (r.skip_cooldown == false) and true or false self.actor.changed = true self:refresh(true) end end}
	local third = math.floor((self.rail_w - 12) / 3)
	self.b_use = Button.new{text=_t"Use this routine", width=self.rail_w, font=self.bigfont, fct=function() self:useRoutine() end}
	self.b_rename = Button.new{text=_t"Rename", width=third, font=font(17), fct=function() self:renameRoutine() end}
	self.b_copy = Button.new{text=_t"Copy", width=third, font=font(17), fct=function() self:copyRoutine() end}
	self.b_delete = Button.new{text=_t"Delete", width=third, font=font(17), fct=function() self:deleteRoutine() end}
	-- centre: steps (or the picker) over Add step
	self.c_flow = Flow.new{width=self.content_w, height=self.ih - bh - 8}
	self.b_add = Button.new{text=_t"Add step", width=self.content_w, font=self.bigfont, fct=function() self:openPicker() end}
	self.b_cancel = Button.new{text=_t"Cancel", width=self.content_w, font=self.bigfont, fct=function() self:closePicker() end}
	-- detail: description over the step controls
	self.desc_y = 96
	local rows = bh * 3 + 24
	local desc_h = self.ih - self.desc_y - rows - 8
	self.c_desc = TextzoneList.new{focus_check=true, scrollbar=true, width=self.detail_w - 16, height=desc_h, dest_area={h=desc_h}}
	self.b_target = Button.new{text=_t"Target", width=self.detail_w, font=font(19), fct=function() self:pickTarget() end}
	local seg = math.floor((self.detail_w - 12) / 3)
	self.b_unusable = {}
	for i, u in ipairs(UNUSABLE) do
		local key = u[1]
		self.b_unusable[i] = Button.new{text=u[2], width=seg, font=font(17), fct=function() self:setUnusable(key) end}
	end
	self.b_up = Button.new{text=_t"Up", width=seg, font=font(17), fct=function() self:moveStep(-1) end}
	self.b_down = Button.new{text=_t"Down", width=seg, font=font(17), fct=function() self:moveStep(1) end}
	self.b_remove = Button.new{text=_t"Remove", width=seg, font=font(17), fct=function() self:removeStep() end}

	local cx = self.rail_w + gap
	local dx = cx + self.content_w + gap
	self:loadUI{
		{left=0, top=0, ui=self.c_rail},
		{left=0, bottom=bh + 8, ui=self.b_use},
		{left=0, bottom=2 * (bh + 8), ui=self.b_cool},
		{left=0, bottom=0, ui=self.b_rename},
		{left=third + 6, bottom=0, ui=self.b_copy},
		{left=2 * (third + 6), bottom=0, ui=self.b_delete},
		{left=cx, top=0, ui=self.c_flow},
		{left=cx, bottom=0, ui=self.b_add},
		{left=cx, bottom=0, ui=self.b_cancel},
		{left=dx + 8, top=self.desc_y, ui=self.c_desc},
		{left=dx, bottom=(bh + 8) * 2, ui=self.b_target},
		{left=dx, bottom=bh + 8, ui=self.b_unusable[1]},
		{left=dx + seg + 6, bottom=bh + 8, ui=self.b_unusable[2]},
		{left=dx + 2 * (seg + 6), bottom=bh + 8, ui=self.b_unusable[3]},
		{left=dx, bottom=0, ui=self.b_up},
		{left=dx + seg + 6, bottom=0, ui=self.b_down},
		{left=dx + 2 * (seg + 6), bottom=0, ui=self.b_remove},
	}
	self:setupUI()
	end
	self.parkable = {self.b_add, self.b_cancel, self.b_target, self.b_unusable[1], self.b_unusable[2], self.b_unusable[3], self.b_up, self.b_down, self.b_remove}
	for _, b in ipairs(self.parkable) do
		local u = self.ui_by_ui[b]
		u.home_x, u.home_y = u.x, u.y
	end
	self:setFocus(self.c_flow)
	self.built = true
	self:showDetail()
	self:refresh()
	self.key:addBinds{ EXIT = function()
		if self.mode == "picker" then self:closePicker() else self:close() end
	end }
end

-- hidden uis still receive taps: park unused buttons off-screen instead
function _M:place(ui, show)
	local u = self.ui_by_ui[ui]
	if not u then return end
	if show then u.x, u.y = u.home_x, u.home_y else u.x, u.y = -9999, -9999 end
end

function _M:close()
	self.actor.act_preview_key = nil
	self.actor.changed = true
	game:unregisterDialog(self)
end

---------------------------------------------------------------------------
-- data helpers
---------------------------------------------------------------------------

function _M:routine()
	local rs = self.actor.act_routines
	self.edit_idx = util.bound(self.edit_idx or 1, 1, #rs)
	return rs[self.edit_idx]
end

function _M:step()
	local r = self:routine()
	return self.sel_step and r.steps[self.sel_step] or nil
end

-- the targeting rules a step may use (same sets the stock editor cycles through)
function _M:rulesFor(st)
	local P = mod.class.Player
	if not st or st.kind == "wait" then return {} end
	if st.kind == "item" then return {"manual", "self"} end
	if st.kind == "talent" then return P.ACT_TARGETS end
	return {"nearest", "attacker", "weakest", "strongest", "marked"}
end

function _M:targetName(st)
	local P = mod.class.Player
	if not st or st.kind == "wait" then return nil end
	local rule = st.target or "nearest"
	return P.ACT_TARGET_NAMES[rule] or rule
end

function _M:builtin(kind)
	for _, b in ipairs(BUILTINS) do if b.kind == kind then return b end end
end

-- what a step card shows under its name
function _M:stepSub(st)
	local parts = {}
	local tn = self:targetName(st)
	if tn then parts[#parts+1] = (_t"target: %s"):format(tn) end
	if st.kind ~= "wait" then parts[#parts+1] = (_t"if unusable: %s"):format(UNUSABLE_NAMES[st.if_unusable or "skip"] or st.if_unusable) end
	return table.concat(parts, "  ·  ")
end

function _M:stepDesc(st)
	if st.kind == "talent" then
		local t = self.actor:getTalentFromId(st.tid)
		if t then
			local ok, d = pcall(self.actor.getTalentFullDescription, self.actor, t)
			if ok and d then return d end
			return t.name
		end
		return tostring(st.tid)
	elseif st.kind == "item" then
		return (_t"Uses %s from your pack or hotkeys. Items aim with their own targeting."):format(tostring(st.item))
	end
	local b = self:builtin(st.kind)
	return b and b.desc or tostring(st.kind)
end

---------------------------------------------------------------------------
-- drawing helpers
---------------------------------------------------------------------------

-- talent / item icon, or a glyph box for the built-in actions
function _M:drawStepIcon(st, x, y, size)
	local e = self.actor:actStepEntity(st)
	if e then
		if st.kind == "talent" then
			local tiles = game.uiset and game.uiset.hotkeys_display_icons and game.uiset.hotkeys_display_icons.tiles
			pcall(e.toScreen, e, tiles, x, y, size, size)
		else
			pcall(e.toScreen, e, nil, x, y, size, size)
		end
		return
	end
	local b = self:builtin(st.kind)
	quad(x, y, size, size, {36, 39, 47})
	frame(x, y, size, size, {60, 63, 72}, 1)
	local d = text(b and b.glyph or "?", 12, 240, 212, 138, true)
	if d then draw(d, x + (size - d.w) / 2, y + (size - d.h) / 2) end
end

---------------------------------------------------------------------------
-- lists
---------------------------------------------------------------------------

function _M:refresh(keep_scroll)
	if not self.built then return end
	local a = self.actor
	do -- routine-level option: skip talents on cooldown without spending a turn (default on)
		local r = self:routine()
		local nt = (r and r.skip_cooldown == false) and _t"Cooldowns: follow step rule" or _t"Cooldowns: skip"
		if self.b_cool.text ~= nt then self.b_cool.text = nt self.b_cool:generate() end
	end
	-- rail
	local items = {}
	for i, r in ipairs(a.act_routines) do
		local active = i == a.act_active
		items[#items+1] = {name=r.name, sub=(#r.steps == 1 and _t"1 step" or (_t"%d steps"):format(#r.steps)) .. (active and _t"  ·  in use" or ""), sel=i == self.edit_idx, data=r,
			on_tap=function() self.edit_idx = i self.sel_step = nil self.mode = "steps" self:refresh() end}
	end
	items[#items+1] = {name=_t"New routine", sub=_t"Start empty", on_tap=function() self:newRoutine() end}
	if self.portrait then
		-- chips in rows of three across the top (the Flow scrolls past two rows)
		self.c_rail:setSections{{items=items, cols=math.min(3, #items), row_h=56, center=true}}
	else
		self.c_rail:setSections{{title=_t"Routines", items=items, cols=1, row_h=64}}
	end

	-- centre
	if self.mode == "picker" then
		self:buildPicker()
	else
		local r = self:routine()
		local steps = {}
		for i, st in ipairs(r.steps) do
			local step = st
			steps[#steps+1] = {name=("%d.  %s"):format(i, a:actStepName(st)), sub=self:stepSub(st), sel=i == self.sel_step, data=st,
				icon=function(x, y, size) self:drawStepIcon(step, x, y, size) end,
				on_tap=function() self.sel_step = i self:showDetail() self:refresh(true) end}
		end
		if #steps == 0 then steps[1] = {name=_t"No steps yet", sub=_t"Tap Add step to build the routine"} end
		local pos = keep_scroll and self.c_flow.scrollbar.pos or 0
		self.c_flow:setSections{{title=r.name, items=steps, cols=1, row_h=74, icon_size=48}}
		self.c_flow.scrollbar.pos = util.minBound(pos, 0, self.c_flow.scrollbar.max)
	end

	-- buttons: Add vs Cancel, and the step controls only with a step selected
	local st = self:step()
	self:place(self.b_add, self.mode ~= "picker")
	self:place(self.b_cancel, self.mode == "picker")
	local show = st ~= nil and self.mode ~= "picker"
	self:place(self.b_target, show and #self:rulesFor(st) > 0)
	for i = 1, 3 do self:place(self.b_unusable[i], show and st.kind ~= "wait") end
	self:place(self.b_up, show) self:place(self.b_down, show) self:place(self.b_remove, show)
	if st then
		local tn = self:targetName(st)
		local label = tn and (_t"Target: %s"):format(tn) or _t"Target"
		if self.b_target.text ~= label then self.b_target.text = label self.b_target:generate() end
	end
	a.act_preview_key = nil
end

function _M:showDetail()
	local st = self:step()
	self.c_desc:erase()
	if not st then
		self.c_desc:switchItem("help", _t"Tap a step to change what it aims at, what happens when it cannot fire, or its order. Tap Add step to append a talent or an action.", true)
		return
	end
	self.c_desc:switchItem(st, self:stepDesc(st), true) -- force: erase() keeps cur_item, so re-selecting the same step went blank
end

---------------------------------------------------------------------------
-- the picker (replaces the step list)
---------------------------------------------------------------------------

function _M:pickerEntries()
	local a = self.actor
	local acts, tal, items = {}, {}, {}
	for _, b in ipairs(BUILTINS) do
		acts[#acts+1] = {name=mod.class.Player.ACT_KIND_NAMES[b.kind] or b.kind, sub=K.pitch(b.desc), step={kind=b.kind, target=(b.kind ~= "wait") and "nearest" or nil, if_unusable="skip"}}
	end
	-- hidden talents still count when they are innate (Shoot) or sit on a hotkey
	local on_hotkey = {}
	for _, hk in pairs(a.hotkey or {}) do if hk[1] == "talent" then on_hotkey[hk[2]] = true end end
	for tid, lvl in pairs(a.talents) do
		local t = a:getTalentFromId(tid)
		if t and t.mode == "activated" and (not t.hide or t.innate or on_hotkey[tid]) then
			local status
			if a:isTalentCoolingDown(t) then status = (_t"cooling down %d"):format(a:isTalentCoolingDown(t)) else status = _t"ready" end
			tal[#tal+1] = {name=t.name, sub=status, t=t, step={kind="talent", tid=tid, target="nearest", if_unusable="approach"}}
		end
	end
	table.sort(tal, function(x, y) return x.name < y.name end)
	local seen = {}
	for i = 1, 12 * (a.nb_hotkey_pages or 7) do
		local hk = a.hotkey[i]
		if hk and hk[1] == "inventory" and not seen[hk[2]] then
			seen[hk[2]] = true
			items[#items+1] = {name=hk[2], sub=_t"item on your hotkeys", step={kind="item", item=hk[2], target="manual", if_unusable="skip"}}
		end
	end
	return acts, tal, items
end

function _M:buildPicker()
	local acts, tal, items = self:pickerEntries()
	local function card(e)
		local st = e.step
		return {name=e.name, sub=e.sub, data=e, icon=function(x, y, size) self:drawStepIcon(st, x, y, size) end, on_tap=function() self:appendStep(st) end}
	end
	local secs = {}
	local l = {} for _, e in ipairs(acts) do l[#l+1] = card(e) end
	secs[#secs+1] = {title=_t"Actions", items=l, min_w=200, row_h=74, icon_size=40}
	l = {} for _, e in ipairs(tal) do l[#l+1] = card(e) end
	if #l > 0 then secs[#secs+1] = {title=_t"Talents", items=l, min_w=200, row_h=74, icon_size=40} end
	l = {} for _, e in ipairs(items) do l[#l+1] = card(e) end
	if #l > 0 then secs[#secs+1] = {title=_t"Items", items=l, min_w=200, row_h=74, icon_size=40} end
	self.c_flow:setSections(secs)
	self.c_flow.scrollbar.pos = 0
end

function _M:openPicker()
	self.mode = "picker"
	self.c_desc:erase()
	self.c_desc:switchItem("picker", _t"Tap an action or a talent to add it after the selected step (or at the end). Talents fire at the step's target; items use their own targeting.")
	self:refresh()
end

function _M:closePicker()
	self.mode = "steps"
	self:showDetail()
	self:refresh()
end

function _M:appendStep(step)
	local r = self:routine()
	local st = table.clone(step)
	local pos = (self.sel_step and self.sel_step < #r.steps) and self.sel_step + 1 or #r.steps + 1
	table.insert(r.steps, pos, st)
	r.pos = 1
	self.sel_step = pos
	self.mode = "steps"
	print("[ACT] touch editor add", tostring(st.kind), tostring(st.tid or st.item or ""), "at", pos)
	self:showDetail()
	self:refresh()
end

---------------------------------------------------------------------------
-- step controls
---------------------------------------------------------------------------

function _M:pickTarget()
	local st = self:step()
	if not st then return end
	local P = mod.class.Player
	local list = {}
	local cur = st.target or "nearest"
	for _, rule in ipairs(self:rulesFor(st)) do
		local n = P.ACT_TARGET_NAMES[rule] or rule
		list[#list+1] = {name=(rule == cur and "#GOLD#" or "") .. n .. (rule == cur and "#LAST#" or ""), rule=rule}
	end
	if #list == 0 then return end
	Dialog:listPopup(_t"Target", _t"What this step aims at.", list, math.floor(game.w * 0.5), math.floor(game.h * 0.8), function(item)
		if not item then return end
		st.target = item.rule
		self:routine().pos = 1
		self:refresh(true)
	end)
end

function _M:setUnusable(key)
	local st = self:step()
	if not st or st.kind == "wait" then return end
	st.if_unusable = key
	self:routine().pos = 1
	self:refresh(true)
end

function _M:removeStep()
	local r = self:routine()
	if self.sel_step and r.steps[self.sel_step] then
		table.remove(r.steps, self.sel_step)
		self.sel_step = math.min(self.sel_step, #r.steps)
		if self.sel_step == 0 then self.sel_step = nil end
		r.pos = 1
		self:showDetail()
		self:refresh(true)
	end
end

function _M:moveStep(dir)
	local r = self:routine()
	local i = self.sel_step
	if not i or not r.steps[i] or not r.steps[i + dir] then return end
	r.steps[i], r.steps[i + dir] = r.steps[i + dir], r.steps[i]
	self.sel_step = i + dir
	r.pos = 1
	self:refresh(true)
end

---------------------------------------------------------------------------
-- routine controls
---------------------------------------------------------------------------

function _M:useRoutine()
	self.actor.act_active = self.edit_idx
	self.actor.act_preview_key = nil
	self:refresh(true)
end

function _M:newRoutine()
	local rs = self.actor.act_routines
	rs[#rs+1] = {name=("Routine %d"):format(#rs + 1), steps={}, pos=1}
	self.edit_idx = #rs
	self.sel_step = nil
	self.mode = "steps"
	self:showDetail()
	self:refresh()
end

function _M:copyRoutine()
	local rs = self.actor.act_routines
	local r = self:routine()
	rs[#rs+1] = {name=r.name .. " 2", steps=table.clone(r.steps, true), pos=1}
	self.edit_idx = #rs
	self.sel_step = nil
	self:showDetail()
	self:refresh()
end

function _M:deleteRoutine()
	local rs = self.actor.act_routines
	if #rs <= 1 then Dialog:simplePopup(_t"Act", _t"Keep at least one routine.") return end
	local r = self:routine()
	Dialog:yesnoPopup(_t"Delete routine", (_t"Delete '%s'?"):format(r.name), function(ret)
		if not ret then return end
		table.remove(rs, self.edit_idx)
		if self.actor.act_active >= self.edit_idx then self.actor.act_active = math.max(1, self.actor.act_active - 1) end
		self.edit_idx = math.max(1, self.edit_idx - 1)
		self.sel_step = nil
		self:showDetail()
		self:refresh()
	end, _t"Delete", _t"Keep")
end

function _M:renameRoutine()
	local r = self:routine()
	game:registerDialog(GetText.new(_t"Routine name", _t"Name", 1, 30, function(txt) r.name = txt self:refresh(true) end, nil, r.name))
end

---------------------------------------------------------------------------
-- panes
---------------------------------------------------------------------------

function _M:innerDisplayBack(x, y, nb_keyframes)
	x, y = x + self.ix, y + self.iy
	if self.portrait then return self:innerDisplayBackPortrait(x, y) end
	quad(x, y, self.rail_w, self.ih, PANE)
	local cx = x + self.rail_w + 12
	quad(cx, y, self.content_w, self.ih, {18, 19, 23})
	local dx = cx + self.content_w + 12
	quad(dx, y, self.detail_w, self.ih, PANE)
	local st = self:step()
	if self.mode == "picker" then
		draw(text(_t"Add a step", 22, 240, 212, 138, true), dx + 12, y + 16)
		draw(text(_t"Tap a card to add it", 13, 142, 136, 120), dx + 12, y + 50)
		return
	end
	if not st then
		draw(text(self:routine().name, 22, 240, 212, 138, true, self.detail_w - 24), dx + 12, y + 16)
		draw(text(_t"Tap a step to edit it", 13, 142, 136, 120), dx + 12, y + 50)
		return
	end
	local sz = 56
	quad(dx + 12, y + 12, sz + 8, sz + 8, {14, 15, 18})
	self:drawStepIcon(st, dx + 16, y + 16, sz)
	local tx = dx + 12 + sz + 20
	local maxw = self.detail_w - (tx - dx) - 12
	draw(text(("%d.  %s"):format(self.sel_step, self.actor:actStepName(st)), 20, 240, 212, 138, true, maxw), tx, y + 16)
	local kind = st.kind == "talent" and _t"talent" or st.kind == "item" and _t"item" or _t"action"
	draw(text(kind, 13, 142, 136, 120, false, maxw), tx, y + 46)
end

-- portrait: top strip (chips + routine buttons), steps in the middle, the
-- step header + controls in a bottom sheet
function _M:innerDisplayBackPortrait(x, y)
	quad(x, y, self.iw, self.top_h - 4, PANE)
	quad(x, y + self.top_h - 4, self.iw, self.sheet_y - self.top_h, {18, 19, 23})
	local sy = y + self.sheet_y
	quad(x, sy, self.iw, self.sheet_h, PANE)
	quad(x, sy, self.iw, 2, {60, 63, 72})
	local st = self:step()
	if self.mode == "picker" then
		draw(text(_t"Add a step", 22, 240, 212, 138, true), x + 12, sy + 16)
		draw(text(_t"Tap a card to add it", 13, 142, 136, 120), x + 12, sy + 50)
		return
	end
	if not st then
		draw(text(self:routine().name, 22, 240, 212, 138, true, self.iw - 24), x + 12, sy + 16)
		draw(text(_t"Tap a step to edit it", 13, 142, 136, 120), x + 12, sy + 50)
		return
	end
	local sz = 56
	quad(x + 12, sy + 12, sz + 8, sz + 8, {14, 15, 18})
	self:drawStepIcon(st, x + 16, sy + 16, sz)
	local tx = x + 12 + sz + 20
	local maxw = self.iw - (tx - x) - 12
	draw(text(("%d.  %s"):format(self.sel_step, self.actor:actStepName(st)), 20, 240, 212, 138, true, maxw), tx, sy + 16)
	local kind = st.kind == "talent" and _t"talent" or st.kind == "item" and _t"item" or _t"action"
	draw(text(kind, 13, 142, 136, 120, false, maxw), tx, sy + 46)
end

-- a rotation: the parent game hook swaps the dialog for a fresh one laid out
-- for the new orientation, keeping the routine and step being edited
function _M:touch_reopen()
	local d = _M.new(self.actor)
	d.edit_idx = util.bound(self.edit_idx or 1, 1, math.max(1, #self.actor.act_routines))
	local r = d:routine()
	d.sel_step = (self.sel_step and r and r.steps[self.sel_step]) and self.sel_step or nil
	d.mode = "steps"
	d:showDetail()
	d:refresh()
	return d
end

function _M:innerDisplay(x, y, nb_keyframes)
	-- gold frame on the current "if unusable" choice
	local st = self:step()
	if not st or self.mode == "picker" or st.kind == "wait" then return end
	local cur = st.if_unusable or "skip"
	for i, u in ipairs(UNUSABLE) do
		if u[1] == cur then
			local b = self.b_unusable[i]
			local e = self.ui_by_ui[b]
			if e then frame(x + e.x - 2, y + e.y - 2, b.w + 4, b.h + 4, GOLD, 2) end
		end
	end
end
