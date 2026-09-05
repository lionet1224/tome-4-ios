-- ToME iOS port: the interactive touch-controls coach.
-- Lives on game.touch_coach while the "touch-tutorial" practice level is up. A
-- banner at the top of the HUD names one thing to do; each step advances only
-- when the player actually did it (polled every frame), or when Skip is tapped.

require "engine.class"
local K = require "engine.ui.TouchKit"

module(..., package.seeall, class.make)

_M.HINT_AFTER_MS = 20000

local function now() return core.game.getTime() end

local function findByPractice(id)
	if not game.level then return nil end
	local out = {}
	for uid, e in pairs(game.level.entities) do
		if e.practice_id == id and not e.dead then out[#out+1] = e end
	end
	return out
end

local function spot(kind)
	local lev = game.level
	if not lev or not lev.spots then return nil end
	for _, s in ipairs(lev.spots) do
		if s.type == "practice" and s.subtype == kind then return s.x, s.y end
	end
end

local function playerHas(id)
	local p = game.player
	if not p then return false end
	local found = false
	p:inventoryApplyAll(function(inven, item, o) if o.practice_id == id then found = true end end)
	return found
end

---------------------------------------------------------------------------
-- the steps
---------------------------------------------------------------------------
_M.STEPS = {
	{
		id = "move",
		title = _t"Move",
		text = _t"Drag anywhere on the map: the tile you will step onto lights up. Release to step. Reach the marked tile.",
		hint = _t"Put a finger on the grass, slide it a little toward the mark, then let go. Drag back to the middle to cancel.",
		target = function(c) local x, y = spot("mark") return x, y end,
		check = function(c)
			local x, y = spot("mark")
			return x and game.player.x == x and game.player.y == y
		end,
	},
	{
		id = "fight",
		title = _t"Fight by hand",
		text = _t"A rat waits in the next room. Tap it to target it, then tap a skill in the drawer that opens at the bottom.",
		hint = _t"Any skill will do. Attack is on the far left of the drawer. SKILLS opens the drawer any time.",
		target = function(c) local r = findByPractice("rat")[1] if r then return r.x, r.y, r end end,
		tick = function(c)
			if game.player.touch_target then c.seen_target = true end
			local tm = game.uiset and game.uiset.touch_manual
			if tm and tm.drawer_open then c.seen_drawer = true end
		end,
		on_start = function(c) c.rats0 = #findByPractice("rat") end,
		check = function(c)
			-- a dead creature leaves the level's entity list at once, so count the living instead:
			-- one rat fewer than when the step began (or one hurt) = done, whatever killed it
			local alive = findByPractice("rat")
			if #alive < (c.rats0 or 3) then return true end
			for _, e in ipairs(alive) do if e.life and e.max_life and e.life < e.max_life then return true end end
			return false
		end,
	},
	{
		id = "act",
		title = _t"Act",
		text = _t"Two rats in the room after. Tap ACT: each tap does the next step of your routine, approach then attack. Keep tapping until both are down.",
		hint = _t"ACT is the big button at the bottom right. Hold it for its menu if you want to see the routine.",
		target = function(c) local r = findByPractice("rat")[1] if r then return r.x, r.y, r end end,
		check = function(c)
			return #findByPractice("rat") == 0
		end,
	},
	{
		id = "auto",
		title = _t"Auto",
		text = _t"Tap AUTO. It explores and fights on its own, and stops when an elite comes into view. Then finish the chief with ACT.",
		hint = _t"AUTO is next to ACT. When it stops, the chief is close: tap ACT to close in and attack.",
		target = function(c) local r = findByPractice("elite")[1] if r then return r.x, r.y, r end end,
		tick = function(c)
			if game.player.auto_act then c.seen_auto = true end
		end,
		check = function(c)
			return #findByPractice("elite") == 0 -- the chief dead is what matters, AUTO or not
		end,
	},
	{
		id = "pickup",
		title = _t"Pick up",
		text = _t"With no enemies in view you can tap a tile to walk there. Walk back to the dagger in the first room and pick it up.",
		hint = _t"Tap the dagger's tile to walk to it; standing on it, tap yourself to pick it up.",
		target = function(c) local x, y = spot("dagger") return x, y end,
		check = function(c) return playerHas("dagger") end,
	},
	{
		id = "hold",
		title = _t"Hold",
		text = _t"Hold a finger on the signpost tile to open the tile menu (inspect, travel, mark). Then close it with a two-finger tap.",
		hint = _t"Keep the finger still for a moment. Two fingers anywhere means back.",
		target = function(c) local x, y = spot("sign") return x, y end,
		tick = function(c)
			for _, d in ipairs(game.dialogs or {}) do
				if d.__CLASSNAME == "mod.dialogs.MapMenu" then c.seen_menu = true end
			end
			if c.seen_menu and #game.dialogs == 0 then c.menu_closed = true end
		end,
		check = function(c) return c.seen_menu and c.menu_closed end,
	},
	{
		id = "places",
		title = _t"Places",
		text = _t"Open More (the ... button), choose Places, and travel to the way out.",
		hint = _t"Places lists exits, shops and people wherever you are. Tap an entry to walk there.",
		target = function(c) local x, y = spot("exit") return x, y end,
		check = function(c)
			local x, y = spot("exit")
			return x and game.player.x == x and game.player.y == y
		end,
	},
	{
		id = "done",
		title = _t"You are ready",
		text = _t"That is all of it. Tap yourself on the way out to leave the practice.",
		target = function(c) local x, y = spot("exit") return x, y end,
		check = function(c) return false end,
	},
}

---------------------------------------------------------------------------
-- lifecycle
---------------------------------------------------------------------------
function _M:init()
	self.step = 1
	self.started_at = now()
	self.done_at = nil
	self:startStep()
end

function _M:startStep()
	local s = _M.STEPS[self.step]
	self.started_at = now()
	self.hinting = false
	if s and s.on_start then s.on_start(self) end
	print("[COACH] step", self.step, s and s.id or "?")
end

function _M:current() return _M.STEPS[self.step] end

function _M:advance()
	print("[COACH] step", self.step, "done")
	if self.step >= #_M.STEPS then return end
	self.step = self.step + 1
	self:startStep()
end

function _M:skip()
	print("[COACH] step", self.step, "skipped")
	if self.step >= #_M.STEPS then return end
	self.step = self.step + 1
	self:startStep()
end

-- polled every frame from the HUD
function _M:tick()
	local s = self:current()
	if not s or not game.player or not game.level then return end
	if s.tick then pcall(s.tick, self) end
	local ok, done = pcall(s.check, self)
	if ok and done then self:advance() return end
	if not self.hinting and s.hint and now() - self.started_at > _M.HINT_AFTER_MS then self.hinting = true end
end

---------------------------------------------------------------------------
-- drawing: banner at the top centre, pulsing marker on the objective
---------------------------------------------------------------------------
function _M:layout()
	local TI = require "engine.TouchInput"
	local sa = TI.safeArea()
	-- between the character panel (left) and the minimap (right), under neither
	local x = sa.l + 360
	local w = math.max(420, game.w - sa.r - 310 - x)
	local y = sa.t + 8
	return x, y, w
end

function _M:display()
	self:tick()
	if game.dialogs and #game.dialogs > 0 then
		if game.mouse.areas_name and game.mouse.areas_name.touch_coach_skip then game.mouse:unregisterZone("touch_coach_skip") end
		return
	end
	local s = self:current()
	if not s then return end
	local x, y, w = self:layout()
	local text = (self.hinting and s.hint) or s.text
	local lines = K.wrap(text, K.font(15), w - 24 - 110, 3)
	local h = 34 + #lines * 19 + 10
	K.quad(x, y, w, h, {14, 15, 18}, 225)
	K.frame(x, y, w, h, K.GOLD, 2)
	K.draw(K.text(("%d / %d"):format(self.step, #_M.STEPS), 11, 142, 136, 120, true), x + 12, y + 8)
	K.draw(K.text(s.title, 18, 240, 212, 138, true, w - 140), x + 60, y + 6)
	for i, l in ipairs(lines) do K.draw(K.text(l, 15, 234, 227, 209, false, w - 24 - 110), x + 12, y + 32 + (i - 1) * 19) end
	-- skip
	local bx, by, bw, bh = x + w - 100, y + 8, 88, 34
	local down = K.pressed(bx, by, bw, bh)
	K.quad(bx, by, bw, bh, down and {62, 58, 40} or {36, 39, 47})
	K.frame(bx, by, bw, bh, {88, 91, 100}, 1)
	K.draw(K.text(self.step >= #_M.STEPS and _t"Close" or _t"Skip", 14, 234, 227, 209, true), bx + 24, by + 8)
	if game.mouse.areas_name and game.mouse.areas_name.touch_coach_skip then game.mouse:unregisterZone("touch_coach_skip") end
	game.mouse:registerZone(bx, by, bw, bh, function(button, mx, my, xrel, yrel, cbx, cby, event)
		if button == "left" and event == "button" then
			if self.step >= #_M.STEPS then game.touch_coach = nil if game.mouse.areas_name and game.mouse.areas_name.touch_coach_skip then game.mouse:unregisterZone("touch_coach_skip") end
			else self:skip() end
		end
		return true
	end, nil, "touch_coach_skip", false, 1)
	-- objective marker
	if s.target then
		local ok, tx, ty = pcall(s.target, self)
		if ok and tx and ty and game.level.map:isBound(tx, ty) and game.level.map.seens(tx, ty) then
			local map = game.level.map
			local sx, sy = map:getTileToScreen(tx, ty) -- top-left corner (the centred form put the frame half a tile off)
			local tw, th = map.tile_w * (map.zoom or 1), map.tile_h * (map.zoom or 1)
			local pulse = 0.55 + 0.45 * math.sin(now() / 180)
			K.frame(sx - 3, sy - 3, tw + 6, th + 6, K.GOLD, 3)
			K.quad(sx, sy, tw, th, K.GOLD, math.floor(40 * pulse))
		end
	end
end

---------------------------------------------------------------------------
-- entry points
---------------------------------------------------------------------------
-- called by the zone's on_enter
function _M.begin()
	if not game or not game.level or not game.zone or game.zone.short_name ~= "touch-tutorial" then return end
	game.touch_coach = _M.new()
end

-- the way out: wrap up and return to the title screen the way the stock tutorial does
function _M.finish()
	print("[COACH] finish")
	game.touch_coach = nil
	pcall(function() if game.mouse.areas_name and game.mouse.areas_name.touch_coach_skip then game.mouse:unregisterZone("touch_coach_skip") end end)
	local Dialog = require "engine.ui.Dialog"
	local okd = pcall(function()
		Dialog:simplePopup(_t"Touch practice", _t"You have the controls. Back to the title screen to make a real character.", function() util.showMainMenu() end)
	end)
	if not okd then util.showMainMenu() end
end

-- start a fresh practice character: a reboot into the game module with a flag the birther reads
function _M.start()
	local Module = require "engine.Module"
	local mod = game and game.__mod_info
	if not mod or not mod.engine then
		-- from the boot menu the caller passes the module definition itself
		return false
	end
	local function go() Module:instanciate(mod, "player", true, false, "touch_practice=true") end
	-- from inside a real game: save it first and say so, the practice level is a throwaway character
	if game.zone and game.zone.short_name ~= "touch-tutorial" and game.player and game.player.x then
		require("engine.ui.Dialog"):yesnoPopup(_t"Practice the controls", _t"Your game is saved first; the practice level uses a throwaway character and returns to the title screen when done. Go?", function(ret)
			if not ret then return end
			game:saveGame()
			game:onTickEnd(go)
		end, _t"Go", _t"Not now")
		return true
	end
	go()
	return true
end

function _M.startFromBoot(mod)
	local Module = require "engine.Module"
	Module:instanciate(mod, "player", true, false, "touch_practice=true")
end
