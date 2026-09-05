-- ToME iOS port: mobile-native "Load game".
-- Save cards on the left (thumbnail, name, class/level/zone), a detail pane on
-- the right with the full screenshot and big Load / Delete buttons. The
-- version/addon checks and the load/delete logic come from the desktop
-- LoadGame dialog (this is a subclass); only the widgets are new.

require "engine.class"
local Module = require "engine.Module"
local Dialog = require "engine.ui.Dialog"
local LoadGame = require "mod.dialogs.LoadGame"
local Button = require "engine.ui.Button"
local Checkbox = require "engine.ui.Checkbox"
local Savefile = require "engine.Savefile"
local K = require "engine.ui.TouchKit"

module(..., package.seeall, class.inherit(LoadGame))

local font, text, draw, quad, frame, wrap = K.font, K.text, K.draw, K.quad, K.frame, K.wrap
local GOLD, PANE = K.GOLD, K.PANE

--- Pull the readable bits out of the save description written by
-- Game:getSaveDescription ("Name the level 12 Cornac Berserker.\n...\nExploring level 2 of Trollmire.")
function _M.parseDescription(desc)
	desc = tostring(desc or "")
	local info = {}
	local level, sub, cls = desc:match("the level (%d+) (%S+) ([^%.\n]+)%.")
	if level then info.level, info.subrace, info.class = tonumber(level), sub, cls end
	local diff, death = desc:match("Difficulty: ([^/\n]+) / ([^\n]+)")
	if diff then info.difficulty, info.permadeath = diff:gsub("%s+$", ""), death:gsub("%s+$", "") end
	info.campaign = desc:match("Campaign: ([^\n]+)")
	local zl, zone = desc:match("Exploring level (%S+) of ([^%.\n]+)%.")
	if zone then info.zone_level, info.zone = zl, zone end
	return info
end

function _M.ago(ts)
	if not ts then return nil end
	local d = os.time() - ts
	if d < 90 then return _t"just now" end
	if d < 3600 then return ("%d min ago"):tformat(math.floor(d / 60)) end
	if d < 86400 then return ("%d h ago"):tformat(math.floor(d / 3600)) end
	return ("%d days ago"):tformat(math.floor(d / 86400))
end

--- Every loadable save, newest first, with the module it needs resolved the
-- way the desktop dialog does it (save.mod, save.usable, save.addons_status).
function _M.scan(show_compat)
	local list = Module:listSavefiles(show_compat)
	local saves = {}
	for i = #list, 1, -1 do
		local m = list[i]
		if m.is_boot then table.remove(list, i) m.savefiles = {} end
		local mod_addons = {}
		for _, save in ipairs(m.savefiles or {}) do
			local mod_string = ("%s-%d.%d.%d"):format(m.short_name, save.module_version and save.module_version[1] or -1, save.module_version and save.module_version[2] or -1, save.module_version and save.module_version[3] or -1)
			save.module_string = mod_string
			local mod = list[mod_string]
			if not mod and save.module_version and m.versions and m.versions[1] and m.versions[1].version and engine.version_patch_same(m.versions[1].version, save.module_version) then mod = m.versions[1] end
			if not mod and show_compat and m.versions and m.versions[1] then mod = m.versions[1] end
			if mod and save.loadable then
				local laddons = mod_addons[mod]
				if not laddons then
					laddons = table.reversekey(Module:listAddons(mod, true), "short_name")
					mod_addons[mod] = laddons
				end
				local addons, missing = {}, {}
				save.usable = true
				for _, add in ipairs(save.addons or {}) do
					if laddons[add] then addons[#addons+1] = add
					else missing[#missing+1] = add save.usable = false end
				end
				save.addons_ok, save.addons_missing = addons, missing
				save.mod = mod
				save.base_name = save.short_name
				save.mod_name = mod.long_name or mod.name
				save.info = _M.parseDescription(save.description)
				if save.screenshot and not save.thumb then
					local ok, w, h = pcall(function() return save.screenshot:getSize() end)
					if ok and w then
						local tex = { save.screenshot:glTexture() }
						tex.w, tex.h = w, h
						save.thumb = tex
					end
					save.screenshot = nil
				end
				saves[#saves+1] = save
			end
		end
	end
	table.sort(saves, function(a, b) return (a.timestamp or 0) > (b.timestamp or 0) end)
	return saves
end

--- Load a save entry from scan(): the same version / developer-mode checks as the desktop dialog.
function _M.playEntry(save, ignore_mod_compat, force_addons)
	if not save or not save.mod then return end
	local save_v = engine.version_from_string(save.module_string)
	local save_m = engine.version_from_string(save.mod.version_string)
	if not ignore_mod_compat and not engine.version_patch_same(save_m, save_v) and save_m.name == save_v.name then
		Dialog:yesnoLongPopup(_t"Original game version not found", ("This savefile was created with game version %s. You can try loading it with the current version if you wish but it is recommended you play it with the old version to ensure compatibility"):tformat(save.module_string), 500, function(ret)
			if not ret then _M.playEntry(save, true, force_addons) end
		end, _t"Cancel", _t"Run with newer version", true)
		return
	end
	if config.settings.cheat and not save.cheat then
		Dialog:yesnoPopup(_t"Developer Mode", _t"#LIGHT_RED#WARNING: #LAST#Loading a savefile while in developer mode will permanently invalidate it. Proceed?", function(ret) if not ret then
			Module:instanciate(save.mod, save.base_name, false)
		end end, _t"Cancel", _t"Load anyway", true)
	else
		local extra_info = nil
		if force_addons then extra_info = "ignore_addons_not_loading=true" end
		Module:instanciate(save.mod, save.base_name, false, nil, extra_info)
	end
end

function _M:init(force_compat)
	self.show_compat = force_compat and true or false
	self.force_addons = false
	Dialog.init(self, _t"Load game", game.w * 0.94, game.h * 0.92)
	self.__touch_load = true

	self.detail_w = 380
	local gap = 12
	self.list_w = self.iw - self.detail_w - gap
	local bigfont = font(22)

	self.c_compat = Checkbox.new{default=self.show_compat, width=math.floor(self.list_w / 2), title=_t"Show older versions", on_change=function(v) self.show_compat = v self:refresh() end}
	self.c_force_addons = Checkbox.new{default=false, width=math.floor(self.list_w / 2), title=_t"Ignore unloadable addons", on_change=function(v) self.force_addons = v end}
	local toggles_h = self.c_compat.h + 6
	if __module_extra_info.show_ignore_addons_not_loading then toggles_h = toggles_h + self.c_force_addons.h + 6 end

	self.c_flow = K.Flow.new{width=self.list_w, height=self.ih - toggles_h}
	self.b_load = Button.new{text=_t"Load", width=self.detail_w, font=bigfont, fct=function() self:playSave() end}
	self.b_delete = Button.new{text=_t"Delete", width=self.detail_w, font=bigfont, fct=function() self:deleteSave() end}

	local dx = self.list_w + gap
	local uis = {
		{left=0, top=0, ui=self.c_flow},
		{left=0, bottom=0, ui=self.c_compat},
		{left=dx, bottom=self.b_delete.h + 8, ui=self.b_load},
		{left=dx, bottom=0, ui=self.b_delete},
	}
	if __module_extra_info.show_ignore_addons_not_loading then
		uis[2] = {left=0, bottom=self.c_force_addons.h + 6, ui=self.c_compat}
		uis[#uis+1] = {left=0, bottom=0, ui=self.c_force_addons}
	end
	self:loadUI(uis)
	self:setupUI(false, true)
	self:setFocus(self.c_flow)
	self:refresh()

	self.key:addBinds{
		EXIT = function() game:unregisterDialog(self) end,
	}
end

function _M:refresh()
	self.saves = _M.scan(self.show_compat)
	if self.save_sel then
		local keep
		for _, s in ipairs(self.saves) do if s.short_name == self.save_sel.short_name and s.mod == self.save_sel.mod then keep = s end end
		self.save_sel = keep
	end
	self.cur_sel = self.save_sel
	self:buildCards()
end

function _M:cardSub(save)
	local i = save.info or {}
	local parts = {}
	if i.level then parts[#parts+1] = ("Level %d %s %s"):tformat(i.level, i.subrace or "", i.class or "") end
	if i.zone then parts[#parts+1] = ("%s %s"):format(i.zone, i.zone_level or "") end
	local ago = _M.ago(save.timestamp)
	if ago then parts[#parts+1] = ago end
	if not save.usable then parts[#parts+1] = _t"missing addons" end
	return table.concat(parts, " · ")
end

function _M:buildCards()
	local items = {}
	for _, save in ipairs(self.saves) do
		local icon
		if save.thumb then
			local t = save.thumb
			icon = function(x, y, size)
				-- 16:9-ish thumbnail inside the icon box
				local w, h = size, math.floor(size * t.h / t.w)
				if h > size then h = size w = math.floor(size * t.w / t.h) end
				t[1]:toScreenFull(x, y + (size - h) / 2, w, h, t[2] * w / t.w, t[3] * h / t.h)
			end
		end
		items[#items+1] = {name=save.name, sub=self:cardSub(save), icon=icon, sel=self.save_sel == save, data=save, locked=not save.usable and not self.force_addons or false,
			on_tap=function() self:select(save) end}
	end
	local secs = {}
	if #items > 0 then
		secs[#secs+1] = {title=_t"Saved characters", items=items, min_w=280, row_h=92, icon_size=76}
	else
		secs[#secs+1] = {title=_t"Saved characters", items={{name=_t"No saved games", sub=_t"Start a new character from the main menu."}}, cols=1, row_h=72}
	end
	self.c_flow:setSections(secs)
	self.c_flow.scrollbar.pos = 0
	self:toggleDisplay(self.b_load, self.save_sel ~= nil and (self.save_sel.usable or self.force_addons))
	self:toggleDisplay(self.b_delete, self.save_sel ~= nil)
end

function _M:select(save)
	-- a second tap on the selected card loads it, like the desktop double-click
	if self.save_sel == save and save and (save.usable or self.force_addons) then self:playSave() return end
	self.save_sel = save
	self.cur_sel = save
	self:buildCards()
end

function _M:on_focus() end
function _M:switch() self:refresh() end

function _M:playSave(ignore_mod_compat)
	if not self.save_sel then return end
	if not (self.save_sel.usable or self.force_addons) then return end -- hidden buttons still get taps
	_M.playEntry(self.save_sel, ignore_mod_compat, self.force_addons)
end

function _M:deleteSave()
	if not self.save_sel then return end
	local sel = self.save_sel
	Dialog:yesnoPopup(_t"Delete savefile", ("Really delete #{bold}##GOLD#%s#WHITE##{normal}#"):tformat(sel.name), function(ret)
		if ret then
			local base = Module:setupWrite(sel.mod)
			local save = Savefile.new(sel.base_name)
			save:delete()
			save:close()
			fs.umount(base)
			game.save_list = Module:listSavefiles()
			self.save_sel, self.cur_sel = nil, nil
			self:refresh()
		end
	end, _t"Delete", _t"Cancel")
end

function _M:regen()
	self:refresh()
end

-- the detail pane: screenshot, name, the parsed facts, version and addons
function _M:innerDisplayBack(x, y, nb_keyframes)
	x, y = x + self.ix, y + self.iy
	local dx = x + self.list_w + 12
	local pw = self.detail_w
	quad(dx, y, pw, self.ih, PANE)
	local save = self.save_sel
	if not save then
		for li, l in ipairs(wrap(_t"Tap a character to see where you left off.", font(16), pw - 24, 3)) do draw(text(l, 16, 142, 136, 120, false, pw - 24), dx + 12, y + 16 + (li - 1) * 22) end
		return
	end
	local cy = y + 12
	if save.thumb then
		local t = save.thumb
		local w = pw - 24
		local h = math.floor(w * t.h / t.w)
		local maxh = math.floor(self.ih * 0.4)
		if h > maxh then h = maxh w = math.floor(h * t.w / t.h) end
		quad(dx + 12 + (pw - 24 - w) / 2 - 3, cy - 3, w + 6, h + 6, {14, 15, 18})
		t[1]:toScreenFull(dx + 12 + (pw - 24 - w) / 2, cy, w, h, t[2] * w / t.w, t[3] * h / t.h)
		cy = cy + h + 14
	end
	draw(text(save.name, 22, 240, 212, 138, true, pw - 24), dx + 12, cy) cy = cy + 32
	local i = save.info or {}
	local rows = {}
	if i.level then rows[#rows+1] = {_t"Character", ("Level %d %s %s"):tformat(i.level, i.subrace or "", i.class or "")} end
	if i.zone then rows[#rows+1] = {_t"Where", ("%s, level %s"):tformat(i.zone, i.zone_level or "?")} end
	if i.difficulty then rows[#rows+1] = {_t"Rules", ("%s · %s"):format(i.difficulty, i.permadeath or "")} end
	if i.campaign then rows[#rows+1] = {_t"Campaign", i.campaign} end
	local ago = _M.ago(save.timestamp)
	if ago then rows[#rows+1] = {_t"Last played", ago} end
	rows[#rows+1] = {_t"Game version", save.module_string or "?"}
	if save.addons and #save.addons > 0 then
		local okn, miss = #(save.addons_ok or {}), save.addons_missing or {}
		rows[#rows+1] = {_t"Addons", #miss > 0 and ("%d missing: %s"):tformat(#miss, table.concat(miss, ", ")) or ("%d loaded"):tformat(okn), #miss > 0}
	end
	for _, r in ipairs(rows) do
		if cy > y + self.ih - self.b_load.h - self.b_delete.h - 60 then break end
		draw(text(r[1]:upper(), 11, 142, 136, 120, true), dx + 12, cy + 2)
		local v = text(r[2], 15, r[3] and 224 or 234, r[3] and 122 or 227, r[3] and 106 or 209, false, pw - 130)
		if v then draw(v, dx + pw - 12 - v.w, cy) end
		cy = cy + 26
	end
	if not save.usable and not self.force_addons then
		for li, l in ipairs(wrap(_t"This character needs addons that are not installed. Turn on \"Ignore unloadable addons\" to load it anyway.", font(13), pw - 24, 3)) do draw(text(l, 13, 224, 122, 106, false, pw - 24), dx + 12, cy + (li - 1) * 18) end
	end
end

function _M:innerDisplay(x, y, nb_keyframes)
	-- a gold frame on Load so it reads as the main action
	local b = self.ui_by_ui[self.b_load]
	if b and not b.hidden then frame(x + b.x - 3, y + b.y - 3, self.b_load.w + 6, self.b_load.h + 6, GOLD, 3) end
end
