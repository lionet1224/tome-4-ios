-- Frame rate during AUTO, split into world ticks / map / HUD / particles per frame,
-- for the pace, effects and HUD-cache settings. Portrait (run with orientation="portrait").
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local TI = require "engine.TouchInput"
	local Map = require "engine.Map"
	local TW = require "mod.class.TouchWheel"
	local p, map = game.player, game.level.map
	local tm = game.uiset.touch_manual
	p.invulnerable = 1 p.no_breath = 1
	local function free(x, y) return map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR) end
	local spawned = {}
	local function spawn(n)
		local tries = 0
		while #spawned < n and tries < 400 do
			tries = tries + 1
			local x, y = p.x + rng.range(-7, 7), p.y + rng.range(-7, 7)
			if free(x, y) and core.fov.distance(p.x, p.y, x, y) >= 3 and p:hasLOS(x, y) then
				local a = game.zone:makeEntity(game.level, "actor", {type="vermin"}, nil, true)
				if a then
					game.zone:addEntity(game.level, a, "actor", x, y)
					a.faction = "enemies" a.rank = 1 a.max_life = 60 a.life = 60 a.exp_worth = 0
					spawned[#spawned+1] = a
				end
			end
		end
		p:playerFOV()
	end
	local function clear() for _, a in ipairs(spawned) do if not a.dead then a:die(p) end end spawned = {} end
	local function measure(tag, ms)
		TI.prof_tick, TI.prof_map, TI.prof_hud, TI.prof_uiset = 0, 0, 0, 0
		Map.prof_particles = 0
		local c0, b0 = tm.band_captures or 0, tm.band_blits or 0
		local f0, t0 = TI.frames or 0, core.game.getTime()
		T.wait(ms)
		local n = math.max(1, (TI.frames or 0) - f0)
		local dt = (core.game.getTime() - t0) / 1000
		local per = function(v) return (v or 0) / n * 1000 end
		local caps, blits = (tm.band_captures or 0) - c0, (tm.band_blits or 0) - b0
		T.log(("%s: %.1f fps | per frame: tick %.1f  map %.1f  hud %.1f  particles %.1f  uiset %.1f ms | band captures %d blits %d | auto %s"):format(
			tag, n / dt, per(TI.prof_tick), per(TI.prof_map), per(TI.prof_hud), per(Map.prof_particles), per(TI.prof_uiset), caps, blits, tostring(p.auto_act)))
		return n / dt, caps, blits
	end
	T.log("portrait", tostring(TI.portrait()), "band_y", tostring(tm.rects.band_y), "grab", tostring(core.display.grabScreen ~= nil))
	local bad = {}
	local idle = measure("idle, no AUTO", 3000)
	-- the cache logic itself: with the glow fallback off and nothing happening, idle frames must come from the texture
	tm.band_fallback_ms = 1000000
	local _, caps0, blits0 = measure("idle, cache without the time fallback", 3000)
	tm.band_fallback_ms = nil
	if blits0 < caps0 * 2 then bad[#bad+1] = ("idle cache: %d captures, %d blits"):format(caps0, blits0) end
	-- during AUTO every player turn refreshes the band, so the hit rate depends on frames per turn
	local function pass(tag, pace, effects, cache)
		TW.set("auto_pace", pace) TW.set("auto_effects", effects) TW.set("hud_cache", cache)
		spawn(6)
		p:autoActStart(true) T.wait(400)
		if not p.auto_act then T.log("AUTO did not start for", tag) end
		local fps, caps, blits = measure(tag, 4000)
		if not cache and blits > 0 then bad[#bad+1] = tag..": blits with the cache off" end
		p:autoActStop("stopped") T.wait(200)
		clear() T.wait(300)
		return fps
	end
	local dflt = pass("AUTO smooth / effects off / cache on (default)", "smooth", false, true)
	local nocache = pass("AUTO smooth / effects off / cache off", "smooth", false, false)
	local effects = pass("AUTO smooth / effects on / cache on", "smooth", true, true)
	local fast = pass("AUTO fast / effects off / cache on", "fast", false, true)
	TW.set("auto_pace", "smooth") TW.set("auto_effects", false) TW.set("hud_cache", true)
	T.log(("fps: idle %.1f  default %.1f  no-cache %.1f  effects %.1f  fast %.1f"):format(idle, dflt, nocache, effects, fast))
	T.shot("autofps-band")
	for _, b in ipairs(bad) do T.log("BAD", b) end
	T.log("finished")
end
