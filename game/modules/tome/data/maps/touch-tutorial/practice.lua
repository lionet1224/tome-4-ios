-- Touch practice level: a small forest clearing chain used by the iOS controls coach.
startx = 3
starty = 4

defineTile("&", "TREE", nil, nil, nil)
defineTile(",", "GRASS", nil, nil, nil)
defineTile("P", "GRASS", nil, nil, nil)
defineTile("M", "PRACTICE_MARK", nil, nil, nil)
defineTile("d", "GRASS", "PRACTICE_DAGGER", nil, nil)
defineTile("r", "GRASS", nil, "PRACTICE_RAT", nil)
defineTile("R", "GRASS", nil, "PRACTICE_ELITE_RAT", nil)
defineTile("s", "PRACTICE_SIGN", nil, nil, nil)
defineTile("E", "PRACTICE_EXIT", nil, nil, nil)

addSpot({8, 4}, "practice", "mark")
addSpot({3, 7}, "practice", "dagger")
addSpot({32, 16}, "practice", "sign")
addSpot({36, 17}, "practice", "exit")

return [[
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&,,,,,,,,&&,,,,,,,,&&,,,,,,,,&&&&&&&&&&
&&,,,,,,,,&&,,,,,,,,&&,,,,r,,,&&&&&&&&&&
&&,P,,,,M,,,,,,,,r,,&&,,,,,,,,&&&&&&&&&&
&&,,,,,,,,&&,,,,,,,,,,,,,,,,,,&&&&&&&&&&
&&,,,,,,,,&&,,,,,,,,&&,,,,,r,,&&&&&&&&&&
&&,d,,,,,,&&,,,,,,,,&&,,,,,,,,&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&,&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&,&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&,&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&,&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&,,,,,,,,,,,R,&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&,,,,,,,,&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&,,,,,,,,&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&,,,,,,,,&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&,,s,,,,,&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&,,,,,,E,&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&,,,,,,,,&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&]]
