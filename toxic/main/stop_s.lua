-- Note: this small file is out of other because it has to be the last one in meta.
-- Its onResourceStop handler is called as the lastest

local function onResourceStop()
	local prof = DbgPerf(50)
	
	-- Note: pairs uses next function which for unknown key starts from table beggining
	for el, player in pairs(g_Players) do
		player:destroy()
	end
	
	Settings.cleanup_done = true
	Debug.info('rafalh script has stopped!')
	
	prof:cp('stop')
end

local function onPlayerQuit()
	local player = Player.fromEl(source)
	player:destroy()
end

addInitFunc(function()
	addEventHandler('onResourceStop', g_ResRoot, onResourceStop)
	addEventHandler('onPlayerQuit', g_Root, onPlayerQuit)
end)
