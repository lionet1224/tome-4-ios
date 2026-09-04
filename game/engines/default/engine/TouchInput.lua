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
_M.DEFAULTS = {wheel=true, trigger="hold", pos="finger", zone="thirds", wedges=8, hold_ms=160, unlock_all=true, emulate=false}

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
local function motion(button, x, y, xrel, yrel) emit(function(m) m:receiveMouseMotion(button, x, y, xrel or 0, yrel or 0) end) end
local function click(button, x, y)
	emit(function(m)
		m:receiveMouseMotion("none", x, y, 0, 0)
		m:receiveMouse(button, x, y, false)
		m:receiveMouse(button, x, y, true)
	end)
end
local function park() _M.park_cursor = 2 end

function _M.escape()
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

function _M.fingerDown(id, x, y)
	-- a touch that starts with nothing down is a fresh gesture: drop stale state
	if _M.nb <= 0 or (not _M.t and not _M.multi) then
		if _M.nb > 0 then print("[TOUCH] stale gesture state reset", _M.nb) end
		_M.reset()
	end
	if not _M.fingers[id] then _M.nb = _M.nb + 1 end
	_M.fingers[id] = true
	if _M.nb >= 2 then
		local t = _M.t
		if t then
			if t.wheel and _M.wheel then _M.wheel:cancel() end
			if t.moved and not t.held and not t.wheel then emit(function(m) m:receiveMouse("left", t.x, t.y, true) end) end
			t.moved = true
			t.multi = true
		end
		_M.multi = {t0=now(), fired=false}
		return
	end
	_M.t = {id=id, x0=x, y0=y, x=x, y=y, t0=now(), moved=false, held=false}
	if _M.wheel then _M.t.wheel_zone = _M.wheel:zoneOf(x, y) end
end

function _M.fingerMove(id, x, y)
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
	if not t.moved then
		if not far then return end
		t.moved = true
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
	if m and not m.fired and not m.pinched and now() - m.t0 < 600 then
		m.fired = true
		_M.escape()
	end
	if _M.nb > 0 then return end
	local t = _M.t
	_M.t, _M.multi = nil, nil
	if not t then return end
	if t.wheel then
		if _M.wheel then _M.wheel:release() end
		park()
		return
	end
	if t.multi then return end
	if t.held then
		if t.hold_fired then park() return end
		if not t.hover and not t.moved then
			print("[TOUCH] long-press -> right click at", t.x0, t.y0)
			click("right", t.x0, t.y0)
		end
		return -- after a hover-scrub the cursor (and its tooltip) stays put
	end
	if t.moved then
		emit(function(mm) mm:receiveMouse("left", x, y, true) end)
		return
	end
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
function _M.tick()
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
-- home indicator on iOS; `touch.safe = {l=,t=,r=,b=}` overrides, e.g. on the Mac)
function _M.safeArea()
	local ts = config.settings.touch
	if ts and ts.safe then return ts.safe end
	local w = (type(game) == "table" and game.w) or (core.display.size())
	if not _M._safe or _M._safe_w ~= w then
		local l, t, r, b, pw, ph = 0, 0, 0, 0, 0, 0
		if core.display.safeArea then l, t, r, b, pw, ph = core.display.safeArea() end
		_M._safe = {l=l or 0, t=t or 0, r=r or 0, b=b or 0, pw=pw or 0, ph=ph or 0}
		_M._safe_w = w
	end
	return _M._safe
end

--- Draw a synthetic Dynamic Island where the real one sits (simulator
-- screenshots do not include it): `touch.show_island = true`
local function drawIsland()
	local sa = _M.safeArea()
	if not (sa.l and sa.l > 0) then return end
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
		function T.tap(x, y) down(x, y) T.wait(60) up(x, y) T.wait(120) end
		function T.hold(x, y, ms) down(x, y) T.wait(ms or 600) up(x, y) T.wait(120) end
		function T.swipe(x1, y1, x2, y2, ms, hold_first)
			down(x1, y1)
			if hold_first then T.wait(hold_first) end
			local steps = 12
			for i = 1, steps do
				_M.fingerMove(1, x1 + (x2 - x1) * i / steps, y1 + (y2 - y1) * i / steps)
				T.wait((ms or 300) / steps)
			end
			up(x2, y2) T.wait(120)
		end
		function T.two_finger() _M.fingerDown(1, 500, 300) _M.fingerDown(2, 560, 300) T.wait(60) _M.fingerUp(2, 560, 300) _M.fingerUp(1, 500, 300) T.wait(120) end
		function T.key(name) local k = engine.KeyBind.current if k then k:triggerVirtual(name) end T.wait(120) end
		function T.log(...) print("[SCRIPT]", ...) end
		function T.shot(name)
			-- taken at the end of the next frame, once dialogs are drawn (frameEnd)
			_M.pending_shot = name
			T.wait(120)
		end
		_M.script = {co=coroutine.create(function() body(T) end), wake_fct=function() return wake end, game=game}
		print("[TOUCH] script started", path)
	end
	local s = _M.script
	if now() < s.wake_fct() then return end
	local ok, err = coroutine.resume(s.co)
	if not ok then print("[TOUCH] script error", err) end
	if coroutine.status(s.co) == "dead" then _M.script_done = true print("[SCRIPT] done") end
end
