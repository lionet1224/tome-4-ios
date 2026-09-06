-- Touch chat in portrait: header row, speech full width, answers under it; reopen.
-- Run with TOUCH_EXTRA=', orientation="portrait", hand="left"' tools/touch/sim-run.sh tools/touch/tests/chat-portrait.lua <outdir>
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local TI = require "engine.TouchInput"
	T.log("size", game.w, game.h, "portrait", tostring(TI.portrait()))
	local p = game.player
	local npc = game.zone:makeEntity(game.level, "actor", {type="humanoid"}, nil, true) or game.zone:makeEntity(game.level, "actor", nil, nil, true)
	if not npc then T.log("no npc") T.log("finished") return end
	local x, y = util.findFreeGrid(p.x, p.y, 5, true, {[Map.ACTOR]=true})
	if not x then T.log("no grid") T.log("finished") return end
	game.zone:addEntity(game.level, npc, "actor", x, y)
	require("engine.Chat").new("golbug-explains", npc, p):invoke()
	T.wait(800)
	local d = game.dialogs[#game.dialogs]
	T.log("chat class", tostring(d and d.__CLASSNAME), "portrait layout", tostring(d and d.portrait), "answers", tostring(d and d.c_answers and #d.c_answers.items), "node", tostring(d and d.cur_id))
	if not d or not d.c_answers then T.log("BAD no touch chat") T.log("finished") return end
	local function checkBounds(dd, tag)
		local bad = 0
		if dd.w > game.w or dd.h > game.h then T.log("BAD "..tag..": dialog bigger than the screen", dd.w, dd.h) bad = bad + 1 end
		for _, u in ipairs(dd.uis) do
			local ui = u.ui
			if not (ui.w and ui.w > 0 and ui.h and ui.h > 0) then T.log("BAD "..tag..": ui with empty size", tostring(ui.__CLASSNAME), tostring(ui.w), tostring(ui.h)) bad = bad + 1 end
			if u.x < dd.ix or u.y < dd.iy or u.x + ui.w > dd.ix + dd.iw + 1 or u.y + ui.h > dd.iy + dd.ih + 1 then
				T.log("BAD "..tag..": ui outside the dialog", tostring(ui.__CLASSNAME), u.x, u.y, ui.w, ui.h, "dialog", dd.ix, dd.iy, dd.iw, dd.ih) bad = bad + 1
			end
		end
		local hdr = dd.header_h or 0
		local desc = dd.ui_by_ui[dd.c_desc]
		if desc and desc.y < dd.iy + hdr then T.log("BAD "..tag..": speech overlaps the header", desc.y, hdr) bad = bad + 1 end
		T.log(tag, "dialog", dd.w, dd.h, "speech w", dd.c_desc.w, "answers w", dd.c_answers.w, "bounds checked, problems", bad)
	end
	checkBounds(d, "open")
	if d.c_desc.w < d.iw - 1 then T.log("BAD speech not full width", d.c_desc.w, d.iw) end
	T.shot("chatp-open")
	-- drag the speech a little (finger scroll must not count as a tap)
	local ux, uy = d.ui_by_ui[d.c_desc].x, d.ui_by_ui[d.c_desc].y
	T.swipe(d.display_x + ux + 200, d.display_y + uy + 100, d.display_x + ux + 200, d.display_y + uy + 30, 300) T.wait(400)
	T.log("still open after drag", tostring(game.dialogs[#game.dialogs] == d))
	if game.dialogs[#game.dialogs] ~= d then T.log("BAD drag closed or changed the chat") end
	-- rotation hook: the same node again
	local nd = d:touch_reopen()
	T.log("reopen: node", tostring(d.cur_id), "->", tostring(nd and nd.cur_id), "answers", tostring(nd and #nd.c_answers.items))
	if not nd or nd.cur_id ~= d.cur_id then T.log("BAD touch_reopen changed the node") end
	if nd then game:replaceDialog(d, nd) d = nd T.wait(500) checkBounds(d, "reopened") end
	-- tap the first answer card
	local a = d.c_answers
	local it = a.items[1]
	local tx, ty = a.last_screen_x + a.w / 2, a.last_screen_y + it.y + it.h / 2 - a.scrollbar.pos
	T.tap(tx, ty) T.wait(800)
	local d2 = game.dialogs[#game.dialogs]
	T.log("after tap: top", tostring(d2 and d2.__CLASSNAME), "same", tostring(d2 == d), "node", tostring(d2 and d2.cur_id))
	if d2 == d then T.log("BAD answer tap did nothing") end
	if d2 and d2.c_answers then checkBounds(d2, "next node") end
	T.shot("chatp-after")
	for _ = 1, 6 do
		local dd = game.dialogs[#game.dialogs]
		if not dd or not dd.c_answers then break end
		local last = dd.c_answers.items[#dd.c_answers.items]
		dd.c_answers.scrollbar.pos = dd.c_answers.scrollbar.max
		T.wait(200)
		local lx, ly = dd.c_answers.last_screen_x + dd.c_answers.w / 2, dd.c_answers.last_screen_y + last.y + last.h / 2 - dd.c_answers.scrollbar.pos
		T.tap(lx, ly) T.wait(600)
	end
	T.log("chat closed", tostring(not (game.dialogs[#game.dialogs] and game.dialogs[#game.dialogs].c_answers)))
	T.log("finished")
end
