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


-- This file uses Kruskals algorithm to find a MST(minimum spanning tree) in a graph of rooms

local MST = require "engine.algorithms.MST"

local max_links = args.max_links or 3
local map = args.map
local orooms = args.rooms


local mstrun = MST.new()

-- Extract usable rooms
local rooms = {}
for i, room in ipairs(orooms) do if not room.do_not_connect then
	rooms[#rooms+1] = room
end end
if #rooms <= 1 then return true end -- Easy !

local hitmap = nil
if args.check_crossings then
	hitmap = Tilemap.new(self.mapsize, '#')
	for i, room in ipairs(rooms) do
		for x = room.merged_pos.x, room.merged_pos.x + room.data_w - 1 do
			for y = room.merged_pos.y, room.merged_pos.y + room.data_h - 1 do
				hitmap:put(hitmap:point(x, y), i)
			end
		end
	end
end

-- Generate all possible edges
for i, room in ipairs(rooms) do
	local c1 = room:centerPoint()
	for j, proom in ipairs(rooms) do if proom ~= room then
		local c2 = proom:centerPoint()

		-- Check if we cross an other room
		local ok = true
		if args.check_crossings then
			local l = line.new(c1.x, c1.y, c2.x, c2.y)
			local nx, ny = l()
			while nx and ny do
				local v = hitmap:get{x=nx, y=ny}
				if v ~= i and v ~= j and v ~= '#' then ok = false break end
				nx, ny = l()
			end
		end

		if ok then
			mstrun:edge(room, proom, core.fov.distance(c1.x, c1.y, c2.x, c2.y))
		end
	end end
end

-- Compute!
mstrun:run()

if args.edges_surplus_shorter then
	-- Add some more randomly selected edges
	mstrun:fattenShorter(args.edges_surplus or 0)
else
	-- Add some more randomly selected edges
	mstrun:fattenRandom(args.edges_surplus or 0)
end

-- Draw the paths
local full = true
local tunnel_debug_chars = {0,1,2,3,4,5,6,7,8,9,'A','B','C','D','E','F','G','H','I','J','K','L','M','N'}
local tunnel_debug_id = 1

local door_check = args.smart_door_check or {'#'}
door_check[#door_check+1] = '⍓'

local links = {}
for _, edge in pairs(mstrun.mst) do
	local pos1, kind1
	local pos2, kind2
	if args.from_center then
		pos1, kind1 = edge.to:centerPoint(), 'open'
		pos2, kind2 = edge.from:centerPoint(), 'open'
	else
		pos1, kind1 = edge.from:findRandomClosestExit(args.closest_exits or 7, edge.to:centerPoint(), nil, args.exitable_chars or {'.', ';', '='})
		pos2, kind2 = edge.to:findRandomClosestExit(args.closest_exits or 7, edge.from:centerPoint(), nil, args.exitable_chars or {'.', ';', '='})
	end
	if pos1 and pos2 then
		map:tunnelAStar(pos1, pos2, --[[tunnel_debug_chars[tunnel_debug_id] or ]]args.tunnel_char or '.', args.tunnel_through or {'#'}, args.tunnel_avoid or nil, {erraticness=args.erraticness or 5})
		if kind1 == 'open' then map:smartDoor(pos1, args.door_chance or 40, '+', door_check) end
		if kind2 == 'open' then map:smartDoor(pos2, args.door_chance or 40, '+', door_check) end
		tunnel_debug_id = tunnel_debug_id + 1
		links[edge.to] = links[edge.to] or {}
		links[edge.to][edge.from] = true
		links[edge.from] = links[edge.from] or {}
		links[edge.from][edge.to] = true
	else
		full = false
	end
end

return full, links
