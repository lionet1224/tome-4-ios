-- Touch death screen, preview mode (no side effects: no life used, no save).
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local DD = require "mod.dialogs.DeathDialog"
	local d = DD.new(game.player, {preview=true})
	game:registerDialog(d)
	T.wait(800) T.shot("death-open")
	T.log("choices", #d.list)
	local function itemAt(sec, i) local it = d.c_flow.sections[sec].items[i] return d.c_flow.last_screen_x + it.x + it.w / 2, d.c_flow.last_screen_y + it.y + it.h / 2 - d.c_flow.scrollbar.pos end
	-- the last card is always "Exit to main menu"; in preview it only prints and closes
	T.tap(itemAt(1, #d.list)) T.wait(500)
	T.log("dialog still open", tostring(game:hasDialog(d)))
	T.shot("death-after")
	T.log("finished")
end
