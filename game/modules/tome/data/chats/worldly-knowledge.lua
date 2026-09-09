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

local function generate_rewards()
	local rewards = game.player:callTalent(game.player.T_WORLDLY_KNOWLEDGE, "getRewards")
	local answers = {}
	local what = rewards.all
	if not game.player:attr("has_arcane_knowledge") then what = table.merge(what, rewards.antimagic) end
	if not game.player:attr("forbid_arcane") then what = table.merge(what, rewards.normal) end
	local rewards_s = table.keys(what) table.sort(rewards_s)
	if rewards_s then
		for _, tt in ipairs(rewards_s) do if game.player:knowTalentType(tt) == nil or game.player:knowTalentType(tt) == false then
			local tt_def = game.player:getTalentTypeFrom(tt)
			local cat = tt_def.type:gsub("/.*", "")
			local doit = function(npc, player)
				if player:knowTalentType(tt) == nil then player:setTalentTypeMastery(tt, 1.0) end
				player:learnTalentType(tt, true)
			end
			answers[#answers+1] = {("[%s (at mastery %0.2f)]"):tformat(_t(cat, "talent category"):capitalize().." / "..tt_def.name:capitalize(), 1.0),
				action=doit,
				on_select=function(npc, player)
					game.tooltip_x, game.tooltip_y = 1, 1
					game:tooltipDisplayAtMap(game.w, game.h, ("#GOLD#%s / %s#LAST#\n%s"):tformat(_t(cat, "talent category"):capitalize(), tt_def.name:capitalize(), tt_def.description))
				end,
			}
		end end
	end
	return answers
end

newChat{ id="welcome",
	text = _t[[Learn which category?]],
	answers = generate_rewards(),
}

return "welcome"
