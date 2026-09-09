-- ToME - Tales of Maj'Eyal
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

can_shift = true
base_size = 32
ad = rng.range(0, 360)
ad2 = 0
period = 120
num = 6
radius = radius or 10
life = 18

local colors = {
	{.02, .3, .1},
	{.8, 1, .6},
}

local nb = 0
local frames = 18

local inv = 1

return { generator = function()
	local a = math.rad(ad)*inv
	local a2 = math.rad(ad + ad2)*inv
	local r = base_size * .3
	local r2 = base_size * .8
	if inv < 0 then r2 = r2 * .5 end
	--local dirv = math.rad(1)
	--local col = rng.range(20, 80)/255
	local dir = a2 +math.rad(180)
	
	local x = r*math.cos(a) + r2*math.cos(a2)
	local y = r*math.sin(a) + r2*math.sin(a2)
	
	local vel = 2 * (r2 / life)
	local accel = -vel/(life-1)
	
	local color_f = rng.float(0, 1)
	color_f = color_f ^ 5
	
	local color = {}
	
	for c=1, 3 do
		color[c] = colors[2][c] * color_f + colors[1][c] * (1 - color_f)
	end
	--this averages the color between the two above but weighted heavily towards the first so we get mostly green with lil spikes of yellow! :D
	
	if inv < 1 then
		color[1] = color[1] * .8
		color[2] = color[2] + .4 * (1 - color[2])
		color[3] = color[3] + .1 * (1 - color[3])
	end
	--massages the color of the converse ring a bit for contrast! :D

	return {
		trail = life,
		life = life,
		size = 8, sizev = 0, sizea = 0,

		x = x - 4, xv = 0, xa = 0,
		y = y - 4, yv = 0, ya = 0,
		dir = dir, dirv = 0, dira = 0,
		vel = vel, velv = accel, vela = 0,

		r = color[1],  rv = 0, ra = 0,
		g = color[2],  gv = 0, ga = 0,
		b = color[3],  bv = 0, ba = 0,
		a = .95, av = 0, aa = 0,
	}
end, },
function(self)
	if nb < frames then
		for i = 1, num do
			self.ps:emit(1)
			ad = ad + 360/num
			inv = -inv
		end
		ad = (ad + 80/frames) % 360
		ad2 = ad2 + (120/frames)
		nb = nb+1
	end
end,
num * life