-- ToME iOS port: mobile-native message log reader.
-- Replaces mod.dialogs.ShowChatLog on touch: a chip row (Game log + chat
-- channels), the lines in a drag-scrolling TextzoneList opened at the newest
-- entry, a "Newest" jump button and Close. Chat talk (USERCHAT_TALK) still works
-- on a channel chip.

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local Base = require "engine.ui.Base"
local Focusable = require "engine.ui.Focusable"
local Button = require "engine.ui.Button"
local TextzoneList = require "engine.ui.TextzoneList"
local K = require "engine.ui.TouchKit"

module(..., package.seeall, class.inherit(Dialog))

-- how many lines of a log we render at most (each line is a texture)
local MAX_LINES = 400

------------------------------------------------------------------------
-- a single row of chips (same look as the inventory filter chips)
------------------------------------------------------------------------
local Chips = class.inherit(Base, Focusable){}
function Chips:init(t)
	self.items = t.items -- {title=, kind=}
	self.on_change = t.on_change
	self.w, self.h = t.width, 50
	self.cur = t.default or self.items[1].kind
	Base.init(self, t)
end
function Chips:generate()
	self.mouse:reset()
	self.key:reset()
	-- shrink padding, then font, until the row fits
	for _, try in ipairs{{17, 26, 6}, {17, 14, 4}, {16, 12, 4}, {15, 10, 3}} do
		self.size = try[1]
		local x = 0
		for _, it in ipairs(self.items) do
			local d = K.text(it.title, self.size, 255, 255, 255, true)
			local w = (d and d.w or 40) + try[2]
			it.x, it.w = x, w
			x = x + w + try[3]
		end
		if x - try[3] <= self.w then break end
	end
	self.mouse:registerZone(0, 0, self.w, self.h, function(button, x, y, xrel, yrel, bx, by, event)
		if event ~= "button" or button ~= "left" then return end
		for _, it in ipairs(self.items) do
			if x >= it.x and x < it.x + it.w then
				if self.cur ~= it.kind then self.cur = it.kind self.on_change(it.kind) end
				return
			end
		end
	end)
end
function Chips:display(x, y)
	for _, it in ipairs(self.items) do
		local on = it.kind == self.cur
		K.quad(x + it.x, y + 6, it.w, 38, on and K.GOLD or {36, 39, 47})
		local d = on and K.text(it.title, self.size, 28, 20, 15, true) or K.text(it.title, self.size, 184, 178, 158, true)
		if d then K.draw(d, x + it.x + (it.w - d.w) / 2, y + 6 + (38 - d.h) / 2) end
	end
end

------------------------------------------------------------------------
-- the dialog
------------------------------------------------------------------------
function _M:init(title, shadow, log, chat)
	self.log = log or (game.uiset and game.uiset.logdisplay)
	self.chat = chat or profile.chat
	self.no_close_bar = true -- has its own Close button
	Dialog.init(self, title or _t"Message log", game.w * 0.96, game.h * 0.96)

	local bigfont = K.font(22)
	local gap = 8

	-- chips: the game log first, then every chat channel (global last, as the stock dialog orders them)
	local chips = {{title=_t"Game log", kind="__log"}}
	local names = {}
	if self.chat and self.chat.channels then
		for name in pairs(self.chat.channels) do names[#names+1] = name end
		table.sort(names, function(a, b) if a == "global" then return false elseif b == "global" then return true else return a < b end end)
		for _, name in ipairs(names) do
			local nb = 0
			for _ in pairs(self.chat.channels[name].users or {}) do nb = nb + 1 end
			chips[#chips+1] = {title=name:capitalize() .. (nb > 0 and (" (" .. nb .. ")") or ""), kind=name}
		end
	end
	local start = _M.last_tab or "__log"
	local found = false
	for _, c in ipairs(chips) do if c.kind == start then found = true end end
	if not found then start = "__log" end

	self.c_chips = Chips.new{width=self.iw, items=chips, default=start, on_change=function(kind) self:switchTo(kind) end}
	local bh = 56
	local text_h = self.ih - self.c_chips.h - gap - bh - gap
	self.c_text = TextzoneList.new{width=self.iw - 8, height=text_h, scrollbar=true, focus_check=true, dest_area={h=text_h}}
	self.b_newest = Button.new{text=_t"Newest", width=200, font=bigfont, fct=function() self:jumpToNewest() end}
	self.b_close = Button.new{text=_t"Close", width=200, font=bigfont, fct=function() game:unregisterDialog(self) end}

	self:loadUI{
		{left=0, top=0, ui=self.c_chips},
		{left=0, top=self.c_chips.h + gap, ui=self.c_text},
		{left=0, bottom=0, ui=self.b_newest},
		{right=0, bottom=0, ui=self.b_close},
	}
	self:setupUI()
	self:setFocus(self.c_text)

	self.key:addBinds{
		EXIT = function() game:unregisterDialog(self) end,
		ACCEPT = function() game:unregisterDialog(self) end,
		MOVE_UP = function() self:scrollBy(-self.c_text.h / 3) end,
		MOVE_DOWN = function() self:scrollBy(self.c_text.h / 3) end,
		USERCHAT_TALK = function()
			if not self.chat then return end
			if self.cur ~= "__log" then self.chat:setCurrentTarget(true, self.cur) end
			self.chat:talkBox()
		end,
	}
	self.key:addCommands{
		_HOME = function() self.c_text.scrollbar.pos = 0 end,
		_END = function() self:jumpToNewest() end,
		_PAGEUP = function() self:scrollBy(-self.c_text.h) end,
		_PAGEDOWN = function() self:scrollBy(self.c_text.h) end,
	}

	-- chat lines arriving while we read: refresh the open channel
	if self.chat and self.chat.registerTalkEvents then
		self.event_fct = function(e) if e.channel and e.channel == self.cur then self:switchTo(self.cur, true) end end
		self.chat:registerTalkEvents(self.event_fct)
	end

	self:switchTo(start)
end

function _M:unload()
	if self.chat and self.event_fct and self.chat.unregisterTalkEvents then self.chat:unregisterTalkEvents(self.event_fct) end
end

-- oldest first, capped, joined into one block of text
function _M:linesFor(kind)
	local raw
	if kind == "__log" then raw = self.log and self.log:getLog(true) or {}
	else raw = (self.chat and self.chat.channels and self.chat.channels[kind]) and self.chat:getLog(kind, true) or {} end
	local lines = {}
	local first = math.max(1, #raw - MAX_LINES + 1)
	for i = #raw, first, -1 do -- getLog returns newest first
		local e = raw[i]
		local s = type(e) == "table" and e.str or e
		if type(s) == "table" and s.toString then s = s:toString() end
		lines[#lines+1] = tostring(s or "")
	end
	if #lines == 0 then lines[1] = kind == "__log" and _t"#GREY#Nothing has happened yet." or _t"#GREY#No messages on this channel." end
	if #raw > MAX_LINES then table.insert(lines, 1, ("#GREY#(%d older lines not shown)"):format(#raw - MAX_LINES)) end
	return table.concat(lines, "\n")
end

function _M:switchTo(kind, keep_scroll)
	self.cur = kind
	_M.last_tab = kind
	local sb = self.c_text.scrollbar
	local at_bottom = (not keep_scroll) or (sb and sb.max and sb.pos >= sb.max - 2)
	local old = sb and sb.pos or 0
	self.c_text.items = {} -- drop the previous block's textures
	self.c_text.cur_item = 0
	self.c_text:switchItem(kind .. "|" .. tostring(os.time()) .. "|" .. tostring(math.random(1, 1e6)), self:linesFor(kind), true)
	if sb then
		sb.max = math.max(0, sb.max or 0)
		sb.pos = at_bottom and sb.max or util.minBound(old, 0, sb.max)
	end
end

function _M:jumpToNewest()
	local sb = self.c_text.scrollbar
	if sb then sb.pos = math.max(0, sb.max or 0) end
	self.c_text.scroll_inertia = 0
end

function _M:scrollBy(dy)
	local sb = self.c_text.scrollbar
	if sb then sb.pos = util.minBound(sb.pos + dy, 0, math.max(0, sb.max or 0)) end
end

function _M:innerDisplayBack(x, y, nb_keyframes)
	-- a dark pane behind the text so the map does not show through
	local t = self.ui_by_ui[self.c_text]
	if t then K.quad(x + t.x - 4, y + t.y - 4, self.c_text.w + 8, self.c_text.h + 8, {14, 15, 18}, 235) end
end

function _M:innerDisplay(x, y, nb_keyframes)
	-- "Newest" only matters when scrolled up: dim it at the bottom
	local sb = self.c_text.scrollbar
	local b = self.ui_by_ui[self.b_newest]
	if b and sb and (not sb.max or sb.max <= 0 or sb.pos >= sb.max - 2) then
		K.quad(x + b.x, y + b.y, self.b_newest.w, self.b_newest.h, {14, 15, 18}, 150)
	end
end
