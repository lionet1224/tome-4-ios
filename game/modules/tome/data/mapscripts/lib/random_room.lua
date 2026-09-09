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

-- Load a random room, converting it to a format taht Tilemap can use
local list = table.clone(args.list or {
	"simple",
	"pilar", "oval","s","cells","inner_checkerboard","y","inner","small_inner_cross","small_cross","big_cells","cells2","inner_cross","cells3","cells4","cells5","cells6","cross","equal2","pilar2","cells7","cells8","double_y","equal","center_arrows","h","pilar_big",
	"big_cross", "broken_room", "cells9", "double_helix", "inner_fort", "multi_pillar", "split2", "womb", "big_inner_circle", "broken_x", "circle_cross", "inner_circle2", "inner_pillar", "small_x", "weird1", "xroads", "broken_infinity", "cells10", "cross_circled", "inner_circle", "micro_pillar", "split1", "weird2",
	"basic_cell", "circular", "cross_quartet", "double_t", "five_blocks", "five_pillars", "five_walls", "four_blocks", "four_chambers", "hollow_cross", "interstice", "long_hall", "long_hall2", "narrow_spiral", "nine_chambers", "sideways_s", "side_passages_2", "side_passages_4", "spiral_cell", "thick_n", "thick_wall", "tiny_pillars", "two_domes", "two_passages", "zigzag",
})

local simple_chance = args.simple_chance or 40
local simple_size = args.simple_size or {w={5, 12}, h={5, 12}}

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

local function make_simple()
	local wall = replacers['#'] or '#'
	local floor = replacers['.'] or '.'
	local tm = Tilemap.new({rng.range(unpack(simple_size.w)), rng.range(unpack(simple_size.h))}, floor)
	tm.random_room_kind = "simple"
	set_exitable(tm)

	for p in tm:pointIterator() do
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
		end
	end

	return tm
end

local function gen(overlist)
	local list = list
	if overlist then list = overlist end
	local rid, ri = rng.table(list)
	if rng.percent(simple_chance) then rid = "simple" end
	-- rid="simple"

	local tm = nil

	-- Handle "simple" nativvely as the "simple" room is actualyl a complex function that cant work here
	if rid == "simple" then
		return make_simple()
	else
		local f, err = loadfile("/data/rooms/"..rid..".lua")
		if not f then error(err) end
		local ok, data = pcall(f)
		if not ok then error(data) end
		if type(data) ~= "table" then
			print("[WARNING] random_room tilemap round room id", rid, "returning a non table")
			table.remove(list, ri)
			return gen(list)
		end

		local w, h = #data[1], #data
		tm = Tilemap.new({w, h})
		tm.random_room_kind = rid
		set_exitable(tm)

		for j = 1, h do
			local i = 1
			for c in data[j]:gmatch(".") do
				if c == '!' then table.insert(tm.rr_exits.openables, tm:point(i, j))
				elseif c == '+' then table.insert(tm.rr_exits.doors, tm:point(i, j)) end

				if replacers[c] then c = replacers[c] end
				tm:put({x=i, y=j}, c)

				i = i + 1
			end
		end
		return tm
	end
end

return gen
