-- Script by Deagle

addEvent("onMapStarting")

local function updateWaterLevel()
	setWaterLevel(0.01)
	setTimer(setWaterLevel, 50, 1, 0.01)
end

addEventHandler("onMapStarting", g_Root, updateWaterLevel)
addEventHandler("onClientResourceStart", g_ResRoot, updateWaterLevel)
