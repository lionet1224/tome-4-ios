-- T-Engine4 iOS port: the touch input layer.
--
-- SDL's touch-as-mouse emulation is switched off (main.c); every finger event
-- lands here and this module decides what the gesture means, then emits the
-- mouse events the rest of the engine understands, in a known order:
--   tap                  -> motion, left down, left up, cursor parked off-screen
--   drag                 -> left down at the start, motion with "left", left up
--   hold (450 ms), lift  -> right click (context menus)
--   hold, then drag      -> hover-scrub: motion with no button (tooltips follow)
--   two-finger tap       -> Escape (EXIT of the current key handler)
--   pinch                -> on_pinch(delta) (the map zooms)
--   hold/drag in a wheel zone -> the radial wheel (a provider set by the uiset)
-- On a desktop build with `touch = {emulate=true}` the mouse is turned into a
-- finger so the same code paths run on the Mac.

require "engine.class"
module(..., package.seeall, class.make)

_M.LONG_PRESS_MS = 450
_M.MOVE_TOLERANCE = 18
_M.DEFAULTS = {wheel=false, drag_step=true, trigger="hold", pos="finger", zone="thirds", wedges=8, hold_ms=160, unlock_all=true, emulate=false, auto_life=50, auto_res=25, auto_rare=true, auto_dim=true, auto_buzz=true, orientation="auto", hand="left"}

function _M.setting(k)
	local t = config.settings.touch
	local v = t and t[k]
	if v == nil then return _M.DEFAULTS[k] end
	return v
end

--- Is the touch UI on (iOS, or desktop emulation)?
function _M.active()
	if __IOS__ then return true end
	local t = config.settings.touch
	return (t and t.emulate) and true or false
end

--- Desktop only: the mouse plays a finger
function _M.emulating()
	if __IOS__ then return false end
	local t = config.settings.touch
	return (t and t.emulate) and true or false
end

-- providers (set by the game module)
_M.wheel = nil      -- object with zoneOf(x,y) / openAt(side,x,y) / move(x,y) / release() / cancel() / open
_M.on_pinch = nil   -- function(delta)
_M.on_hold = nil    -- function(x, y) -> true when a hold there should act at once (buttons), not on release
_M.on_any_touch = nil -- function(x, y): every finger-down (auto-act stops on it)
_M.on_hover_end = nil -- function(x, y): a hold-then-drag was released there (drag and drop)
_M.on_map_drag = nil -- function(phase, t, x, y): a plain drag; "start" returns true to claim it as a
                     -- movement gesture (then "move"/"tick"/"end"/"cancel" follow and no mouse drag is emitted)
                     -- or "hud" to own it for a HUD element (no map pan, no click on release; the
                     -- element reads _M.t itself; "end" is still delivered)
_M.script_ready = nil -- function() -> true once the game module is really playable

-- gesture state
_M.t = nil          -- the primary finger: {x0,y0,x,y,t0,moved,held,hover,wheel,wheel_zone}
_M.fingers = {}
_M.nb = 0
_M.multi = nil
_M.injecting = false

local function now() return core.game.getTime() end
local function mouse() return engine.Mouse.current end

local function emit(fct)
	local m = mouse()
	if not m then return end
	_M.injecting = true
	local ok, err = pcall(fct, m)
	_M.injecting = false
	if not ok then error(err) end
end
local function motion(button, x, y, xrel, yrel) _M.pointer_x, _M.pointer_y = x, y emit(function(m) m:receiveMouseMotion(button, x, y, xrel or 0, yrel or 0) end) end
--- The point the current touch is at: HUD handlers that forward a tap to the map
-- must use this instead of core.mouse.get(), which is the (stale) SDL mouse
function _M.pointer()
	if _M.active() and _M.pointer_x then return _M.pointer_x, _M.pointer_y end
	return core.mouse.get()
end
local function click(button, x, y)
	_M.pointer_x, _M.pointer_y = x, y
	emit(function(m)
		m:receiveMouseMotion("none", x, y, 0, 0)
		m:receiveMouse(button, x, y, false)
		m:receiveMouse(button, x, y, true)
	end)
	-- the motion above makes the map show the tile's tooltip, and nothing moves the
	-- pointer away afterwards (tapping yourself to rest left your own sheet up)
	if _M.clearTooltip then _M.clearTooltip("tap") end
end
local function park() _M.park_cursor = 2 end

function _M.escape()
	_M.hideKeyboard("escape")
	print("[TOUCH] two-finger tap -> EXIT")
	local k = engine.KeyBind and engine.KeyBind.current or (engine.Key and engine.Key.current)
	if k and k.triggerVirtual then k:triggerVirtual("EXIT") end
end

local function openWheel(t)
	t.wheel = true
	_M.wheel:openAt(t.wheel_zone, t.x0, t.y0)
end

function _M.reset()
	_M.t, _M.fingers, _M.nb, _M.multi = nil, {}, 0, nil
end

--- The map tooltip (game.tooltip_x) is shown while a finger scrubs after a hold;
-- nothing moves a pointer away afterwards, so it is cleared on release and on
-- the next touch (the phone showed one stuck on a terrain tile)
function _M.clearTooltip(why)
	if type(game) ~= "table" or game.tooltip_x == nil then return end
	game.tooltip_x, game.tooltip_y = nil, nil
	print("[TOUCH] tooltip cleared:", why)
end

function _M.fingerDown(id, x, y)
	_M.last_down = now()
	local o = _M.osk
	if o and o.box then
		local b = o.box
		local inside = b.last_screen_x and x >= b.last_screen_x and x < b.last_screen_x + (b.w or 0) and y >= b.last_screen_y and y < b.last_screen_y + (b.h or 0)
		if not inside then _M.hideKeyboard("tap outside the box") end
	end
	-- a touch that starts with nothing down is a fresh gesture: drop stale state
	if _M.nb <= 0 or (not _M.t and not _M.multi) then
		if _M.nb > 0 then print("[TOUCH] stale gesture state reset", _M.nb) end
		_M.reset()
	end
	if not _M.fingers[id] then _M.nb = _M.nb + 1 end
	_M.fingers[id] = {x=x, y=y}
	if _M.nb >= 2 then
		local t = _M.t
		if t then
			if t.wheel and _M.wheel then _M.wheel:cancel() end
			if t.step then t.step = nil if _M.on_map_drag then pcall(_M.on_map_drag, "cancel", t) end end
			if t.hud then t.hud = nil if _M.on_map_drag then pcall(_M.on_map_drag, "cancel", t) end end
			if t.moved and not t.held and not t.wheel and not t.step_was then emit(function(m) m:receiveMouse("left", t.x, t.y, true) end) end
			t.moved = true
			t.multi = true
		end
		_M.multi = {t0=now(), fired=false}
		return
	end
	_M.t = {id=id, x0=x, y0=y, x=x, y=y, t0=now(), moved=false, held=false}
	_M.clearTooltip("new touch")
	if _M.on_any_touch then pcall(_M.on_any_touch, x, y) end
	if _M.wheel then _M.t.wheel_zone = _M.wheel:zoneOf(x, y) end
end

--- Two fingers: pan the map by the movement of their midpoint (pinch keeps
-- zooming; a gesture can do both, like a map app). The pan is applied here in
-- tiles, with the sub-tile remainder carried over.
local function twoFingerPan()
	local m = _M.multi
	if not m or _M.nb < 2 then return end
	local n, cx, cy = 0, 0, 0
	for _, f in pairs(_M.fingers) do if type(f) == "table" then n = n + 1 cx, cy = cx + f.x, cy + f.y end end
	if n < 2 then return end
	cx, cy = cx / n, cy / n
	if not m.cx then m.cx, m.cy, m.pdx, m.pdy = cx, cy, 0, 0 return end
	m.pdx, m.pdy = m.pdx + (cx - m.cx), m.pdy + (cy - m.cy)
	m.cx, m.cy = cx, cy
	if not m.panned and (math.abs(m.pdx) > 12 or math.abs(m.pdy) > 12) then m.panned = true print("[TOUCH] two-finger pan") end
	if not m.panned then return end
	local map = type(game) == "table" and game.level and game.level.map
	if not map or not map.setScroll then return end
	local tw, th = map.tile_w * (map.zoom or 1), map.tile_h * (map.zoom or 1)
	local sx, sy = math.floor(m.pdx / tw), math.floor(m.pdy / th)
	if sx ~= 0 or sy ~= 0 then
		map:setScroll(map.mx - sx, map.my - sy)
		m.pdx, m.pdy = m.pdx - sx * tw, m.pdy - sy * th
	end
end

function _M.fingerMove(id, x, y)
	if type(_M.fingers[id]) == "table" then _M.fingers[id].x, _M.fingers[id].y = x, y end
	if _M.nb >= 2 then twoFingerPan() end
	local t = _M.t
	if not t or _M.nb >= 2 or t.multi then return end
	local px, py = t.x, t.y
	t.x, t.y = x, y
	if t.wheel then _M.wheel:move(x, y) return end
	local far = math.abs(x - t.x0) > _M.MOVE_TOLERANCE or math.abs(y - t.y0) > _M.MOVE_TOLERANCE
	if t.wheel_zone and _M.wheel and _M.setting("trigger") == "drag" and far and not t.held and not t.moved then
		openWheel(t)
		_M.wheel:move(x, y)
		return
	end
	if t.held then
		if t.hold_fired then return end
		if far and not t.hover then t.hover = true print("[TOUCH] hover-scrub") end
		if t.hover then motion("none", x, y, x - px, y - py) end
		return
	end
	if t.step then
		if _M.on_map_drag then pcall(_M.on_map_drag, "move", t, x, y) end
		return
	end
	if t.hud then return end -- a HUD element owns this drag (it reads _M.t): no map pan
	if not t.moved then
		if not far then return end
		t.moved = true
		-- a drag on the map may be a movement gesture (drag-to-step): the game claims it;
		-- a drag that starts on a HUD element (the skill strip) is that element's own scroll
		if _M.on_map_drag and _M.setting("drag_step") ~= false then
			local ok, claimed = pcall(_M.on_map_drag, "start", t, x, y)
			if ok and claimed == "hud" then
				t.hud, t.step_was = true, true
				print("[TOUCH] hud drag")
				return
			elseif ok and claimed then
				t.step, t.step_was = true, true
				pcall(_M.on_map_drag, "move", t, x, y)
				return
			end
		end
		print("[TOUCH] drag")
		emit(function(m)
			m:receiveMouseMotion("none", t.x0, t.y0, 0, 0)
			m:receiveMouse("left", t.x0, t.y0, false)
		end)
		motion("left", x, y, x - t.x0, y - t.y0)
	else
		motion("left", x, y, x - px, y - py)
	end
end

function _M.fingerUp(id, x, y)
	_M.fingers[id] = nil
	_M.nb = 0
	for _ in pairs(_M.fingers) do _M.nb = _M.nb + 1 end
	local m = _M.multi
	if m and not m.fired and not m.pinched and not m.panned and now() - m.t0 < 600 then
		m.fired = true
		_M.escape()
	end
	if _M.nb > 0 then return end
	local t = _M.t
	_M.multi = nil
	if not t then return end
	-- _M.t stays set while the release is delivered: handlers (the dialog
	-- drag-scroll) look at it to tell a drag's release from a click
	local function done() _M.t = nil end
	if t.wheel then
		done()
		if _M.wheel then _M.wheel:release() end
		park()
		return
	end
	if t.multi then done() return end
	if t.hud then
		t.hud = nil
		done()
		if _M.on_map_drag then pcall(_M.on_map_drag, "end", t, x, y) end
		park()
		return
	end
	if t.step then
		t.step = nil
		done()
		local ok, res = true, nil
		if _M.on_map_drag then ok, res = pcall(_M.on_map_drag, "end", t, x, y) end
		-- a thumb that rolled a little during a tap is not a flick: deliver the tap
		if ok and res == "tap" then print("[TOUCH] short drag -> tap", t.x0, t.y0) click("left", t.x0, t.y0) end
		park()
		return
	end
	if t.held then
		done()
		if t.hold_fired then park() return end
		if not t.hover and not t.moved then
			print("[TOUCH] long-press -> right click at", t.x0, t.y0)
			click("right", t.x0, t.y0)
			return
		end
		if _M.on_hover_end then pcall(_M.on_hover_end, x, y) end
		-- the scrub's tooltip has no pointer to follow away: drop it with the finger
		_M.clearTooltip("hover released")
		park()
		return
	end
	if t.moved then
		emit(function(mm) mm:receiveMouse("left", x, y, true) end)
		done()
		return
	end
	done()
	print("[TOUCH] tap", t.x0, t.y0)
	click("left", t.x0, t.y0)
	park()
end

function _M.gesture(nb_fingers, x, y, d_rot, d_pinch)
	local m = _M.multi
	if not m or nb_fingers < 2 then return end
	m.pinch = (m.pinch or 0) + (d_pinch or 0)
	if math.abs(m.pinch) > 0.015 then m.pinched = true end
	if m.pinched and _M.on_pinch and math.abs(m.pinch) >= 0.04 then
		local delta = m.pinch * 2.5
		m.pinch = 0
		print("[TOUCH] pinch zoom", delta)
		pcall(_M.on_pinch, delta)
	end
end

--- Called every frame by the engine
-- the on-screen keyboard belongs to one dialog's text box: hide it as soon as that
-- dialog is no longer on top (a popup over it, or it closed) so the popup is reachable
function _M.hideKeyboard(why)
	if not _M.osk then return end
	print("[IOS-OSK] hide:", why or "")
	_M.osk = nil
	if core.key and core.key.unicodeInput then core.key.unicodeInput(false) end
end

function _M.checkKeyboard()
	local o = _M.osk
	if not o then return end
	local top = game and game.dialogs and game.dialogs[#game.dialogs]
	if top ~= o.dialog or not top then _M.hideKeyboard("dialog changed") end
end

function _M.tick()
	_M.checkKeyboard()
	if not _M._orientation_applied and _M.active() then _M.applyOrientation() end
	local t = _M.t
	if t and not t.moved and not t.held and not t.wheel then
		local hold_ms = tonumber(_M.setting("hold_ms")) or 160
		local in_zone = t.wheel_zone and _M.wheel and _M.setting("trigger") == "hold"
		if in_zone and now() - t.t0 >= hold_ms then
			openWheel(t)
		elseif not in_zone and now() - t.t0 >= _M.LONG_PRESS_MS then
			t.held = true
			print("[TOUCH] hold")
			if _M.on_hold and _M.on_hold(t.x0, t.y0) then
				-- a button: act while the finger is still down
				t.hold_fired = true
				print("[TOUCH] hold -> right click now at", t.x0, t.y0)
				click("right", t.x0, t.y0)
			else
				motion("none", t.x0, t.y0, 0, 0) -- hover there so a tooltip can show
			end
		end
	end
	if t and t.step and _M.on_map_drag then pcall(_M.on_map_drag, "tick", t, t.x, t.y) end
	if _M.park_cursor then
		_M.park_cursor = _M.park_cursor - 1
		if _M.park_cursor <= 0 then
			_M.park_cursor = nil
			motion("none", -10, -10, 0, 0)
		end
	end
	_M.scriptTick()
end

--- Safe-area insets {l, t, r, b} in logical units (Dynamic Island / notch and
-- home indicator on iOS; `touch.safe = {l=,t=,r=,b=}` overrides, e.g. on the Mac).
-- Cached per screen size, so a rotation re-reads them.
function _M.safeArea()
	local ts = config.settings.touch
	if ts and ts.safe then return ts.safe end
	local w, h
	if type(game) == "table" and game.w and game.h then w, h = game.w, game.h else w, h = core.display.size() end
	if not _M._safe or _M._safe_w ~= w or _M._safe_h ~= h then
		local l, t, r, b, pw, ph = 0, 0, 0, 0, 0, 0
		if core.display.safeArea then l, t, r, b, pw, ph = core.display.safeArea() end
		_M._safe = {l=l or 0, t=t or 0, r=r or 0, b=b or 0, pw=pw or 0, ph=ph or 0}
		_M._safe_w, _M._safe_h = w, h
	end
	return _M._safe
end

--- Portrait: the screen is taller than wide (the phone rotated; iOS 16+ rotates live)
function _M.portrait()
	local w, h
	if type(game) == "table" and game.w and game.h then w, h = game.w, game.h else w, h = core.display.size() end
	return (h or 0) > (w or 0)
end

--- Which thumb presses Act: "left" or "right" (touch.hand; the layout mirrors)
function _M.hand()
	if _M.setting("hand") == "right" then return "right" end
	return "left"
end

--- Tell iOS which orientations are allowed (touch.orientation = auto | landscape |
-- portrait). Returns true when it took effect at once, false when a restart is needed.
function _M.applyOrientation()
	local mode = _M.setting("orientation")
	if mode ~= "landscape" and mode ~= "portrait" then mode = "auto" end
	_M._orientation_applied = mode
	if not core.display.setOrientation then return false end
	local ok, live = pcall(core.display.setOrientation, mode)
	print("[TOUCH] orientation", mode, (ok and live) and "live" or "restart needed")
	return (ok and live) and true or false
end

--- Draw a synthetic Dynamic Island where the real one sits (simulator
-- screenshots do not include it): `touch.show_island = true`
local function drawIsland()
	local sa = _M.safeArea()
	if not (sa.l and sa.l > 0) or _M.portrait() then return end
	local w, h = core.display.size()
	local f = (sa.pw and sa.pw > 0) and (w / sa.pw) or 1.5
	local iw, ih, ix = 37 * f, 126 * f, 11 * f   -- points: 37x126 pill, 11 from the edge
	local iy = (h - ih) / 2
	local rr = iw / 2
	core.display.drawQuad(ix, iy + rr, iw, ih - 2 * rr, 0, 0, 0, 255)
	if core.display.drawRingWedge then
		core.display.drawRingWedge(ix + rr, iy + rr, 0, rr, 0, 360, 0, 0, 0, 255)
		core.display.drawRingWedge(ix + rr, iy + ih - rr, 0, rr, 0, 360, 0, 0, 0, 255)
	end
	-- home indicator
	core.display.drawQuad(w / 2 - 70 * f, h - 8 * f - 5 * f, 140 * f, 5 * f, 255, 255, 255, 140)
end

--- Called by the engine at the very end of a frame (everything drawn)
function _M.frameEnd()
	if config.settings.touch and config.settings.touch.show_island then pcall(drawIsland) end
	local name = _M.pending_shot
	if not name then return end
	_M.pending_shot = nil
	local w, h = core.display.size()
	local png = core.display.getScreenshot and core.display.getScreenshot(0, 0, w, h)
	if png then local fh = fs.open("/shot-"..name..".png", "w") if fh then fh:write(png) fh:close() print("[SCRIPT] shot", name) end end
end

--- Desktop emulation: called by engine.Mouse before it dispatches a real mouse event.
-- Returns true when the event was consumed as a finger.
function _M.mouseAsFinger(button, x, y, isup)
	if _M.injecting or not _M.emulating() then return false end
	if button == "left" then
		if isup then _M.fingerUp(1, x, y) else _M.fingerDown(1, x, y) end
		return true
	elseif button == "right" then
		if isup then _M.escape() end
		return true
	end
	return false
end
function _M.mouseMotionAsFinger(button, x, y)
	if _M.injecting or not _M.emulating() then return false end
	if _M.t then _M.fingerMove(1, x, y) end
	return true
end

-- ---------------------------------------------------------------------------
-- Scripted gestures for tests: settings `touch.script = "/path/file.lua"`.
-- The file returns function(T) and runs in a coroutine once the game is up:
--   T.tap(x, y)  T.hold(x, y, ms)  T.swipe(x1, y1, x2, y2, ms)  T.wait(ms)
--   T.two_finger()  T.key("EXIT")  T.shot("name")  T.log("...")
function _M.scriptTick()
	local path = config.settings.touch and config.settings.touch.script
	if not path then return end
	-- the boot menu has a fake level/player: wait for a real game module
	local ingame = game and game.__mod_info and game.__mod_info.short_name ~= "boot" and game.level and game.player and game.player.x
	if config.settings.touch.script_early and game and game.__mod_info and game.__mod_info.short_name ~= "boot" then ingame = true end
	-- `touch.script_boot = true`: run the script on the title screen (boot module) too
	if config.settings.touch.script_boot and game and game.__mod_info and game.__mod_info.short_name == "boot" and game.dialogs and #game.dialogs > 0 then ingame = true end
	if ingame and _M.script_ready and not _M.script_ready() then ingame = false end
	if _M.script and _M.script.game ~= game then _M.script, _M.script_done = nil, nil end
	if _M.script_done then return end
	if not _M.script then
		if not ingame then return end
		local f, err = loadfile(path)
		if not f then print("[TOUCH] script load failed", err) _M.script_done = true return end
		local ok, body = pcall(f)
		if not ok or type(body) ~= "function" then print("[TOUCH] script must return a function", body) _M.script_done = true return end
		local T = {}
		local wake = 0
		function T.wait(ms) wake = now() + ms coroutine.yield() end
		function T.waitFor(fct, timeout) local t0 = now() while not fct() and now() - t0 < (timeout or 120000) do T.wait(300) end end
		local function down(x, y) _M.fingerDown(1, x, y) end
		local function up(x, y) _M.fingerUp(1, x, y) end
		function T.tap(x, y) down(x, y) up(x, y) T.wait(150) end
		-- a quick thumb roll: down, a few moves and up within the same frame
		function T.flick(x1, y1, x2, y2) down(x1, y1) for i = 1, 4 do _M.fingerMove(1, x1 + (x2 - x1) * i / 4, y1 + (y2 - y1) * i / 4) end up(x2, y2) T.wait(150) end
		function T.hold(x, y, ms) down(x, y) T.wait(ms or 600) up(x, y) T.wait(120) end
		function T.swipe(x1, y1, x2, y2, ms, hold_first)
			down(x1, y1)
			if hold_first then T.wait(hold_first) end
			local steps = 12
			for i = 1, steps do
				_M.fingerMove(1, x1 + (x2 - x1) * i / steps, y1 + (y2 - y1) * i / steps)
				-- a real finger moves within a frame; the slow sim frames must not turn the start into a hold
				local moved = math.sqrt(((x2 - x1) * i / steps)^2 + ((y2 - y1) * i / steps)^2)
				if hold_first or moved >= 20 then T.wait((ms or 300) / steps) end
			end
			up(x2, y2) T.wait(120)
		end
		function T.two_finger() _M.fingerDown(1, 500, 300) _M.fingerDown(2, 560, 300) T.wait(60) _M.fingerUp(2, 560, 300) _M.fingerUp(1, 500, 300) T.wait(120) end
		function T.key(name) local k = engine.KeyBind.current if k then k:triggerVirtual(name) end T.wait(120) end
		-- stdout can lose its tail after a reboot; mirror the script log into a file the runner reads
		local function filelog(...)
			local parts = {} for i = 1, select("#", ...) do parts[#parts+1] = tostring(select(i, ...)) end
			local f = fs.open("/touch-test.log", "a")
			if f then f:write(table.concat(parts, "\t") .. "\n") f:close() end
		end
		function T.log(...) print("[SCRIPT]", ...) filelog("[SCRIPT]", ...) end
		T.filelog = filelog
		function T.close() local d = game.dialogs and game.dialogs[#game.dialogs] if d then game:unregisterDialog(d) end T.wait(120) end
		function T.shot(name)
			-- taken at the end of the next frame, once dialogs are drawn (frameEnd)
			_M.pending_shot = name
			T.wait(120)
		end
		_M.script = {co=coroutine.create(function() body(T) end), wake_fct=function() return wake end, game=game, filelog=filelog}
		print("[TOUCH] script started", path)
	end
	local s = _M.script
	-- synthetic fingers are not SDL events, so the idle throttle stops the engine ticking;
	-- keep the world moving while a script runs (same budget the soak autopilot uses)
	if game and game.tick and game.level and game.player and not game.paused and game.__mod_info and game.__mod_info.short_name ~= "boot" then
		local t0 = now()
		for _ = 1, 12 do if now() - t0 > 20 or game.paused then break end game:tick() end
	end
	if now() < s.wake_fct() then return end
	local ok, err = coroutine.resume(s.co)
	if not ok then print("[TOUCH] script error", err) end
	if not ok and s.filelog then s.filelog("[TOUCH] script error", tostring(err)) end
	if coroutine.status(s.co) == "dead" then _M.script_done = true print("[SCRIPT] done") if s.filelog then s.filelog("[SCRIPT] done") end end
end
