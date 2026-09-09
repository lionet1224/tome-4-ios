-- ToME - Tales of Maj'Eyal
-- iOS port: radial touch wheels.
-- Hold (or drag) in the left third of the screen: a wheel of the current
-- hotkey page; hold in the right third: a wheel of the common actions.
-- Slide to a wedge and lift to fire; lift inside the hub to cancel.

require "engine.class"
local FontPackage = require "engine.FontPackage"

module(..., package.seeall, class.make)

local TouchInput = require "engine.TouchInput"
_M.DEFAULTS = TouchInput.DEFAULTS
_M.setting = TouchInput.setting

function _M.set(k, v)
	config.settings.touch = config.settings.touch or {}
	config.settings.touch[k] = v
	local parts = {}
	for kk, vv in pairs(config.settings.touch) do
		parts[#parts+1] = ("%s=%s"):format(kk, type(vv) == "string" and ("%q"):format(vv) or tostring(vv))
	end
	game:saveSettings("touch", ("touch = {%s}\n"):format(table.concat(parts, ", ")))
end

function _M.enabled()
	return TouchInput.active() and _M.setting("wheel") and true or false
end

--- iOS port: treat every birth option (classes, races, the transmogrification
-- chest, ...) as unlocked. The chest is what makes carry weight a non-issue:
-- with it every item on the floor is picked up automatically.
function _M.applyUnlocks()
	if not __IOS__ or _M.setting("unlock_all") == false then return end
	local ab = profile and profile.mod and profile.mod.allow_build
	if ab and not getmetatable(ab) then
		setmetatable(ab, {__index=function() return true end})
		print("[TOUCH] all birth options unlocked")
	end
end

function _M:init(uiset)
	self.uiset = uiset
	self.open = false
	self.labels = {}
	-- the HUD labels follow the touch text size setting
	local K = require "engine.ui.TouchKit"
	local sc = K.uiScale and K.uiScale() or 1
	local okf, f, size = pcall(FontPackage.resolveFont, FontPackage, "default")
	if sc ~= 1 and okf and f and f[size] then self.font = core.display.newFont(f.font, math.floor(f[size] * sc + 0.5), f.bold)
	else self.font = FontPackage:get("default", true) end
end

--- Which wheel does a touch at screen x,y belong to (nil = none)
function _M:zoneOf(x, y)
	if not _M.enabled() or not game.level or not game.player then return nil end
	if game.key ~= game.normal_key then return nil end -- dialogs, targeting
	if game.dialogs and #game.dialogs > 0 then return nil end
	local w, h = game.w, game.h
	local r = game.uiset and game.uiset.touch_attack_rect
	if r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h then return nil end
	local zone = _M.setting("zone")
	if zone == "bottom" then
		if y < h * 0.5 then return nil end
	else
		if y < h * 0.15 then return nil end
	end
	if x < w / 3 then return "L" elseif x > w * 2 / 3 then return "R" end
	return nil
end

local function zoomFct(delta)
	return function()
		local map = game.level and game.level.map
		if map and map.setZoom then map:setZoom(delta, game.player and game.player.x, game.player and game.player.y) end
	end
end

function _M:buildItems(side)
	local p = game.player
	local items = {}
	if side == "L" then
		local n = _M.setting("wedges")
		local base = 12 * (p.hotkey_page - 1)
		for i = 1, n do
			local j = base + i
			local it = {kind="hotkey", id=j, num=i, name=_t"empty", empty=true, dim=true}
			local hk = p.hotkey[j]
			if hk then
				it.empty, it.dim = false, false
				if hk[1] == "talent" then
					local t = p:getTalentFromId(hk[2])
					if t then
						it.name = t.name
						it.entity = t.display_entity
						local cd = p:isTalentCoolingDown(t)
						if cd and cd > 0 then it.cd = math.ceil(cd) it.dim = true
						elseif p:isTalentActive(t.id) then it.active = true
						elseif not p:preUseTalent(t, true, true) then it.dim = true end
					end
				elseif hk[1] == "inventory" then
					local o = p:findInAllInventories(hk[2], {no_add_name=true, force_id=true, no_count=true})
					it.name = hk[2]
					if o then it.entity = o else it.dim = true end
				end
			end
			items[#items+1] = it
		end
		items[#items+1] = {kind="page", dir=1, name=("page %d"):format(self:pageStep(1)), glyph=">"}
		items[#items+1] = {kind="page", dir=-1, name=("page %d"):format(self:pageStep(-1)), glyph="<"}
	else
		items = {
			{kind="key", key="SHOW_CHARACTER_SHEET", name=_t"Character", glyph="@"},
			{kind="key", key="USE_TALENTS", name=_t"Talents", glyph="*"},
			{kind="key", key="SHOW_QUESTS", name=_t"Journal", glyph="?"},
			{kind="key", key="EXIT", name=_t"Menu", glyph="="},
			{kind="fct", fct=zoomFct(-0.25), name=_t"Zoom out", glyph="-"},
			{kind="fct", fct=zoomFct(0.25), name=_t"Zoom in", glyph="+"},
			{kind="key", key="SHOW_INVENTORY", name=_t"Inventory", glyph="i"},
			{kind="key", key="REST", name=_t"Rest", glyph="R"},
			{kind="key", key="RUN_AUTO", name=_t"Explore", glyph="z"},
		}
		if (p.unused_stats or 0) > 0 or (p.unused_talents or 0) > 0 or (p.unused_generics or 0) > 0 or (p.unused_talents_types or 0) > 0 then
			items[1] = {kind="key", key="LEVELUP", name=_t"Level up", glyph="+", glow=true}
		end
	end
	return items
end

--- Next/previous page that has something bound (page 1 always counts)
function _M:pageStep(dir)
	local p = game.player
	local np = p.nb_hotkey_pages or 7
	local page = p.hotkey_page
	for _ = 1, np - 1 do
		page = util.boundWrap(page + dir, 1, np)
		if page == 1 then return page end
		for i = 1, 12 do if p.hotkey[12 * (page - 1) + i] then return page end end
	end
	return p.hotkey_page
end

function _M:openAt(side, x, y)
	self.open = true
	self.side = side
	self.sel = nil
	self.items = self:buildItems(side)
	local w, h = game.w, game.h
	self.r_out = math.floor(h * 0.275)
	self.r_in = math.floor(self.r_out * 0.31)
	local sa = TouchInput.safeArea()
	if _M.setting("pos") == "corner" then
		self.cx = side == "L" and (sa.l + self.r_out + 30) or (w - sa.r - self.r_out - 30)
		self.cy = h - sa.b - self.r_out - 20
	else
		self.cx = util.bound(x, sa.l + self.r_out + 8, w - sa.r - self.r_out - 8)
		self.cy = util.bound(y, sa.t + self.r_out + 50, h - sa.b - self.r_out - 8)
	end
	print("[TOUCH] wheel open", side, self.cx, self.cy)
end

function _M:move(x, y)
	if not self.open then return end
	local dx, dy = x - self.cx, y - self.cy
	local d = math.sqrt(dx * dx + dy * dy)
	local n = #self.items
	local sel = nil
	if d > self.r_in then
		local a = math.deg(math.atan2(dx, -dy))
		if a < 0 then a = a + 360 end
		sel = math.floor(((a + 180 / n) % 360) / (360 / n)) + 1
	end
	if sel ~= self.sel then
		self.sel = sel
		local it = self.items[sel or 0]
		-- page wedges flip on entry; a jittering finger on the hub edge must
		-- not flip again and again, hence the cooldown
		if it and it.kind == "page" and core.game.getTime() - (self.last_flip or 0) > 350 then
			self.last_flip = core.game.getTime()
			game.player:setHotkeyPage(self:pageStep(it.dir))
			self.items = self:buildItems(self.side)
			print("[TOUCH] wheel page", game.player.hotkey_page)
		end
	end
end

function _M:release()
	if not self.open then return end
	local it = self.items[self.sel or 0]
	self.open = false
	if not it or it.kind == "page" then print("[TOUCH] wheel cancel") return end
	print("[TOUCH] wheel pick", it.kind, it.name, it.id or it.key or "")
	if it.kind == "hotkey" then
		if it.empty then return end
		game.player:activateHotkey(it.id)
	elseif it.kind == "key" then
		game.key:triggerVirtual(it.key)
	elseif it.kind == "fct" then
		it.fct()
	end
end

function _M:cancel()
	if self.open then print("[TOUCH] wheel cancel") end
	self.open = false
end

--- Draw a cached text label centered on x,y
function _M:drawLabel(txt, x, y, scale, r, g, b, a)
	local l = self.labels[txt]
	if not l then
		local s = core.display.drawStringBlendedNewSurface(self.font, txt, 255, 255, 255)
		local t = {s:glTexture()}
		local w, h = s:getSize()
		l = {t=t, w=w, h=h}
		self.labels[txt] = l
	end
	scale = scale or 1
	local w, h = l.w * scale, l.h * scale
	l.t[1]:toScreenFull(x - w / 2, y - h / 2, w, h, l.t[2] * scale, l.t[3] * scale, r or 1, g or 1, b or 1, a or 1)
end

function _M:display()
	if not self.open then return end
	local d = core.display
	local n = #self.items
	local cx, cy = self.cx, self.cy
	local step = 360 / n
	for i, it in ipairs(self.items) do
		local a0 = (i - 1) * step - step / 2 + 1.5
		local a1 = a0 + step - 3
		local r, g, b, a = 24, 23, 20, 240
		if it.kind == "page" then r, g, b = 40, 36, 28 end
		if i == self.sel then r, g, b = 58, 46, 18 end
		d.drawRingWedge(cx, cy, self.r_in, self.r_out, a0, a1, r, g, b, a)
		local br, bg, bb = 59, 52, 39
		if i == self.sel or it.glow then br, bg, bb = 210, 170, 74 end
		d.drawRingWedge(cx, cy, self.r_out - 3, self.r_out, a0, a1, br, bg, bb, 255)

		local am = math.rad((i - 1) * step)
		local rm = (self.r_in + self.r_out) / 2 + 6
		local lx, ly = cx + rm * math.sin(am), cy - rm * math.cos(am)
		local alpha = it.dim and 0.45 or 1
		if it.entity then
			it.entity:toScreen(nil, lx - 24, ly - 34, 48, 48, alpha)
		elseif it.glyph then
			self:drawLabel(it.glyph, lx, ly - 12, 1.7, 0.94, 0.83, 0.54, alpha)
		end
		-- wedges carry only the icon and the key number (or cooldown); the
		-- selected item's full name goes in the hub where it cannot overlap
		local txt
		if it.cd then txt = ("%d: %d"):format(it.num, it.cd)
		elseif it.num then txt = tostring(it.num)
		else txt = it.name end
		if it.cd then self:drawLabel(txt, lx, ly + 22, 0.85, 1, 0.7, 0.62, 1)
		else self:drawLabel(txt, lx, ly + 22, 0.85, 0.9, 0.87, 0.78, alpha) end
	end
	d.drawRingWedge(cx, cy, 0, self.r_in - 6, 0, 360, 15, 15, 18, 240)
	d.drawRingWedge(cx, cy, self.r_in - 8, self.r_in - 6, 0, 360, 59, 52, 39, 255)
	local cur = self.items[self.sel or 0]
	if cur and cur.kind ~= "page" then
		-- name over the hub, on a dark strip so it reads over the map
		local name = cur.name
		if cur.cd then name = ("%s (%d turns)"):format(name, cur.cd) end
		local l = self.labels[name]
		local lw = l and l.w or 200
		d.drawQuad(cx - lw / 2 - 12, cy - self.r_out - 44, lw + 24, 36, 10, 10, 12, 220)
		self:drawLabel(name, cx, cy - self.r_out - 26, 1, 0.94, 0.83, 0.54, 1)
	end
	if self.side == "L" then
		self:drawLabel(("page %d/%d"):format(game.player.hotkey_page, game.player.nb_hotkey_pages or 7), cx, cy - 6, 0.85, 0.82, 0.67, 0.29, 1)
		self:drawLabel(_t"lift = cancel", cx, cy + 12, 0.7, 0.56, 0.53, 0.47, 1)
	else
		self:drawLabel(_t"lift = cancel", cx, cy + 2, 0.7, 0.56, 0.53, 0.47, 1)
	end
end
