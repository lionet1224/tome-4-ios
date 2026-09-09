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

local p = game.party:findMember{main=true}

local function void_portal_open(npc, player)
	-- Charred scar was successful
	-- do return false end
	if player:hasQuest("charred-scar") and player:hasQuest("charred-scar"):isCompleted("stopped") then return false end
	return true
end
local function aeryn_alive(npc, player)
	for uid, e in pairs(game.level.entities) do
		if e.define_as and e.define_as == "HIGH_SUN_PALADIN_AERYN" then return e end
	end
end


--------------------------------------------------------
-- Distant Sun is not exactly benevolent after all
--------------------------------------------------------
if p:attr("sun_paladin_avatar") then
newChat{ id="welcome",
	text = ([[<<<The two Sorcerers lie dead before you.
Their bodies vanish in a small cloud of mist, quickly fading away.
You feel you the gentle warmth of your Distant Sun patron. It speaks directly to your mind!>>>
#YELLOW#YOU HAVE DONE WELL %s! YOU DESERVE A REWARD!#LAST#
<<<You can feel your mind filling with warmth and desire to serve your patron>>>
#YELLOW#BUT YOU MUST DO ONE MORE TASK!#LAST#
<<<The warmth in your head is getting intense, too intense. You feel your sanity burning away!>>>
#YELLOW#THROW YOURSELF INTO THE PORTAL! OPEN THE WAY FOR MY POWER TO RADIATE OVER YOUR WORLD! #CRIMSON#DO IT!#LAST#
<<<Those last words are compelling. You can not resist!>>>
]]):tformat(p.name:upper()),
	answers = {
		{_t"#YELLOW#[sacrifice yourself to bring forth your patron to Eyal!]", action=function(npc, player)
			player.no_resurrect = true
			player:die(player, {special_death_msg=("sacrificing %s to bring the fiery wrath of the Distant Sun"):tformat(string.his_her_self(player))})
			player:setQuestStatus("high-peak", engine.Quest.COMPLETED, "distant-sun")
			player:hasQuest("high-peak"):win("distant-sun")
		end},
		{_t"Nnnnnooo! Get.. get out of my head!", jump="distant-sun-unsure"},
	}
}

local shertul = game.zone:makeEntityByName(game.level, "actor", "CALDIZAR_AOADS", true)
newChat{ id="distant-sun-unsure",
	text = _t[[<<<The warmth in your mind turns into searing pain!>>>
#CRIMSON#YOU WILL DO AS YOU ARE TOLD! YOU ARE MY TOOL AND I INTEND TO USE IT!
]],
	answers = {
		{_t"#LIGHT_GREEN#[sacrifice yourself to bring forth your patron to Eyal!]", action=function(npc, player)
			player.no_resurrect = true
			player:die(player, {special_death_msg=("sacrificing %s to bring the fiery wrath of the Distant Sun"):tformat(string.his_her_self(player))})
			player:setQuestStatus("high-peak", engine.Quest.COMPLETED, "distant-sun")
			player:hasQuest("high-peak"):win("distant-sun")
		end},
		{_t"#LIGHT_GREEN#[In a last incredible display of willpower you fight the Distant Sun for a few seconds, letting you project your thoughts to Aeryn.]#WHITE# High Lady! Kill me #{bold}#NOW#{normal}#",
			cond=function(npc, player) return not void_portal_open(nil, player) and aeryn_alive(npc, player) and player:getWil() >= 55 end, switch_npc=aeryn_alive(), jump="distant-sun-stab"
		},
		{_t"#LIGHT_GREEN#[In a last incredible display of willpower you fight the Distant Sun for a few seconds, unsure how to stop it.]#WHITE##{bold}#NO!#{normal}#",
			switch_npc=shertul, cond=function(npc, player) return not void_portal_open(nil, player) and not aeryn_alive(npc, player) and player:getWil() >= 55 end, jump="distant-sun-shertul"
		},
	}
}

newChat{ id="distant-sun-stab",
	text = _t[[<<<Through your mind Aeryn sees what the Distant Sun is planning.>>>
You were a precious ally and a friend. The world will remember your last act of selfless sacrifice. I swear it.
<<<As she says this she pierces your body with a mighty thrust of her sword, ending the plans of your mad patron.>>>
]],
	answers = {
		{_t"#LIGHT_GREEN#[slip peacefully into death.]", action=function(npc, player)
			player.no_resurrect = true
			player:die(player, {special_death_msg=("sacrificing %s to stop the mad sun's plans"):tformat(string.his_her_self(player))})
			player:setQuestStatus("high-peak", engine.Quest.COMPLETED, "distant-sun-stab")
			player:hasQuest("high-peak"):win("distant-sun-selfless")
		end},
	}
}

newChat{ id="distant-sun-shertul",
	text = _t[[<<<The precious seconds fly by, but as you feel your mind breaking and burning you see a strange figure appearing in front of you, it radiates of immense power.>>>
<<<The strange, amorphous figure in front of you remains completely silent. With a gesture of one of its tendrils, the staff is ripped from your hands. A surge of energy goes through the room as it grips the staff. Then you remember the old myth of the Godslayers. This is none other than a ***Sher'Tul***#{italic}#, and it knows you have been colluding with a god. That alone tells you everything you need to know.>>>
]],
	answers = {
		{_t"#CRIMSON#[Your mind is burnt by your patron sun! Fight for your sun god now!]", action=function(npc, player)
			player.no_resurrect = true
			game.level.data.no_worldport = true
			game.zone.no_worldport = true
			local who, o, item, inven_id = game.party:findInAllInventoriesBy("define_as", "STAFF_ABSORPTION_AWAKENED")
			if who and o then
				who:removeObject(inven_id, item, true)
			end
			local x, y = util.findFreeGrid(player.x, player.y, 100, true, {[engine.Map.ACTOR]=true})
			if x then
				game.zone:addEntity(game.level, shertul, "actor", x, y)
				shertul:setTarget(player)
				shertul:setPersonalReaction(player, -100)
			end
			player.on_die = function()
				game:onTickEnd(function()
					player:setQuestStatus("high-peak", engine.Quest.COMPLETED, "distant-sun-shertul")
					player:hasQuest("high-peak"):win("distant-sun-shertul")
				end)
			end
		end},
	}
}

return "welcome"
end

--------------------------------------------------------
-- Yeeks have a .. plan
--------------------------------------------------------
if p.descriptor.race == "Yeek" then
newChat{ id="welcome",
	text = ([[#LIGHT_GREEN#*The two Sorcerers lie dead before you.*#WHITE#
#LIGHT_GREEN#*Their bodies vanish in a small cloud of mist, quickly fading away.*#WHITE#
#LIGHT_GREEN#*You feel the Way reaching out to you, the whole yeek race speaks to you.*#WHITE#
You have done something incredible %s! You also have created a unique opportunity for the yeek race!
The energies of those farportals are incredible, using them we could make the Way radiate all over Eyal, forcing it down on the other races, bringing them the same peace and happiness we feel in the Way.
You must go through the farportal and willingly sacrifice yourself inside. Your mind will embed itself into the farportal network, spreading the Way far and wide!
Even though you will die you will bring the world, and the yeeks, ultimate peace.
The Way will never forget you. Now go and make history!
]]):tformat(p.female and _t"sister" or _t"brother"),
	answers = {
		{_t"#LIGHT_GREEN#[sacrifice yourself to bring the Way to every sentient creature.]", action=function(npc, player)
			player.no_resurrect = true
			player:die(player, {special_death_msg=("sacrificing %s to bring the Way to all"):tformat(string.his_her_self(player))})
			player:setQuestStatus("high-peak", engine.Quest.COMPLETED, "yeek")
			player:hasQuest("high-peak"):win("yeek-sacrifice")
		end},
		{_t"But... I did so much, I could do so much more for the Way by staying alive!", jump="yeek-unsure"},
	}
}

newChat{ id="yeek-unsure",
	text = _t[[#LIGHT_GREEN#*You feel the Way taking over your mind, your body.*#WHITE#
You will do as asked, for the good of all Yeeks! The Way is always right.
]],
	answers = {
		{_t"#LIGHT_GREEN#[sacrifice yourself to bring the Way to every sentient creature.]", action=function(npc, player)
			player.no_resurrect = true
			player:die(player, {special_death_msg=("sacrificing %s to bring the Way to all"):tformat(string.his_her_self(player))})
			player:setQuestStatus("high-peak", engine.Quest.COMPLETED, "yeek")
			player:hasQuest("high-peak"):win("yeek-sacrifice")
		end},
		{_t"#LIGHT_GREEN#[In a last incredible display of willpower you fight the Way for a few seconds, letting you project your thoughts to Aeryn.]#WHITE# High Lady! Kill me #{bold}#NOW#{normal}#",
			cond=function(npc, player) return not void_portal_open(nil, player) and aeryn_alive(npc, player) and player:getWil() >= 55 end, switch_npc=aeryn_alive(), jump="yeek-stab"
		},
	}
}

newChat{ id="yeek-stab",
	text = _t[[#LIGHT_GREEN#*Through your mind Aeryn sees what the Way is planning.*#WHITE#
You were a precious ally and a friend. The world will remember your last act of selfless sacrifice. I swear it.
#LIGHT_GREEN#*As she says this she pierces your body with a mighty thrust of her sword, ending the plans of the Way.*#WHITE#
]],
	answers = {
		{_t"#LIGHT_GREEN#[slip peacefully into death.]", action=function(npc, player)
			player.no_resurrect = true
			player:die(player, {special_death_msg=("sacrificing %s to stop the Way"):tformat(string.his_her_self(player))})
			player:setQuestStatus("high-peak", engine.Quest.COMPLETED, "yeek-stab")
			player:hasQuest("high-peak"):win("yeek-selfless")
		end},
	}
}

return "welcome"
end

--------------------------------------------------------
-- Default
--------------------------------------------------------

---------- If the void portal has been opened
if void_portal_open(nil, p) then
newChat{ id="welcome",
	text = _t[[#LIGHT_GREEN#*The two Sorcerers lie dead before you.*#WHITE#
#LIGHT_GREEN#*Their bodies vanish in a small cloud of mist, quickly fading away.*#WHITE#
But the portal to the Void is already open. It must be closed before the Creator can come through or all will have been in vain!
After searching the remains of the Sorcerers you find a note explaining that the portal can only be closed with a sentient being's sacrifice.]],
	answers = {
		{_t"Aeryn, I am sorry but one of us needs to be sacrificed for the world to go on. #LIGHT_GREEN#[sacrifice Aeryn for the sake of the world]", jump="aeryn-sacrifice", switch_npc=aeryn_alive(), cond=aeryn_alive},
		{_t"I will close it. #LIGHT_GREEN#[sacrifice yourself for the sake of the world]", action=function(npc, player)
			player.no_resurrect = true
			player:die(player, {special_death_msg=("sacrificing %s for the sake of the world"):tformat(string.his_her_self(player))})
			player:hasQuest("high-peak"):win("self-sacrifice")
		end},
	}
}

newChat{ id="aeryn-sacrifice",
	text = _t[[I cannot believe we succeeded. I was prepared to die and it seems I will die, but at least I will do so knowing my sacrifice is not in vain.
Please, make sure the world is safe.]],
	answers = {
		{_t"You will never be forgotten.", action=function(npc, player)
			local aeryn = aeryn_alive(npc, player)
			game.level:removeEntity(aeryn, true)
			if player.descriptor and player.descriptor.subclass == "Sun Paladin" then
				game:setAllowedBuild("paladin_fallen", true)
			end
			player:hasQuest("high-peak"):win("aeryn-sacrifice")
		end},
	}
}

----------- If the void portal is still closed
else
newChat{ id="welcome",
	text = _t[[#LIGHT_GREEN#*The two Sorcerers lie dead before you.*#WHITE#
#LIGHT_GREEN#*Their bodies vanish in some immaterial mist.*#WHITE#
You have won the game!
Both Maj'Eyal and the Far East are safe from the dark schemes of the Sorcerers and their God.]],
	answers = {
		{_t"Aeryn, are you well?", jump="aeryn-ok", switch_npc=aeryn_alive(), cond=aeryn_alive},
		{_t"[leave]", action=function(npc, player) player:hasQuest("high-peak"):win("full") end},
	}
}

newChat{ id="aeryn-ok",
	text = _t[[I cannot believe we succeeded. I was prepared to die and yet I live.
I might have underestimated you. You did more than we could have hoped for!]],
	answers = {
		{_t"We both did.", action=function(npc, player) player:hasQuest("high-peak"):win("full") end},
	}
}
end


return "welcome"
