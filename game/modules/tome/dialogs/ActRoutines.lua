-- ToME - Tales of Maj'Eyal
-- iOS port: editor for the Act button's routines.

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local List = require "engine.ui.List"
local Button = require "engine.ui.Button"
local Textzone = require "engine.ui.Textzone"
local GetText = require "engine.dialogs.GetText"

module(..., package.seeall, class.inherit(Dialog))

function _M:init(actor)
	self.actor = actor
	actor:actRoutines()
	Dialog.init(self, _t"Act routines", game.w * 0.9, game.h * 0.9)
	self.lw = math.floor(self.iw * 0.3)
	self.rw = self.iw - self.lw - 20
	self:build()
	self:loadUI(self.uis_def)
	self:setupUI()
	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end }
end

local function btn(text, fct) return Button.new{text=text, fct=fct} end

function _M:routineList()
	local list = {}
	for i, r in ipairs(self.actor.act_routines) do
		list[#list+1] = {name=(i == self.actor.act_active and "#GOLD#> " or "")..r.name..(i == self.actor.act_active and "#LAST#" or ""), idx=i}
	end
	return list
end

function _M:stepList()
	local r = self.actor:actRoutine()
	local list = {}
	local P = mod.class.Player
	for i, st in ipairs(r.steps) do
		local tgt = (st.kind == "talent" or st.kind == "item") and (" -> "..(P.ACT_TARGET_NAMES[st.target or "nearest"] or st.target)) or ((st.kind == "wait") and "" or (" -> "..(P.ACT_TARGET_NAMES[st.target or "nearest"] or st.target)))
		local mode = st.if_unusable == "wait" and _t" [wait]" or st.if_unusable == "approach" and _t" [step in]" or ""
		list[#list+1] = {name=("%d. %s%s%s"):format(i, self.actor:actStepName(st), tgt, mode), idx=i}
	end
	if #list == 0 then list[1] = {name=_t"(no steps: tap Add)", idx=nil} end
	return list
end

function _M:build()
	local bh = 50
	self.c_routines = List.new{width=self.lw, height=self.ih - bh * 2 - 60, scrollbar=true, list=self:routineList(), fct=function(item) if item.idx then self.actor.act_active = item.idx self:refresh() end end, select=function(item) end}
	self.c_steps = List.new{width=self.rw, height=self.ih - bh * 2 - 60, scrollbar=true, list=self:stepList(), fct=function(item) self.sel_step = item.idx print("[ACT] editor select", tostring(item.idx)) end, select=function(item) end}
	self.c_help = Textzone.new{width=self.iw, auto_height=true, text=_t"Left: routines (tap = make active). Right: the steps in order; tap one to select it, then use the buttons. Target cycles what a step aims at. Skip/Wait/Step: what a tap does when the step cannot fire (skip it, wait a turn, or step toward the target)."}
	local b_new = btn(_t"New", function() self:newRoutine() end)
	local b_rename = btn(_t"Rename", function() self:renameRoutine() end)
	local b_copy = btn(_t"Copy", function() self:copyRoutine() end)
	local b_del = btn(_t"Delete", function() self:deleteRoutine() end)
	local b_add = btn(_t"Add step", function() self:addStep() end)
	local b_rem = btn(_t"Remove", function() self:removeStep() end)
	local b_up = btn(_t"Up", function() self:moveStep(-1) end)
	local b_down = btn(_t"Down", function() self:moveStep(1) end)
	local b_target = btn(_t"Target", function() if self.sel_step then self:cycleTarget(self.sel_step) end end)
	local b_wait = btn(_t"Skip/Wait/Step", function() self:toggleWait() end)
	local b_done = btn(_t"Done", function() game:unregisterDialog(self) end)
	self.uis_def = {
		{left=0, top=0, ui=self.c_help},
		{left=0, top=self.c_help.h + 10, ui=self.c_routines},
		{left=self.lw + 20, top=self.c_help.h + 10, ui=self.c_steps},
		{left=0, bottom=0, ui=b_new}, {left=b_new, bottom=0, ui=b_rename}, {left=b_rename, bottom=0, ui=b_copy}, {left=b_copy, bottom=0, ui=b_del},
		{left=self.lw + 20, bottom=0, ui=b_add}, {left=b_add, bottom=0, ui=b_rem}, {left=b_rem, bottom=0, ui=b_up}, {left=b_up, bottom=0, ui=b_down}, {left=b_down, bottom=0, ui=b_target}, {left=b_target, bottom=0, ui=b_wait},
		{right=0, bottom=0, ui=b_done},
	}
end

function _M:refresh()
	local old_r, old_s = self.c_routines, self.c_steps
	self.c_routines = List.new{width=self.lw, height=old_r.h, scrollbar=true, list=self:routineList(), fct=old_r.fct, select=function(item) end}
	self.c_steps = List.new{width=self.rw, height=old_s.h, scrollbar=true, list=self:stepList(), fct=old_s.fct, select=function(item) end}
	self:replaceUI(old_r, self.c_routines)
	self:replaceUI(old_s, self.c_steps)
	if self.sel_step and self.c_steps.list[self.sel_step] then self.c_steps.sel = self.sel_step end
	self.actor.act_preview_key = nil
end

function _M:newRoutine()
	local rs = self.actor.act_routines
	rs[#rs+1] = {name=("Routine %d"):format(#rs + 1), steps={}, pos=1}
	self.actor.act_active = #rs
	self:refresh()
end
function _M:copyRoutine()
	local rs = self.actor.act_routines
	local r = self.actor:actRoutine()
	rs[#rs+1] = {name=r.name.." 2", steps=table.clone(r.steps, true), pos=1}
	self.actor.act_active = #rs
	self:refresh()
end
function _M:deleteRoutine()
	local rs = self.actor.act_routines
	if #rs <= 1 then Dialog:simplePopup(_t"Act", _t"Keep at least one routine.") return end
	table.remove(rs, self.actor.act_active)
	self.actor.act_active = math.max(1, self.actor.act_active - 1)
	self:refresh()
end
function _M:renameRoutine()
	local r = self.actor:actRoutine()
	game:registerDialog(GetText.new(_t"Routine name", _t"Name", 1, 30, function(txt) r.name = txt self:refresh() end, nil, r.name))
end

function _M:addStep()
	local a = self.actor
	local list = {
		{name=_t"Bump attack", step={kind="bump", target="nearest", if_unusable="skip"}},
		{name=_t"Approach (one step toward the target)", step={kind="approach", target="nearest", if_unusable="skip"}},
		{name=_t"Step back (away from enemies)", step={kind="back", target="nearest", if_unusable="skip"}},
		{name=_t"Wait a turn", step={kind="wait", if_unusable="skip"}},
	}
	local tal = {}
	for tid, lvl in pairs(a.talents) do
		local t = a:getTalentFromId(tid)
		if t and t.mode == "activated" and not t.hide then tal[#tal+1] = {name=t.name, step={kind="talent", tid=tid, target="nearest", if_unusable="approach"}} end
	end
	table.sort(tal, function(x, y) return x.name < y.name end)
	for _, it in ipairs(tal) do list[#list+1] = it end
	local seen = {}
	for i = 1, 12 * (a.nb_hotkey_pages or 7) do
		local hk = a.hotkey[i]
		if hk and hk[1] == "inventory" and not seen[hk[2]] then seen[hk[2]] = true list[#list+1] = {name=_t"Use: "..hk[2], step={kind="item", item=hk[2], target="manual", if_unusable="skip"}} end
	end
	Dialog:listPopup(_t"Add a step", _t"Talents fire at the step's target; items use their own targeting.", list, math.floor(game.w * 0.5), math.floor(game.h * 0.8), function(item)
		if not item then return end
		local r = a:actRoutine()
		local st = table.clone(item.step)
		local pos = (self.sel_step and self.sel_step < #r.steps) and self.sel_step + 1 or #r.steps + 1
		table.insert(r.steps, pos, st)
		self.sel_step = pos
		self:refresh()
	end)
end

function _M:removeStep()
	local r = self.actor:actRoutine()
	if self.sel_step and r.steps[self.sel_step] then table.remove(r.steps, self.sel_step) self.sel_step = math.min(self.sel_step, #r.steps) if self.sel_step == 0 then self.sel_step = nil end r.pos = 1 self:refresh() end
end
function _M:moveStep(dir)
	local r = self.actor:actRoutine()
	local i = self.sel_step
	if not i or not r.steps[i] or not r.steps[i + dir] then return end
	r.steps[i], r.steps[i + dir] = r.steps[i + dir], r.steps[i]
	self.sel_step = i + dir
	self:refresh()
end
function _M:toggleWait()
	local r = self.actor:actRoutine()
	local st = self.sel_step and r.steps[self.sel_step]
	if st then
		-- skip -> wait -> step in (closes distance when out of range) -> skip
		local nxt = {skip="wait", wait="approach", approach="skip"}
		st.if_unusable = nxt[st.if_unusable or "skip"] or "skip"
		self:refresh()
	end
end
function _M:cycleTarget(i)
	local r = self.actor:actRoutine()
	local st = r.steps[i]
	if not st or st.kind == "wait" then return end
	local P = mod.class.Player
	local rules = P.ACT_TARGETS
	if st.kind ~= "talent" and st.kind ~= "item" then rules = {"nearest", "attacker", "weakest", "strongest", "marked"} end
	if st.kind == "item" then rules = {"manual", "self"} end
	local cur = st.target or "nearest"
	local idx = 1
	for k, v in ipairs(rules) do if v == cur then idx = k % #rules + 1 end end
	st.target = rules[idx]
	self.sel_step = i
	self:refresh()
end
