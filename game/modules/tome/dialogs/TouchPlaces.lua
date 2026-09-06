-- ToME iOS port: "Places", a destination sheet for the current level.
-- Towns and dungeons (world map), exits and stairs (other zones), shops
-- (store traps) and people you can talk to, all from what the player has
-- seen; tap one to auto-travel there the way a map click does.

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local Map = require "engine.Map"
local Tiles = require "engine.Tiles"
local K = require "engine.ui.TouchKit"

module(..., package.seeall, class.inherit(Dialog))

-- zones whose entrance counts as a town on the world map
local TOWN_ZONES = {["town-derth"]=true, ["town-last-hope"]=true, ["town-zigur"]=true, ["town-angolwen"]=true, ["town-irkkk"]=true,
	["town-shatur"]=true, ["town-elvala"]=true, ["town-gates-of-morning"]=true, ["town-sunwall"]=true, ["town-iron-council"]=true,
	["town-kruk-pride"]=true, ["town-point-zero"]=true, ["town-lumberjack-village"]=true}

local function isTownZone(zone_name, grid_name)
	if zone_name then
		if TOWN_ZONES[zone_name] or zone_name:find("^town%-") then return true end
	end
	local n = tostring(grid_name or ""):lower()
	return n:find("town", 1, true) ~= nil or n:find("village", 1, true) ~= nil or n:find("city", 1, true) ~= nil
end

function _M:init()
	self.tiles = Tiles.new(64, 64, nil, nil, true, nil)
	local sa = require("engine.TouchInput").safeArea()
	local w = math.floor((game.w - sa.l - sa.r) * 0.7)
	local h = math.floor((game.h - sa.t - sa.b) * 0.9)
	Dialog.init(self, _t"Places", w, h)
	self.c_flow = K.Flow.new{width=self.iw, height=self.ih}
	self:loadUI{ {left=0, top=0, ui=self.c_flow} }
	self:setupUI()
	self:setFocus(self.c_flow)
	self:build()
	self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end }
end

local function dist(x, y) local p = game.player return core.fov.distance(p.x, p.y, x, y) end
local function byDist(a, b) return a.d < b.d end

--- Every known destination on this level, grouped
function _M:scan()
	local map = game.level.map
	local p = game.player
	local wild = game.zone and game.zone.wilderness
	-- in a town the residents are fixed and known: list every talkable person, seen or not
	local zn = game.zone and tostring(game.zone.short_name or "") or ""
	local is_town = zn:find("^town") ~= nil or ({["last-hope"]=1, ["zigur"]=1, ["angolwen"]=1, ["irkkk"]=1, ["shatur"]=1, ["elvala"]=1, ["gates-of-morning"]=1, ["sunwall"]=1, ["iron-council"]=1, ["kruk-pride"]=1})[zn] ~= nil
	local towns, dungeons, exits, shops, people = {}, {}, {}, {}, {}
	for x = 0, map.w - 1 do for y = 0, map.h - 1 do
		if map.remembers(x, y) or map.seens(x, y) then
			local g = map(x, y, Map.TERRAIN)
			if g and (g.change_level or g.change_zone) then
				local e = {x=x, y=y, ent=g, name=tostring(g.name or g.change_zone or _t"exit"), d=dist(x, y)}
				if wild then
					if isTownZone(g.change_zone, g.name) then towns[#towns+1] = e else dungeons[#dungeons+1] = e end
				else
					exits[#exits+1] = e
				end
			end
			local t = map(x, y, Map.TRAP)
			if t and t.is_store then
				shops[#shops+1] = {x=x, y=y, ent=t, name=tostring(t.name or _t"shop"), d=dist(x, y)}
			end
			if map.seens(x, y) or is_town then
				local a = map(x, y, Map.ACTOR)
				if a and a ~= p and not (game.party and game.party:hasMember(a)) and p:reactionToward(a) >= 0 and (a.can_talk or a.store or a.quest_giver) then
					people[#people+1] = {x=x, y=y, ent=a, name=tostring(a.name or _t"someone"), d=dist(x, y), actor=true}
				end
			end
		end
	end end
	table.sort(towns, byDist) table.sort(dungeons, byDist) table.sort(exits, byDist) table.sort(shops, byDist) table.sort(people, byDist)
	return {towns=towns, dungeons=dungeons, exits=exits, shops=shops, people=people}
end

function _M:subFor(e)
	local here = e.x == game.player.x and e.y == game.player.y
	if here then return _t"You are here" end
	local d = e.d
	local what = ""
	if e.ent and e.ent.change_level and not e.ent.change_zone then
		what = (e.ent.change_level or 0) < 0 and _t"stairs up · " or _t"stairs down · "
	end
	return ("%s%d %s"):format(what, d, d == 1 and _t"tile away" or _t"tiles away")
end

function _M:iconFor(e)
	local ent = e.ent
	if not ent or not ent.toScreen then return nil end
	return function(x, y, size) pcall(ent.toScreen, ent, self.tiles, x, y, size, size) end
end

function _M:cards(list)
	local items = {}
	for _, e in ipairs(list) do
		items[#items+1] = {name=e.name, sub=self:subFor(e), icon=self:iconFor(e), data=e, on_tap=function() self:go(e) end}
	end
	return items
end

function _M:build()
	local s = self:scan()
	local secs = {}
	local wild = game.zone and game.zone.wilderness
	if #s.towns > 0 then secs[#secs+1] = {title=_t"Towns", items=self:cards(s.towns), min_w=220, row_h=88} end
	if #s.dungeons > 0 then secs[#secs+1] = {title=_t"Dungeons", items=self:cards(s.dungeons), min_w=220, row_h=88} end
	if #s.exits > 0 then secs[#secs+1] = {title=_t"Exits and stairs", items=self:cards(s.exits), min_w=220, row_h=88} end
	if #s.shops > 0 then secs[#secs+1] = {title=_t"Shops", items=self:cards(s.shops), min_w=220, row_h=88} end
	if #s.people > 0 then secs[#secs+1] = {title=_t"People", items=self:cards(s.people), min_w=220, row_h=88} end
	if #secs == 0 then
		secs[#secs+1] = {title=wild and _t"Nothing known here yet" or _t"Nothing known on this level yet", items={{name=_t"Explore to find places.", sub=_t"Towns, dungeons, shops and people appear here once you have seen them.", on_tap=function() game:unregisterDialog(self) end}}, cols=1, row_h=88}
	end
	self.c_flow:setSections(secs)
	self.sections = s
end

--- Travel to a destination (or enter it when standing on it)
function _M:go(e)
	local p = game.player
	game:unregisterDialog(self)
	if e.x == p.x and e.y == p.y then
		if e.ent and (e.ent.change_level or e.ent.change_zone) then
			print("[TOUCH] places: enter", e.name)
			game.key:triggerVirtual("CHANGE_LEVEL")
		end
		return
	end
	print("[TOUCH] places: travel to", e.name, e.x, e.y)
	-- the same call a map tap makes: paths there, ends by stepping into a shop door or a
	-- person, which opens the store / starts the talk exactly like the desktop click
	p:mouseMove(e.x, e.y)
end

function _M:innerDisplayBack(x, y, nb_keyframes)
	K.quad(x + self.ix, y + self.iy, self.iw, self.ih, {18, 19, 23})
end
