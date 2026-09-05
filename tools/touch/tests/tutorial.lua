return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	config.settings.touch = config.settings.touch or {}
	config.settings.touch.tutorial_seen = nil
	local TT = require "mod.dialogs.TouchTutorial"
	local d = TT.new()
	game:registerDialog(d) T.wait(800)
	local function btn(b) local u = d.ui_by_ui[b] return d.display_x + u.x + b.w / 2, d.display_y + u.y + b.h / 2 end
	local n = #TT.PAGES
	for i = 1, n do
		T.shot("tutorial-" .. i)
		T.log("page", d.page, "of", n, tostring(TT.PAGES[d.page].title))
		if i < n then T.tap(btn(d.b_next)) T.wait(400) end
	end
	-- swipe right on the illustration goes back a page
	local ix, iy = d.display_x + d.ix + d.ill_w / 2, d.display_y + d.iy + d.ih / 2
	T.swipe(ix - 60, iy, ix + 80, iy, 120) T.wait(600)
	T.log("after swipe right: page", d.page)
	T.swipe(ix + 60, iy, ix - 80, iy, 120) T.wait(600)
	T.log("after swipe left: page", d.page)
	T.tap(btn(d.b_next)) T.wait(600)
	T.log("after Done: open", tostring(game:hasDialog(d)), "seen", tostring(config.settings.touch.tutorial_seen))
	T.log("finished")
end
