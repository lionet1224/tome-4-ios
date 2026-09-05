-- ToME iOS port: the touch controls practice level (see mod.class.TouchCoach)

return {
	name = _t"Touch practice",
	level_range = {1, 1},
	level_scheme = "player",
	max_level = 1,
	decay = {300, 800},
	actor_adjust_level = function(zone, level, e) return zone.base_level + e:getRankLevelAdjust() end,
	width = 40, height = 20,
	all_lited = true,
	persistent = "zone",
	ambient_music = "Woods of Eremae.ogg",
	no_level_connectivity = true,
	no_worldport = true,
	generator =  {
		map = {
			class = "engine.generator.map.Static",
		},
		actor = {
			class = "mod.class.generator.actor.Random",
			nb_npc = {0, 0},
		},
		object = {
			class = "engine.generator.object.Random",
			nb_object = {0, 0},
		},
		trap = {
			class = "engine.generator.trap.Random",
			nb_trap = {0, 0},
		},
	},
	levels =
	{
		[1] = {
			generator = { map = { map = "touch-tutorial/practice" }, },
		},
	},
	on_enter = function(lev, old_lev, newzone)
		-- the coach drives the practice; it is recreated on every entry
		game:onTickEnd(function()
			local ok, TC = pcall(require, "mod.class.TouchCoach")
			if ok and TC and TC.begin then TC.begin() end
		end)
	end,
}
