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

require "engine.class"

--- Handles actors quests
module(..., package.seeall, class.make)

------ Quest Events
local quest_popups = {}
local function tick_end_quests()
	local QuestPopup = require "mod.dialogs.QuestPopup"

	local list = {}
	for quest_id, status in pairs(quest_popups) do
		list[#list+1] = { id=quest_id, status=status }
	end
	quest_popups = {}
	table.sort(list, function(a, b) return a.status > b.status end)

	local lastd = nil
	for _, q in ipairs(list) do
		local quest = game.player:hasQuest(q.id)
		local d = QuestPopup.new(quest, q.status)
		if lastd then
			lastd.unload = function(self) game:registerDialog(d) end
		else
			game:registerDialog(d)
		end
		lastd = d
	end
end

function _M:questPopup(quest, status)
	if game and game.creating_player then return end
	if not quest_popups[quest.id] or quest_popups[quest.id] < status then
		quest_popups[quest.id] = status
		if not game:onTickEndGet("quest_popups") then game:onTickEnd(tick_end_quests, "quest_popups") end
	end
end

function _M:on_quest_grant(quest)
	game.logPlayer(game.player, "#LIGHT_GREEN#Accepted quest '%s'! #WHITE#(Press 'j' to see the quest log)", quest.name)
	if not config.settings.tome.quest_popup then game.bignews:saySimple(60, "#LIGHT_GREEN#Accepted quest '%s'!", quest.name)
	else self:questPopup(quest, -1) end
end

function _M:on_quest_status(quest, status, sub)
	if sub then
		game.logPlayer(game.player, "#LIGHT_GREEN#Quest '%s' status updated! #WHITE#(Press 'j' to see the quest log)", quest.name)
		if not config.settings.tome.quest_popup then game.bignews:saySimple(60, "#LIGHT_GREEN#Quest '%s' updated!", quest.name)
		else self:questPopup(quest, engine.Quest.PENDING) end
	elseif status == engine.Quest.COMPLETED then
		game.logPlayer(game.player, "#LIGHT_GREEN#Quest '%s' completed! #WHITE#(Press 'j' to see the quest log)", quest.name)
		if not config.settings.tome.quest_popup then game.bignews:saySimple(60, "#LIGHT_GREEN#Quest '%s' completed!", quest.name)
		else self:questPopup(quest, status) end
	elseif status == engine.Quest.DONE then
		game.logPlayer(game.player, "#LIGHT_GREEN#Quest '%s' is done! #WHITE#(Press 'j' to see the quest log)", quest.name)
		if not config.settings.tome.quest_popup then game.bignews:saySimple(60, "#LIGHT_GREEN#Quest '%s' done!", quest.name)
		else self:questPopup(quest, status) end
	elseif status == engine.Quest.FAILED then
		game.logPlayer(game.player, "#LIGHT_RED#Quest '%s' is failed! #WHITE#(Press 'j' to see the quest log)", quest.name)
		if not config.settings.tome.quest_popup then game.bignews:saySimple(60, "#LIGHT_RED#Quest '%s' failed!", quest.name)
		else self:questPopup(quest, status) end
	end
end
