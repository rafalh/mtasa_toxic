local LOC_COUNT = 6

local g_Winners = {}

local function onRaceStateChange(state)
	if(state == 'PostFinish') then
		RPC('PodiumStart', g_Winners, math.random(1, LOC_COUNT)):exec()
	elseif(state == 'LoadingMap') then
		RPC('PodiumStop'):exec()
		g_Winners = {}
	end
end

local function onPlayerFinish(rank)
	if(rank <= 3) then
		g_Winners[rank] = Player.fromEl(source):getName(true)
	end
end

addInitFunc(function()
	addEventHandler('onRaceStateChanging', root, onRaceStateChange)
	addEventHandler('onPlayerFinish', root, onPlayerFinish)
	addEventHandler('onPlayerFinishDD', root, onPlayerFinish)
end)
