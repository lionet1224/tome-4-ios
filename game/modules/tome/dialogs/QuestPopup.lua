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
local Shader = require "engine.Shader"
local Dialog = require "engine.ui.Dialog"
local Textzone = require "engine.ui.Textzone"
local FontPackage = require "engine.FontPackage"
local Quest = require "engine.Quest"

module(..., package.seeall, class.inherit(Dialog))

local statuses = {
	[-1] = _t"#LIGHT_GREEN#New#LAST# Quest!",
	[Quest.PENDING] = _t"Quest #AQUAMARINE#Updated!",
	[Quest.COMPLETED] = _t"Quest #LIGHT_GREEN#Completed!",
	[Quest.DONE] = _t"Quest #LIGHT_GREEN#Done!",
	[Quest.FAILED] = _t"Quest #CIMSON#Failed!",
}

function _M:init(quest, status)
	-- iOS port: sheet with a status pill, the quest text and two big buttons
	if require("engine.TouchInput").active() then return self:initTouch(quest, status) end
	local use_ui = "quest"
	if quest.use_ui then use_ui = quest.use_ui end
	if status == Quest.FAILED then use_ui = "quest-fail" end
	
	if status == Quest.DONE then
		if use_ui == "quest-escort" then
			if quest.to_zigur then self.dialog_h_middles_alter = {b8 = "ui/antimagic_complete_dialogframe_8_middle.png"}
			else self.dialog_h_middles_alter = {b8 = "ui/normal_complete_dialogframe_8_middle.png"} end
		elseif use_ui == "quest-idchallenge" then self.dialog_h_middles_alter = {b8 = "ui/complete_dialogframe_8_middle.png"}
		elseif use_ui == "quest-main" then self.dialog_h_middles_alter = {b8 = "ui/complete_dialogframe_8_middle.png"}
		elseif use_ui == "quest" then self.dialog_h_middles_alter = {b8 = "ui/complete_dialogframe_8_middle.png"}
		end
	end

	self.quest = quest
	self.ui = use_ui
	Dialog.init(self, "", 666, 150)

	local add = ''
	if quest.popup_text and quest.popup_text[status] then add = quest.popup_text[status].."\n" end

	self.blight = self:getUITexture("ui/dialogframe_backglow.png")

	local f, fs = FontPackage:getFont("bold")
	local quest = Textzone.new{auto_width=true, auto_height=true, text=("#ANTIQUE_WHITE#Quest: #AQUAMARINE#%s"):tformat(self.quest.name), font={f, math.ceil(fs * 2)}}
	quest:setTextShadow(3)
	quest:setShadowShader(Shader.default.textoutline and Shader.default.textoutline.shad, 2)

	local info = Textzone.new{auto_width=true, auto_height=true, text=add.._t'#ANTIQUE_WHITE#(See your Journal for further details or click here)', font={f, math.ceil(fs)}}
	info:setTextShadow(3)
	info:setShadowShader(Shader.default.textoutline and Shader.default.textoutline.shad, 2)
	
	local status = Textzone.new{ui=use_ui, auto_width=true, auto_height=true, text="#cc9f33#"..(statuses[status] or "????"), has_box=true, font={FontPackage:getFont("bignews")}}
	status:setTextShadow(3)
	status:setShadowShader(Shader.default.textoutline and Shader.default.textoutline.shad, 2)
   
	self:loadUI{
		{hcenter=0, top=0, ui=quest},
		{hcenter=0, bottom=quest.h, ui=info},
		{hcenter=0, top=self.h * 1, ignore_size=true, ui=status},
	}
	self:setupUI(false, true)

	self.key:addBinds{
		EXIT = function() game:unregisterDialog(self) end,
		ACCEPT = function() game:unregisterDialog(self) end,
	}
end

-- Any clicks inside will open the journal (desktop); the touch sheet has buttons
function _M:mouseEvent(button, x, y, xrel, yrel, bx, by, event)
	if self.touch then return Dialog.mouseEvent(self, button, x, y, xrel, yrel, bx, by, event) end
	if event ~= "button" or button ~= "left" then return end
	game:unregisterDialog(self)
	if require("engine.TouchInput").active() then game:registerDialog(require("mod.dialogs.TouchJournal").new("quests", self.quest.id))
	else game:registerDialog(require("engine.dialogs.ShowQuests").new(game.party:findMember{main=true}, self.quest.id)) end
end

function _M:drawFrame(x, y, r, g, b, a)
	-- Draw the glow
	if a >= 1 then
		local a = (1 + math.sin(core.game.getTime() / 500)) / 2
		local x = x + self.frame.ox1
		local y = y + self.frame.oy1
		local mw = math.floor(self.frame.w / 2)
		local blhw = math.floor(self.blight.w / 2)
		local blhh = math.floor(self.blight.h / 2)
		local b8hh = math.floor(self.b8.h / 2)
		self.blight.t:toScreenFull(x + mw - blhw, y - blhh + b8hh, self.blight.w, self.blight.h, self.blight.tw, self.blight.th, r, g, b, 0.5 + 0.5 * a)
	end
	
	Dialog.drawFrame(self, x, y, r, g, b, a)
end

---------------------------------------------------------------------------
-- Touch layout
---------------------------------------------------------------------------
local TOUCH_STATUS = {
	[-1] = {_t"New quest", {123, 211, 137}},
	[Quest.PENDING] = {_t"Quest updated", {127, 255, 212}},
	[Quest.COMPLETED] = {_t"Quest completed", {123, 211, 137}},
	[Quest.DONE] = {_t"Quest done", {123, 211, 137}},
	[Quest.FAILED] = {_t"Quest failed", {224, 122, 106}},
}

function _M:openJournal()
	game:unregisterDialog(self)
	if require("engine.TouchInput").active() then game:registerDialog(require("mod.dialogs.TouchJournal").new("quests", self.quest.id))
	else game:registerDialog(require("engine.dialogs.ShowQuests").new(game.party:findMember{main=true}, self.quest.id)) end
end

function _M:initTouch(quest, status)
	self.touch_static_bg = true -- the game under it is frozen (see Game:display)
	local K = require "engine.ui.TouchKit"
	local Button = require "engine.ui.Button"
	local TextzoneList = require "engine.ui.TextzoneList"
	local TI = require "engine.TouchInput"
	self.touch = true
	self.quest = quest
	self.status = status
	self.ui = "quest"

	local sa = TI.safeArea()
	local W = math.min(900, math.floor((game.w - (sa.l or 0) - (sa.r or 0)) * 0.8))
	local maxh = math.floor((game.h - (sa.t or 0) - (sa.b or 0)) * 0.9)
	Dialog.init(self, "", W, maxh)
	self.blight = self:getUITexture("ui/dialogframe_backglow.png")
	local frame_h = self.h - self.ih
	local avail = maxh - frame_h

	-- text: the popup line for this status, then the quest's own description
	local parts = {}
	if quest.popup_text and quest.popup_text[status] then parts[#parts+1] = quest.popup_text[status] end
	local ok, desc = pcall(function() return quest.desc and quest:desc(game.player) end)
	if ok and type(desc) == "string" and desc ~= "" then parts[#parts+1] = desc end
	if #parts == 0 then parts[1] = _t"See your Journal for the details." end
	local txt = table.concat(parts, "\n\n")

	self.head_h = 96
	local bh = 60
	local bigfont = K.font(22)
	local probe = require("engine.ui.Textzone").new{width=self.iw - 16, height=1, auto_height=true, text=txt .. "\n"}
	local desc_h = util.bound(probe.h + 8, 60, avail - self.head_h - bh - 24)
	self.c_desc = TextzoneList.new{width=self.iw - 16, height=desc_h, scrollbar=true, dest_area={h=desc_h}}
	self.c_desc:switchItem(txt, txt)

	local bw = math.floor((self.iw - 16 - 12) / 2)
	self.b_log = Button.new{text=_t"Quest log", width=bw, font=bigfont, fct=function() self:openJournal() end}
	self.b_ok = Button.new{text=_t"Continue", width=bw, font=bigfont, fct=function() game:unregisterDialog(self) end}

	self:loadUI{
		{left=8, top=self.head_h, ui=self.c_desc},
		{left=8, top=self.head_h + desc_h + 12, ui=self.b_log},
		{left=8 + bw + 12, top=self.head_h + desc_h + 12, ui=self.b_ok},
	}
	self:setFocus(self.b_ok)
	self:setupUI(false, true)

	self.key:addBinds{
		EXIT = function() game:unregisterDialog(self) end,
		ACCEPT = function() game:unregisterDialog(self) end,
	}
end

function _M:innerDisplayBack(x, y, nb_keyframes)
	if not self.touch then return end
	local K = require "engine.ui.TouchKit"
	x, y = x + self.ix, y + self.iy
	local st = TOUCH_STATUS[self.status] or {_t"Quest", {200, 195, 180}}
	-- status pill
	local label = K.text(st[1]:upper(), 12, 20, 22, 28, true)
	if label then
		local pw = label.w + 24
		K.quad(x + 8, y + 14, pw, 26, st[2])
		K.draw(label, x + 8 + 12, y + 14 + (26 - label.h) / 2)
	end
	-- quest name in gold
	local name = tostring(self.quest.name or ""):gsub("#[^#]*#", "")
	K.draw(K.text(name, 24, 240, 212, 138, true, self.iw - 16), x + 8, y + 48)
end