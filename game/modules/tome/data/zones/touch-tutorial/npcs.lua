-- ToME iOS port: practice level creatures (weak, so the controls are the only challenge)
local Talents = require("engine.interface.ActorTalents")

newEntity{
	define_as = "BASE_PRACTICE_RAT",
	type = "vermin", subtype = "rodent",
	display = "r", color=colors.SLATE,
	image = "npc/vermin_rodent_giant_grey_rat.png",
	body = { INVEN = 10 },
	infravision = 10,
	sound_moam = {"creatures/rats/rat_hurt_%d", 1, 2},
	sound_die = {"creatures/rats/rat_die_%d", 1, 2},
	autolevel = "warrior",
	ai = "dumb_talented_simple", ai_state = { ai_move="move_complex", talent_in=3, },
	stats = { str=6, dex=8, mag=3, con=4 },
	combat = { dam=2, atk=0, apr=0, sound="creatures/rats/rat_attack" },
	combat_armor = 0, combat_def = 0,
	size_category = 1,
	level_range = {1, 1}, exp_worth = 0,
	no_drops = true,
	not_power_source = {arcane=true, technique_ranged=true},
}

newEntity{ base = "BASE_PRACTICE_RAT", define_as = "PRACTICE_RAT",
	name = "practice rat",
	rank = 1,
	max_life = 12, life_rating = 0,
	practice_id = "rat",
}

newEntity{ base = "BASE_PRACTICE_RAT", define_as = "PRACTICE_ELITE_RAT",
	name = "practice rat chief", color=colors.GOLD,
	rank = 3,
	max_life = 30, life_rating = 0,
	combat = { dam=3, atk=0, apr=0 },
	practice_id = "elite",
}
