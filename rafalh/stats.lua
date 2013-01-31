local g_Ranks = {}
local g_Stats = {
	"cash", "points",
	"mapsPlayed", "mapsBought", "mapsRated",
	"dmVictories", "huntersTaken", "dmPlayed",
	"ddVictories", "ddPlayed",
	"raceVictories", "racesFinished", "racesPlayed",
	"maxWinStreak", "toptimes_count",
	"bidlvl", "time_here", "exploded", "drowned"}

function StGet ( player_id, name )
	assert ( name )
	
	local player, pdata = false, false
	if ( isElement ( player_id ) ) then
		player = player_id
		pdata = g_Players[player]
		player_id = pdata.id
	else
		player = g_IdToPlayer[player_id]
		if ( player ) then
			pdata = g_Players[player]
		end
	end
	
	local stats = {}
	local keys = name
	if ( type ( keys ) ~= "table" ) then
		keys = { name }
	end
	
	local keys2 = {}
	if ( player ) then
		for i, key in ipairs ( keys ) do
			if ( pdata.stats[key] ) then
				stats[key] = pdata.stats[key]
			else
				table.insert ( keys2, key )
			end
		end
	else
		keys2 = keys
	end
	
	if(#keys2 > 0) then
		local rows = DbQuery("SELECT "..table.concat(keys2, ",").." FROM rafalh_players WHERE player=? LIMIT 1", player_id)
		assert(rows and rows[1])
		if(not rows or not rows[1]) then
			outputDebugString("StGet: wrong column "..table.concat(keys2, ",").." for "..tostring(player_id), 1)
		end
		for k, v in pairs(rows[1]) do
			stats[k] = v
			if(pdata) then
				pdata.stats[k] = v
			end
		end
	end
	
	if ( type ( name ) == "table" ) then
		return stats
	else
		return stats[name]
	end
end

function StSet ( player_id, name, value )
	assert ( player_id and name )
	
	local player, pdata = false, false
	if ( isElement ( player_id ) ) then
		player = player_id
		pdata = g_Players[player]
		player_id = pdata.id
	else
		player = g_IdToPlayer[player_id]
		if ( player ) then
			pdata = g_Players[player]
		end
	end
	
	local stats = name
	if(type ( stats ) ~= "table") then
		assert ( value )
		stats = { [name] = value }
	end
	
	local old_rank = false
	if ( player and stats.points ) then
		old_rank = StRankFromPoints ( StGet ( player, "points" ) )
	end
	
	local set = ""
	local params = {}
	for k, v in pairs(stats) do
		if(v ~= nil) then
			set = set..","..k.."=?"
			table.insert ( params, v )
			if(pdata) then
				pdata.stats[k] = v
			end
		else
			outputDebugString("Tried to set "..k.." to nil", 1)
		end
	end
	
	-- Add player ID at the end of parameters table. Note: we can't use it when calling DbQuery
	-- because unpack has to be on the last place. If it's not only one element from table is used.
	table.insert(params, player_id)
	
	DbQuery("UPDATE rafalh_players SET "..set:sub(2).." WHERE player=?", unpack(params))
	
	if(player and stats.points) then
		setPlayerAnnounceValue(player, "score", tostring(stats.points))
		
		local new_rank = StRankFromPoints(stats.points)
		if(new_rank ~= old_rank) then
			customMsg(255, 255, 255, "%s has new rank: %s!", getPlayerName(player), new_rank)
		end
	end
	
	if(player) then
		AchvCheckPlayer(player)
	end
	
	notifySyncerChange("stats", player_id)
end

function StAdd(player_id, name, n)
	StSet(player_id, name, StGet(player_id, name) + n)
end

function StRankFromPoints(points)
	local pt = -1
	local rank = nil
	
	for pt_i, rank_i in pairs(g_Ranks) do
		if(pt_i > pt and pt_i <= points) then
			rank = rank_i
			pt = pt_i
		end
	end
	
	return rank or "none"
end

local function StPlayerStatsSyncCallback ( id )
	id = touint(id)
	if(id) then
		local fields = table.copy(g_Stats)
		table.insert(fields, "name")
		
		local data = StGet(id, fields)
		if(data) then
			data._rank = StRankFromPoints(data.points)
			local player = g_IdToPlayer[id]
			if(player) then
				data._join_time = g_Players[player].join_time
			end
			data.name = data.name:gsub("#%x%x%x%x%x%x", "")
			return data
		end
	end
	
	return false
end

local function StInit ()
	local node, i = xmlLoadFile("conf/ranks.xml"), 0
	if(node) then
		while(true) do
			local subnode = xmlFindChild(node, "rank", i)
			if(not subnode) then break end
			i = i + 1
			
			local pts = touint(xmlNodeGetAttribute(subnode, "points" ), 0)
			local name = xmlNodeGetAttribute(subnode, "name")
			assert(name)
			g_Ranks[pts] = name
		end
		xmlUnloadFile(node)
	end
	
	local idTbl = {}
	for player, pdata in pairs(g_Players) do
		pdata.stats = {}
		table.insert(idTbl, pdata.id)
	end
	local idStr = table.concat(idTbl, ",")
	DbQuery("UPDATE rafalh_players SET online=1 WHERE player IN (??)", idStr)
	
	local fields = table.concat(g_Stats, ",")
	local rows = DbQuery("SELECT player, "..fields.." FROM rafalh_players WHERE player IN (??)", idStr)
	for i, data in ipairs(rows) do
		local player = g_IdToPlayer[data.player]
		local pdata = g_Players[player]
		for i, field in ipairs(g_Stats) do
			pdata.stats[field] = data[field]
		end
		
		if(not pdata.is_console) then
			setPlayerAnnounceValue(player, "score", tostring(data.points))
		end
	end
	
	addSyncer("stats", StPlayerStatsSyncCallback)
end

local function StCleanupPlayer(player)
	local pdata = g_Players[player]
	local now = getRealTime().timestamp
	local timeSpent = now - pdata.join_time
	local playTime = StGet(player, "time_here") + timeSpent
	pdata.join_time = now
	StSet(player, {time_here = playTime, online = 0, last_visit = now})
end

local function StCleanup()
	for player, pdata in pairs(g_Players) do
		StCleanupPlayer(player)
	end
end

local function StOnPlayerJoin()
	local pdata = g_Players[source]
	
	local fields = table.concat(g_Stats, ",")
	local rows = DbQuery("SELECT "..fields.." FROM rafalh_players WHERE player=?", pdata.id)
	pdata.stats = rows[1]
	assert(pdata.stats)
	
	setPlayerAnnounceValue(source, "score", tostring(pdata.stats.points))
	DbQuery("UPDATE rafalh_players SET online=1 WHERE player=?", pdata.id)
end

local function StOnPlayerConnect(playerNick, playerIP, playerUsername, playerSerial)
	local max_warns = SmGetUInt("max_warns", 0)
	if(max_warns > 0) then
		local rows = DbQuery("SELECT warnings FROM rafalh_players WHERE serial=? LIMIT 1", playerSerial)
		local data = rows and rows[1]
		if(data and data.warnings > max_warns) then
			cancelEvent(true, "You have "..data.warnings.." warnings (limit: "..max_warns..")!")
		end
	end
end

local function StOnPlayerQuit()
	StCleanupPlayer(source)
end

local function StOnPlayerWasted(totalAmmo, killer, weapon)
	if(wasEventCancelled()) then return end
	
	if(weapon == 53 and g_Players[source]) then -- drowned
		StAdd(source, "drowned", 1)
	end
end

local function StOnVehicleExplode()
	if(wasEventCancelled()) then return end
	
	local player = getVehicleOccupant(source)
	-- Note: Blow in Admin Panel generates two onVehicleExplode but only one has health > 0
	if(player and g_Players[player] and getElementHealth(source) > 0) then
		StAdd(player, "exploded", 1)
	end
end

addEventHandler("onResourceStart", g_ResRoot, StInit)
addEventHandler("onResourceStop", g_ResRoot, StCleanup)
addEventHandler("onPlayerConnect", g_Root, StOnPlayerConnect)
addEventHandler("onPlayerJoin", g_Root, StOnPlayerJoin)
addEventHandler("onPlayerQuit", g_Root, StOnPlayerQuit)
addEventHandler("onPlayerWasted", g_Root, StOnPlayerWasted)
addEventHandler("onVehicleExplode", g_Root, StOnVehicleExplode)
