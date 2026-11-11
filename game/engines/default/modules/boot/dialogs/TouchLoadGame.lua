-- ToME iOS port: mobile-native "Load character".
-- A full-screen sheet: the most recently played character as a hero card (level
-- screenshot, name, class, where they are, pills, a big Continue), everyone else
-- as rows sorted by last played, the fallen tucked at the bottom. A long-press
-- (or the hero's "..." button) opens a small actions sheet: Load, Details, Delete.
-- The version/addon checks and the load/delete logic come from the desktop
-- LoadGame dialog (this is a subclass); only the widgets are new.

require "engine.class"
local Module = require "engine.Module"
local Dialog = require "engine.ui.Dialog"
local LoadGame = require "mod.dialogs.LoadGame"
local Button = require "engine.ui.Button"
local Savefile = require "engine.Savefile"
local K = require "engine.ui.TouchKit"

module(..., package.seeall, class.inherit(LoadGame))

local font, text, draw, quad, frame, wrap = K.font, K.text, K.draw, K.quad, K.frame, K.wrap
local GOLD, PANE, CARD = K.GOLD, K.PANE, K.CARD
local INK = {236, 225, 200}
local MUTED = {154, 143, 122}
local GREEN = {143, 211, 156}
local RED = {224, 138, 130}
local HERO_BG = {30, 26, 19}
local LINE = {58, 51, 41}

--- Pull the readable bits out of the save description written by
-- Game:getSaveDescription ("Name the level 12 Cornac Berserker.\n...\nExploring level 2 of Trollmire.")
function _M.parseDescription(desc)
	desc = tostring(desc or "")
	local info = {}
	-- the description is built with :tformat, so it may be English or Chinese (zh_hans)
	local level, sub, cls = desc:match("the level (%d+) (%S+) ([^%.\n]+)%.")
	if not level then
		local first = desc:match("^[^\n]*")
		level, sub, cls = first:match("\231\173\137\231\186\167(%d+)\239\188\140(%S+) (.+)\227\128\130%s*$")
	end
	if level then info.level, info.subrace, info.class = tonumber(level), sub, cls end
	local diff, death = desc:match("Difficulty: ([^/\n]+) / ([^\n]+)")
	if not diff then diff, death = desc:match("\233\154\190\229\186\166\239\188\154([^/\n]+) / ([^\n]+)") end
	if diff then info.difficulty, info.permadeath = diff:gsub("%s+$", ""), death:gsub("%s+$", "") end
	info.campaign = desc:match("Campaign: ([^\n]+)") or desc:match("\230\136\152\229\189\185\239\188\154([^\n]+)")
	local zl, zone = desc:match("Exploring level (%S+) of ([^%.\n]+)%.")
	if not zone then
		zl, zone = desc:match("\230\173\163\229\156\168\230\142\162\231\180\162\230\165\188\229\177\130 (%S+)\239\188\140([^\n]+)\227\128\130%s*$")
	end
	if zone then info.zone_level, info.zone = zl, zone end
	-- the stock description never says so; a module that does gets the Fallen section
	local low = desc:lower()
	info.dead = (low:find("%f[%a]dead%f[%A]") or low:find("%f[%a]died%f[%A]") or low:find("%f[%a]fallen%f[%A]")) and true or false
	return info
end

function _M.ago(ts)
	if not ts then return nil end
	local d = os.time() - ts
	if d < 90 then return _t"just now" end
	if d < 3600 then return ("%d min ago"):tformat(math.floor(d / 60)) end
	if d < 86400 then return ("%d h ago"):tformat(math.floor(d / 3600)) end
	if d < 86400 * 14 then return ("%d days ago"):tformat(math.floor(d / 86400)) end
	return ("%d weeks ago"):tformat(math.floor(d / (86400 * 7)))
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
			local same_version = mod ~= nil
			if not mod and save.module_version and m.versions and m.versions[1] and m.versions[1].version and engine.version_patch_same(m.versions[1].version, save.module_version) then mod = m.versions[1] same_version = true end
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
				save.older_version = not same_version
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

--- Draw a 16:9 thumbnail fitted into a w x h box (letterboxed, centred)
local function drawThumb(t, x, y, w, h)
	local tw, th = w, math.floor(w * t.h / t.w)
	if th > h then th = h tw = math.floor(h * t.w / t.h) end
	t[1]:toScreenFull(x + (w - tw) / 2, y + (h - th) / 2, tw, th, t[2] * tw / t.w, t[3] * th / t.h)
end

---------------------------------------------------------------------------
-- the actions sheet: Load / Details / Delete for one save
---------------------------------------------------------------------------
local Sheet = class.inherit(Dialog){}

function Sheet:init(save, owner)
	self.save, self.owner = save, owner
	local TI = require "engine.TouchInput"
	local sa = TI.safeArea()
	local w = math.min(game.w - sa.l - sa.r - 20, 640)
	local bw, bh, gap = w - 16 - 16, 52, 8
	self.b_load = Button.new{text=_t"Load", width=bw, font=font(22), fct=function() self:doLoad() end}
	self.b_details = Button.new{text=_t"Details", width=bw, font=font(19), fct=function() self:doDetails() end}
	self.b_delete = Button.new{text="#LIGHT_RED#"..(_t"Delete"), width=bw, font=font(19), fct=function() self:doDelete() end}
	self.head_h = 64
	local h = 8 + self.head_h + 3 * (bh + gap) + 16
	self.no_close_box = true
	-- anchored to the bottom of the screen (Dialog.init takes x, y as the forced position)
	Dialog.init(self, nil, w, h, sa.l + math.floor((game.w - sa.l - sa.r - w) / 2), game.h - sa.b - h - 8)
	self.__load_sheet = true
	self:loadUI{
		{left=8, top=self.head_h, ui=self.b_load},
		{left=8, top=self.head_h + bh + gap, ui=self.b_details},
		{left=8, top=self.head_h + 2 * (bh + gap), ui=self.b_delete},
	}
	self:setupUI(false, true)
	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end }
end

function Sheet:close() game:unregisterDialog(self) end

function Sheet:doLoad()
	local s = self.save
	self:close()
	if s.usable or self.owner.force_addons then _M.playEntry(s, self.owner.show_compat, self.owner.force_addons)
	else Dialog:simplePopup(s.name, _t"This character needs addons that are not installed. Turn on \"Addon problems\" at the bottom to load it anyway.") end
end

function Sheet:doDetails()
	local s = self.save
	self:close()
	local lines = {tostring(s.description or "")}
	lines[#lines+1] = ""
	lines[#lines+1] = (_t"Game version: %s"):format(s.module_string or "?")
	if s.addons and #s.addons > 0 then
		local miss = s.addons_missing or {}
		if #miss > 0 then lines[#lines+1] = (_t"Missing addons: %s"):format(table.concat(miss, ", "))
		else lines[#lines+1] = (_t"Addons: %s"):format(table.concat(s.addons_ok or s.addons, ", ")) end
	end
	local ago = _M.ago(s.timestamp)
	if ago then lines[#lines+1] = (_t"Last played %s"):format(ago) end
	Dialog:simpleLongPopup(s.name, table.concat(lines, "\n"), math.floor(game.w * 0.85))
end

function Sheet:doDelete()
	local s, owner = self.save, self.owner
	self:close()
	owner:deleteEntry(s)
end

function Sheet:innerDisplayBack(x, y, nb_keyframes)
	x, y = x + self.ix, y + self.iy
	local s = self.save
	draw(text(s.name, 20, GOLD[1], GOLD[2], GOLD[3], true, self.iw - 16), x + 8, y + 6)
	local i = s.info or {}
	local parts = {}
	if i.level then parts[#parts+1] = ("Level %d %s %s"):tformat(i.level, i.subrace or "", i.class or "") end
	if i.difficulty then parts[#parts+1] = ("%s / %s"):format(i.difficulty, i.permadeath or "") end
	local ago = _M.ago(s.timestamp)
	if ago then parts[#parts+1] = (_t"played %s"):format(ago) end
	draw(text(table.concat(parts, " · "), 15, MUTED[1], MUTED[2], MUTED[3], false, self.iw - 16), x + 8, y + 38)
end

function Sheet:innerDisplay(x, y, nb_keyframes)
	local b = self.ui_by_ui[self.b_load]
	if b then frame(x + b.x - 3, y + b.y - 3, self.b_load.w + 6, self.b_load.h + 6, GOLD, 3) end
end

---------------------------------------------------------------------------
-- the load screen
---------------------------------------------------------------------------

function _M:init(force_compat)
	self.show_compat = force_compat and true or false
	self.force_addons = false
	local TI = require "engine.TouchInput"
	local sa = TI.safeArea()
	self.portrait = TI.portrait()
	self.no_close_box = true
	-- the whole screen minus the safe area (Dialog.init clamps to exactly this)
	Dialog.init(self, nil, game.w - sa.l - sa.r - 10, game.h - sa.t - sa.b - 40)
	self.__touch_load = true

	local bigfont = font(22)
	self.top_h = 52
	self.foot_h = 52 -- two small toggle buttons
	self.b_back = Button.new{text=_t"< Back", width=90, font=font(18), fct=function() game:unregisterDialog(self) end}

	-- hero card geometry
	if self.portrait then
		self.hero_x, self.hero_y, self.hero_w = 0, self.top_h, self.iw
		self.shot_h = 150
	else
		self.hero_x, self.hero_y, self.hero_w = 0, self.top_h, math.floor(self.iw * 0.45)
		self.shot_h = math.min(math.floor(self.hero_w * 9 / 16), math.floor((self.ih - self.top_h - self.foot_h) * 0.45))
	end
	self.hero_h = self.shot_h + 166
	local avail_h = self.ih - self.top_h - self.foot_h
	if self.hero_h > avail_h then self.hero_h = avail_h end
	self.b_more = Button.new{text="...", width=40, font=bigfont, fct=function() if self.hero then self:openSheet(self.hero) end end}
	self.b_continue = Button.new{text=_t"Continue", width=self.hero_w - 24 - 16 - (self.b_more.w + 10), font=bigfont, fct=function() self:playHero() end}

	-- the rows
	if self.portrait then
		self.flow_x, self.flow_y = 0, self.hero_y + self.hero_h + 10
		self.flow_w, self.flow_h = self.iw, self.ih - self.flow_y - self.foot_h
	else
		self.flow_x, self.flow_y = self.hero_w + 12, self.top_h
		self.flow_w, self.flow_h = self.iw - self.hero_w - 12, self.ih - self.top_h - self.foot_h
	end
	self.c_flow = K.Flow.new{width=self.flow_w, height=self.flow_h}
	-- footer: the two compatibility toggles as small buttons (a drawn link under a
	-- dialog-level zone never got the tap: the dialog's own zone takes left clicks)
	self.b_compat = Button.new{text=self:footLabel("compat"), width=200, font=font(17), fct=function() self:toggle("compat") end}
	self.b_addons = Button.new{text=self:footLabel("addons"), width=200, font=font(17), fct=function() self:toggle("addons") end}

	local cta_y = self.hero_y + self.hero_h - 12 - self.b_continue.h
	self:loadUI{
		{left=0, top=4, ui=self.b_back},
		{left=self.hero_x + 12, top=cta_y, ui=self.b_continue},
		{left=self.hero_x + 12 + self.b_continue.w + 10, top=cta_y, ui=self.b_more},
		{left=self.flow_x, top=self.flow_y, ui=self.c_flow},
		{left=self.flow_x, bottom=0, ui=self.b_compat},
		{left=self.flow_x + self.b_compat.w + 10, bottom=0, ui=self.b_addons},
	}
	self:setupUI(false, true)
	self:setFocus(self.c_flow)

	-- footer links (dialog-relative rects, taps via a zone of our own) and long-press
	self.foot_rects = {}
	self.mouse:registerZone(0, 0, self.w, self.h, function(button, mx, my, xrel, yrel, bx, by, event)
		if event ~= "button" then return false end
		-- (the long-press opens the sheet itself in on_hold; the right click that follows is ignored)
		if button == "right" then return false end
		return false
	end)
	self.prev_on_hold = TI.on_hold
	TI.on_hold = function(x, y)
		local d = game.dialogs[#game.dialogs]
		if d ~= self then return false end
		local bx, by = x - self.display_x, y - self.display_y
		local sv = self:saveAt(bx, by)
		if not sv then return false end
		print("[TOUCH] load game: long-press", tostring(sv.name))
		self:openSheet(sv)
		return true
	end

	self:refresh()
	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end }
end

function _M:unload()
	local TI = require "engine.TouchInput"
	if TI.on_hold and self.prev_on_hold ~= TI.on_hold then TI.on_hold = self.prev_on_hold end
end

--- The save under a dialog-relative point: the hero card or a row
function _M:saveAt(bx, by)
	-- bx/by are dialog-relative; the rows are hit-tested against where the Flow
	-- last drew itself (its own screen origin), which is what the finger sees
	local hx, hy = self.ix + self.hero_x, self.iy + self.hero_y
	if self.hero and bx >= hx and bx < hx + self.hero_w and by >= hy and by < hy + self.hero_h then return self.hero end
	local fl = self.c_flow
	if not fl.last_screen_x then return nil end
	local sx, sy = bx + self.display_x, by + self.display_y
	local fx, fy = sx - fl.last_screen_x, sy - fl.last_screen_y + (fl.scrollbar.pos or 0)
	if fx < 0 or fx >= fl.w or sy < fl.last_screen_y or sy >= fl.last_screen_y + fl.h then return nil end
	for _, sec in ipairs(self.c_flow.sections or {}) do
		for _, it in ipairs(sec.items) do
			if it.data and fx >= it.x and fx < it.x + it.w and fy >= it.y and fy < it.y + it.h then return it.data end
		end
	end
	return nil
end

function _M:footLabel(kind)
	if kind == "compat" then return (_t"Older versions: %s"):format(self.show_compat and _t"on" or _t"off") end
	return (_t"Addon problems: %s"):format(self.force_addons and _t"on" or _t"off")
end

function _M:toggle(kind)
	if kind == "compat" then self.show_compat = not self.show_compat
	elseif kind == "addons" then self.force_addons = not self.force_addons end
	print("[TOUCH] load game toggle", kind, tostring(self.show_compat), tostring(self.force_addons))
	if self.b_compat then self.b_compat.text = self:footLabel("compat") self.b_compat:generate() end
	if self.b_addons then self.b_addons.text = self:footLabel("addons") self.b_addons:generate() end
	self:refresh()
end

function _M:refresh()
	self.saves = _M.scan(self.show_compat)
	self.hero = nil
	local alive, fallen = {}, {}
	for _, s in ipairs(self.saves) do
		if s.info and s.info.dead then fallen[#fallen+1] = s else alive[#alive+1] = s end
	end
	self.hero = alive[1]
	self.others = {}
	for i = 2, #alive do self.others[#self.others+1] = alive[i] end
	self.fallen = fallen
	self:buildCards()
end

function _M:usable(save)
	return save.usable or self.force_addons
end

function _M:rowSub(save)
	local i = save.info or {}
	local parts = {}
	if i.level then parts[#parts+1] = ("Level %d · %s %s"):tformat(i.level, i.subrace or "", i.class or "") end
	if i.zone then parts[#parts+1] = ("%s %s"):format(i.zone, i.zone_level or "") end
	local ago = _M.ago(save.timestamp)
	if ago then parts[#parts+1] = ago end
	if not save.usable then parts[#parts+1] = "#LIGHT_RED#"..(_t"missing addons").."#LAST#"
	elseif save.older_version then parts[#parts+1] = "#YELLOW#"..(_t"older version").."#LAST#" end
	return table.concat(parts, " · ")
end

function _M:thumbIcon(save)
	local t = save.thumb
	if not t then return nil end
	return function(x, y, size) drawThumb(t, x, y, size, size) end
end

function _M:buildCards()
	local function row(save, dead)
		local name = save.name
		if dead then name = "#GREY#"..name.."  #LIGHT_RED#\226\152\160#LAST#" end
		return {name=name, sub=self:rowSub(save), icon=self:thumbIcon(save), data=save, locked=(not self:usable(save)) or dead or false,
			on_tap=function() if self:usable(save) then _M.playEntry(save, self.show_compat, self.force_addons) else self:openSheet(save) end end}
	end
	local secs = {}
	if #self.saves == 0 then
		secs[#secs+1] = {title=_t"Saved characters", items={{name=_t"No saved games"}}, cols=1, row_h=60}
	else
		local items = {}
		for _, s in ipairs(self.others) do items[#items+1] = row(s, false) end
		if #items > 0 then secs[#secs+1] = {title=_t"Other characters", items=items, cols=1, row_h=64, icon_size=48} end
		if #self.fallen > 0 then
			local f = {}
			for _, s in ipairs(self.fallen) do f[#f+1] = row(s, true) end
			secs[#secs+1] = {title=_t"Fallen", items=f, cols=1, row_h=64, icon_size=48}
		end
		if #secs == 0 then secs[#secs+1] = {title=_t"Other characters", items={{name=_t"No other characters"}}, cols=1, row_h=60} end
	end
	self.c_flow:setSections(secs)
	self.c_flow.scrollbar.pos = 0
	self.count = #self.saves
	self:toggleDisplay(self.b_continue, self.hero ~= nil)
	self:toggleDisplay(self.b_more, self.hero ~= nil)
	-- a hero the player cannot load: the button still explains via the sheet
	self.b_continue.text = (self.hero and not self:usable(self.hero)) and _t"Needs addons" or _t"Continue"
	self.b_continue:generate()
end

function _M:playHero()
	if not self.hero then return end
	if self:usable(self.hero) then _M.playEntry(self.hero, self.show_compat, self.force_addons) else self:openSheet(self.hero) end
end

function _M:openSheet(save)
	if not save then return end
	print("[TOUCH] load game: actions for", tostring(save.name))
	game:registerDialog(Sheet.new(save, self))
end

--- kept for the main menu and older callers
function _M:select(save) self:openSheet(save) end
function _M:on_focus() end
function _M:switch() self:refresh() end

function _M:deleteEntry(sel)
	if not sel then return end
	Dialog:yesnoPopup(_t"Delete savefile", ("Really delete #{bold}##GOLD#%s#WHITE##{normal}#"):tformat(sel.name), function(ret)
		if ret then
			local base = Module:setupWrite(sel.mod)
			local save = Savefile.new(sel.base_name)
			save:delete()
			save:close()
			fs.umount(base)
			game.save_list = Module:listSavefiles()
			self:refresh()
		end
	end, _t"Delete", _t"Cancel")
end

function _M:regen()
	self:refresh()
end

local function pill(x, y, label, col, border)
	local d = text(label:upper(), 14, col[1], col[2], col[3], true)
	if not d then return x end
	local w = d.w + 16
	quad(x, y, w, 26, {24, 21, 17})
	frame(x, y, w, 26, border or LINE, 1)
	draw(d, x + 8, y + 3)
	return x + w + 6
end

-- the sheet's own chrome: top row, hero card, section grounds, footer links
function _M:innerDisplayBack(x, y, nb_keyframes)
	x, y = x + self.ix, y + self.iy
	-- top row: title beside the back button, the count at the right
	draw(text(_t"Load character", 22, INK[1], INK[2], INK[3], true), x + 104, y + 12)
	local cnt = text((self.count or 0) == 1 and _t"1 saved" or ("%d saved"):tformat(self.count or 0), 15, MUTED[1], MUTED[2], MUTED[3])
	if cnt then draw(cnt, x + self.iw - cnt.w - 8, y + 18) end

	-- hero card
	local hx, hy, hw, hh = x + self.hero_x, y + self.hero_y, self.hero_w, self.hero_h
	quad(hx, hy, hw, hh, HERO_BG)
	frame(hx, hy, hw, hh, {138, 114, 56}, 2)
	local s = self.hero
	if not s then
		for li, l in ipairs(wrap(_t"No character to continue. Start a new one from the title screen.", font(17), hw - 40, 4)) do
			draw(text(l, 17, MUTED[1], MUTED[2], MUTED[3]), hx + 20, hy + 24 + (li - 1) * 24)
		end
	else
		quad(hx + 1, hy + 1, hw - 2, self.shot_h, {20, 17, 13})
		if s.thumb then drawThumb(s.thumb, hx + 1, hy + 1, hw - 2, self.shot_h) end
		local cy = hy + self.shot_h + 10
		draw(text(s.name, 24, GOLD[1], GOLD[2], GOLD[3], true, hw - 24), hx + 12, cy) cy = cy + 32
		local i = s.info or {}
		local meta = {}
		if i.level then meta[#meta+1] = ("Level %d %s %s"):tformat(i.level, i.subrace or "", i.class or "") end
		if i.zone then meta[#meta+1] = ("%s, level %s"):tformat(i.zone, i.zone_level or "?") end
		draw(text(table.concat(meta, " · "), 16, MUTED[1], MUTED[2], MUTED[3], false, hw - 24), hx + 12, cy) cy = cy + 28
		local px = hx + 12
		if i.difficulty then px = pill(px, cy, i.difficulty, RED, {122, 58, 51}) end
		if i.permadeath then px = pill(px, cy, i.permadeath, MUTED) end
		px = pill(px, cy, i.dead and _t"Dead" or _t"Alive", i.dead and RED or GREEN, i.dead and {122, 58, 51} or {47, 93, 58})
		local ago = _M.ago(s.timestamp)
		if ago then px = pill(px, cy, ago, MUTED) end
		if not s.usable then pill(px, cy, _t"missing addons", RED, {122, 58, 51})
		elseif s.older_version then pill(px, cy, _t"older version", {240, 212, 138}) end
	end

	-- rows ground
	quad(x + self.flow_x, y + self.flow_y, self.flow_w, self.flow_h, {18, 16, 13})

end

function _M:innerDisplay(x, y, nb_keyframes)
	-- a gold frame on Continue so it reads as the main action
	local b = self.ui_by_ui[self.b_continue]
	if b and not b.hidden and self.hero and self:usable(self.hero) then frame(x + b.x - 3, y + b.y - 3, self.b_continue.w + 6, self.b_continue.h + 6, GOLD, 3) end
end
