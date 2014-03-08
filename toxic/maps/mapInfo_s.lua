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
		if(pdata and pdata.id) then
			table.insert(idList, pdata.id)
		end
	end
	
	if(g_MapInfo.type == 'DD' and DdPreloadPersonalTops) then
		DdPreloadPersonalTops(map:getId(), idList, true)
	elseif(BtPreloadPersonalTops) then
		BtPreloadPersonalTops(map:getId(), idList, true)
	end
	MiUpdateRates(map, players)
	
	for i, player in ipairs(players) do
		local pdata = Player.fromEl(player)
		local personalTop
		
		if(not pdata) then
			personalTop = false
		elseif(g_MapInfo.type == 'DD' and DdGetPersonalTop) then
			personalTop = DdGetPersonalTop(map:getId(), pdata.id, true)
		elseif(BtGetPersonalTop) then
			personalTop = BtGetPersonalTop(map:getId(), pdata.id, true)
		end
		
		-- Make time readable
		if(personalTop) then
			personalTop.time = formatTimePeriod(personalTop.time / 1000)
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
