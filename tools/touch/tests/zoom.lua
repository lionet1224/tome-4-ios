return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Map = require "engine.Map"
	local map = game.level.map
	map:recreate() T.wait(600) T.key("MOVE_STAY") T.wait(600)
	T.shot("zoom-recreate-1x")
	map:setZoom(0.6, game.player.x, game.player.y) T.wait(400)
	T.shot("zoom-1.6x")
	map:recreate() T.wait(600) T.key("MOVE_STAY") T.wait(600)
	T.log("after recreate", tostring(Map.zoom), tostring(map.zoom), "mw", map.viewport.mwidth)
	T.shot("zoom-after-recreate")
	map:setZoom(-0.6, game.player.x, game.player.y) T.wait(300)
	T.log("finished")
end
