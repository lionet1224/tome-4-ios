-- Achievements on touch: the game's opener lands on the journal's Achievements tab (chips, cards, sheet).
-- Run with TOUCH_EXTRA=', orientation="portrait", hand="left"' too.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local d = require("mod.dialogs.ShowAchievements").new(_t"Tales of Maj'Eyal Achievements", game.party)
	game:registerDialog(d) T.wait(800)
	T.log("dialog class", tostring(d.__CLASSNAME), "kind", tostring(d.kind), "portrait", tostring(d.portrait))
	if tostring(d.__CLASSNAME) ~= "mod.dialogs.TouchJournal" or d.kind ~= "achievements" then T.log("BAD achievements did not open the touch journal tab") T.log("finished") return end
	local function checkBounds(tag)
		local bad = 0
		for _, u in ipairs(d.uis) do
			local ui = u.ui
			if u.x < 50000 then
				if not (ui.w and ui.w > 0 and ui.h and ui.h > 0) then T.log("BAD "..tag..": empty ui", tostring(ui.__CLASSNAME)) bad = bad + 1 end
				if u.x < d.ix or u.y < d.iy or u.x + ui.w > d.ix + d.iw + 3 or u.y + ui.h > d.iy + d.ih + 3 then T.log("BAD "..tag..": ui outside", tostring(ui.__CLASSNAME), u.x, u.y, ui.w, ui.h) bad = bad + 1 end
			end
		end
		T.log(tag, "bounds problems", bad)
	end
	checkBounds("open")
	local secs = d.c_flow.sections
	T.log("sections", #secs, "chips", secs[1] and #secs[1].items or 0, "cards", secs[2] and #secs[2].items or 0)
	if #secs < 1 then T.log("BAD no sections") end
	local function itemAt(sec, i)
		local it = d.c_flow.sections[sec] and d.c_flow.sections[sec].items[i]
		if not it then return nil end
		return d.c_flow.last_screen_x + it.x + it.w / 2, d.c_flow.last_screen_y + it.y + it.h / 2 - d.c_flow.scrollbar.pos, it
	end
	-- the Locked chip: a fresh character has earned nothing, locked ones are plenty
	local cx, cy = itemAt(1, 2)
	if cx then T.tap(cx, cy) T.wait(500) end
	T.log("filter", tostring(d.filters.achievements), "cards now", d.c_flow.sections[2] and #d.c_flow.sections[2].items or 0)
	local x, y, it = itemAt(2, 1)
	if x and it and it.data then
		T.tap(x, y) T.wait(500)
		T.log("picked", tostring(d.cur and d.cur.name), "sheet item", tostring(d.c_desc.cur_item ~= nil))
		if not d.cur then T.log("BAD card tap did not select") end
		if not d.c_desc.cur_item then T.log("BAD sheet shows nothing") end
	else T.log("no achievement cards to tap") end
	checkBounds("picked")
	T.shot("achievements")
	local nd = d:touch_reopen()
	T.log("reopen kind", tostring(nd and nd.kind), "filter", tostring(nd and nd.filters.achievements))
	if not nd or nd.kind ~= "achievements" then T.log("BAD reopen lost the tab") end
	if nd and nd.unload then nd:unload() end
	T.key("EXIT") T.wait(300)
	T.log("finished")
end
