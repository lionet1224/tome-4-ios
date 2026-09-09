-- Portrait. A dagger goes to the off-hand while the main hand keeps its sword: by tapping the
-- off-hand slot with the dagger selected, and through the item menu's "Wield in off-hand".
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p = game.player
	local function mk(subtype) local o = game.zone:makeEntity(game.level, "object", {type="weapon", subtype=subtype}, nil, true) if o then o:identify(true) p:addObject(p.INVEN_INVEN, o) end return o end
	local sword, dagger, dagger2 = mk("longsword"), mk("dagger"), mk("dagger")
	if not (sword and dagger and dagger2) then T.log("no items") T.log("finished") return end
	-- a one-handed main weapon first (the birth greatsword forbids an off-hand)
	local inv = p:getInven(p.INVEN_INVEN)
	local si for i, o in ipairs(inv) do if o == sword then si = i end end
	p:doWear(p.INVEN_INVEN, si, sword, p, p.INVEN_MAINHAND) T.wait(200)
	T.log("main hand", p:getInven(p.INVEN_MAINHAND)[1] and p:getInven(p.INVEN_MAINHAND)[1]:getName{do_color=false} or "nil", "off-hand", p:getInven(p.INVEN_OFFHAND)[1] and "taken" or "empty")
	T.key("SHOW_INVENTORY") T.wait(1000)
	local d = game.dialogs[#game.dialogs]
	local entry for _, e in ipairs(d.c_list.items or {}) do if e.object == dagger then entry = e end end
	if not entry then T.log("BAD dagger not listed") T.log("finished") return end
	d:selectEntry(entry) T.wait(200)
	local slot for _, s in ipairs(d.c_grid.slots) do if s.def.short_name == "OFFHAND" then slot = s end end
	local inv2 = p:getInven(p.INVEN_OFFHAND)
	d:selectWorn(inv2[1] and {object=inv2[1], inven=p.INVEN_OFFHAND, item=1, worn=true} or nil, slot) T.wait(400)
	local oh = p:getInven(p.INVEN_OFFHAND)[1]
	local mh = p:getInven(p.INVEN_MAINHAND)[1]
	T.log("after slot tap: off-hand", oh and oh:getName{do_color=false} or "nil", "main hand", mh and mh:getName{do_color=false} or "nil")
	if oh ~= dagger then T.log("BAD the slot tap did not wear the dagger in the off-hand") end
	if mh ~= sword then T.log("BAD the main hand changed") end
	T.shot("offhand")
	-- the menu route with the second dagger replaces the first
	local e2 for _, e in ipairs(d.c_list.items or {}) do if e.object == dagger2 then e2 = e end end
	if e2 then
		local UseItemDialog = require "mod.dialogs.UseItemDialog"
		local ud = UseItemDialog.new(false, p, dagger2, e2.item, e2.inven, function() end)
		local has = false for _, it in ipairs(ud.list or {}) do if it.action == "wear_off" then has = true end end
		T.log("menu offers off-hand", tostring(has))
		if not has then T.log("BAD no 'Wield in off-hand' action") else ud:use({action="wear_off"}) T.wait(300) end
		local oh2 = p:getInven(p.INVEN_OFFHAND)[1]
		T.log("after menu: off-hand", oh2 and oh2:getName{do_color=false} or "nil")
		if has and oh2 ~= dagger2 then T.log("BAD the menu did not wear the second dagger in the off-hand") end
	end
	T.key("EXIT") T.wait(300)
	T.log("finished")
end
