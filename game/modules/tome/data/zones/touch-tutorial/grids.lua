-- ToME iOS port: practice level terrain
load("/data/general/grids/basic.lua")
load("/data/general/grids/forest.lua")

newEntity{ base = "GRASS", define_as = "PRACTICE_MARK",
	name = "practice mark", image = "terrain/grass.png",
	add_mos = {{image = "terrain/marble_floor.png", display_w = 0.6, display_h = 0.6, display_x = 0.2, display_y = 0.2}},
	practice_id = "mark",
}

newEntity{ base = "GRASS", define_as = "PRACTICE_SIGN",
	name = "signpost", image = "terrain/grass.png",
	add_mos = {{image = "terrain/signpost.png"}},
	practice_id = "sign",
	does_block_move = false,
}

newEntity{ base = "GRASS", define_as = "PRACTICE_EXIT",
	name = "way out of the practice", image = "terrain/marble_floor.png",
	add_mos = {{image = "terrain/stair_down.png"}},
	notice = true, always_remember = true,
	change_level = 1, change_zone = "wilderness",
	practice_id = "exit",
	change_level_check = function(self, who)
		-- leaving ends the practice; the coach shows the wrap-up and returns to the title screen
		local ok, TC = pcall(require, "mod.class.TouchCoach")
		if ok and TC then TC.finish() end
		return true
	end,
}
