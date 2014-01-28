local INVISIBLE_DIM = 65534

local g_CarHide = false
local g_KnownVehicles = {}
local g_SpecMode = nil -- unknown

local function ChUpdatePlayer(player)
	local veh = getPedOccupiedVehicle(player)
	local localVeh = getPedOccupiedVehicle(localPlayer)
	local dim = 0
	local cols = (isElement(veh) and getElementData(veh, 'race.collideothers') or 0) ~= 0
	
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
	local players = getElementsByType('player')
	for i, player in ipairs(players) do
		--if(player ~= localPlayer) then
			ChUpdatePlayer(player)
		--end
	end
end

local function ChVehDataChange(dataName)
	if(dataName ~= 'race.collideothers') then return end
	local player = getVehicleOccupant(source)
	if(player) then
		ChUpdatePlayer(player)
	end
end

local function ChVehDestroy()
	g_KnownVehicles[source] = nil
end

local function ChVehEnter(player)
	if(g_KnownVehicles[source] or getElementType(player) ~= 'player') then return end
	
	g_KnownVehicles[source] = true
	addEventHandler('onClientElementDataChange', source, ChVehDataChange, false)
	addEventHandler('onClientElementDestroy', source, ChVehDestroy, false)
	
	ChUpdatePlayer(player)
end

local function ChEnable()
	if(g_CarHide) then return end
	g_CarHide = true
	--outputDebugString('CarHide enabled', 3)
	
	addEventHandler('onClientVehicleEnter', root, ChVehEnter)
	for i, player in ipairs(getElementsByType('player')) do
		local veh = getPedOccupiedVehicle(player)
		if(veh) then
			g_KnownVehicles[veh] = true
			addEventHandler('onClientElementDataChange', veh, ChVehDataChange, false)
			addEventHandler('onClientElementDestroy', veh, ChVehDestroy, false)
		end
	end
	ChUpdateAllPlayers()
end

local function ChDisable()
	if(not g_CarHide) then return end
	g_CarHide = false
	--outputDebugString('CarHide disabled', 3)
	
	ChUpdateAllPlayers()
	
	removeEventHandler('onClientVehicleEnter', root, ChVehEnter)
	for veh, v in pairs(g_KnownVehicles) do
		removeEventHandler('onClientElementDataChange', veh, ChVehDataChange)
		removeEventHandler('onClientElementDestroy', veh, ChVehDestroy)
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
		outputMsg(Styles.green, "Car Hide has been enabled")
	else
		outputMsg(Styles.red, "Car Hide has been disabled")
	end
end

local function ChPulse()
	local target = getCameraTarget()
	local localVeh = getPedOccupiedVehicle(localPlayer)
	
	-- If there is no target check if camera direction points to local vehicle (for example in TRIALS maps)
	if(not target and localVeh) then
		local cx, cy, cz, tx, ty, tz = getCameraMatrix()
		local camPos = Vector3(cx, cy, cz)
		local camDir = Vector3(tx - cx, ty - cy, tz - cz)
		local vehPos = Vector3(getElementPosition(localVeh))
		if(vehPos:distFromSeg(camPos, camPos + 100*camDir) < 0.1) then
			target = localVeh
			--outputDebugString('TRIALS camera!', 3)
		end
	end
	
	-- If spectator mode has been enabled/disabled update all players
	local specMode = (target ~= localPlayer and target ~= localVeh)
	if(specMode ~= g_SpecMode) then
		g_SpecMode = specMode
		ChUpdateAllPlayers()
	end
end

local function ChInit()
	ChPulse()
	setTimer(ChPulse, 1000, 0)
	
	addCommandHandler('carhide', ChToggle, false)
	local key = getKeyBoundToCommand('carhide') or 'O'
	bindKey(key, 'down', 'carhide')
end

addEventHandler('onClientResourceStart', resourceRoot, ChInit)

Settings.register
{
	name = 'carHide',
	default = false,
	cast = tobool,
	onChange = function(oldVal, newVal)
		ChSetEnabled(newVal)
	end,
	createGui = function(wnd, x, y, w, onChange)
		local cb = guiCreateCheckBox(x, y, w, 20, "Hide other cars when GM is enabled", Settings.carHide, false, wnd)
		if(onChange) then
			addEventHandler('onClientGUIClick', cb, onChange, false)
		end
		return 20, cb
	end,
	acceptGui = function(cb)
		Settings.carHide = guiCheckBoxGetSelected(cb)
	end,
}
