local text = "Missed Stars: " .. state.miss
util.Center("The End", staticBody, util.bigFontset)
local quoteBody = eapi.NewBody(staticBody, { x = 0, y = -48 })
util.Center("Thank you for playing!", quoteBody)
input.Bind("Start", true, util.KeyDown(eapi.Quit))
util.PrintOrange({ x = -396, y = -240 }, text, nil, nil, 0.2)

local tile = actor.FillScreen(util.white, 1000, util.Gray(1.0))
eapi.AnimateColor(tile, eapi.ANIM_CLAMP, util.invisible, 1.0, 0)
