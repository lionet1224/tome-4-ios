-- Touch chat: spawn a creature, talk to it (the golbug-explains chat), tap an answer.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local p = game.player
	local npc = game.zone:makeEntity(game.level, "actor", {type="humanoid"}, nil, true) or game.zone:makeEntity(game.level, "actor", nil, nil, true)
	if not npc then T.log("no npc") T.log("finished") return end
	local x, y = util.findFreeGrid(p.x, p.y, 5, true, {[Map.ACTOR]=true})
	if not x then T.log("no grid") T.log("finished") return end
	game.zone:addEntity(game.level, npc, "actor", x, y)
	require("engine.Chat").new("golbug-explains", npc, p):invoke()
	T.wait(800)
	local d = game.dialogs[#game.dialogs]
	T.log("chat class", tostring(d and d.__CLASSNAME), "answers", tostring(d and d.c_answers and #d.c_answers.items), "node", tostring(d and d.cur_id))
	T.shot("chat-open")
	if not d or not d.c_answers then T.log("finished") return end
	-- drag the speech a little (finger scroll must not count as a tap)
	local ux, uy = d.ui_by_ui[d.c_desc].x, d.ui_by_ui[d.c_desc].y
	T.swipe(d.display_x + ux + 200, d.display_y + uy + 120, d.display_x + ux + 200, d.display_y + uy + 40, 300) T.wait(400)
	T.log("still open after drag", tostring(game.dialogs[#game.dialogs] == d))
	-- tap the first answer card
	local a = d.c_answers
	local it = a.items[1]
	local tx, ty = a.last_screen_x + a.w / 2, a.last_screen_y + it.y + it.h / 2 - a.scrollbar.pos
	T.tap(tx, ty) T.wait(800)
	local d2 = game.dialogs[#game.dialogs]
	T.log("after tap: top", tostring(d2 and d2.__CLASSNAME), "same", tostring(d2 == d), "node", tostring(d2 and d2.cur_id))
	T.shot("chat-after")
	-- walk the rest of the conversation by always taking the last answer (the leave one), max 6 nodes
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
