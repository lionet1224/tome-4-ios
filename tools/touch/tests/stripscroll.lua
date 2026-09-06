-- portrait band: a drag on the skill strip scrolls it and nothing else (no map pan, no card on
-- release); a hold-and-scrub tooltip on the map clears with the finger
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local TI = require "engine.TouchInput"
	local p, map = game.player, game.level.map
	local m = game.uiset.touch_manual
	local r = m:layout()
	T.log(("portrait=%s band_y=%s strip=%s"):format(tostring(TI.portrait()), tostring(r.band_y), r.strip and ("%d,%d %dx%d"):format(r.strip.x, r.strip.y, r.strip.w, r.strip.h) or "nil"))
	if not r.strip then T.log("BAD no strip") T.log("finished") return end
	-- the card area starts past the header (170 px + margins)
	local x1, y1 = r.strip.x + 12 + 170 + 60, r.strip.y + r.strip.h / 2
	local mx0, my0, turn0 = map.mx, map.my, game.turn
	T.swipe(x1, y1, x1 - 160, y1 - r.strip.h / 2 - 60, 400) -- leaves the strip upwards, onto the map
	T.wait(800)
	T.log(("after strip drag: view %s,%s -> %s,%s turn %d -> %d key=%s"):format(mx0, my0, map.mx, map.my, turn0, game.turn, game.key == game.normal_key and "normal" or "other"))
	if map.mx ~= mx0 or map.my ~= my0 then T.log("BAD strip drag panned the map") end
	if game.turn ~= turn0 then T.log("BAD strip drag fired a card") end
	if game.key ~= game.normal_key then T.log("BAD strip drag left targeting on") T.key("EXIT") T.wait(300) end
	-- hold on a tile a few tiles away, scrub, release: the tooltip must not stay
	local tx, ty = p.x + 3, p.y
	if not map:isBound(tx, ty) then tx = p.x - 3 end
	local sx, sy = map:getTileToScreen(tx, ty, true)
	if sy and r.band_y and sy < r.band_y - 20 then
		T.swipe(sx, sy, sx + 40, sy, 300, 700)
		T.wait(300)
		T.log("tooltip after scrub release:", tostring(game.tooltip_x))
		-- a tap on the band background (between AUTO and More)
		local bx = (r.auto.x + r.auto.w + r.more.x) / 2
		T.tap(bx, r.act.y + 40) T.wait(300)
		T.log("tooltip after band tap:", tostring(game.tooltip_x))
		if game.tooltip_x ~= nil then T.log("BAD tooltip stuck") end
	else
		T.log("note: tile off the map view, tooltip step skipped")
	end
	T.shot("strip")
	T.log("finished")
end
