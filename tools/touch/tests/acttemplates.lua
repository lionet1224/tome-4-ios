-- Class routine templates: every template names real talents and allowed kinds/conds,
-- the test character gets a routine of talents it knows, and reset replaces the active one.
return function(T)
	T.wait(1500) T.key("EXIT") T.wait(6000) T.key("EXIT") T.wait(600)
	local Actor = require "mod.class.Actor"
	local AT = require "mod.class.ActTemplates"
	local p = game.player
	local KINDS = {talent=true, bump=true, distance=true, swap=true, wait=true}
	local CONDS = {adjacent=true, not_adjacent=true, group=true, life=true, resource=true, target_life=true, no_enemies=true, pets_low=true}
	local TARGETS = {nearest=true, attacker=true, weakest=true, strongest=true, furthest=true, marked=true, best_aoe=true, manual=true, self=true}
	local n, bad = 0, 0
	for class, tpl in pairs(AT.TEMPLATES) do
		n = n + 1
		if type(tpl.steps) ~= "table" or #tpl.steps == 0 then T.log("BAD template " .. class .. " has no steps") bad = bad + 1 end
		for i, st in ipairs(tpl.steps or {}) do
			if not KINDS[st.kind] then T.log("BAD template " .. class .. " step " .. i .. " kind " .. tostring(st.kind)) bad = bad + 1 end
			if st.cond and not CONDS[st.cond] then T.log("BAD template " .. class .. " step " .. i .. " cond " .. tostring(st.cond)) bad = bad + 1 end
			if st.target and not TARGETS[st.target] then T.log("BAD template " .. class .. " step " .. i .. " target " .. tostring(st.target)) bad = bad + 1 end
			if st.kind == "talent" then
				if not st.tid then T.log("BAD template " .. class .. " step " .. i .. " has no tid") bad = bad + 1
				elseif not Actor.talents_def[st.tid] then T.log("BAD template " .. class .. " unknown talent " .. tostring(st.tid)) bad = bad + 1 end
			end
			if st.kind == "distance" and not (st.range and st.range >= 1) then T.log("BAD template " .. class .. " distance step without a range") bad = bad + 1 end
		end
	end
	-- every talent must come from the class's own trees (or a tree every class can learn, or one
	-- granted by an item or at birth): a wrong variant (T_STUNNING_BLOW vs T_STUNNING_BLOW_ASSAULT)
	-- silently collapses the routine to a bump
	local defs = require("engine.Birther").birth_descriptor_def
	local GENERIC = {["cunning/survival"]=true, ["technique/combat-training"]=true, ["technique/conditioning"]=true,
		["technique/combat-techniques-active"]=true, ["technique/combat-techniques-passive"]=true, ["technique/field-control"]=true, ["technique/mobility"]=true}
	local function granted(ty) return ty:find("/other$") or ty:find("%-other$") or ty:find("/objects$") or ty:find("%-base$") end
	for class, tpl in pairs(AT.TEMPLATES) do
		local sd = defs and defs.subclass and defs.subclass[class]
		local trees = sd and sd.talents_types
		if not trees and p.descriptor and p.descriptor.subclass == class then trees = p.descriptor.talents_types end
		if type(trees) == "function" then local ok, r = pcall(trees, nil) trees = ok and type(r) == "table" and r or nil end
		if not trees then T.log("note: no descriptor for", class)
		else
			for _, st in ipairs(tpl.steps or {}) do
				local def = st.kind == "talent" and Actor.talents_def[st.tid]
				local ty = def and def.type and def.type[1]
				if ty and not (trees[ty] ~= nil or GENERIC[ty] or granted(ty) or def.uber) then
					T.log("BAD template " .. class .. " " .. st.tid .. " not in the class trees (" .. ty .. ")") bad = bad + 1
				end
			end
		end
	end
	T.log("templates", n, "problems", bad)
	-- the test character
	local sub = p.descriptor and p.descriptor.subclass
	T.log("player subclass", tostring(sub), "template", tostring(AT.TEMPLATES[sub] ~= nil), "available", tostring(AT.available(p)))
	local r = AT.default(p)
	if not r then
		if AT.TEMPLATES[sub] then T.log("BAD default() returned nil for " .. tostring(sub)) end
	else
		T.log("default routine", r.name, "mode", r.mode, "steps", #r.steps)
		for i, st in ipairs(r.steps) do
			T.log(("  %d. %s %s%s%s"):format(i, st.kind, tostring(st.tid or ""), st.cond and (" when " .. st.cond .. (st.pct and (" " .. st.pct) or "")) or "", st.target and (" @" .. st.target) or ""))
			if st.kind == "talent" and not p:knowTalent(st.tid) then T.log("BAD default routine holds an unknown talent " .. tostring(st.tid)) end
		end
		if #r.steps == 0 then T.log("BAD default routine is empty") end
	end
	-- reset replaces the active routine
	local rs = p:actRoutines()
	local before = rs[p.act_active or 1]
	local ok = AT.reset(p)
	local after = p:actRoutines()[p.act_active or 1]
	T.log("reset", tostring(ok), "active now", tostring(after and after.name), "changed", tostring(after ~= before))
	if r and not ok then T.log("BAD reset returned false with a template available") end
	if ok and (after == before or after.name ~= r.name) then T.log("BAD reset did not install the class routine") end
	if ok and after.mode ~= r.mode then T.log("BAD reset lost the mode") end
	T.log("finished")
end
