-- Touch character creation in portrait: step pills on top, cards full width, bottom sheet; reopen.
-- Run with TOUCH_EXTRA=', orientation="portrait", hand="left"' tools/touch/sim-run.sh tools/touch/tests/birth-portrait.lua <outdir>
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local TI = require "engine.TouchInput"
	T.log("size", game.w, game.h, "portrait", tostring(TI.portrait()))
	local TB = require "mod.dialogs.TouchBirther"
	local d = TB.new("test", game.player, {"base", "world", "difficulty", "permadeath", "race", "subrace", "sex", "class", "subclass"}, function() end)
	game:registerDialog(d)
	T.wait(800)
	T.log("dialog", d.iw, d.ih, "portrait layout", tostring(d.portrait), "bar_h", tostring(d.bar_h), "sheet_y", tostring(d.sheet_y), "content_w", d.content_w)
	if d.content_w <= 0 then T.log("BAD content width", d.content_w) end

	local function checkBounds(tag)
		local bad = 0
		for _, u in ipairs(d.uis) do
			local ui = u.ui
			if u.x > -1000 and u.x < 50000 then -- parked uis sit at -9999
				if not (ui.w and ui.w > 0 and ui.h and ui.h > 0) then T.log("BAD "..tag..": ui with empty size", tostring(ui.text or ui.__CLASSNAME), tostring(ui.w), tostring(ui.h)) bad = bad + 1 end
				if u.x < d.ix or u.y < d.iy or u.x + ui.w > d.ix + d.iw + 8 or u.y + ui.h > d.iy + d.ih + 8 then
					T.log("BAD "..tag..": ui outside the dialog", tostring(ui.text or ui.__CLASSNAME), u.x, u.y, ui.w, ui.h, "dialog", d.ix, d.iy, d.iw, d.ih) bad = bad + 1
				end
			end
		end
		T.log(tag, "bounds checked, problems", bad)
	end
	local function itemAt(sec, i) local it = d.c_flow.sections[sec].items[i] return d.c_flow.last_screen_x + it.x + it.w / 2, d.c_flow.last_screen_y + it.y + it.h / 2 - d.c_flow.scrollbar.pos end
	local function btn(b) local u = d.ui_by_ui[b] return d.display_x + u.x + b.w / 2, d.display_y + u.y + b.h / 2 end
	local function pill(i) local u = d.ui_by_ui[d.c_rail] return d.display_x + u.x + (i - 0.5) * (d.c_rail.pill_w + d.c_rail.gap), d.display_y + u.y + d.c_rail.h / 2 end

	checkBounds("who")
	T.shot("birthp-1-who")
	T.tap(itemAt(2, 2)) T.wait(300) -- Male
	T.log("sex", tostring(d.descriptors_by_type.sex))
	if d.descriptors_by_type.sex ~= "Male" then T.log("BAD sex card tap") end
	T.tap(btn(d.b_next)) T.wait(600)
	T.log("step", tostring(d.step))
	if d.step ~= 2 then T.log("BAD Next did not reach the race step") end
	checkBounds("race")
	T.shot("birthp-2-race")
	T.tap(itemAt(1, 1)) T.wait(500)
	T.log("race parent", tostring(d.race_parent and d.race_parent.id))
	if #d.c_flow.sections >= 2 then T.tap(itemAt(2, 2)) T.wait(500) end
	T.log("subrace", tostring(d.descriptors_by_type.subrace))
	if not d.descriptors_by_type.subrace then T.log("BAD no subrace picked") end
	T.shot("birthp-2-lineage")
	T.tap(btn(d.b_next)) T.wait(600)
	if d.step ~= 3 then T.log("BAD Next did not reach the class step") end
	T.tap(itemAt(1, 1)) T.wait(500)
	T.log("class parent", tostring(d.class_parent and d.class_parent.id))
	if #d.c_flow.sections >= 2 then T.tap(itemAt(2, 1)) T.wait(500) end
	T.log("subclass", tostring(d.descriptors_by_type.subclass))
	if not d.descriptors_by_type.subclass then T.log("BAD no subclass picked") end
	checkBounds("class")
	T.shot("birthp-3-class")
	-- rotation hook: a fresh dialog with the same choices at the same step
	local nd = d:touch_reopen()
	T.log("reopen: step", d.step, "->", tostring(nd and nd.step), "name", tostring(nd and nd.c_name.text), "sex", tostring(nd and nd.descriptors_by_type.sex), "subrace", tostring(nd and nd.descriptors_by_type.subrace), "subclass", tostring(nd and nd.descriptors_by_type.subclass))
	if not nd or nd.step ~= d.step or nd.descriptors_by_type.subrace ~= d.descriptors_by_type.subrace or nd.descriptors_by_type.subclass ~= d.descriptors_by_type.subclass or nd.c_name.text ~= d.c_name.text then T.log("BAD touch_reopen lost the choices") end
	if nd then game:replaceDialog(d, nd) d = nd T.wait(500) checkBounds("reopened") T.shot("birthp-3-reopened") end
	T.tap(btn(d.b_next)) T.wait(600)
	if d.step ~= 4 then T.log("BAD Next did not reach the difficulty step") end
	checkBounds("difficulty")
	T.shot("birthp-4-difficulty")
	T.tap(itemAt(1, 3)) T.wait(400)
	T.log("difficulty", tostring(d.descriptors_by_type.difficulty))
	T.tap(btn(d.b_next)) T.wait(600)
	T.log("ready", tostring(d.ready), "step", tostring(d.step))
	if d.step ~= 5 then T.log("BAD Next did not reach the start step") end
	checkBounds("start")
	T.shot("birthp-5-start")
	-- the step pills (portrait only): tap the second one
	if d.portrait or require("engine.TouchInput").portrait() then
		T.tap(pill(2)) T.wait(500)
		T.log("pill step", tostring(d.step))
		if d.step ~= 2 then T.log("BAD step pill tap did not go to the race step") end
		T.shot("birthp-pill-race")
	end
	T.log("finished")
end
