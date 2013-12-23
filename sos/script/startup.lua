local transitionDuration = 2
local defaultAcceleration = { x = 0, y = -480 }

local titleParent = eapi.NewBody(gameWorld, vector.null)
local titleBody = eapi.NewBody(titleParent, vector.null)
util.Center("Highway Star", titleBody, util.bigFontset)
local quoteBody = eapi.NewBody(titleBody, { x = 0, y = -48 })
util.Center("Oooh she's a killing machine!", quoteBody)

local function Jitter()
	local src = eapi.GetPos(titleBody)
	local dst = vector.Rnd(vector.null, 4)
	eapi.SetVel(titleBody, vector.Scale(vector.Sub(dst, src), 100))
	eapi.AddTimer(titleBody, 0.01, Jitter)
end

Jitter()

local horizon = eapi.NewBody(gameWorld, { x = 0, y = 240 })
local lightBlue = { r = 0.2, g = 0.4, b = 1.0 }
local darkBlue = { r = 0.02, g = 0.05, b = 0.2 }

local lowHorizon = eapi.NewBody(horizon, { x = 0, y = -240 })
state.lowTile = actor.FillScreen(util.white, -40, util.Gray(0.0), lowHorizon)

local transition = 1
local function Emit()
	local ttl = 1 + 0.5 * transition
	local size = { x = 800, y = 1 }
	local dstSize = { x = 800, y = 8 }
	local offset = { x = -400, y = -1 }
	local dstOffset = { x = -400, y = -4 }
	local body = eapi.NewBody(horizon, vector.null)
	local tile = eapi.NewTile(body, offset, size, util.white, -10)

	eapi.SetColor(tile, darkBlue)
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, lightBlue, ttl, 0)
	eapi.AnimateSize(tile, eapi.ANIM_CLAMP, dstSize, ttl, 0)
	eapi.AnimatePos(tile, eapi.ANIM_CLAMP, dstOffset, ttl, 0)
	eapi.SetAcc(body, defaultAcceleration)
	eapi.AddTimer(staticBody, 0.1, Emit)
	util.DelayedDestroy(body, ttl)
end

Emit()

local left = string.char(157)
local right = string.char(156)
local info = "Use " .. left .. " and " .. right .. " to move, ESC quits."

local infoBody = eapi.NewBody(titleBody, { x = 0, y = -228 })
util.Center(info, infoBody)

local counterTimer = nil
local function StartCounter()
	transition = transition - 0.01 / transitionDuration
	counterTimer = eapi.AddTimer(staticBody, 0.01, StartCounter)
end

local sideImg = eapi.ChopImage("image/side.png", { 256, 256 })

local sideSize = { x = 400, y = 240 }
local function MoveSide(from, to, flip)
	local dst = { x = to, y = -240 }
	local src = { x = from, y = -240 }
	local tile = eapi.NewTile(staticBody, src, sideSize, sideImg, -9)
	eapi.AnimatePos(tile, eapi.ANIM_CLAMP, dst, 1, 0)
	eapi.SetColor(tile, { r = 0.02, g = 0.01, b = 0.05, a = 0.9 })
	eapi.FlipX(tile, flip)
end

local function BikePass()
	eapi.PlaySound(gameWorld, "sound/pass.ogg")
end
eapi.AddTimer(staticBody, 1.0, BikePass)

local function MoveInSides()
	MoveSide(-800, -500, false)
	MoveSide(400, 100, true)
	eapi.AddTimer(staticBody, 1, priss.Create)
end

local function StopHorizon()
	eapi.SetPos(horizon, vector.null)
	eapi.SetVel(horizon, vector.null)
	eapi.SetAcc(horizon, vector.null)
	eapi.CancelTimer(counterTimer)
	transition = 0
	MoveInSides()
end

local function Reverse()
	eapi.SetAcc(horizon, { x = 0, y = 480 / transitionDuration })
end

local function DisplaceHorizon()
	eapi.SetAcc(horizon, { x = 0, y = -480 / transitionDuration })
	eapi.AddTimer(staticBody, 0.5 * transitionDuration, Reverse)
	eapi.AddTimer(staticBody, transitionDuration, StopHorizon)
	eapi.PlayMusic("sound/music.ogg", nil, 0.5)
	StartCounter()
	fx.StarSky()
end

local function BindAll(immediate, fn)
	input.Bind("Left", immediate, fn)
	input.Bind("Right", immediate, fn)
	input.Bind("Start", immediate, fn)
end

local function GoGoGo()
	eapi.SetAcc(titleParent, defaultAcceleration)
	util.DelayedDestroy(titleParent, 1.5)
	eapi.CancelTimer(jitterTimer)
	DisplaceHorizon()
	BindAll()
end

BindAll(true, util.KeyDown(GoGoGo))

local splash = eapi.NewBody(gameWorld, vector.null)
local splashTile = actor.FillScreen(util.white, 1000, util.Gray(0), splash)
for i = -400, 400, 50 do
	local size = { x = 1, y = 480 }
	local dstSize = { x = 8, y = 480 }
	local offset = { x = i, y = -240 }
	local tile = eapi.NewTile(splash, offset, size, util.white, 1001)
	eapi.SetColor(tile, darkBlue)
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, lightBlue, 1.5, 0)
	eapi.AnimateSize(tile, eapi.ANIM_CLAMP, dstSize, 1.5, 0)
end
util.PrintOrange({ x = -392, y = 220 }, "BRSD3", 1002, splash, 0.2)
eapi.SetAcc(splash, defaultAcceleration)
util.DelayedDestroy(splash, 1.5)
