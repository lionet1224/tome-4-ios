-- ToME iOS port: mobile-native NPC conversation.
-- Same logic as engine.dialogs.Chat (answers, conditions, jumps, actions, regen);
-- only the widgets change: portrait column, scrolling speech, answer cards.

require "engine.class"
local Chat = require "engine.dialogs.Chat"
local Dialog = require "engine.ui.Dialog"
local Base = require "engine.ui.Base"
local Focusable = require "engine.ui.Focusable"
local Slider = require "engine.ui.Slider"
local Textzone = require "engine.ui.Textzone"
local TextzoneList = require "engine.ui.TextzoneList"
local Tiles = require "engine.Tiles"
local K = require "engine.ui.TouchKit"

module(..., package.seeall, class.inherit(Chat))

local GOLD, CARD, PANE = K.GOLD, K.CARD, K.PANE
local font, text, draw, quad, frame, circle, wrap = K.font, K.text, K.draw, K.quad, K.frame, K.circle, K.wrap

---------------------------------------------------------------------------
-- Answers: full-width cards, a letter badge and the answer wrapped on up to
-- three lines; one pixel scroller so a finger drag scrolls it
---------------------------------------------------------------------------
local Answers = class.inherit(Base, Focusable){}
local ANS_FONT, LINE_H, PAD, GAP, BADGE = 17, 22, 12, 8, 30

function Answers:init(t)
	self.w = t.width
	self.h = t.height or 60
	self.on_use = t.on_use
	self.items = {}
	self.content_h = 0
	self.scrollbar = Slider.new{size=self.h, max=1}
	self.scroll_inertia = 0
	Base.init(self, t)
end

function Answers:generate()
	self.mouse:reset()
	self.key:reset()
	self.scrollbar = Slider.new{size=self.h, max=1}
	self.scroll_inertia = 0
	self:layout()
	self.mouse:registerZone(0, 0, self.w, self.h, function(button, x, y, xrel, yrel, bx, by, event)
		if event == "button" and button == "wheelup" then self.scroll_inertia = math.min(self.scroll_inertia, 0) - 5 return
		elseif event == "button" and button == "wheeldown" then self.scroll_inertia = math.max(self.scroll_inertia, 0) + 5 return end
		if event ~= "button" or button ~= "left" then return end
		local sy = y + self.scrollbar.pos
		for _, it in ipairs(self.items) do
			if sy >= it.y and sy < it.y + it.h then
				if self.on_use then self.on_use(it) end
				return
			end
		end
	end)
	self.key:addBinds{
		ACCEPT = function() local it = self.items[self.sel or 1] if it and self.on_use then self.on_use(it) end end,
		MOVE_UP = function() self.sel = math.max(1, (self.sel or 1) - 1) end,
		MOVE_DOWN = function() self.sel = math.min(#self.items, (self.sel or 0) + 1) end,
	}
end

-- list entries come from Chat:generateList: {name="a) text", answer=i, color=}
function Answers:setList(list)
	self.items = {}
	for i, e in ipairs(list) do
		local letter, body = tostring(e.name):match("^(%a)%)%s*(.*)$")
		self.items[#self.items+1] = {name=e.name, answer=e.answer, color=e.color, letter=letter or tostring(i), body=body or tostring(e.name)}
	end
	self.sel = 1
	self:layout()
end

function Answers:layout()
	local f = font(ANS_FONT)
	local maxw = self.w - PAD * 2 - BADGE - 12
	local y = 0
	for _, it in ipairs(self.items) do
		it.lines = wrap((it.body:gsub("#[^#]*#", "")), f, maxw, 3)
		if #it.lines == 0 then it.lines = {""} end
		it.h = math.max(60, PAD * 2 + #it.lines * LINE_H - 4)
		it.y = y
		y = y + it.h + GAP
	end
	self.content_h = math.max(0, y - GAP)
	if self.scrollbar then
		self.scrollbar.max = math.max(0, self.content_h - self.h)
		self.scrollbar.pos = util.minBound(self.scrollbar.pos or 0, 0, self.scrollbar.max)
	end
end

function Answers:setHeight(h)
	self.h = math.max(60, math.floor(h))
	self.scrollbar = Slider.new{size=self.h, max=1}
	self:layout()
	self.mouse:reset()
	self.mouse:registerZone(0, 0, self.w, self.h, function(button, x, y, xrel, yrel, bx, by, event)
		if event == "button" and button == "wheelup" then self.scroll_inertia = math.min(self.scroll_inertia, 0) - 5 return
		elseif event == "button" and button == "wheeldown" then self.scroll_inertia = math.max(self.scroll_inertia, 0) + 5 return end
		if event ~= "button" or button ~= "left" then return end
		local sy = y + self.scrollbar.pos
		for _, it in ipairs(self.items) do
			if sy >= it.y and sy < it.y + it.h then
				if self.on_use then self.on_use(it) end
				return
			end
		end
	end)
end

function Answers:display(x, y, nb_keyframes, screen_x, screen_y)
	self.last_screen_x, self.last_screen_y = screen_x, screen_y
	self.scrollbar.pos = util.minBound(self.scrollbar.pos + self.scroll_inertia, 0, self.scrollbar.max)
	if self.scroll_inertia > 0 then self.scroll_inertia = math.max(self.scroll_inertia - 1, 0)
	elseif self.scroll_inertia < 0 then self.scroll_inertia = math.min(self.scroll_inertia + 1, 0) end
	local oy = y - self.scrollbar.pos
	core.display.glScissor(true, screen_x, screen_y, self.w, self.h)
	for i, it in ipairs(self.items) do
		local iy = oy + it.y
		if iy + it.h > y and iy < y + self.h then
			quad(x, iy, self.w, it.h, CARD)
			if i == self.sel and self.focused then frame(x, iy, self.w, it.h, GOLD, 2) end
			-- letter badge
			local cx, cy = x + PAD + BADGE / 2, iy + it.h / 2
			circle(cx, cy, BADGE / 2, GOLD, 1, BADGE / 2 - 2)
			local l = text(it.letter, 14, 240, 212, 138, true)
			if l then draw(l, cx - l.w / 2, cy - l.h / 2) end
			-- the answer
			local tx = x + PAD + BADGE + 12
			local ty = iy + (it.h - #it.lines * LINE_H) / 2
			local r, g, b = 234, 227, 209
			if it.color then r, g, b = it.color[1] or r, it.color[2] or g, it.color[3] or b end
			for li, line in ipairs(it.lines) do
				draw(text(line, ANS_FONT, r, g, b, false, self.w - (tx - x) - PAD), tx, ty + (li - 1) * LINE_H)
			end
		end
	end
	core.display.glScissor(false)
	if self.scrollbar.max > 0 then
		local frac = self.h / math.max(1, self.content_h)
		local bh = math.max(20, self.h * frac)
		local by = (self.h - bh) * (self.scrollbar.pos / self.scrollbar.max)
		quad(x + self.w - 4, y + by, 3, bh, {120, 120, 120}, 120)
	end
end

---------------------------------------------------------------------------
-- The dialog
---------------------------------------------------------------------------
_M.portrait_w = 210

function _M:init(chat, id, width)
	self.force_width = width
	self.cur_id = id
	self.chat = chat
	self.npc = chat.npc
	self.player = chat.player
	self.no_offscreen = "bottom"
	self.no_close_box = true -- a conversation must be answered; the box would do nothing
	self.tiles = Tiles.new(64, 64, nil, nil, true, nil)

	local TI = require "engine.TouchInput"
	local sa = TI.safeArea()
	local W = math.floor((game.w - (sa.l or 0) - (sa.r or 0)) * 0.96)
	local maxh = math.floor((game.h - (sa.t or 0) - (sa.b or 0)) * 0.94)
	local name = self.npc.getName and self.npc:getName() or self.npc.name
	Dialog.init(self, name, W, maxh)
	local frame_h = self.h - self.ih
	local avail = maxh - frame_h

	self:generateList()

	local gap = 12
	local rw = self.iw - self.portrait_w - gap

	-- answers first: they must always be reachable; the speech takes the rest and scrolls
	self.c_answers = Answers.new{width=rw, height=60, on_use=function(item) self:use(item) end}
	self.c_answers:setList(self.list)
	local ans_max = math.floor(avail * 0.6)
	local ans_h = math.min(self.c_answers.content_h, ans_max)

	local probe = Textzone.new{font=chat.dialog_text_font, width=rw, height=1, auto_height=true, text=self.text .. "\n"}
	local desc_h = math.min(probe.h + 8, avail - ans_h - gap)
	-- keep room for the portrait column even on a one-liner
	desc_h = math.max(desc_h, math.min(avail - ans_h - gap, 230 - ans_h - gap), 60)
	self.c_desc = TextzoneList.new{font=chat.dialog_text_font, width=rw, height=desc_h, scrollbar=true, dest_area={h=desc_h}}
	self.c_desc:switchItem(self.text, self.text)
	self.c_answers:setHeight(math.min(self.c_answers.content_h, avail - desc_h - gap))

	self:loadUI{
		{left=self.portrait_w + gap, top=0, ui=self.c_desc},
		{left=self.portrait_w + gap, top=desc_h + gap, ui=self.c_answers},
	}
	self:setFocus(self.c_answers)
	self:setupUI(false, true)

	self.key:addCommands{
		__TEXTINPUT = function(c)
			if self.list and self.list.chars[c] then
				self:use(self.list[self.list.chars[c]])
			end
		end,
	}
end

-- a new node = a new dialog of this class (the stock regen builds an engine Chat)
function _M:regen()
	local d = _M.new(self.chat, self.cur_id, self.force_width)
	d.__showup = false
	game:replaceDialog(self, d)
	self.next_dialog = d
end

function _M:innerDisplayBack(x, y, nb_keyframes)
	x, y = x + self.ix, y + self.iy
	local pw = self.portrait_w
	quad(x, y, pw, self.ih, PANE)
	-- the speaker
	local sz = math.min(160, pw - 24, self.ih - 60)
	local px, py = x + (pw - sz) / 2, y + 12
	quad(px - 4, py - 4, sz + 8, sz + 8, {14, 15, 18})
	local who = self.npc.chat_display_entity or self.npc
	pcall(who.toScreen, who, self.tiles, px, py, sz, sz)
	local name = self.npc.getName and self.npc:getName() or self.npc.name
	local ny = py + sz + 10
	for li, line in ipairs(wrap((tostring(name):gsub("#[^#]*#", "")), font(16), pw - 16, 2)) do
		local d = text(line, 16, 240, 212, 138, true, pw - 16)
		if d then draw(d, x + (pw - d.w) / 2, ny + (li - 1) * 20) end
	end
	-- you, small, at the bottom of the column
	if self.ih >= sz + 140 then
		local you = self.player.chat_display_entity or self.player
		local ys = 56
		local yx, yy = x + (pw - ys) / 2, y + self.ih - ys - 26
		pcall(you.toScreen, you, self.tiles, yx, yy, ys, ys)
		local d = text(_t"You", 12, 142, 136, 120, true)
		if d then draw(d, x + (pw - d.w) / 2, yy + ys + 4) end
	end
end
