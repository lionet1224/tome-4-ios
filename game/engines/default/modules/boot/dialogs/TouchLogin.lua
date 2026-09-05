-- ToME iOS port: the te4.org online profile as a touch sheet.
-- Sits in the upper part of the safe area so the on-screen keyboard never covers
-- the fields. Logged out: username / password, Log in, Register, Cancel.
-- Logged in: who you are, a DLC download action, Log out, Close.
-- Login, registration and logout go through the same boot Game / profile calls
-- the desktop MainMenu uses, so their popups and events are unchanged.

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local Button = require "engine.ui.Button"
local Textbox = require "engine.ui.Textbox"
local Textzone = require "engine.ui.Textzone"
local MainMenu = require "mod.dialogs.MainMenu"
local K = require "engine.ui.TouchKit"

module(..., package.seeall, class.inherit(Dialog))

local font, text, draw, quad = K.font, K.text, K.draw, K.quad

function _M:init()
	local sa = require("engine.TouchInput").safeArea()
	local w = math.min(640, math.floor(game.w - sa.l - sa.r - 40))
	self.logged = profile and profile.auth and profile.auth.name or nil
	local h = self.logged and 300 or 380
	-- high on the screen: the keyboard needs the lower half (Dialog.init takes the forced y)
	Dialog.init(self, _t"Online profile", w, h, nil, sa.t + 16)
	self.__touch_login = true
	self.__showup = false

	local bigfont = font(20)
	local uis = {}
	if config.settings.disable_all_connectivity then
		local zone = Textzone.new{width=self.iw - 16, auto_height=true, text=_t"Online features are switched off (Options, Online). Turn them on to use your te4.org profile."}
		self.b_close = Button.new{text=_t"Close", width=self.iw, font=bigfont, fct=function() self:close() end}
		uis[#uis+1] = {left=8, top=8, ui=zone}
		uis[#uis+1] = {left=0, bottom=0, ui=self.b_close}
	elseif self.logged then
		local zone = Textzone.new{width=self.iw - 16, auto_height=true, text=("#GOLD#Logged in as %s#WHITE#\n%s"):tformat(tostring(self.logged),
			core.webview and _t"Owned DLC and addons download from te4.org." or _t"This build cannot download DLC by itself: copy the addon files into the app instead.")}
		local half = math.floor((self.iw - 8) / 2)
		self.b_logout = Button.new{text=_t"Log out", width=half, font=bigfont, fct=function() self:logout() end}
		self.b_close = Button.new{text=_t"Close", width=half, font=bigfont, fct=function() self:close() end}
		uis[#uis+1] = {left=8, top=8, ui=zone}
		if core.webview then
			-- the in-app download needs the web component; without it the note above says what to do
			self.b_dlc = Button.new{text=_t"Download owned addons and DLC", width=self.iw, font=bigfont, fct=function() self:downloadAddons() end}
			uis[#uis+1] = {left=0, bottom=self.b_close.h + 8, ui=self.b_dlc}
		end
		uis[#uis+1] = {left=0, bottom=0, ui=self.b_logout}
		uis[#uis+1] = {left=half + 8, bottom=0, ui=self.b_close}
	else
		local help = Textzone.new{width=self.iw - 16, auto_height=true, text=_t"#GREY#Your te4.org account: profile, vault and achievements. DLC is not downloadable on the phone; its files go into the app build.#WHITE#"}
		self.c_user = Textbox.new{title=_t"Username: ", text="", chars=20, max_len=200, fct=function() self:login() end}
		self.c_pass = Textbox.new{title=_t"Password: ", size_title=self.c_user.title, text="", chars=20, max_len=200, hide=true, fct=function() self:login() end}
		local half = math.floor((self.iw - 8) / 2)
		self.b_login = Button.new{text=_t"Log in", width=half, font=bigfont, fct=function() self:login() end}
		self.b_register = Button.new{text=_t"Register", width=half, font=bigfont, fct=function() self:register() end}
		self.b_close = Button.new{text=_t"Cancel", width=self.iw, font=bigfont, fct=function() self:close() end}
		uis[#uis+1] = {left=8, top=4, ui=help}
		uis[#uis+1] = {left=8, top=help.h + 16, ui=self.c_user}
		uis[#uis+1] = {left=8, top=help.h + 16 + self.c_user.h + 10, ui=self.c_pass}
		uis[#uis+1] = {left=0, bottom=self.b_close.h + 8, ui=self.b_login}
		uis[#uis+1] = {left=half + 8, bottom=self.b_close.h + 8, ui=self.b_register}
		uis[#uis+1] = {left=0, bottom=0, ui=self.b_close}
	end
	self:loadUI(uis)
	self:setupUI(false, true)
	if self.c_user then self:setFocus(self.c_user) end
	self.key:addBinds{ EXIT = function() self:close() end }
end

function _M:close()
	game:unregisterDialog(self)
	-- the title menu shows the login state in its Account card: refresh it
	local d = game.dialogs[#game.dialogs]
	if d and d.__touch_menu and d.on_recover_focus then d:on_recover_focus() end
end

-- the login/logout state changed: show the sheet again in its new state
function _M:rebuild()
	game:unregisterDialog(self)
	game:registerDialog(_M.new())
end

function _M:login()
	local user, pass = self.c_user and self.c_user.text or "", self.c_pass and self.c_pass.text or ""
	if user:len() < 2 then Dialog:simplePopup(_t"Username", _t"Your username is too short") return end
	if pass:len() < 4 then Dialog:simplePopup(_t"Password", _t"Your password is too short") return end
	-- same call as the desktop menu: waits for the answer and pops up the result
	game:createProfile({create=false, login=user, pass=pass})
	if profile and profile.auth then self:rebuild() end
end

function _M:register()
	-- the desktop registration dialog (it does not read self)
	MainMenu.register(self)
end

function _M:logout()
	profile:logOut()
	self:rebuild()
end

function _M:downloadAddons()
	if not core.webview then
		Dialog:simplePopup(_t"Not available", _t"This build has no web component, so it cannot fetch DLC. Copy the .teaa addon files into the app instead.")
		return
	end
	if game.grabAddons then game:grabAddons() end
	Dialog:simplePopup(_t"Addons", _t"Checking your owned addons and DLC. Progress shows in the log at the bottom of the title screen; restart the game once the downloads finish.")
end

function _M:innerDisplayBack(x, y, nb_keyframes)
	x, y = x + self.ix, y + self.iy
	quad(x, y, self.iw, self.ih, K.PANE, 160)
end
