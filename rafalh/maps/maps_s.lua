g_RootRoom = false

addEvent("onPlayerFinish")
addEvent("onPlayerWinDD")
addEvent("onRoomMapStart")
addEvent("onRoomMapStop")
addEvent("onGamemodeMapStart")
addEvent("onGamemodeMapStop")
addEvent("onPlayerPickUpRacePickup")
addEvent("onClientSetNextMap", true)
addEvent("onClientMapList", true)
addEvent("onMapListReq", true)
addEvent("onChangeMapReq", true)

function initRoomMaps(room)
	if(room.mapsInit) then return end
	room.mapsInit = true
	
	local map = false
	
	local mapMgrRes = getResourceFromName("mapmanager")
	if(mapMgrRes and getResourceState(mapMgrRes) == "running") then
		local mapRes = call(mapMgrRes, "getRunningGamemodeMap")
		map = mapRes and Map.create(mapRes)
	elseif(room.el ~= g_Root) then
		local roomMgrRes = getResourceFromName("roommgr")
		if(roomMgrRes and getResourceState(roomMgrRes) == "running") then
			outputDebugString(tostring(room.el), 3)
			local mapPath = call(roomMgrRes, "getRoomMap", room.el)
			map = mapPath and Map.create(mapPath)
		end
	end
	
	assert(not map or getmetatable(map) == Map.__mt)
	room.currentMap = map
	room.lastMap = map
	room.mapRepeats = 1
	room.isRace = map and #getCurrentMapElements(room, "checkpoint") > 0
end

function findMap (str, removed)
	local mapMgrRes = getResourceFromName("mapmgr")
	if(mapMgrRes and getResourceState(mapMgrRes) == "running") then
		local maps = call(mapMgrRes, "findMaps", str)
		for i, mapPath in ipairs(maps) do
			local map = Map.create(mapPath)
			if(removed ~= nil) then
				local rows = DbQuery ("SELECT removed FROM rafalh_maps WHERE map=? LIMIT 1", map:getId())
				local isRemoved = (rows[1].removed ~= "")
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
	
	local strLower = str:lower ()
	local result = false
	
	for i, map in maps:ipairs() do
		local map_name = getResourceInfo (map.res, "name")
		local matches = false
		
		if(getResourceName (map.res):lower () == strLower) then
			matches = 2
		elseif(map_name) then
			map_name = map_name:lower ()
			if (map_name == strLower) then
				matches = 1
			elseif(map_name:find (strLower, 1, true)) then
				matches = 3
			end
		end
		
		if(matches and removed ~= nil) then
			local rows = DbQuery ("SELECT removed FROM rafalh_maps WHERE map=? LIMIT 1", map:getId())
			if((rows[1].removed ~= "") ~= removed) then
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
	local i = math.random (1, maps:getCount())
	local map
	while(maps:getCount() > 0) do
		map = maps:get(i)
		local rows = DbQuery("SELECT removed FROM rafalh_maps WHERE map=? LIMIT 1", map:getId())
		if(rows[1].removed == "") then
			break
		end
		maps:remove(i)
		local i = math.random (1, maps:getCount())
	end
	
	if(maps:getCount() == 0) then
		outputDebugString("Failed to get random map!", 1)
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
	
	local map_id = map:getId()
	local rows = DbQuery("SELECT removed FROM rafalh_maps WHERE map=? LIMIT 1", map_id)
	local map_name = map:getName()
	
	if (room.lastMap == map) then
		room.mapRepeats = room.mapRepeats + 1
	else
		room.lastMap = map
		room.mapRepeats = 1
	end
	room.currentMap = map
	
	if(rows[1].removed ~= "") then
		scriptMsg("Map %s is removed! Changing to random map.", map_name)
		--cancelEvent () -- map resource is still running
		setMapTimer(startRandomMap, 500, 1, room)
	else
		room.isRace = #(getCurrentMapElements(room, "checkpoint")) > 0
		local map_type = map:getType()
		
		local now = getRealTime().timestamp
		DbQuery("UPDATE rafalh_maps SET played=played+1, played_timestamp=? WHERE map=?", now, map_id)
		
		local mapTypeCounter = false
		if(room.isRace) then
			mapTypeCounter = "racesPlayed"
		elseif(map_type.name == "DD") then
			mapTypeCounter = "ddPlayed"
		elseif(map_type.name == "DM") then
			mapTypeCounter = "dmPlayed"
		end
		
		for player, pdata in pairs(g_Players) do
			pdata.accountData:add("mapsPlayed", 1)
			if(mapTypeCounter) then
				pdata.accountData:add(mapTypeCounter, 1)
			end
		end
		
		local was_queued = (g_StartingQueuedMap == map)
		g_StartingQueuedMap = false
		
		-- output map name to console so players can easly copy the name to clipboard
		outputConsole("Map "..map_name.." started"..(was_queued and " (queued)" or "")..".")
		
		-- update others_in_row for map types
		if(not was_queued) then -- queue updates others_in_row when new map is added
			local dbg_buf = "Starting map type: "..map_type.name
			for i, map_type2 in ipairs (g_MapTypes) do
				if (map_type2 ~= map_type) then
					map_type2.others_in_row = map_type2.others_in_row + 1
					dbg_buf = dbg_buf..", "..map_type2.name..": "..map_type2.others_in_row.."("..map_type2.max_others_in_row..")"
				else
					map_type2.others_in_row = 0
				end
			end
			outputDebugString(dbg_buf, 3)
		end
		
		-- show toptimes
		BtSendMapInfo(room, true)
		
		-- init some players data
		for player, pdata in pairs (g_Players) do
			if(pdata.room == room) then
				pdata.cp_times = SmGetBool("cp_recorder") and room.isRace and {}
				pdata.winner = false
			end
		end
		
		-- start recording
		local winning_veh = map_type and map_type.winning_veh
		room.recording = (room.isRace or winning_veh) and SmGetBool ("recorder")
		if (room.isRace or winning_veh) then
			if (room.recording) then
				RcStartRecording(room, map_id)
			end
		end
		
		-- set fps limit
		local maxFps = map_type and map_type.max_fps
		if(maxFps) then
			setFPSLimit(maxFps)
		end
		
		-- check if ghostmode should be enabled
		if(not map:getSetting("ghostmode")) then
			local gm = map_type and map_type.gm
			setMapTimer(GmSet, 3000, 1, room, gm, true)
		end
		
		-- show best times
		BtPrintTimes(room, map_id)
		
		-- allow bets
		GbStartBets()
	end
end

local function onMapStop(room)
	if (room.recording) then
		room.recording = false
		RcStopRecording (room)
	end
	
	GbFinishBets ()
	
	if (g_OldVehicleWeapons) then
		set ("*race.vehicleweapons", g_OldVehicleWeapons)
		g_OldVehicleWeapons = nil
	end
	
	room.currentMap = false
	
	for i, el in ipairs(room.tempElements or {}) do
		destroyElement(el)
	end
	room.tempElements = {}
end

local function handlePlayerTime(player, ms)
	local pdata = Player.fromEl(player)
	if(not pdata.id) then return 0 end
	
	local map = getCurrentMap(pdata.room)
	local default_speed = tonumber(map:getSetting("gamespeed")) or 1
	local speed = getGameSpeed ()
	if(math.abs(speed - default_speed) > 0.001) then
		outputDebugString("Invalid game speed (default: "..default_speed..", current: "..speed..")", 3)
		return 0
	end
	
	local map_id = map:getId()
	local n = addPlayerTime(pdata.id, map_id, ms)
	if(n >= 1) then -- improved best time
		privMsg (player, "You have improved your personal best time! New: %s", formatTimePeriod(ms / 1000))
		
		if (n <= 3) then -- new toptime
			local th = ({ "st", "nd", "rd" })[n]
			scriptMsg ("The %s top time: %s by %s!", n..th, formatTimePeriod (ms / 1000), getPlayerName(player))
			
			local award = 30000 / n
			pdata.accountData:add("cash", award)
			privMsg(player, "%s added to your cash! Total: %s.", formatMoney(award), formatMoney(pdata.accountData.cash))
		end
		
		if (n <= 8) then
			BtSendMapInfo(pdata.room, true)
		end
	end
	
	return n
end

local function handlePlayerWin(player)
	local pdata = Player.fromEl(player)
	local room = pdata.room
	scriptMsg("%s is the winner!", getPlayerName(player))
	
	GbFinishBets(player)
	
	local map = getCurrentMap(room)
	local mapType = map and map:getType()
	local winCounter = false
	if(not mapType) then
		outputDebugString("unknown map type", 2)
	elseif(room.isRace) then
		winCounter = "raceVictories"
	elseif(mapType.name == "DM") then
		winCounter = "dmVictories"
	elseif(mapType.name == "DD") then
		winCounter = "ddVictories"
	end
	
	if(winCounter) then
		pdata.accountData:add(winCounter, 1)
	end
	
	if(room.winStreakPlayer == player) then
		room.winStreakLen = room.winStreakLen + 1
		if(g_PlayersCount > 1) then
			scriptMsg("%s is on a winning streak! It's his %u. victory.", getPlayerName(player), room.winStreakLen)
		end
	else
		room.winStreakPlayer = player
		room.winStreakLen = 1
	end
	local maxStreak = pdata.accountData.maxWinStreak
	if(room.winStreakLen > maxStreak) then
		pdata.accountData:set("maxWinStreak", room.winStreakLen)
	end
end

local function setPlayerFinalRank(player, rank)
	local cashadd = math.floor (1000 * g_PlayersCount / rank)
	local pointsadd = math.floor (g_PlayersCount / rank)
	local pdata = Player.fromEl(player)
	
	local stats = {}
	stats.cash = pdata.accountData.cash + cashadd
	stats.points = pdata.accountData.points + pointsadd
	pdata.accountData:set(stats)
	privMsg (player, "%s added to your cash! Total: %s.", formatMoney(cashadd), formatMoney(stats.cash))
	privMsg (player, "You earned %s points. Total: %s.", formatNumber(pointsadd), formatNumber(stats.points))
	
	if(rank == 1) then
		handlePlayerWin(player)
	end
end

local function onPlayerFinish(rank, ms)
	local pdata = Player.fromEl(source)
	local map = getCurrentMap(pdata.room)
	local map_id = map:getId()
	
	if(rank <= 3) then
		local rank_str = ({"first", "second", "third"})[rank]
		pdata.accountData:add(rank_str, 1)
	end
	
	pdata.accountData:add("racesFinished", 1)
	
	local n = handlePlayerTime(source, ms)
	local improvedBestTime = (n >= 1)
	
	RcFinishRecordingPlayer(source, ms, map_id, improvedBestTime)
	
	setPlayerFinalRank(source, rank)
end

local function onPlayerWinDD()
	local pdata = Player.fromEl(source)
	pdata.accountData:add("dm_wins", 1)
	
	--local game_weight = 0.007 * g_PlayersCount / 32
	
	for player, pdata in pairs(g_Players) do
		pdata.accountData:add("dm", 1)
		
		--local efectiveness_dd = pdata.accountData.efectiveness_dd
		--local rank = (player == source) and 1 or g_PlayersCount
		--efectiveness_dd = efectiveness_dd * (1 - game_weight) + (rank - 1) / g_PlayersCount * game_weight
		--pdata.accountData:set("efectiveness_dd", efectiveness_dd)
	end
	
	setPlayerFinalRank(source, 1)
	triggerClientEvent(root, "main.onPlayerWinDD", source)
end

local function onPlayerPickUpRacePickup(pickupID, pickupType, vehicleModel)
	local pdata = Player.fromEl(source)
	local room = pdata.room
	local map = getCurrentMap(room)
	local mapType = map and map:getType()
	
	if(pickupType == "vehiclechange" and mapType and mapType.winning_veh and vehicleModel and mapType.winning_veh[vehicleModel] and not pdata.winner) then
		pdata.winner = true
		scriptMsg("Warning! %s has been given to %s.", getVehicleNameFromModel (vehicleModel), getPlayerName (source))
		if(GmIsEnabled(room)) then
			GmSet(room, false)
		end
		
		if(mapType.name == "DM") then
			pdata.accountData:add("huntersTaken", 1)
		end
		
		local race_res = getResourceFromName("race")
		local ms = race_res and call(race_res, "getTimePassed")
		if(ms) then
			local n = handlePlayerTime(source, ms)
			local improvedBestTime = (n >= 1)
			RcFinishRecordingPlayer(source, ms, map:getId(), improvedBestTime)
		end
	end
end

local function onMapListReq()
	local mapsList = {}
	local maps = getMapsList()
	
	for i, map in maps:ipairs() do
		local mapResName = (map.res and getResourceName(map.res)) or map.path
		local mapName = map:getName()
		local mapAuthor = map:getInfo("author") or ""
		mapsList[mapResName] = {mapName, mapAuthor, 0, 0}
	end
	
	local rows = DbQuery("SELECT name, played, rates, rates_count FROM rafalh_maps", map)
	for i, data in ipairs (rows) do
		if(mapsList[data.name]) then
			mapsList[data.name][3] = data.played
			if(data.rates_count > 0) then
				mapsList[data.name][4] = data.rates / data.rates_count
			end
		end
	end
	
	triggerClientEvent(client, "onClientMapList", g_ResRoot, mapsList)
end

local function onChangeMapReq(mapResName)
	if (not hasObjectPermissionTo (client, "command.setmap", false)) then return end
	
	local map = false
	local mapRes = getResourceFromName(mapResName)
	if(mapRes) then
		map = Map.create(mapRes)
	else
		local mapMgrRes = getResourceFromName("mapmgr")
		if(mapMgrRes and getResourceState(mapMgrRes) == "running" and call(mapMgrRes, "isMap", mapResName)) then
			map = Map.create(mapResName)
		end
	end
	
	if (map) then
		GbCancelBets ()
		local room = Player.fromEl(client).room
		map:start(room)
	else
		outputDebugString("getResourceFromName failed", 2)
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
	
	local roomMgrRes = getResourceFromName("roommgr")
	if(roomMgrRes and getResourceState(roomMgrRes) == "running") then
		return call(roomMgrRes, "getRoomMapElements", room.el, type)
	end
	
	return false
end

function getMapsList()
	local mapMgrRes = getResourceFromName("mapmanager")
	if(mapMgrRes and getResourceState(mapMgrRes) == "running") then
		local gamemodeRes = call(mapMgrRes, "getRunningGamemode")
		local mapResList = call(mapMgrRes, "getMapsCompatibleWithGamemode", gamemodeRes)
		return MapList.create(mapResList)
	end
	
	local mapMgrRes = getResourceFromName("mapmgr")
	if(mapMgrRes and getResourceState(mapMgrRes) == "running") then
		local mapList = call(mapMgrRes, "getMapsList")
		return MapList.create(mapList)
	end
	
	return false
end

addInitFunc(function()
	g_RootRoom = Room.create(g_Root)
	
	addEventHandler("onRoomMapStart", g_Root, function(mapPath)
		local map = Map.create(mapPath)
		local room = Room.create(source)
		onMapStart(map, room)
	end)
	addEventHandler("onRoomMapStop", g_Root, function()
		local room = Room.create(source)
		onMapStop(room)
	end)
	addEventHandler("onGamemodeMapStart", g_Root, function(mapRes)
		local map = Map.create(mapRes)
		onMapStart(map, g_RootRoom)
	end)
	addEventHandler("onGamemodeMapStop", g_Root, function()
		onMapStop(g_RootRoom)
	end)
	addEventHandler ("onPlayerFinish", g_Root, onPlayerFinish)
	addEventHandler ("onPlayerWinDD", g_Root, onPlayerWinDD)
	addEventHandler ("onPlayerPickUpRacePickup", g_Root, onPlayerPickUpRacePickup)
	addEventHandler ("onMapListReq", g_ResRoot, onMapListReq)
	addEventHandler ("onChangeMapReq", g_ResRoot, onChangeMapReq)
end)
