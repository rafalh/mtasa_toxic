
-- Note: '' <> x'' in SQLite

BestTimesTable = Database.Table{
	name = 'besttimes',
	{'player', 'INT UNSIGNED', fk = {'players', 'player'}},
	{'map', 'INT UNSIGNED', fk = {'maps', 'map'}},
	{'time', 'INT UNSIGNED'},
	{'rec', 'INT UNSIGNED', null = true, fk = {'blobs', 'id'}},
	{'cp_times', 'INT UNSIGNED', null = true, fk = {'blobs', 'id'}},
	{'timestamp', 'INT UNSIGNED', null = true},
	{'besttimes_idx', unique = {'map', 'time', 'player'}},
	{'besttimes_idx2', unique = {'map', 'player'}},
}

PlayersTable:addColumns{
	{'toptimes_count', 'SMALLINT UNSIGNED', default = 0},
}

local g_BestTimeCache = {}

function addPlayerTime(playerId, mapId, time)
	local prof = DbgPerf()
	local wasInTop = false
	local now = getRealTime().timestamp
	
	-- Save new time in database
	local personalTop = BtGetPersonalTop(mapId, playerId)
	if(not personalTop) then
		DbQuery('INSERT INTO '..BestTimesTable..' (player, map, time, timestamp) VALUES(?, ?, ?, ?)', playerId, mapId, time, now)
	elseif(personalTop.time < time) then -- new time is worse
		return -1
	else
		local oldPos = BtGetPersonalTop(mapId, playerId, true).pos
		wasInTop = (oldPos <= 3) -- were we in the top?
		
		DbQuery('UPDATE '..BestTimesTable..' SET time=?, timestamp=? WHERE player=? AND map=?', time, now, playerId, mapId)
	end
	
	-- Calculate new player position in Top Times
	local newPos = DbCount(BestTimesTable, 'map=? AND time<=?', mapId, time)
	
	-- Update cache
	local cache = Cache.get('BestTime.m'..mapId..'.Personal')
	cache[playerId] = {time = time, pos = newPos}
	for pid, row in pairs(cache) do
		if(row and row.pos and row.pos >= newPos) then
			row.pos = row.pos + 1
		end
	end
	
	-- Check if player joined the Top
	if(newPos <= 3 and not wasInTop) then
		-- Increment Top Times count
		AccountData.create(playerId):add('toptimes_count', 1)
		
		-- Find player which quit the top
		local besttime4 = DbQuerySingle('SELECT player, rec, cp_times FROM '..BestTimesTable..' WHERE map=? ORDER BY time LIMIT 3,1', mapId)
		if(besttime4) then
			-- Decrement his Top Times count
			AccountData.create(besttime4.player):add('toptimes_count', -1)
			
			-- Forget playback trace and CP times
			DbQuery('UPDATE '..BestTimesTable..' SET rec=NULL, cp_times=NULL WHERE player=? AND map=?', besttime4.player, mapId)
			if(besttime4.rec) then
				DbQuery('DELETE FROM '..BlobsTable..' WHERE id=?', besttime4.rec)
			end
			if(besttime4.cp_times) then
				DbQuery('DELETE FROM '..BlobsTable..' WHERE id=?', besttime4.cp_times)
			end
		end
	end
	
	-- Update Tops Cache
	local topsCache = Cache.get('BestTimes.m'..mapId..'.Tops')
	if(topsCache and newPos <= #topsCache) then
		Cache.remove('BestTimes.m'..mapId..'.Tops')
	end
	
	-- Update Map Info
	MiUpdateTops(mapId)
	
	prof:cp('addPlayerTime')
	return newPos
end

function BtDeleteTimes(cond, ...)
	local rows = DbQuery('SELECT rec, cp_times FROM '..BestTimesTable..' WHERE '..cond, ...)
	local blobs = {}
	for i, row in ipairs(rows) do
		if(row.rec) then
			table.insert(blobs, row.rec)
		end
		if(row.cp_times) then
			table.insert(blobs, row.cp_times)
		end
	end
	
	DbQuery('DELETE FROM '..BestTimesTable..' WHERE '..cond, ...)
	if(#blobs > 0) then
		local blobsStr = table.concat(blobs, ',')
		DbQuery('DELETE FROM '..BlobsTable..' WHERE id IN (??)', blobsStr)
	end
end

function BtGetTops(map, count)
	-- this takes long...
	--local start = getTickCount()
	--for i = 1, 100, 1 do
	local cachedTops = Cache.get('BestTimes.m'..map:getId()..'.Tops')
	if(cachedTops and #cachedTops >= count) then
		return cachedTops
	end
	
	local rows = DbQuery(
		'SELECT bt.player, bt.time, p.name '..
		'FROM '..BestTimesTable..' bt '..
		'INNER JOIN '..PlayersTable..' p ON bt.player=p.player '..
		'WHERE bt.map=? ORDER BY time LIMIT ?', map:getId(), count)
	--end
	for i, data in ipairs(rows) do
		data.time = formatTimePeriod(data.time / 1000)
	end
	
	Cache.set('BestTimes.m'..map:getId()..'.Tops', rows, 300)
	
	--Debug.warn('Toptimes: '..(getTickCount()-start)..' ms')
	return rows
end

function BtPreloadPersonalTops(mapId, playerIdList, needsPos)
	local personalCache = Cache.get('BestTime.m'..mapId..'.Personal')
	if(not personalCache) then
		personalCache = {}
		Cache.set('BestTime.m'..mapId..'.Personal', personalCache, 300)
	end
	
	local idList = {}
	for i, playerId in ipairs(playerIdList) do
		if(personalCache[playerId] == nil or (needsPos and personalCache[playerId] and not personalCache[playerId].pos)) then
			personalCache[playerId] = false
			table.insert(idList, playerId)
		end
	end
	
	if(#idList > 0) then
		local rows
		if(needsPos) then
			rows = DbQuery(
				'SELECT bt1.player, bt1.time, ('..
					'SELECT COUNT(*) FROM '..BestTimesTable..' bt2 '..
					'WHERE bt2.map=bt1.map AND bt2.time<=bt1.time) AS pos '..
				'FROM '..BestTimesTable..' bt1 '..
				'WHERE bt1.map=? AND bt1.player IN (??)', mapId, table.concat(idList, ','))
		else
			rows = DbQuery(
				'SELECT player, time '..
				'FROM '..BestTimesTable..' '..
				'WHERE map=? AND player IN (??)', mapId, table.concat(idList, ','))
		end
		
		for i, data in ipairs(rows) do
			local playerId = data.player
			data.player = nil
			personalCache[playerId] = data
		end
	end
end

function BtGetPersonalTop(mapId, playerId, needsPos)
	if(not playerId) then return false end
	BtPreloadPersonalTops(mapId, {playerId}, needsPos)
	local cache = Cache.get('BestTime.m'..mapId..'.Personal')
	local info = cache[playerId]
	return info and table.copy(info)
end

-- race_delay_indicator uses it
function getTopTime(mapRes, cp_times)
	assert(mapRes and cp_times)
	local map = Map(mapRes)
	local mapId = map:getId()
	
	local rows
	if(cp_times) then
		rows = DbQuery('SELECT bt.time, bt.player, b.data AS cp_times FROM '..BestTimesTable..' bt, '..BlobsTable..' b '..
			'WHERE bt.map=? AND b.id=bt.cp_times ORDER BY bt.time LIMIT 1', mapId)
		for i, row in ipairs(rows) do
			assert(row.cp_times:len() > 0)
			if(zlibUncompress) then
				row.cp_times = zlibUncompress(row.cp_times)
			end
			if(not row.cp_times) then
				Debug.warn('Failed to uncompress '..row.cp_times:len())
				row.cp_times = {}
			end
		end
	end
	
	if(rows and rows[1]) then
		rows[1].rank = BtGetPersonalTop(mapId, rows[1].player, true).pos
	end
	
	return rows
end

function BtPrintTimes(room, mapId)
	-- Prepare list of player IDs in room
	local idList = {}
	for player, pdata in pairs(g_Players) do
		if(pdata.room == room and pdata.id) then
			table.insert(idList, pdata.id)
		end
	end
	
	-- Get personal times for all players in room
	BtPreloadPersonalTops(mapId, idList)
	
	for player, pdata in pairs(g_Players) do
		if(pdata.room == room and pdata.id) then
			local personalTop = BtGetPersonalTop(mapId, pdata.id)
			if(personalTop) then
				Debug.info(tostring(personalTop.time)..' '..type(personalTop.time))
				local timeStr = formatTimePeriod(personalTop.time / 1000)
				
				-- Display notification
				if(pdata.addNotify) then
					pdata:addNotify{
						icon = 'best_times/race.png',
						{"Your personal best time: %s", timeStr}
					}
				else
					privMsg(pdata, "Your personal best time: %s", timeStr)
				end
			end
		end
	end
end
