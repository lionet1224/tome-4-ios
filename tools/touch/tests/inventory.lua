return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p = game.player
	-- some loot to play with
	for _, t in ipairs{{type="armor", subtype="heavy"}, {type="weapon"}, {type="jewelry"}} do local o = game.zone:makeEntity(game.level, "object", t, nil, true) if o then p:addObject(p:getInven("INVEN"), o) end end
	T.key("SHOW_INVENTORY") T.wait(1200)
	local d = game.dialogs[#game.dialogs]
	T.shot("inv-open")
	-- find the armour row
	local row
	for i, e in ipairs(d.c_list.items) do if e.object.type == "armor" and e.object:wornInven() then row = i break end end
	T.log("armour row", tostring(row))
	local lx, ly = d.c_list.last_screen_x + 120, d.c_list.last_screen_y + (row - 1) * d.c_list.row_h + 30 - (d.c_list.scrollbar and d.c_list.scrollbar.pos or 0)
	T.tap(lx, ly) T.wait(500) T.shot("inv-compare")
	-- drag it onto its slot
	local o = d.c_list.items[row].object
	local slot for _, s in ipairs(d.c_doll.slots) do if s.def.short_name == p.inven_def[o:wornInven()].short_name then slot = s break end end
	local sx, sy = d.c_doll.last_screen_x + slot.x + 32, d.c_doll.last_screen_y + slot.y + 32
	T.swipe(lx, ly, sx, sy, 500, 600) T.wait(600) T.shot("inv-after-drag")
	-- take it off again by dragging the slot into the list
	T.swipe(sx, sy, lx, ly + 100, 500, 600) T.wait(600) T.shot("inv-after-takeoff")
	-- double tap = wear
	T.tap(lx, ly) T.tap(lx, ly) T.wait(600) T.shot("inv-after-doubletap")
	d:switchTab("transmo") T.wait(400) T.shot("inv-chest")
	T.log("finished")
end
