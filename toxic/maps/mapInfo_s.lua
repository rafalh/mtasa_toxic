local g_MapInfo = false

local function MiGetInfo(map)
	local info = DbQuerySingle('SELECT played, rates, rates_count FROM '..MapsTable..' WHERE map=? LIMIT 1', map:getId())
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
	
	-- Prepare map info
	if(not g_MapInfo) then
		g_MapInfo = MiGetInfo(map)
	end
	
	-- Get Tops
	local topTimes
	if(g_MapInfo.type == 'DD' and DdGetTops) then
		topTimes = DdGetTops(map, 8)
	else
		topTimes = BtGetTops(map, 8)
	end
	
	-- Send Tops and map general info to all players
	RPC('MiSetMapInfo', g_MapInfo, topTimes):setClient(playerOrRoom.el):exec()
	
	-- Prepare list of IDs
	local players = getElementsByType('player', playerOrRoom.el)
	local idList = {}
	for i, player in ipairs(players) do
		local pdata = Player.fromEl(player)
		if(pdata and pdata.id) then
			table.insert(idList, pdata.id)
		end
	end
	
	-- Preload all needed information
	if(g_MapInfo.type == 'DD' and DdPreloadPersonalTops) then
		DdPreloadPersonalTops(map:getId(), idList, true)
	elseif(BtPreloadPersonalTops) then
		BtPreloadPersonalTops(map:getId(), idList, true)
	end
	RtPreloadPersonalMapRating(map:getId(), idList)
	
	for i, player in ipairs(players) do
		local pdata = Player.fromEl(player)
		local personalTop, personalRating
		
		-- Load personal Top
		if(not pdata) then
			personalTop = false
		elseif(g_MapInfo.type == 'DD' and DdGetPersonalTop) then
			personalTop = DdGetPersonalTop(map:getId(), pdata.id, true)
		elseif(BtGetPersonalTop) then
			personalTop = BtGetPersonalTop(map:getId(), pdata.id, true)
		end
		
		-- Make time readable
		if(personalTop and personalTop.time) then
			personalTop.time = formatTimePeriod(personalTop.time / 1000)
		end
		
		-- Get player rating for current map
		if(RtGetPersonalMapRating and pdata) then
			personalRating = RtGetPersonalMapRating(map:getId(), pdata.id)
		end
		
		-- Send personal Top and rating to owner
		RPC('MiSetPersonalInfo', personalTop, personalRating):setClient(player):exec()
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
end

addInitFunc(function()
	addEventHandler('onGamemodeMapStop', g_Root, MiDeleteCache)
end)
