-- touch party dialogs: switch (PartySelect), orders (PartyOrder), give item (PartySendItem)
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local p, map = game.player, game.level.map
	local function inside(d)
		local bad = 0
		for _, u in ipairs(d.uis or {}) do
			local ui = u.ui
			if u.x and u.x < 50000 and not u.hidden then
				if u.x < d.ix or u.y < d.iy or u.x + ui.w > d.ix + d.iw + 3 or u.y + ui.h > d.iy + d.ih + 3 then bad = bad + 1 T.log("BAD ui outside", tostring(ui.__CLASSNAME), u.x, u.y, ui.w, ui.h, d.iw, d.ih) end
			end
		end
		return bad
	end
	local function tapCard(d, it)
		T.tap(d.c_flow.last_screen_x + it.x + it.w / 2, d.c_flow.last_screen_y + it.y + it.h / 2 - (d.c_flow.scrollbar.pos or 0))
	end
	-- a temporary ally
	local npc
	for _, dd in ipairs{{1, 0}, {-1, 0}, {0, 1}, {0, -1}} do
		local x, y = p.x + dd[1], p.y + dd[2]
		if map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR) then
			npc = game.zone:makeEntity(game.level, "actor", {type="vermin"}, nil, true)
			if npc then game.zone:addEntity(game.level, npc, "actor", x, y) break end
		end
	end
	if not npc then T.log("no npc") T.log("finished") return end
	npc.faction = p.faction
	game.party:addMember(npc, {control="full", type="summon", title="Test ally", orders={target=true, behavior=true, leash=true, anchor=true, talents=true, dismiss=true}})
	T.wait(300)
	-- 1. PartySelect
	local d = require("mod.dialogs.PartySelect").new()
	game:registerDialog(d) T.wait(600)
	local secs = d.c_flow and d.c_flow.sections or {}
	local n = secs[1] and #secs[1].items or 0
	T.log("PartySelect cards", n, "inside problems", inside(d))
	-- the game never lists the character you already control, so the ally is the only card
	if n < 1 then T.log("BAD PartySelect should list the ally") end
	T.shot("party-select")
	local ally
	for _, it in ipairs(secs[1] and secs[1].items or {}) do if it.data == npc then ally = it end end
	if ally then tapCard(d, ally) T.wait(600) end
	T.log("after tap: PartySelect open", tostring(game:hasDialog(d)), "controlling ally", tostring(game.player == npc))
	if game:hasDialog(d) then T.log("BAD PartySelect did not close on tap") T.key("EXIT") T.wait(300) end
	if ally and game.player ~= npc then T.log("BAD tapping the ally did not hand control over") end
	if game.player ~= p then game.party:select(p) T.wait(400) end
	p = game.player
	-- 2. PartyOrder
	local def = game.party.members[npc]
	local o = require("mod.dialogs.PartyOrder").new(npc, def)
	game:registerDialog(o) T.wait(600)
	local osecs = o.c_flow and o.c_flow.sections or {}
	local on = osecs[1] and #osecs[1].items or 0
	T.log("PartyOrder options", on, "inside problems", inside(o))
	if on < 1 then T.log("BAD PartyOrder shows no orders") end
	T.shot("party-order")
	-- tap "Set the leash distance" if present (opens a quantity prompt), else the first
	local pick
	for _, it in ipairs(osecs[1] and osecs[1].items or {}) do if it.data and it.data.order == "leash" then pick = it end end
	pick = pick or (osecs[1] and osecs[1].items[1])
	if pick then tapCard(o, pick) T.wait(600) end
	T.log("after order tap: PartyOrder open", tostring(game:hasDialog(o)), "top", tostring(game.dialogs[#game.dialogs] and game.dialogs[#game.dialogs].title))
	if game:hasDialog(o) then T.log("BAD PartyOrder did not close on tap") end
	for _ = 1, 3 do if #game.dialogs > 0 then T.key("EXIT") T.wait(300) end end
	-- 3. PartySendItem
	local obj = game.zone:makeEntity(game.level, "object", {type="weapon"}, nil, true)
	if obj then obj:identify(true) p:addObject("INVEN", obj) end
	local inven = p:getInven("INVEN")
	local idx
	for i, it in ipairs(inven) do if it == obj then idx = i end end
	local ended = false
	local s = require("mod.dialogs.PartySendItem").new(p, obj, inven, idx or 1, function() ended = true end)
	game:registerDialog(s) T.wait(600)
	local ssecs = s.c_flow and s.c_flow.sections or {}
	local sn = ssecs[1] and #ssecs[1].items or 0
	T.log("PartySendItem cards", sn, "recipients", #(s.recipients or {}), "inside problems", inside(s))
	T.shot("party-send")
	local rec = ssecs[1] and ssecs[1].items[1]
	if rec and rec.data and not rec.locked then
		tapCard(s, rec) T.wait(600)
		T.log("after give: dialog open", tostring(game:hasDialog(s)), "on_end fired", tostring(ended), "ally has it", tostring(npc:findInAllInventories(obj:getName{no_count=true, force_id=true, no_add_name=true}) ~= nil))
		if not ended then T.log("BAD giving the item did not complete") end
	else
		T.log("note: no recipient with a pack (a vermin has no inventory); dialog rendered the empty state")
	end
	if game:hasDialog(s) then T.key("EXIT") T.wait(300) end
	T.log("finished")
end
