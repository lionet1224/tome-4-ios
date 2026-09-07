-- Boot module: the Backups screen (list, back up now, actions sheet, details).
-- Run with sim-run.sh ... boot.
return function(T)
	T.waitFor(function() return game and game.__mod_info and game.__mod_info.short_name == "boot" and game.dialogs and game.dialogs[#game.dialogs] and game.dialogs[#game.dialogs].__touch_menu end, 30000)
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
	local x, y = card(d, _t"Backups")
	if not x then T.log("BAD no Backups card on the title menu") T.log("finished") return end
	-- the card may sit below the visible area: scroll the menu to the end first
	local fl = d.c_flow
	fl.scrollbar.pos = fl.scrollbar.max or 0
	T.wait(300)
	x, y = card(d, _t"Backups")
	T.tap(x, y) T.wait(1500)
	local bk = game.dialogs[#game.dialogs]
	if not (bk and bk.__touch_backups) then T.log("BAD Backups screen did not open; top is", tostring(bk and (bk.title or bk.__CLASSNAME))) T.log("finished") return end
	T.log(("screen %dx%d dialog %dx%d flow at %d,%d %dx%d backups before %d"):format(game.w, game.h, bk.w, bk.h, bk.flow_x, bk.flow_y, bk.flow_w, bk.flow_h, #bk.backups))
	local before = #bk.backups
	-- Back up now
	local b = bk.ui_by_ui[bk.b_backup]
	T.tap(bk.display_x + b.x + bk.b_backup.w / 2, bk.display_y + b.y + bk.b_backup.h / 2)
	T.waitFor(function() local top = game.dialogs[#game.dialogs] return top and top ~= bk and tostring(top.title or ""):find("Backed up") end, 60000)
	local top = game.dialogs[#game.dialogs]
	T.log("after backup: top", tostring(top and top.title), "backups", #bk.backups)
	if top and top ~= bk then T.key("EXIT") T.wait(400) end
	if #bk.backups <= before then T.log("BAD no new backup listed") T.log("finished") return end
	local e = bk.backups[1]
	T.log("newest", e.file, e.when)
	local TB = require "engine.dialogs.TouchBackups"
	local chars, err = TB.backupContents(e.file)
	T.log("contents:", chars and #chars or tostring(err), "characters")
	if game.save_list and #game.save_list > 0 and (not chars or #chars == 0) then T.log("BAD backup has no desc.lua although saves exist") end
	-- the actions sheet
	bk:openSheet(e) T.wait(600)
	local sh = game.dialogs[#game.dialogs]
	T.log("sheet", tostring(sh and sh.__backup_sheet), "buttons", tostring(sh and sh.b_restore and sh.b_restore.text), tostring(sh and sh.b_details and sh.b_details.text), tostring(sh and sh.b_delete and sh.b_delete.text))
	if not (sh and sh.__backup_sheet and sh.b_restore and sh.b_details and sh.b_delete) then T.log("BAD sheet missing or incomplete") T.log("finished") return end
	if sh.display_y + sh.h > game.h then T.log("BAD sheet below the screen") end
	T.shot("backups-sheet")
	sh:doDetails() T.wait(800)
	local pop = game.dialogs[#game.dialogs]
	T.log("details popup:", tostring(pop and pop.title))
	if not (pop and pop ~= bk and tostring(pop.title or ""):find("Backup")) then T.log("BAD no details popup") end
	if pop and pop ~= bk then T.key("EXIT") T.wait(400) end
	T.shot("backups")
	T.key("EXIT") T.wait(400)
	T.log("back on menu", tostring(game.dialogs[#game.dialogs] and game.dialogs[#game.dialogs].__touch_menu))
	T.log("finished")
end
