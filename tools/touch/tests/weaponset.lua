-- Portrait: the worn grid (with the set-2 slots) only exists there; landscape shows the paper doll.
-- The second weapon set from the inventory: "Wield in set 2" puts a weapon into the
-- quick-swap slot without swapping sets, the worn grid shows the set-2 slots, and the
-- Swap weapons action brings it to hand.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p = game.player
	local o = game.zone:makeEntity(game.level, "object", {type="weapon", subtype="battleaxe"}, nil, true)
	if not o then T.log("no weapon") T.log("finished") return end
	o:identify(true)
	p:addObject(p.INVEN_INVEN, o)
	local inven = p:getInven(p.INVEN_INVEN)
	local item for i, oo in ipairs(inven) do if oo == o then item = i end end
	T.log("pack item", o:getName{do_color=false}, "slot", tostring(item), "qs slot", tostring(p.INVEN_QS_MAINHAND))
	local UseItemDialog = require "mod.dialogs.UseItemDialog"
	local ud = UseItemDialog.new(false, p, o, item, p.INVEN_INVEN, function() end)
	local names = {} for _, e in ipairs(ud.list or {}) do names[#names+1] = tostring(e.action) end
	T.log("actions", table.concat(names, ","))
	local has = false for _, e in ipairs(ud.list or {}) do if e.action == "wear2" then has = true end end
	if not has then T.log("BAD no 'Wield in set 2' action") T.log("finished") return end
	ud:use({action="wear2"})
	T.wait(300)
	local qs = p:getInven(p.INVEN_QS_MAINHAND)
	local inqs = qs and qs[1] == o
	local mh = p:getInven(p.INVEN_MAINHAND)[1]
	T.log("in set 2", tostring(inqs), "main hand", mh and mh:getName{do_color=false} or "nil")
	if not inqs then T.log("BAD the weapon is not in the second set") end
	if mh == o then T.log("BAD the weapon went into the main hand") end
	-- the grid shows set-2 slots
	T.key("SHOW_INVENTORY") T.wait(1000)
	local d = game.dialogs[#game.dialogs]
	local n2 = 0 for _, s in ipairs(d.c_grid and d.c_grid.slots or {}) do if s.set2 then n2 = n2 + 1 end end
	T.log("set-2 slots in the grid", n2)
	if n2 == 0 then T.log("BAD no set-2 slots in the worn grid") end
	T.shot("weaponset-grid")
	T.key("EXIT") T.wait(400)
	-- swap sets: it comes to hand
	game.key:triggerVirtual("QUICK_SWITCH_WEAPON") T.wait(400)
	local mh2 = p:getInven(p.INVEN_MAINHAND)[1]
	T.log("after swap: main hand", mh2 and mh2:getName{do_color=false} or "nil")
	if mh2 ~= o then T.log("BAD the swap did not bring the set-2 weapon to hand") end
	T.log("finished")
end
