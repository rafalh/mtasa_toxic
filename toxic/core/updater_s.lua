local function mergeMaps(mapDst, mapSrc)
	-- Rates
	local rows = DbQuery('SELECT rS.player FROM '..RatesTable..' rS, '..RatesTable..' rD WHERE rS.map=? AND rD.map=? AND rS.player=rD.player', mapSrc, mapDst)
	if(not rows) then return false end
	
	local players = {}
	local questionMarks = {}
	for i, data in ipairs(rows) do
		table.insert(players, data.player)
		table.insert(questionMarks, '?')
	end
	if(#players > 0) then
		local questionMarksStr = table.concat(questionMarks, ',')
		DbQuery('DELETE FROM '..RatesTable..' WHERE map=? AND player IN ('..questionMarksStr..')', mapSrc, unpack(players)) -- remove duplicates
		DbQuery('UPDATE '..PlayersTable..' SET mapsRated=mapsRated-1 WHERE player IN ('..questionMarksStr..')', unpack(players)) -- remove duplicates
		DbQuery('UPDATE '..RatesTable..' SET map=? WHERE map=?', mapDst, mapSrc)
	end
	
	-- Best times
	local rows = DbQuery('SELECT btS.player, btS.time AS timeSrc, btD.time AS timeDst FROM '..BestTimesTable..' btS, '..BestTimesTable..' btD WHERE btS.map=? AND btD.map=? AND btS.player=btD.player', mapSrc, mapDst)
	local playersSrc, playersDst = {}, {}
	local questionMarksSrc, questionMarksDst = {}, {}
	
	for i, data in ipairs(rows) do
		local rows2
		
		if(data.timeSrc < data.timeDst) then -- src besttime is better
			table.insert(playersDst, data.player)
			table.insert(questionMarksDst, '?')
			rows2 = DbQuery('SELECT COUNT(player) AS pos FROM '..BestTimesTable..' WHERE map=? AND time<=?', mapDst, data.timeDst)
		else -- dst besttime is better
			table.insert(playersSrc, data.player)
			table.insert(questionMarksSrc, '?')
			rows2 = DbQuery('SELECT COUNT(player) AS pos FROM '..BestTimesTable..' WHERE map=? AND time<=?', mapSrc, data.timeSrc)
		end
		
		if(rows2[1].pos <= 3) then
			DbQuery('UPDATE '..PlayersTable..' SET toptimes_count=toptimes_count-1 WHERE player=?', data.player)
		end
	end
	if(#playersDst > 0) then
		local questionMarksStr = table.concat(questionMarksDst, ',')
		BtDeleteTimes('map=? AND player IN ('..questionMarksStr..')', mapDst, unpack(playersDst)) -- remove duplicates
	end
	if(#playersSrc > 0) then
		local questionMarksStr = table.concat(questionMarksSrc, ',')
		BtDeleteTimes('map=? AND player IN ('..questionMarksStr..')', mapSrc, unpack(playersSrc)) -- remove duplicates
	end
	DbQuery('UPDATE '..BestTimesTable..' SET map=? WHERE map=?', mapDst, mapSrc) -- set new best times map
	
	-- Map
	local rows = DbQuery('SELECT * FROM '..MapsTable..' WHERE map=?', mapSrc)
	local data = rows and rows[1]
	DbQuery('UPDATE '..MapsTable..' SET '..
		'played=played+?, rates=rates+?, rates_count=rates_count+?, '..
		'played_timestamp=max(played_timestamp, ?), added_timestamp=min(added_timestamp, ?) WHERE map=?',
		data.played, data.rates, data.rates_count, data.played_timestamp, data.added_timestamp, mapDst)
	DbQuery('DELETE FROM '..MapsTable..' WHERE map=?', mapSrc) -- remove map
	return true
end

Updater = {
	currentVer = 159,
	list = {
		{
			ver = 153,
			func = function()
				if(not DbQuery('ALTER TABLE '..MapsTable..' ADD COLUMN patcherSeq SMALLINT NOT NULL DEFAULT 0')) then
					return 'Failed to add patcherSeq column'
				end
				return false
			end
		},
		{
			ver = 154,
			func = function()
				if(not DbQuery('INSERT INTO '..SerialsTable..' (serial) '..
						'SELECT DISTINCT serial '..
						'FROM '..PlayersTable)) then
					return 'Failed to init serials table'
				end

				if(not DbQuery('INSERT INTO '..AliasesTable..' (serial, name) '..
						'SELECT DISTINCT s.id AS serial, n.name '..
						'FROM '..PlayersTable..' p, '..SerialsTable..' s, '..DbPrefix..'names n '..
						'WHERE p.player=n.player AND p.serial=s.serial')) then
					return 'Failed to init aliases table'
				end
				
				if(not DbQuery('DROP TABLE '..DbPrefix..'names')) then
					return 'Failed to delete names table'
				end
				
				return false
			end
		},
		{
			ver = 155,
			func = function()
				if(not DbQuery('DROP INDEX IF EXISTS '..DbPrefix..'rates_idx') or
					not DbQuery('CREATE UNIQUE INDEX '..DbPrefix..'rates_idx ON '..RatesTable..' (map, player)')) then
					return 'Failed to recreate rafalh_rates_idx'
				end
				return false
			end
		},
		{
			ver = 157,
			func = function()
				local rows = DbQuerySync('SELECT m1.map AS map1, m2.map AS map2 FROM '..MapsTable..' m1, '..MapsTable..' m2 WHERE m1.name=m2.name AND m1.map<m2.map')
				for i, row in ipairs(rows) do
					outputDebugString('Merging maps: '..row.map1..' <- '..row.map2, 3)
					if(not mergeMaps(row.map1, row.map2)) then
						return 'Merging maps failed'
					end
					coroutine.yield()
				end
				return false
			end
		},
		{
			ver = 158,
			func = function()
				if(not DbQuerySync('DROP INDEX IF EXISTS '..DbPrefix..'maps_idx') or
					not DbQuerySync('CREATE UNIQUE INDEX '..DbPrefix..'maps_idx ON '..MapsTable..' (name)')) then
					return 'Failed to recreate rafalh_maps_idx'
				end
				return false
			end
		},
		{
			ver = 159,
			func = function()
				if(not DbQuerySync('DROP INDEX IF EXISTS '..DbPrefix..'mutes_idx') or
					not DbQuerySync('CREATE UNIQUE INDEX '..DbPrefix..'mutes_idx ON '..MutesTable..' (serial)')) then
					return 'Failed to recreate rafalh_mutes_idx'
				end
				return false
			end
		},
	}
}
