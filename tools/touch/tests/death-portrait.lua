-- Touch death screen in portrait (preview mode, no side effects): stacked layout, every ui inside, reopen.
-- Run with TOUCH_EXTRA=', orientation="portrait", hand="left"' tools/touch/sim-run.sh tools/touch/tests/death-portrait.lua <outdir>
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local TI = require "engine.TouchInput"
	T.log("size", game.w, game.h, "portrait", tostring(TI.portrait()))
	local DD = require "mod.dialogs.DeathDialog"
	local d = DD.new(game.player, {preview=true})
	game:registerDialog(d)
	T.wait(800)
	T.log("dialog", d.iw, d.ih, "portrait layout", tostring(d.portrait), "hero_h", d.hero_h, "flow_y", tostring(d.flow_y), "left_w", d.left_w)
	local function checkBounds(tag)
		local bad = 0
		for _, u in ipairs(d.uis) do
			local ui = u.ui
			if not (ui.w and ui.w > 0 and ui.h and ui.h > 0) then T.log("BAD "..tag..": ui with empty size", tostring(ui.__CLASSNAME), tostring(ui.w), tostring(ui.h)) bad = bad + 1 end
			if u.x > -1000 and u.x < 50000 then
				if u.x < d.ix or u.y < d.iy or u.x + ui.w > d.ix + d.iw + 1 or u.y + ui.h > d.iy + d.ih + 1 then
					T.log("BAD "..tag..": ui outside the dialog", tostring(ui.__CLASSNAME), u.x, u.y, ui.w, ui.h, "dialog", d.ix, d.iy, d.iw, d.ih) bad = bad + 1
				end
			end
		end
		T.log(tag, "bounds checked, problems", bad)
	end
	checkBounds("open")
	if d.portrait and d.c_flow.w < d.iw - 1 then T.log("BAD portrait choices not full width", d.c_flow.w, d.iw) end
	T.log("choices", #d.list)
	T.shot("death-portrait")
	-- scroll the death text a little (it sits above the choices in portrait)
	local e = d.ui_by_ui[d.c_desc]
	if e then
		local x, y = d.display_x + e.x + d.c_desc.w / 2, d.display_y + e.y + d.c_desc.h / 2
		T.swipe(x, y + 60, x, y - 60, 300) T.wait(400)
	end
	-- rotation hook: preview dialogs rebuild
	local nd = d:touch_reopen()
	T.log("reopen", tostring(nd ~= nil), "choices", tostring(nd and #nd.list))
	if not nd then T.log("BAD touch_reopen returned nil for a preview dialog") end
	if nd then game:replaceDialog(d, nd) d = nd T.wait(400) checkBounds("reopened") end
	-- the last card is always "Exit to main menu"; in preview it only prints and closes
	local function itemAt(sec, i) local it = d.c_flow.sections[sec].items[i] return d.c_flow.last_screen_x + it.x + it.w / 2, d.c_flow.last_screen_y + it.y + it.h / 2 - d.c_flow.scrollbar.pos end
	T.tap(itemAt(1, #d.list)) T.wait(500)
	T.log("dialog still open", tostring(game:hasDialog(d)))
	T.shot("death-portrait-after")
	T.log("finished")
end
