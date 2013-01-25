function getPlayersStats(player, order, desc, limit, start, online)
	-- Validate parameters
	limit = math.min ( touint ( limit, 20 ), 20 )
	start = touint ( start )
	if ( order and not tostring ( order ):match ( "^[%l_/%*%+-]+$" ) ) then -- check validity of arguments
		return false
	end
	
	-- Build query
	local cond = {"serial<>'0'"}
	local player_id = touint(player)
	if(player_id) then
		table.insert(cond, "player="..player_id)
	elseif(player) then
		table.insert(cond, "name LIKE "..DbStr("%"..tostring(player).."%"))
	end
	if(online) then
		table.insert(cond, "online=1")
	end
	
	local where = ""
	if(#cond > 0) then
		where = " WHERE "..table.concat(cond, " AND ")
	end
	
	local rows = DbQuery ( "SELECT COUNT(*) AS c FROM rafalh_players"..where )
	local players_count = rows[1].c
	
	local query = "SELECT player, cash, points, warnings, dm, dm_wins, first, second, third, time_here, first_visit, last_visit, bidlvl, name, toptimes_count, online, ip FROM rafalh_players"..where
	if ( order ) then
		query = query.." ORDER BY "..tostring ( order )..( ( desc and " DESC" ) or "" )
	end
	query = query.." LIMIT "
	if ( start ) then
		query = query..start..","
	end
	query = query..limit
	
	-- Query database
	local rows = DbQuery ( query )
	if ( rows ) then
		for i, data in ipairs ( rows ) do
			data.rank = StRankFromPoints ( data.points )
			data.name = data.name:gsub("#%x%x%x%x%x%x", "")
		end
	end
	
	return rows, players_count
end

function getPlayerProfile ( player_id )
	-- Validate parameters
	player_id = touint ( player_id )
	if ( not player_id ) then
		return false
	end
	
	-- Query database
	local rows = DbQuery ( "SELECT * FROM rafalh_profiles WHERE player=?", player_id )
	if ( rows ) then
		local result = {}
		
		for i, data in ipairs ( rows ) do
			local prof_field = g_ProfileFields[data.field]
			if ( prof_field ) then
				result[prof_field.longname] = data.value
			end
		end
		
		return result
	end
	
	return false
end

function getMaps ( map, order, desc, limit, start )
	-- Validate parameters
	limit = math.min ( touint ( limit, 20 ), 20 )
	start = touint ( start )
	if ( order and not tostring ( order ):match ( "^[%l_/%*%+-]+$" ) ) then -- check validity of arguments
		return false
	end
	if ( order == "rating" ) then
		order = "rates/max(rates_count, 1)"
	end
	
	-- Build query
	local where = ""
	if ( map ) then
		local map_id = touint ( map )
		if ( map_id ) then
			where = " WHERE map="..map_id
		else
			local pattern = tostring ( map ):gsub ( " ", "%%" )
			where = " WHERE name LIKE "..DbStr ( "%"..pattern.."%" )
		end
	end
	
	local rows = DbQuery ( "SELECT COUNT(*) AS c FROM rafalh_maps"..where )
	local maps_count = rows[1].c
	
	local query = "SELECT map, name, played, rates, rates_count FROM rafalh_maps"..where
	if ( order ) then
		query = query.." ORDER BY "..tostring ( order )..( ( desc and " DESC" ) or "" )
	end
	
	query = query.." LIMIT "
	if ( start ) then
		query = query..start..","
	end
	query = query..limit
	
	-- Query database
	local rows = DbQuery ( query )
	for i, data in ipairs ( rows ) do
		local map_res = getResourceFromName ( data.name )
		local map = map_res and Map.create(map_res)
		data.name = map and map:getName()
		data.author = map:getInfo("author")
	end
	
	return rows, maps_count
end

function getMapInfo(mapId)
	mapId = tonumber(mapId)
	if(not mapId) then return false end
	
	local rows = DbQuery("SELECT * FROM rafalh_maps WHERE map=?", mapId)
	local data = rows and rows[1]
	if(not data) then return false end
	
	local mapRes = getResourceFromName(data.name)
	if(mapRes) then
		data.name = getResourceInfo(mapRes, "name")
		data.author = getResourceInfo(mapRes, "author")
	end
	
	local rows = DbQuery("SELECT bt.player, bt.time, p.name FROM rafalh_besttimes bt, rafalh_players p WHERE bt.map=? AND p.player=bt.player ORDER BY bt.time LIMIT 8", mapId)
	if(rows) then
		for i, data in ipairs(rows) do
			data.name = data.name:gsub("#%x%x%x%x%x%x", "")
		end
		data.toptimes = rows
	end
	
	return data
end

addEvent("main_onPlayersListReq", true)
addEventHandler("main_onPlayersListReq", g_ResRoot, function(...)
	local rows, cnt = getPlayersStats(...)
	triggerClientEvent(client, "main_onPlayersList", g_ResRoot, rows, cnt)
end)

addEvent("main_onPlayerProfileReq", true)
addEventHandler("main_onPlayerProfileReq", g_ResRoot, function(id)
	local data = getPlayerProfile(id)
	triggerClientEvent(client, "main_onPlayerProfile", g_ResRoot, id, data)
end)
