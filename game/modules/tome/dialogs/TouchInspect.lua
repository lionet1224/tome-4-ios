-- ToME iOS port: what the magnifier shows. The text the desktop map tooltip would
-- hold for a tile (creature, object, trap, terrain), as a dialog that fits its
-- text and scrolls when it is longer than the screen.

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local TextzoneList = require "engine.ui.TextzoneList"
local FontPackage = require "engine.FontPackage"

module(..., package.seeall, class.inherit(Dialog))

--- @param title dialog title
--- @param text a tstring (or string) with the details
function _M:init(title, text)
	self.force_close_bar = true -- always a Close bar under it for the thumb
	local w = math.floor(game.w * 0.92)
	Dialog.init(self, title, w, math.floor(game.h * 0.8))

	local font = core.display.newFont(FontPackage:getFont("default"), 18)
	local str = type(text) == "table" and text.toString and text:toString() or tostring(text)
	local tw = math.floor(self.iw - 10)
	local max_h = self.ih

	local tz = TextzoneList.new{width=tw, height=500, variable_height=true, font=font}
	tz:switchItem(str, str)
	local resize_h = true
	if tz.h > max_h then
		tz = TextzoneList.new{width=tw, height=max_h, scrollbar=true, focus_check=true, font=font, dest_area={h=max_h}}
		tz:switchItem(str, str)
		resize_h = false
	end
	self.c_desc = tz

	self:loadUI{
		{left=0, top=0, ui=self.c_desc},
	}
	self:setupUI(false, resize_h)
	self:setFocus(self.c_desc)

	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end }
end
