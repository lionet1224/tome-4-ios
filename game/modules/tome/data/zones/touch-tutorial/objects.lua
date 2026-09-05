-- ToME iOS port: practice level items
load("/data/general/objects/objects.lua")

newEntity{ base = "BASE_KNIFE", define_as = "PRACTICE_DAGGER",
	name = "practice dagger", unided_name = "practice dagger",
	level_range = {1, 1}, cost = 0, rarity = false,
	combat = { dam = 5, apr = 4, physcrit = 4, dammod = {dex=0.45, str=0.45} },
	practice_id = "dagger",
	identified = true,
}
