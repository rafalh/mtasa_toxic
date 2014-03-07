g_RootRoom = false

-- Locals
local g_MapMgrRes = Resource('mapmanager')
local g_MapMgrNewRes = Resource('mapmgr')
local g_RoomMgrRes = Resource('roommgr')
local g_RaceRes = Resource('race')

MapsTable = Database.Table{
	name = 'maps',
	{'map', 'INT UNSIGNED', pk = true},
	{'name', 'VARCHAR(255)'},
	{'played', 'MEDIUMINT UNSIGNED', default = 0},
	{'rates', 'MEDIUMINT UNSIGNED', default = 0},
	{'rates_count', 'SMALLINT UNSIGNED', default = 0},
	{'removed', 'VARCHAR(255)', null = true},
	{'played_timestamp', 'INT UNSIGNED', null = true},
	{'added_timestamp', 'INT UNSIGNED', null = true},
	{'maps_idx', unique = {'name'}},
}

addEvent('onPlayerFinish')
addEvent('onPlayerFinishDD')
addEvent('onPlayerWinDD')
addEvent('onPlayerPickUpRacePickup')
addEvent('onRaceStateChanging')
addEvent('onRoomMapStart')
addEvent('onRoomMapStop')
addEvent('onGamemodeMapStart')
addEvent('onGamemodeMapStop')
addEvent('onClientSetNextMap', true)
addEvent('onChangeMapReq', true)

function initRoomMaps(room)
	if(room.mapsInit) then return end
	room.mapsInit = true
	
	local map = false
	
	if(g_MapMgrRes:isReady()) then
		local mapRes = g_MapMgrRes:call('getRunningGamemodeMap')
		map = mapRes and Map(mapRes)
	elseif(room.el ~= g_Root) then
		if(g_RoomMgrRes:isReady()) then
			Debug.info(tostring(room.el))
			local mapPath = g_RoomMgrRes:call('getRoomMap', room.el)
			map = mapPath and Map(mapPath)
		end
	end
	
	assert(not map or getmetatable(map) == Map.__mt)
	room.currentMap = map
	room.lastMap = map
	room.mapRepeats = 1
	room.isRace = map and #getCurrentMapElements(room, 'checkpoint') > 0
	room.tempElements = {}
end

function findMap(str, removed)
	if(g_MapMgrNewRes:isReady()) then
		local maps = g_MapMgrNewRes:call('findMaps', str)
		for i, mapPath in ipairs(maps) do
			local map = Map(mapPath)
			if(removed ~= nil) then
				local data = DbQuerySingle('SELECT removed FROM '..MapsTable..' WHERE map=? LIMIT 1', map:getId())
				local isRemoved = (data.removed and true)
				if(isRemoved == removed) then
					return map
				end
			else
				return map
			end
		end
		
		return false
	end
	
	local maps = getMapsList()
	
	if(not str or not maps) then
		return false
	end
	
	local strLower = str:lower()
	local result = false
	
	for i, map in maps:ipairs() do
		local map_name = getResourceInfo(map.res, 'name')
		local matches = false
		
		if(getResourceName(map.res):lower() == strLower) then
			matches = 2
		elseif(map_name) then
			map_name = map_name:lower()
			if(map_name == strLower) then
				matches = 1
			elseif(map_name:find(strLower, 1, true)) then
				matches = 3
			end
		end
		
		if(matches and removed ~= nil) then
			local data = DbQuerySingle('SELECT removed FROM '..MapsTable..' WHERE map=? LIMIT 1', map:getId())
			if((data.removed and true) ~= removed) then
				matches = false
			end
		end
		
		if(matches == 1) then
			return map
		elseif(matches) then
			result = map
		end
	end
	
	return result
end

function getRandomMap()
	local maps = getMapsList()
	local i = math.random(1, maps:getCount())
	local map
	while(maps:getCount() > 0) do
		map = maps:get(i)
		local data = DbQuerySingle('SELECT removed FROM '..MapsTable..' WHERE map=? LIMIT 1', map:getId())
		if(not data.removed) then
			break
		end
		maps:remove(i)
		local i = math.random(1, maps:getCount())
	end
	
	if(maps:getCount() == 0) then
		Debug.err('Failed to get random map!')
		return false
	end
	
	return map
end

local function getActivePlayers(ignore)
	local active = {}
	for i, player in ipairs(getAlivePlayers()) do
		if(not isPedDead(player) and player ~= ignore) then
			table.insert(active, player)
		end
	end
	return active
end

function startRandomMap(room)
	assert(room)
	local map = MqPop(room)
	if(map) then
		g_StartingQueuedMap = map
	else
		map = getRandomMap()
	end
	map:start(room)
end

local function onMapStart(map, room)
	assert(getmetatable(map) == Map.__mt)
	
	local prof = DbgPerf()
	local prof2 = DbgPerf(30)
	
	local map_id = map:getId()
	local data = DbQuerySingle('SELECT removed FROM '..MapsTable..' WHERE map=? LIMIT 1', map_id)
	local map_name = map:getName()
	
	if(room.lastMap == map) then
		room.mapRepeats = room.mapRepeats + 1
	else
		room.lastMap = map
		room.mapRepeats = 1
	end
	room.currentMap = map
	room.mapsInit = true
	room.matchInfo = {}
	prof2:cp('onMapStart 1')
	
	if(data.removed) then
		scriptMsg("Map %s is removed! Changing to random map.", map_name)
		--cancelEvent() -- map resource is still running
		setMapTimer(startRandomMap, 500, 1, room)
	else
		room.isRace = #(getCurrentMapElements(room, 'checkpoint')) > 0
		local mapType = map:getType()
		
		local now = getRealTime().timestamp
		DbQuery('UPDATE '..MapsTable..' SET played=played+1, played_timestamp=? WHERE map=?', now, map_id)
		prof2:cp('onMapStart 2')
		
		local was_queued = (g_StartingQueuedMap == map)
		g_StartingQueuedMap = false
		
		-- output map name to console so players can easly copy the name to clipboard
		outputConsole('Map '..map_name..' started'..(was_queued and ' (queued)' or '')..'.')
		
		-- update others_in_row for map types
		if(not was_queued) then -- queue updates others_in_row when new map is added
			local dbg_buf = 'Starting map type: '..mapType.name
			for i, map_type2 in ipairs(g_MapTypes) do
				if(map_type2 ~= mapType) then
					map_type2.others_in_row = map_type2.others_in_row + 1
					dbg_buf = dbg_buf..', '..map_type2.name..': '..map_type2.others_in_row..'('..tostring(map_type2.max_others_in_row)..')'
				else
					map_type2.others_in_row = 0
				end
			end
			--Debug.info(dbg_buf)
		end
		prof2:cp('onMapStart 4')
		
		-- show toptimes
		MiSendMapInfo(room)
		MiShow(room)
		
		-- init some players data
		for player, pdata in pairs(g_Players) do
			if(pdata.room == room) then
				pdata.winner = false
			end
		end
		prof2:cp('onMapStart 5')
		
		-- start recording
		local winningVeh = mapType and mapType.winning_veh
		local hasRanking = room.isRace or winningVeh
		room.recording = hasRanking and RcStartRecording and Settings.recorder
		if(room.recording) then
			RcStartRecording(room, map_id)
		end
		if(hasRanking and TopTimePlayback) then
			TopTimePlayback.start(room, map_id)
		end
		prof2:cp('onMapStart 6')
		
		-- set fps limit
		local maxFps = mapType and mapType.max_fps
		if(maxFps) then
			setFPSLimit(maxFps)
		end
		
		-- check if ghostmode should be enabled
		if(not map:getSetting('ghostmode')) then
			local gm = mapType and mapType.gm
			setMapTimer(GmSet, 3000, 1, room, gm, true)
		end
		prof2:cp('onMapStart 7')
		
		-- show best times
		if(BtPrintTimes) then
			BtPrintTimes(room, map_id)
		end
		
		-- allow bets
		GbStartBets()
		
		StMapStart(room)
	end
	
	prof2:cp('onMapStart 8')
	prof:cp('onMapStart')
end

local function onMapStop(room)
	if(not room.currentMap) then return end

	local prof = DbgPerf()
	
	-- Stop recording and playback
	if(room.recording) then
		room.recording = false
		RcStopRecording(room)
	end
	if(TopTimePlayback) then
		TopTimePlayback.stop(room)
	end
	
	if(GbFinishBets) then
		GbFinishBets()
	end
	
	if(StMapStop) then
		StMapStop(room)
	end
	
	room.currentMap = false
	
	-- Set old vehicleweapons value in case it has been changed
	if(g_OldVehicleWeapons) then
		set('*race.vehicleweapons', g_OldVehicleWeapons)
		g_OldVehicleWeapons = nil
	end
	
	-- Destroy temporary objects
	for i, el in ipairs(room.tempElements or {}) do
		destroyElement(el)
	end
	room.tempElements = {}
	
	prof:cp('onMapStop')
end

local function handlePlayerTime(player, ms)
	local prof = DbgPerf()
	local pdata = Player.fromEl(player)
	if(not pdata.id) then return 0 end
	
	local map = getCurrentMap(pdata.room)
	local default_speed = tonumber(map:getSetting('gamespeed')) or 1
	local speed = getGameSpeed()
	if(math.abs(speed - default_speed) > 0.001) then
		Debug.info('Invalid game speed (default: '..default_speed..', current: '..speed..')')
		return 0
	end
	
	local map_id = map:getId()
	local n = addPlayerTime and addPlayerTime(pdata.id, map_id, ms) or 0
	if(n >= 1) then -- improved best time
		pdata:addNotify{
			icon = 'best_times/race.png',
			{"You have improved your personal best time!"},
			{"New: %s", formatTimePeriod(ms / 1000)},
		}
		
		if(n <= 3) then -- new toptime
			local th = ({ '1st', '2nd', '3rd' })[n]
			scriptMsg("The %s top time: %s by %s!", th, formatTimePeriod(ms / 1000), getPlayerName(player))
			
			local award = 30000 / n
			pdata.accountData:add('cash', award)
			privMsg(player, "%s added to your cash! Total: %s.", formatMoney(award), formatMoney(pdata.accountData.cash))
		end
		
		if(n <= 8) then
			MiShow(pdata.room)
		end
	end
	
	prof:cp('handlePlayerTime')
	return n
end

local function handlePlayerWin(player)
	scriptMsg("%s is the winner!", getPlayerName(player))
	
	GbFinishBets(player)
end

local function onPlayerFinish(rank, ms)
	local prof = DbgPerf()
	local prof2 = DbgPerf(30)
	
	local pdata = Player.fromEl(source)
	local map = getCurrentMap(pdata.room)
	
	local n = handlePlayerTime(source, ms)
	local improvedBestTime = (n >= 1)
	
	RcFinishRecordingPlayer(source, ms, map:getId(), improvedBestTime)
	
	if(rank == 1) then
		handlePlayerWin(source)
	end
	
	StPlayerFinish(pdata, rank, ms)
	
	prof:cp('onPlayerFinish')
end

local function onPlayerFinishDD(rank, timePassed)
	if(rank == 1) then return end -- ignore (use onPlayerWinDD instead)
	
	local player = Player.fromEl(source)
	if(not player) then return end -- for example has been kicked
	
	StPlayerFinish(player, rank, timePassed)
end

local function onPlayerWinDD()
	handlePlayerWin(source)
	triggerClientEvent(root, 'main.onPlayerWinDD', source)
	
	local player = Player.fromEl(source)
	assert(player)
	StPlayerFinish(player, 1)
	
	--[[local game_weight = 0.007 * g_PlayersCount / 32
	local pdata = Player.fromEl(source)
	for player, pdata in pairs(g_Players) do
		local efectiveness_dd = pdata.accountData.efectiveness_dd
		local rank = (player == source) and 1 or g_PlayersCount
		efectiveness_dd = efectiveness_dd * (1 - game_weight) + (rank - 1) / g_PlayersCount * game_weight
		pdata.accountData:set('efectiveness_dd', efectiveness_dd)
	end]]
end

local function onPlayerPickUpRacePickup(pickupID, pickupType, vehicleModel)
	local prof = DbgPerf()
	
	local player = Player.fromEl(source)
	local room = player.room
	local map = getCurrentMap(room)
	local mapType = map and map:getType()
	
	if(pickupType == 'vehiclechange' and mapType and mapType.winning_veh and vehicleModel and mapType.winning_veh[vehicleModel] and not player.winner) then
		player.winner = true
		scriptMsg("Warning! %s has been given to %s.", getVehicleNameFromModel(vehicleModel), player:getName())
		if(GmIsEnabled(room)) then
			GmSet(room, false)
		end
		
		StHunterTaken(player)
		
		local ms = g_RaceRes:isReady() and g_RaceRes:call('getTimePassed')
		if(ms) then
			local n = handlePlayerTime(player.el, ms)
			local improvedBestTime = (n >= 1)
			RcFinishRecordingPlayer(player.el, ms, map:getId(), improvedBestTime)
		end
	end
	
	prof:cp('onPlayerPickUpRacePickup')
end

local function onRaceStateChange(state)
	local room = g_RootRoom
	if(state == 'Running') then
		room.gameIsRunning = true
	elseif(state == 'PostFinish') then
		room.gameIsRunning = false
	end
end

function getMapList()
	local prof = DbgPerf()
	local prof2 = DbgPerf(20)
	
	local mapsList = {}
	local maps = getMapsList()
	prof2:cp('onMapListReq 1')
	for i, map in maps:ipairs() do
		local mapResName = (map.res and getResourceName(map.res)) or map.path
		local mapName = map:getName()
		local mapAuthor = map:getInfo('author') or ''
		mapsList[mapResName] = {mapName, mapAuthor, 0, 0}
	end
	prof2:cp('onMapListReq 2')
	local rows = DbQuery('SELECT name, played, rates, rates_count FROM '..MapsTable)
	prof2:cp('onMapListReq 3')
	for i, data in ipairs(rows) do
		if(mapsList[data.name]) then
			mapsList[data.name][3] = data.played
			if(data.rates_count > 0) then
				mapsList[data.name][4] = data.rates / data.rates_count
			end
		end
	end
	prof2:cp('onMapListReq 4')
	prof:cp('onMapListReq')
	return mapsList
end
RPC.allow('getMapList')

local function onChangeMapReq(mapResName)
	if(not hasObjectPermissionTo(client, 'command.setmap', false)) then return end
	
	local map = false
	local mapRes = getResourceFromName(mapResName)
	if(mapRes) then
		map = Map(mapRes)
	else
		if(g_MapMgrNewRes:isReady() and g_MapMgrNewRes:call('isMap', mapResName)) then
			map = Map(mapResName)
		end
	end
	
	if(map) then
		GbCancelBets()
		local room = Player.fromEl(client).room
		map:start(room)
	else
		Debug.warn('getResourceFromName failed')
	end
end

function getCurrentMap(room)
	assert(room ~= nil)
	if(not room) then return false end
	if(not room.mapsInit) then initRoomMaps(room) end
	assert(not room.currentMap or getmetatable(room.currentMap) == Map.__mt)
	return room.currentMap
end

function getLastMap(room)
	assert(room ~= nil)
	if(not room) then return false end
	if(not room.mapsInit) then initRoomMaps(room) end
	return room.lastMap
end

function getCurrentMapElements(room, type)
	local map = room.currentMap
	if(map.res) then
		return getElementsByType(type, map.resRoot)
	end
	
	if(g_RoomMgrRes:isReady()) then
		return g_RoomMgrRes:call('getRoomMapElements', room.el, type)
	end
	
	return false
end

function getMapsList()
	if(g_MapMgrRes:isReady()) then
		local gamemodeRes = g_MapMgrRes:call('getRunningGamemode')
		local mapResList = g_MapMgrRes:call('getMapsCompatibleWithGamemode', gamemodeRes)
		return MapList(mapResList)
	end
	
	if(g_MapMgrNewRes:isReady()) then
		local mapList = g_MapMgrNewRes:call('getMapsList')
		return MapList(mapList)
	end
	
	return false
end

addInitFunc(function()
	g_RootRoom = Room(g_Root)
	
	addEventHandler('onRoomMapStart', g_Root, function(mapPath)
		local map = Map(mapPath)
		local room = Room(source)
		onMapStart(map, room)
	end)
	addEventHandler('onRoomMapStop', g_Root, function()
		local room = Room(source)
		onMapStop(room)
	end)
	addEventHandler('onGamemodeMapStart', g_Root, function(mapRes)
		local map = Map(mapRes)
		onMapStart(map, g_RootRoom)
	end)
	addEventHandler('onGamemodeMapStop', g_Root, function()
		onMapStop(g_RootRoom)
	end)
	addEventHandler('onPlayerFinish', g_Root, onPlayerFinish)
	addEventHandler('onPlayerFinishDD', g_Root, onPlayerFinishDD)
	addEventHandler('onPlayerWinDD', g_Root, onPlayerWinDD)
	addEventHandler('onPlayerPickUpRacePickup', g_Root, onPlayerPickUpRacePickup)
	addEventHandler('onRaceStateChanging', g_Root, onRaceStateChange)
	addEventHandler('onChangeMapReq', g_ResRoot, onChangeMapReq)
end)
