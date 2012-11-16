local g_Ranks = {}
--[[local g_StatsSync = {}

addEvent ( "onPlayerStatsReq", true )
addEvent ( "onClientPlayerStats", true )
addEvent ( "onTopReq", true )
addEvent ( "onClientTop", true )]]

local function StPlayerStatsSyncCallback ( id )
	id = touint ( id )
	if ( id ) then
		local rows = DbQuery ( "SELECT name, cash, points, first, second, third, dm, dm_wins, toptimes_count, bidlvl, time_here, exploded, drowned FROM rafalh_players WHERE player=?", id )
		if ( rows and rows[1] ) then
			rows[1]._rank = StRankFromPoints ( rows[1].points )
			local player = g_IdToPlayer[id]
			if ( player ) then
				rows[1]._join_time = g_Players[player].join_time
			end
			return rows[1]
		end
	end
	
	return false
end

local function StTopSyncCallback ( toptype )
	toptype = toint ( toptype )
	local top_fields = { "cash", "points", "first", "second", "third", "dm", "dm_wins", "bidlvl" }
	local field = toptype and top_fields[math.abs ( toptype )]
	
	if ( field ) then
		local query = "SELECT player AS id, name, "..field.." FROM rafalh_players WHERE serial<>'0'"
		if ( toptype > 0 ) then
			query = query.." AND online=1"
		end
		query = query.." ORDER BY "..field.." DESC LIMIT 18"
		return DbQuery ( query )
	end
	
	return false
end

local function StInit ()
	local node, i = xmlLoadFile ( "conf/ranks.xml" ), 0
	if ( node ) then
		while ( true ) do
			local subnode = xmlFindChild ( node, "rank", i )
			if ( not subnode ) then break end
			i = i + 1
			
			local pts = touint ( xmlNodeGetAttribute ( subnode, "points" ), 0 )
			local name = xmlNodeGetAttribute ( subnode, "name" )
			assert ( name )
			g_Ranks[pts] = name
		end
		xmlUnloadFile ( node )
	end
	
	for player, pdata in pairs ( g_Players ) do
		if ( not pdata.is_console ) then
			local rows = DbQuery ( "SELECT points FROM rafalh_players WHERE player=?", pdata.id )
			setPlayerAnnounceValue ( player, "score", tostring ( rows[1].points ) )
			DbQuery ( "UPDATE rafalh_players SET online=1 WHERE player=?", pdata.id )
		end
	end
	
	addSyncer ( "stats", StPlayerStatsSyncCallback )
	
	addSyncer ( "tops", StTopSyncCallback, true )
end

local function StCleanupPlayer ( player )
	local pdata = g_Players[player]
	local timestamp = getRealTime ().timestamp
	local add_timehere = timestamp - pdata.join_time
	DbQuery ( "UPDATE rafalh_players SET time_here=time_here+"..add_timehere..", last_visit=?, online=0 WHERE player=?", timestamp, pdata.id )
	pdata.join_time = timestamp
end

local function StCleanup ()
	for player, pdata in pairs ( g_Players ) do
		StCleanupPlayer ( player )
	end
end

function StRankFromPoints ( points )
	local pt = -1
	local rank = nil
	
	for pt_i, rank_i in pairs ( g_Ranks ) do
		if ( pt_i > pt and pt_i <= points ) then
			rank = rank_i
			pt = pt_i
		end
	end
	
	return rank or "none"
end

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
		if ( not pdata.stats ) then
			pdata.stats = {}
		end
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
	
	if ( #keys2 > 0 ) then
		local rows = DbQuery ( "SELECT "..table.concat ( keys2, "," ).." FROM rafalh_players WHERE player=? LIMIT 1", player_id )
		if ( not rows or not rows[1] ) then
			outputDebugString ( "StGet: wrong column "..table.concat ( keys2, "," ).." for "..tostring ( player_id ), 1 )
		end
		for k, v in pairs ( rows[1] ) do
			stats[k] = v
			if ( pdata ) then
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
	if ( type ( stats ) ~= "table" ) then
		assert ( value )
		stats = { [name] = value }
	end
	
	local old_rank = false
	if ( player and stats.points ) then
		old_rank = StRankFromPoints ( StGet ( player, "points" ) )
	end
	
	if ( pdata and not pdata.stats ) then
		pdata.stats = {}
	end
	
	local set = ""
	local params = {}
	for k, v in pairs ( stats ) do
		if ( v ~= nil ) then
			set = set..","..k.."=?"
			table.insert ( params, v )
			if ( pdata ) then
				pdata.stats[k] = v
			end
		else
			outputDebugString ( "Tried to set "..k.." to nil", 1 )
		end
	end
	
	-- Add player ID at the end of parameters table. Note: we can't use it when calling DbQuery
	-- because unpack has to be on the last place. If it's not only one element from table is used.
	table.insert ( params, player_id )
	
	DbQuery ( "UPDATE rafalh_players SET "..set:sub ( 2 ).." WHERE player=?", unpack ( params ) )
	
	if ( player and stats.points ) then
		setPlayerAnnounceValue ( player, "score", tostring ( stats.points ) )
		
		local new_rank = StRankFromPoints ( stats.points )
		if ( new_rank ~= old_rank ) then
			customMsg ( 255, 255, 255, "%s has new rank: %s!", getPlayerName ( player ), new_rank )
		end
	end
	
	notifySyncerChange ( "stats", player_id )
end

local function StOnPlayerConnect ( playerNick, playerIP, playerUsername, playerSerial )
	local max_warns = SmGetUInt ( "max_warns", 0 )
	if ( max_warns > 0 ) then
		local rows = DbQuery ( "SELECT warnings FROM rafalh_players WHERE serial=? LIMIT 1", playerSerial )
		if ( rows[1] and rows[1].warnings > max_warns ) then
			cancelEvent ( true, "You have "..rows[1].warnings.." warnings (limit: "..max_warns..")!" )
		end
	end
end

local function StOnPlayerQuit ()
	StCleanupPlayer ( source )
end

local function StOnPlayerWasted ( totalAmmo, killer, weapon )
	if ( wasEventCancelled () ) then return end
	
	if ( weapon == 53 and g_Players[source] ) then -- drowned
		local drowned = StGet ( source, "drowned" ) + 1
		StSet ( source, "drowned", drowned )
	end
end

local function StOnVehicleExplode ()
	if ( wasEventCancelled () ) then return end
	
	local player = getVehicleOccupant ( source )
	-- Note: Blow in Admin Panel generates two onVehicleExplode but only one has health > 0
	if ( player and g_Players[player] and getElementHealth ( source ) > 0 ) then
		local exploded = StGet ( player, "exploded" ) + 1
		StSet ( player, "exploded", exploded )
	end
end

--[[local function StOnPlayerStatsReq ( id, sync )
	id = touint ( id )
	if ( id ) then
		local rows = DbQuery ( "SELECT cash, points, first, second, third, dm, dm_wins, toptimes_count, bidlvl, time_here, exploded, drowned FROM rafalh_players WHERE player=?", id )
		if ( rows and rows[1] ) then
			triggerClientEvent ( client, "onClientPlayerStats", g_ResRoot, id, rows[1] )
		end
		if ( sync ) then
			if ( not g_StatsSync[id] ) then
				g_StatsSync[id] = {}
			end
			g_StatsSync[id].c = 1
			g_StatsSync[id][client] = true
		elseif ( g_StatsSync[id] and g_StatsSync[id][client] ) then
			g_StatsSync[id].c = g_StatsSync[id].c - 1
			g_StatsSync[id][client] = nil
			if ( g_StatsSync[id].c <= 0 ) then
				g_StatsSync[id] = nil
			end
		end
	end
end

local function StOnTopReq ( top_type, online )
	local top_fields = { "cash", "points", "first", "second", "third", "dm", "dm_wins", "bidlvl" }
	local field = top_fields[top_type]
	if ( field ) then
		local query = "SELECT name, "..field.." FROM rafalh_players"
		if ( online ) then
			query = query.." WHERE online=1"
		end
		query = query.." ORDER BY "..field.." DESC LIMIT 8"
		local rows = DbQuery ( query )
		if ( rows and rows[1] ) then
			triggerClientEvent ( client, "onClientTop", g_ResRoot, top_type, rows )
		end
	end
end]]

addEventHandler ( "onResourceStart", g_ResRoot, StInit )
addEventHandler ( "onResourceStop", g_ResRoot, StCleanup )
addEventHandler ( "onPlayerConnect", g_Root, StOnPlayerConnect )
addEventHandler ( "onPlayerQuit", g_Root, StOnPlayerQuit )
addEventHandler ( "onPlayerWasted", g_Root, StOnPlayerWasted )
addEventHandler ( "onVehicleExplode", g_Root, StOnVehicleExplode )
--addEventHandler ( "onPlayerStatsReq", g_ResRoot, StOnPlayerStatsReq )
--addEventHandler ( "onTopReq", g_ResRoot, StOnTopReq )
