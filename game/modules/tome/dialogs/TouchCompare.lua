-- ToME - Tales of Maj'Eyal
-- iOS port: side-by-side comparison of an item with what is worn in its slot.

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local Button = require "engine.ui.Button"
local Textzone = require "engine.ui.Textzone"
local TextzoneList = require "engine.ui.TextzoneList"
local Separator = require "engine.ui.Separator"
local FontPackage = require "engine.FontPackage"

module(..., package.seeall, class.inherit(Dialog))

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
