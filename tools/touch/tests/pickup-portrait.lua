-- Floor pickup in portrait: rows fill the width, description and buttons in a bottom sheet; rotation rebuild.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local TI = require "engine.TouchInput"
	local p = game.player
	local n = 0
	for i = 1, 3 do
		local o = game.zone:makeEntity(game.level, "object", {type="weapon"}, nil, true)
		if o then game.level.map:addObject(p.x, p.y, o) n = n + 1 end
	end
	p:playerPickup()
	T.wait(800)
	local d = game.dialogs[#game.dialogs]
	T.log("dropped", n, "dialog", tostring(d and d.__CLASSNAME), "touch", tostring(d and d.touch), "rows", tostring(d and d.list and #d.list))
	if not (d and d.touch and d.c_list) then T.log("BAD no touch pickup dialog") T.log("finished") return end
	T.log(("screen %dx%d portrait=%s inner %dx%d list %dx%d sheet_y=%s"):format(game.w, game.h, tostring(TI.portrait()), d.iw, d.ih, d.c_list.w, d.c_list.h, tostring(d.sheet_y)))
	local bad = 0
	for _, u in ipairs(d.uis) do
		local ui = u.ui
		if u.x < 50000 and u.x > -1000 then
			if ui.w <= 0 or ui.h <= 0 or u.x < d.ix or u.y < d.iy or u.x + ui.w > d.ix + d.iw + 1 or u.y + ui.h > d.iy + d.ih + 1 then
				T.log("BAD ui outside the dialog", tostring(ui.text or ui.__CLASSNAME), u.x, u.y, ui.w, ui.h, "inner", d.ix, d.iy, d.iw, d.ih) bad = bad + 1
			end
		end
	end
	T.log("bounds checked, problems", bad)
	if d.portrait and math.abs(d.c_list.w - d.iw) > 1 then T.log("BAD portrait list not full width") end
	-- hold the first row: description in the sheet
	local lx, ly = d.c_list.last_screen_x + 120, d.c_list.last_screen_y + 33
	T.hold(lx, ly, 700) T.wait(400)
	local read = d.cur_item and d.cur_item.object
	T.log("read about", tostring(read and read.name))
	T.shot("pickup-portrait")
	-- rotation rebuild keeps the item read about
	local nd = d:touch_reopen()
	T.log("reopen", tostring(nd ~= nil), "rows", tostring(nd and #nd.list), "same item", tostring(nd and nd.cur_item and nd.cur_item.object == read))
	if read and not (nd and nd.cur_item and nd.cur_item.object == read) then T.log("BAD reopen lost the selection") end
	-- take everything through the sheet button
	local u = d.ui_by_ui[d.b_all]
	local pack = #p:getInven("INVEN")
	T.tap(d.display_x + u.x + d.b_all.w / 2, d.display_y + u.y + d.b_all.h / 2) T.wait(800)
	T.log("after take all: pack", pack, "->", #p:getInven("INVEN"), "open", tostring(game:hasDialog(d)))
	T.log("finished")
end
