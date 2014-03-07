
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

function addPlayerTime(player_id, map_id, time)
	local prof = DbgPerf()
	local wasInTop = false
	local now = getRealTime().timestamp
	
	-- Save new time in database
	local besttime = DbQuerySingle('SELECT time FROM '..BestTimesTable..' WHERE player=? AND map=? LIMIT 1', player_id, map_id)
	if(not besttime) then
		DbQuery('INSERT INTO '..BestTimesTable..' (player, map, time, timestamp) VALUES(?, ?, ?, ?)', player_id, map_id, time, now)
	elseif(besttime.time < time) then -- new time is worse
		return -1
	else
		local oldPos = DbCount(BestTimesTable, 'map=? AND time<=?', map_id, besttime.time)
		wasInTop = (oldPos <= 3) -- were we in the top?
		
		DbQuery('UPDATE '..BestTimesTable..' SET time=?, timestamp=? WHERE player=? AND map=?', time, now, player_id, map_id)
	end
	
	local newPos = DbCount(BestTimesTable, 'map=? AND time<=?', map_id, time)
	
	-- Check if player joined the Top
	if(newPos <= 3 and not wasInTop) then
		-- Increment Top Times count
		AccountData.create(player_id):add('toptimes_count', 1)
		
		-- Find player which quit the top
		local besttime4 = DbQuerySingle('SELECT player, rec, cp_times FROM '..BestTimesTable..' WHERE map=? ORDER BY time LIMIT 3,1', map_id)
		if(besttime4) then
			-- Decrement his Top Times count
			AccountData.create(besttime4.player):add('toptimes_count', -1)
			
			-- Forget playback trace and CP times
			DbQuery('UPDATE '..BestTimesTable..' SET rec=NULL, cp_times=NULL WHERE player=? AND map=?', besttime4.player, map_id)
			if(besttime4.rec) then
				DbQuery('DELETE FROM '..BlobsTable..' WHERE id=?', besttime4.rec)
			end
			if(besttime4.cp_times) then
				DbQuery('DELETE FROM '..BlobsTable..' WHERE id=?', besttime4.cp_times)
			end
		end
	end
	
	-- Update Map Info if Top Times table changed
	if(newPos <= 8) then
		MiUpdateTops(map_id) -- invalidate cache
	end
	
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
	local rows = DbQuery(
		'SELECT bt.player, bt.time, p.name '..
		'FROM '..BestTimesTable..' bt '..
		'INNER JOIN '..PlayersTable..' p ON bt.player=p.player '..
		'WHERE bt.map=? ORDER BY time LIMIT ?', map:getId(), count)
	--end
	for i, data in ipairs(rows) do
		data.time = formatTimePeriod(data.time / 1000)
	end
	--Debug.warn('Toptimes: '..(getTickCount()-start)..' ms')
	return rows
end

function BtUpdatePlayerTops(playerTimes, map, players)
	local idList = {}
	for i, player in ipairs(players) do
		local pdata = Player.fromEl(player)
		if(pdata and playerTimes[player] == nil and pdata.id) then
			playerTimes[player] = false
			table.insert(idList, pdata.id)
		end
	end
	
	if(#idList > 0) then
		local rows = DbQuery(
			'SELECT bt1.player, bt1.time, ('..
				'SELECT COUNT(*) FROM '..BestTimesTable..' bt2 '..
				'WHERE bt2.map=bt1.map AND bt2.time<=bt1.time) AS pos '..
			'FROM '..BestTimesTable..' bt1 '..
			'WHERE bt1.map=? AND bt1.player IN (??)', map:getId(), table.concat(idList, ','))
		
		for i, data in ipairs(rows) do
			local player = Player.fromId(data.player)
			assert(player)
			data.time = formatTimePeriod(data.time / 1000)
			playerTimes[player.el] = data
		end
	end
end

-- race_delay_indicator uses it
function getTopTime(map_res, cp_times)
	assert(map_res and cp_times)
	local map = Map(map_res)
	local map_id = map:getId()
	
	local rows
	if(cp_times) then
		rows = DbQuery('SELECT bt.time, b.data AS cp_times FROM '..BestTimesTable..' bt, '..BlobsTable..' b '..
			'WHERE bt.map=? AND b.id=bt.cp_times ORDER BY bt.time LIMIT 1', map_id)
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
		local rows2 = DbQuery('SELECT count(player) AS c FROM '..BestTimesTable..' WHERE time<? AND map=?', rows[1].time, map_id)
		rows[1].rank = rows2[1].c + 1
	end
	
	return rows
end

function BtPrintTimes(room, map_id)
	-- Prepare list of player IDs in room
	local idList = {}
	for player, pdata in pairs(g_Players) do
		if(pdata.room == room and pdata.id) then
			table.insert(idList, pdata.id)
		end
	end
	
	-- Get personal times for all players in room
	local rows = DbQuery('SELECT player, time FROM '..BestTimesTable..' WHERE map=? AND player IN (??)', map_id, table.concat(idList, ','))
	for i, data in ipairs(rows) do
		local pdata = Player.fromId(data.player)
		local timeStr = formatTimePeriod(data.time / 1000)
		
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
