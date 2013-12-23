local store = { }

local function Square(x)
	return { b = -x, t = x, l = -x, r = x }
end

local function GetPos(actor, relativeTo)
	return eapi.GetPos(actor.body, relativeTo or gameWorld)
end

local function MakeTile(obj)
	local offset = obj.offset
	local size = obj.spriteSize
	obj.tile = eapi.NewTile(obj.body, offset, size, obj.sprite, obj.z)
	return obj.tile
end

local function MakeShape(obj, bb)
	local shape = eapi.NewShape(obj.body, nil, bb or obj.bb, obj.class)
	obj.shape[shape] = shape
	store[shape] = obj
	return shape
end

local function Create(actor)
	actor.shape = { }
	actor.blinkIndex = 0
	local parent = actor.parentBody or gameWorld
	actor.body = eapi.NewBody(parent, actor.pos)
	actor.blinkTime = eapi.GetTime(actor.body)
	if actor.bb and actor.class then
		MakeShape(actor)
	end
	if actor.sprite then
		MakeTile(actor)
	end
	if actor.velocity then
		eapi.SetVel(actor.body, actor.velocity)
	end
	return actor	
end


local function DeleteShapeObject(shape)
	eapi.Destroy(shape)
	store[shape] = nil
end

local function DeleteShape(actor)
	util.Map(DeleteShapeObject, actor.shape)
	actor.shape = { }
end

local function Delete(actor)
	if actor.destroyed then return end
	util.Map(Delete, actor.children)
	util.MaybeCall(actor.OnDelete, actor)
	DeleteShape(actor)
	eapi.Destroy(actor.body)
	actor.destroyed = true
end

local function Link(child, parent)
	if parent.children == nil then parent.children = { } end
	eapi.Link(child.body, parent.body)
	parent.children[child] = child
end

local function SimpleCollide(type1, type2, Func, priority, update)
	update = (update == nil) and true or update
	local function Callback(shape1, shape2, resolve)
		if not resolve then return end
		Func(shape1, shape2, resolve)
	end
	eapi.Collide(gameWorld, type1, type2, Callback, update, priority or 10)
end

local function DelayedDelete(obj, time)
	eapi.AddTimer(obj.body, time, function() Delete(obj) end)
end

local function BoxAtPos(pos, size)
	return { l = pos.x - size, r = pos.x + size,
		 b = pos.y - size, t = pos.y + size }		 
end

local function LoadMisc(frame)
	return eapi.NewSpriteList({ "image/misc.png", filter = true }, frame)
end

util.white = LoadMisc({ { 8, 8 }, { 16, 16 } })
util.gradient = LoadMisc({ { 40, 8 }, { 16, 16 } })

local function ESC(keyDown)
	if keyDown then
		eapi.Quit()
	end
end

input.Bind("Quit", false, ESC)

local function FillScreen(sprite, z, color, body)
	body = body or staticBody
	local size = actor.screenSize
	local offset = vector.Scale(size, -0.5)
	local tile = eapi.NewTile(body, offset, size, sprite, z)
	if color then eapi.SetColor(tile, color) end
	return tile
end

local function LoadSprite(fileName, size)
	return eapi.ChopImage({ fileName, filter = true }, size)
end

actor = {
	store = store,
	BoxAtPos = BoxAtPos,
	MakeShape = MakeShape,
	FillScreen = FillScreen,
	screenSize = { x = 800, y = 480 },
	SimpleCollide = SimpleCollide,
	DelayedDelete = DelayedDelete,
	DeleteShape = DeleteShape,
	LoadSprite = LoadSprite,
	MakeTile = MakeTile,
	Create = Create,
	Square = Square,
	Delete = Delete,
	GetPos = GetPos,
	Link = Link,
}
return actor
