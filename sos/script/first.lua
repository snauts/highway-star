dofile("config.lua")
dofile("script/util.lua")
dofile("script/vector.lua")

camera     = nil
gameWorld  = nil
staticBody = nil

state = { miss = 0 }
if util.FileExists("saavgaam") then 
	dofile("saavgaam")
end

util.Preload()
util.Goto("init")
