-- frame rate idle vs. with dialogs, with the time spent in the HUD and in the dialogs per frame
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local TI = require "engine.TouchInput"
	local function measure(tag, ms)
		TI.prof_uiset, TI.prof_dialogs = 0, 0
		local f0, t0 = TI.frames or 0, core.game.getTime()
		T.wait(ms)
		local n, dt = (TI.frames or 0) - f0, (core.game.getTime() - t0) / 1000
		local fps = n / dt
		T.log(("%s: %.1f fps  hud %.1f ms/frame  dialogs %.1f ms/frame  (%d frames)"):format(tag, fps, TI.prof_uiset / math.max(1, n) * 1000, TI.prof_dialogs / math.max(1, n) * 1000, n))
		return fps
	end
	T.log("fbo: full_fbo", tostring(game.full_fbo ~= nil), "map fbo", tostring(game.fbo ~= nil), "newFBO works", tostring(core.display.newFBO(64, 64) ~= nil))
	local idle = measure("idle", 3000)
	T.key("SHOW_INVENTORY") T.wait(800)
	local inv = measure("inventory", 3000)
	T.shot("inv-static")
	T.log("static background:", tostring(game.touch_bg_valid), "tex", tostring(game.touch_bg_tex ~= nil))
	T.key("EXIT") T.wait(500)
	T.key("LEVELUP") T.wait(800)
	local lvl = measure("level-up", 3000)
	T.key("EXIT") T.wait(500)
	game.uiset.touch_manual:openMore() T.wait(600)
	local more = measure("More popup", 3000)
	T.key("EXIT") T.wait(500)
	game:registerDialog(require("mod.dialogs.TouchPlaces").new()) T.wait(800)
	local places = measure("Places", 3000)
	T.key("EXIT") T.wait(500)
	-- a lore popup, with an illustration if one is loaded
	local defs = require("mod.class.interface.PartyLore").lore_defs
	local def, first
	for _, l in ipairs(defs) do if type(l.lore) == "string" and l.name then first = first or l if l.image then def = l break end end end
	def = def or first
	if def then
		local c0 = os.clock()
		local d = require("mod.dialogs.LorePopup").new(def, game.w * 0.6)
		local build = (os.clock() - c0) * 1000
		game:registerDialog(d) T.wait(800)
		T.log(("lore popup '%s' image=%s built in %.0f ms; %dx%d = %.0f%% of the screen"):format(tostring(def.name), tostring(def.image), build, d.w, d.h, 100 * d.w * d.h / (game.w * game.h)))
		TI.prof_uis = {}
		local nf0 = TI.frames or 0
		measure("lore popup", 3000)
		local nf = math.max(1, (TI.frames or 0) - nf0)
		local rows = {}
		for k, v in pairs(TI.prof_uis) do rows[#rows+1] = {k=k, ms=v / nf * 1000} end
		table.sort(rows, function(a, b) return a.ms > b.ms end)
		for i = 1, math.min(6, #rows) do T.log(("  lore widget %s: %.1f ms/frame"):format(rows[i].k, rows[i].ms)) end
		TI.prof_uis = nil
		T.key("EXIT") T.wait(500)
	else T.log("no lore def loaded") end
	T.log("dialogs still open:", #game.dialogs, tostring(game.dialogs[#game.dialogs] and game.dialogs[#game.dialogs].title), "snapshot", tostring(game.touch_bg_fbo ~= nil))
	measure("idle again", 2000)
	T.log("finished")
end
