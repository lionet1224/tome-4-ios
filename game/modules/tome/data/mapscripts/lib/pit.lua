-- TE4 - T-Engine 4
-- Copyright (C) 2009 - 2019 Nicolas Casalini
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

-- local size = args.size or {w={15, 15}, h={15, 15}}
local size = args.size or {w={7, 12}, h={7, 12}}
local replacers = args.replacers or {
	['!'] = '#',
}

local function set_exitable(tm)
	tm.rr_exits = { openables={}, doors={} }
	
	function tm:mergedAt(x, y, into)
		local function translate(map, x, y, into)
			local d = self:point(x, y) - 1
			for _, open in pairs(self.rr_exits.openables) do open.x, open.y = open.x + d.x, open.y + d.y end
			for _, door in pairs(self.rr_exits.doors) do door.x, door.y = door.x + d.x, door.y + d.y end
			return true
		end
		Tilemap.mergedAt(self, x, y, into)

		-- Tell the tilemap we merge into to keep translating the map positions if it is itself on_merged_at
		into.on_merged_at[#into.on_merged_at+1] = translate

		-- And translate right now too
		translate(self, x, y, into)
	end

	function tm:findExits(pos, kind)
		local list = {}
		if not kind or kind == "openable" then
			for _, open in pairs(self.rr_exits.openables) do
				local dist = core.fov.distance(pos.x, pos.y, open.x, open.y)
				table.insert(list, {dist = dist, pos = open, kind = "open"})			
			end
		end
		if not kind or kind == "door" then
			for _, door in pairs(self.rr_exits.doors) do
				local dist = core.fov.distance(pos.x, pos.y, door.x, door.y)
				table.insert(list, {dist = dist, pos = door, kind = "door"})			
			end
		end
		table.sort(list, "dist")
		return list
	end
end

return function(filter)
	if not filter then filter = rng.table(mapdata.rooms_config.pit.filters) end

	local door = replacers['+'] or '+'
	local wall = replacers['#'] or '#'
	local floor = replacers['.'] or '.'
	local tm = Tilemap.new({rng.range(unpack(size.w)), rng.range(unpack(size.h))}, floor)
	tm.is_pit = true
	set_exitable(tm)

	local pitdata = "pitdata"..tostring(tm)
	self:additionalTileInfos(pitdata, floor, nil, {random_filter=filter, entity_mod=function(e) e:setEffect(e.EFF_VAULTED, 1, {}) return e end}, nil, {special=true})

	local doors = {}
	for p in tm:pointIterator() do
		-- Outer shell & openings
		if p.x == 1 or p.x == tm.data_w then
			if p.y == 1 or p.y == tm.data_h then
				tm:put(p, wall)
			else
				tm:put(p, wall)
				table.insert(tm.rr_exits.openables, p)
			end
		elseif p.y == 1 or p.y == tm.data_h then
			if p.x == 1 or p.x == tm.data_h then
				tm:put(p, wall)
			else
				tm:put(p, wall)
				table.insert(tm.rr_exits.openables, p)
			end
		elseif p.x >= 3 and p.x <= tm.data_w - 2 and p.y >= 3 and p.y <= tm.data_h - 2 then
			if p.x == 3 or p.x == tm.data_w - 2 or p.y == 3 or p.y == tm.data_h - 2 then
				tm:put(p, wall)
				if not (p.x == 3 and p.y == 3) and not (p.x == tm.data_w - 2 and p.y == 3) and not (p.x == 3 and p.y == tm.data_h - 2) and not (p.x == tm.data_w - 2 and p.y == tm.data_h - 2) then
					doors[#doors+1] = p
				end
			else
				tm:put(p, pitdata)
			end
		end
	end
	local doorpos = rng.table(doors)
	if doorpos then
		local pitinfo = "pitinfo"..tostring(tm)
		self:additionalTileInfos(pitinfo, door, nil, nil, nil, {special=true, pit_info={x1=-doorpos.x+4, y1=-doorpos.y+4, x2=-doorpos.x+4+tm.data_w-4-3, y2=-doorpos.y+4+tm.data_h-4-3}})
		tm:put(doorpos, pitinfo)
	end
	tm.pit_doorpos = doorpos
	return tm
end
