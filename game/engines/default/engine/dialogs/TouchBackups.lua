-- ToME iOS port: "Backups" — save backups the player can carry out of the app.
-- Saves live only inside the app container; a sideloaded build that expires or
-- is deleted takes them along. This screen zips the whole save/ tree into
-- backups/tome-saves-YYYYMMDD-HHMM.zip (visible in the Files app once the app's
-- Documents folder is shared), lists the backups newest first, and offers
-- Restore / Details / Delete from a long-press or a tap on a card.
-- Lives in the engine so both the title menu (boot module) and the in-game
-- Options can open it.

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local Button = require "engine.ui.Button"
local Module = require "engine.Module"
local K = require "engine.ui.TouchKit"

module(..., package.seeall, class.inherit(Dialog))

local font, text, draw, quad, frame = K.font, K.text, K.draw, K.quad, K.frame
local GOLD, PANE = K.GOLD, K.PANE
local INK = {236, 225, 200}
local MUTED = {154, 143, 122}
local RED = {224, 138, 130}
local LINE = {58, 51, 41}

local BACKUP_DIR = "/backups"
local RESTORE_MOUNT = "/restore-tmp"

---------------------------------------------------------------------------
-- module directory: in game the write path already is the game module's; from
-- the title menu it is the boot module's, so the game module's is mounted for
-- the duration of an operation
---------------------------------------------------------------------------

local function gameModule()
	local mods = Module:listModules()
	return mods and mods.tome
end

--- Run fct with the game module's user directory mounted as the write path
local function withGameDir(fct)
	if game and game.__mod_info and game.__mod_info.short_name ~= "boot" then return fct() end
	local mod = gameModule()
	if not mod then return nil, "game module not found" end
	local prev = fs.getWritePath()
	local base = Module:setupWrite(mod)
	local ok, a, b = pcall(fct)
	fs.umount(base)
	if prev then fs.setWritePath(prev) end
	if not ok then return nil, tostring(a) end
	return a, b
end

---------------------------------------------------------------------------
-- file helpers (PhysFS paths)
---------------------------------------------------------------------------

local function readAll(path)
	local f = fs.open(path, "r")
	if not f then return nil end
	local data = f:read()
	f:close()
	return data or ""
end

local function writeAll(path, data)
	local f = fs.open(path, "w")
	if not f then return false end
	f:write(data)
	f:close()
	return true
end

--- Every file under dir, as {rel=relative path, path=full path}
local function walk(dir, rel, out)
	out = out or {}
	rel = rel or ""
	for _, name in ipairs(fs.list(dir) or {}) do
		local p = dir.."/"..name
		local r = (rel == "") and name or (rel.."/"..name)
		if fs.isdir(p) then walk(p, r, out) else out[#out+1] = {rel=r, path=p} end
	end
	return out
end

--- Backups in the backup dir, newest first: {file=, name=, stamp=, when=}
function _M.listBackups()
	local out = {}
	if not fs.exists(BACKUP_DIR) then return out end
	for _, name in ipairs(fs.list(BACKUP_DIR) or {}) do
		local y, mo, d, h, mi = name:match("^tome%-saves%-(%d%d%d%d)(%d%d)(%d%d)%-(%d%d)(%d%d)%.zip$")
		if y then
			local stamp = os.time{year=tonumber(y), month=tonumber(mo), day=tonumber(d), hour=tonumber(h), min=tonumber(mi)}
			out[#out+1] = {file=name, stamp=stamp, when=("%s-%s-%s %s:%s"):format(y, mo, d, h, mi)}
		elseif name:find("%.zip$") then
			out[#out+1] = {file=name, stamp=0, when=name}
		end
	end
	table.sort(out, function(a, b) return a.stamp > b.stamp end)
	return out
end

local function ago(ts)
	if not ts or ts == 0 then return nil end
	local d = os.time() - ts
	if d < 90 then return _t"just now" end
	if d < 3600 then return ("%d min ago"):tformat(math.floor(d / 60)) end
	if d < 86400 then return ("%d h ago"):tformat(math.floor(d / 3600)) end
	if d < 86400 * 14 then return ("%d days ago"):tformat(math.floor(d / 86400)) end
	return ("%d weeks ago"):tformat(math.floor(d / (86400 * 7)))
end

--- Zip the whole save/ tree into a new backup. Returns the file name, or nil + why.
function _M.doBackup()
	return withGameDir(function()
		if not fs.exists("/save") then return nil, _t"No saves yet." end
		if not fs.exists(BACKUP_DIR) then fs.mkdir(BACKUP_DIR) end
		local name = os.date("tome-saves-%Y%m%d-%H%M.zip")
		-- fs.zipOpen goes through PhysFS (the save writer hands it "/vault/..." paths), so it
		-- takes a virtual path inside the write dir, not a disk path
		local zpath = BACKUP_DIR.."/"..name
		local zip = fs.zipOpen(zpath)
		print("[BACKUP] zip", zpath, "opened", tostring(zip ~= nil))
		if not zip then return nil, "could not create the zip at "..zpath end
		local files = walk("/save", "save")
		local n = 0
		for i, f in ipairs(files) do
			-- skip the pipe's temporary files; the save zips are already compressed, so store them
			if not f.rel:find("%.tmp$") then
				local data = readAll(f.path)
				if data then zip:add(f.rel, data, 1) n = n + 1 end
			end
		end
		zip:close()
		print("[TOUCH] backup written", name, n, "files")
		return name, n
	end)
end

--- The characters inside a backup: {{name=, description=}}
function _M.backupContents(file)
	return withGameDir(function()
		local real = fs.getRealPath(BACKUP_DIR.."/"..file)
		if not real then return nil, "backup not found" end
		fs.mount(real, RESTORE_MOUNT, false)
		local chars = {}
		for _, dir in ipairs(fs.list(RESTORE_MOUNT.."/save", true) or {}) do
			local desc = Module:loadSavefileDescription(RESTORE_MOUNT.."/save/"..dir)
			if desc then chars[#chars+1] = {name=desc.name or dir, description=desc.description or "", short_name=dir} end
		end
		fs.umount(real)
		table.sort(chars, function(a, b) return tostring(a.name) < tostring(b.name) end)
		return chars
	end)
end

--- Copy every file of the backup back under save/ (overwriting). Returns the file count.
function _M.restoreBackup(file)
	return withGameDir(function()
		local real = fs.getRealPath(BACKUP_DIR.."/"..file)
		if not real then return nil, "backup not found" end
		fs.mount(real, RESTORE_MOUNT, false)
		if not fs.exists("/save") then fs.mkdir("/save") end
		local files = walk(RESTORE_MOUNT.."/save", "")
		local n = 0
		for i, f in ipairs(files) do
			local data = readAll(f.path)
			if data then
				-- make the directories of f.rel under /save
				local cur = "/save"
				local parts = {}
				for part in f.rel:gmatch("[^/]+") do parts[#parts+1] = part end
				for j = 1, #parts - 1 do
					cur = cur.."/"..parts[j]
					if not fs.exists(cur) then fs.mkdir(cur) end
				end
				if writeAll("/save/"..f.rel, data) then n = n + 1 end
			end
		end
		fs.umount(real)
		print("[TOUCH] backup restored", file, n, "files")
		return n
	end)
end

function _M.deleteBackup(file)
	return withGameDir(function()
		fs.delete(BACKUP_DIR.."/"..file)
		return true
	end)
end

---------------------------------------------------------------------------
-- the actions sheet: Restore / Details / Delete for one backup
---------------------------------------------------------------------------

local Sheet = class.inherit(Dialog){}

function Sheet:init(entry, owner)
	self.entry, self.owner = entry, owner
	local TI = require "engine.TouchInput"
	local sa = TI.safeArea()
	local w = math.min(game.w - sa.l - sa.r - 20, 640)
	local bw, bh, gap = w - 16 - 16, 52, 8
	self.in_game = owner.in_game
	local restore_txt = self.in_game and (_t"Restore (from the title screen)") or _t"Restore"
	self.b_restore = Button.new{text=restore_txt, width=bw, font=font(22), fct=function() self:doRestore() end}
	self.b_details = Button.new{text=_t"Details", width=bw, font=font(19), fct=function() self:doDetails() end}
	self.b_delete = Button.new{text="#LIGHT_RED#"..(_t"Delete"), width=bw, font=font(19), fct=function() self:doDelete() end}
	self.head_h = 64
	local h = 8 + self.head_h + 3 * (bh + gap) + 16
	self.no_close_box = true
	Dialog.init(self, nil, w, h, sa.l + math.floor((game.w - sa.l - sa.r - w) / 2), game.h - sa.b - h - 8)
	self.__backup_sheet = true
	self:loadUI{
		{left=8, top=self.head_h, ui=self.b_restore},
		{left=8, top=self.head_h + bh + gap, ui=self.b_details},
		{left=8, top=self.head_h + 2 * (bh + gap), ui=self.b_delete},
	}
	self:setupUI(false, true)
	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end }
end

function Sheet:close() game:unregisterDialog(self) end

function Sheet:doRestore()
	local e = self.entry
	self:close()
	if self.in_game then
		Dialog:simplePopup(_t"Restore", _t"Restoring replaces the saves of the character you are playing. Quit to the title screen and restore from there.")
		return
	end
	Dialog:yesnoLongPopup(_t"Restore backup", (_t"This replaces your current saves with the backup from %s. Continue?"):format(e.when), math.floor(game.w * 0.85), function(ret)
		if not ret then return end
		local popup = Dialog:simpleWaiter(_t"Restoring", _t"Please wait while the saves are restored...")
		local n, err = _M.restoreBackup(e.file)
		popup:done()
		if not n then Dialog:simplePopup(_t"Restore failed", tostring(err))
		else
			if game.save_list ~= nil and Module.listSavefiles then game.save_list = Module:listSavefiles() end
			Dialog:simplePopup(_t"Restored", (_t"%d files restored. The characters are back in Load game."):format(n))
		end
	end, _t"Restore", _t"Cancel")
end

function Sheet:doDetails()
	local e = self.entry
	self:close()
	local chars, err = _M.backupContents(e.file)
	local lines = {}
	if not chars then lines[1] = tostring(err)
	elseif #chars == 0 then lines[1] = _t"No characters in this backup."
	else
		for _, c in ipairs(chars) do
			lines[#lines+1] = ("#GOLD#%s#LAST#"):format(tostring(c.name))
			local first = tostring(c.description):match("[^\n]*") or ""
			if first ~= "" then lines[#lines+1] = first end
			lines[#lines+1] = ""
		end
	end
	Dialog:simpleLongPopup((_t"Backup %s"):format(e.when), table.concat(lines, "\n"), math.floor(game.w * 0.85))
end

function Sheet:doDelete()
	local e = self.entry
	self:close()
	Dialog:yesnoPopup(_t"Delete backup", (_t"Really delete the backup from %s?"):format(e.when), function(ret)
		if ret then _M.deleteBackup(e.file) self.owner:refresh() end
	end, _t"Delete", _t"Cancel")
end

function Sheet:innerDisplayBack(x, y, nb_keyframes)
	quad(x, y, self.w, self.h, {26, 23, 19})
	frame(x, y, self.w, self.h, {138, 114, 56}, 1)
	x, y = x + self.ix, y + self.iy
	draw(text(self.entry.when, 22, GOLD[1], GOLD[2], GOLD[3], true, self.iw - 16), x + 8, y + 6)
	local a = ago(self.entry.stamp)
	draw(text(a and (_t"made %s"):format(a) or self.entry.file, 15, MUTED[1], MUTED[2], MUTED[3], false, self.iw - 16), x + 8, y + 36)
end

function Sheet:innerDisplay(x, y, nb_keyframes)
	local b = self.ui_by_ui[self.b_restore]
	if b and not self.in_game then frame(x + b.x - 3, y + b.y - 3, self.b_restore.w + 6, self.b_restore.h + 6, GOLD, 3) end
end

---------------------------------------------------------------------------
-- the screen
---------------------------------------------------------------------------

function _M:init(in_game)
	self.in_game = in_game and true or false
	local TI = require "engine.TouchInput"
	local sa = TI.safeArea()
	self.portrait = TI.portrait()
	self.no_close_box = true
	Dialog.init(self, nil, game.w - sa.l - sa.r - 10, game.h - sa.t - sa.b - 40)
	self.__touch_backups = true

	self.top_h = 52
	self.hint_h = 6
	self.b_back = Button.new{text=_t"< Back", width=90, font=font(18), fct=function() game:unregisterDialog(self) end}
	self.b_backup = Button.new{text=_t"Back up now", width=self.iw - 24 - 16, font=font(22), fct=function() self:backupNow() end}
	self.flow_x = 0
	self.flow_y = self.top_h + self.hint_h + self.b_backup.h + 16
	self.flow_w, self.flow_h = self.iw, self.ih - self.flow_y
	self.c_flow = K.Flow.new{width=self.flow_w, height=self.flow_h}

	self:loadUI{
		{left=0, top=4, ui=self.b_back},
		{left=12, top=self.top_h + self.hint_h, ui=self.b_backup},
		{left=self.flow_x, top=self.flow_y, ui=self.c_flow},
	}
	self:setupUI(false, true)
	self:setFocus(self.c_flow)

	-- a long-press on a card opens its sheet (a tap does too)
	self.prev_on_hold = TI.on_hold
	TI.on_hold = function(x, y)
		local d = game.dialogs[#game.dialogs]
		if d ~= self then return false end
		local e = self:entryAt(x, y)
		if not e then return false end
		self:openSheet(e)
		return true
	end

	self:refresh()
	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end }
end

function _M:unload()
	local TI = require "engine.TouchInput"
	if TI.on_hold and self.prev_on_hold ~= TI.on_hold then TI.on_hold = self.prev_on_hold end
end

function _M:touch_reopen()
	return _M.new(self.in_game)
end

--- The backup under a screen point, from where the Flow last drew its cards
function _M:entryAt(sx, sy)
	local fl = self.c_flow
	if not fl.last_screen_x then return nil end
	local fx, fy = sx - fl.last_screen_x, sy - fl.last_screen_y + (fl.scrollbar.pos or 0)
	if fx < 0 or fx >= fl.w or sy < fl.last_screen_y or sy >= fl.last_screen_y + fl.h then return nil end
	for _, sec in ipairs(fl.sections or {}) do
		for _, it in ipairs(sec.items) do
			if it.data and fx >= it.x and fx < it.x + it.w and fy >= it.y and fy < it.y + it.h then return it.data end
		end
	end
	return nil
end

function _M:refresh()
	self.backups = withGameDir(function() return _M.listBackups() end) or {}
	local items = {}
	for _, e in ipairs(self.backups) do
		local a = ago(e.stamp)
		items[#items+1] = {name=e.when, sub=a or e.file, data=e, on_tap=function() self:openSheet(e) end}
	end
	local secs = {}
	if #items > 0 then
		secs[#secs+1] = {title=_t"Backups", items=items, cols=1, row_h=64}
	else
		secs[#secs+1] = {title=_t"Backups", items={{name=_t"No backups yet"}}, cols=1, row_h=60}
	end
	self.c_flow:setSections(secs)
end

function _M:openSheet(e)
	if not e then return end
	print("[TOUCH] backups: actions for", tostring(e.file))
	game:registerDialog(Sheet.new(e, self))
end

function _M:backupNow()
	local popup = Dialog:simpleWaiter(_t"Backing up", _t"Please wait while the saves are zipped...")
	local name, n = _M.doBackup()
	popup:done()
	if not name then Dialog:simplePopup(_t"Backup failed", tostring(n)) return end
	self:refresh()
	Dialog:simplePopup(_t"Backed up", (_t"%d files written to %s. Copy it out of the app's folder in the Files app to keep it safe."):format(n or 0, name))
end

function _M:innerDisplayBack(x, y, nb_keyframes)
	x, y = x + self.ix, y + self.iy
	draw(text(_t"Backups", 24, INK[1], INK[2], INK[3], true, self.iw - 220), x + 104, y + 12)
	local count = text(("%d"):format(#(self.backups or {})), 15, MUTED[1], MUTED[2], MUTED[3])
	if count then draw(count, x + self.iw - count.w - 8, y + 18) end
	quad(x + self.flow_x, y + self.flow_y, self.flow_w, self.flow_h, {18, 16, 13})
end

function _M:innerDisplay(x, y, nb_keyframes)
	local b = self.ui_by_ui[self.b_backup]
	if b then frame(x + b.x - 3, y + b.y - 3, self.b_backup.w + 6, self.b_backup.h + 6, GOLD, 3) end
end
