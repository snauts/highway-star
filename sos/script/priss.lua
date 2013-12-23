local bendTime = 0.4
local bikeSpeed = 400
local maxAngle = math.pi / 12
local steerAcc = bikeSpeed / bendTime

local function StopChild(obj)
	eapi.SetVel(obj.body, vector.null)
end

local function BendChild(obj, dir)
	eapi.SetVel(obj.body, { x = 0, y = dir * maxAngle / bendTime })
end

local function ChildLeft(obj)
	BendChild(obj, 1)
end

local function ChildRight(obj)
	BendChild(obj, -1)
end

local function GetChildBender(dir)
	return (dir > 0) and ChildRight or ChildLeft
end

local function Stop()
	eapi.SetAcc(priss.obj.body, vector.null)
	util.Map(StopChild, priss.obj.children)
	priss.obj.accAmount = 0
end

local function Dir(predicate)
	return predicate and 1 or -1
end

local down = 0
local function KeyDown(keyDir)
	down = down + keyDir
	return down ~= 0
end

local function AnimateAngle(tile, angle, time)
	eapi.AnimateAngle(tile, eapi.ANIM_CLAMP, vector.null, angle, time, 0)
end

local function CancelPrissTimer(obj)
	if obj.timer then
		eapi.CancelTimer(obj.timer)
		obj.timer = nil
	end
end

local function Move(somedown, dir)
	local obj = priss.obj
	local vel = eapi.GetVel(obj.body)
	local target = somedown and dir or 0
	local state = vel.x / bikeSpeed
	local diff = target - state
	local time = bendTime * math.abs(diff)

	CancelPrissTimer(obj)

	local steerDir = util.Sign(diff)
	obj.accAmount = steerAcc * steerDir
	util.Map(GetChildBender(steerDir), obj.children)

	eapi.SetAcc(obj.body, { x = obj.accAmount, y = 0 })
	obj.timer = eapi.AddTimer(obj.body, time, Stop)

	AnimateAngle(obj.tile, -target * maxAngle, time)
	obj.direction = dir
end

local function Wall(from, to)
	return { l = from, r = to, b = -240, t = -160 }
end

eapi.NewShape(staticBody, nil, Wall(400, 440), "Wall")
eapi.NewShape(staticBody, nil, Wall(-440, -400), "Wall")

local function RotateChild(angle)
	return function(obj)
		local base = { x = 0, y = obj.yOffset }
		eapi.SetPos(obj.body, vector.Rotate(base, angle))
	end
end

local function SparkColor()
	return { r = 0.2 + 0.2 * math.random(), g = 0.0, b = 0.7 }
end

local function EmitSparks(priss, status)
	local amount = math.abs(status) * bendTime
	for i = 1, 1 + math.floor(20 * amount), 1 do
		local pos = eapi.GetPos(priss.body, gameWorld)
		local vel = { x = -status, y = 0.5 * amount }
		vel = vector.Rotate(vel, math.random(-15, 15))
		vel = vector.Scale(vel, 50 + 150 * math.random())
		fx.Spark(vector.Rnd(pos, 16), vel, SparkColor())
	end
end

local function RunIntoWall(child)
	local obj = priss.obj
	local pos = eapi.GetPos(obj.body)
	local vel = eapi.GetVel(obj.body)
	local velDir = util.Sign(vel.x)
	local status = 0.5 * vel.x / bikeSpeed
	status = status + velDir * 0.5
	EmitSparks(actor.store[child], status)
	eapi.PlaySound(gameWorld, "sound/crash.ogg", 0, 0.5)
	if util.Sign(pos.x) == velDir then
		local angle = status * maxAngle
		local speed = -status * bikeSpeed
		eapi.SetVel(obj.body, { x = speed, y = 0 })
		util.Map(RotateChild(vector.Degrees(angle)), obj.children)
		eapi.SetAngle(obj.tile, angle)
		Move(down ~= 0, obj.direction)
	end
end

actor.SimpleCollide("Priss", "Wall", RunIntoWall, nil, true)

local function MoveKey(keyDir, dir)
	Move(KeyDown(keyDir), dir * keyDir)
end

local function Left(keydown)
	MoveKey(Dir(keydown), -1)
end

local function Right(keydown)
	MoveKey(Dir(keydown), 1)
end

local function EnableInput()
	Stop()
	pattern.Next()
	input.Bind("Left", true, Left)
	input.Bind("Right", true, Right)
end

local function AddSubBody(obj, w, h, yOffset)
	local child = {
		pos = vector.Offset(actor.GetPos(obj), 0,yOffset),
		bb = { l = -w, r = w, b = -h, t = h },
		yOffset = yOffset,
		class = "Priss",
	}
	child = actor.Create(child)
	actor.Link(child, obj)
	eapi.SetStepC(child.body, eapi.STEPFUNC_ROT, 0)
end

local bikeImg = actor.LoadSprite("image/bike.png", { 32, 64 })

local function Create()
	local obj = {
		z = 10,
		direction = 0,
		sprite = bikeImg,
		pos = { x = 0, y = -240 - 64 },
		offset = { x = -16, y = 0 },
		spriteSize = { x = 32, y = 64 },
	}
	obj = actor.Create(obj)
	eapi.SetVel(obj.body, { x = 0, y = 144 })
	eapi.SetAcc(obj.body, { x = 0, y = -144 })
	eapi.Animate(obj.tile, eapi.ANIM_LOOP, 64, 0)
	eapi.AddTimer(obj.body, 1, EnableInput)
	AddSubBody(obj, 8, 8, 16)
	AddSubBody(obj, 12, 8, 32)
	AddSubBody(obj, 8, 8, 48)
	AddSubBody(obj, 4, 4, 60)
	priss.obj = obj
	fx.Blocks()
end

local smallSize = { x = 4, y = 8 }
local smallPos = { x = -2, y = -4 }

local function HidePriss()
	local obj = priss.obj
	eapi.SetVel(obj.body, vector.null)
	eapi.SetColor(obj.tile, util.invisible)
end

local function Boost(ttl)
	input.Bind("Left")
	input.Bind("Right")
	local obj = priss.obj
	CancelPrissTimer(obj)
	local pos = actor.GetPos(obj)
	eapi.AnimatePos(obj.tile, eapi.ANIM_CLAMP, smallPos, ttl, 0)
	eapi.AnimateSize(obj.tile, eapi.ANIM_CLAMP, smallSize, ttl, 0)
	eapi.AnimateAngle(obj.tile, eapi.ANIM_CLAMP, vector.null, 0, ttl, 0)
	eapi.PlaySound(gameWorld, "sound/pass.ogg")
	eapi.SetVel(obj.body, vector.Scale(pos, -1 / ttl))
	eapi.AddTimer(obj.body, ttl, HidePriss)
	eapi.SetAcc(obj.body, vector.null)
end

priss = {
	Create = Create,
	Boost = Boost,
}
