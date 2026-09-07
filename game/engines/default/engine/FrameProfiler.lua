-- iOS port: where a frame's time goes. Installed once the game runs; every frame over
-- SLOW_MS prints a breakdown, and a summary goes out every 5 s. Read it from the phone's
-- Documents/te4_log.txt (tools/ios/pull-log.sh). Sections: the world tick (with the NPC
-- turns inside it), map, HUD band, whole uiset, particles, dialogs, image loads, sound
-- loads, the message log, the damage flyers, and Lua memory growth.
local _M = {}

_M.SLOW_MS = 45
_M.installed = false
local acc = {}
local counts = {}
local function clock() return os.clock() end

local function wrap(tbl, key, section, counter)
	local orig = tbl[key]
	if type(orig) ~= "function" then return end
	tbl[key] = function(...)
		local t0 = clock()
		local a, b, c, d = orig(...)
		acc[section] = (acc[section] or 0) + (clock() - t0)
		if counter then counts[counter] = (counts[counter] or 0) + 1 end
		return a, b, c, d
	end
end

function _M.install()
	if _M.installed or type(game) ~= "table" or not game.tick or not game.level then return end
	_M.installed = true
	wrap(game, "tick", "tick", "ticks")
	local ok, NPC = pcall(require, "mod.class.NPC")
	if ok and NPC then wrap(NPC, "act", "ai", "npc_acts") end
	wrap(core.display, "loadImage", "images", "images")
	wrap(core.sound, "load", "sounds", "sounds")
	local ok2, Log = pcall(require, "engine.LogDisplay")
	if ok2 and Log then wrap(Log, "display", "log") end
	local ok3, Fly = pcall(require, "engine.FlyingText")
	if ok3 and Fly then wrap(Fly, "display", "flyers") wrap(Fly, "add", "flyers_add", "flyers") end
	print("[FRAME] profiler installed")
end

local base = {}
local last_t, sum_dt, n, slow, worst = nil, 0, 0, 0, 0
local sums = {}
local last_mem, last_turn = nil, nil
local last_summary = nil

local function ms(v) return (v or 0) * 1000 end

--- Called once per frame (from TouchInput.tick)
function _M.frame()
	if not _M.installed then _M.install() if not _M.installed then return end end
	if config.settings.touch and config.settings.touch.fps_log == false then return end
	local TI = require "engine.TouchInput"
	local Map = require "engine.Map"
	local now = core.game.getTime()
	if not last_t then last_t, last_summary = now, now last_mem = collectgarbage("count") last_turn = game.turn return end
	local dt = now - last_t
	last_t = now
	-- what the other timers gathered since the last frame (they keep accumulating for the
	-- tests that read them over seconds: take deltas instead of resetting them)
	local function take(cur, key)
		cur = cur or 0
		if cur < (base[key] or 0) then base[key] = 0 end
		local d = cur - (base[key] or 0)
		base[key] = cur
		return d
	end
	acc.map, acc.hud, acc.uiset, acc.dialogs, acc.particles = take(TI.prof_map, "map"), take(TI.prof_hud, "hud"), take(TI.prof_uiset, "uiset"), take(TI.prof_dialogs, "dialogs"), take(Map.prof_particles, "particles")
	local mem = collectgarbage("count")
	local dmem = mem - (last_mem or mem)
	last_mem = mem
	local dturn = (game.turn or 0) - (last_turn or 0)
	last_turn = game.turn
	n = n + 1 sum_dt = sum_dt + dt
	if dt > worst then worst = dt end
	for k, v in pairs(acc) do sums[k] = (sums[k] or 0) + (v or 0) end
	if dt > _M.SLOW_MS then
		slow = slow + 1
		local enemies = game.player and game.player.actEnemies and #game.player:actEnemies() or -1
		print(("[FRAME] %dms turn+%d enemies %d | tick %.0f (ai %.0f in %d) map %.0f hud %.0f uiset %.0f particles %.0f dialogs %.0f | images %.0f/%d sounds %.0f/%d log %.0f flyers %.0f (+%d) | mem %+dK%s"):format(
			dt, dturn, enemies, ms(acc.tick), ms(acc.ai), counts.npc_acts or 0, ms(acc.map), ms(acc.hud), ms(acc.uiset), ms(acc.particles), ms(acc.dialogs),
			ms(acc.images), counts.images or 0, ms(acc.sounds), counts.sounds or 0, ms(acc.log), ms(acc.flyers), counts.flyers or 0, math.floor(dmem),
			(game.player and game.player.auto_act) and " AUTO" or ""))
	end
	if now - last_summary >= 5000 then
		local avg = sum_dt / math.max(1, n)
		local per = function(k) return ms(sums[k]) / math.max(1, n) end
		print(("[FRAME] 5s: %.1f fps, avg %.1f ms, %d slow (worst %d) | avg per frame: tick %.1f ai %.1f map %.1f hud %.1f uiset %.1f particles %.1f dialogs %.1f images %.1f sounds %.1f log %.1f flyers %.1f | mem %dK"):format(
			1000 / math.max(1, avg), avg, slow, worst, per("tick"), per("ai"), per("map"), per("hud"), per("uiset"), per("particles"), per("dialogs"), per("images"), per("sounds"), per("log"), per("flyers"), math.floor(mem)))
		last_summary, sum_dt, n, slow, worst, sums = now, 0, 0, 0, 0, {}
	end
	-- reset our per-frame accumulators
	for k in pairs(acc) do acc[k] = 0 end
	for k in pairs(counts) do counts[k] = 0 end
end

return _M
