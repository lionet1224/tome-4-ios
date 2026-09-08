-- Birth screen: picking a race shows the hero as that race at once, and every race card
-- (Giants included, which only have a composite tile) has an icon.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local TB = require "mod.dialogs.TouchBirther"
	local d = TB.new("test", game.player, {"base", "world", "difficulty", "permadeath", "race", "subrace", "sex", "class", "subclass"}, function() end)
	game:registerDialog(d)
	T.wait(800)
	local function tileOf() local a = d.actor return tostring(a.image) .. "|" .. tostring(a.moddable_tile) end
	local function parent(name) for _, r in ipairs(d.all_races) do if r.id == name then return r end end end
	-- race cards: every unlocked race has an icon
	local items = d:cardsFor(d.all_races, nil, function() end, true)
	local missing = {}
	for _, it in ipairs(items) do if not it.locked and not it.icon then missing[#missing+1] = tostring(it.data.id) end end
	T.log("race cards", #items, "without icon:", table.concat(missing, ", "))
	if #missing > 0 then T.log("BAD race cards without an icon: " .. table.concat(missing, ", ")) end
	local giant = parent("Giant")
	if giant then
		local gi = d:cardsFor({giant}, nil, function() end, true)[1]
		T.log("Giant card icon", tostring(gi.icon ~= nil), "locked", tostring(giant.locked))
		if not giant.locked and not gi.icon then T.log("BAD no Giant icon") end
	end
	-- pick Human, then Giant: the hero tile must follow the race before any lineage is chosen
	local t0 = tileOf()
	d:raceUse(parent("Human")) T.wait(300)
	local t1 = tileOf()
	d:raceUse(parent("Giant")) T.wait(300)
	local t2 = tileOf()
	T.log("tile start", t0) T.log("tile after Human", t1) T.log("tile after Giant", t2)
	if t2 == t1 then T.log("BAD the hero tile did not change when the race changed") end
	if not t2:find("ogre") then T.log("BAD the Giant preview is not an ogre tile") end
	-- picking a lineage keeps working
	local first for _, n in ipairs(parent("Giant").nodes) do if not n.locked then first = n break end end
	if first then d:raceUse(first) T.wait(300) T.log("after lineage", first.id, tileOf(), "subrace", tostring(d.descriptors_by_type.subrace)) end
	T.shot("racepreview")
	T.key("EXIT") T.wait(300)
	T.log("finished")
end
