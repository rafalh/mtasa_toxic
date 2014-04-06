local g_Poll = false

RatesTable = Database.Table{
	name = 'rates',
	{'player', 'INT UNSIGNED', fk = {'players', 'player'}},
	{'map', 'INT UNSIGNED', fk = {'maps', 'map'}},
	{'rate', 'TINYINT UNSIGNED'},
	{'rates_idx', unique = {'map', 'player'}},
}

addEvent('onPollStarting')

local function RtAddPlayerRate(playerId, rate, mapId)
	local mapData = DbQuerySingle('SELECT rates, rates_count FROM '..MapsTable..' WHERE map=? LIMIT 1', mapId)
	
	local oldRate = RtGetPersonalMapRating(mapId, playerId)
	if(not oldRate or Settings.allow_rate_change) then
		if(oldRate) then
			assert(mapData.rates_count > 0 and mapData.rates > 0)
			mapData.rates = mapData.rates - oldRate + rate
			DbQuery('UPDATE '..RatesTable..' SET rate=? WHERE player=? AND map=?', rate, playerId, mapId)
		else
			mapData.rates_count = mapData.rates_count + 1
			mapData.rates = mapData.rates + rate
			DbQuery('INSERT INTO '..RatesTable..' (player, map, rate) VALUES(?, ?, ?)', playerId, mapId, rate)
			AccountData.create(playerId):add('mapsRated', 1)
		end
		
		-- Update cache
		local personalCache = Cache.get('MapRating.m'..mapId..'.Personal')
		personalCache[playerId] = rate
		
		-- Update map rating
		DbQuery('UPDATE '..MapsTable..' SET rates=?, rates_count=? WHERE map=?', mapData.rates, mapData.rates_count, mapId)
		
		-- Update map info
		MiUpdateInfo()
		
		return (mapData.rates / mapData.rates_count)
	else
		return false, "You rated this map before: %u!", {oldRate}
	end
end

function RtPlayerRate(rate)
	local pdata = Player.fromEl(source)
	local room = pdata.room
	local map = getCurrentMap(room)
	
	-- Check arguments
	rate = touint(rate, 0)
	if(rate < 1 or rate > 5 or not map or not pdata.id) then return end
	
	-- Add new rate
	local mapId = map:getId()
	local newMapRating, err, tbl = RtAddPlayerRate(pdata.id, rate, mapId)
	
	if(newMapRating) then
		-- Update Map Info window
		MiUpdateInfo()
		
		-- Success
		privMsg(source, "Rate added! Current average rating: %.2f", newMapRating)
	else
		-- Error
		privMsg(source, err, unpack(tbl))
	end
end
RPC.allow('RtPlayerRate')

local function RtTimerProc(room)
	local map = getCurrentMap(room)
	if(not map or g_Poll) then return end
	
	local pidList = {}
	for player, pdata in pairs(g_Players) do
		if(pdata.id and pdata.sync) then
			table.insert(pidList, pdata.id)
		end
	end
	
	local mapId = map:getId()
	RtPreloadPersonalMapRating(mapId, pidList)
	
	for i, pid in ipairs(pidList) do
		local rate = RtGetPersonalMapRating(mapId, pid)
		if(not rate) then
			local player = Player.fromId(pid)
			RPC('RtSetVisible', true):setClient(player.el):exec()
		end
	end
end

function RtPreloadPersonalMapRating(mapId, playerIdList)
	local personalCache = Cache.get('MapRating.m'..mapId..'.Personal')
	if(not personalCache) then
		personalCache = {}
		Cache.set('MapRating.m'..mapId..'.Personal', personalCache, 300)
	end
	
	local idList = {}
	for i, playerId in ipairs(playerIdList) do
		if(personalCache[playerId] == nil) then
			personalCache[playerId] = false
			table.insert(idList, playerId)
		end
	end
	
	if(#idList > 0) then
		local rows = DbQuery('SELECT player, rate FROM '..RatesTable..' WHERE map=? AND player IN (??)', mapId, table.concat(idList, ','))
		
		for i, data in ipairs(rows) do
			assert(personalCache[data.player] == false)
			personalCache[data.player] = data.rate
		end
	end
end

function RtGetPersonalMapRating(mapId, playerId)
	if(not playerId) then return false end
	RtPreloadPersonalMapRating(mapId, {playerId})
	local cache = Cache.get('MapRating.m'..mapId..'.Personal')
	return cache[playerId]
end

local function RtMapStart()
	setMapTimer(RtTimerProc, 60 * 1000, 1, g_RootRoom) -- FIXME
	g_Poll = false
end

local function RtPoolStarting()
	--Debug.info('RtPoolStarting')
	RPC('RtSetVisible', false):exec()
	g_Poll = true
end

addInitFunc(function()
	addEventHandler('onGamemodeMapStart', g_Root, RtMapStart) -- FIXME
	addEventHandler('onPollStarting', g_Root, RtPoolStarting)
end)

#if(TEST) then
	Test.register('MapRating', function()
		local map = Map(resource)
		local testPlayer = Player.getConsole()
		
		local myRate = RtGetPersonalMapRating(map:getId(), testPlayer.id)
		Test.checkEq(myRate, false)
		
		local newRating = RtAddPlayerRate(testPlayer.id, 3, map:getId())
		Test.checkEq(newRating, 3)
		
		local myRate = RtGetPersonalMapRating(map:getId(), testPlayer.id)
		Test.checkEq(myRate, 3)
		
		-- Cleanup
		Database.query('DELETE FROM '..RatesTable..' WHERE map=?', map:getId())
		Database.query('DELETE FROM '..MapsTable..' WHERE map=?', map:getId())
		Cache.remove('MapRating.m'..map:getId()..'.Personal')
		Map.idCache[map.res or map.path] = nil
	end)
#end
