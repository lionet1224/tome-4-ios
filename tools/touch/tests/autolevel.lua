-- a level up stops AUTO
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p = game.player
	p:autoActStart() T.wait(600)
	local lvl = p.level
	p:gainExp(p:getExpChart(p.level + 1) - p.exp + 5)
	T.wait(1500)
	T.log("level", lvl, "->", p.level, "auto_act", tostring(p.auto_act))
	if p.level == lvl then T.log("note: no level gained") end
	if p.auto_act then T.log("BAD AUTO kept going after the level up") p:autoActStop("test") end
	T.log("finished")
end
