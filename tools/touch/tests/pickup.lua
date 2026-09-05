-- Touch "pick up from the floor" dialog: three weapons on the tile, tap one, Take all.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p = game.player
	local before = #p:getInven("INVEN")
	local n = 0
	for i = 1, 3 do
		local o = game.zone:makeEntity(game.level, "object", {type="weapon"}, nil, true)
		if o then game.level.map:addObject(p.x, p.y, o) n = n + 1 end
	end
	T.log("dropped", n, "pack before", before)
	p:playerPickup()
	T.wait(800)
	local d = game.dialogs[#game.dialogs]
	T.log("dialog", tostring(d and d.__CLASSNAME), "touch", tostring(d and d.touch), "rows", tostring(d and d.list and #d.list))
	T.shot("pickup-open")
	if not (d and d.touch and d.c_list) then T.log("finished") return end
	-- hold the first row: description in the pane
	local lx, ly = d.c_list.last_screen_x + 120, d.c_list.last_screen_y + 33
	T.hold(lx, ly, 700) T.wait(400)
	T.log("read about", tostring(d.cur_item and d.cur_item.object and d.cur_item.object.name))
	T.shot("pickup-desc")
	-- tap it: taken, row gone
	T.tap(lx, ly) T.wait(600)
	T.log("after tap: rows", tostring(d.list and #d.list), "pack", #p:getInven("INVEN"), "open", tostring(game:hasDialog(d)))
	T.shot("pickup-after-tap")
	-- take the rest
	local u = d.ui_by_ui[d.b_all]
	T.tap(d.display_x + u.x + d.b_all.w / 2, d.display_y + u.y + d.b_all.h / 2) T.wait(800)
	T.log("after take all: pack", #p:getInven("INVEN"), "open", tostring(game:hasDialog(d)), "floor left", tostring(game.level.map:getObject(p.x, p.y, 1) ~= nil))
	T.shot("pickup-after-all")
	T.log("finished")
end
