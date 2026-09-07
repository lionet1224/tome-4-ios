-- the alchemist ingredients list, touch version
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p = game.player
	game.party:collectIngredient("TROLL_INTESTINE", 3, true)
	game.party:collectIngredient("RITCH_STINGER", 1, true)
	local d = require("mod.dialogs.ShowIngredients").new(game.party)
	game:registerDialog(d) T.wait(600)
	local secs = d.c_flow and d.c_flow.sections or {}
	local n = secs[1] and #secs[1].items or 0
	T.log("ingredient cards", n, "portrait", tostring(d.portrait), "cur", tostring(d.cur and d.cur.plain))
	if n < 2 then T.log("BAD expected two ingredient cards") end
	local bad = 0
	for _, u in ipairs(d.uis or {}) do
		local ui = u.ui
		if u.x < d.ix or u.y < d.iy or u.x + ui.w > d.ix + d.iw + 3 or u.y + ui.h > d.iy + d.ih + 3 then bad = bad + 1 T.log("BAD ui outside", tostring(ui.__CLASSNAME), u.x, u.y, ui.w, ui.h) end
	end
	T.log("inside problems", bad)
	T.shot("ingredients")
	local it = secs[1] and secs[1].items[2]
	if it then
		T.tap(d.c_flow.last_screen_x + it.x + it.w / 2, d.c_flow.last_screen_y + it.y + it.h / 2 - (d.c_flow.scrollbar.pos or 0)) T.wait(500)
		T.log("after tap: cur", tostring(d.cur and d.cur.plain), "desc shown", tostring(d.c_desc.cur_item ~= nil))
		if d.cur ~= it.data then T.log("BAD tapping a card did not select it") end
	end
	T.key("EXIT") T.wait(300)
	T.log("after EXIT: open", tostring(game:hasDialog(d)))
	T.log("finished")
end
