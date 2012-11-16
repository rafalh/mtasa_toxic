---------------------
-- Local variables --
---------------------

local g_Initialized = false
local g_Recording = false
local g_WinningStreakPlayer = false
local g_WinningStreakLen = 0
local g_CurrentMap = false
local g_LastMap = false
local g_IsRace = false
g_MapRepeats = 1

-------------------
-- Custom events --
-------------------

addEvent ("onPlayerFinish")
addEvent ("onPlayerWinDD")
addEvent ("onPlayerPickUpRacePickup")
addEvent ("onClientSetNextMap", true)
addEvent ("onClientMapList", true)
addEvent ("onMapListReq", true)
addEvent ("onChangeMapReq", true)

---------------
-- Functions --
---------------

local function init()
	if(g_Initialized) then return end
	g_Initialized = true
	
	local mapManagerRes = getResourceFromName("mapmanager")
	if(not mapManagerRes or getResourceState(mapManagerRes) ~= "running") then
		return false
	end
	
	local mapRes = call(mapManagerRes, "getRunningGamemodeMap")
	g_CurrentMap = mapRes and Map.create(mapRes)
	g_LastMap = g_CurrentMap
	g_MapRepeats = 1
	g_IsRace = g_CurrentMap and #(g_CurrentMap:getElements("checkpoint")) > 0
end

function findMap (str, removed)
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
		local rows = DbQuery ("SELECT removed FROM rafalh_maps WHERE map=? LIMIT 1", map:getId())
		if (rows[1].removed == "") then
			break
		end
		maps:remove(i)
		local i = math.random (1, maps:getCount())
	end
	
	if (maps:getCount() == 0) then
		outputDebugString("Failed to get random map!", 1)
		return false
	end
	
	return map
end

local function getActivePlayers (ignore)
	local active = {}
	for i, player in ipairs (getAlivePlayers ()) do
		if (not isPedDead (player) and player ~= ignore) then
			table.insert (active, player)
		end
	end
	return active
end

function startRandomMap()
	local map = MqPop()
	if(map) then
		g_StartingQueuedMap = map
	else
		map = getRandomMap()
	end
	map:start()
end

local function onGamemodeMapStart(map_res)
	local map = Map.create(map_res)
	local map_id = map:getId()
	local rows = DbQuery ("SELECT played, rates, rates_count, removed FROM rafalh_maps WHERE map=? LIMIT 1", map_id)
	local map_name = map:getName()
	
	if (g_LastMap == map) then
		g_MapRepeats = g_MapRepeats + 1
	else
		g_LastMap = map
		g_MapRepeats = 1
	end
	g_CurrentMap = map
	
	if (rows[1].removed ~= "") then
		scriptMsg ("Map %s is removed! Changing to random map.", map_name)
		--cancelEvent () -- map resource is still running
		setMapTimer(startRandomMap, 500, 1)
	else
		g_IsRace = #(map:getElements("checkpoint")) > 0
		local map_type = map:getType()
		
		local now = getRealTime().timestamp
		DbQuery ("UPDATE rafalh_maps SET played=played+1, played_timestamp=? WHERE map=?", now, map_id)
		
		local was_queued = (g_StartingQueuedMap == map)
		g_StartingQueuedMap = false
		
		-- output map name to console so players can easly copy the name to clipboard
		outputConsole ("Map "..map_name.." started"..(was_queued and " (queued)" or "")..".")
		
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
			outputDebugString (dbg_buf, 3)
		end
		
		-- show toptimes
		BtSendMapInfo (true)
		
		-- init some players data
		for player, pdata in pairs (g_Players) do
			pdata.cp_times = SmGetBool ("cp_recorder") and g_IsRace and {}
			pdata.winner = false
		end
		
		-- start recording
		local winning_veh = map_type and map_type.winning_veh
		g_Recording = (g_IsRace or winning_veh) and SmGetBool ("recorder")
		if (g_IsRace or winning_veh) then
			if (g_Recording) then
				RcStartRecording (map_id)
			end
		end
		
		-- set fps limit
		local maxFps = map_type and map_type.max_fps
		if(maxFps) then
			setFPSLimit(maxFps)
		end
		
		-- check if ghostmode should be enabled
		if (not map:getSetting("ghostmode")) then
			local gm = map_type and map_type.gm
			--outputDebugString("Map has no ghostmode specified. Changing to "..tostring(gm), 3)
			setMapTimer (GmSet, 3000, 1, gm, true)
		end
		
		-- show best times
		BtPrintTimes(map_id)
		
		-- allow bets
		GbStartBets ()
	end
end

local function onGamemodeMapStop (map)
	if (g_Recording) then
		g_Recording = false
		RcStopRecording ()
	end
	
	GbFinishBets ()
	
	if (g_OldVehicleWeapons) then
		set ("*race.vehicleweapons", g_OldVehicleWeapons)
		g_OldVehicleWeapons = nil
	end
	
	g_CurrentMap = false
end

local function handlePlayerTime (player, ms)
	local map = getCurrentMap()
	local default_speed = tonumber(map:getSetting("gamespeed")) or 1
	local speed = getGameSpeed ()
	if(math.abs(speed - default_speed) > 0.001) then
		outputDebugString("Invalid game speed (default: "..default_speed..", current: "..speed..")", 3)
		return 0
	end
	
	local map_id = map:getId()
	local n = addPlayerTime (g_Players[player].id, map_id, ms)
	if (n >= 1) then -- improved best time
		privMsg (player, "You have improved your personal best time! New: %s", formatTimePeriod (ms / 1000))
		
		if (n <= 3) then -- new toptime
			local th = ({ "st", "nd", "rd" })[n]
			scriptMsg ("The %s top time: %s by %s!", n..th, formatTimePeriod (ms / 1000), getPlayerName (player))
			
			local award = 30000 / n
			local cash = StGet (player, "cash") + award
			StSet (player, "cash", cash)
			privMsg (player, "%s added to your cash! Total: %s.", formatMoney (award), formatMoney (cash))
		end
		
		if (n <= 8) then
			BtSendMapInfo (true)
		end
	end
	
	return n
end

local function handlePlayerWin (player)
	scriptMsg ("%s is the winner!", getPlayerName (player))
	
	GbFinishBets (player)
	
	if (g_WinningStreakPlayer == player) then
		g_WinningStreakLen = g_WinningStreakLen + 1
		if (g_PlayersCount > 1) then
			scriptMsg ("%s is on a winning streak! It's his %u. victory.", getPlayerName (player), g_WinningStreakLen)
		end
	else
		g_WinningStreakPlayer = player
		g_WinningStreakLen = 1
	end
end

local function setPlayerFinalRank (player, rank)
	local cashadd = math.floor (1000 * g_PlayersCount / rank)
	local pointsadd = math.floor (g_PlayersCount / rank)
	
	local stats = StGet (player, { "cash", "points" })
	stats.cash = stats.cash + cashadd
	stats.points = stats.points + pointsadd
	StSet (player, stats)
	privMsg (player, "%s added to your cash! Total: %s.", formatMoney (cashadd), formatMoney (stats.cash))
	privMsg (player, "You earned %s points. Total: %s.", formatNumber (pointsadd), formatNumber (stats.points))
	
	if (rank == 1) then
		handlePlayerWin (player)
	end
end

local function onPlayerFinish (rank, ms)
	local map = getCurrentMap()
	local map_id = map:getId()
	
	if (rank <= 3) then
		local rank_str = ({ "first", "second", "third" })[rank]
		local val = StGet (source, rank_str) + 1
		StSet (source, rank_str, val)
	end
	
	--local rows = DbQuery ("SELECT time FROM rafalh_besttimes WHERE map=? ORDER BY time LIMIT 1", map_id)
	--scriptMsg (rank..th.." "..getPlayerName (source).." - "..formatTimePeriod (ms / 1000)..((rows and rows[1] and rows[1].time < ms and " (+"..formatTimePeriod ((ms - rows[1].time) / 1000)..")") or ""))
	
	local n = handlePlayerTime (source, ms)
	
	RcFinishRecordingPlayer (source, ms, map_id, n >= 1)
	
	setPlayerFinalRank (source, rank)
end

local function onPlayerWinDD ()
	local dm_wins = StGet (source, "dm_wins") + 1
	StSet (source, "dm_wins", dm_wins)
	
	--local game_weight = 0.007 * g_PlayersCount / 32
	
	for player, pdata in pairs (g_Players) do
		local dm_count = StGet (player, "dm") + 1
		StSet (player, "dm", dm_count)
		
		--local efectiveness_dd = StGet (player, "efectiveness_dd")
		--local rank = (player == source) and 1 or g_PlayersCount
		--efectiveness_dd = efectiveness_dd * (1 - game_weight) + (rank - 1) / g_PlayersCount * game_weight
		--StSet (player, "efectiveness_dd", efectiveness_dd)
	end
	
	setPlayerFinalRank (source, 1)
end

local function onPlayerPickUpRacePickup (pickupID, pickupType, vehicleModel)
	local map = getCurrentMap()
	local mapType = map and map:getType()
	
	if (pickupType == "vehiclechange" and mapType and mapType.winning_veh and vehicleModel and mapType.winning_veh[vehicleModel] and not g_Players[source].winner) then
		g_Players[source].winner = true
		scriptMsg ("Warning! %s has been given to %s.", getVehicleNameFromModel (vehicleModel), getPlayerName (source))
		if (GmIsEnabled ()) then
			GmSet (false)
		end
		
		local race_res = getResourceFromName ("race")
		local ms = race_res and call (race_res, "getTimePassed")
		if (ms) then
			local n = handlePlayerTime (source, ms)
			
			RcFinishRecordingPlayer (source, ms, map_id, n >= 1)
		end
	end
end

local function onMapListReq()
	local map_list = {}
	local maps = getMapsList()
	
	for i, map in maps:ipairs() do
		local map_res_name = getResourceName (map.res)
		local map_name = map:getName()
		map_list[map_res_name] = { map_name, 0, 0 }
	end
	
	local rows = DbQuery ("SELECT * FROM rafalh_maps", map)
	for i, data in ipairs (rows) do
		if (map_list[data.name]) then
			map_list[data.name][2] = data.played
			if (data.rates_count > 0) then
				map_list[data.name][3] = data.rates / data.rates_count
			end
		end
	end
	
	triggerClientEvent (client, "onClientMapList", g_ResRoot, map_list)
end

local function onChangeMapReq(map_res_name)
	if (not hasObjectPermissionTo (client, "command.setmap", false)) then return end
	
	local map_res = getResourceFromName (map_res_name)
	if (map_res) then
		GbCancelBets ()
		Map.create(map_res):start()
	else
		outputDebugString ("getResourceFromName failed", 2)
	end
end

function getCurrentMap()
	if(not g_Initialized) then init() end
	return g_CurrentMap
end

function getLastMap()
	if(not g_Initialized) then init() end
	return g_LastMap
end

function getMapsList()
	local mapManagerRes = getResourceFromName("mapmanager")
	if(not mapManagerRes or getResourceState(mapManagerRes) ~= "running") then
		return false
	end
	
	local gamemodeRes = call(mapManagerRes, "getRunningGamemode")
	local mapResList = call(mapManagerRes, "getMapsCompatibleWithGamemode", gamemodeRes)
	return MapList.create(mapResList)
end

addEventHandler ("onGamemodeMapStart", g_Root, onGamemodeMapStart)
addEventHandler ("onGamemodeMapStop", g_Root, onGamemodeMapStop)
addEventHandler ("onPlayerFinish", g_Root, onPlayerFinish)
addEventHandler ("onPlayerWinDD", g_Root, onPlayerWinDD)
addEventHandler ("onPlayerPickUpRacePickup", g_Root, onPlayerPickUpRacePickup)
addEventHandler ("onMapListReq", g_ResRoot, onMapListReq)
addEventHandler ("onChangeMapReq", g_ResRoot, onChangeMapReq)
addEventHandler ("onResourceStart", g_ResRoot, init)
