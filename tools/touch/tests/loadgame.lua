-- Boot module: the touch "Load character" screen (hero card, rows, actions sheet, footer toggles).
-- Run with sim-run.sh ... boot (touch.script_boot, autopilot off).
return function(T)
	T.waitFor(function() return game and game.__mod_info and game.__mod_info.short_name == "boot" and game.dialogs and game.dialogs[#game.dialogs] and game.dialogs[#game.dialogs].__touch_menu end, 60000)
	-- FirstRun / account sheets may sit on top of the title menu
	local function menuUp() local d = game.dialogs[#game.dialogs] return d and d.c_flow and d.c_flow.sections and #d.c_flow.sections > 0 and d.__touch_menu end
	for _ = 1, 3 do
		if menuUp() then break end
		local d = game.dialogs[#game.dialogs]
		T.log("closing", tostring(d and d.__CLASSNAME))
		if d and tostring(d.__CLASSNAME):find("FirstRun") then d:doLater() elseif d then T.key("EXIT") end
		T.waitFor(menuUp, 20000)
	end
	T.wait(800)
	local d = game.dialogs[#game.dialogs]
	if not (d and d.__touch_menu) then T.log("no touch main menu on top") T.log("finished") return end
	local function card(dlg, name)
		for _, sec in ipairs(dlg.c_flow.sections) do
			for _, it in ipairs(sec.items) do
				if it.name == name then return dlg.c_flow.last_screen_x + it.x + it.w / 2, dlg.c_flow.last_screen_y + it.y + it.h / 2 - dlg.c_flow.scrollbar.pos end
			end
		end
	end
	local x, y = card(d, _t"Load game")
	if not x then T.log("no Load game card") T.log("finished") return end
	T.tap(x, y) T.wait(2500)
	local ld = game.dialogs[#game.dialogs]
	if not (ld and ld.__touch_load) then T.log("BAD load screen did not open; top is", tostring(ld and (ld.title or ld.__CLASSNAME))) T.log("finished") return end
	T.log(("screen %dx%d portrait=%s dialog %dx%d at %d,%d hero_h=%d flow %d,%d %dx%d"):format(game.w, game.h, tostring(ld.portrait), ld.w, ld.h, ld.display_x, ld.display_y, ld.hero_h, ld.flow_x, ld.flow_y, ld.flow_w, ld.flow_h))
	T.log("saves", #ld.saves, "hero", tostring(ld.hero and ld.hero.name), "others", #ld.others, "fallen", #ld.fallen, "sections", #ld.c_flow.sections)
	if #ld.saves > 0 and not ld.hero then T.log("BAD saves exist but no hero") end
	if #ld.c_flow.sections < 1 then T.log("BAD no sections") end
	-- the Continue button sits inside the screen and inside the hero card
	local e = ld.ui_by_ui[ld.b_continue]
	if ld.hero then
		local sx, sy = ld.display_x + e.x, ld.display_y + e.y
		T.log("Continue at", sx, sy, ld.b_continue.w, ld.b_continue.h, "hidden", tostring(e.hidden))
		if e.hidden then T.log("BAD Continue hidden with a hero") end
		if sx < 0 or sy < 0 or sx + ld.b_continue.w > game.w or sy + ld.b_continue.h > game.h then T.log("BAD Continue off screen") end
		local hero_bottom = ld.display_y + ld.iy + ld.hero_y + ld.hero_h
		if sy + ld.b_continue.h > hero_bottom + 1 then T.log("BAD Continue below the hero card") end
		-- every ui inside the dialog
		for _, u in ipairs(ld.uis) do
			if not u.hidden and (u.x < ld.ix - 1 or u.y < ld.iy - 1 or u.x + u.ui.w > ld.ix + ld.iw + 8 or u.y + u.ui.h > ld.iy + ld.ih + 8) then
				T.log("BAD ui outside the dialog", tostring(u.ui.text or u.ui.__CLASSNAME), u.x, u.y, u.ui.w, u.ui.h)
			end
		end
	end
	T.shot("loadgame")
	-- the actions sheet for the hero (never tap Continue: it would load)
	if ld.hero then
		ld:openSheet(ld.hero) T.wait(600)
		local sh = game.dialogs[#game.dialogs]
		T.log("sheet", tostring(sh and sh.__load_sheet), "buttons", tostring(sh and sh.b_load and sh.b_load.text), tostring(sh and sh.b_details and sh.b_details.text), tostring(sh and sh.b_delete and sh.b_delete.text))
		if not (sh and sh.__load_sheet) then T.log("BAD no actions sheet") else
			if sh.display_y + sh.h > game.h then T.log("BAD sheet off the bottom") end
			T.shot("loadgame-sheet")
			T.key("EXIT") T.wait(400)
		end
	end
	-- long-press a row opens the sheet too
	if #ld.others > 0 then
		local sec = ld.c_flow.sections[1]
		local it = sec.items[1]
		local rx, ry = ld.c_flow.last_screen_x + it.x + it.w / 2, ld.c_flow.last_screen_y + it.y + it.h / 2 - ld.c_flow.scrollbar.pos
		T.hold(rx, ry, 900) T.wait(600)
		local sh = game.dialogs[#game.dialogs]
		T.log("long-press row:", tostring(it.data and it.data.name), "sheet", tostring(sh and sh.__load_sheet), "for", tostring(sh and sh.save and sh.save.name))
		if not (sh and sh.__load_sheet) then T.log("BAD long-press did not open the sheet") else T.key("EXIT") T.wait(400) end
	end
	-- footer toggle
	local e = ld.b_compat and ld.ui_by_ui[ld.b_compat]
	local r = e and {x=e.x, y=e.y, w=ld.b_compat.w, h=ld.b_compat.h}
	if r then
		local before = ld.show_compat
		T.tap(ld.display_x + r.x + r.w / 2, ld.display_y + r.y + r.h / 2) T.wait(800)
		T.log("Older versions:", tostring(before), "->", tostring(ld.show_compat))
		if ld.show_compat == before then T.log("BAD footer toggle did not flip show_compat") end
	else T.log("BAD no footer rect") end
	T.key("EXIT") T.wait(400)
	T.log("back on menu", tostring(game.dialogs[#game.dialogs] and game.dialogs[#game.dialogs].__touch_menu))
	T.log("finished")
end
