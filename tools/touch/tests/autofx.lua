-- no floating hit text while AUTO plays; 60 fps requested on iOS
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local p = game.player
	T.log("display_fps", tostring(config.settings.display_fps))
	if (config.settings.display_fps or 0) < 60 then T.log("BAD fps below 60") end
	local before = game.flyers:add(p.x, p.y, 30, 0, -1, "test", {255, 255, 255})
	p:autoActStart(true) T.wait(300)
	local during = game.flyers:add(p.x, p.y, 30, 0, -1, "test", {255, 255, 255})
	p:autoActStop("test") T.wait(300)
	local after = game.flyers:add(p.x, p.y, 30, 0, -1, "test", {255, 255, 255})
	T.log("flyer before", tostring(before ~= nil), "during auto", tostring(during ~= nil), "after", tostring(after ~= nil))
	if during ~= nil then T.log("BAD flyer shown during AUTO") end
	if before == nil or after == nil then T.log("BAD flyers suppressed outside AUTO") end
	T.log("finished")
end
