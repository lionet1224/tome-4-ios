-- ToME - Tales of Maj'Eyal
-- iOS port: side-by-side comparison of an item with what is worn in its slot.

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local Button = require "engine.ui.Button"
local Textzone = require "engine.ui.Textzone"
local TextzoneList = require "engine.ui.TextzoneList"
local Separator = require "engine.ui.Separator"
local FontPackage = require "engine.FontPackage"
local Base = require "engine.ui.Base"
local Focusable = require "engine.ui.Focusable"

module(..., package.seeall, class.inherit(Dialog))

------
-- the compare card: item header + stat table (new | worn)
------------------------------------------------------------------------
local Card = class.inherit(Base, Focusable){}
local STATS = {
	{k="dam", n=_t"Damage", get=function(o) return o.combat and o.combat.dam end},
	{k="apr", n=_t"Armour pen.", get=function(o) return o.combat and o.combat.apr end},
	{k="atk", n=_t"Accuracy", get=function(o) return o.combat and o.combat.atk end},
	{k="crit", n=_t"Crit chance", get=function(o) return o.combat and o.combat.physcrit end, unit="%"},
	{k="armor", n=_t"Armour", get=function(o) return o.wielder and o.wielder.combat_armor end},
	{k="def", n=_t"Defence", get=function(o) return o.wielder and o.wielder.combat_def end},
	{k="enc", n=_t"Weight", get=function(o) return o.encumber end, lower_better=true},
}
function Card:init(t)
	self.w, self.h = t.width, t.height
	self.actor = t.actor
	Base.init(self, t)
end
function Card:generate()
	self.mouse:reset() self.key:reset()
	self.f_title = core.display.newFont(FontPackage:getFont("default"), 22)
	self.f_small = core.display.newFont(FontPackage:getFont("default"), 14)
	self.f_row = core.display.newFont(FontPackage:getFont("default"), 17)
	self.texts = {}
end
function Card:text(font, str, r, g, b)
	local key = tostring(font).."|"..str.."|"..r..","..g..","..b
	local d = self.texts[key]
	if not d then
		local w = font:size((str:gsub("#[^#]*#", ""))) + 6
		d = font:draw(str, w, r, g, b, true)[1]
		if d then d.w = math.min(d.w, w) end
		self.texts[key] = d
	end
	return d
end
function Card:set(o, worn, kind)
	self.o, self.worn, self.kind = o, worn, kind
	self.texts = {}
	self.rows = {}
	if not o then return end
	for _, st in ipairs(STATS) do
		local a = st.get(o)
		local b = worn and st.get(worn) or nil
		if a or b then
			local dir = nil
			if a and b and a ~= b then dir = (a > b) and "up" or "down" if st.lower_better then dir = dir == "up" and "down" or "up" end end
			self.rows[#self.rows+1] = {n=st.n, a=a and (("%s%s"):format(math.floor(a * 10) / 10, st.unit or "")) or "-", b=b and (("%s%s"):format(math.floor(b * 10) / 10, st.unit or "")) or "-", dir=dir}
		end
	end
end
function Card:contentHeight()
	return 70 + (#self.rows > 0 and (28 + #self.rows * 32 + 8) or 0)
end
function Card:display(x, y, nb_keyframes, screen_x, screen_y)
	self.last_sx, self.last_sy = screen_x or x, screen_y or y
	local o = self.o
	if not o then
		local d = self:text(self.f_row, _t"Tap an item to see how it compares with what you wear.", 142, 136, 120)
		if d then d._tex:toScreenFull(x + 10, y + 20, d.w, d.h, d._tex_w, d._tex_h) end
		return
	end
	core.display.drawQuad(x, y, 60, 60, 14, 15, 18, 255)
	pcall(o.toScreen, o, nil, x + 6, y + 6, 48, 48)
	local ok, name = pcall(o.getName, o, {do_color=true, no_count=true})
	local nd = self:text(self.f_title, ok and tostring(name) or tostring(o.name), 255, 255, 255)
	if nd then
		local maxw = self.w - 72
		core.display.glScissor(true, self.last_sx + 72, self.last_sy, maxw, 70)
		nd._tex:toScreenFull(x + 72, y + 6, nd.w, nd.h, nd._tex_w, nd._tex_h)
		core.display.glScissor(false)
	end
	local kind = self.kind or ""
	if self.worn then local okw, wn = pcall(self.worn.getName, self.worn, {do_color=true, no_count=true}) kind = kind.."  ·  "..(_t"replaces ")..(okw and tostring(wn) or self.worn.name) end
	local kd = self:text(self.f_small, kind, 160, 155, 140)
	if kd then
		core.display.glScissor(true, self.last_sx + 72, self.last_sy, self.w - 72, 70)
		kd._tex:toScreenFull(x + 72, y + 40, kd.w, kd.h, kd._tex_w, kd._tex_h)
		core.display.glScissor(false)
	end
	if #self.rows == 0 then return end
	local ty = y + 70
	core.display.drawQuad(x, ty, self.w, 28 + #self.rows * 32 + 8, 30, 32, 40, 255)
	local h1 = self:text(self.f_small, _t"STAT", 142, 136, 120)
	local h2 = self:text(self.f_small, self.worn and _t"NEW" or _t"VALUE", 240, 212, 138)
	local h3 = self:text(self.f_small, _t"WORN", 142, 136, 120)
	local c2, c3 = x + self.w - 170, x + self.w - 80
	if h1 then h1._tex:toScreenFull(x + 12, ty + 7, h1.w, h1.h, h1._tex_w, h1._tex_h) end
	if h2 then h2._tex:toScreenFull(c2 + 70 - h2.w, ty + 7, h2.w, h2.h, h2._tex_w, h2._tex_h) end
	if self.worn and h3 then h3._tex:toScreenFull(c3 + 70 - h3.w, ty + 7, h3.w, h3.h, h3._tex_w, h3._tex_h) end
	core.display.drawQuad(x, ty + 27, self.w, 1, 60, 62, 70, 255)
	local ry = ty + 32
	for _, r in ipairs(self.rows) do
		local nd2 = self:text(self.f_row, r.n, 235, 230, 215)
		local cr, cg, cb = 235, 230, 215
		if r.dir == "up" then cr, cg, cb = 123, 211, 137 elseif r.dir == "down" then cr, cg, cb = 224, 122, 106 end
		local va = self:text(self.f_row, r.a..(r.dir == "up" and " ^" or r.dir == "down" and " v" or ""), cr, cg, cb)
		local vb = self:text(self.f_row, r.b, 142, 136, 120)
		if nd2 then nd2._tex:toScreenFull(x + 12, ry + 4, nd2.w, nd2.h, nd2._tex_w, nd2._tex_h) end
		if va then va._tex:toScreenFull(c2 + 70 - va.w, ry + 4, va.w, va.h, va._tex_w, va._tex_h) end
		if self.worn and vb then vb._tex:toScreenFull(c3 + 70 - vb.w, ry + 4, vb.w, vb.h, vb._tex_w, vb._tex_h) end
		ry = ry + 32
	end
end

------------------------------------------------------------------

--- The compare card (item header + NEW / WORN stat table) for other touch
-- screens; the inventory has its own copy of the same element
_M.Card = Card

--- @param actor the wearer
-- @param o the candidate object
-- @param worn list of worn objects in the same slot (may be empty)
-- @param on_wear function called by the big button (nil = no button)
function _M:init(actor, o, worn, on_wear)
	self.actor = actor
	self.bigfont = core.display.newFont(FontPackage:getFont("default"), 22)
	Dialog.init(self, _t"Compare", game.w * 0.96, game.h * 0.96)
	local colw = math.floor((self.iw - 20) / 2)
	local bh = 56
	local wi = o:wornInven()
	local inven = wi and actor:getInven(wi)

	-- headers
	local left_name = o:getName{do_color=true}
	local right_name = (#worn > 0) and worn[1]:getName{do_color=true} or _t"#GREY#nothing worn in that slot#LAST#"
	self.c_lhead = Textzone.new{width=colw, auto_height=true, text=("#GOLD#New:#LAST# %s"):format(left_name)}
	self.c_rhead = Textzone.new{width=colw, auto_height=true, text=("#GOLD#Worn:#LAST# %s"):format(right_name)}
	local head_h = math.max(self.c_lhead.h, self.c_rhead.h)
	local list_h = self.ih - head_h - bh - 24

	-- the candidate, with the engine's own diffs against what is worn
	self.c_left = TextzoneList.new{focus_check=true, scrollbar=true, width=colw, height=list_h, dest_area={h=list_h}}
	local ok, d = pcall(o.getDesc, o, {do_color=true}, inven, nil, actor)
	if ok and d then self.c_left:switchItem(d, d) end
	self.c_right = TextzoneList.new{focus_check=true, scrollbar=true, width=colw, height=list_h, dest_area={h=list_h}}
	if #worn > 0 then
		local ok2, d2 = pcall(worn[1].getDesc, worn[1], {do_color=true}, nil, true, actor)
		if ok2 and d2 then self.c_right:switchItem(d2, d2) end
	end

	local uis = {
		{left=0, top=0, ui=self.c_lhead},
		{left=colw + 20, top=0, ui=self.c_rhead},
		{left=0, top=head_h + 8, ui=self.c_left},
		{left=colw + 20, top=head_h + 8, ui=self.c_right},
		{left=colw + 10 - 2, top=head_h + 8, ui=Separator.new{dir="horizontal", size=list_h}},
	}
	if on_wear then
		local b = Button.new{text=_t"Wield / wear this one", width=320, font=self.bigfont, fct=function() game:unregisterDialog(self) on_wear() end}
		uis[#uis+1] = {right=0, bottom=0, ui=b}
	end
	local bc = Button.new{text=_t"Close", width=140, font=self.bigfont, fct=function() game:unregisterDialog(self) end}
	uis[#uis+1] = {left=0, bottom=0, ui=bc}
	self:loadUI(uis)
	self:setupUI()
	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end }
end
