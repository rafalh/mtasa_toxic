function getMaps ( map, order, desc, limit, start )
	-- Validate parameters
	limit = math.min ( touint ( limit, 20 ), 20 )
	start = touint ( start )
	if ( order and not tostring ( order ):match ( '^[%l_/%*%+-]+$' ) ) then -- check validity of arguments
		return false
	end
	if ( order == 'rating' ) then
		order = 'rates/max(rates_count, 1)'
	end
	
	-- Build query
	local where = ''
	if ( map ) then
		local map_id = touint ( map )
		if ( map_id ) then
			where = ' WHERE map='..map_id
		else
			local pattern = tostring ( map ):gsub ( ' ', '%%' )
			where = ' WHERE name LIKE '..DbStr ( '%'..pattern..'%' )
		end
	end
	
	local rows = DbQuery ( 'SELECT COUNT(*) AS c FROM '..MapsTable..where )
	local maps_count = rows[1].c
	
	local query = 'SELECT map, name, played, rates, rates_count FROM '..MapsTable..where
	if ( order ) then
		query = query..' ORDER BY '..tostring ( order )..( ( desc and ' DESC' ) or '' )
	end
	
	query = query..' LIMIT '
	if ( start ) then
		query = query..start..','
	end
	query = query..limit
	
	-- Query database
	local rows = DbQuery ( query )
	for i, data in ipairs ( rows ) do
		local map_res = getResourceFromName ( data.name )
		local map = map_res and Map.create(map_res)
		data.name = map and map:getName()
		data.author = map and map:getInfo('author')
	end
	
	return rows, maps_count
end

function getMapInfo(mapId)
	mapId = tonumber(mapId)
	if(not mapId) then return false end
	
	local rows = DbQuery('SELECT * FROM '..MapsTable..' WHERE map=?', mapId)
	local data = rows and rows[1]
	if(not data) then return false end
	
	local mapRes = getResourceFromName(data.name)
	if(mapRes) then
		data.name = getResourceInfo(mapRes, 'name')
		data.author = getResourceInfo(mapRes, 'author')
	end
	
	local rows = DbQuery('SELECT bt.player, bt.time, p.name FROM '..BestTimesTable..' bt, '..PlayersTable..' p WHERE bt.map=? AND p.player=bt.player ORDER BY bt.time LIMIT 8', mapId)
	if(rows) then
		for i, data in ipairs(rows) do
			data.name = data.name:gsub('#%x%x%x%x%x%x', '')
		end
		data.toptimes = rows
	end
	
	return data
end
