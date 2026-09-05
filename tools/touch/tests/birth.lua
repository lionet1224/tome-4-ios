return function(T)
	T.log("a") T.wait(1500)
	local names = {} for i, dd in ipairs(game.dialogs) do names[#names+1] = tostring(dd.title or dd.__CLASSNAME) end
	T.log("dialogs", #game.dialogs, table.concat(names, " | "), "current is top", tostring(engine.KeyBind.current == (game.dialogs[#game.dialogs] and game.dialogs[#game.dialogs].key)), "current is game", tostring(engine.KeyBind.current == game.key))
	T.key("EXIT") T.log("b") T.wait(6000) T.key("EXIT") T.log("c") T.wait(600)
	local TB = require "mod.dialogs.TouchBirther"
	T.log("d")
	local d = TB.new("test", game.player, {"base", "world", "difficulty", "permadeath", "race", "subrace", "sex", "class", "subclass"}, function() end)
	T.log("e")
	game:registerDialog(d)
	T.log("f")
	T.wait(800) T.shot("birth-1-who")
	local function itemAt(sec, i) local it = d.c_flow.sections[sec].items[i] return d.c_flow.last_screen_x + it.x + it.w / 2, d.c_flow.last_screen_y + it.y + it.h / 2 - d.c_flow.scrollbar.pos end
	local function btn(b) local u = d.ui_by_ui[b] return d.display_x + u.x + b.w / 2, d.display_y + u.y + b.h / 2 end
	T.tap(itemAt(2, 2)) T.wait(300) -- Male
	T.log("sex", tostring(d.descriptors_by_type.sex))
	T.tap(btn(d.b_next)) T.wait(600) T.shot("birth-2-race")
	T.log("step", tostring(d.step))
	T.tap(itemAt(1, 1)) T.wait(500) T.shot("birth-2-race-human")
	T.log("race parent", tostring(d.race_parent and d.race_parent.id))
	if #d.c_flow.sections >= 2 then T.tap(itemAt(2, 2)) T.wait(500) end
	T.log("subrace", tostring(d.descriptors_by_type.subrace))
	T.wait(1500) T.shot("birth-2-lineage")
	if #d.c_flow.sections >= 3 then T.tap(itemAt(3, 2)) T.wait(800) T.shot("birth-2-look") end
	T.tap(btn(d.b_next)) T.wait(600) T.shot("birth-3-class")
	T.tap(itemAt(1, 1)) T.wait(500)
	T.log("class parent", tostring(d.class_parent and d.class_parent.id))
	if #d.c_flow.sections >= 2 then T.tap(itemAt(2, 1)) T.wait(500) end
	T.log("subclass", tostring(d.descriptors_by_type.subclass))
	T.shot("birth-3-path")
	local x, y = itemAt(1, 1)
	T.swipe(x, y + 250, x, y, 400) T.wait(800) T.shot("birth-3-scrolled")
	T.log("flow scroll", tostring(d.c_flow.scrollbar.pos))
	T.tap(btn(d.b_next)) T.wait(600) T.shot("birth-4-difficulty")
	T.tap(itemAt(1, 3)) T.wait(400)
	T.log("difficulty", tostring(d.descriptors_by_type.difficulty))
	T.tap(btn(d.b_next)) T.wait(600) T.shot("birth-5-start")
	T.log("ready", tostring(d.ready), "step", tostring(d.step))
	T.tap(d.display_x + 100, d.display_y + 120) T.wait(500) T.shot("birth-rail-race")
	T.log("rail step", tostring(d.step))
	T.log("finished")
end
