local g_MapInfo = false
local g_PlayerRates = {}

local function MiGetInfo(map)
	local info = DbQuerySingle('SELECT played, rates, rates_count FROM '..MapsTable..' WHERE map=? LIMIT 1', map:getId())
	info.name = map:getName()
	info.rating = (info.rates_count > 0 and info.rates/info.rates_count) or 0
	info.author = map:getInfo('author')
	local mapType = map:getType()
	info.type = mapType and mapType.name
	return info
end

local function MiUpdateRates(map, players)
	local idList = {}
	for i, player in ipairs(players) do
		local pdata = Player.fromEl(player)
		if(g_PlayerRates[player] == nil and pdata and pdata.id) then
			table.insert(idList, pdata.id)
			g_PlayerRates[player] = false
		end
	end
	
	local rows = DbQuery('SELECT player, rate FROM '..RatesTable..' WHERE map=? AND player IN (??)', map:getId(), table.concat(idList, ','))
	for i, data in ipairs(rows) do
		local pdata = Player.fromId(data.player)
		g_PlayerRates[pdata.el] = data.rate
	end
end

function MiSendMapInfo(playerOrRoom)
	local room = playerOrRoom.cls == Player and playerOrRoom.room or playerOrRoom
	
	local prof = DbgPerf()
	local map = getCurrentMap(room)
	if(not map) then return end
	
	if(not g_MapInfo) then
		g_MapInfo = MiGetInfo(map)
	end
	
	assert(not DdUpdatePlayerTops) -- FIXME
	
	local topTimes
	if(g_MapInfo.type == 'DD' and DdGetTops) then
		topTimes = DdGetTops(map, 8)
	else
		topTimes = BtGetTops(map, 8)
	end
	RPC('MiSetMapInfo', g_MapInfo, topTimes):setClient(playerOrRoom.el):exec()
	
	local players = getElementsByType('player', playerOrRoom.el)
	local idList = {}
	for i, player in ipairs(players) do
		local pdata = Player.fromEl(player)
		if(pdata.id) then
			table.insert(idList, pdata.id)
		end
	end
	
	BtPreloadPersonalTops(map:getId(), idList, true)
	MiUpdateRates(map, players)
	
	for i, player in ipairs(players) do
		local pdata = Player.fromEl(player)
		local personalTop
		
		if(BtGetPersonalTime) then
			personalTop = {}
			personalTop.time = BtGetPersonalTime(map:getId(), pdata.id)
			personalTop.pos = BtGetPersonalPos(map:getId(), pdata.id)
			if(not personalTop.time) then
				personalTop = false
			end
		end
		
		RPC('MiSetPersonalInfo', personalTop, g_PlayerRates[player]):setClient(player):exec()
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
	MiSendMapInfo(g_RootRoom)
end

function MiDeleteCache()
	g_MapInfo = false
	g_PlayerRates = {}
end

addInitFunc(function()
	addEventHandler('onGamemodeMapStop', g_Root, MiDeleteCache)
end)
