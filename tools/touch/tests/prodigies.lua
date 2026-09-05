-- Touch prodigies screen: open, pick a card, read, scroll. Never learns anything.
-- Run via tools/touch/sim-run.sh tools/touch/tests/prodigies.lua <outdir>
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	game.player.unused_prodigies = 1
	local pending = {}
	local d = require("mod.dialogs.TouchProdigies").new(game.player, pending)
	game:registerDialog(d)
	T.wait(800) T.shot("prodigies-open")
	local function itemAt(sec, i)
		local it = d.c_flow.sections[sec].items[i]
		return d.c_flow.last_screen_x + it.x + it.w / 2, d.c_flow.last_screen_y + it.y + it.h / 2 - d.c_flow.scrollbar.pos
	end
	local n = 0
	for _, s in ipairs(d.c_flow.sections) do n = n + #s.items end
	T.log("sections", #d.c_flow.sections, "cards", n, "flow max", tostring(d.c_flow.scrollbar.max))
	T.tap(itemAt(1, 1)) T.wait(500)
	T.log("selected", tostring(d.cur and d.cur.talent), "kind", tostring(d.cur and d.cur.kind), "status", tostring(d.cur and d.cur.status))
	T.shot("prodigies-detail")
	local x, y = itemAt(1, 1)
	T.swipe(x, y + 300, x, y, 400) T.wait(800)
	T.log("flow scroll", tostring(d.c_flow.scrollbar.pos))
	T.shot("prodigies-scrolled")
	local chosen = 0
	for _, v in pairs(pending) do if v then chosen = chosen + 1 end end
	T.log("chosen", chosen, "points", tostring(game.player.unused_prodigies))
	T.key("EXIT") T.wait(300)
	T.log("closed", tostring(not game:hasDialog(d)))
	T.log("finished")
end
