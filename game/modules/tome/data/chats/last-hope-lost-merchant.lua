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
local q = game.player:hasQuest("lost-merchant")
if q and q:isStatus(q.COMPLETED, "saved") then

npc.chat_display_entity = engine.Entity.new{name=_t"Urthol's Wondrous Emporium", image="portrait/shop_urthol_s_wondrous_emporium.png"}

local p = game:getPlayer(true)

local trap = p:knowTalentType("cunning/trapping") and not game.state:unlockTalentCheck(player.T_AMBUSH_TRAP, player)
local poison = p:getTalentFromId(p.T_STONING_POISON)
local poison = poison and p:knowTalentType("cunning/poisons") and not p:knowTalent(poison) and p:canLearnTalent(poison)
newChat{ id="welcome",
	text = _t[[Ah, my #{italic}#good#{normal}# friend @playername@!
Thanks to you I made it safely to this great city! I am planning to open my most excellent boutique soon, but since I am in your debt, perhaps I could open early for you if you are in need of rare goods.]]
..((trap or poison) and (_t"\nBy the way, "..((trap and _t"during our escape I found the plans for an #YELLOW#Ambush Trap#LAST#" or "")
..(poison and (trap and _t" and while" or _t"while").. _t" organizing my inventory, I came across some #YELLOW#Smelly Toxin#LAST# that a colleague claimed could actually turn creatures to stone.  Truly exotic!" or _t".")).._t"\nYou would not happen to be interested, by any chance?") or "")
..((game.state:isAdvanced() and _t"\nOh my friend, good news! As I told you I can now request a truly #{italic}#unique#{normal}# object to be crafted just for you. For a truly unique price..." or _t"\nI eventually plan to arrange a truly unique service for the most discerning of customers. If you come back later when I'm fully set up I shall be able to order for you something quite marvellous. For a perfectly #{italic}#suitable#{normal}# price, of course.")),
	answers = {
		{_t"Yes please, let me see your wares.", action=function(npc, player)
			npc.store:loadup(game.level, game.zone)
			npc.store:interact(player)
		end},
		{_t"What about the unique object?", cond=function(npc, player) return game.state:isAdvanced() end, jump="unique1"},
		{_t"Ambush Trap?  Sounds useful.", cond=function(npc, player) return trap end, jump="trap"},
		{_t"Smelly Toxin?  What kind of smell?", cond=function(npc, player) return poison end, jump="poison"},
		{_t("Sorry, I have to go!", "chat_last-hope-lost-merchant")},
	}
}

newChat{ id="trap",
	text = _t[[You know, I have asked here and there and it happens to be a very rare thing this contraption...
But since you have saved me, I'm willing to part from it for only 3000 gold pieces, a real bargain!]],
	answers = {
		{_t"Expensive, but I will take it.", cond=function(npc, player) return player.money >= 3000 end, jump="traplearn"},
		{_t"..."},
	}
}

newChat{ id="traplearn",
	text = _t[[Nice doing business with you my friend. There you go!]],
	answers = {
		{_t("Thanks.", "chat_last-hope-lost-merchant"), action=function(npc, player)
			game.state:unlockTalent(player.T_AMBUSH_TRAP, player)
			player:incMoney(-3000)
		end},
	}
}

newChat{ id="poison",
	text = _t[[Ungrol told me this substance contains some exceedingly rare components.
"More Toxin than Medicine" he said.  Allas, he had not the funds to buy it.  On the other hand, because of our special relationship, I'm willing to let you have it #{italic}#at cost#{normal}# -- only 1500 gold pieces!]],
	answers = {
		{_t"Fairly pricey, but seems useful.  We have a deal!", cond=function(npc, player) return player.money >= 1500 end, jump="poisonlearn"},
		{_t"That price ... er stuff really stinks ..."},
	}
}

newChat{ id="poisonlearn",
	text = _t[[Here you are.  Just be sure not to get any on yourself!]],
	answers = {
		{_t("Thanks.", "chat_last-hope-lost-merchant"), action=function(npc, player)
			player:incMoney(-1500)
			player:learnTalent(player.T_STONING_POISON, true, 1)
		end},
	}
}

newChat{ id="unique1",
	text = _t[[I normally offer this service only for a truly deserved price, but for you my friend I am willing to offer a 20% discount - #{italic}#only#{normal}# 4000 gold to make an utterly unique item of your choice.  What do you say?]],
	answers = {
		{_t"Why, 'tis a paltry sum - take my order, man, and be quick about it!", cond=function(npc, player) return player.money >= 10000 end, jump="make"},
		{_t"Yes, please!", cond=function(npc, player) return player.money >= 4000 end, jump="make"},
		{_t"HOW MUCH?! Please, excuse me, I- I need some fresh air...", cond=function(npc, player) return player.money < 500 end},
		{_t"Not now, thank you."},
	}
}

local maker_list = loadChatFile("artifact-maker")
local artifacts_bases = {
	armours = {
		"elven-silk robe",
		"drakeskin leather armour",
		"voratun mail armour",
		"voratun plate armour",
		"elven-silk cloak",
		"drakeskin leather gloves",
		"voratun gauntlets",
		"elven-silk wizard hat",
		"drakeskin leather cap",
		"voratun helm",
		"pair of drakeskin leather boots",
		"pair of voratun boots",
		"drakeskin leather belt",
		"voratun shield",
	},
	weapons = {
		"voratun battleaxe",
		"voratun greatmaul",
		"voratun greatsword",
		"voratun waraxe",
		"voratun mace",
		"voratun longsword",
		"voratun dagger",
		"living mindstar",
		"quiver of dragonbone arrows",
		"dragonbone longbow",
		"drakeskin leather sling",
		"dragonbone staff",
		"pouch of voratun shots",
	},
	misc = {
		"voratun ring",
		"voratun amulet",
		"dwarven lantern",
		"voratun pickaxe",
		{"dragonbone wand", _t"dragonbone wand"},
		{"dragonbone totem", _t"dragonbone totem"},
		{"voratun torque", _t"voratun torque"},
	},
}
cur_chat:triggerHook{"LostMerchant:artifactList", artifacts_bases=artifacts_bases}
newChat{ id="make",
	text = _t[[Which kind of item would you like ?]],
	answers = maker_list("welcome", function(player, art) player:incMoney(-4000) end, artifacts_bases),
}

else

newChat{ id="welcome",
	text = _t[[*This store does not appear to be open yet*]],
	answers = {
		{_t"[leave]"},
	}
}

end

return "welcome"
