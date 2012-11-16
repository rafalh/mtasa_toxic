function getPlayersStats ( player, order, desc, limit, start )
	-- Validate parameters
	limit = math.min ( touint ( limit, 20 ), 20 )
	start = touint ( start )
	if ( order and not tostring ( order ):match ( "^[%l_/%*%+-]+$" ) ) then -- check validity of arguments
		return false
	end
	
	-- Build query
	local where = ""
	if ( player ) then
		local player_id = touint ( player )
		if ( player_id ) then
			where = " WHERE player="..player_id
		else
			where = " WHERE name LIKE "..DbStr ( "%"..tostring ( player ).."%" )
		end
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
	
	local query = "SELECT name, played, rates, rates_count FROM rafalh_maps"..where
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
	end
	
	return rows, maps_count
end
