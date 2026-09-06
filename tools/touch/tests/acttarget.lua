-- a tapped target overrides the routine's "nearest enemy" rule
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local p, map = game.player, game.level.map
	local function free(x, y) return map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR) end
	local function spawn(dx, dy)
		local x, y = p.x + dx, p.y + dy
		if not free(x, y) then return nil end
		local npc = game.zone:makeEntity(game.level, "actor", {type="vermin"}, nil, true)
		if not npc then return nil end
		game.zone:addEntity(game.level, npc, "actor", x, y) npc.faction = "enemies"
		return npc
	end
	local near, far
	for _, d in ipairs{{1, 0}, {-1, 0}, {0, 1}, {0, -1}} do near = spawn(d[1], d[2]) if near then break end end
	for _, d in ipairs{{3, 0}, {-3, 0}, {0, 3}, {0, -3}, {3, 3}, {-3, -3}} do far = spawn(d[1], d[2]) if far then break end end
	if not near or not far then T.log("could not spawn two hostiles") T.log("finished") return end
	T.log("near", near.name, "far", far.name)
	p:playerFOV() T.wait(400) -- the enemy list comes from the field of view
	local step = {kind="bump", target="nearest", if_unusable="skip"}
	local r0 = p:actResolveTarget(step)
	T.log("no selection ->", tostring(r0 and r0.name), r0 == near and "(near)" or "")
	if r0 ~= near then T.log("BAD nearest rule should pick the adjacent one") end
	game.uiset.touch_manual:setTarget(far) T.wait(200)
	local r1 = p:actResolveTarget(step)
	T.log("far selected ->", tostring(r1 and r1.name), r1 == far and "(far)" or "")
	if r1 ~= far then T.log("BAD selected target ignored") end
	-- the selection dies: back to the rule
	far:die(p) T.wait(300)
	local r2 = p:actResolveTarget(step)
	T.log("far dead ->", tostring(r2 and r2.name))
	if r2 ~= near then T.log("BAD dead selection should fall back to nearest") end
	T.log("finished")
end
