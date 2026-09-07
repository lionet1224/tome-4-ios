-- Act never attacks a friendly creature: an escort standing between you and the enemy
-- is walked around, never bumped, and a selected friendly is not a target.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local p, map = game.player, game.level.map
	local m = game.uiset.touch_manual
	for _, e in pairs(game.level.entities) do
		if e.__is_actor and e ~= p and e.x and p:reactionToward(e) < 0 then map:remove(e.x, e.y, Map.ACTOR) game.level:removeEntity(e) end
	end
	local function free(x, y) return map:isBound(x, y) and not map:checkEntity(x, y, Map.TERRAIN, "block_move") and not map(x, y, Map.ACTOR) end
	-- a corridor-free spot: player, friend one tile east, enemy three tiles east
	local placed = false
	for r = 0, 14 do for x = math.floor(map.w / 2) - r, math.floor(map.w / 2) + r do for y = math.floor(map.h / 2) - r, math.floor(map.h / 2) + r do
		if not placed and free(x, y) and free(x + 1, y) and free(x + 2, y) and free(x + 3, y) and free(x + 1, y + 1) and free(x + 1, y - 1) then p:move(x, y, true) placed = true end
	end end if placed then break end end
	local function mk(dx, dy, faction)
		local a = game.zone:makeEntity(game.level, "actor", {type="vermin"}, nil, true)
		if not a then return nil end
		game.zone:addEntity(game.level, a, "actor", p.x + dx, p.y + dy)
		a.faction = faction a.ai = "none" a.never_move = 1 a.max_life = 1000 a.life = 1000
		a.__hits = 0
		local o = a.takeHit a.takeHit = function(self, ...) self.__hits = self.__hits + 1 return o(self, ...) end
		return a
	end
	local friend = mk(1, 0, "escort")
	local enemy = mk(3, 0, "enemies")
	if not friend or not enemy then T.log("no actors") T.log("finished") return end
	T.log("friend reaction", p:reactionToward(friend), "enemy reaction", p:reactionToward(enemy), "enemies in view", #p:actEnemies())
	if p:reactionToward(friend) < 0 then T.log("BAD the escort faction counts as hostile here") end
	p:playerFOV() T.wait(300)
	-- Act steps: the friend must never be hit and the player must not stand still forever
	local x0, y0 = p.x, p.y
	for i = 1, 4 do p:actStep() T.wait(300) end
	T.log(("after 4 Act taps: player %d,%d -> %d,%d  friend hits %d alive %s  enemy hits %d"):format(x0, y0, p.x, p.y, friend.__hits, tostring(not friend.dead), enemy.__hits))
	if friend.__hits > 0 or friend.dead then T.log("BAD Act hit the escort") end
	if p.x == x0 and p.y == y0 then T.log("BAD Act did not walk around the escort") end
	-- a selected friendly is not a target for Act
	m:setTarget(friend) T.wait(200)
	local tgt = p:actResolveTarget({target="nearest"}, nil)
	T.log("selected friend -> target", tgt and tgt.name or "nil")
	if tgt == friend then T.log("BAD a selected friendly became the Act target") end
	m:setTarget(nil)
	T.log("finished")
end
