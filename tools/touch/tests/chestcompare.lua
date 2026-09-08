-- The level-end Transmogrification Chest dialog: picking a chest item must show the
-- comparison against what is worn, exactly like the inventory does.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p = game.player
	p.has_transmo = 1
	-- a chest item of a worn kind: a body armour when one is worn, else a weapon
	local worn = p:getInven("BODY") and p:getInven("BODY")[1]
	-- a weapon of another kind than the one wielded: its description must carry the deltas
	local mh = p:getInven("MAINHAND") and p:getInven("MAINHAND")[1]
	worn = mh or worn
	local filter = mh and {type="weapon", subtype="battleaxe"} or (worn and {type="armor", subtype=worn.subtype} or {type="weapon"})
	local o = game.zone:makeEntity(game.level, "object", filter, nil, true)
	if not o then T.log("no object") T.log("finished") return end
	o:identify(true)
	p:addObject(p.INVEN_INVEN, o)
	o.__transmo = true
	T.log("chest item", o:getName{do_color=false}, "worn", worn and worn:getName{do_color=false} or "nothing", "slot", tostring(o:wornInven()))
	-- what class/Game.lua's changeLevel does
	local titleupdator = p:getEncumberTitleUpdator(p:transmoGetName())
	local d = p:showEquipInven(titleupdator(), nil, function(o, inven, item, button, event) return false end)
	d.c_inven.dont_update_last_tabs = true
	d.c_inven:switchTab{kind="transmo"}
	T.wait(600)
	T.log("dialog", d.__CLASSNAME or "?", "tab", tostring(d.tab), "chest_mode", tostring(d.chest_mode), "entries", d.c_list and #(d.c_list.items or {}) or -1)
	-- select the chest item through the list
	local found
	for i, e in ipairs(d.c_list and d.c_list.items or {}) do if e.object == o then found = e break end end
	if not found then T.log("BAD chest item not listed in the chest tab") T.shot("chest-tab") T.log("finished") return end
	d:selectEntry(found) T.wait(400)
	T.shot("chest-compare")
	local card = d.c_card
	T.log("selected", tostring(d.cur and d.cur.object == o), "desc_compared", tostring(d.desc_compared), "card rows", card and card.rows and #card.rows or -1, "card worn", card and card.worn and card.worn:getName{do_color=false} or "nil")
	if worn and not d.desc_compared then T.log("BAD no comparison for the chest item") end
	local txt = d.desc_text or ""
	local deltas = txt:find("#00ff00#") or txt:find("#ff0000#") or txt:find("%(%+") or txt:find("%(%-")
	T.log("delta markup in the description", tostring(deltas ~= nil))
	if worn and not deltas then T.log("BAD the description carries no comparison deltas") end
	if worn and card and card.worn ~= worn then T.log("BAD card does not compare against the worn item") end
	T.key("EXIT") T.wait(300)
	T.log("finished")
end
