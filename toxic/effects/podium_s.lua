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

local function onPlayerFinish(rank)
	if(rank <= 3) then
		-- Note: player can be nil if player just left the game
		local player = Player.fromEl(source)
		g_Winners[rank] = player and player:getName(true) or 'Unknown'
	end
end

local function onPlayerWinDD()
	local player = Player.fromEl(source)
	g_Winners[1] = player and player:getName(true) or 'Unknown'
end

addInitFunc(function()
	addEventHandler('onRaceStateChanging', root, onRaceStateChange)
	addEventHandler('onPlayerFinish', root, onPlayerFinish)
	addEventHandler('onPlayerFinishDD', root, onPlayerFinish)
	addEventHandler('onPlayerWinDD', root, onPlayerWinDD)
end)
