-- rod of recall from the bar: the recall must change level without an error
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p = game.player
	local rod = game.zone:makeEntityByName(game.level, "object", "ROD_OF_RECALL")
	if not rod then T.log("no rod") T.log("finished") return end
	rod:identify(true)
	p:addObject("INVEN", rod)
	T.wait(300)
	local zone0 = game.zone.short_name
	-- bind it to a slot the way autoBind does, then use it like the strip does
	local slot
	for i = 1, 36 do if p.hotkey[i] and p.hotkey[i][1] == "inventory" and p.hotkey[i][2] == rod:getName{no_count=true, force_id=true, no_add_name=true} then slot = i end end
	T.log("rod bound to slot", tostring(slot))
	if slot then p:hotkeyInventory(p.hotkey[slot][2]) else p:playerUseItem(rod) end
	T.wait(1000)
	if game.key ~= game.normal_key then T.key("ACCEPT") T.wait(500) end
	T.log("after use: key normal", tostring(game.key == game.normal_key), "dialogs", #game.dialogs, "zone", game.zone.short_name)
	-- the recall fires after a few turns: pass turns
	for i = 1, 40 do
		if game.zone.short_name ~= zone0 then break end
		if #game.dialogs > 0 then T.key("EXIT") end
		p:useEnergy() game:tick() T.wait(150)
	end
	T.waitFor(function() return game.zone.short_name ~= zone0 end, 20000)
	T.log("zone", zone0, "->", game.zone.short_name, "wilderness", tostring(game.zone.wilderness))
	if game.zone.short_name == zone0 then T.log("BAD recall did not change zone") end
	T.log("finished")
end
