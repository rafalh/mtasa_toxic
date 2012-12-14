----------------------------------
-- Global functions definitions --
----------------------------------

local function CmdInfo(message, arg)
	--scriptMsg(strGradient("Rafalh[PL] scripts system for Multi Theft Auto.", 0, 255, 0, 255, 255, 0))
	scriptMsg("Rafalh[PL] scripts system for Multi Theft Auto.")
end

-- fixme: doesnt work for console
CmdRegister("info", CmdInfo, false)

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
		
		scriptMsg("Map name: %s - Played: %u - Rating: %.1f(rated by %u players)%s",
			map_name, rows[1].played, rating, rows[1].rates_count, rows[1].removed ~= "" and " - Removed: "..rows[1].removed or "")
	else
		privMsg(source, "Cannot find map!")
	end
end

CmdRegister("mapinfo", CmdMapInfo, false, "Displays information about current map")

local function CmdAlive(message, arg)
	local players = getAlivePlayers()
	local buf = ""
	
	for i, player in ipairs(players) do
		if(not isPedDead(player)) then
			buf = buf..((buf ~= "" and ", "..getPlayerName(player)) or getPlayerName(player))
		end
	end
	scriptMsg("Alive Players: %s.",(buf ~= "" and buf) or "none")
end

CmdRegister("alive", CmdAlive, false, "Shows alive players")
CmdRegisterAlias("a", "alive")

local function CmdAdmins(message, arg)
	local admins = ""
	for i, player in ipairs(getElementsByType("player")) do
		if(isObjectInACLGroup("user."..getAccountName(getPlayerAccount(player)), aclGetGroup("Admin"))) then
			admins = admins..((admins ~= "" and ", ") or "")..getPlayerName(player)
		end
	end
	local super_mods = ""
	for i, player in ipairs(getElementsByType("player")) do
		if(isObjectInACLGroup("user."..getAccountName(getPlayerAccount(player)), aclGetGroup("SuperModerator"))) then
			super_mods = super_mods..((super_mods ~= "" and ", ") or "")..getPlayerName(player)
		end
	end
	local moderators = ""
	for i, player in ipairs(getElementsByType("player")) do
		if(isObjectInACLGroup("user."..getAccountName(getPlayerAccount(player)), aclGetGroup("Moderator"))) then
			moderators = moderators..((moderators ~= "" and ", ") or "")..getPlayerName(player)
		end
	end
	if(admins == "") then
		admins = "none"
	end
	scriptMsg("Current admins: %s.", admins)
	if(super_mods ~= "") then
		scriptMsg("Current super-moderators: %s.", super_mods)
	end
	if(moderators ~= "") then
		scriptMsg("Current moderators: %s.", moderators)
	end
end

CmdRegister("admins", CmdAdmins, false, "Shows admins and moderators playing the game already")

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

local function CmdPlayers(message, arg)
	scriptMsg("Total players count: %u.", g_PlayersCount)
end

CmdRegister("players", CmdPlayers, false, "Shows players count")

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
					buf = buf.."(removed)"
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

local function CmdRate(message, arg)
	local rate = touint(arg[2], 0)
	
	if(rate >= 1 and rate <= 10) then
		RtPlayerRate(rate)
	else
		privMsg(source, "Usage: %s", arg[1].." <1-10>")
	end
end

CmdRegister("rate", CmdRate, false, "Rates current map")

local function CmdRating(message, arg)
	local room = g_Players[source].room
	local map = getCurrentMap(room)
	
	if(map) then
		local map_id = map:getId()
		local map_name = map:getName()
		local rows = DbQuery("SELECT rates, rates_count FROM rafalh_maps WHERE map=? LIMIT 1", map_id)
		local rating = 0
		if(rows[1].rates_count > 0) then
			rating = rows[1].rates / rows[1].rates_count
		end
		
		scriptMsg("Map rating: %.2f(rated by %u players).", rating, rows[1].rates_count)
	end
end

CmdRegister("rating", CmdRating, false, "Checks current map rating")

local function CmdTime(message, arg)
	local tm = getRealTime()
	scriptMsg("Local time: %d-%02d-%02d %d:%02d:%02d.", tm.monthday, tm.month + 1, tm.year + 1900, tm.hour, tm.minute, tm.second)
end

CmdRegister("time", CmdTime, false, "Shows current time")

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

local function CmdAvgPlayers(message, arg)
	scriptMsg("Average players count: %.1f.", SmGetNum("avg_players", 0))
end

CmdRegister("avgplayers", CmdAvgPlayers, false, "Shows avarange players count")

local function CmdCountry(message, arg)
	local player =(#arg >= 2 and findPlayer(message:sub(arg[1]:len() + 2))) or source
	local admin_res = getResourceFromName("admin")
	local country = admin_res and getResourceState(admin_res) == "running" and call(admin_res, "getPlayerCountry", player)
	
	if(g_Countries[country]) then
		country = g_Countries[country]
	end
	
	scriptMsg("%s is from: %s.", getPlayerName(player), country or "unknown country")
end

CmdRegister("country", CmdCountry, false, "Shows player country based on IP")
CmdRegisterAlias("ip2c", "country")

local function CmdVersion(message, arg)
	local player =(#arg >= 2 and findPlayer(message:sub(arg[1]:len() + 2))) or source
	local ver = getPlayerVersion(player)
	
	scriptMsg("%s's MTA version: %s(revision %s).", getPlayerName(player), ver:sub(1, 5), ver:sub(7))
end

CmdRegister("version", CmdVersion, false, "Shows player MTA version")
CmdRegisterAlias("ver", "version")
