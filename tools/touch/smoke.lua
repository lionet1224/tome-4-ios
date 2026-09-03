-- Scripted touch smoke test (engine.TouchInput script). Runs on the Mac with
-- touch emulation, or on iOS. Markers are checked by tools/touch/mac-run.sh.
return function(T)
	local w, h = core.display.size()
	T.log("screen", w, h)
	T.key("EXIT")                       -- close the birth-time level-up dialog
	T.wait(500)
	T.tap(w / 2 + 96, h / 2)             -- walk one tile: a plain tap
	T.wait(400)
	T.hold(w / 2 + 96, h / 2, 700)       -- hold = tile action menu (right click)
	T.wait(400)
	T.key("EXIT")                        -- close the menu
	T.wait(300)
	T.swipe(w / 2, h / 2, w / 2 - 160, h / 2, 400)   -- drag = pan
	T.wait(300)
	T.swipe(w * 0.2, h * 0.7, w * 0.2 + 120, h * 0.7 - 60, 600, 250) -- hold, slide: hotkey wheel
	T.wait(500)
	T.key("EXIT")                        -- cancel targeting if the wheel fired a talent
	T.wait(300)
	T.two_finger()                       -- Escape: game menu opens
	T.wait(400)
	T.key("EXIT")                        -- and closes
	T.wait(300)
	T.key("SHOW_INVENTORY")
	T.wait(500)
	T.swipe(w * 0.7, h * 0.6, w * 0.7, h * 0.3, 300)  -- drag inside a dialog = scroll
	T.wait(300)
	T.key("EXIT")
	T.wait(300)
	T.log("finished")
end
