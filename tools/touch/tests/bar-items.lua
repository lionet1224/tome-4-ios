-- Items on the action bar + tap the target's name to inspect it.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p = game.player
	local Picker = require "mod.dialogs.TouchSlotPicker"
	-- a usable rod in the pack, bound to slot 5 the way the item sheet does it
	local o = game.zone:makeEntityByName(game.level, "object", "ROD_OF_RECALL") or game.zone:makeEntity(game.level, "object", {type="charm", subtype="rod"}, nil, true)
	if not o then T.log("no rod could be made") T.log("finished") return end
	o:identify(true)
	p:addObject(p:getInven("INVEN"), o)
	T.wait(2000) -- the auto-bind runs at most every 1.5 s
	T.log("auto-bound slot", tostring(Picker.itemSlot(p, o)), "latch", tostring(p.touch_autobound_recall))
	Picker.bindItem(p, o, 5)
	T.log("bound", Picker.itemHotkeyName(o), "slot", tostring(Picker.itemSlot(p, o)), "hotkey5", tostring(p.hotkey[5] and p.hotkey[5][2]))
	-- open the drawer with the Skills button
	local tm = game.uiset.touch_manual
	local sk = game.uiset.touch_skills_rect or (tm and tm.rects and tm.rects.skills)
	if not sk then T.log("no skills rect") T.log("finished") return end
	T.tap(sk.x + sk.w / 2, sk.y + sk.h / 2) T.wait(500)
	local rects = game.uiset.touch_strip_rects or (tm and tm.strip_rects) or {}
	local card
	for _, c in pairs(rects) do if c.item then card = c end end
	T.log("drawer open", tostring(tm and tm.drawer_open), "item card", tostring(card ~= nil), "cards", (function() local n = 0 for _ in pairs(rects) do n = n + 1 end return n end)())
	T.shot("bar-item")
	if card then
		T.tap(card.x + card.w / 2, card.y + card.h / 2) T.wait(800)
		local top = game.dialogs[#game.dialogs]
		T.log("after item tap: key", game.key == game.targetmode_key and "targeting" or (game.key == game.normal_key and "normal" or "other"), "top dialog", tostring(top and (top.title or top.__CLASSNAME)))
		if game.key == game.targetmode_key then T.key("EXIT") T.wait(300) end
		if game.dialogs[#game.dialogs] then T.key("EXIT") T.wait(300) end
	end
	-- a hostile to target, then tap its name in the drawer
	local Map = require "engine.Map"
	local npc = game.zone:makeEntity(game.level, "actor", {type="vermin"}, nil, true)
	local tx, ty
	for d = 2, 4 do
		for _, dir in ipairs{{d, 0}, {-d, 0}, {0, d}, {0, -d}} do
			local x, y = p.x + dir[1], p.y + dir[2]
			if not tx and game.level.map:isBound(x, y) and not game.level.map:checkAllEntities(x, y, "block_move") then tx, ty = x, y end
		end
	end
	if npc and tx then
		game.zone:addEntity(game.level, npc, "actor", tx, ty)
		T.wait(400)
		local sx, sy = game.level.map:getTileToScreen(tx, ty, true)
		T.tap(sx, sy) T.wait(500)
		T.log("target", tostring(p.touch_target and p.touch_target.name), "drawer", tostring(tm.drawer_open))
		local who = tm.strip_who_rect
		if who then
			T.tap(who.x + who.w / 2, who.y + who.h / 2) T.wait(800)
			local top = game.dialogs[#game.dialogs]
			T.log("after name tap: top dialog", tostring(top and top.__CLASSNAME), tostring(top and top.title))
			T.shot("inspect")
			if top then T.key("EXIT") T.wait(300) end
		else
			T.log("no who rect")
		end
	else
		T.log("no hostile spawned")
	end
	T.log("finished")
end
