-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2019 Nicolas Casalini
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

require "engine.class"
require "engine.ui.Dialog"
local List = require "engine.ui.List"
local Savefile = require "engine.Savefile"
local Map = require "engine.Map"
local GetQuantity = require "engine.dialogs.GetQuantity"
local PartySendItem = require "mod.dialogs.PartySendItem"

module(..., package.seeall, class.inherit(engine.ui.Dialog))

function _M:init(center_mouse, actor, object, item, inven, onuse, no_use, dst_actor)
	self.actor = actor
	self.dst_actor = dst_actor
	self.object = object
	self.inven = inven
	self.item = item
	self.onuse = onuse
	self.no_use_allowed = no_use

	self:generateList()
	local name = object:getName()
	local w = self.font_bold:size(name)

	-- iOS port: an action sheet - the description on top, big buttons under it
	if require("engine.TouchInput").active() then
		local FontPackage = require "engine.FontPackage"
		local Button = require "engine.ui.Button"
		local TextzoneList = require "engine.ui.TextzoneList"
		local bigfont = core.display.newFont(FontPackage:getFont("default"), 22)
		engine.ui.Dialog.init(self, name, game.w * 0.72, game.h * 0.92)
		local desc_h = math.floor(self.ih * 0.5)
		local desc = TextzoneList.new{focus_check=true, scrollbar=true, width=self.iw, height=desc_h, dest_area={h=desc_h}}
		local ok, d = pcall(object.getDesc, object, {do_color=true}, actor:getInven(object:wornInven()), nil, actor)
		if ok and d then desc:switchItem(d, d) end
		local uis = {{left=0, top=0, ui=desc}}
		local x, y, rowh = 0, desc_h + 12, 0
		for i, it in ipairs(self.list) do
			local b = Button.new{text=it.name, font=bigfont, fct=function() self:use(it) end}
			if i == 1 then b.glow = 0.6 end
			if x + b.w > self.iw then x = 0 y = y + rowh + 8 rowh = 0 end
			uis[#uis+1] = {left=x, top=y, ui=b}
			x = x + b.w + 8
			rowh = math.max(rowh, b.h)
		end
		self:loadUI(uis)
		self:setupUI()
		self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end, }
		return
	end

	engine.ui.Dialog.init(self, name, 1, 1)

	local list = List.new{width=math.max(w, self.max) + 10, nb_items=#self.list, list=self.list, fct=function(item) self:use(item) end}

	self:loadUI{
		{left=0, top=0, ui=list},
	}
	self:setupUI(true, true, function(w, h)
		if center_mouse then
			local mx, my = core.mouse.get()
			self.force_x = mx - w / 2
			self.force_y = my - (self.h - self.ih + list.fh / 3)
		end
	end)

	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end, }
end

function _M:use(item)
	if not item then return end
	game:unregisterDialog(self)

	local act = item.action

	if act == "bar-put" then
		local Picker = require "mod.dialogs.TouchSlotPicker"
		local o, actor = self.object, self.actor
		game:registerDialog(Picker.new(actor, ("Put %s on the bar"):tformat(o:getName{do_color=false, no_count=true}), function(slot) Picker.bindItem(actor, o, slot) end,
			Picker.itemSlot(actor, o), {subject=o:getName{no_count=true}, on_remove=function() Picker.unbindItem(actor, o) end}))
		return
	elseif act == "bar-remove" then
		require("mod.dialogs.TouchSlotPicker").unbindItem(self.actor, self.object)
		-- a deliberate removal keeps auto-bar items (Rod of Recall) from coming back by themselves
		if self.object.define_as then self.actor.touch_autobound = self.actor.touch_autobound or {} self.actor.touch_autobound[self.object.define_as] = true end
		return
	end

	if act == "use" then
		if self.object:wornInven() and not self.object.wielded and not self.object.use_no_wear then
			self:simplePopup(_t"Impossible", _t"You must wear this object to use it!")
		else
			self.actor:playerUseItem(self.object, self.item, self.inven, self.onuse)
			self.onuse(self.inven, self.item, self.object, true)
		end
	elseif act == "identify" then
		self.object:identify(true)
		self.onuse(self.inven, self.item, self.object, false)
	elseif act == "drop" then
		if self.object:getNumber() > 1 then
			game:registerDialog(GetQuantity.new(_t"Drop how many?", ("1 to %d"):tformat(self.object:getNumber()), self.object:getNumber(), self.object:getNumber(), function(qty)
				qty = util.bound(qty, 1, self.object:getNumber())
				self.actor:doDrop(self.inven, self.item, function() self.onuse(self.inven, self.item, self.object, false) end, qty)
			end, 1))
		else
			self.actor:doDrop(self.inven, self.item, function() self.onuse(self.inven, self.item, self.object, false) end)
		end
	elseif act == "wear" then
		self.actor:doWear(self.inven, self.item, self.object, self.dst_actor)
		if self.object.wielded and not self.actor.player and game.party:hasMember(self.actor) then -- make sure usable equipment worn by party members begins cooling down
			mod.class.Player.cooldownWornObject(self.actor, self.object)
		end
		self.onuse(self.inven, self.item, self.object, false)
	elseif act == "takeoff" then
		self.actor:doTakeoff(self.inven, self.item, self.object, nil, self.dst_actor)
		self.onuse(self.inven, self.item, self.object, false)
	elseif act == "tinker-remove" then
		self.actor:doTakeoffTinker(self.inven[self.item], self.object)
		self.actor:sortInven()
		self.onuse(self.inven, self.item, self.object, false)
	elseif act == "tinker-detach" then
		self.actor:doTakeoffTinker(self.object, self.object.tinker)
		self.actor:sortInven()
		self.onuse(self.inven, self.item, self.object, false)
	elseif act == "tinker-add" then
		local list = {}
		for inven_idx, inven in pairs(self.actor.inven) do if inven.worn then
			for item_idx, o in ipairs(inven) do
				if self.actor.tinker_restrict_slots and (not self.actor.tinker_restrict_slots[inven.name] or self.actor.tinker_restrict_slots[inven.name] < item_idx) then
					-- nothing
				else
					if o:canAttachTinker(self.object, true) then list[#list+1] = {name=o:getName{do_color=true}, inven=inven, item=item_idx, o=o} end
				end
			end
		end end
		local doit = function(w)
			if not w then return end
			self.actor:doWearTinker(self.inven, self.item, self.object, w.inven, w.item, w.o, true)
			self.actor:sortInven()
			self.onuse(self.inven, self.item, self.object, false)
		end
		if #list == 1 then doit(list[1])
		elseif #list == 0 then
			self:simplePopup(_t"Attach to item", _t"You do not have any equipped items that it can be attached to.")
		else
			self:listPopup(_t"Attach to item", _t"Select which item to attach it to:", list, 300, 400, doit)
		end
	elseif act == "transfer" then
		game:registerDialog(PartySendItem.new(self.actor, self.object, self.inven, self.item, function()
			self.onuse(self.inven, self.item, self.object, false)
		end))		
	elseif act == "transmo" then
		self:yesnoPopup(self.actor:transmoGetWord():capitalize(), ("Really %s %s"):tformat(self.actor:transmoGetWord(), self.object:getName{}), function(ret)
			if not ret then return end
			self.actor:transmoInven(self.inven, self.item, self.object)
			self.onuse(self.inven, self.item, self.object, false)
		end)
	elseif act == "wear_off" then
		-- iOS port: wear in the off-hand slot outright (the game only picks it by itself when it is empty)
		local off = self.actor:getObjectOffslot(self.object)
		local id = off and self.actor["INVEN_"..off]
		if id then self.actor:doWear(self.inven, self.item, self.object, self.actor, id) end
	elseif act == "wear2" then
		-- iOS port: put the item into the second weapon set without swapping sets first
		local wi = self.object:wornInven()
		local sn = wi and self.actor.inven_def[wi] and self.actor.inven_def[wi].short_name
		local qs = sn and self.actor["INVEN_QS_"..sn]
		local qinv = qs and self.actor:getInven(qs)
		if not qinv then game.logPlayer(self.actor, "This item has no place in the second set.") return end
		local ok, err = self.actor:canWearObject(self.object)
		if not ok then game.logPlayer(self.actor, "%s can not wear %s: %s.", self.actor:getName():capitalize(), self.object:getName{do_color=true}, err or "?") return end
		local o = self.actor:removeObject(self.inven, self.item)
		-- the slot holds one item: the previous one goes back to the pack
		while #qinv >= (qinv.max or 1) do local old = self.actor:removeObject(qinv, 1) if old then self.actor:addObject(self.actor.INVEN_INVEN, old) end end
		self.actor:addObject(qs, o)
		self.actor:sortInven()
		game.logPlayer(self.actor, "You put %s in your second weapon set.", o:getName{do_color=true})
		self.actor.changed = true
	elseif act == "toinven" then
		self.object.__transmo = false
		self.actor:checkEncumbrance()
		self.onuse(self.inven, self.item, self.object, false)
	elseif act == "untag" then
		self.object.__tagged = nil
		self.onuse(self.inven, self.item, self.object, false)
	elseif act == "tag" then
		local d = require("engine.dialogs.GetText").new(_t"Tag object (tagged objects can not be destroyed or dropped)", _t"Tag:", 2, 25, function(tag) if tag then
			self.object.__tagged = tag
			self.object.__transmo = false
			self.onuse(self.inven, self.item, self.object, false)
		end end)
		game:registerDialog(d)
	elseif act == "chat-link" then
		profile.chat.uc_ext:sendObjectLink(self.object)
	elseif act == "debug-inspect" then
		local DebugConsole = require"engine.DebugConsole"
		local d = DebugConsole.new()
		game:registerDialog(d)
		DebugConsole.line = "=__uids["..self.object.uid.."]"
		DebugConsole.line_pos = #DebugConsole.line
		d.changed = true
	else
		self:triggerHook{"UseItemMenu:use", actor=self.actor, object=self.object, inven=self.inven, item=self.item, act=act, onuse=self.onuse}
	end
end

function _M:generateList()
	local list = {}

	local transmo_chest = self.actor:attr("has_transmo")

	if not self.object:isIdentified() and self.actor:attr("auto_id") and self.actor:attr("auto_id") >= 2 then list[#list+1] = {name=_t"Identify", action="identify"} end
	if not self.dst_actor and self.object.__transmo then list[#list+1] = {name=_t"Move to normal inventory", action="toinven"} end
	if not self.dst_actor and not self.object.__transmo and not self.no_use_allowed then if self.object:canUseObject() then list[#list+1] = {name=_t"Use", action="use"} end end
	if self.inven == self.actor.INVEN_INVEN and self.object:wornInven() and self.actor:getInven(self.object:wornInven()) then list[#list+1] = {name=_t"Wield/Wear", action="wear"} end
	do -- iOS port: wear in the off-hand
		local off = self.inven == self.actor.INVEN_INVEN and self.actor:getObjectOffslot(self.object)
		if off and self.actor["INVEN_"..off] and self.actor:getInven(self.actor["INVEN_"..off]) and self.actor:canWearObject(self.object, off) then
			list[#list+1] = {name=(_t"Wield in %s"):format(self.actor.inven_def[self.actor["INVEN_"..off]].name:lower()), action="wear_off"}
		end
	end
	do -- iOS port: the second weapon set
		local wi = self.inven == self.actor.INVEN_INVEN and self.object:wornInven()
		local sn = wi and self.actor.inven_def[wi] and self.actor.inven_def[wi].short_name
		if sn and self.actor["INVEN_QS_"..sn] and self.actor:getInven(self.actor["INVEN_QS_"..sn]) then list[#list+1] = {name=_t"Wield in set 2", action="wear2"} end
	end
	if not self.object.__transmo then if self.inven ~= self.actor.INVEN_INVEN and self.object:wornInven() then list[#list+1] = {name=_t"Take off", action="takeoff"} end end
	if not self.object.__transmo then if self.inven ~= self.actor.INVEN_INVEN and self.object.is_tinker and self.object.tinkered then list[#list+1] = {name=_t"Detach from item", action="tinker-remove"} end end
	if not self.object.__transmo then if self.inven == self.actor.INVEN_INVEN and self.object.is_tinker and not self.object.tinkered then list[#list+1] = {name=_t"Attach to item", action="tinker-add"} end end
	if not self.object.__transmo and self.object.tinker then list[#list+1] = { name = _t'Detach tinker', action='tinker-detach' } end
	-- iOS port: usable items (rods, wands, torques...) go on the action bar like talents
	if require("engine.TouchInput").active() and not self.dst_actor and not self.object.__transmo and self.object:canUseObject() and self.actor.hotkey then
		local Picker = require "mod.dialogs.TouchSlotPicker"
		if Picker.itemSlot(self.actor, self.object) then list[#list+1] = {name=_t"Remove from bar", action="bar-remove"}
		else list[#list+1] = {name=_t"Put on bar", action="bar-put"} end
	end
	if not self.dst_actor and not self.object.__tagged and self.inven == self.actor.INVEN_INVEN then list[#list+1] = {name=_t"Drop", action="drop"} end
	if not self.dst_actor and self.inven == self.actor.INVEN_INVEN and not self.object.plot and not self.object.quest and game.party:countInventoryAble() >= 2 then list[#list+1] = {name=_t"Transfer to party", action="transfer"} end
	if not self.dst_actor and not self.object.__tagged and self.inven == self.actor.INVEN_INVEN and transmo_chest and self.actor:transmoFilter(self.object) then list[#list+1] = {name=("%s now"):tformat(self.actor:transmoGetWord():capitalize()), action="transmo"} end
	if profile.auth and profile.hash_valid then list[#list+1] = {name=_t"Link item in chat", action="chat-link"} end
	if config.settings.cheat then list[#list+1] = {name=_t"Lua inspect", action="debug-inspect", color=colors.simple(colors.LIGHT_BLUE)} end
	if not self.object.__tagged then list[#list+1] = {name=_t"Tag", action="tag"} end
	if self.object.__tagged then list[#list+1] = {name=_t"Untag", action="untag"} end

	self:triggerHook{"UseItemMenu:generate", actor=self.actor, object=self.object, inven=self.inven, item=self.item, menu=list}

	self.max = 0
	self.maxh = 0
	for i, v in ipairs(list) do
		local w, h = self.font:size(v.name)
		self.max = math.max(self.max, w)
		self.maxh = self.maxh + self.font_h
	end

	self.list = list
end
