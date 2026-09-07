-- lore illustrations are preloaded on level entry and the popup draws from the cache
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local PL = require "mod.class.interface.PartyLore"
	local files = PL.levelLoreImages()
	T.log("lore illustrations on this level:", #files, table.concat(files, ", "))
	T.wait(3000)
	T.log("cache size after 3 s:", PL.loreImageCacheSize())
	if #files > 0 and PL.loreImageCacheSize() == 0 then T.log("BAD nothing preloaded") end
	if #files == 0 then T.log("none on this level") end
	-- a popup with an illustration: from the cache when preloaded, loaded on demand otherwise
	local def
	for _, l in ipairs(PL.lore_defs) do if type(l.lore) == "string" and l.name and l.image then def = l break end end
	for _, f in ipairs(files) do for _, l in ipairs(PL.lore_defs) do if l.image == f then def = l end end end
	if not def then T.log("no lore def with an image") T.log("finished") return end
	local c0 = os.clock()
	local d = require("mod.dialogs.LorePopup").new(def, game.w * 0.6)
	T.log(("popup '%s' image=%s built in %.0f ms from_cache=%s drawn image=%s"):format(tostring(def.name), tostring(def.image), (os.clock() - c0) * 1000, tostring(d.image_from_cache), tostring(d.image ~= nil)))
	if not d.image then T.log("BAD popup has no illustration") end
	local expected = PL.loreImageCached(def.image) ~= nil
	T.wait(600) T.shot("lore-cache")
	if d.image_from_cache ~= true and #files > 0 then
		-- the level's own lore must come from the preload
		local onlevel = false for _, f in ipairs(files) do if f == def.image then onlevel = true end end
		if onlevel then T.log("BAD level lore was not served from the cache") end
	end
	T.key("EXIT") T.wait(300)
	T.log("finished")
end
