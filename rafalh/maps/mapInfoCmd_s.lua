local function CmdRespawn(message, arg)
	local room = g_Players[source].room
	local map = getCurrentMap(room)
	if(#arg >= 2) then
		map = findMap(message:sub(arg[1]:len() + 2))
	end
	
	if(map) then
		local rs = map:getSetting("respawn") or get("race.respawnmode")
		local rstime = map:getSetting("respawntime") or get("race.respawntime")
		if(rs == "none") then
			scriptMsg("Respawn is disabled.")
		else
			scriptMsg("Respawn is enabled (%u seconds).", rstime or 10)
		end
	else
		privMsg(source, "Cannot find map!")
	end
end

CmdRegister("respawn", CmdRespawn, false, "Checks if current map supports respawn")
CmdRegisterAlias("rs", "respawn")

local function CmdMapInfo(message, arg)
	local map
	if(#arg >= 2) then
		map = findMap(message:sub(arg[1]:len() + 2))
	else
		local room = g_Players[source].room
		map = getCurrentMap(room)
	end
	
	if(map) then
		local map_name = map:getName()
		local map_id = map:getId()
		local rows = DbQuery("SELECT played, rates, rates_count, removed FROM rafalh_maps WHERE map=? LIMIT 1", map_id)
		local rating = rows[1].rates_count > 0 and(("%.1f"):format(rows[1].rates/rows[1].rates_count)) or 0
		
		scriptMsg("Map name: %s - Played: %u - Rating: %.1f (rated by %u players)%s",
			map_name, rows[1].played, rating, rows[1].rates_count, rows[1].removed ~= "" and " - Removed: "..rows[1].removed or "")
	else
		privMsg(source, "Cannot find map!")
	end
end

CmdRegister("mapinfo", CmdMapInfo, false, "Displays information about current map")

local function CmdRace(message, arg)
	local room = g_Players[source].room
	local map = getCurrentMap(room)
	
	if(map) then
		local map_name = map:getName()
		local author = map:getInfo("author")
		
		if(author) then
			scriptMsg("Map %s made by %s.", map_name, author)
		else
			scriptMsg("Map %s.", map_name)
		end
	end
end

CmdRegister("race", CmdRace, false)
CmdRegisterAlias("creator", "race")

local function CmdMaps(message, arg)
	local maps = getMapsList()
	scriptMsg("Total maps count: %u.", maps:getCount())
end

CmdRegister("maps", CmdMaps, false, "Shows maps count")

local function CmdMapStats(message, arg)
	local rows = DbQuery("SELECT * FROM rafalh_maps")
	local maps_data = {}
	for i, data in ipairs(rows) do
		maps_data[data.map] = data
	end
	
	local maps = getMapsList()
	local map_type_stats = {}
	for i, map in maps:ipairs() do
		local map_name = map:getName()
		local map_type = map:getType()
		assert(map_type)
		
		local stats = map_type_stats[map_type]
		if(not stats) then
			stats = { count = 0, removed = 0, rates = 0, rates_count = 0, played = 0 }
			map_type_stats[map_type] = stats
		end
		
		stats.count = stats.count + 1
		local map_id = map:getId()
		if(maps_data[map_id]) then
			if(maps_data[map_id].removed ~= "") then
				stats.removed = stats.removed + 1
			end
			stats.rates = stats.rates + maps_data[map_id].rates
			stats.rates_count = stats.rates_count + maps_data[map_id].rates_count
			stats.played = stats.played + maps_data[map_id].played
		end
	end
	scriptMsg("Total maps count: %u", #maps)
	for map_type, stats in pairs(map_type_stats) do
		local rating = 0
		if(stats.rates_count > 0) then
			rating = stats.rates / stats.rates_count
		end
		
		scriptMsg(map_type.name.." - count: %u - played: %u - removed: %u - rating: %s",
			stats.count, stats.played, stats.removed, formatNumber(rating, 1))
	end
end

CmdRegister("mapstats", CmdMapStats, false, "Shows statistics for each map type")

local function CmdPlayed(message, arg)
	local room = g_Players[source].room
	local map = getCurrentMap(room)
	
	if(map) then
		local map_id = map:getId()
		local rows = DbQuery("SELECT played FROM rafalh_maps WHERE map=? LIMIT 1", map_id)
		local map_name = map:getName()
		
		scriptMsg("Map %s played %u times.", map_name, rows[1].played)
	end
end

CmdRegister("played", CmdPlayed, false, "Shows how many times map was played")

local function CmdCheckMap(message, arg)
	local str = message:sub(arg[1]:len() + 2)
	if(str:len() >= 3) then
		local maps = getMapsList()
		local buf = ""
		local pattern = str:lower()
		for i, map in maps:ipairs() do
			local map_name = map:getName()
			
			if(map_name:lower():find(pattern, 1, true)) then
				buf = buf..((buf ~= "" and ", ") or "")..map_name
				local map_id = map:getId()
				local data = DbQuery("SELECT removed FROM rafalh_maps WHERE map=? LIMIT 1", map_id)
				
				if(data[1].removed ~= "") then
					buf = buf.." (removed)"
				end
				
				if(buf:len() > 256) then
					buf = buf..", .." --third point will be added letter
					break
				end
			end
		end
		if(buf == "") then
			scriptMsg("Maps not found for \"%s\".", str)
		else
			scriptMsg("Found maps: %s.", buf)
		end
	else
		privMsg(source, "Usage: %s", arg[1].." <text>")
		privMsg(source, "Specify at least 3 characters.")
	end
end

CmdRegister("checkmap", CmdCheckMap, false, "Searches for a map with specified name")
CmdRegisterAlias("check", "checkmap")

local function CmdNextMapQueue(message, arg)
	local queue = ""
	local room = g_Players[source].room
	if(room.mapQueue and #room.mapQueue > 0) then
		for i, map in ipairs(room.mapQueue) do
			local mapName = map:getName()
			queue = queue..", "..i..". "..mapName
		end
		queue = queue:sub(3)
	else
		queue = "empty"
	end
	privMsg(source, "Next map queue: %s.", queue)
end

CmdRegister("mapqueue", CmdNextMapQueue, false, "Displays next map queue")
CmdRegisterAlias("nextmapqueue", "mapqueue")
CmdRegisterAlias("queue", "mapqueue")

local function CmdMapId(message, arg)
	local room = g_Players[source].room
	local map = getCurrentMap(room)
	scriptMsg("Map ID: %u", map:getId())
end

CmdRegister("mapid", CmdMapId, true)
