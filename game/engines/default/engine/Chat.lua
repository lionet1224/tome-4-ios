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
require "Json2"
local slt2 = require "slt2"

--- Handle chats between the player and NPCs
-- @classmod engine.Chat
module(..., package.seeall, class.make)

_M.chat_dialog = "engine.dialogs.Chat"
_M.chat_context_strings = {"#{italic}##LIGHT_GREEN#", "#LAST##{normal}#"}
_M.chat_bold_strings = {"#{bold}#", "#{normal}#"}

--- Init
-- @string name used to load a chat file
-- @param[type=Actor] npc the NPC that the player is talking to
-- @param[type=Actor] player the player
-- @param[type=table] data
function _M:init(name, npc, player, data)
	print("[CHAT] Loading...", name)

	local hd = {"Chat:init", name=name, npc=npc, player=player, data=data}
	if self:triggerHook(hd) then
		name, npc, player, data = hd.name, hd.npc, hd.player, hd.data
	end

	self.chat_env = {}
	self.quick_replies = 0
	self.chats = {}
	self.npc = npc
	self.player = player
	self.name = name
	data = setmetatable(data or {}, {__index=_G})
	self.data = data
	if not data.player then data.player = player end
	if not data.npc then data.npc = npc end

	local function loadchat(name, setid)
		local filepath, is_chat_format = self:getChatFile(name)
		if not is_chat_format then
			local f, err = loadfile(filepath)
			if not f and err then error(err) end
			local env = setmetatable({
				cur_chat = self,
				loadChatFile = function(file) return loadchat(file, false) end,
				setDialogWidth = function(w) self.force_dialog_width = w end,
				newChat = function(c) self:addChat(c) end,
				setTextFont = function(font, size) self.dialog_text_font = {font, size} end,
				setAnswerFont = function(font, size) self.dialog_answer_font = {font, size} end,
			}, {__index=data})
			setfenv(f, env)
			if setid then self.default_id = f() else return f() end
		else
			self:loadChatFormat(filepath)
		end
	end
	self._loadchat = loadchat
	loadchat(name, true)

	self:triggerHook{"Chat:load", data=data}
end

--- Get chat file
-- Also has support for chat files in addons
-- @string file /data*/chats/{file}.lua
function _M:getChatFile(file)
	local _, _, addon, rfile = file:find("^([^+]+)%+(.+)$")
	if addon and rfile then
		if fs.exists("/data-"..addon.."/chats/"..rfile..".chat") then return "/data-"..addon.."/chats/"..rfile..".chat", true end
		return "/data-"..addon.."/chats/"..rfile..".lua"
	end
	if fs.exists("/data/chats/"..file..".chat") then return "/data/chats/"..file..".chat", true end
	return "/data/chats/"..file..".lua"
end

function _M:setFunctionEnv(fct)
	local env = setmetatable({
		self = self,
		cur_chat = self,
		chat_env = self.chat_env,
		loadChatFile = function(file) return self._loadchat(file, false) end,
		newChat = function(c) self:addChat(c) end,
	}, {__index=_G})
	setfenv(fct, env)
end

--- Build up an answer from various nodes
-- Note to future code divers, this is a recursive method and on long chats can recurse a log, but it only use tailcalls so it's fine. Lua rocks
function _M:chatFormatActions(nodes, answer, node, stop_at)
	if not node or node == stop_at then return end
	local function getnext()
		-- Find out if we have actions to take, conditions to apply and where to jump to
		if table.sget(node, 'outputs', 'output_1', "connections", 1, "node") then
			return nodes[table.sget(node, 'outputs', 'output_1', "connections", 1, "node")]
		end
	end

	local function add_action(node, action)
		self:setFunctionEnv(action)
		if answer.action then
			local old = answer.action
			answer.action = function(npc, player)
				local r1 = old(npc, player)
				local r2 = action(npc, player)
				return r2 or r1
			end
		else
			answer.action = action
		end
	end
	local function add_cond(node, cond)
		if node.data['not'] then local oc = cond cond = function(npc, player) return not oc(npc, player) end end
		self:setFunctionEnv(cond)
		if answer.cond then
			local old = answer.cond
			answer.cond = function(npc, player)
				return old(npc, player) and cond(npc, player)
			end
		else
			answer.cond = cond
		end
	end

	---------------------------------------------------------------------------
	if node.name == "chat" or node.name == "entry-selector" or node.name == "dynamic" then
		answer.jump = node.data.chatid
	---------------------------------------------------------------------------
	elseif node.name == "lua-code" then
		local action, err = loadstring("return function(npc, player) "..node.data.code.." end")
		if not action and err then error("[Chat] chatFormatActions ERROR: "..err) end
		action = action()
		add_action(node, action)
		return self:chatFormatActions(nodes, answer, getnext(), stop_at)
	---------------------------------------------------------------------------
	elseif node.name == "lua-cond" then
		if not node.data.code:find("return ") then node.data.code = "return "..node.data.code end
		local cond, err = loadstring("return function(npc, player) "..node.data.code.." end")
		if not cond and err then error("[Chat] chatFormatActions ERROR: "..err) end
		cond = cond()
		add_cond(node, cond)
		return self:chatFormatActions(nodes, answer, getnext(), stop_at)
	---------------------------------------------------------------------------
	elseif node.name == "quest-set" then
		local Quest = require "engine.Quest"
		local sub = nil
		if node.data.sub ~= "" then sub = node.data.sub end
		add_action(node, function(npc, player) if player:hasQuest(node.data.quest) then player:setQuestStatus(node.data.quest, Quest[node.data.status], sub) end end)
		return self:chatFormatActions(nodes, answer, getnext(), stop_at)
	---------------------------------------------------------------------------
	elseif node.name == "quest-give" then
		local Quest = require "engine.Quest"
		add_action(node, function(npc, player) player:grantQuest(node.data.quest) end)
		return self:chatFormatActions(nodes, answer, getnext(), stop_at)
	---------------------------------------------------------------------------
	elseif node.name == "quest-cond" then
		local Quest = require "engine.Quest"
		local sub = nil
		if node.data.sub ~= "" then sub = node.data.sub end
		add_cond(node, function(npc, player) return player:hasQuest(node.data.quest) and player:isQuestStatus(node.data.quest, Quest[node.data.status], sub) end)
		return self:chatFormatActions(nodes, answer, getnext(), stop_at)
	---------------------------------------------------------------------------
	elseif node.name == "quest-has" then
		if node.data.state == "has" then
			add_cond(node, function(npc, player) return player:hasQuest(node.data.quest) end)
		else
			add_cond(node, function(npc, player) return not player:hasQuest(node.data.quest) end)
		end
		return self:chatFormatActions(nodes, answer, getnext(), stop_at)
	---------------------------------------------------------------------------
	elseif node.name == "birth-descriptor" then
		add_cond(node, function(npc, player) return player.descriptor and player.descriptor[node.data.what] == node.data.value end)
		return self:chatFormatActions(nodes, answer, getnext(), stop_at)
	---------------------------------------------------------------------------
	elseif node.name == "object-has" then
		add_cond(node, function(npc, player)
			local actor = node.data.who == "player" and player or npc
			if node.data['in'] == "all-inventories" then
				return actor:findInAllInventoriesBy(node.data.search_by, node.data.search)
			elseif node.data['in'] == "worn-inventories" then
				return actor:findInAllWornInventoriesBy(true, node.data.search_by, node.data.search)
			elseif node.data['in'] == "nonworn-inventories" then
				return actor:findInAllWornInventoriesBy(false, node.data.search_by, node.data.search)
			else
				return actor:findInInventoryBy(actor:getInven(node.data['in']), node.data.search_by, node.data.search)
			end
			return 
		end)
		return self:chatFormatActions(nodes, answer, getnext(), stop_at)
	---------------------------------------------------------------------------
	elseif node.name == "attr-inc" then
		if not node.data.value:find("return ") then node.data.value = "return "..node.data.value end
		local a, err = loadstring(node.data.value)
		if not a and err then error("[Chat] chatFormatActions ERROR: "..err) end
		a = a()
		local is_player = node.data.who == "player"
		add_action(node, function(npc, player) return (is_player and player or npc):attr(node.data.attr, a) end)
		return self:chatFormatActions(nodes, answer, getnext(), stop_at)
	---------------------------------------------------------------------------
	elseif node.name == "attr-get" then
		if node.data.value == "" and node.data.test ~= "?" and node.data.test ~= "!" then error("[Chat] chatFormatActions ERROR: no value for a non existance test") end
		if not node.data.value:find("return ") then node.data.value = "return "..node.data.value end
		local a, err = loadstring(node.data.value)
		if not a and err then error("[Chat] chatFormatActions ERROR: "..err) end
		a = a()
		local is_player = node.data.who == "player"
		add_cond(node, function(npc, player)
			local actor = (is_player and player or npc)
			local v = actor:attr(node.data.attr)
			if node.data.test == "?" then return v and true or false
			elseif node.data.test == "!" then return not v and true or false
			elseif node.data.test == "=" then return v == a
			elseif node.data.test == ">" then return v > a
			elseif node.data.test == "<" then return v < a
			elseif node.data.test == ">=" then return v >= a
			elseif node.data.test == "<=" then return v <= a
			end
		end)
		return self:chatFormatActions(nodes, answer, getnext(), stop_at)
	---------------------------------------------------------------------------
	elseif node.name == "swap-actor" then
		if node.data.custom == "id" then
			local e
			if node.data.id == "player" then e = self.player
			else e = game.level:findEntity{define_as = node.data.id}
			end
			if e then
				answer.switch_npc = e
				if node.data.move_camera == true then answer.switch_npc_move_camera = true end
			end
		elseif node.data.custom == "true" then
			if not node.data.def:find("return ") then node.data.def = "return "..node.data.def end
			local a, err = loadstring(node.data.def)
			if not a and err then error("[Chat] chatFormatActions ERROR: "..err) end
			answer.switch_npc = engine.Entity.new(a())
		else
			local Map = require "engine.Map"
			local is_tall = false
			if Map.tiles then
				local _, _, _, w, h = Map.tiles:get('', 0, 0, 0, 0, 0, 0, node.data.image)
				is_tall = h > w
			end
			answer.switch_npc = engine.Entity.new{name=node.data.name, image=node.data.image, dislpay_y=is_tall and -1 or 0, display_h=is_tall and 2 or 1}
		end
		return self:chatFormatActions(nodes, answer, getnext(), stop_at)
	---------------------------------------------------------------------------
	elseif node.name == "change-zone" then
		local zone = nil
		if node.data.zone ~= "--" then zone = node.data.zone end
		add_action(node, function() game:changeLevel(tonumber(node.data.level), zone) end)
		return self:chatFormatActions(nodes, answer, getnext(), stop_at)
	---------------------------------------------------------------------------
	elseif node.name == "set-faction-reaction" then
		add_action(node, function(npc, player)
			local f1 = node.data.f1
			if f1 == "--player--" then f1 = player.faction end
			local f2 = node.data.f2
			if f2 == "--npc--" then f2 = npc.faction end
			engine.Faction:setFactionReaction(f1, f2, tonumber(node.data.reaction), true)
		end)
		return self:chatFormatActions(nodes, answer, getnext(), stop_at)
	---------------------------------------------------------------------------
	elseif node.name == "unique" then
		local getstore = function(npc, player)
			local store = {}
			if node.data.store == "player" then player.__chat_uniqueness = player.__chat_uniqueness or {} store = player.__chat_uniqueness end
			if node.data.store == "npc" then npc.__chat_uniqueness = npc.__chat_uniqueness or {} store = npc.__chat_uniqueness end
			if node.data.store == "game" then game.state.__chat_uniqueness = game.state.__chat_uniqueness or {} store = game.state.__chat_uniqueness end
			return store
		end
		add_cond(node, function(npc, player) local store = getstore(npc, player) return not store[node.data.id] end)
		add_action(node, function(npc, player) local store = getstore(npc, player) store[node.data.id] = true end)
		return self:chatFormatActions(nodes, answer, getnext(), stop_at)
	---------------------------------------------------------------------------
	elseif node.name == "not" then
		if answer.cond then local old = answer.cond answer.cond = function(npc, player) return not old(npc, player) end
		else answer.cond = function() return false end end
		return self:chatFormatActions(nodes, answer, getnext(), stop_at)
	---------------------------------------------------------------------------
	elseif node.name == "or" then
		-- Recurse back to the star of the condition chains of both input2 and input3, then walk them the usual way until we reach us again
		local conds = {}
		local function walk_chain(chainnode)
			local fakeanswer = {}
			local function walk(n)
				local tid = table.sget(n, 'inputs', 'input_1', "connections", 1, "node")
				-- If we have a parent, follow it
				if tid then
					return walk(nodes[tid])
				-- No parent, we are the start of the chain, that building the cond
				else
					self:chatFormatActions(nodes, fakeanswer, getnext(), node)
				end
			end
			walk(chainnode)
			conds[#conds+1] = fakeanswer.cond
		end

		for i, d in ipairs(table.sget(node, 'inputs', 'input_2', "connections") or {}) do walk_chain(nodes[d.node]) end
		for i, d in ipairs(table.sget(node, 'inputs', 'input_3', "connections") or {}) do walk_chain(nodes[d.node]) end

		add_cond(node, function(npc, player) for i, cond in ipairs(conds) do if cond(npc, player) then return true end end end)
		return self:chatFormatActions(nodes, answer, getnext(), stop_at)
	else
		return self:triggerHook{"Chat:chatFormatActions", nodes=node, answer=answer, node=node, add_action=add_action, add_cond=add_cond, getnext=getnext, stop_at=stop_at}
	end
end

function _M:loadChatFormat(filepath)
	local fdata = fs.readAll(filepath)
	if not fdata then print("[Chat] loadChatFormat: error reading file") return end
	local data = json.decode(fdata)

	-- Fix chatids to ensure uniqueness
	local chatids = {}
	for nodeid, node in pairs(data) do
		if node.name == "chat" then
			local chatid = node.data.chatid
			while chatids[node.data.chatid] do node.data.chatid = chatid..rng.range(1, 99999) end
			chatids[node.data.chatid] = node
		end
	end

	for nodeid, node in pairs(data) do
		if node.name == "chat" then
			local answers = {}
			local i = 1
			while node.data["answer"..i] do
				answers[i] = {_t(node.data["answer"..i])}
				-- Find out if we have actions to take, conditions to apply and where to jump to
				if table.sget(node, 'outputs', 'output_'..i, "connections", 1, "node") then
					local tn = data[table.sget(node, 'outputs', 'output_'..i, "connections", 1, "node")]
					self:chatFormatActions(data, answers[i], tn)
				end
				i = i + 1
			end
			self:addChat{ id = node.data.chatid,
				text = _t(node.data.chat),
				answers = answers,
			}	
		elseif node.name == "entry-selector" then
			local answers = {}
			local i = 1
			while table.sget(node, 'outputs', 'output_'..i, "connections", 1, "node") do
				answers[i] = {""}
				-- Find out if we have actions to take, conditions to apply and where to jump to
				local tn = data[table.sget(node, 'outputs', 'output_'..i, "connections", 1, "node")]
				self:chatFormatActions(data, answers[i], tn)
				i = i + 1
			end
			local auto, err = loadstring("return function(npc, player) "..node.data.code.." end")
			if not auto and err then error("[Chat] chatFormatActions ERROR: "..err) end
			auto = auto()
			self:setFunctionEnv(auto)
			self:addChat{ id = node.data.chatid,
				text = "",
				auto = auto,
				answers = answers,
			}	
		elseif node.name == "dynamic" then
			local auto, err = loadstring(node.data.code)
			if not auto and err then error("[Chat] chatFormatActions ERROR: "..err) end
			self:setFunctionEnv(auto)
			local text, answers = auto()
			self:addChat{ id = node.data.chatid,
				text = text,
				answers = answers,
			}	
		end
	end
	self.default_id = "welcome"
end

--- Switch the NPC talking
-- @param[type=Actor] npc
-- @return NPC we switched from
function _M:switchNPC(npc, pan_camera)
	local old = self.npc
	self.npc = npc
	if pan_camera and game.level and game.level.map and npc.x and npc.y then
		game.level.map:centerViewAround(npc.x, npc.y)
	end
	return old
end

--- Adds a chat to the list of possible chats
-- @param[type=table] c
function _M:addChat(c)
	self:triggerHook{"Chat:add", c=c}

	assert(c.id, "no chat id")
	assert(c.text or c.template, "no chat text or template")
	assert(c.answers, "no chat answers")
	self.chats[c.id] = c
	print("[CHAT] loaded", c.id, c)

	if not c.ignore_easy_controls and c.text then
		c.text = c.text:gsub("<<<(.-)>>>", self.chat_context_strings[1].."%1"..self.chat_context_strings[2])
		c.text = c.text:gsub("%*%*(.-)%*%*", self.chat_bold_strings[1].."%1"..self.chat_bold_strings[2])
	end

	-- Parse answers looking for quick replies
	for i, a in ipairs(c.answers) do
		if a.quick_reply then
			a.jump = "quick_reply"..self.quick_replies
			self:addChat{id="quick_reply"..self.quick_replies, text=a.quick_reply, answers={{"[leave]"}}}
			self.quick_replies = self.quick_replies + 1
		end
	end
end

--- Invokes a chat
-- @string[opt=self.default_id] id the id of the first chat to run
-- @return `engine.dialog.Chat`
function _M:invoke(id)
	if self.npc.onChat then self.npc:onChat() end
	if self.player.onChat then self.player:onChat() end

	local hd = {"Chat:invoke", id = id or self.default_id }
	self:triggerHook(hd)

	local d = require(self.chat_dialog).new(self, hd.id, self.force_dialog_width or 500)
	game:registerDialog(d)
	return d
end

--- Gets the chat with the given id
-- @string id the id of the chat
-- @return `Chat`
function _M:get(id)
	local c = self.chats[id]
	if c and c.template then
		local tpl = slt2.loadstring(c.template)
		c.text = slt2.render(tpl, {data=self.data, player=self.player, npc=self.npc})
	end
	return c
end

--- Replace some keywords in the given text
-- @string text @playername@, @npcname@, @playerdescriptor.(.-)@
function _M:replace(text)
	local Birther = require "engine.Birther"
	text = text:noun_sub("@playername@", self.player:getName()):noun_sub("@npcname@", self.npc.getName and self.npc:getName() or _t(self.npc.name, "entity name") or _t"???")
	text = text:gsub("@playerdescriptor.(.-)@", function(what)
		if not self.player.descriptor then return _t"???" end
		if self.player.descriptor["fake_"..what] then return _t(self.player.descriptor["fake_"..what]) end
		if self.player.descriptor[what] and Birther.birth_descriptor_def[what] and Birther.birth_descriptor_def[what][self.player.descriptor[what]] then
			if Birther.birth_descriptor_def[what][self.player.descriptor[what]].chat_name then return Birther.birth_descriptor_def[what][self.player.descriptor[what]].chat_name end
			if Birther.birth_descriptor_def[what][self.player.descriptor[what]].display_name then return Birther.birth_descriptor_def[what][self.player.descriptor[what]].display_name end
		end
		return _t(self.player.descriptor[what])
	end)
	return text
end
