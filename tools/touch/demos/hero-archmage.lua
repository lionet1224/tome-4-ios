-- Build a level 50 Archmage in randart gear and park them inside Vor Pride, then save.
-- Run with: AP_CLASS=Archmage AP_RACE=Higher bash tools/touch/sim-run.sh tools/touch/demos/hero-archmage.lua <outdir>
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(800)
	local p = game.player
	T.log("born", p.name, tostring(p.descriptor.subrace), tostring(p.descriptor.subclass))
	p.name = "Archmage"
	game.save_name = "Archmage"

	-- levels and stats
	p:forceLevelup(50)
	p:incStat(p.STAT_MAG, 90) p:incStat(p.STAT_WIL, 70) p:incStat(p.STAT_CUN, 60) p:incStat(p.STAT_CON, 90)
	p.unused_stats = 0

	-- every known spell tree, maxed (locked class trees unlocked)
	local learned = 0
	for tt, known in pairs(p.talents_types) do
		if known == false then p:learnTalentType(tt, true) end
		local def = p.talents_types_def[tt]
		if def then for _, t in ipairs(def.talents) do
			local n = 0
			while p:getTalentLevelRaw(t.id) < (t.points or 5) and n < 8 do
				if not p:learnTalent(t.id, true) then break end
				n = n + 1 learned = learned + 1
			end
		end end
	end
	p.unused_talents = 0 p.unused_generics = 0 p.unused_talents_types = 0
	T.log("level", p.level, "talent levels learned", learned)

	-- randart gear in every slot
	local slots = {
		{type="weapon", subtype="staff"}, {type="armor", subtype="cloth"}, {type="armor", subtype="cloak"},
		{type="armor", subtype="head"}, {type="armor", subtype="feet"}, {type="armor", subtype="hands"},
		{type="armor", subtype="belt"}, {type="jewelry", subtype="amulet"}, {type="jewelry", subtype="ring"},
		{type="jewelry", subtype="ring"}, {type="lite"},
	}
	for _, f in ipairs(slots) do
		f.ignore_material_restriction = true f.no_tome_drops = true
		-- high-tier bases only (voratun, dragonbone...): the randart powers sit on top of them
		f.special = function(e) return e.randart_able and not e.unique and (e.material_level or 5) >= 4 end
		local base = game.zone:makeEntity(game.level, "object", f, 50, true)
		local o = base and game.state:generateRandart{lev=50, base=base}
		if o then
			o:identify(true)
			local ok, err = pcall(p.wearObject, p, o, true, false)
			T.log("wear", f.type, tostring(f.subtype), o:getName{do_color=false}, ok and "ok" or tostring(err))
		else T.log("no item for", f.type, tostring(f.subtype)) end
	end
	p:resetToFull()
	p.money = 8000

	-- into the pride
	game:onTickEnd(function() game:changeLevel(1, "vor-pride") end)
	local t0 = core.game.getTime()
	while (not game.zone or game.zone.short_name ~= "vor-pride" or not game.level) and core.game.getTime() - t0 < 60000 do T.wait(300) end
	T.wait(1500)
	T.log("zone", tostring(game.zone and game.zone.short_name), "level", tostring(game.level and game.level.level))
	T.shot("hero")
	-- the level change autosaves zone and game; a second saveGame() here collides with it
	local t1 = core.game.getTime()
	while (savefile_pipe.saving or (savefile_pipe.current_nb or 0) > 0) and core.game.getTime() - t1 < 120000 do T.wait(500) end
	T.wait(3000)
	T.log("saved after", core.game.getTime() - t1, "ms")
	T.log("finished")
end
