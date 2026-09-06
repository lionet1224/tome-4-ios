-- ToME iOS port: manual play controls (no radial wheels).
--   tap an enemy       -> it becomes the touch target (gold ring) and the skill strip slides in
--   tap a strip card   -> cast that talent at the target
--   drag on the map    -> preview the destination tile, release to step (the only way to
--                         walk while enemies are in view); hold still at the end to keep going
--   Skills button      -> opens/closes the drawer (the strip) at will; cards cast at the target,
--                         else at the nearest enemy, else aim by hand
--   "..." button       -> action sheet with everything the right wheel used to hold
-- Owned by the Minimalist uiset (self.touch_manual); drawn after the Act/AUTO dock.

require "engine.class"
local Map = require "engine.Map"
local Dialog = require "engine.ui.Dialog"
local K = require "engine.ui.TouchKit"
local TouchInput = require "engine.TouchInput"

module(..., package.seeall, class.make)

_M.DRAG_DEADZONE = 28
-- a release steps only after a deliberate flick: at least a tile of travel, or
-- a drag held long enough to have read the preview; a shorter, quicker wobble
-- was a tap (thumbs roll a few mm while tapping)
_M.STEP_MIN_PX = 44
_M.STEP_MIN_MS = 250
_M.REPEAT_AFTER_MS = 600
_M.REPEAT_EVERY_MS = 220
_M.BTN = 86
_M.CARD_W, _M.CARD_H = 68, 78
_M.STRIP_H = 96

local DIRS = {[-1]={[-1]=7, [0]=4, [1]=1}, [0]={[-1]=8, [0]=5, [1]=2}, [1]={[-1]=9, [0]=6, [1]=3}}

local function now() return core.game.getTime() end
local function quad(x, y, w, h, r, g, b, a) core.display.drawQuad(x, y, w, h, r, g, b, a or 255) end
local function frame(x, y, w, h, r, g, b, a, t)
	t = t or 3
	quad(x, y, w, t, r, g, b, a) quad(x, y + h - t, w, t, r, g, b, a) quad(x, y, t, h, r, g, b, a) quad(x + w - t, y, t, h, r, g, b, a)
end
local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end

function _M:init(uiset)
	self.uiset = uiset
	self.strip_scroll = 0
	self.rects = {}
	self.zones = {}
end

function _M:label(txt, x, y, scale, r, g, b, a)
	self.uiset.touch_wheel:drawLabel(txt, x, y, scale, r, g, b, a)
end

---------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------

--- Enemies in view, nearest first
function _M:enemies()
	local p = game.player
	if not p or not p.actEnemies then return {} end
	local list = p:actEnemies()
	table.sort(list, function(a, b) return a.d < b.d end)
	return list
end

function _M:nearestEnemy()
	local e = self:enemies()[1]
	return e and e.a or nil
end

--- The touch target, dropped when it is gone from view
function _M:target()
	local p = game.player
	local t = p and p.touch_target
	if not t then return nil end
	if t.dead or not t.x or not game.level or game.level.map(t.x, t.y, Map.ACTOR) ~= t or not p:canSee(t) then
		p.touch_target = nil
		return nil
	end
	return t
end

function _M:setTarget(a)
	local p = game.player
	if not p then return end
	if a then print("[TOUCH] target", a.name) else if p.touch_target then print("[TOUCH] target cleared") end end
	p.touch_target = a
	if a then self.drawer_open = true end
end

--- Cast a talent at a creature the way an Act step does; logs why when it cannot
function _M:cast(tid, target, allow_manual)
	local p = game.player
	if not p or game.key ~= game.normal_key then return false, _t"busy" end
	local t = tid and p:knowTalent(tid) and p:getTalentFromId(tid) or nil
	if not t then return false, _t"unknown talent" end
	local why
	if p:isTalentCoolingDown(t) then why = _t"cooling down"
	elseif not p:preUseTalent(t, true, true) then why = _t"not usable now" end
	if why then game.logPlayer(p, "%s: %s.", t.name, why) return false, why end
	local ok, tg = pcall(p.getTalentTarget, p, t)
	local aims = (ok and tg) or t.requires_target or (p:getTalentRange(t) or 0) > 0
	if not aims then print("[TOUCH] cast (no target)", t.name) p:useTalent(t.id) return true end
	if tg and (tg.type == "self" or (tg.range and tg.range == 0 and not tg.radius)) then print("[TOUCH] cast self", t.name) p:useTalent(t.id, nil, nil, nil, p) return true end
	if not target then
		if allow_manual then print("[TOUCH] cast manual", t.name) p:useTalent(t.id) return true end
		game.logPlayer(p, "%s: no enemy in view. Hold the button to aim by hand.", t.name)
		return false, _t"no target"
	end
	local d = core.fov.distance(p.x, p.y, target.x, target.y)
	-- out of range or sight for this target: let the game's own aiming decide instead of refusing
	-- (some talents, Disengage among them, aim at a spot rather than the creature)
	if d > p:getTalentRange(t) or not p:hasLOS(target.x, target.y) then
		print("[TOUCH] cast -> manual aim (range/LOS)", t.name)
		p:useTalent(t.id)
		return true
	end
	print("[TOUCH] cast", t.name, "->", target.name)
	p:useTalent(t.id, nil, nil, nil, target)
	return true
end

--- Every entry of the bar: activable hotkey talents and usable hotkey items, in slot order
function _M:stripTalents()
	local p = game.player
	local list, seen = {}, {}
	if not p or not p.hotkey then return list end
	local pages = p.nb_hotkey_pages or 3
	for i = 1, 12 * pages do
		local hk = p.hotkey[i]
		if hk and hk[1] == "talent" and not seen[hk[2]] then
			local t = p:getTalentFromId(hk[2])
			if t and t.mode ~= "passive" and p:knowTalent(t) then
				seen[hk[2]] = true
				local cd = p:isTalentCoolingDown(t)
				list[#list+1] = {tid=t.id, t=t, cd=(cd and cd > 0) and cd or nil, slot=i}
			end
		elseif hk and hk[1] == "inventory" and not seen["item:"..tostring(hk[2])] then
			-- a bar item (Rod of Recall...): skipped when it is gone from the pack
			local o = p:findInAllInventories(hk[2], {no_add_name=true, force_id=true, no_count=true})
			if o then
				seen["item:"..tostring(hk[2])] = true
				local okc, cd = pcall(o.getObjectCooldown, o, p)
				cd = okc and tonumber(cd) or nil
				list[#list+1] = {item=hk[2], o=o, name=o:getName{do_color=false, no_count=true}, cd=(cd and cd > 0) and cd or nil, slot=i}
			end
		end
	end
	-- stable order = the hotkey slots (set from Talents); a used skill stays where it is, only dimmed
	table.sort(list, function(a, b) return a.slot < b.slot end)
	return list
end

function _M:drawTalentIcon(t, x, y, size, dim)
	if t.display_entity then
		pcall(t.display_entity.toScreen, t.display_entity, nil, x, y, size, size)
	end
	if dim then quad(x, y, size, size, 10, 10, 12, 150) end
end

---------------------------------------------------------------------------
-- layout
---------------------------------------------------------------------------

--- Height of the routine strip drawn above Act by the uiset (boxes + name)
_M.ACT_STRIP_H = 76

--- Screen rectangles for this frame. This is the one place the touch HUD is
-- laid out: the uiset draws Act/AUTO (and Cast/Cancel) at r.act / r.auto.
-- The hand setting puts the dock under that thumb and Skills/More on the
-- other side; in portrait the drawer spans the width above the dock row.
function _M:layout()
	local sa = TouchInput.safeArea()
	local w, h = game.w, game.h
	local bw, gap = 112, 10
	local portrait = TouchInput.portrait()
	local left = TouchInput.hand() == "left"
	local fs = _M.BTN
	local r = self.rects
	r.portrait, r.hand = portrait, left and "left" or "right"
	local dock_y = h - sa.b - 24 - bw
	local dock_bottom = dock_y + bw
	-- Act under the thumb, AUTO beside it towards the middle
	local act_x, auto_x
	if left then
		act_x = sa.l + 24
		auto_x = act_x + bw + gap
	else
		act_x = w - sa.r - 24 - bw
		auto_x = act_x - bw - gap
	end
	r.act = {x=act_x, y=dock_y, w=bw, h=bw}
	r.auto = {x=auto_x, y=dock_y, w=bw, h=bw}
	if portrait then
		-- the HUD band: the map ends above it (Jordan: "size the game area to be above
		-- the main buttons"), so there is no drawer and no Skills button; the skill
		-- strip is always there, full width, above the routine strip and the dock.
		-- More / Level up stacked on the other edge, bottom-aligned with the dock.
		local sk_x = left and (w - sa.r - 24 - fs) or (sa.l + 24)
		r.skills = nil
		r.more = {x=sk_x, y=dock_bottom - 44, w=fs, h=44}
		r.levelup = {x=sk_x, y=r.more.y - 8 - 44, w=fs, h=44}
		local strip_y = dock_y - _M.ACT_STRIP_H - 8 - _M.STRIP_H
		r.strip = {x=sa.l + 12, y=strip_y, w=w - sa.l - sa.r - 24, h=_M.STRIP_H}
		r.band_y = strip_y - 8
	else
		r.band_y = nil
		-- Skills just past AUTO, More above it, the drawer filling the rest of the bottom edge
		local sk_x = left and (auto_x + bw + gap) or (auto_x - gap - fs)
		r.skills = {x=sk_x, y=dock_bottom - fs, w=fs, h=fs}
		r.more = {x=sk_x, y=r.skills.y - 8 - 44, w=fs, h=44}
		-- a glowing Level up pill above More whenever points are unspent
		r.levelup = {x=sk_x, y=r.more.y - 8 - 44, w=fs, h=44}
		local sy = h - sa.b - 24 - _M.STRIP_H
		if left then
			local x0 = sk_x + fs + 12
			r.strip = {x=x0, y=sy, w=(w - sa.r - 120) - x0, h=_M.STRIP_H}
		else
			r.strip = {x=sa.l + 120, y=sy, w=sk_x - 12 - (sa.l + 120), h=_M.STRIP_H}
		end
	end
	return r
end

--- Where the map viewport ends: the top of the HUD band in portrait, the screen
-- bottom in landscape (the uiset sets map_h_stop from this)
function _M:bandTop()
	if not TouchInput.portrait() then return game.h end
	self:layout() -- never a stale rectangle (rotation)
	return self.rects.band_y or game.h
end

--- The band background (portrait), painted before Act/AUTO so the map never
-- shows through below its viewport
function _M:displayBand()
	self:layout()
	local r = self.rects
	if not r.portrait or not r.band_y then return end
	quad(0, r.band_y, game.w, game.h - r.band_y, 14, 15, 19, 255)
	quad(0, r.band_y, game.w, 2, 58, 61, 70, 255)
end

--- Is the skill strip on screen (always in portrait, the drawer elsewhere)
function _M:stripShown()
	return self.rects.portrait or self.drawer_open
end

function _M:hudHit(x, y)
	local r = self.rects
	if r.portrait and r.band_y and y >= r.band_y then return true end -- the whole band
	if inRect(r.strip, x, y) and self:stripShown() then return true end
	if inRect(r.more, x, y) or inRect(r.skills, x, y) or inRect(r.act, x, y) or inRect(r.auto, x, y) then return true end
	if self:levelUpPending() and inRect(r.levelup, x, y) then return true end
	-- the routine strip above Act (it grows away from the screen edge)
	if r.act and y >= r.act.y - _M.ACT_STRIP_H and y < r.act.y then
		if r.hand == "left" then
			if x < r.act.x + r.act.w + 140 then return true end
		elseif x >= r.act.x - 140 then return true end
	end
	return false
end

---------------------------------------------------------------------------
-- mouse zones (finger taps arrive as clicks)
---------------------------------------------------------------------------

function _M:zone(name, rect, fct)
	if not game.mouse:updateZone(name, rect.x, rect.y, rect.w, rect.h, nil, 1) then
		game.mouse:registerZone(rect.x, rect.y, rect.w, rect.h, function(button, mx, my, xrel, yrel, bx, by, event)
			if event == "button" and not xrel and not yrel then fct(button, mx, my) end
			return true
		end, nil, name, false, 1)
	end
	self.zones[name] = true
end

function _M:dropZone(name)
	if self.zones[name] and game.mouse.areas_name and game.mouse.areas_name[name] then game.mouse:unregisterZone(name) end
	self.zones[name] = nil
end

--- Called by the uiset while a dialog is open: nothing of ours must catch taps
function _M:hide()
	for name in pairs(self.zones) do self:dropZone(name) end
	self.rects = {}
end

---------------------------------------------------------------------------
-- the Skills button (opens and closes the drawer)
---------------------------------------------------------------------------

function _M:toggleDrawer()
	self.drawer_open = not self.drawer_open
	print("[TOUCH] skills drawer", self.drawer_open and "open" or "closed")
end

function _M:displaySkills()
	local r = self.rects.skills
	if not r then self:dropZone("touch_skills") return end -- portrait: the strip is always there
	local on = self.drawer_open
	local down = K.pressed(r.x, r.y, r.w, r.h)
	quad(r.x, r.y, r.w, r.h, (on or down) and 43 or 20, (on or down) and 39 or 22, (on or down) and 24 or 28, 225)
	if on or down then frame(r.x, r.y, r.w, r.h, 210, 170, 74, 255, 2) else frame(r.x, r.y, r.w, r.h, 58, 61, 70, 255, 2) end
	-- a small talent glyph: the first ready hotkey talent, else a star
	local list = self:stripTalents()
	local first = list[1]
	if first and first.t and first.t.display_entity then self:drawTalentIcon(first.t, r.x + (r.w - 40) / 2, r.y + 8, 40, false)
	elseif first and first.o then pcall(first.o.toScreen, first.o, nil, r.x + (r.w - 40) / 2, r.y + 8, 40, 40)
	else self:label("*", r.x + r.w / 2, r.y + 30, 1.8, 0.94, 0.83, 0.54, 1) end
	self:label(_t"SKILLS", r.x + r.w / 2, r.y + r.h - 16, 0.6, 0.9, 0.87, 0.78, 1)
	self:zone("touch_skills", r, function(button) if button == "left" then self:toggleDrawer() end end)
end

---------------------------------------------------------------------------
-- more (action sheet)
---------------------------------------------------------------------------

function _M:openMore()
	local p = game.player
	local list = {}
	local function key(name, k) list[#list+1] = {name=name, fct=function() game.key:triggerVirtual(k) end} end
	if p.unused_stats > 0 or p.unused_talents > 0 or p.unused_generics > 0 or p.unused_talents_types > 0 or p.unused_prodigies > 0 then key(_t"Level up!", "LEVELUP") end
	list[#list+1] = {name=_t"Places", fct=function() game:registerDialog(require("mod.dialogs.TouchPlaces").new()) end}
	key(_t"Inventory", "SHOW_INVENTORY")
	key(_t"Character sheet", "SHOW_CHARACTER_SHEET")
	key(_t"Talents", "USE_TALENTS")
	key(_t"Journal", "SHOW_QUESTS")
	key(_t"Level map", "SHOW_MAP")
	key(_t"Rest", "REST")
	key(_t"Explore", "RUN_AUTO")
	list[#list+1] = {name=_t"Zoom in", fct=function() local map = game.level and game.level.map if map and map.setZoom then map:setZoom(0.25, p.x, p.y) end end}
	list[#list+1] = {name=_t"Zoom out", fct=function() local map = game.level and game.level.map if map and map.setZoom then map:setZoom(-0.25, p.x, p.y) end end}
	list[#list+1] = {name=_t"Options", fct=function() game:registerDialog((TouchInput.active() and require("mod.dialogs.TouchOptions") or require("mod.dialogs.GameOptions")).new()) end}
	list[#list+1] = {name=_t"Touch controls guide", fct=function() game:registerDialog(require("mod.dialogs.TouchTutorial").new()) end}
	key(_t"Game menu", "EXIT")
	Dialog:listPopup(_t"More", "", list, 360, 60 + #list * 46, function(item) if item and item.fct then item.fct() end end)
end

function _M:displayMore()
	local r = self.rects.more
	local down = K.pressed(r.x, r.y, r.w, r.h)
	quad(r.x, r.y, r.w, r.h, down and 43 or 20, down and 39 or 22, down and 24 or 28, 225)
	if down then frame(r.x, r.y, r.w, r.h, 210, 170, 74, 255, 2) else frame(r.x, r.y, r.w, r.h, 58, 61, 70, 255, 2) end
	self:label("...", r.x + r.w / 2, r.y + r.h / 2 - 4, 1.4, 0.9, 0.87, 0.78, 1)
	self:zone("touch_more", r, function(button) if button == "left" then self:openMore() end end)
	self:displayLevelUp()
end

function _M:levelUpPending()
	local p = game.player
	if not p then return false end
	return (p.unused_stats or 0) > 0 or (p.unused_talents or 0) > 0 or (p.unused_generics or 0) > 0 or (p.unused_talents_types or 0) > 0 or (p.unused_prodigies or 0) > 0
end

-- the desktop HUD glows a level-up icon by the portrait; here a pulsing gold pill above More
function _M:displayLevelUp()
	local r = self.rects.levelup
	if not r then return end
	if not self:levelUpPending() then self:dropZone("touch_levelup") return end
	local pulse = 0.6 + 0.4 * math.sin(core.game.getTime() / 220)
	local down = K.pressed(r.x, r.y, r.w, r.h)
	quad(r.x, r.y, r.w, r.h, 60, 46, 16, 235)
	frame(r.x, r.y, r.w, r.h, 210, 170, 74, math.floor(255 * (down and 1 or pulse)), 2)
	self:label(_t"LEVEL UP", r.x + r.w / 2, r.y + r.h / 2, 0.62, 1, 0.9, 0.55, 1)
	self:zone("touch_levelup", r, function(button) if button == "left" then game.key:triggerVirtual("LEVELUP") end end)
end

---------------------------------------------------------------------------
-- target ring + skill strip
---------------------------------------------------------------------------

function _M:displayTarget()
	local t = self:target()
	if not t then return end
	local map = game.level.map
	local x, y = map:getTileToScreen(t.x, t.y)
	local tw, th = map.tile_w * (map.zoom or 1), map.tile_h * (map.zoom or 1)
	if not x or x < 0 or y < 0 then return end
	local pulse = 2 + 2 * math.sin(now() / 160)
	frame(x - pulse, y - pulse, tw + 2 * pulse, th + 2 * pulse, 0, 0, 0, 160, 5)
	frame(x - pulse, y - pulse, tw + 2 * pulse, th + 2 * pulse, 210, 170, 74, 255, 3)
end

function _M:displayStrip()
	local t = self:target()
	local r = self.rects.strip
	local portrait = self.rects.portrait
	if not self:stripShown() or not r or r.w < 200 then
		self:dropZone("touch_strip")
		self.strip_rects = nil
		return
	end
	local p = game.player
	quad(r.x, r.y, r.w, r.h, 20, 22, 28, 230)
	frame(r.x, r.y, r.w, r.h, 58, 61, 70, 255, 2)
	-- who: the target, or what a tap will do without one
	local who_w = 170
	local cx = r.x + 12 + who_w / 2 - 6
	self.strip_who_rect = t and {x=r.x, y=r.y, w=12 + who_w, h=r.h} or nil
	if t then
		local nm = t.name or "?"
		if #nm > 18 then nm = nm:sub(1, 17).."." end
		self:label(nm, cx, r.y + 24, 0.8, 0.94, 0.83, 0.54, 1)
		if portrait then
			-- a small x in the header corner clears the target (the strip itself stays)
			local cr = {x=r.x + 12 + who_w - 30, y=r.y + 4, w=26, h=26}
			quad(cr.x, cr.y, cr.w, cr.h, 36, 39, 47, 255)
			self:label("x", cr.x + 13, cr.y + 12, 0.7, 0.9, 0.87, 0.78, 1)
			self.strip_clear_rect = cr
		else
			self.strip_clear_rect = nil
		end
		local rank = (type(t.TextRank) == "function" and select(1, t:TextRank())) or (t.rank and tostring(t.rank)) or ""
		local life = t.max_life and t.max_life > 0 and math.floor(100 * t.life / t.max_life) or 0
		local sub = ("L%d %s · %d%%"):format(t.level or 1, tostring(rank):gsub("#[^#]*#", ""), life)
		if #sub > 26 then sub = sub:sub(1, 25) end
		self:label(sub, cx, r.y + 52, 0.55, 0.56, 0.53, 0.47, 1)
		self:label(_t"tap name for details", cx, r.y + 74, 0.5, 0.94, 0.83, 0.54, 1)
	else
		self.strip_clear_rect = nil
		self:label(_t"No target", cx, r.y + 30, 0.8, 0.9, 0.87, 0.78, 1)
		local n = #self:enemies()
		self:label(n > 0 and _t"casts at the nearest enemy" or _t"tap a skill to aim it", cx, r.y + 60, 0.5, 0.56, 0.53, 0.47, 1)
	end
	-- cards, scrolling by drag when they do not fit
	local list = self:stripTalents()
	local cw, ch, gap = _M.CARD_W, _M.CARD_H, 8
	local x0 = r.x + 12 + who_w
	local avail = r.w - 12 - who_w - (portrait and 20 or 44 + 20)
	local total = #list * (cw + gap)
	local maxs = math.max(0, total - avail)
	local ti = TouchInput.t
	if ti and ti.moved and not ti.held and ti.x0 >= x0 and ti.x0 < x0 + avail and ti.y0 >= r.y and ti.y0 < r.y + r.h then
		if self.strip_drag ~= ti then self.strip_drag, self.strip_drag_s = ti, self.strip_scroll end
		self.strip_scroll = util.bound(self.strip_drag_s - (ti.x - ti.x0), 0, maxs)
	elseif not ti then
		self.strip_drag = nil
	end
	self.strip_scroll = util.bound(self.strip_scroll, 0, maxs)
	core.display.glScissor(true, x0, r.y, avail, r.h)
	self.strip_rects = {}
	for i, e in ipairs(list) do
		local x = x0 + (i - 1) * (cw + gap) - self.strip_scroll
		local y = r.y + (r.h - ch) / 2
		if x + cw > x0 and x < x0 + avail then
			quad(x, y, cw, ch, 36, 39, 47, 255)
			if e.t then
				self:drawTalentIcon(e.t, x + (cw - 44) / 2, y + 4, 44, e.cd ~= nil)
				if e.cd then
					self:label(tostring(math.ceil(e.cd)), x + cw - 12, y + 12, 0.7, 1, 0.75, 0.65, 1)
				elseif p:preUseTalent(e.t, true, true) then
					frame(x, y, cw, ch, 210, 170, 74, 255, 2)
				end
			else
				-- a bar item: its own icon, dimmed while it recharges
				pcall(e.o.toScreen, e.o, nil, x + (cw - 44) / 2, y + 4, 44, 44)
				if e.cd then
					quad(x + (cw - 44) / 2, y + 4, 44, 44, 0, 0, 0, 110)
					self:label(tostring(math.ceil(e.cd)), x + cw - 12, y + 12, 0.7, 1, 0.75, 0.65, 1)
				else
					frame(x, y, cw, ch, 120, 170, 210, 255, 2)
				end
			end
			local n = e.t and e.t.name or e.name or "?"
			if #n > 9 then n = n:sub(1, 8).."." end
			self:label(n, x + cw / 2, y + ch - 12, 0.5, 0.9, 0.87, 0.78, 1)
			self.strip_rects[i] = {x=x, y=y, w=cw, h=ch, tid=e.tid, item=e.item}
		end
	end
	core.display.glScissor(false)
	-- close (landscape drawer only: in portrait the strip is part of the band)
	if portrait then
		self.strip_close_rect = nil
	else
		local cx = r.x + r.w - 44 - 10
		quad(cx, r.y + (r.h - 44) / 2, 44, 44, 36, 39, 47, 255)
		self:label("X", cx + 22, r.y + r.h / 2, 0.9, 0.9, 0.87, 0.78, 1)
		self.strip_close_rect = {x=cx, y=r.y + (r.h - 44) / 2, w=44, h=44}
	end
	self:zone("touch_strip", r, function(button, mx, my) self:stripTap(button, mx, my) end)
end

function _M:stripTap(button, mx, my)
	-- the release of a scroll is not a tap on whatever ended up under the thumb
	local ti = TouchInput.t
	if ti and ti.moved then print("[TOUCH] strip: drag release ignored") return end
	if self.strip_close_rect and inRect(self.strip_close_rect, mx, my) then self:setTarget(nil) self.drawer_open = false print("[TOUCH] skills drawer closed") return end
	if self.strip_clear_rect and inRect(self.strip_clear_rect, mx, my) then self:setTarget(nil) return end
	-- the target's name: open its sheet (the desktop hover tooltip has no finger equivalent)
	if self.strip_who_rect and inRect(self.strip_who_rect, mx, my) then
		local t = self:target()
		if t then
			print("[TOUCH] inspect", t.name)
			local ok, err = pcall(function() game:registerDialog(require("mod.dialogs.CharacterSheet").new(t)) end)
			if not ok then print("[TOUCH] inspect failed", tostring(err)) end
		end
		return
	end
	for _, c in pairs(self.strip_rects or {}) do
		if inRect(c, mx, my) then
			if c.item then
				-- exactly what the hotkey does: use the item (its own targeting if it aims)
				print("[TOUCH] bar item", c.item)
				if game.key == game.normal_key then game.player:hotkeyInventory(c.item) end
				return
			end
			if button == "right" then self:cast(c.tid, nil, true) return end
			local tgt = self:target() or self:nearestEnemy()
			-- nobody in view: aim by hand (Cast / Cancel)
			self:cast(c.tid, tgt, tgt == nil)
			return
		end
	end
end

---------------------------------------------------------------------------
-- drag to step
---------------------------------------------------------------------------

--- TouchInput provider: phase = start | move | tick | end | cancel
function _M:drag(phase, t, x, y)
	local p = game.player
	if phase == "start" then
		local function no(why) print("[TOUCH] drag is not a step:", why) return false end
		if not game.level or not p then return no("no level") end
		if game.key ~= game.normal_key then return no("not in normal key mode") end
		if game.dialogs and #game.dialogs > 0 then return no("dialog open") end
		if self.uiset.touch_wheel and self.uiset.touch_wheel.open then return no("wheel open") end
		-- a drag starting on the skill strip scrolls the strip (displayStrip reads the finger)
		-- and nothing else: no map pan, no card on release
		if self:stripShown() and inRect(self.rects.strip, t.x0, t.y0) then print("[TOUCH] hud drag (strip)") return "hud" end
		-- portrait: the whole band is the HUD's; a drag there never pans the map
		if self.rects.portrait and self.rects.band_y and t.y0 >= self.rects.band_y then print("[TOUCH] hud drag (band)") return "hud" end
		if self:hudHit(t.x0, t.y0) then return no("on the HUD") end
		local map = game.level.map
		if t.x0 < map.display_x or t.x0 >= map.display_x + map.viewport.width or t.y0 < map.display_y or t.y0 >= map.display_y + map.viewport.height then return no("outside the map") end
		self.step = {t=t, dir=nil, moved_at=now(), last=0, steps=0}
		print("[TOUCH] drag -> step gesture")
		return true
	end
	local s = self.step
	if not s or s.t ~= t then return false end
	if phase == "move" then
		local dx, dy = t.x - t.x0, t.y - t.y0
		local d = math.sqrt(dx * dx + dy * dy)
		local dir = nil
		if d > _M.DRAG_DEADZONE then
			local a = math.deg(math.atan2(dy, dx))
			local k = math.floor((a + 22.5 + 360) / 45) % 8
			local sx = ({1, 1, 0, -1, -1, -1, 0, 1})[k + 1]
			local sy = ({0, 1, 1, 1, 0, -1, -1, -1})[k + 1]
			dir = {sx, sy}
		end
		if (dir and not s.dir) or (not dir and s.dir) or (dir and s.dir and (dir[1] ~= s.dir[1] or dir[2] ~= s.dir[2])) then s.moved_at = now() end
		s.dir = dir
		return true
	elseif phase == "tick" then
		if s.dir and now() - s.moved_at >= _M.REPEAT_AFTER_MS and now() - s.last >= _M.REPEAT_EVERY_MS then
			if #self:enemies() > 0 and s.steps > 0 then return true end -- an enemy came into view: stop walking
			self:stepOnce(s)
		end
		return true
	elseif phase == "end" then
		self.step = nil
		if s.steps == 0 then
			local dx, dy = t.x - t.x0, t.y - t.y0
			local d = math.sqrt(dx * dx + dy * dy)
			local held = now() - (t.t0 or now())
			if not s.dir or (d < _M.STEP_MIN_PX and held < _M.STEP_MIN_MS) then
				print(("[TOUCH] drag too short for a step (%d px, %d ms)"):format(d, held))
				return "tap"
			end
			self:stepOnce(s)
		end
		return true
	end
	self.step = nil
	return true
end

function _M:stepOnce(s)
	local p = game.player
	if not p or game.key ~= game.normal_key then return end
	local dir = DIRS[s.dir[1]][s.dir[2]]
	s.last = now()
	s.steps = s.steps + 1
	self:doStep(dir)
end

--- Actor:move only moves with enough energy; right after another action the
-- player's turn has not come back yet, so keep the step pending for a moment
function _M:doStep(dir)
	local p = game.player
	if not p:enoughEnergy() then
		print("[TOUCH] step", dir, "pending (energy", p.energy and p.energy.value, ")")
		self.pending_step = {dir=dir, t=now()}
		return
	end
	self.pending_step = nil
	print("[TOUCH] step", dir, "energy", p.energy and p.energy.value)
	local ok, err = pcall(p.moveDir, p, dir)
	if not ok then print("[TOUCH] step error", err) end
end

function _M:flushPendingStep()
	local ps = self.pending_step
	if not ps then return end
	if now() - ps.t > 1500 then self.pending_step = nil return end
	local p = game.player
	if p and game.key == game.normal_key and p:enoughEnergy() then self:doStep(ps.dir) end
end

function _M:displayStepPreview()
	local s = self.step
	if not s or not s.dir or not game.level then return end
	local p = game.player
	local map = game.level.map
	local tx, ty = p.x + s.dir[1], p.y + s.dir[2]
	local x, y = map:getTileToScreen(tx, ty)
	if not x then return end
	local tw, th = map.tile_w * (map.zoom or 1), map.tile_h * (map.zoom or 1)
	-- dashed gold frame
	local seg, gapl = 8, 6
	local function dash(x1, y1, x2, y2)
		local len = math.max(math.abs(x2 - x1), math.abs(y2 - y1))
		local n = math.floor(len / (seg + gapl))
		for i = 0, n do
			local f = (i * (seg + gapl)) / len
			local sx, sy = x1 + (x2 - x1) * f, y1 + (y2 - y1) * f
			if x1 == x2 then quad(sx - 1, sy, 3, math.min(seg, len - i * (seg + gapl)), 210, 170, 74, 255)
			else quad(sx, sy - 1, math.min(seg, len - i * (seg + gapl)), 3, 210, 170, 74, 255) end
		end
	end
	quad(x, y, tw, th, 210, 170, 74, 45)
	dash(x, y, x + tw, y) dash(x, y + th - 1, x + tw, y + th - 1) dash(x, y, x, y + th) dash(x + tw - 1, y, x + tw - 1, y + th)
	-- a bar on the far side shows the direction
	local bx, by, bw, bh = x, y, tw, th
	if s.dir[1] > 0 then quad(x + tw - 6, y, 6, th, 240, 212, 138, 255) elseif s.dir[1] < 0 then quad(x, y, 6, th, 240, 212, 138, 255) end
	if s.dir[2] > 0 then quad(x, y + th - 6, tw, 6, 240, 212, 138, 255) elseif s.dir[2] < 0 then quad(x, y, tw, 6, 240, 212, 138, 255) end
	local blocked = map:checkEntity(tx, ty, Map.TERRAIN, "block_move") and not map(tx, ty, Map.ACTOR)
	local a = map(tx, ty, Map.ACTOR)
	local hint = a and (p:reactionToward(a) < 0 and _t"attack" or _t"swap") or (blocked and _t"blocked" or nil)
	if hint then self:label(hint, x + tw / 2, y - 14, 0.6, 1, 0.83, 0.79, 1) end
end

---------------------------------------------------------------------------
-- per-frame
---------------------------------------------------------------------------

--- Called by the uiset (no dialog open, not targeting)
-- items that go on the bar by themselves the first time they are in the pack (define_as names)
_M.AUTO_BAR = {"ROD_OF_RECALL"}

--- Bind the AUTO_BAR items to a free slot once per character; a deliberate removal (the item
-- sheet's "Remove from bar" sets the same latch) keeps them off afterwards
function _M:autoBind()
	local p = game.player
	if not p or not p.inven or not p.hotkey then return end
	local now_t = now()
	if self.autobind_at and now_t - self.autobind_at < 1500 then return end
	self.autobind_at = now_t
	local SP = require "mod.dialogs.TouchSlotPicker"
	p.touch_autobound = p.touch_autobound or {}
	local pack = p:getInven(p.INVEN_INVEN)
	if not pack then return end
	for _, def in ipairs(_M.AUTO_BAR) do
		if not p.touch_autobound[def] then
			for _, o in ipairs(pack) do
				if o.define_as == def and o:canUseObject() then
					if not SP.itemSlot(p, o) then
						local slot
						for i = 1, 12 * (p.nb_hotkey_pages or 3) do if not p.hotkey[i] then slot = i break end end
						if slot then SP.bindItem(p, o, slot) print("[TOUCH] auto-bound", o.name, "to slot", slot) end
					end
					p.touch_autobound[def] = true
					if def == "ROD_OF_RECALL" then p.touch_autobound_recall = true end
					break
				end
			end
		end
	end
end

function _M:display()
	if not game.level or not game.player then return end
	self:layout()
	self:autoBind()
	self:flushPendingStep()
	self:displayTarget()
	self:displayStepPreview()
	self:displaySkills()
	self:displayMore()
	self:displayStrip()
	-- what the test harness reads
	self.uiset.touch_skills_rect = self.rects.skills
	self.uiset.touch_more_rect = self.rects.more
	self.uiset.touch_strip_rects = self.strip_rects
	self.uiset.touch_strip_rect = self.rects.strip
	self.uiset.touch_drawer_open = self:stripShown()
	self.uiset.touch_band_y = self.rects.band_y
end

--- Called every frame while targeting or a dialog is open: only the ring stays
function _M:displayQuiet()
	if not game.level or not game.player then return end
	self:flushPendingStep()
	self:displayTarget()
end
