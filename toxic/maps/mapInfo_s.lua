local g_MapInfo = false
local g_Tops = {}

local function MiGetInfo(map)
	local rows = DbQuery('SELECT played, rates, rates_count FROM '..MapsTable..' WHERE map=? LIMIT 1', map:getId())
	local info = rows and rows[1]
	info.name = map:getName()
	info.rating = (info.rates_count > 0 and info.rates/info.rates_count) or 0
	info.author = map:getInfo('author')
	return info
end

function MiSendMapInfo(playerOrRoom)
	local room = playerOrRoom.cls == Player and playerOrRoom.room or playerOrRoom
	
	local prof = DbgPerf()
	local map = getCurrentMap(room)
	if(not map) then return end
	
	if(not g_Tops) then
		g_Tops = BtGetTops(map)
	end
	
	if(not g_MapInfo) then
		g_MapInfo = MiGetInfo(map)
	end
	
	local players = getElementsByType('player', playerOrRoom.el)
	
	BtUpdatePlayerTops(g_PlayerTimes, map, players)
	
	prof2:cp('retreiving toptimes')
	
	for i, player in ipairs(players) do
		RPC('MiSetMapInfo', g_MapInfo, g_Tops, g_PlayerTimes[player]):setClient(player):exec()
		
		if(show) then
			RPC('MiShow'):setClient(player):exec()
		end
	end
	prof:cp('MiSendMapInfo')
end

function MiShow(playerOrRoom)
	local players = getElementsByType('player', playerOrRoom.el)
	for i, player in ipairs(players) do
		RPC('MiShow'):setClient(player):exec()
	end
end

function MiUpdateInfo()
	g_MapInfo = false
	MiSendMapInfo(g_RootRoom)
end

function MiUpdateTops(map_id)
	--[[for el, room in Room.pairs() do
		local map = getCurrentMap(room)
		if(map and map:getId() == map_id) then
			room.tops = false
			room.playerTimes = {}
		end
	end]]
	g_Tops = false
	g_PlayerTimes = {}
	MiSendMapInfo(g_RootRoom)
end

function MiDeleteCache()
	g_MapInfo = false
	g_Tops = false
	g_PlayerTimes = {}
end

addInitFunc(function()
	addEventHandler('onGamemodeMapStop', g_Root, MiDeleteCache)
end)
