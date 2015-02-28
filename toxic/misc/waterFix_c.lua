addEvent('onClientMapStarting')

local function updateWaterLevel()
	local x, y, z = getElementPosition(localPlayer)
	local lvl = getWaterLevel(x, y, z)
	if(lvl == 0) then
		setWaterLevel(0.001)
	end
end

local function onMapStart()
	setTimer(updateWaterLevel, 3000, 1)
end

addInitFunc(function()
	addEventHandler('onClientMapStarting', g_Root, onMapStart)
	addEventHandler('onClientResourceStart', g_ResRoot, updateWaterLevel)
end)
