local woom = nil
local timeout = 7
local progress = 0
local reference = nil
local Current = util.Noop

local function Schedule(delay)
	if delay >= 0.2 then fx.epsilon = 0 end
	eapi.AddTimer(reference, delay, Current)
end

local function Straight(progress)
	return function()
		fx.Star(progress)
		Schedule(0.2)
	end
end

local function First()
	return Straight(0)
end

local function Right(body)
	return Straight(0.5)
end

local function Left(body)
	return Straight(-0.5)
end

local function Sine()
	local progress = 0
	return function()
		fx.Star(0.5 * math.sin(progress))
		progress = progress + 0.2
		Schedule(0.1)
	end
end

local function Alt2()
	local max = 5
	local pos = 0.25
	local count = max
	fx.Shower()
	return function()
		fx.Star(pos)
		count = count - 1
		if count == 0 then
			pos = -pos
			count = max
			Schedule(0.8)
		else
			Schedule(0.2)
		end
	end
end

local function HR3()
	local pos = 0.2
	return function()
		for i = -0.1, 0.1, 0.1 do fx.Star(pos + i) end
		Schedule(1.4)
		pos = -pos
	end
end

local function StopWoom()
	eapi.FadeSound(woom, 0.1)
end

local function FadeScreen()
	local fadeTime = 5
	local tile = actor.FillScreen(util.white, 1000, util.invisible)
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, util.Gray(1), fadeTime, 0)
	util.Delay(staticBody, fadeTime, util.Goto, "end")
	eapi.FadeMusic(fadeTime)
end

local function End()
	local boostTime = 0.5
	eapi.AddTimer(staticBody, timeout + boostTime, FadeScreen)
	util.Delay(staticBody, timeout, priss.Boost, boostTime)
	fx.Rayleigh(1.0, 2)
	fx.Sun()

	return util.Noop
end

local function Bam()
	local pos = 0.8
	local step = -0.1
	local maxInterval = 0.12
	local interval = maxInterval
	return function()
		fx.Star(pos)
		pos = pos + step
		if math.abs(pos) >= 0.8 then
			step = -step
			Schedule(0.3)
			interval = maxInterval
		else
			Schedule(interval)
			interval = interval * 0.98
		end
	end
end

local function Arcs()
	local width = 0.5
	local pos = -width
	local start = 0.001
	local step = start
	return function()
		fx.Star(pos)
		pos = pos + step
		if math.abs(step) < 0.1 then
			step = 2 * step
		end
		if math.abs(pos) >= width then
			pos = width * util.Sign(pos)
			step = -start * util.Sign(step)
			Schedule(0.5)
		else
			Schedule(0.1)
		end
	end
end

local function Fib()
	local pos = 0
	local count = 1
	local step = 0.05
	eapi.AddTimer(staticBody, 2, fx.Moon)
	return function()
		fx.Star(0.4 * (pos - 0.5) + count * step)
		if count > -1 then
			Schedule(0.05)
			count = count - 1
		else
			pos = (pos + util.golden) % 1
			Schedule(0.7)
			step = -step
			count = 1
		end
	end
end

local function SinAdd()
	local secondary = 0
	local progress = 0
	fx.Rayleigh(0.2)
	return function()
		fx.Star(0.5 * math.sin(progress) + 0.1 * math.sin(secondary))
		progress = progress + 0.1
		secondary = secondary + 0.5
		Schedule(0.1)
	end
end

local function SinMul()
	local secondary = 0
	local progress = 0
	fx.SlowShower()
	fx.Rayleigh(0.4)
	fx.DimSky(0.5, timeout)
	return function()
		local scale = 0.5 * (math.sin(secondary) + 1)
		fx.Star(0.2 * (0.2 + 0.8 * scale) * math.sin(progress))
		secondary = secondary + 0.12
		progress = progress + 0.36
		Schedule(0.1)
	end
end

local function Noise(x, y, z)
	return eapi.Fractal(x, 0, 0, 2, 1)
end

local function Perlin()
	local progress = 0
	fx.Rayleigh(0.6)
	fx.DimSky(0.25, timeout)
	return function()
		local val = 4 * (Noise(progress) - 0.25)
		fx.Star(math.max(-0.8, math.min(0.8, val)))
		progress = progress + 0.04
		Schedule(0.1)
	end
end

local list = {
	First,
	Right,
	Left,
	Alt2,
	Arcs,
	HR3,
	Fib,
	Bam,
	Sine,
	SinAdd,
	SinMul,
	Perlin,
	End,
}

local function Woom()
	if woom then eapi.FadeSound(woom, 0.1) end
	woom = eapi.PlaySound(gameWorld, "sound/woom.ogg", 0, 0.5)
end

local function Upscale(tile)
	local pos = eapi.GetPos(tile)
	local size = eapi.GetSize(tile)
	local dstPos = vector.Scale(pos, 2.5)
	local dstSize = vector.Scale(size, 2.5)
	eapi.SetPos(tile, vector.Scale(pos, 1.5))
	eapi.SetSize(tile, vector.Scale(size, 1.5))
	eapi.AnimatePos(tile, eapi.ANIM_CLAMP, dstPos, 0.25, 0)
	eapi.AnimateSize(tile, eapi.ANIM_CLAMP, dstSize, 0.25, 0)
end

local function ShowLevelsRemaining(ttl)
	local black = util.Gray(0)
	local num = "" .. (#list - progress)
	local pos = { x = -16 * #num, y = -32 }
	local body = eapi.NewBody(gameWorld, { x = 0, y = -90 })
	local tiles = util.Print(pos, num, black, -39, body, util.bigFontset)
	util.DelayedDestroy(body, ttl)
	util.Map(Upscale, tiles)
end

local function Flash()
	local ttl = 0.25
	eapi.PlaySound(gameWorld, "sound/pass.ogg")
	eapi.SetColor(state.lowTile, util.Gray(1.0))
	eapi.AnimateColor(state.lowTile, eapi.ANIM_CLAMP, util.Gray(0), ttl, 0)
	ShowLevelsRemaining(ttl)
end

local function Next(state)
	if reference then eapi.Destroy(reference) end
	reference = eapi.NewBody(gameWorld, vector.null)
	progress = progress + 1
	local Fn = list[progress]
	if Fn then
		Current = Fn()
		pattern.Reset()
		Schedule(0)
		fx.Sweep()
		Flash()
		Woom()
	end
end

local function Reset()
	if pattern.timer then eapi.CancelTimer(pattern.timer) end
	pattern.timer = eapi.AddTimer(staticBody, timeout, Next)
	Woom()
end

Noise(0)

pattern = {
	Next = Next,
	Reset = Reset,
}

