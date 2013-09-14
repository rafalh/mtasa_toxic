-- Globals
local LOC_COUNT = 6
local g_Winners = {}

-- Events
addEvent('onRaceStateChanging')
addEvent('onPlayerFinish')
addEvent('onPlayerFinishDD')
addEvent('onPlayerWinDD')

local function onRaceStateChange(state)
	if(state == 'PostFinish') then
		if(#g_Winners > 0) then
			RPC('PodiumStart', g_Winners, math.random(1, LOC_COUNT)):exec()
		end
	elseif(state == 'LoadingMap') then
		RPC('PodiumStop'):exec()
		g_Winners = {}
	end
end

local function setWinner(playerEl, rank)
	-- Note: player can be nil if player just left the game
	local player = Player.fromEl(playerEl)
	
	local veh
	if(player) then
		local raceRes = getResourceFromName('race')
		if(raceRes and getResourceState(raceRes) == 'running') then
			veh = call(raceRes, 'getPlayerVehicle', player.el)
		end
		if(not veh) then
			veh = getPedOccupiedVehicle(player.el)
		end
	end
	
	local name = player and player:getName(true) or "Unknown"
	local vehModel = veh and getElementModel(veh) or 411 -- Infernus
	local pedModel = player and getElementModel(player.el) or 0 -- CJ
	g_Winners[rank] = {name, vehModel, pedModel}
end

local function onPlayerFinish(rank)
	if(rank <= 3) then
		setWinner(source, rank)
	end
end

local function onPlayerWinDD()
	setWinner(source, 1)
end

addInitFunc(function()
	addEventHandler('onRaceStateChanging', root, onRaceStateChange)
	addEventHandler('onPlayerFinish', root, onPlayerFinish)
	addEventHandler('onPlayerFinishDD', root, onPlayerFinish)
	addEventHandler('onPlayerWinDD', root, onPlayerWinDD)
end)
