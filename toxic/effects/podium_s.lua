local g_Winners = {}
local DEBUG = true

local function onRaceStateChange(state)
	if(state == 'PostFinish') then
		RPC('PodiumStart', g_Winners):exec()
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
