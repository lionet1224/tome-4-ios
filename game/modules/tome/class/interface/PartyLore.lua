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

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local LorePopup = require "mod.dialogs.LorePopup"
local slt2 = require "slt2"

module(..., package.seeall, class.make)

_M.lore_defs = {}

-- iOS port: lore illustrations are decoded and uploaded when a level is entered, so
-- the popup on pickup does not hitch. A small FIFO cache keyed by file name.
local lore_images, lore_images_order = {}, {}
_M.LORE_IMAGE_CACHE_MAX = 12

--- The cached illustration {tex, w, h, tw, th} for data/gfx/lore/<file>, loading it if needed
function _M.loreImage(file)
	if not file then return nil end
	local d = lore_images[file]
	if d ~= nil then return d or nil end
	local ok, surf = pcall(core.display.loadImage, "/data/gfx/lore/"..file)
	if not ok or not surf then lore_images[file] = false return nil end
	local w, h = surf:getSize()
	local tex, tw, th = surf:glTexture()
	d = {tex=tex, w=w, h=h, tw=tw, th=th}
	lore_images[file] = d
	lore_images_order[#lore_images_order+1] = file
	while #lore_images_order > _M.LORE_IMAGE_CACHE_MAX do
		local old = table.remove(lore_images_order, 1)
		lore_images[old] = nil
	end
	return d
end

--- The cached illustration without loading (nil when not cached)
function _M.loreImageCached(file) return file and lore_images[file] or nil end

function _M.loreImageCacheSize() return #lore_images_order end

--- Files of the illustrations of the lore that lies on the current level
function _M.levelLoreImages()
	local files, seen = {}, {}
	if not game or not game.level or not game.level.entities then return files end
	for _, e in pairs(game.level.entities) do
		local id = e.lore or e.on_id_lore
		if type(id) == "string" then
			local l = _M.lore_defs[id]
			if l and l.image and not seen[l.image] then seen[l.image] = true files[#files+1] = l.image end
		end
	end
	return files
end

--- Load them one per timer tick (a big PNG at once would hitch the level load itself)
function _M.preloadLevelLore()
	if not game or not game.registerTimer then return end
	local files = _M.levelLoreImages()
	local queue = {}
	for _, f in ipairs(files) do if not lore_images[f] then queue[#queue+1] = f end end
	_M.preload_queue = queue
	print("[LORE] preloading", #queue, "illustrations for this level")
	if #queue == 0 then return end
	local function step()
		local f = table.remove(_M.preload_queue, 1)
		if not f then return end
		_M.loreImage(f)
		if #_M.preload_queue > 0 then game:registerTimer(0.05, step) end
	end
	game:registerTimer(0.5, step)
end

class:bindHook("Game:changeLevel", function(self, data)
	if require("engine.TouchInput").active() then pcall(_M.preloadLevelLore) end
end)

--- Loads lore
function _M:loadDefinition(file, env)
	local f, err = loadfile(file)
	if not f and err then error(err) end
	setfenv(f, setmetatable(env or {
		Lore = self,
		newLore = function(t) self:newLore(t) end,
		load = function(f) self:loadDefinition(f, getfenv(2)) end
	}, {__index=_G}))
	f()
end

--- Make a new lore with a name and desc
function _M:newLore(t)
	assert(t.id, "no lore name")
	assert(t.category, "no lore category")
	assert(t.name, "no lore name")
	assert(t.lore, "no lore lore")

	t.order = #self.lore_defs+1

	if t.lore and type(t.lore) == "string" then
		t.lore = t.lore:gsub("%[i%]", "#{italic}#"):gsub("%[/i%]", "#{normal}#")
		               :gsub("%[b%]", "#{bold}#"):gsub("%[/b%]", "#{normal}#")
		               :gsub("%[u%]", "#{underline}#"):gsub("%[/u%]", "#{normal}#")
	end

	self.lore_defs[t.id] = t
	self.lore_defs[#self.lore_defs+1] = t
--	print("[LORE] defined", t.order, t.id)
end

function _M:init(t)
	self.additional_lore = self.additional_lore or {}
	self.additional_lore_nb = self.additional_lore_nb or 0
	self.lore_known = self.lore_known or {}
end

function _M:knownLore(lore)
	self.lore_known = self.lore_known or {}
	return self.lore_known[lore] and true or false
end

function _M:isLoreShareable(lore)
	local l = self.lore_defs[lore] or self.additional_lore[lore]
	if not l then return false end
	if l.not_shareable then return false end
	return true
end

function _M:getLore(lore, silent)
	self.lore_known = self.lore_known or {}
	self.additional_lore = self.additional_lore or {}
	if not silent then assert(self.lore_defs[lore] or self.additional_lore[lore], "bad lore id "..lore) end
	local l = self.lore_defs[lore] or self.additional_lore[lore]
	if not l then return end
	l = table.clone(l)

	if l.template then
		local tpl = slt2.loadstring(l.lore)
		local ok, err = pcall(function()
			l.lore = slt2.render(tpl, {player=self:findMember{main=true}, self=self, Lore=_M})
		end)
		if not ok and err then
			error("Error while lore learning '"..tostring(lore).."' : "..tostring(err))
		end
	end	

	return l
end

function _M:additionalLore(id, name, category, lore)
	self.additional_lore = self.additional_lore or {}
	if self.additional_lore[id] then return end
	self.additional_lore_nb = (self.additional_lore_nb or 0) + 1
	self.additional_lore[id] = {id=id, name=name, category=category, lore=lore, order=self.additional_lore_nb + #self.lore_defs}
end

function _M:relearningLore(v)
	self.relearning_lore = v
end

function _M:learnLore(lore, nopopup, silent, nostop, after_learn_cb, display_entity)
	print("[LORE] learning..", lore)
	local l = self:getLore(lore, silent)
	if not l then return end
	local learnt = false

	self.lore_known = self.lore_known or {}

	if not config.settings.tome.lore_popup and profile.mod.lore and profile.mod.lore.lore and profile.mod.lore.lore[lore] and not l.always_pop then
		nopopup = true
		nostop = true
	end

	if not self:knownLore(lore) or l.always_pop then
		game.logPlayer(self, "Lore found: #0080FF#%s", l.name)
		if not nopopup then
			LorePopup.new(l, game.w * 0.6, 0.8, after_learn_cb, display_entity)
			game.logPlayer(self, "You can read all your collected lore in the game menu, by pressing Escape.")
		end
		learnt = true
	end

	self.lore_known[lore] = true
	if learnt and not self.additional_lore[lore] then game.player:registerLoreFound(lore) end
	print("[LORE] learnt", lore)
	if learnt then if l.on_learn then l.on_learn(self:findMember{main=true}, self.relearning_lore) end end

	if game.player.runStop and not nostop then
		game.player:runStop(_t"learnt lore")
		game.player:restStop(_t"learnt lore")
	end

	if nopopup and after_learn_cb then after_learn_cb("nopopup") end
end
