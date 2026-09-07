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
local Dialog = require "engine.ui.Dialog"
local Textzone = require "engine.ui.Textzone"

module(..., package.seeall, class.inherit(Dialog))

function _M:init(what)
	self.what = what

	local f, err = loadfile("/data/texts/unlock-"..self.what..".lua")
	if not f and err then error(err) end
	setfenv(f, {_t=_t})
	self.name, self.str = f()

	game.logPlayer(game.player, "#VIOLET#Option unlocked: %s", self.name)

	if require("engine.TouchInput").active() then return self:initTouch() end

	Dialog.init(self, ("Option unlocked: %s"):tformat(self.name), math.min(math.max(game.w * 0.8, 800), 1200, game.w), 400)

	self.c_desc = Textzone.new{width=math.floor(self.iw - 10), no_color_bleed=true, auto_height=true, text=self.str}

	self:loadUI{
		{left=0, top=0, ui=self.c_desc},
	}
	self:setupUI(true, true)

	self.key:addBinds{
		ACCEPT = accept_key and "EXIT",
		EXIT = function()
			game:unregisterDialog(self)
			if on_exit then on_exit() end
		end,
	}
end

--- iOS port: a sheet that fits the phone: "Unlocked", the name in gold, the text
-- scrollable, a full-width OK. Nothing dismisses it but OK / back.
function _M:initTouch()
	local K = require "engine.ui.TouchKit"
	local Button = require "engine.ui.Button"
	local TextzoneList = require "engine.ui.TextzoneList"
	local TI = require "engine.TouchInput"
	self.touch = true
	self.touch_static_bg = true
	local sa = TI.safeArea()
	local W = math.floor((game.w - (sa.l or 0) - (sa.r or 0)) * (TI.portrait() and 0.94 or 0.7))
	local H = math.floor((game.h - (sa.t or 0) - (sa.b or 0)) * (TI.portrait() and 0.7 or 0.86))
	Dialog.init(self, _t"Unlocked", W, H)
	self.head_h = 56 -- the name line, drawn in innerDisplayBack
	local bh = 60
	local th = self.ih - self.head_h - bh - 16
	self.c_text = TextzoneList.new{width=self.iw - 16, height=th, scrollbar=true, focus_check=true, dest_area={h=th}}
	self.b_ok = Button.new{text=_t"OK", width=self.iw - 16, font=K.font(22), fct=function() self:touchEnd() end}
	self:loadUI{
		{left=8, top=self.head_h, ui=self.c_text},
		{left=0, bottom=0, ui=self.b_ok},
	}
	self:setupUI()
	self.c_text:switchItem(self.str, self.str, true)
	self:setFocus(self.c_text)
	self.key:addBinds{ EXIT = function() self:touchEnd() end, ACCEPT = function() self:touchEnd() end }
end

function _M:touchEnd()
	game:unregisterDialog(self)
end

function _M:touch_reopen()
	return _M.new(self.what)
end

function _M:innerDisplayBack(x, y, nb_keyframes)
	if not self.touch then return end
	local K = require "engine.ui.TouchKit"
	x, y = x + self.ix, y + self.iy
	K.draw(K.text(tostring(self.name or ""), 26, 240, 212, 138, true, self.iw - 16), x + 8, y + 10)
end
