-- portrait inventory: one column (chips / list or doll / bottom sheet), every ui inside the
-- dialog, the Worn chip swaps the doll in, and touch_reopen rebuilds with the same state.
-- Run with TOUCH_EXTRA=', orientation="portrait", hand="left"'
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p = game.player
	for _, t in ipairs{{type="armor", subtype="heavy"}, {type="weapon"}, {type="jewelry"}} do local o = game.zone:makeEntity(game.level, "object", t, nil, true) if o then p:addObject(p:getInven("INVEN"), o) end end
	T.key("SHOW_INVENTORY") T.wait(1200)
	local d = game.dialogs[#game.dialogs]
	T.log(("screen %dx%d portrait=%s dialog %dx%d inner %dx%d at %d,%d"):format(game.w, game.h, tostring(d.portrait), d.w, d.h, d.iw, d.ih, d.display_x or -1, d.display_y or -1))
	if not d.portrait then T.log("BAD dialog did not build in portrait") end
	local function entry(ui) return d.ui_by_ui[ui] end
	local function rect(name, ui)
		local e = entry(ui)
		if not e then T.log("BAD no entry for", name) return end
		T.log(("%s x=%d y=%d w=%d h=%d hidden=%s"):format(name, e.x, e.y, ui.w, ui.h, tostring(e.hidden)))
		return e
	end
	rect("chips", d.c_chips) rect("list", d.c_list) rect("doll", d.c_doll) rect("card", d.c_card) rect("desc", d.c_desc) rect("primary", d.b_primary) rect("drop", d.b_drop) rect("more", d.b_more)
	-- entry x/y include the dialog's inner offset (ix, iy)
	local function inside(e, ui) return e and e.x >= d.ix and e.y >= d.iy and e.x + ui.w <= d.ix + d.iw + 1 and e.y + ui.h <= d.iy + d.ih + 1 end
	for _, u in ipairs(d.uis_def) do
		local e = entry(u.ui)
		if e and not e.hidden and not inside(e, u.ui) then T.log(("BAD ui outside the dialog: %s x=%d y=%d w=%d h=%d (inner %dx%d)"):format(tostring(u.ui._NAME or u.ui.__CLASSNAME), e.x, e.y, u.ui.w, u.ui.h, d.iw, d.ih)) end
	end
	-- chips fit the row
	local last = d.c_chips.items[#d.c_chips.items]
	T.log("chips", #d.c_chips.items, "row end", last.x + last.w, "of", d.c_chips.w)
	if last.x + last.w > d.c_chips.w then T.log("BAD chips overflow the row") end
	if entry(d.c_doll) and not entry(d.c_doll).hidden then T.log("BAD doll shown on the All tab") end
	if entry(d.c_list) and entry(d.c_list).hidden then T.log("BAD list hidden on the All tab") end
	-- tap a list item: the card shows it
	local row
	for i, e in ipairs(d.c_list.items) do if e.object.type == "armor" then row = i break end end
	if row then
		local lx, ly = d.c_list.last_screen_x + 120, d.c_list.last_screen_y + (row - 1) * d.c_list.row_h + 30 - (d.c_list.scrollbar and d.c_list.scrollbar.pos or 0)
		T.tap(lx, ly) T.wait(500)
		T.log("selected", tostring(d.cur and d.cur.object and d.cur.object.name), "card", tostring(d.c_card.o and d.c_card.o.name), "primary", tostring(d.b_primary.text))
		if not (d.cur and d.cur.object == d.c_list.items[row].object) then T.log("BAD list tap did not select the row") end
		if d.c_card.o ~= d.c_list.items[row].object then T.log("BAD card does not show the tapped item") end
	else T.log("no armour row") end
	T.shot("inv-portrait")
	-- the Worn chip: doll in, list out
	local ce = entry(d.c_chips)
	local worn for _, it in ipairs(d.c_chips.items) do if it.kind == "worn" then worn = it end end
	if worn and ce then
		T.tap(d.display_x + ce.x + worn.x + worn.w / 2, d.display_y + ce.y + 25) T.wait(500)
		T.log("tab", d.tab, "doll hidden", tostring(entry(d.c_doll).hidden), "list hidden", tostring(entry(d.c_list).hidden), "doll at", entry(d.c_doll).x, entry(d.c_doll).y)
		if d.tab ~= "worn" then T.log("BAD Worn chip did not switch the tab") end
		if entry(d.c_doll).hidden or not inside(entry(d.c_doll), d.c_doll) then T.log("BAD doll not on screen on the Worn tab") end
		if not entry(d.c_list).hidden or entry(d.c_list).x < d.iw then T.log("BAD list not parked on the Worn tab") end
		-- tap a worn slot: the card shows the worn item
		local slot for _, s in ipairs(d.c_doll.slots) do local inv = p.inven[s.id] if inv and inv[s.item] then slot = s break end end
		if slot then
			T.tap(d.c_doll.last_screen_x + slot.x + d.c_doll.box / 2, d.c_doll.last_screen_y + slot.y + d.c_doll.box / 2) T.wait(500)
			T.log("worn tap", tostring(d.cur and d.cur.worn), tostring(d.c_card.o and d.c_card.o.name), "primary", tostring(d.b_primary.text))
			if not (d.cur and d.cur.worn) then T.log("BAD worn slot tap did not select") end
		end
	else T.log("BAD no Worn chip") end
	T.shot("inv-worn")
	-- rotation hook: a fresh dialog with the same tab and selection
	local tab, obj = d.tab, d.cur and d.cur.object
	local nd = d:touch_reopen()
	T.log("reopen", tostring(nd ~= nil and nd ~= d), "tab", tostring(nd and nd.tab), "cur", tostring(nd and nd.cur and nd.cur.object and nd.cur.object.name), "portrait", tostring(nd and nd.portrait))
	if not nd or nd == d then T.log("BAD touch_reopen returned nothing") end
	if nd and nd.tab ~= tab then T.log("BAD reopened tab differs") end
	if nd and obj and not (nd.cur and nd.cur.object == obj) then T.log("BAD reopened selection differs") end
	if nd then nd:unload() end
	T.log("finished")
end
