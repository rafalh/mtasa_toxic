-- Note: this small file is out of other because it has to be the last one in meta.
-- Its onResourceStop handler is called as the lastest

local function onResourceStop ()
	-- Note: pairs uses next function which for unknown key starts from table beggining
	for el, player in pairs ( g_Players ) do
		player:destroy()
	end
	
	SmSet ( "cleanup_done", true )
	outputDebugString ( "rafalh script has stopped!", 3 )
end

local function onPlayerQuit ()
	local player = g_Players[source]
	player:destroy()
end

addEventHandler ( "onResourceStop", g_ResRoot, onResourceStop )
addEventHandler ( "onPlayerQuit", g_Root, onPlayerQuit )
