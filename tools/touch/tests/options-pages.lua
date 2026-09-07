-- Touch options: the Video and Audio sections are real rows (no desktop tree dialogs).
-- Run with TOUCH_EXTRA=', orientation="portrait", hand="left"'
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local d = require("mod.dialogs.TouchOptions").new()
	game:registerDialog(d) T.wait(800)
	local function rowNamed(frag) for i, it in ipairs(d.c_rows.items) do if tostring(it.label):find(frag) then return it, i end end end
	local function rowCenter(i) local it = d.c_rows.items[i] return d.c_rows.last_screen_x + it.x + it.w / 2, d.c_rows.last_screen_y + it.y + it.h / 2 - d.c_rows.scrollbar.pos end
	d:switchTo("video") T.wait(400)
	local names = {} for _, it in ipairs(d.c_rows.items) do names[#names+1] = it.label end
	T.log("video rows:", table.concat(names, " | "))
	local fps, fi = rowNamed("Frame rate")
	if not fps then T.log("BAD no Frame rate row") T.log("finished") return end
	local shown = d.c_rows.valueOf(fps)
	T.log("fps row shows", shown, "setting", tostring(config.settings.display_fps))
	if shown ~= tostring(config.settings.display_fps) then T.log("BAD fps row value differs from the setting") end
	local x, y = rowCenter(fi)
	T.tap(x, y) T.wait(700)
	local top = game.dialogs[#game.dialogs]
	T.log("after tap: top dialog", tostring(top and top.title), tostring(top and top.__CLASSNAME))
	if top == d then T.log("BAD the frame-rate row opened nothing") else T.key("EXIT") T.wait(400) end
	if not rowNamed("Resolution") or not rowNamed("Particle") or not rowNamed("Gamma") then T.log("BAD a video row is missing") end
	d:switchTo("audio") T.wait(400)
	names = {} for _, it in ipairs(d.c_rows.items) do names[#names+1] = it.label.." = "..d.c_rows.valueOf(it) end
	T.log("audio rows:", table.concat(names, " | "))
	if #d.c_rows.items < 3 then T.log("BAD expected the enable + two volume rows") end
	if not rowNamed("Music") or not rowNamed("Effects") then T.log("BAD volume rows missing") end
	local _, mi = rowNamed("Music")
	x, y = rowCenter(mi) T.tap(x, y) T.wait(700)
	top = game.dialogs[#game.dialogs]
	T.log("music tap: top dialog", tostring(top and top.title))
	if top == d then T.log("BAD the music row opened nothing") else T.key("EXIT") T.wait(400) end
	T.shot("options-audio")
	T.key("EXIT") T.wait(300)
	T.log("finished")
end
