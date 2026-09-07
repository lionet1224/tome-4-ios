-- the touch character sheet: header, chips, rows / cards, bottom sheet; the player's and an enemy's
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local TI = require "engine.TouchInput"
	local p, map = game.player, game.level.map
	local CS = require "mod.dialogs.CharacterSheet"
	local d = CS.new(p)
	game:registerDialog(d) T.wait(800)
	T.log(("screen %dx%d portrait=%s dialog %dx%d inner %dx%d touch=%s kind=%s"):format(game.w, game.h, tostring(TI.portrait()), d.w, d.h, d.iw, d.ih, tostring(d.touch), tostring(d.kind)))
	local function bounds(tag)
		local bad = 0
		for _, u in ipairs(d.uis or {}) do
			local ui = u.ui
			if not u.hidden and u.x and u.x < 50000 then
				if u.x < d.ix - 1 or u.y < d.iy - 1 or u.x + ui.w > d.ix + d.iw + 8 or u.y + ui.h > d.iy + d.ih + 8 then
					T.log("BAD "..tag..": ui outside the dialog", tostring(ui.text or ui.__CLASSNAME), u.x, u.y, ui.w, ui.h, "inner", d.ix, d.iy, d.iw, d.ih) bad = bad + 1
				end
			end
		end
		T.log(tag, "bounds problems", bad)
	end
	bounds("general")
	-- every chip renders a section
	local chips = d.c_chips
	local e = d.ui_by_ui[chips]
	for _, it in ipairs(chips.items) do
		T.tap(d.display_x + e.x + it.x + it.w / 2, d.display_y + e.y + 25) T.wait(600)
		T.log(("tab %s: kind=%s rows=%s list shown=%s cards shown=%s"):format(it.kind, tostring(d.kind), tostring(d.touch_rows), tostring(not d.ui_by_ui[d.c_list].hidden), tostring(not d.ui_by_ui[d.c_flow].hidden)))
		if d.kind ~= it.kind then T.log("BAD chip did not switch the tab") end
		if (d.touch_rows or 0) == 0 then T.log("BAD empty tab "..it.kind) end
		bounds(it.kind)
		T.shot("charsheet-"..it.kind)
	end
	-- a talent card fills the sheet
	d:touchSwitch("talents") T.wait(300)
	local sec = d.c_flow.sections[1]
	local card = sec and sec.items[1]
	if card and card.data then
		local before = d.touch_text
		local f = d.ui_by_ui[d.c_flow]
		T.tap(d.display_x + f.x + card.x + card.w / 2, d.display_y + f.y + card.y + card.h / 2 - d.c_flow.scrollbar.pos) T.wait(500)
		T.log("talent tap:", tostring(card.name), "text changed", tostring(d.touch_text ~= before), "sel", tostring(card.sel))
		if d.touch_text == before then T.log("BAD talent tap did not change the sheet text") end
	else T.log("note: no talent card to tap") end
	-- a stat row fills the sheet
	d:touchSwitch("general") T.wait(300)
	local row
	for i, r in ipairs(d.c_list.rows) do if not r.head then row = {i=i, r=r} break end end
	if row then
		local l = d.ui_by_ui[d.c_list]
		local before = d.touch_text
		T.tap(d.display_x + l.x + 40, d.display_y + l.y + row.r.y1 + 20 - (d.c_list.scrollbar.pos or 0)) T.wait(500)
		T.log("row tap:", tostring(row.r.label), "text changed", tostring(d.touch_text ~= before))
	end
	-- reopen keeps the tab
	d:touchSwitch("defence")
	local nd = d:touch_reopen()
	T.log("reopen kind", tostring(nd and nd.kind))
	if not nd or nd.kind ~= "defence" then T.log("BAD touch_reopen lost the tab") end
	if nd then nd:unload() end
	T.key("EXIT") T.wait(400)
	-- an enemy's sheet
	local npc
	for _, dd in ipairs{{2, 0}, {-2, 0}, {0, 2}, {0, -2}, {2, 2}, {-2, -2}} do
		local x, y = p.x + dd[1], p.y + dd[2]
		if map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR) then
			npc = game.zone:makeEntity(game.level, "actor", {type="vermin"}, nil, true)
			if npc then game.zone:addEntity(game.level, npc, "actor", x, y) npc.faction = "enemies" break end
		end
	end
	if npc then
		p:playerFOV() T.wait(300)
		local ok, err = pcall(function() local ed = CS.new(npc) game:registerDialog(ed) return ed end)
		T.wait(800)
		local ed = game.dialogs[#game.dialogs]
		T.log("enemy sheet:", tostring(ok), tostring(err), "actor", tostring(ed and ed.actor and ed.actor.name), "rows", tostring(ed and ed.touch_rows))
		if not ok or not (ed and ed.actor == npc) then T.log("BAD enemy sheet did not open") end
		T.shot("charsheet-enemy")
		T.key("EXIT") T.wait(300)
	else T.log("note: no room to spawn an enemy") end
	T.log("finished")
end
