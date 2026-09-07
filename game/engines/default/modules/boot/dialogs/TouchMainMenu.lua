-- ToME iOS port: the title screen for fingers.
-- Big cards: Continue (the most recent character), New character, Load game,
-- Options, More (the desktop menu for everything else: addons, credits,
-- profile). A subclass of the desktop MainMenu so the boot Game's
-- isClassName checks, the login helpers and the autopilot hook keep working.

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local MainMenu = require "mod.dialogs.MainMenu"
local Module = require "engine.Module"
local FontPackage = require "engine.FontPackage"
local KeyBind = require "engine.KeyBind"
local K = require "engine.ui.TouchKit"

module(..., package.seeall, class.inherit(MainMenu))

local font, text, draw, quad, frame = K.font, K.text, K.draw, K.quad, K.frame
local GOLD = K.GOLD

function _M:init()
	local w = math.min(600, math.floor(game.w * 0.6))
	local h = math.min(560, math.floor(game.h * 0.94))
	self.no_close_box = true -- the title menu cannot be dismissed: no X
	Dialog.init(self, _t"Tales of Maj'Eyal", w, h)
	self.__showup = false
	self.__main_menu = true
	self.__touch_menu = true

	-- the desktop entries, kept as functions so the autopilot and "More" reuse them
	local l = {}
	self.list = l
	l[#l+1] = {name=_t"New Game", fct=function() game:registerDialog(require("mod.dialogs.NewGame").new()) end}
	l[#l+1] = {name=_t"Load Game", fct=function() game:registerDialog(require("mod.dialogs.TouchLoadGame").new()) end}
	l[#l+1] = {name=_t"Options", fct=function() self:openOptions() end}
	l[#l+1] = {name=_t"More", fct=function() game:registerDialog(MainMenu.new()) end}

	self:setupAutopilot(l[1].fct)

	-- the most recent character, for Continue
	self.last_save = nil
	local ok, saves = pcall(function() return require("mod.dialogs.TouchLoadGame").scan(false) end)
	if ok and saves then
		for _, s in ipairs(saves) do if s.usable then self.last_save = s break end end
	end

	self.c_flow = K.Flow.new{width=self.iw, height=self.ih - 24}
	self:loadUI{
		{left=0, top=0, ui=self.c_flow},
	}
	self:setupUI(false, true)
	self:setFocus(self.c_flow)
	self:buildCards()

	self.key:addBind("LUA_CONSOLE", function()
		if config.settings.cheat then game:registerDialog(require("engine.DebugConsole").new()) end
	end)
	self.key:addBind("SCREENSHOT", function() game:saveScreenshot() end)
	KeyBind:load("chat")
	self.key:bindKeys()
	self.key:addBind("USERCHAT_TALK", function() profile.chat:talkBox(nil, true) end)
end

function _M:buildCards()
	local TL = require "mod.dialogs.TouchLoadGame"
	local secs = {}
	local s = self.last_save
	if s then
		local i = s.info or {}
		local parts = {}
		if i.level then parts[#parts+1] = ("Level %d %s %s"):tformat(i.level, i.subrace or "", i.class or "") end
		if i.zone then parts[#parts+1] = ("%s %s"):format(i.zone, i.zone_level or "") end
		local ago = TL.ago(s.timestamp)
		if ago then parts[#parts+1] = ago end
		local icon
		if s.thumb then
			local t = s.thumb
			icon = function(x, y, size)
				local w, h = size, math.floor(size * t.h / t.w)
				if h > size then h = size w = math.floor(size * t.w / t.h) end
				t[1]:toScreenFull(x, y + (size - h) / 2, w, h, t[2] * w / t.w, t[3] * h / t.h)
			end
		end
		secs[#secs+1] = {title=_t"Continue", items={
			{name=s.name, sub=table.concat(parts, " · "), icon=icon, sel=true, data=s, on_tap=function() TL.playEntry(s) end},
		}, cols=1, row_h=96, icon_size=80}
	end
	local main = {
		{name=_t"New character", sub=_t"Start a new adventure", on_tap=function() self.list[1].fct() end},
		{name=_t"Load game", sub=_t"All saved characters", on_tap=function() self.list[2].fct() end},
		{name=_t"Options", sub=_t"Touch, video, sound, keys", on_tap=function() self.list[3].fct() end},
		{name=_t"More", sub=_t"Addons, credits, profile", on_tap=function() self.list[4].fct() end},
	}
	secs[#secs+1] = {title=s and _t"Or" or _t"Play", items=main, cols=2, row_h=76, center=true}
	-- te4.org profile: the touch login sheet (DLC needs it)
	local who
	if config.settings.disable_all_connectivity then who = _t"Online features are off"
	elseif profile and profile.auth and profile.auth.name then who = (_t"Logged in as %s"):tformat(tostring(profile.auth.name))
	else who = _t"Log in to te4.org for DLC and the vault" end
	secs[#secs+1] = {title=_t"Account", items={
		{name=_t"Online profile", sub=who, on_tap=function() game:registerDialog(require("mod.dialogs.TouchLogin").new()) end},
		{name=_t"Backups", sub=_t"Back up and restore your saves", on_tap=function() game:registerDialog(require("engine.dialogs.TouchBackups").new(false)) end},
	}, cols=1, row_h=64, center=true}
	self.c_flow:setSections(secs)
end

-- the same options list as the desktop menu
function _M:openOptions()
	local list = {
		"resume",
		"keybinds_all",
		{_t"Game Options", function()
			local mod = Module:listModules().tome
			if not mod then return end
			local allmounts = fs.getSearchPath(true)
			if not mod.team then fs.mount(fs.getRealPath(mod.dir), "/mod", false)
			else fs.mount(fs.getRealPath(mod.team), "/", false) end
			local d = require("mod.dialogs.GameOptions").new()
			function d:unload()
				fs.reset()
				fs.mountAll(allmounts)
			end
			game:registerDialog(d)
		end},
		"language",
		"video",
		"sound",
		"cheatmode", -- (no Steam entry: nothing behind it on iOS)
	}
	game:registerDialog(require("engine.dialogs.GameMenu").new(list))
end

function _M:innerDisplayBack(x, y, nb_keyframes)
	x, y = x + self.ix, y + self.iy
	-- engine version, small, bottom left
	draw(text(("T-Engine4 %d.%d.%d"):format(engine.version[1], engine.version[2], engine.version[3]), 11, 142, 136, 120), x + 4, y + self.ih - 16)
	if profile and profile.auth and profile.auth.name then
		local d = text(("%s"):format(tostring(profile.auth.name)), 11, 142, 136, 120, false, self.iw / 2)
		if d then draw(d, x + self.iw - d.w - 4, y + self.ih - 16) end
	end
end

-- profile / connection events rebuild the desktop menu; do the same here
function _M:on_recover_focus()
	game:unregisterDialog(self)
	game:registerDialog(new())
end

function _M:updateUI() end
