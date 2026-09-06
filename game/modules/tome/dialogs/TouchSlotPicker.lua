-- ToME iOS port: the shared "which slot of the bar" picker.
-- Used by the Talents screen (put a talent on the bar) and by the item sheet
-- (put a usable item such as a Rod of Recall on the bar). The bar is the stock
-- hotkey table: actor.hotkey[i] = {"talent", tid} | {"inventory", name}, so the
-- desktop hotbar, the skill drawer, the Act routines and activateHotkey all agree.

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local Button = require "engine.ui.Button"
local K = require "engine.ui.TouchKit"
local GOLD, quad, frame, text, draw, font = K.GOLD, K.quad, K.frame, K.text, K.draw, K.font
local Flow = K.Flow

module(..., package.seeall, class.inherit(Dialog))

_M.SLOTS_PER_PAGE = 12
_M.PAGES = 3

---------------------------------------------------------------------------
-- static helpers (no dialog needed)
---------------------------------------------------------------------------

--- The hotkey name of an object, the same string the stock auto-hotkey uses
function _M.itemHotkeyName(o)
	return o:getName{no_count=true, force_id=true, no_add_name=true}
end

--- The slot holding this object, or nil
function _M.itemSlot(actor, o)
	if not actor or not actor.hotkey then return nil end
	local name = _M.itemHotkeyName(o)
	for i, hk in pairs(actor.hotkey) do
		if hk[1] == "inventory" and hk[2] == name then return i end
	end
	return nil
end

--- The slot holding this talent, or nil
function _M.talentSlot(actor, tid)
	if not actor or not actor.hotkey then return nil end
	for i, hk in pairs(actor.hotkey) do
		if hk[1] == "talent" and hk[2] == tid then return i end
	end
	return nil
end

local function clearEntry(actor, kind, id)
	for i, hk in pairs(actor.hotkey) do
		if hk[1] == kind and hk[2] == id then actor.hotkey[i] = nil end
	end
end

--- Put the object in slot i (one slot per item, like the desktop hotbar)
function _M.bindItem(actor, o, slot)
	actor.hotkey = actor.hotkey or {}
	local name = _M.itemHotkeyName(o)
	clearEntry(actor, "inventory", name)
	actor.hotkey[slot] = {"inventory", name}
	actor.changed = true
	print("[TOUCH] item -> bar slot", name, slot)
end

function _M.unbindItem(actor, o)
	if not actor.hotkey then return end
	clearEntry(actor, "inventory", _M.itemHotkeyName(o))
	actor.changed = true
	-- a deliberate removal: the auto-bind (TouchManual.AUTO_BAR) must not put it back
	actor.touch_autobound = actor.touch_autobound or {}
	if o.define_as then actor.touch_autobound[o.define_as] = true end
	if o.define_as == "ROD_OF_RECALL" then actor.touch_autobound_recall = true end
	print("[TOUCH] item off bar", _M.itemHotkeyName(o))
end

function _M.bindTalent(actor, tid, slot)
	actor.hotkey = actor.hotkey or {}
	clearEntry(actor, "talent", tid)
	actor.hotkey[slot] = {"talent", tid}
	actor.changed = true
	print("[TOUCH] talent -> bar slot", tostring(tid), slot)
end

function _M.unbindTalent(actor, tid)
	if not actor.hotkey then return end
	clearEntry(actor, "talent", tid)
	actor.changed = true
	print("[TOUCH] talent off bar", tostring(tid))
end

--- What a slot holds: name, drawable entity (or nil), empty flag
function _M.slotLabel(actor, i)
	local hk = actor.hotkey and actor.hotkey[i]
	if not hk then return _t"empty", nil, true end
	if hk[1] == "talent" then
		local t = actor:getTalentFromId(hk[2])
		return t and tostring(t.name) or tostring(hk[2]), t and t.display_entity or nil, false
	elseif hk[1] == "inventory" then
		local o = actor:findInAllInventories(hk[2], {no_add_name=true, force_id=true, no_count=true})
		return tostring(hk[2]), o, false
	end
	return tostring(hk[2] or hk[1]), nil, false
end

---------------------------------------------------------------------------
-- the dialog
---------------------------------------------------------------------------

--- new(actor, title, fct, current_slot, opts)
--   fct(slot) is called with the chosen slot (the dialog closes first)
--   opts.on_remove: shown as a "Remove from bar" card when current_slot is set
--   opts.subject: a short name for the thing being placed (shown under the title)
function _M:init(actor, title, fct, current_slot, opts)
	self.actor = actor
	self.fct = fct
	self.current_slot = current_slot
	self.opts = opts or {}
	local w, h = math.floor(game.w * 0.9), math.floor(game.h * 0.92)
	Dialog.init(self, title or _t"Pick a slot", w, h)
	self.bigfont = font(22)
	self.c_flow = Flow.new{width=self.iw, height=self.ih - 60 - 8}
	self.b_back = Button.new{text=_t"Cancel", width=200, font=self.bigfont, fct=function() game:unregisterDialog(self) end}
	self:loadUI{
		{left=0, top=0, ui=self.c_flow},
		{right=0, bottom=0, ui=self.b_back},
	}
	self:setupUI()
	self:build()
	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end }
end

function _M:build()
	local a = self.actor
	local secs = {}
	local pages = math.min(_M.PAGES, a.nb_hotkey_pages or _M.PAGES)
	local tiles = game.uiset and game.uiset.hotkeys_display_icons and game.uiset.hotkeys_display_icons.tiles
	for p = 1, pages do
		local items = {}
		for j = 1, _M.SLOTS_PER_PAGE do
			local i = _M.SLOTS_PER_PAGE * (p - 1) + j
			local name, ent, empty = _M.slotLabel(a, i)
			local slot = i
			items[#items+1] = {name=("%d · %s"):format(j, name), sub=(self.current_slot == i) and _t"here now" or (empty and _t"free" or _t"replace"),
				sel=self.current_slot == i, locked=false,
				icon=ent and function(x, y, size) pcall(ent.toScreen, ent, tiles, x, y, size, size) end or nil,
				on_tap=function() self:pick(slot) end}
		end
		secs[#secs+1] = {title=("Bar page %d"):tformat(p), items=items, cols=4, row_h=66, icon_size=44}
	end
	local more = {}
	if self.current_slot and self.opts.on_remove then
		more[#more+1] = {name=_t"Remove from bar", sub=("now in slot %d"):tformat(self.current_slot), on_tap=function()
			game:unregisterDialog(self)
			self.opts.on_remove()
		end}
	end
	more[#more+1] = {name=_t"Cancel", sub=_t"leave the bar as it is", on_tap=function() game:unregisterDialog(self) end}
	secs[#secs+1] = {title=self.opts.subject and tostring(self.opts.subject) or _t"Or", items=more, min_w=200, row_h=66}
	self.c_flow:setSections(secs)
end

function _M:pick(slot)
	game:unregisterDialog(self)
	if self.fct then self.fct(slot) end
end

function _M:innerDisplayBack(x, y, nb_keyframes)
	if self.opts.subject then
		draw(text(_t"Tap a slot: this is the order of the skill drawer", 13, 142, 136, 120, false, self.iw), x + self.ix, y + self.iy + self.ih - 60 + 20)
	end
end
