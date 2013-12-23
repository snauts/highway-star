local damping = 0.75

local rayImg = actor.LoadSprite("image/ray.png", { 256, 256 })
local starImg = actor.LoadSprite("image/star.png", { 64, 64 })
local twinkleImg = actor.LoadSprite("image/twinkle.png", { 64, 64 })

local bb = { l = -600, r = 600, b = -280, t = -240 }
eapi.NewShape(staticBody, nil, bb, "Ground")

local function SparkVsGround(spark)
	spark = actor.store[spark]
	local vel = eapi.GetVel(spark.body)
	vel.y = damping * math.abs(vel.y)
	eapi.SetVel(spark.body, vel)
end

actor.SimpleCollide("Spark", "Ground", SparkVsGround, nil, true)

local function FadeOut(obj, color, ttl)
	color = util.SetColorAlpha(util.CopyTable(color), 0)
	eapi.AnimateColor(obj.tile, eapi.ANIM_CLAMP, color, ttl)
end

local function Spark(pos, vel, color, ttl, scale)
	ttl = ttl or 2
	scale = scale or 1
	local obj = {
		z = 20,
		pos = pos,
		velocity = vel,
		class = "Spark",
		sprite = twinkleImg,
		bb = actor.Square(2),
		offset = vector.Scale({ x = -8, y = -8 }, scale),
		spriteSize = vector.Scale({ x = 16, y = 16 }, scale),
	}
	obj = actor.Create(obj)
	eapi.SetAcc(obj.body, { x = 0, y = -500 })
	util.AnimateRotation(obj.tile, -0.5 * util.Sign(vel.x))
	eapi.SetColor(obj.tile, color)
	actor.DelayedDelete(obj, ttl)
	FadeOut(obj, color, ttl)
end

local srcPos = { x = -0.5, y = -0.5 }
local srcSize = { x = 1, y = 1 }
local dstPos = { x = -32, y = -32 }
local dstSize = { x = 64, y = 64 }

local function SparkColor()
	return { r = 1.0, g = 1.0 - 0.5 * math.random(), b = 0.0 }
end

local function ColorRay(tile, ttl)
	local color = SparkColor()
	eapi.SetColor(tile, color)
	color = util.SetColorAlpha(color, 0)
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, color, ttl, 0)
end

local ray1Pos = { x = -32, y = 0 }
local ray1Size = { x = 64, y = 2 }

local ray2Pos = { x = -64, y = -128 }
local ray2Size = { x = 128, y = 1024 }

local function Ray(pos)
	local ttl = 0.5
	local body = eapi.NewBody(gameWorld, pos)
	local tile = eapi.NewTile(body, ray1Pos, ray1Size, rayImg, 25)
	eapi.AnimateSize(tile, eapi.ANIM_CLAMP, ray2Size, ttl, 0)
	eapi.AnimatePos(tile, eapi.ANIM_CLAMP, ray2Pos, ttl, 0)
	util.PlaySound(gameWorld, "sound/miss.ogg", 0.05)
	util.DelayedDestroy(body, ttl)
	ColorRay(tile, ttl)
end

local function Miss(obj)
	state.miss = state.miss + 1
	Ray(actor.GetPos(obj))
	actor.Delete(obj)
	pattern.Reset()
end

local function Star(state)
	local ttl = 2.1
	local obj = {
		class = "Star",
		sprite = starImg,
		z = 19 - fx.epsilon,
		bb = actor.Square(16),
		pos = { x = state * 100, y = 0 },
		spriteSize = srcSize,
		offset = srcPos,
	}
	obj = actor.Create(obj)
	local time = eapi.GetTime(gameWorld)
	eapi.SetAcc(obj.body, { x = state * 200, y = -120 })
	eapi.AnimatePos(obj.tile, eapi.ANIM_CLAMP, dstPos, ttl)
	eapi.AnimateSize(obj.tile, eapi.ANIM_CLAMP, dstSize, ttl)
	eapi.Animate(obj.tile, eapi.ANIM_LOOP, 32, -1.5 * time % 1)
	obj.deathTimer = util.Delay(obj.body, ttl, Miss, obj)
	fx.epsilon = (fx.epsilon + 0.00001) % 1
end

local function StarSpark(pos, angle, scale)
	local vel = { x = math.random(50, 150), y = 0 }
	vel = vector.Rotate(vel, angle + math.random(-30, 30))
	fx.Spark(vector.Rnd(pos, 16), vel, SparkColor(), 1, scale)
end

local function PickUpStar(star)
	local pos = eapi.GetPos(star.body)
	local angle = vector.Angle(eapi.GetVel(star.body))
	eapi.PlaySound(gameWorld, "sound/pickup.ogg", 0, 0.5)
	actor.Delete(star)
	for i = 1, 3, 1 do
		StarSpark(pos, angle + 90)
		StarSpark(pos, angle - 90)
	end
end

local function GetStar(star, obj)
	obj = actor.store[obj]
	star = actor.store[star]
	actor.DeleteShape(star)
	eapi.CancelTimer(star.deathTimer)
	eapi.SetAcc(star.body, vector.null)

	local pos1 = actor.GetPos(obj)
	local pos2 = actor.GetPos(star)
	local vel = vector.Sub(pos1, pos2)
	eapi.SetVel(star.body, vector.Scale(vel, 20))
	util.Delay(star.body, 0.05, PickUpStar, star)
end

actor.SimpleCollide("Star", "Priss", GetStar, nil, true)

local function AllStars()
	local starList = { }
	local function Collect(obj)
		if obj.class == "Star" then
			starList[obj] = obj
		end
	end
	util.Map(Collect, actor.store)
	return starList
end

local function RemoveStar(obj)
	local pos = eapi.GetPos(obj.body)
	local scale = 0.2 + 1.0 * math.sqrt(math.abs(pos.y) / 240)
	StarSpark(pos, 210, scale)
	StarSpark(pos, -30, scale)
	actor.Delete(obj)
end

local function Sweep(star)
	util.Map(RemoveStar, AllStars())
end

local height = 240

local nightImg = eapi.ChopImage("image/night-sky.png", { 800, height })

local function StarSky()
	local speed = 10.0
	state.starSkyTiles = { }
	local body = eapi.NewBody(gameWorld, { x = 0, y = height })
	eapi.SetVel(body, { x = 0, y = height / speed })

	for i = -height, 0, height do
		local offset = { x = -400, y = i }
		local tile = eapi.NewTile(body, offset, nil, nightImg, -50)
		state.starSkyTiles[tile] = tile
	end

	local function Back()
		local pos = eapi.GetPos(body)
		eapi.SetPos(body, { x = 0, y = pos.y - height })
		eapi.AddTimer(body, speed, Back)
	end
	Back()
end

local function DimTile(tile, amount, time)
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, util.Gray(amount), time, 0)
end

local function DimSky(amount, time)
	local function Dim(tile) DimTile(tile, amount, time) end
	util.Map(Dim, state.starSkyTiles)
end

local blockImg = actor.LoadSprite("image/block.png", { 128, 128 })

local dstPos = { x = -40, y = -30 }
local dstSize = { x = 80, y = 100 }

local srcPos = vector.Scale(dstPos, 0.01)
local srcSize = vector.Scale(dstSize, 0.01)

local srcColor = { r = 0.1, g = 0.0, b = 0.1 }
local dstColor = { r = 0.2, g = 0.0, b = 0.5 }

local function EmitRoadSideBlock(dir)
	local ttl = 1
	local body = eapi.NewBody(gameWorld, { x = dir * 100, y = 0 })
	local tile = eapi.NewTile(body, srcPos, srcSize, blockImg, -8)
	eapi.SetAcc(body, { x = dir * 800, y = -480 })

	eapi.SetColor(tile, srcColor)
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, dstColor, ttl, 0)
	eapi.AnimateSize(tile, eapi.ANIM_CLAMP, dstSize, ttl, 0)
	eapi.AnimatePos(tile, eapi.ANIM_CLAMP, dstPos, ttl, 0)
	util.DelayedDestroy(body, ttl)
	eapi.FlipX(tile, dir < 0)
end

local function Blocks()
	EmitRoadSideBlock(1)
	EmitRoadSideBlock(-1)
	eapi.AddTimer(staticBody, 0.1, Blocks)
end

local srcPos = { x = -0.5, y = 0 }
local srcSize = { x = 1, y = 20 }

local dstPos = { x = -2, y = 0 }
local dstSize = { x = 4, y = 200 }

local meteorImg = actor.LoadSprite("image/meteor.png", { 16, 32 })

local showerTimeout = 0.1
local showerModifier = 1.0
local function Shower()
	local ttl = 0.6
	local maxAngle = 85
	local pos = 2 * math.random() - 1
	local body = eapi.NewBody(gameWorld, { x = pos * 200, y = 240 })
	local tile = eapi.NewTile(body, srcPos, srcSize, meteorImg, -48)

	util.RotateTile(tile, maxAngle * pos)
	eapi.SetVel(body, vector.Rotate({ x = 0, y = -1000 }, maxAngle * pos))

	eapi.AnimateSize(tile, eapi.ANIM_CLAMP, dstSize, ttl, 0)
	eapi.AnimatePos(tile, eapi.ANIM_CLAMP, dstPos, ttl, 0)

	eapi.AddTimer(staticBody, showerTimeout, Shower)
	showerTimeout = showerTimeout * showerModifier
	util.DelayedDestroy(body, ttl)
end

local function SlowShower()
	showerModifier = 1.1
end

local sunImg = actor.LoadSprite("image/sun.png", { 256, 256 })

local function Circle(body, radius, z, color)
	local size = { x = radius, y = radius }
	local offset = vector.Scale(size, -0.5)
	local tile = eapi.NewTile(body, offset, size, sunImg, z)
	eapi.SetColor(tile, color)
	return tile
end

local function Moon()
	local speed = 30
	local body = eapi.NewBody(gameWorld, { x = 0, y = -120 })
	Circle(body, 200, -49.2, { r = 0.20, g = 0.20, b = 0.4 })
	Circle(body, 180, -49.1, { r = 0.50, g = 0.50, b = 1.0 })
	Circle(body, 160, -49.0, { r = 0.95, g = 0.95, b = 1.0 })
	eapi.SetVel(body, { x = 0, y = speed })
	util.DelayedDestroy(body, 480 / speed)
end

local rayleighImg = eapi.ChopImage("image/rayleigh.png", { 800, 240 })

local function CreateRayleigh()
	local pos = { x = -400, y = 0 }
	state.rayleigh = eapi.NewTile(staticBody, pos, nil, rayleighImg, -47)
	eapi.SetColor(state.rayleigh, { r = 0.0, g = 0.0, b = 0.0, a = 0.0 })
end

local function Rayleigh(x, time)
	time = time or 7
	local darkSky = { r = x, g = x, b = x, a = x }
	if not state.rayleigh then CreateRayleigh() end
	eapi.AnimateColor(state.rayleigh, eapi.ANIM_CLAMP, darkSky, time, 0)
end

local function Sun()
	local body = eapi.NewBody(gameWorld, { x = 0, y = -240 })
	Circle(body, 480, -46.2, { r = 1.0, g = 0.3, b = 0.0 })
	Circle(body, 440, -46.1, { r = 1.0, g = 1.0, b = 0.2 })
	Circle(body, 400, -46.0, { r = 1.0, g = 1.0, b = 0.95 })
	eapi.SetVel(body, { x = 0, y = 30 })
end

fx = {
	Sun = Sun,
	Star = Star,
	Moon = Moon,
	Spark = Spark,
	Sweep = Sweep,
	Shower = Shower,
	Blocks = Blocks,
	DimSky = DimSky,
	StarSky = StarSky,
	Rayleigh = Rayleigh,
	SlowShower = SlowShower,
	epsilon = 0,
}
