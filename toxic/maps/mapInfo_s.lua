local g_MapInfo, g_Tops = false, false
local g_PlayerTops = {}

local function MiGetInfo(map)
	local rows = DbQuery('SELECT played, rates, rates_count FROM '..MapsTable..' WHERE map=? LIMIT 1', map:getId())
	local info = rows and rows[1]
	info.name = map:getName()
	info.rating = (info.rates_count > 0 and info.rates/info.rates_count) or 0
	info.author = map:getInfo('author')
	local mapType = map:getType()
	info.type = mapType and mapType.name
	return info
end

function MiSendMapInfo(playerOrRoom)
	local room = playerOrRoom.cls == Player and playerOrRoom.room or playerOrRoom
	
	local prof = DbgPerf()
	local map = getCurrentMap(room)
	if(not map) then return end
	
	if(not g_MapInfo) then
		g_MapInfo = MiGetInfo(map)
	end
	
	local players = getElementsByType('player', playerOrRoom.el)
	
	if(g_MapInfo.type == 'DD' and DdGetTops) then
		g_Tops = DdGetTops(map, 8)
		DdUpdatePlayerTops(g_PlayerTops, map, players)
	elseif(BtGetTops) then
		g_Tops = BtGetTops(map, 8)
		BtUpdatePlayerTops(g_PlayerTops, map, players)
	end
	
	for i, player in ipairs(players) do
		RPC('MiSetMapInfo', g_MapInfo, g_Tops, g_PlayerTops[player]):setClient(player):exec()
	end
	
	if(show) then
		RPC('MiShow'):setClient(players):exec()
	end
	
	prof:cp('MiSendMapInfo')
end

function MiShow(playerOrRoom)
	RPC('MiShow'):setClient(playerOrRoom.el):exec()
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
	g_PlayerTops = {}
	MiSendMapInfo(g_RootRoom)
end

function MiDeleteCache()
	g_MapInfo = false
	g_Tops = false
	g_PlayerTops = {}
end

addInitFunc(function()
	addEventHandler('onGamemodeMapStop', g_Root, MiDeleteCache)
end)
