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

return function(jumpback_id, on_success, mainbases)
	local l = {{_t"I've changed my mind.", jump = jumpback_id}}
	for kind, bases in pairs(mainbases) do
		l[#l+1] = {_t(kind):capitalize(), action=function(npc, player)
			local l = {{_t"I've changed my mind.", jump = jumpback_id}}
			newChat{ id="makereal",
				text = _t[[Which kind of item would you like ?]],
				answers = l,
			}

			for i, name in ipairs(bases) do
				local dname = nil
				if type(name) == "table" then name, dname = name[1], name[2] end
				local not_ps, force_themes
				not_ps = game.state:attrPowers(player) -- make sure randart is compatible with player
				if not_ps.arcane then force_themes = {'antimagic'} end
				
				local o, ok
				local tries = 100
				repeat
					o = game.zone:makeEntity(game.level, "object", {name=name, ignore_material_restriction=true, no_tome_drops=true, ego_filter={keep_egos=true, ego_chance=-1000}}, nil, true)
					if o then ok = true end
					if o and not game.state:checkPowers(player, o, nil, "antimagic_only") then
						ok = false o = nil 
					end
					tries = tries - 1
				until ok or tries < 0
				if o then
					if not dname then dname = o:getName{force_id=true, do_color=true, no_count=true}
					else dname = "#B4B4B4#"..o:getDisplayString()..dname.."#LAST#" end
					l[#l+1] = {dname, action=function(npc, player)
						local art, ok
						local nb = 0
						repeat
							art = game.state:generateRandart{base=o, lev=70, egos=4, force_themes=force_themes, forbid_power_source=not_ps}
							if art then ok = true end
							if art and not game.state:checkPowers(player, art, nil, "antimagic_only") then
								ok = false
							end
							nb = nb + 1
							if nb == 40 then break end
						until ok
						if art and nb < 40 then
							art:identify(true)
							player:addObject(player.INVEN_INVEN, art)
							on_success(player, art)
							-- clear chrono worlds and their various effects
							game:chronoCancel(_t"#CRIMSON#Your timetravel has no effect on pre-determined outcomes such as this.")
							if not config.settings.cheat then game:saveGame() end

							newChat{ id="naming",
								text = ("Do you want to name your item?\n%s"):tformat(tostring(art:getTextualDesc())),
								answers = {
									{_t"Yes, please.", action=function(npc, player)
										local d = require("engine.dialogs.GetText").new(_t"Name your item", _t"Name", 2, 40, function(txt)
											art.name = txt:removeColorCodes():gsub("#", " ")
											game.log("#LIGHT_BLUE#You are given: %s", art:getName{do_color=true})
										end, function() game.log("#LIGHT_BLUE#You are given: %s", art:getName{do_color=true}) end)
										game:registerDialog(d)
									end},
									{_t"No thanks.", action=function() game.log("#LIGHT_BLUE#You are given: %s", art:getName{do_color=true}) end},
								},
							}
							return "naming"
						else
							newChat{ id="oups",
								text = _t"Oh I am sorry, it seems we could not make the item your require.",
								answers = {
									{_t"Oh, let's try something else then.", jump="make"},
									{_t"Oh well, maybe later then."},
								},
							}
							return "oups"
						end
					end}
				end
			end

			return "makereal"
		end}
	end
	return l
end
