-- The inventory: chips, the worn grid, an item compared with what is worn, the off-hand slot. Portrait.
return function(T)
	local L = dofile("/touch-demo-lib.lua")
	L.prelude(T)
	local p = game.player
	local function mk(t, st) local o = game.zone:makeEntity(game.level, "object", {type=t, subtype=st}, nil, true) if o then o:identify(true) p:addObject(p.INVEN_INVEN, o) end return o end
	local sword, dagger, armour = mk("weapon", "longsword"), mk("weapon", "dagger"), mk("armor", "heavy")
	local inv = p:getInven(p.INVEN_INVEN)
	local si for i, o in ipairs(inv) do if o == sword then si = i end end
	if si then p:doWear(p.INVEN_INVEN, si, sword, p, p.INVEN_MAINHAND) end
	T.key("SHOW_INVENTORY") T.wait(2500)
	local d = game.dialogs[#game.dialogs]
	local function entry(o) for _, e in ipairs(d.c_list.items or {}) do if e.object == o then return e end end end
	local e = entry(armour) if e then d:selectEntry(e) T.wait(3500) end
	e = entry(dagger) if e then d:selectEntry(e) T.wait(2500) end
	local slot for _, s in ipairs(d.c_grid and d.c_grid.slots or {}) do if s.def.short_name == "OFFHAND" then slot = s end end
	if slot and d.c_grid.last_screen_x then T.tap(d.c_grid.last_screen_x + slot.x + 38, d.c_grid.last_screen_y + slot.y + 30) T.wait(3000) end
	-- a chip
	local ch = d.c_chips
	if ch and ch.last_screen_x and ch.items[2] then T.tap(ch.last_screen_x + ch.items[2].x + ch.items[2].w / 2, ch.last_screen_y + ch.h / 2) T.wait(2000) end
	if ch and ch.last_screen_x and ch.items[1] then T.tap(ch.last_screen_x + ch.items[1].x + ch.items[1].w / 2, ch.last_screen_y + ch.h / 2) T.wait(1500) end
	T.key("EXIT") T.wait(800)
	T.log("finished")
end
