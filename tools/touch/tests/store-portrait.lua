-- Shop in portrait: Buy / Sell tabs, list fills the width, description + button in a bottom sheet; rotation rebuild.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local TI = require "engine.TouchInput"
	local p = game.player
	local Store = require "mod.class.Store"
	local st = Store.new{name="Test shop", store={purse=50, nb_fill=0, restock_after=1000000}}
	local stocked = 0
	for i = 1, 4 do
		local o = game.zone:makeEntity(game.level, "object", {type="weapon"}, nil, true)
		if o then o:identify(true) st:addObject("INVEN", o) stocked = stocked + 1 end
	end
	local sellable = game.zone:makeEntity(game.level, "object", {type="weapon"}, nil, true)
	if sellable then sellable:identify(true) p:addObject("INVEN", sellable) end
	p.money = (p.money or 0) + 500
	st:interact(p, "Test shop")
	T.wait(800)
	-- a lore / quest popup may land on top of the shop: dismiss it
	for _ = 1, 3 do
		local top = game.dialogs[#game.dialogs]
		if top and top.c_tabs then break end
		if top then T.log("dismissing", tostring(top.__CLASSNAME)) T.key("EXIT") T.wait(500) end
	end
	local d = game.dialogs[#game.dialogs]
	T.log("stocked", stocked, "dialog", tostring(d and d.__CLASSNAME), "mode", tostring(d and d.mode))
	if not (d and d.c_list and d.c_tabs) then T.log("BAD no touch store dialog") T.log("finished") return end
	T.log(("screen %dx%d portrait=%s inner %dx%d list %dx%d sheet_y=%s"):format(game.w, game.h, tostring(TI.portrait()), d.iw, d.ih, d.c_list.w, d.c_list.h, tostring(d.sheet_y)))
	local function bounds(tag)
		local bad = 0
		for _, u in ipairs(d.uis) do
			local ui = u.ui
			if u.x < 50000 and u.x > -1000 then
				if ui.w <= 0 or ui.h <= 0 or u.x < d.ix or u.y < d.iy or u.x + ui.w > d.ix + d.iw + 1 or u.y + ui.h > d.iy + d.ih + 1 then
					T.log("BAD "..tag..": ui outside the dialog", tostring(ui.text or ui.__CLASSNAME), u.x, u.y, ui.w, ui.h, "inner", d.ix, d.iy, d.iw, d.ih) bad = bad + 1
				end
			end
		end
		T.log(tag, "bounds checked, problems", bad)
	end
	bounds("buy")
	if d.portrait and math.abs(d.c_list.w - d.iw) > 1 then T.log("BAD portrait list not full width") end
	T.log("buy rows", #d.c_list.items)
	-- tap the first row: description and the Buy button
	local lx, ly = d.c_list.last_screen_x + 120, d.c_list.last_screen_y + 33
	T.tap(lx, ly) T.wait(500)
	T.log("selected", tostring(d.cur and d.cur.object and d.cur.object.name), "button", tostring(d.b_primary.text))
	if not d.cur then T.log("BAD tap did not select a row") end
	-- rarity colour survives a cut name
	local cut, coloured = 0, 0
	for _, e in ipairs(d.c_list.items) do if e.name_cut then cut = cut + 1 if e.name_color then coloured = coloured + 1 end end end
	T.log("names cut", cut, "of", #d.c_list.items, "cut with colour", coloured)
	if cut > coloured then T.log("BAD a cut name lost its colour") end
	-- header-only card for the selected weapon; the description compares it with what is wielded
	local cu = d.ui_by_ui[d.c_card]
	local marked = d.desc_text and (d.desc_text:find("#00ff00#", 1, true) or d.desc_text:find("#ff0000#", 1, true)) ~= nil
	T.log("card item", tostring(d.c_card.o and d.c_card.o.name), "worn", tostring(d.c_card.worn and d.c_card.worn.name), "h", d.c_card.h, "desc h", d.c_desc.h, "compared", tostring(d.desc_compared), "delta markup", tostring(marked))
	if not (d.cur and d.c_card.o == d.cur.object) then T.log("BAD the card does not show the selected item") end
	if d.c_card.h ~= 90 then T.log("BAD card is not header-only", d.c_card.h) end
	local wi = d.cur and d.cur.object:wornInven()
	local has_worn = wi and d.actor_actor:getInven(wi) and #d.actor_actor:getInven(wi) > 0
	if has_worn and not d.desc_compared then T.log("BAD description not compared against the worn item") end
	if has_worn and not marked then T.log("note: no delta markup (identical stats?)") end
	if d.desc_text and not d.desc_text:find("gold", 1, true) then T.log("BAD price line missing from the description") end
	if cu and (cu.y < d.iy or cu.y + d.c_card.h > d.iy + d.ih + 1) then T.log("BAD card outside the dialog", cu.y, d.c_card.h) end
	local du = d.ui_by_ui[d.c_desc]
	if du and cu and du.y < cu.y + d.c_card.h then T.log("BAD description overlaps the card", du.y, cu.y, d.c_card.h) end
	T.shot("store-portrait")
	-- Sell tab
	local tu = d.ui_by_ui[d.c_tabs]
	local sell_tab = d.c_tabs.uis[2]
	T.tap(d.display_x + tu.x + sell_tab.x + sell_tab.ui.w / 2, d.display_y + tu.y + sell_tab.ui.h / 2) T.wait(500)
	T.log("mode after Sell tap", tostring(d.mode), "rows", #d.c_list.items)
	if d.mode ~= "sell" then T.log("BAD Sell tab did not switch") end
	bounds("sell")
	T.tap(lx, ly) T.wait(400)
	local sel = d.cur and d.cur.object
	T.log("sell selected", tostring(sel and sel.name))
	T.shot("store-sell")
	-- rotation rebuild keeps tab and selection
	local nd = d:touch_reopen()
	T.log("reopen", tostring(nd ~= nil), "mode", tostring(nd and nd.mode), "same item", tostring(nd and nd.cur and nd.cur.object == sel))
	if not nd or nd.mode ~= d.mode then T.log("BAD reopen lost the tab") end
	if sel and not (nd and nd.cur and nd.cur.object == sel) then T.log("BAD reopen lost the selection") end
	T.key("EXIT") T.wait(300)
	T.log("closed", tostring(not game:hasDialog(d)))
	T.log("finished")
end
