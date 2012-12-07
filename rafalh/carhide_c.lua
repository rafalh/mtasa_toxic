local g_CarHide = false
local g_KnownVehicles = {}
local INVISIBLE_DIM = 65534
local g_SpecMode = nil -- unknown

local function ChUpdatePlayer(player)
	local veh = getPedOccupiedVehicle(player)
	local localVeh = getPedOccupiedVehicle(localPlayer)
	local dim = 0
	local cols = (isElement(veh) and getElementData(veh, "race.collideothers") or 0) ~= 0
	
	if(g_CarHide and player ~= localPlayer and not cols and not g_SpecMode) then
		dim = INVISIBLE_DIM
	end
	
	if(getElementDimension(player) == dim) then return end
	
	setElementDimension(player, dim)
	if(veh) then
		setElementDimension(veh, dim)
	end
end

local function ChUpdateAllPlayers()
	local players = getElementsByType("player")
	for i, player in ipairs(players) do
		--if(player ~= localPlayer) then
			ChUpdatePlayer(player)
		--end
	end
end

local function ChVehDataChange(dataName)
	if(dataName ~= "race.collideothers") then return end
	local player = getVehicleOccupant(source)
	if(player) then
		ChUpdatePlayer(player)
	end
end

local function ChVehDestroy()
	g_KnownVehicles[source] = nil
end

local function ChVehEnter(player)
	if(g_KnownVehicles[source]) then return end
	
	g_KnownVehicles[source] = true
	addEventHandler("onClientElementDataChange", source, ChVehDataChange)
	addEventHandler("onClientElementDestroy", source, ChVehDestroy)
	
	ChUpdatePlayer(player)
end

local function ChEnable()
	if(g_CarHide) then return end
	g_CarHide = true
	
	addEventHandler("onClientVehicleEnter", root, ChVehEnter)
	for i, player in ipairs(getElementsByType("player")) do
		local veh = getPedOccupiedVehicle(player)
		if(veh) then
			g_KnownVehicles[veh] = true
			addEventHandler("onClientElementDataChange", veh, ChVehDataChange)
			addEventHandler("onClientElementDestroy", veh, ChVehDestroy)
		end
	end
	ChUpdateAllPlayers()
end

local function ChDisable()
	if(not g_CarHide) then return end
	g_CarHide = false
	
	ChUpdateAllPlayers()
	
	removeEventHandler("onClientVehicleEnter", root, ChVehEnter)
	for veh, v in pairs(g_KnownVehicles) do
		removeEventHandler("onClientElementDataChange", veh, ChVehDataChange)
		removeEventHandler("onClientElementDestroy", veh, ChVehDestroy)
	end
	g_KnownVehicles = {}
end

function ChSetEnabled(enabled)
	if(enabled) then
		ChEnable()
	else
		ChDisable()
	end
end

local function ChToggle()
	ChSetEnabled(not g_CarHide)
	if(g_CarHide) then
		outputChatBox("Car Hide is enabled", 0, 255, 0)
	else
		outputChatBox("Car Hide is disabled", 255, 0, 0)
	end
end

local function ChPulse()
	local target = getCameraTarget()
	local localVeh = getPedOccupiedVehicle(localPlayer)
	local specMode = (target ~= localPlayer and target ~= localVeh)
	if(specMode ~= g_SpecMode) then
		g_SpecMode = specMode
		ChUpdateAllPlayers()
	end
end

local function ChInit()
	ChPulse()
	setTimer(ChPulse, 1000, 0)
end

addCommandHandler("carhide", ChToggle, false)
addEventHandler("onClientResourceStart", resourceRoot, ChInit)

addEvent("rafalh_onCarHideReq", true)
addEventHandler("rafalh_onCarHideReq", localPlayer, ChSetEnabled)
